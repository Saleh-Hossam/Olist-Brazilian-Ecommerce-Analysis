USE Brazilian_E_Commerce;
-----------------------------------------------------------------------------------------
--SELECT * FROM Order_payments
-----------------------------------------------------------------------------------------
-- Data Quality Check
-- Nulls or Empty & Blank Spaces
-----------------------------------------------------------------------------------------
SELECT	*
FROM Order_payments
WHERE CASE WHEN COALESCE(TRIM(order_id),'') = '' THEN 1 
		   WHEN payment_sequential IS NULL THEN 1
		   WHEN COALESCE(TRIM(payment_type),'') = '' THEN 1
		   WHEN payment_installments IS NULL THEN 1 
		   WHEN payment_value IS NULL THEN 1
		   ELSE 0 END = 1; 

/* No Nulls. The empty rows are in payment_installments and payment_value —
   these belong to orders paid instantly without installments or via voucher with no payment value.
   Only 11 rows affected */

-----------------------------------------------------------------------------------------
-- Checking for Duplicates
-----------------------------------------------------------------------------------------
SELECT * FROM (
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY order_id, payment_sequential ORDER BY order_id) RN
FROM Order_payments) R 
WHERE RN > 1;

/* The primary key for this table is a composite of order_id and payment_sequential —
   together they form a unique row */

-----------------------------------------------------------------------------------------
-- Top Numbers
-----------------------------------------------------------------------------------------
SELECT 
	COUNT(DISTINCT order_id) TotalOrders,
	COUNT(DISTINCT payment_type) Num_Payments,
	ROUND(SUM(payment_value),2) TotalPaymentValue
FROM Order_payments;

-----------------------------------------------------------------------------------------
-- Payment Breakdown by Type
-----------------------------------------------------------------------------------------
SELECT 
	*,
	SUM(PaymentByPaymentType) OVER() Total_Payment,
	CONCAT(ROUND(PaymentByPaymentType / SUM(PaymentByPaymentType) OVER() * 100,2),'%') Payment_Percent
FROM (
SELECT 
	payment_type,
	ROUND(SUM(payment_value),2) PaymentByPaymentType
FROM Order_payments
GROUP BY payment_type) R
ORDER BY PaymentByPaymentType DESC;

/* Credit card represents the highest payment method */

-----------------------------------------------------------------------------------------
-- Not Defined Payment Type
-----------------------------------------------------------------------------------------
SELECT * FROM Order_payments 
WHERE payment_type = 'not_defined';

/* 3 orders with not_defined payment type and no payment value */

-----------------------------------------------------------------------------------------
-- Installments by Payment Type
-----------------------------------------------------------------------------------------
SELECT DISTINCT payment_type
FROM Order_payments 
WHERE payment_installments > 1;

/* Installments are exclusive to credit card — which makes sense.
   However this means our revenue is tied to customers' ability to complete their installment payments */

-----------------------------------------------------------------------------------------
-- Payment Summary by Type
-----------------------------------------------------------------------------------------
SELECT 
	payment_type,
	COUNT(DISTINCT order_id) Total_Orders,
	MAX(payment_installments) Max_Installments,
	AVG(payment_installments) Avg_Installments,
	ROUND(AVG(payment_value),2) Avg_PaymentValue
FROM Order_payments
GROUP BY payment_type
ORDER BY Total_Orders DESC;

/* Max installments reached 24 but the average is only 3 */

-----------------------------------------------------------------------------------------
-- Top 10 Orders by Payment Value
-----------------------------------------------------------------------------------------
SELECT 
	TOP 10 order_id,
	MAX(payment_value) Max_PaymentValue,
	SUM(payment_installments) Total_Installments
FROM Order_payments
GROUP BY order_id
ORDER BY Max_PaymentValue DESC;

-----------------------------------------------------------------------------------------
-- Bottom 10 Orders by Payment Value
-----------------------------------------------------------------------------------------
SELECT 
	TOP 10 order_id,
	MAX(payment_value) Max_PaymentValue,
	SUM(payment_installments) Total_Installments
FROM Order_payments
GROUP BY order_id
ORDER BY Max_PaymentValue ASC;

/* Bottom orders show 0 value — explained by vouchers and not_defined payment types */

SELECT * FROM Order_payments
WHERE payment_value = 0;

-----------------------------------------------------------------------------------------
-- Reconciliation: Payments vs. Order Items
-- Goal: Check if total payments match total order value (price + freight)
-----------------------------------------------------------------------------------------
WITH Total_Payments AS (
	SELECT order_id, SUM(payment_value) Total_Paid
	FROM Order_payments
	GROUP BY order_id
),
Total_Items AS (
	SELECT order_id, SUM(price + freight_value) Total_Price
	FROM Order_items
	GROUP BY order_id
)
SELECT 
		COUNT(*) Total_Orders,
		ROUND(SUM(Total_Paid),2) Actual_Value,
		ROUND(SUM(Total_Price),2) Expected_Value,
		ROUND(SUM(ABS(Total_Paid - Total_Price)),2) Total_Discrepancy,
		SUM(CASE WHEN ABS(Total_Price - Total_Paid) < 0.01 THEN 1 ELSE 0 END) Matching_Orders,
		SUM(CASE WHEN Total_Price - Total_Paid > 0.01 THEN 1 ELSE 0 END) UnderPaid_Orders,
		SUM(CASE WHEN Total_Paid - Total_Price > 0.01 THEN 1 ELSE 0 END) OverPaid_Orders,
		SUM(CASE WHEN ABS(Total_Price - Total_Paid) > 0.01 THEN 1 ELSE 0 END) Unmatched_Orders
FROM Total_Items ti 
RIGHT JOIN Total_Payments pt
ON PT.order_id = TI.order_id;

/* Reconciliation: Order_payments vs Order_items

   Official Revenue:  R$16,008,872.12  (source: Order_payments — payment-side truth)
   Item-side Revenue: R$15,843,409.78  (source: Order_items — price + freight)
   Gap: ~R$165K across 775 orders that have payment records but no item records

   452 orders have a discrepancy > R$0.01 between what was paid vs item value
   - 311 overpaid, 141 underpaid, total variance R$3,272.34 (0.02% of revenue)
   - Likely explained by vouchers reducing actual payment below item price

   Decision: Revenue headline = R$16,008,872.12 (payments)
   Category-level analysis will use Order_items (~R$15.8M) — gap documented here */