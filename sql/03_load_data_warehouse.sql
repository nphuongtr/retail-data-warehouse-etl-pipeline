-- =====================================================
-- RETAIL DATA WAREHOUSE & AUTOMATED ETL PIPELINE
-- Purpose: Create data warehouse schema
-- =====================================================

-- 1. Create warehouse schema

CREATE SCHEMA IF NOT EXISTS dw

-- 2. Create customer dimension

CREATE TABLE dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id NUMERIC UNIQUE
);

-- 3. Create product dimension

CREATE TABLE dw.dim_product (
	product_key SERIAL PRIMARY KEY,
	stock_code VARCHAR UNIQUE,
	description TEXT
);

-- 4. Create date dimension

CREATE TABLE dw.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE,
    day INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    quarter INTEGER,
    year INTEGER
);

-- 5. Create country dimension

CREATE TABLE dw.dim_country (
	country_key SERIAL PRIMARY KEY,
	country_name VARCHAR UNIQUE
);

-- 6. Create sales fact table

CREATE TABLE dw.fact_sales (
    sales_key BIGSERIAL PRIMARY KEY,
    invoice VARCHAR,
    customer_key INTEGER REFERENCES dw.dim_customer(customer_key),
    product_key INTEGER REFERENCES dw.dim_product(product_key),
    date_key INTEGER REFERENCES dw.dim_date(date_key),
    country_key INTEGER REFERENCES dw.dim_country(country_key),
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    revenue NUMERIC(12,2)
);

-- 7. Verify warehouse tables 

SELECT 
	table_name
FROM information_schema.tables
WHERE table_schema = 'dw'
ORDER BY table_name;

-- 8. Load product dimension

-- 8.1 Check products with multiple descriptions

SELECT
    stock_code,
    COUNT(DISTINCT description) AS description_count
FROM clean_sales
GROUP BY stock_code
HAVING COUNT(DISTINCT description) > 1
ORDER BY description_count DESC
LIMIT 20;


-- 8.2 Inspect descriptions for a product with multiple descriptions

SELECT
    stock_code,
    description,
    COUNT(*) AS occurrence_count
FROM clean_sales
WHERE stock_code = '23191'
GROUP BY stock_code, description
ORDER BY occurrence_count DESC;


-- 8.3 Load product dimension using the most common description

INSERT INTO dw.dim_product (
    stock_code,
    description
)
SELECT
    stock_code,
    description
FROM (
    SELECT
        stock_code,
        description,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY COUNT(*) DESC, description
        ) AS row_num
    FROM clean_sales
    WHERE stock_code IS NOT NULL
    GROUP BY stock_code, description
) AS ranked_products
WHERE row_num = 1;


-- 8.4 Verify product dimension

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT stock_code) AS unique_stock_codes
FROM dw.dim_product;

-- 9. Load customer dimension

INSERT INTO dw.dim_customer (
    customer_id
)
SELECT DISTINCT
    customer_id
FROM clean_sales
WHERE customer_id IS NOT NULL;

-- 9.1 Verify customer dimension

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM dw.dim_customer;


-- 10. Load Country Dimension

-- 10.1 Load unique countries

INSERT INTO dw.dim_country (
    country_name
)
SELECT DISTINCT
    country
FROM clean_sales
WHERE country IS NOT NULL;


-- 10.2 Verify country dimension

SELECT
    COUNT(*) AS total_countries,
    COUNT(DISTINCT country_name) AS unique_countries
FROM dw.dim_country

-- 11. Load Date Dimension

-- 11.1 Load unique transaction dates

INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day,
    month,
    month_name,
    quarter,
    year
)
SELECT DISTINCT
    TO_CHAR(invoice_date::DATE, 'YYYYMMDD')::INTEGER,
    invoice_date::DATE,
    EXTRACT(DAY FROM invoice_date)::INTEGER,
    EXTRACT(MONTH FROM invoice_date)::INTEGER,
    TO_CHAR(invoice_date, 'Month'),
    EXTRACT(QUARTER FROM invoice_date)::INTEGER,
    EXTRACT(YEAR FROM invoice_date)::INTEGER
FROM clean_sales
WHERE invoice_date IS NOT NULL;


-- 11.2 Verify date dimension

SELECT
    COUNT(*) AS total_dates,
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date
FROM dw.dim_date;

-- 12. Check Dimension Key Matching

SELECT
    COUNT(*) AS total_source_rows,
    COUNT(p.product_key) AS matched_products,
    COUNT(c.customer_key) AS matched_customers,
    COUNT(co.country_key) AS matched_countries,
    COUNT(d.date_key) AS matched_dates
FROM clean_sales s
LEFT JOIN dw.dim_product p
    ON s.stock_code = p.stock_code
LEFT JOIN dw.dim_customer c
    ON s.customer_id = c.customer_id
LEFT JOIN dw.dim_country co
    ON s.country = co.country_name
LEFT JOIN dw.dim_date d
    ON s.invoice_date::DATE = d.full_date;

-- 13. Load Fact Sales

INSERT INTO dw.fact_sales (
    invoice,
    customer_key,
    product_key,
    date_key,
    country_key,
    quantity,
    unit_price,
    revenue
)
SELECT
    s.invoice,
    c.customer_key,
    p.product_key,
    d.date_key,
    co.country_key,
    s.quantity,
    s.price,
    s.quantity * s.price
FROM clean_sales s
LEFT JOIN dw.dim_customer c
    ON s.customer_id = c.customer_id
LEFT JOIN dw.dim_product p
    ON s.stock_code = p.stock_code
LEFT JOIN dw.dim_date d
    ON s.invoice_date::DATE = d.full_date
LEFT JOIN dw.dim_country co
    ON s.country = co.country_name;

-- 14. Verify Fact Sales

SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT invoice) AS total_invoices,
    SUM(quantity) AS total_items,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(*) FILTER (
        WHERE customer_key IS NULL
    ) AS transactions_without_customer
FROM dw.fact_sales;

