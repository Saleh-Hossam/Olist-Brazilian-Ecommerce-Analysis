USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
--SELECT * FROM Order_items;
-----------------------------------------------------------------------------------------
-- Data Quality Check
-- Nulls or Empty & Blank Spaces

SELECT	*
FROM Order_items
WHERE CASE WHEN COALESCE(TRIM(order_id),'') = '' THEN 1 
		   WHEN COALESCE(order_item_id,'') = '' THEN 1
		   WHEN COALESCE(TRIM(Product_id),'') = '' THEN 1 
		   WHEN COALESCE(TRIM(seller_id),'') = '' THEN 1 
		   WHEN COALESCE(shipping_limit_date,'') = '' THEN 1
		   WHEN COALESCE(price,'') = '' THEN 1
		   WHEN COALESCE(freight_value,'') = '' THEN 1 ELSE 0 END = 1; 

SELECT * FROM Order_items WHERE COALESCE(freight_value,'') = ''; 

-- There are 383 rows with empty freight_value — no other nulls or empty values found --

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY order_id, order_item_id ORDER BY order_id) RN
FROM Order_items) R 
WHERE RN > 1;

/* The primary key for this table is a composite of order_id and order_item_id —
   both are needed to uniquely identify a row, while other columns may repeat */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
	 COUNT(DISTINCT order_id) Total_Orders,
	 COUNT(order_item_id) Num_Items,
	 COUNT(DISTINCT product_id) Num_Products,
	 COUNT(DISTINCT seller_id) Num_Sellers,
	 ROUND(AVG(price),2) Avg_Price,
	 ROUND(AVG(COALESCE(freight_value,0)),2) Avg_Freight_Value
FROM Order_items;

-----------------------------------------------------------------------------------------
-- Top 10 Products by Price
-----------------------------------------------------------------------------------------
SELECT 
		TOP 10 order_id,
		MAX(price) Product_Price
FROM Order_items
GROUP BY order_id
ORDER BY MAX(price) DESC;

-- Bottom 10 Products by Price
SELECT 
		TOP 10 order_id,
		freight_value,
		MAX(price) Product_Price
FROM Order_items
GROUP BY order_id, freight_value
ORDER BY MAX(price);

/* The price for some products is almost zero — however adding the freight value
   brings the total to an acceptable range */

-----------------------------------------------------------------------------------------
-- Max Items in One Order
-----------------------------------------------------------------------------------------
SELECT TOP 10
    order_id,
    MAX(order_item_id) Max_Items_In_One_Order,
    ROUND(SUM(price),2) Total_Order_Cost,
    ROUND(SUM(freight_value),2) Total_Shipping_Cost
FROM Order_items
GROUP BY order_id
ORDER BY Max_Items_In_One_Order DESC;

-----------------------------------------------------------------------------------------
-- Financials: Executive Summary
-- Goal: Calculate total revenue and shipping costs
-----------------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT order_id) AS Total_Orders,
    
    -- The Money
    SUM(price) AS Total_Revenue_GMV,
    SUM(freight_value) AS Total_Shipping_Cost,
    
    -- The Ratio
    -- "For every $100 in product, how much do customers pay in shipping?"
    (SUM(freight_value) / SUM(price)) * 100 AS Freight_Ratio_Pct,
	SUM(price + freight_value) AS Total_Revenue,
    1.0 * (COUNT(order_item_id) / COUNT(DISTINCT order_id)) Average_Items_Per_Order
FROM Order_items;