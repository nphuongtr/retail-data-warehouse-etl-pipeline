# Data Dictionary
## Retail Data Warehouse & Automated ETL Pipeline

This document describes the structure, columns, data types, and relationships of the PostgreSQL retail data warehouse.

The warehouse follows a dimensional model consisting of four dimension tables and one central fact table.

## 1. Warehouse Overview

| Table | Description |
|---|---|
| `dw.dim_customer` | Stores unique customer identifiers |
| `dw.dim_product` | Stores unique products and their descriptions |
| `dw.dim_date` | Stores calendar attributes for transaction dates |
| `dw.dim_country` | Stores unique country names |
| `dw.fact_sales` | Stores individual retail transaction-line records |

## 2. Dimension Tables

### 2.1 Customer Dimension — `dw.dim_customer`

Stores unique customer identifiers used to analyze purchasing behavior.

| Column | Data Type | Key / Constraint | Description |
|---|---|---|---|
| `customer_key` | SERIAL (INTEGER) | Primary Key | Unique warehouse identifier for each customer |
| `customer_id` | NUMERIC | UNIQUE | Original customer identifier from the source dataset |

### 2.2 Product Dimension — `dw.dim_product`

Stores unique products based on their stock codes and descriptions.

| Column | Data Type | Key / Constraint | Description |
|---|---|---|---|
| `product_key` | SERIAL (INTEGER) | Primary Key | Unique warehouse identifier for each product |
| `stock_code` | VARCHAR | UNIQUE | Original stock code identifying a product |
| `description` | TEXT | — | Product description; the most common description is selected when a stock code has multiple descriptions |

### 2.3 Date Dimension — `dw.dim_date`

Stores calendar information for transaction dates and supports time-based analysis.

| Column | Data Type | Key / Constraint | Description |
|---|---|---|---|
| `date_key` | INTEGER | Primary Key | Date identifier in YYYYMMDD format |
| `full_date` | DATE | UNIQUE | Complete calendar date |
| `day` | INTEGER | — | Day of the month |
| `month` | INTEGER | — | Month number (1–12) |
| `month_name` | VARCHAR(20) | — | Full month name |
| `quarter` | INTEGER | — | Calendar quarter (1–4) |
| `year` | INTEGER | — | Calendar year |

### 2.4 Country Dimension — `dw.dim_country`

Stores unique country names associated with retail transactions.

| Column | Data Type | Key / Constraint | Description |
|---|---|---|---|
| `country_key` | SERIAL (INTEGER) | Primary Key | Unique warehouse identifier for each country |
| `country_name` | VARCHAR | UNIQUE | Country name from the source dataset |

## 3. Fact Table

### Sales Fact — `dw.fact_sales`

Stores individual retail transaction-line records and connects sales data to the four dimension tables.

**Grain:** One row represents one transaction line from the cleaned source dataset.

| Column | Data Type | Key / Constraint | Description |
|---|---|---|---|
| `sales_key` | BIGSERIAL (BIGINT) | Primary Key | Unique identifier for each sales record |
| `invoice` | VARCHAR | — | Invoice number associated with the transaction |
| `customer_key` | INTEGER | Foreign Key | References `dw.dim_customer.customer_key` |
| `product_key` | INTEGER | Foreign Key | References `dw.dim_product.product_key` |
| `date_key` | INTEGER | Foreign Key | References `dw.dim_date.date_key` |
| `country_key` | INTEGER | Foreign Key | References `dw.dim_country.country_key` |
| `quantity` | INTEGER | — | Number of units purchased |
| `unit_price` | NUMERIC(10,2) | — | Price per unit |
| `revenue` | NUMERIC(12,2) | — | Transaction-line revenue, calculated as quantity multiplied by unit price |

## 4. Table Relationships

The fact table connects to each dimension table through foreign keys.

| Fact Table Column | Referenced Dimension | Relationship |
|---|---|---|
| `customer_key` | `dw.dim_customer.customer_key` | Many-to-One |
| `product_key` | `dw.dim_product.product_key` | Many-to-One |
| `date_key` | `dw.dim_date.date_key` | Many-to-One |
| `country_key` | `dw.dim_country.country_key` | Many-to-One |

