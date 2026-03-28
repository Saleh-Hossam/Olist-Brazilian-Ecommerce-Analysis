USE Brazilian_E_Commerce;
GO

/* =========================================================================================
   PROJECT: Olist E-Commerce Analytics
   AUTHOR: Saleh Hossam
   
   PURPOSE: This script handles the final data modeling and answers the core business 
   questions before we move everything into Power BI for dashboarding.
========================================================================================= */

-- =========================================================================================
-- STEP 1: CREATE THE MASTER VIEW
-- Joining all our core tables together so we have one clean dataset for Power BI.
-- We're also using a Window Function here to keep only the most recent review per order,
-- which fixes that issue where 547 orders had duplicate/conflicting reviews.
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
    WHERE Ranking = 1
)
SELECT 
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    COALESCE(oi.freight_value, 0) AS freight_value,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.order_status, 
    c.customer_state,
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
-- These pull directly from the Master View we just built above.
-- =========================================================================================

-- BQ1: How much revenue are we making month over month?
-- -----------------------------------------------------------------------------------------
SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS Order_Month,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY Order_Month;

-- -----------------------------------------------------------------------------------------
-- BQ2: Which product categories bring in the most money?
-- -----------------------------------------------------------------------------------------
SELECT TOP 10
    category_name,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY category_name
ORDER BY Total_Revenue DESC;

-- -----------------------------------------------------------------------------------------
-- BQ3: Where are our top-paying customers located geographically?
-- -----------------------------------------------------------------------------------------
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(15,2)) AS Total_Revenue
FROM vw_Olist_Master_Data
WHERE LOWER(order_status) = 'delivered'
GROUP BY customer_state
ORDER BY Total_Orders DESC;

-- -----------------------------------------------------------------------------------------
-- BQ4: What is our average delivery time, and how often are we on time?
-- -----------------------------------------------------------------------------------------
SELECT 
   CAST(AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) * 1.0) AS DECIMAL(10,2)) AS Avg_Delivery_Time_Days,
   CONCAT(ROUND((CAST(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS FLOAT) / COUNT(DISTINCT order_id) * 100), 2), '%') AS Pct_On_Time
FROM vw_Olist_Master_Data 
WHERE order_delivered_customer_date IS NOT NULL 
  AND LOWER(order_status) = 'delivered';

-- -----------------------------------------------------------------------------------------
-- BQ5: Who are our top 20 sellers, and are their customers actually happy?
-- (Checking to see if high revenue hides poor customer service)
-- -----------------------------------------------------------------------------------------
SELECT TOP 20
    seller_id,
    COUNT(DISTINCT order_id) AS Total_Orders,
    CAST(SUM(price + freight_value) AS DECIMAL(10,2)) AS Total_Revenue,
    CAST(AVG(review_score * 1.0) AS DECIMAL(10,2)) AS Avg_Review_Score
FROM vw_Olist_Master_Data 
WHERE LOWER(order_status) = 'delivered'
GROUP BY seller_id
ORDER BY Total_Revenue DESC;

-- -----------------------------------------------------------------------------------------
-- BQ6: Does slow shipping actually cause bad reviews?
-- -----------------------------------------------------------------------------------------
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