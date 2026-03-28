USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
--SELECT * FROM Orders
-----------------------------------------------------------------------------------------
-- Data Quality Check
-- Nulls or Empty & Blank Spaces
-----------------------------------------------------------------------------------------
SELECT	*
FROM Orders
WHERE CASE WHEN COALESCE(TRIM(order_id),'') = '' THEN 1 
		   WHEN COALESCE(TRIM(Customer_id),'') = '' THEN 1
		   WHEN COALESCE(TRIM(Order_status),'') = '' THEN 1 
		   WHEN order_purchase_timestamp IS NULL THEN 1 
		   WHEN order_approved_at IS NULL THEN 1
		   WHEN order_delivered_carrier_date IS NULL THEN 1
		   WHEN order_delivered_customer_date IS NULL THEN 1
		   WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END = 1;

/* Nulls are exclusively in:
   order_approved_at // order_delivered_carrier_date // order_delivered_customer_date */

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_id) RN
FROM Orders) R 
WHERE RN > 1;

/* No Duplicates in order_id or customer_id */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
	COUNT(order_id) Orders_Count,
	COUNT(customer_id) Customer_Count
FROM Orders;

/* customer_id is a temporary ID assigned per purchase, not a unique customer identifier —
   the same customer can have different customer_ids across separate orders */

-----------------------------------------------------------------------------------------
-- Order Status Breakdown
-----------------------------------------------------------------------------------------
SELECT	
		*,
		SUM(Orders_Count) OVER() TotalOrders,
		CONCAT(ROUND((CAST(Orders_Count AS FLOAT) / SUM(Orders_Count) OVER() * 100),2),'%') PercentOfTotalOrders
FROM(
SELECT	
	Order_status,
	COUNT(order_id) Orders_Count
FROM Orders
GROUP BY Order_status) R 
ORDER BY Orders_Count DESC;

/* The vast majority of orders are Delivered (97%) which is a good sign */

-----------------------------------------------------------------------------------------
-- Investigate the Nulls by Status
-----------------------------------------------------------------------------------------
SELECT Order_status,
		COUNT(order_id) Num_Orders
FROM Orders
WHERE CASE 		   
		   WHEN order_approved_at IS NULL THEN 1
		   WHEN order_delivered_carrier_date IS NULL THEN 1
		   WHEN order_delivered_customer_date IS NULL THEN 1
		   ELSE 0 END = 1
GROUP BY Order_status
ORDER BY Num_Orders DESC;

-----------------------------------------------------------------------------------------
-- Investigate the Nulls — Delivered Orders With Missing Dates
-----------------------------------------------------------------------------------------
SELECT	*
FROM Orders
WHERE CASE WHEN order_approved_at IS NULL THEN 1
		   WHEN order_delivered_carrier_date IS NULL THEN 1
		   WHEN order_delivered_customer_date IS NULL THEN 1
		   ELSE 0 END = 1
		   AND Order_status = 'delivered';

/* Having nulls in these columns is expected for non-delivered orders.
   However, there are 23 orders marked as delivered with no date details — worth flagging */

-----------------------------------------------------------------------------------------
-- Orders by Month
-----------------------------------------------------------------------------------------
SELECT 
		*,
		SUM(Orders_Count) OVER() TotalOrders,
		CONCAT(ROUND((CAST(Orders_Count AS FLOAT)/SUM(Orders_Count) OVER() * 100),2),'%') PercentOfTotal
FROM(
SELECT	
	    MONTH(order_purchase_timestamp) MonthNumber,
		DATENAME(MONTH,order_purchase_timestamp) Months,
		COUNT(order_id) Orders_Count
FROM Orders
GROUP BY DATENAME(MONTH,order_purchase_timestamp), MONTH(order_purchase_timestamp)
) R
ORDER BY MonthNumber;

/* August, May, and July are the highest months by number of orders */

-----------------------------------------------------------------------------------------
-- Month over Month Growth
-----------------------------------------------------------------------------------------
SELECT 
		*,
		LAG(Orders_Count) OVER(ORDER BY YearMonth) PreviousMonthOrders,
		Orders_Count - LAG(Orders_Count) OVER(ORDER BY YearMonth) MoM,
		CONCAT(ROUND((CAST(Orders_Count AS FLOAT) - LAG(Orders_Count) OVER(ORDER BY YearMonth)) / LAG(Orders_Count) OVER(ORDER BY YearMonth) * 100,2),'%') AS MoM_Growth_Rate
		
FROM(
SELECT	
	    FORMAT(order_purchase_timestamp,'yyyy-MM') YearMonth,
		COUNT(order_id) Orders_Count
FROM Orders
WHERE order_purchase_timestamp > '2016-12-31' AND order_purchase_timestamp < '2018-09-01'
GROUP BY FORMAT(order_purchase_timestamp,'yyyy-MM')
) R
ORDER BY YearMonth;

/* Nov 2017 (Black Friday): Sales exploded
   Dec 2017 (Christmas?): Sales crashed
   Jan 2018 (New Year): Sales bounced back */

-----------------------------------------------------------------------------------------
-- Logical Integrity Check (The Time Machine)
-- Goal: Find orders that violate the natural order of events
-----------------------------------------------------------------------------------------
SELECT 
    order_id, 
    order_status, 
    order_purchase_timestamp, 
    order_delivered_carrier_date, 
    order_delivered_customer_date
FROM Orders
WHERE 
    -- 1. Delivered before it was shipped?
    order_delivered_customer_date < order_delivered_carrier_date 
    
    -- 2. Shipped before it was purchased?
    OR order_delivered_carrier_date < order_purchase_timestamp;