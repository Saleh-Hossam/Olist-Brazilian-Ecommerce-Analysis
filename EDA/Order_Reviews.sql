USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
-- 'Data Quality Check'
-- NUlls or Empty & Blank Spaces
-----------------------------------------------------------------------------------------
SELECT 	*
FROM order_reviews
WHERE CASE WHEN COALESCE(TRIM(review_id),'') = '' THEN 1 
           WHEN COALESCE(TRIM(order_id),'') = '' THEN 1
           WHEN COALESCE(review_score,'') = '' THEN 1
           WHEN COALESCE(TRIM(review_comment_title),'') = '' THEN 1
           WHEN COALESCE(TRIM(review_comment_message),'') = '' THEN 1 
           WHEN review_creation_date IS NULL THEN 1
           WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END = 1;

/* The Nulls are only in Review_comment_title and Comment_message columns only, which is expected
   as not all customers would leave comments.
   There are 99,224 rows in the Order_Reviews table and 89,399 Nulls for the mentioned columns */

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY review_id, order_id ORDER BY review_id ASC) RN
FROM order_reviews) R 
WHERE RN > 1;

/* The primary key for this table is the composite of review_id and order_id.
   review_id alone has duplicates, and order_id alone has duplicates.
   This means the same order can have multiple reviews submitted by the customer 
   at different points in time — not because of multiple items. */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT review_id) Num_Reviews,
    COUNT(DISTINCT order_id) Num_Orders,
    AVG(review_score) Avg_Score,
    SUM(CASE WHEN COALESCE(TRIM(review_comment_title),'') = '' THEN 1 ELSE 0 END) Num_No_Comment_Title,
    SUM(CASE WHEN COALESCE(TRIM(review_comment_message),'') = '' THEN 1 ELSE 0 END) Num_No_Comment_Message
FROM order_reviews;

/* Avg score of 4 is a positive signal given the 1-5 scale.
   29,392 orders have a comment title but no comment message. */

-----------------------------------------------------------------------------------------
-- Orders With No Review
-----------------------------------------------------------------------------------------
SELECT (SELECT COUNT(order_id) FROM Orders) - COUNT(DISTINCT order_id) AS Orders_With_No_Review
FROM order_reviews;

/* 768 orders have no review record */

-----------------------------------------------------------------------------------------
-- Review Score Distribution
-----------------------------------------------------------------------------------------
SELECT 
    *, 
    CONCAT(ROUND(CAST(Num_Reviews AS FLOAT) / SUM(Num_Reviews) OVER() * 100, 2), '%') Percent_Of_Total
FROM (
    SELECT 
        review_score,
        COUNT(review_id) Num_Reviews
    FROM order_reviews 
    GROUP BY review_score) s
ORDER BY Num_Reviews DESC;

/* Score 5 is the most common. Score 1 (the lowest) is the third most frequent — worth monitoring */

-----------------------------------------------------------------------------------------
-- Most Common Review Titles
-----------------------------------------------------------------------------------------
SELECT 
    TOP 10 review_comment_title,
    COUNT(order_id) Num_Orders,
    COUNT(review_id) Num_Reviews
FROM order_reviews
WHERE review_comment_title IS NOT NULL
GROUP BY review_comment_title
ORDER BY Num_Orders DESC, Num_Reviews DESC;

/* Most repeated titles are "Recomendo" and "Super recomendo" — positive signals */

-----------------------------------------------------------------------------------------
-- Date Anomaly Check
-----------------------------------------------------------------------------------------
SELECT * FROM order_reviews 
WHERE review_creation_date > review_answer_timestamp;

/* No anomalies found where creation date is more recent than the answer timestamp */

-----------------------------------------------------------------------------------------
-- Duplicate Orders With Conflicting Review Scores
-----------------------------------------------------------------------------------------
SELECT order_id, MIN(review_score) Min_Score, MAX(review_score) Max_Score
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY order_id;

/* 547 orders have duplicate reviews with conflicting scores.
   Decision: Use most recent review per order (by review_creation_date).
   Reason: Most recent score reflects the customer's final decision */