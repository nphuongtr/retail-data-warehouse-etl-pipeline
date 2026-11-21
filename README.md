# Retail Data Warehouse & Automated ETL Pipeline

## Project Overview

This project builds an end-to-end retail data analytics solution using PostgreSQL, Python, and Power BI. The goal is to transform raw retail transaction data into a structured data warehouse, automate the ETL process, and develop business-focused data marts and dashboards.

The project demonstrates how raw transactional data can be extracted, cleaned, transformed, validated, and organized to support business reporting and decision-making.

## Business Objectives

- Build a centralized retail data warehouse using a dimensional model.
- Automate data extraction, transformation, and loading (ETL) with Python.
- Create analytical data marts for sales, products, customers, and countries.
- Analyze revenue trends and retail performance.
- Develop an interactive Power BI dashboard to communicate business insights.

## Technology Stack

| Technology | Purpose |
|---|---|
| PostgreSQL 18 | Data storage, SQL transformations, and data warehouse |
| Python | Automated ETL pipeline and data validation |
| SQL | Data profiling, cleaning, dimensional modeling, and data marts |
| Power BI Service | Data visualization and business reporting |
| Git & GitHub | Version control and project documentation |

## Dataset

The project uses two retail transaction CSV files covering December 2009 through December 2011.

The combined dataset contains more than one million transaction records.

### Data Processing

The data preparation process included:

- Inspecting the source data and profiling data quality.
- Identifying missing customer IDs.
- Detecting duplicate transaction records.
- Preparing data for dimensional modeling.
- Validating records and calculations during the ETL process.

Missing customer IDs were retained as NULL customer keys in the fact table rather than being assigned to an incorrect customer.

Duplicate records were identified during profiling and were not automatically removed.

## Data Warehouse Architecture

The warehouse uses a dimensional model with a central fact table and four dimension tables.

### Dimension Tables

| Table | Records | Description |
|---|---:|---|
| `dw.dim_customer` | 5,878 | Customer information |
| `dw.dim_product` | 4,916 | Product information |
| `dw.dim_date` | 604 | Date dimension |
| `dw.dim_country` | 43 | Country information |

### Fact Table

`dw.fact_sales`

Contains 1,041,652 transaction records and connects sales transactions to the dimension tables.

## Python ETL Pipeline

The automated ETL pipeline is implemented in:

`python/etl_pipeline.py`

The pipeline follows three main stages:

1. **Extract:** Reads the source retail CSV files.
2. **Transform:** Processes and prepares transaction data for the warehouse.
3. **Load:** Loads dimension and fact data into PostgreSQL.

The pipeline also includes validation steps to check the data before committing changes.

The code was organized into modular functions to make the process easier to maintain, test, and reuse.

## Data Marts

Four analytical data marts were created to support business reporting.

| Data Mart | Purpose |
|---|---|
| `dw.mart_monthly_sales` | Monthly sales performance and trends |
| `dw.mart_country_sales` | Revenue and sales performance by country |
| `dw.mart_product_sales` | Product-level sales performance |
| `dw.mart_customer_sales` | Customer-level purchasing behavior |

These data marts provide aggregated information for business analysis and Power BI reporting.

## Key Business Metrics

The completed warehouse contains the following results:

| Metric | Result |
|---|---:|
| Total transactions in fact table | 1,041,652 |
| Total items sold | 11,420,287 |
| Total revenue | £20,972,594.55 |
| Total invoices | 40,077 |
| Average order value | £523.31 |

### Key Business Insights

- The United Kingdom generated approximately 85.21% of total revenue.
- The top 1,801 frequent customers accounted for approximately 80.18% of total revenue.
- The top 10 products generated approximately £2.12 million, representing 10.11% of total revenue.

These findings highlight the importance of the UK market, customer retention, and product-level sales analysis.

## Power BI Dashboard

The Power BI dashboard includes:

- KPI cards for total revenue, items sold, and invoices.
- Monthly revenue trend analysis.
- Monthly items sold analysis.
- Top 10 countries by revenue.
- Top 10 products by revenue.
- Top 10 customers by revenue.

### Dashboard Report

[View Retail Sales Performance Dashboard (PDF)](reports/Retail_Sales_Performance.pdf)

## Project Structure

```text
online-retail-sales-analysis/
│
├── data/
│   ├── online_retail_2009_2010.csv
│   ├── online_retail_2010_2011.csv
│   ├── monthly_sales.csv
│   ├── country_sales.csv
│   ├── product_sales.csv
│   └── customer_sales.csv
│
├── python/
│   └── etl_pipeline.py
│
├── sql/
│   ├── 01_database_inspection.sql
│   ├── 02_data_profiling.sql
│   ├── 03_load_data_warehouse.sql
│   └── 04_create_data_marts.sql
│
├── reports/
│   └── Retail_Sales_Performance.pdf
│
├── .gitignore
└── README.md
```

## How to Run the Project

### 1. Clone the repository

```bash
git clone https://github.com/nphuongtr/online-retail-sales-analysis.git

cd online-retail-sales-analysis
```

### 2. Set up PostgreSQL

Create the PostgreSQL database and configure the required database connection settings.

### 3. Prepare the environment

Install the Python dependencies required by the ETL pipeline and configure the database connection using environment variables.

Keep credentials in `.env` and do not commit sensitive information to GitHub.

### 4. Run SQL scripts

Execute the SQL scripts in the appropriate order to inspect the database, profile the data, build the warehouse, and create analytical data marts.

### 5. Run the ETL pipeline

```bash
python python/etl_pipeline.py
```

### 6. Explore the Power BI dashboard

Connect Power BI to the prepared analytical data and explore the retail sales performance visuals.

## Skills Demonstrated

- SQL querying and data transformation
- PostgreSQL database management
- Dimensional data warehouse design
- Python ETL development
- Data quality profiling and validation
- Data aggregation and business analysis
- Power BI dashboard development
- Git and GitHub project management

## Conclusion

This project demonstrates an end-to-end analytics workflow, from raw transaction data to a structured data warehouse and business intelligence dashboard.

By combining SQL, Python, and Power BI, the solution transforms large volumes of retail transaction data into meaningful business insights that support sales performance analysis and decision-making.