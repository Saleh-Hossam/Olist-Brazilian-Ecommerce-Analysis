USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
--SELECT * FROM Sellers
-----------------------------------------------------------------------------------------
-- Data Quality Check
-- Nulls or Empty & Blank Spaces
-----------------------------------------------------------------------------------------
SELECT 	*
FROM Sellers
WHERE CASE WHEN COALESCE(TRIM(seller_id),'') = '' THEN 1 
           WHEN COALESCE(seller_zip_code_prefix,'') = '' THEN 1
           WHEN COALESCE(TRIM(seller_city),'') = '' THEN 1
           WHEN COALESCE(TRIM(seller_state),'') = '' THEN 1 ELSE 0 END = 1;

/* No Nulls, Empty or Blanks were Found in the Sellers Table */

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY seller_id ORDER BY seller_id) RN
FROM Sellers) R 
WHERE RN > 1;

/* No Duplicates in seller_id which is the Primary Key of the Sellers Table */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
    COUNT(seller_id) Num_Sellers,
    COUNT(DISTINCT seller_zip_code_prefix) Num_Code,
    COUNT(DISTINCT seller_city) Num_City,
    COUNT(DISTINCT seller_state) Num_State
FROM Sellers;

-----------------------------------------------------------------------------------------
-- Top Sellers by Number of Orders and Sum of Revenue
-----------------------------------------------------------------------------------------

-- By Sum of Revenue
SELECT 
TOP 10 *,
CONCAT(ROUND(CAST(Revenue AS FLOAT) / SUM(Revenue) OVER() * 100,2),'%') Percent_Of_Total
FROM (
SELECT 
     seller_id,
    COUNT(DISTINCT order_id) Num_Orders,
    ROUND(SUM(price + COALESCE(freight_value,0)),2) Revenue
FROM Order_items 
GROUP BY seller_id) R
ORDER BY Revenue DESC, Num_Orders DESC;

-- By Number of Orders
SELECT 
TOP 10 *,
CONCAT(ROUND(CAST(Revenue AS FLOAT) / SUM(Revenue) OVER() * 100,2),'%') Percent_Of_Total_Revenue
FROM (
SELECT 
     seller_id,
    COUNT(DISTINCT order_id) Num_Orders,
    ROUND(SUM(price + COALESCE(freight_value,0)),2) Revenue
FROM Order_items 
GROUP BY seller_id) R
ORDER BY Num_Orders DESC, Revenue DESC;

/* Higher order volume doesn't guarantee higher revenue —
   the top sellers by orders and by revenue are not the same */

-----------------------------------------------------------------------------------------
-- Number of Sellers Per State
-----------------------------------------------------------------------------------------
SELECT 
    *, 
    CONCAT(ROUND(CAST(Num_Sellers AS FLOAT) / SUM(Num_Sellers) OVER() * 100,2),'%') Percent_Of_Total
FROM (
SELECT 
    seller_state,
    COUNT(seller_id) Num_Sellers
FROM Sellers
GROUP BY seller_state) S
ORDER BY Num_Sellers DESC;

/* SP and PR are the top seller states — 59.74% for SP and 11.28% for PR */

-----------------------------------------------------------------------------------------
-- Sellers By Category
-----------------------------------------------------------------------------------------
SELECT 
     p.product_category_name,
    COUNT(DISTINCT T.[seller_id]) Number_Sellers
FROM Products P
JOIN Order_items T
ON P.product_id = T.product_id
GROUP BY p.product_category_name
ORDER BY Number_Sellers DESC;

/* After checking, this query isn't fully accurate — a seller isn't limited 
   to one category, so the numbers here don't reflect true specialization */