USE Brazilian_E_Commerce
-----------------------------------------------------------------------------------------
-- 'Data Quality Check'-- 
-- NUlls or Empty & Blank Spaces --


SELECT 
	*
FROM Geolocation
WHERE CASE WHEN COALESCE(TRIM(geolocation_zip_code_prefix),'') = '' THEN 1 
           WHEN COALESCE(geolocation_lat,'') = '' THEN 1
           WHEN COALESCE(geolocation_lng,'') = '' THEN 1
           WHEN COALESCE(TRIM(geolocation_city),'') = '' THEN 1
           WHEN COALESCE(TRIM(geolocation_state),'') = '' THEN 1  ELSE 0  END = 1;
          
/* The columns that have null are the geolocation_lat has null 1336 rows and geolocation_lng
 has 3 rows which are the are part of the 1336 rows in the geolocation_lat*/

-----------------------------------------------------------------------------------------
-- Checking Duplicates -- 

SELECT * FROM 
(
SELECT 
    *,
    ROW_NUMBER() OVER(PARTITION BY geolocation_zip_code_prefix, geolocation_lat,geolocation_lng  ORDER BY geolocation_zip_code_prefix ) RN
FROM Geolocation) R
WHERE RN > 1;

/* After check there are duplicates in the table even after combining the zip_code with Lng and Lat
we still have duplicates values  280,370 after combining the three columns and more with doing that */
-----------------------------------------------------------------------------------------
-- Top Numbers -- 

SELECT 
COUNT(*) Rows_Count,
COUNT(DISTINCT geolocation_zip_code_prefix ) Zip_Code_Count,
COUNT(DISTINCT geolocation_city ) City_Count,
COUNT(DISTINCT geolocation_state ) Stat_Count
FROM Geolocation;

 -----------------------------------------------------------------------------------------
 /* Number of Zip Code by State */

 SELECT 
 geolocation_state,
 COUNT(DISTINCT geolocation_zip_code_prefix ) Zip_Code_Count
 FROM Geolocation
 GROUP BY geolocation_state
 ORDER BY Zip_Code_Count DESC;


 -----------------------------------------------------------------------------------------
 -- Number of orders and Revenue Stemed from every State -- 

 SELECT 
    C.customer_state,
    COUNT(DISTINCT T.order_id) Num_orders,
    ROUND(SUM(T.price + COALESCE(T.freight_value,0)),2) Revenue
FROM Order_items T
JOIN Orders O
ON T.order_id = O.order_id
JOIN Customers C
ON C.customer_id = O.customer_id
GROUP BY C.customer_state;

-----------------------------------------------------------------------------------------

-- Creating Clean Geolocation Table --

WITH Clean_Geolocation AS (
    SELECT 
        geolocation_zip_code_prefix AS zip_code,
        MAX(geolocation_state) AS state,
        MAX(geolocation_city) AS city,
        AVG(geolocation_lat) AS center_lat,
        AVG(geolocation_lng) AS center_lng
    FROM Geolocation
    GROUP BY geolocation_zip_code_prefix
)
-- Test it to prove we fixed the duplicates --
SELECT COUNT(*) as Total_Rows, COUNT(DISTINCT zip_code) as Unique_Zips
FROM Clean_Geolocation; 

