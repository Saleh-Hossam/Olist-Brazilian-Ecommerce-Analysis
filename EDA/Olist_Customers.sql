USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
-- Data Quality Check
-- Nulls or Empty & Blank Spaces
SELECT * 
FROM Customers
WHERE CASE WHEN COALESCE(TRIM(Customer_id),'') = '' THEN 1 ELSE 0 END  = 1
OR CASE WHEN COALESCE(TRIM(customer_unique_id),'') = '' THEN 1 ELSE 0 END  = 1
OR CASE WHEN COALESCE(TRIM(Customer_city),'') = '' THEN 1 ELSE 0 END  = 1
OR CASE WHEN COALESCE(TRIM(Customer_state),'') = '' THEN 1 ELSE 0 END  = 1; 

-- Duplicates --

SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY Customer_id ORDER BY Customer_id) RN
FROM Customers) R 
WHERE RN > 1;

-- Or Simply --
SELECT * FROM Customers WHERE customer_unique_id IS NULL;

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
COUNT(customer_id) Num_Customers,
COUNT(DISTINCT customer_unique_id) Unique_Customers,
COUNT(DISTINCT customer_city) Num_City,
COUNT(DISTINCT customer_state) Num_State
FROM Customers;

-----------------------------------------------------------------------------------------
-- Top 10 Cities by Number of Customers and Their Percentage
-----------------------------------------------------------------------------------------
WITH CT AS (
SELECT 
    customer_city,
	customer_state,
	COUNT(DISTINCT customer_unique_id) Num_Customers
FROM Customers
GROUP BY customer_city, customer_state
)
SELECT TOP 10 *,
		SUM(Num_Customers) OVER() TotalCustomers,
		CONCAT(ROUND((CAST(Num_Customers AS FLOAT) / SUM(Num_Customers) OVER() * 100),2),'%') Customer_Percent
FROM CT
ORDER BY Num_Customers DESC;

/* Sao Paulo is the highest city by customer count */

-----------------------------------------------------------------------------------------
-- Top 10 States by Number of Customers and Their Percentage
-----------------------------------------------------------------------------------------
WITH CT AS (
SELECT 
	customer_state,
	COUNT(DISTINCT customer_unique_id) Num_Customers
FROM Customers
GROUP BY customer_state
)
SELECT TOP 10 *,
		SUM(Num_Customers) OVER() TotalCustomers,
		CONCAT(ROUND((CAST(Num_Customers AS FLOAT) / SUM(Num_Customers) OVER() * 100),2),'%') Customer_Percent 
FROM CT
ORDER BY Num_Customers DESC;

/* Sao Paulo is also the highest state by customer count */

-----------------------------------------------------------------------------------------
-- Customers Who Appear in More Than One State
-- The same unique customer shopping from different states causes
-- the unique customer count to differ from the city/state level totals
-----------------------------------------------------------------------------------------
SELECT 
    customer_unique_id,
    COUNT(DISTINCT customer_state) AS States_Shopped_In
FROM Customers
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_state) > 1
ORDER BY States_Shopped_In DESC;