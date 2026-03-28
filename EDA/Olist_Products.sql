USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
-- Checking Translation Coverage Between Products Table and Product Category Name
-----------------------------------------------------------------------------------------
SELECT 
	p.product_category_name AS Category_Original_Name,
	C.product_category_name_english AS Category_Translation_Name,
	COUNT(*) Num_Products
FROM Products p
LEFT JOIN product_category_name c
ON P.product_category_name = C.product_category_name
GROUP BY p.product_category_name, C.product_category_name_english
ORDER BY Num_Products DESC;

/* Two products have no translation:
   portateis_cozinha_e_preparadores_de_alimentos AND fashion_roupa_infanto_juvenil.
   We also have 610 rows with no product category in the Products table */

-----------------------------------------------------------------------------------------
-- Checking Nulls, Empty Rows and Blanks
-----------------------------------------------------------------------------------------
SELECT 
	* 
FROM Products
WHERE CASE 
           WHEN COALESCE(TRIM(product_id),'') = '' THEN 1
		   WHEN COALESCE(TRIM(product_category_name),'') = '' THEN 1
	       WHEN product_name_lenght IS NULL THEN 1
		   WHEN product_description_lenght IS NULL THEN 1
		   WHEN product_weight_g IS NULL THEN 1
		   WHEN product_length_cm IS NULL THEN 1
		   WHEN product_height_cm IS NULL THEN 1
		   WHEN product_width_cm IS NULL THEN 1 ELSE 0 END = 1;

/* 610 rows have nulls in the Products table because there's no product category —
   as found in the previous query. Most of these still have weight and dimension data.
   Around 5 products have empty or zero values in weight and length.
   One row is completely empty */

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY product_id) Rn
FROM Products) Ranks
WHERE Rn > 1;

/* product_id is the Primary Key — it's unique and there are no duplicates */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
	COUNT(product_id) Num_Products,
	COUNT(DISTINCT product_category_name) Num_Categories
FROM Products;

/* 32,951 product IDs across 73 categories — with 610 rows having no category as noted above */

-----------------------------------------------------------------------------------------
-- Checking the Null Category Rows Against Order_items
-----------------------------------------------------------------------------------------
SELECT 
	COUNT(*) Order_Item_Lines,
	ROUND(SUM(O.price),2) Price,
	ROUND(SUM(o.freight_value),2) Freight
FROM Order_items o
JOIN Products p
ON O.product_id = P.product_id
WHERE p.product_category_name IS NULL;

-----------------------------------------------------------------------------------------
-- Handling Nulls in Category Translation
-- Replacing with original name or 'Unknown' as fallback
-----------------------------------------------------------------------------------------
SELECT 
	P.product_id,
	P.[product_category_name],
	C.[product_category_name_english],
	COALESCE(C.[product_category_name_english], P.[product_category_name], 'Unknown') Final_Category
FROM Products P
LEFT JOIN product_category_name c
ON P.product_category_name = C.product_category_name
ORDER BY C.[product_category_name_english];

/*
CASE WHEN COALESCE(C.[product_category_name_english],P.[product_category_name]) IS NULL THEN 'Unknown'
	WHEN C.[product_category_name_english] IS NULL THEN P.[product_category_name] 
	ELSE C.[product_category_name_english] END Final_Category */

-----------------------------------------------------------------------------------------
-- Top 10 Categories by Revenue
-----------------------------------------------------------------------------------------
WITH Categories AS (
SELECT 
	P.product_id,
	P.[product_category_name],
	C.[product_category_name_english],
	COALESCE(C.[product_category_name_english], P.[product_category_name], 'Unknown') Final_Category
FROM Products P
LEFT JOIN product_category_name c
ON P.product_category_name = C.product_category_name
)
SELECT 
	TOP 10 C.Final_Category,
	ROUND(SUM(O.price + COALESCE(o.freight_value,0)),2) Revenue
FROM Order_items O
JOIN Categories C
ON O.product_id = C.product_id
GROUP BY C.Final_Category
ORDER BY Revenue DESC;