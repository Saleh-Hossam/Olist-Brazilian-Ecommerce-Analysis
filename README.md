# Olist Brazilian E-Commerce Analysis

![Dashboard Preview](Dashboard/Olist_Dashboard.gif)

---

## What This Project Is

Olist is a real Brazilian e-commerce platform. This analysis covers **99,441 orders and $15.84M in revenue** across 2016–2018 — and identifies the single operational factor that predicts customer satisfaction most reliably: delivery time.

| Metric | Value |
|---|---|
| Total Revenue | $15.84M |
| Total Orders | 99,441 |
| Total Items Sold | 112,650 |
| On-Time Rate | 91.89% |
| Avg Review Score | 4.09 / 5 |
| Active Sellers | 3,095 |

Every business query was written and tested in SQL Server before Power BI was opened. The dashboard reflects the analysis — not the other way around.

---

## Key Findings

### Delivery time predicts customer satisfaction — at every score level

| Review Score | Avg Delivery Time |
|---|---|
| ⭐⭐⭐⭐⭐ 5 stars | 9.22 days |
| ⭐⭐⭐⭐ 4 stars | 10.52 days |
| ⭐⭐⭐ 3 stars | 11.88 days |
| ⭐⭐ 2 stars | 13.15 days |
| ⭐ 1 star | 16.42 days |

The 7-day gap between a 1-star and a 5-star experience holds without exception. What the average doesn't show: the drop from 5-star to 4-star costs only 1.3 days. The drop from 2-star to 1-star costs 3.27 days. The damage concentrates at the tail — orders trending past day 13, not the typical delivery.The average masks where the problem actually lives. Orders past day 13 are the ones collapsing satisfaction — not the typical delivery. That's a targeting problem, not a speed problem.


### Revenue is growing — with one anomaly worth investigating

Month-over-month growth held consistently from January 2017 through mid-2018. November 2017 produced the single largest revenue spike in the dataset. Black Friday demand was real and measurable — and likely under-served if fulfillment was straining at the time.

### Five categories drive the majority of revenue

| Category | Revenue |
|---|---|
| Health & Beauty | $1.4M |
| Watches & Gifts | $1.3M |
| Bed, Bath & Table | $1.2M |
| Sports & Leisure | $1.2M |
| Computers & Accessories | $1.1M |

Everything else is a long tail.

### São Paulo is a dependency, not just a market

SP alone accounts for ~41% of all orders and $5.77M in revenue. The top 5 states (SP, RJ, MG, RS, PR) represent roughly 80% of total business. The remaining 22 states combined make up ~20%. The 91.89% on-time rate is a national average that almost certainly masks worse performance in underserved regions — and geographic concentration of that scale is a risk, not just a metric.

### Seller revenue is heavily concentrated

3,095 active sellers. Average revenue per seller: $5.12K. Top seller: $249K — nearly 49x the average. If the top 50 sellers hold a disproportionate share of total revenue (which this gap implies), retention of that cohort matters more than new seller acquisition. The bottom of the distribution is barely active and likely generating operational costs with negligible return.

---

## How the Analysis Was Built

```
Raw CSVs (8 tables)
    ↓
SQL Server — imported and explored table by table (EDA/)
    ↓
Data quality issues identified and resolved in SQL
    ↓
Master View built — single flat dataset joining all 8 tables (Master_View.sql)
    ↓
6 business questions answered directly in SQL
    ↓
Star schema designed and built as SQL Server views (Star_Schema_Views.sql)
    ↓
Revenue and order counts reconciled between master view and star schema before Power BI connection
    ↓
Power BI connected on top — visualization only
```

Every finding in the dashboard can be traced back to a SQL query. The analysis is fully reproducible without Power BI.

---

## The SQL Work

### Exploratory Data Analysis — 8 Tables

Each table was explored independently before any business query was written: row counts, null checks, duplicate detection, date range validation, distribution of key fields.

Notable data quality issues:
- `order_reviews` had **547 orders with multiple review entries** — conflicting scores that would silently skew any satisfaction metric if left uncleaned
- `freight_value` had nulls requiring handling before any revenue calculation
- Product category names were in Portuguese and required joining a translation table

### The Master View

All 8 tables were joined into a single flat view (`vw_Olist_Master_Data`). The review deduplication issue was resolved using a window function — keeping only the most recent review per order:

```sql
WITH Clean_Review AS (
    SELECT order_id, review_score
    FROM (
        SELECT 
            order_id,
            review_score,
            ROW_NUMBER() OVER(
                PARTITION BY order_id 
                ORDER BY review_creation_date DESC
            ) AS Ranking
        FROM order_reviews
    ) AS RankedReviews
    WHERE Ranking = 1
)
```

### Star Schema — Built in SQL, Not in Power BI

Five views were written in SQL Server before Power BI was opened:

| View | Type | Description |
|---|---|---|
| `vw_Fact_Order_Items` | Fact | Line-level transactions with price and freight |
| `vw_Dim_Orders` | Dimension | Order status, timestamps, review scores |
| `vw_Dim_Products` | Dimension | Product categories (translated to English) |
| `vw_Dim_Sellers` | Dimension | Seller IDs and locations |
| `vw_Dim_Customers` | Dimension | Customer state mapping |

Revenue and order counts were reconciled between the master view and star schema before the Power BI model was built — totals matched within rounding on payment values.

---

## The Dashboard

![Star Schema](Analysis/Star_Schema.png)

Two pages:

Page 1 — Business Overview: Revenue trends, category breakdown, geographic distribution. The kind of view a commercial team would open in a Monday meeting.
Page 2 — Operations & Delivery: Fulfillment performance, delivery time by state, on-time rate. Answers the question: where specifically is delivery failing?
---

## Project Structure

```
📁 Olist-Brazilian-Ecommerce-Analysis
    📁 EDA/                       → One SQL file per source table
    📁 Analysis/
        Master_View.sql           → Joins all 8 tables, handles review deduplication
        Star_Schema_Views.sql     → 5 SQL Server views that feed the Power BI model
        Star_Schema.png           → Data model screenshot
    📁 Dashboard/
        Page1.png                 → Business Overview
        Page2.png                 → Operations & Delivery Performance
        Olist_Dashboard.pbix      → Full Power BI file
    README.md
```

**Tools:** SQL Server (SSMS), T-SQL (CTEs, window functions, aggregations, view creation), Power BI Desktop, DAX, Power Query

---

**Saleh Hossam** — Data Analyst · Cairo, Egypt

[Portfolio](https://saleh-hossam.github.io) · [LinkedIn](https://www.linkedin.com/in/saleh-hossam) · [GitHub](https://github.com/Saleh-Hossam)