Each dimension can be associated with multiple sales records, while each fact record references at most one record from each dimension.

## 5. Important Data Handling Rules

- **Customer identifiers:** Missing customer IDs are retained as NULL customer keys in the fact table.
- **Product descriptions:** When a stock code has multiple descriptions, the most frequently occurring description is selected for the product dimension.
- **Date keys:** Date keys are generated using the YYYYMMDD format.
- **Revenue calculation:** Transaction-line revenue is calculated using `quantity * unit_price`.
- **Duplicate records:** Duplicate source records are identified during data profiling and are not automatically removed.
- **Referential integrity:** Foreign keys connect the fact table to the dimension tables.

## 6. Analytical Data Marts

The project includes four PostgreSQL views that aggregate warehouse data into business-focused datasets for reporting and analysis.

These views are created from the central fact table and relevant dimension tables.

### 6.1 Monthly Sales Data Mart — `dw.mart_monthly_sales`

Aggregates sales performance by year and month to support time-series analysis.

| Column | Source / Calculation | Description |
|---|---|---|
| `year` | `dim_date.year` | Calendar year |
| `month` | `dim_date.month` | Month number (1–12) |
| `month_name` | `TRIM(dim_date.month_name)` | Month name |
| `total_invoices` | `COUNT(DISTINCT invoice)` | Number of unique invoices |
| `total_items` | `SUM(quantity)` | Total items sold |
| `total_revenue` | `ROUND(SUM(revenue), 2)` | Total revenue for the month |

**Grouping:** Year and month.

### 6.2 Country Sales Data Mart — `dw.mart_country_sales`

Aggregates sales performance by country to compare geographic markets.

| Column | Source / Calculation | Description |
|---|---|---|
| `country_name` | `dim_country.country_name` | Country name |
| `total_invoices` | `COUNT(DISTINCT invoice)` | Number of unique invoices |
| `total_items` | `SUM(quantity)` | Total items sold |
| `total_revenue` | `ROUND(SUM(revenue), 2)` | Total revenue by country |

**Grouping:** Country.

### 6.3 Product Sales Data Mart — `dw.mart_product_sales`

Aggregates sales performance by product to identify top-selling and highest-revenue products.

| Column | Source / Calculation | Description |
|---|---|---|
| `stock_code` | `dim_product.stock_code` | Unique product stock code |
| `description` | `dim_product.description` | Product description |
| `total_quantity_sold` | `SUM(quantity)` | Total units sold |
| `total_invoices` | `COUNT(DISTINCT invoice)` | Number of unique invoices containing the product |
| `total_revenue` | `ROUND(SUM(revenue), 2)` | Total revenue generated by the product |

**Grouping:** Product stock code and description.

### 6.4 Customer Sales Data Mart — `dw.mart_customer_sales`

Aggregates sales performance by customer to analyze purchasing activity and customer contribution to revenue.

| Column | Source / Calculation | Description |
|---|---|---|
| `customer_id` | `dim_customer.customer_id` | Original customer identifier |
| `total_invoices` | `COUNT(DISTINCT invoice)` | Number of unique invoices |
| `total_items` | `SUM(quantity)` | Total items purchased |
| `total_revenue` | `ROUND(SUM(revenue), 2)` | Total revenue generated by the customer |

**Grouping:** Customer ID.

**Note:** Because this view uses an INNER JOIN to the customer dimension, transactions without a matching customer ID are excluded from this customer-level data mart. They remain in the central fact table.

## 7. Warehouse Summary

| Component | Number of Tables / Views | Records |
|---|---:|---:|
| Dimension tables | 4 | 11,441 |
| Fact table | 1 | 1,041,652 |
| Analytical data mart views | 4 | Varies by aggregation |
 
The warehouse provides a structured foundation for SQL analysis, analytical reporting, Python ETL processing, and Power BI dashboards.