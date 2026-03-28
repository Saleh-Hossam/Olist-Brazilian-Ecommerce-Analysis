# Olist Brazilian E-Commerce Analysis

End-to-end analysis of 100K+ real Brazilian e-commerce orders using **SQL Server** and **Power BI**.  
From raw data to a fully interactive business dashboard — covering revenue growth, product performance, geographic distribution, delivery operations, and seller analytics.

---

## Dashboard Preview

![Olist Dashboard](Dashboard/Olist_Dashboard.gif)

---

## Project Structure

```
📁 Olist-Brazilian-Ecommerce-Analysis
    📁 EDA/                        → Exploratory analysis for all 8 source tables
    📁 Analysis/
        Master_View.sql            → Flat master view joining all tables
        Star_Schema_Views.sql      → 5 views powering the Power BI data model
        Star_Schema.png            → Power BI model view screenshot
    📁 Dashboard/
        Page1.png                  → Business Overview page
        Page2.png                  → Operations & Delivery Performance page
        Olist_Dashboard.pbix       → Full interactive Power BI file
    README.md
```

---

## Tools & Technologies

| Layer | Tool |
|---|---|
| Data Storage | SQL Server (SSMS) |
| Data Modeling | Star Schema — 1 Fact + 4 Dims |
| Analysis | T-SQL — CTEs, Window Functions, Aggregations |
| Visualization | Power BI Desktop — DAX, Power Query |

---

## The Dataset

Public Brazilian e-commerce dataset provided by Olist, covering **Sep 2016 – Aug 2018**.

| Table | Description |
|---|---|
| olist_orders | 99,441 orders with status and timestamps |
| olist_order_items | Line items with price and freight |
| olist_order_payments | Payment method and value |
| olist_order_reviews | Customer review scores and comments |
| olist_customers | Customer location data |
| olist_sellers | Seller location data |
| olist_products | Product dimensions and category |
| olist_geolocation | Zip code coordinates |

---

## Business Questions Answered

### BQ1 — Revenue Trend: Is the business growing?
Consistent month-over-month growth from Jan 2017 through mid-2018.  
**Black Friday Nov 2017** produced the single largest revenue spike in the dataset — confirming strong seasonal demand response.

### BQ2 — Product Performance: Which categories drive revenue?
**Health & Beauty leads at $1.4M**, followed by Watches & Gifts ($1.3M) and Bed, Bath & Table ($1.2M).  
The top 5 categories account for the majority of total revenue — clear signal for inventory and marketing prioritization.

### BQ3 — Geography: Where are the customers?
**São Paulo (SP) dominates with ~41% of all orders** and $5.77M in revenue.  
The top 5 states (SP, RJ, MG, RS, PR) represent approximately 80% of total business volume — the rest of Brazil is largely untapped.

### BQ4 — Delivery Operations: How efficient is fulfillment?
**Average delivery time: 12.5 days** across 99K+ orders.  
**On-time rate: 91.89%** — over 9 in 10 orders delivered on or before the estimated date.

### BQ5 — Seller Performance: Who are the top sellers?
Top seller generated **$249K in revenue** across 1,156 items sold.  
Significant performance variance exists across the 3,095 active sellers — average revenue per seller is $5.12K, indicating a long tail of low-volume sellers.

### BQ6 — Review Scores: What drives customer satisfaction?
**Delivery time is the single strongest predictor of review score.**

| Review Score | Avg Delivery Time |
|---|---|
| ⭐⭐⭐⭐⭐ 5 stars | 9.22 days |
| ⭐⭐⭐⭐ 4 stars | 10.52 days |
| ⭐⭐⭐ 3 stars | 11.88 days |
| ⭐⭐ 2 stars | 13.15 days |
| ⭐ 1 star | 16.42 days |

A **7-day gap** between 1-star and 5-star delivery times. Faster delivery = better reviews — consistently, at every score level.

---

## Data Model

Star schema built in Power BI on top of SQL Server views.

![Star Schema](Analysis/Star_Schema.png)

**Relationships:**
- `Fact_Order_Items` → `Dim_Orders` on `order_id`
- `Fact_Order_Items` → `Dim_Products` on `product_id`
- `Fact_Order_Items` → `Dim_Sellers` on `seller_id`
- `Dim_Orders` → `Dim_Customers` on `customer_id`
- `Dim_Date` → `Dim_Orders` on `order_date`

---

## Key Metrics

| Metric | Value |
|---|---|
| Total Revenue | $15.84M |
| Total Orders | 99,441 |
| Total Items Sold | 112,650 |
| Avg Delivery Time | 12.5 days |
| On-Time Rate | 91.89% |
| Avg Review Score | 4.09 / 5 |
| Active Sellers | 3,095 |

---

## Author

**Saleh Hossam** — Junior Data Analyst  
📍 Cairo, Egypt  
[Portfolio](https://saleh-hossam.github.io) · [LinkedIn](https://www.linkedin.com/in/saleh-hossam) · [GitHub](https://github.com/Saleh-Hossam)
