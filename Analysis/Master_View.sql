USE Brazilian_E_Commerce;
GO

/* =========================================================================================
   PROJECT  : Olist Brazilian E-Commerce Analysis
   AUTHOR   : Saleh Hossam
   DATABASE : Brazilian_E_Commerce (SQL Server)

   PURPOSE  : Builds the master flat view joining all 8 source tables into one clean
              dataset, then answers 6 core business questions directly from that view
              before handing off to Power BI for dashboarding.

   FINDINGS SUMMARY:
   - BQ1: Consistent MoM revenue growth 2017 → 2018. Black Friday Nov 2017 = peak spike.
   - BQ2: Health & Beauty leads at $1.4M. Top 5 categories drive majority of revenue.
   - BQ3: São Paulo (SP) = 41% of all orders and $5.77M revenue. Top 5 states = ~80%.
   - BQ4: Avg delivery time 12.5 days. On-time rate 91.89%.
   - BQ5: Top seller generated $249K. Significant variance across 3,095 active sellers.
   - BQ6: 7-day delivery gap between 1-star (16.42 days) and 5-star (9.22 days) reviews.
           Delivery speed is the single strongest driver of customer satisfaction.
========================================================================================= */


-- =========================================================================================
-- STEP 1: CREATE THE MASTER VIEW
-- Joining all core tables into one flat view for Power BI consumption.
-- 
-- KEY DECISION — Deduplicating reviews with ROW_NUMBER():
--   547 orders had multiple review entries with conflicting scores.
--   Fix: keep only the most recent review per order (ORDER BY review_creation_date DESC).
--   This ensures every order has exactly one review score in all downstream queries.
-- =========================================================================================
CREATE OR ALTER VIEW vw_Olist_Master_Data AS

WITH Clean_Review AS (
    SELECT order_id, review_score
    FROM (
        SELECT 
            order_id,
            review_score,
            ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_creation_date DESC) AS Ranking
        FROM order_reviews 
    ) AS RankedReviews
    WHERE Ranking = 1  -- Keep only the most recent review per order
)
SELECT 
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    COALESCE(oi.freight_value, 0) AS freight_value,      -- NULL freight treated as 0
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.order_status, 
    c.customer_state,
    -- Prefer English category name, fall back to Portuguese, then 'Unknown'
    COALESCE(pc.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
    cr.review_score
FROM Order_items oi
LEFT JOIN Orders o ON oi.order_id = o.order_id
LEFT JOIN Customers c ON c.customer_id = o.customer_id
LEFT JOIN Products p ON p.product_id = oi.product_id
LEFT JOIN product_category_name pc ON pc.product_category_name = p.product_category_name
LEFT JOIN Clean_Review cr ON oi.order_id = cr.order_id;
GO


-- =========================================================================================
-- STEP 2: BUSINESS INTELLIGENCE QUERIES
-- All queries filter on order_status = 'delivered' to ensure we only measure
-- completed transactions with valid revenue and delivery data.
-- =========================================================================================


-- =========================================================================================
-- BQ1: How much revenue are we making month over month?
-- -----------------------------------------------------------------------------------------
-- FINDING: Consistent growth from Jan 2017 through mid-2018.
--          November 2017 shows the single largest revenue spike in the dataset,
--          confirming a strong Black Friday seasonal demand response.
--          September 2018 appears as a sharp drop but is incomplete month data — excluded
--          from dashboard visuals to avoid misleading interpretation.
-- =========================================================================================
SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS Order_Month,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY Order_Month;


-- =========================================================================================
-- BQ2: Which product categories bring in the most money?
-- -----------------------------------------------------------------------------------------
-- FINDING: Health & Beauty leads at $1.4M, followed by Watches & Gifts ($1.3M)
--          and Bed, Bath & Table ($1.2M). The top 5 categories account for the
--          majority of total revenue — clear priority targets for inventory
--          investment and marketing spend.
-- =========================================================================================
SELECT TOP 10
    category_name,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY category_name
ORDER BY Total_Revenue DESC;


-- =========================================================================================
-- BQ3: Where are our top-paying customers located geographically?
-- -----------------------------------------------------------------------------------------
-- FINDING: São Paulo (SP) dominates with ~41% of all orders and $5.77M in revenue.
--          The top 5 states (SP, RJ, MG, RS, PR) represent approximately 80% of
--          total business volume. The remaining 22 states represent a largely
--          untapped market opportunity for geographic expansion.
-- =========================================================================================
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY customer_state
ORDER BY Total_Orders DESC;


-- =========================================================================================
-- BQ4: What is our average delivery time, and how often are we on time?
-- -----------------------------------------------------------------------------------------
-- FINDING: Average delivery time is 12.5 days across 99K+ delivered orders.
--          On-time rate is 91.89% — over 9 in 10 orders arrive on or before
--          the estimated delivery date. Filter excludes NULLs in delivered date
--          to avoid skewing the average with undelivered or cancelled orders.
-- =========================================================================================
SELECT 
   CAST(AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) * 1.0) AS DECIMAL(10,2)) AS Avg_Delivery_Time_Days,
   CONCAT(ROUND((CAST(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS FLOAT) / COUNT(DISTINCT order_id) * 100), 2), '%') AS Pct_On_Time
FROM vw_Olist_Master_Data 
WHERE order_delivered_customer_date IS NOT NULL 
  AND LOWER(order_status) = 'delivered';


-- =========================================================================================
-- BQ5: Who are our top 20 sellers, and are their customers actually happy?
-- -----------------------------------------------------------------------------------------
-- FINDING: Top seller generated $249K in revenue across 1,156 items.
--          Avg revenue per seller is $5.12K across 3,095 active sellers —
--          indicating a long tail of low-volume sellers.
--          Pairing revenue with Avg_Review_Score reveals whether high-revenue
--          sellers are also delivering good customer experiences, or hiding
--          service quality problems behind volume.
-- =========================================================================================
SELECT TOP 20
    seller_id,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(10,2)) AS Total_Revenue,
    CAST(AVG(review_score * 1.0) AS DECIMAL(10,2)) AS Avg_Review_Score
FROM vw_Olist_Master_Data 
WHERE LOWER(order_status) = 'delivered'
GROUP BY seller_id
ORDER BY Total_Revenue DESC;


-- =========================================================================================
-- BQ6: Does slow shipping actually cause bad reviews?
-- -----------------------------------------------------------------------------------------
-- FINDING: Yes — and the data is unambiguous.
--
--          Review Score | Avg Delivery Time
--          -------------|------------------
--          5 stars      | 9.22 days
--          4 stars      | 10.52 days
--          3 stars      | 11.88 days
--          2 stars      | 13.15 days
--          1 star       | 16.42 days
--
--          A 7-day gap between 1-star and 5-star delivery times.
--          Delivery speed is the single strongest predictor of customer satisfaction —
--          every extra day in transit measurably increases the risk of a bad review.
-- =========================================================================================
SELECT 
    review_score,
    CAST(AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) * 1.0) AS DECIMAL(10,2)) AS Avg_Delivery_Time_Days,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score DESC;