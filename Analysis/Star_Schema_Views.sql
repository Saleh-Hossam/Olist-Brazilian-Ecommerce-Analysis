USE Brazilian_E_Commerce;
GO

-- =====================================================================
-- 1. FACT TABLE: Order Items (The core math and IDs)
-- =====================================================================
CREATE OR ALTER VIEW vw_Fact_Order_Items AS
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    COALESCE(freight_value, 0) AS freight_value
FROM Order_items;
GO

-- =====================================================================
-- 2. DIMENSION TABLE: Orders (Dates, Statuses, and Clean Reviews)
-- =====================================================================
CREATE OR ALTER VIEW vw_Dim_Orders AS
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
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    cr.review_score
FROM Orders o
LEFT JOIN Clean_Review cr ON o.order_id = cr.order_id;
GO

-- =====================================================================
-- 3. DIMENSION TABLE: Products (With English Translation)
-- =====================================================================
CREATE OR ALTER VIEW vw_Dim_Products AS
SELECT 
    p.product_id,
    COALESCE(pc.product_category_name_english, p.product_category_name, 'Unknown') AS category_name
FROM Products p
LEFT JOIN product_category_name pc ON p.product_category_name = pc.product_category_name;
GO

-- =====================================================================
-- 4. DIMENSION TABLE: Customers
-- =====================================================================
CREATE OR ALTER VIEW vw_Dim_Customers AS
SELECT 
    customer_id,
    customer_unique_id,
    customer_state,
    customer_city
FROM Customers;
GO

-- =====================================================================
-- 5. DIMENSION TABLE: Sellers
-- =====================================================================
CREATE OR ALTER VIEW vw_Dim_Sellers AS
SELECT 
    seller_id,
    seller_state,
    seller_city
FROM Sellers;
GO
