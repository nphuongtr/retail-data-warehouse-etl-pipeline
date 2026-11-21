-- =====================================================
-- RETAIL DATA WAREHOUSE & AUTOMATED ETL PIPELINE
-- Purpose: Create business-focused data marts
-- =====================================================

-- 15. Create Monthly Sales Data Mart

-- 15.1 Aggregate sales by year and month

CREATE OR REPLACE VIEW dw.mart_monthly_sales AS
SELECT
    d.year,
    d.month,
    TRIM(d.month_name) AS month_name,
    COUNT(DISTINCT f.invoice) AS total_invoices,
    SUM(f.quantity) AS total_items,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_date d
    ON f.date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name

-- 15.2 Verify monthly sales data mart

SELECT *
FROM dw.mart_monthly_sales
ORDER BY year, month

-- 16. Create Country Sales Data Mart

-- 16.1 Aggregate sales by country

CREATE OR REPLACE VIEW dw.mart_country_sales AS
SELECT
    co.country_name,
    COUNT(DISTINCT f.invoice) AS total_invoices,
    SUM(f.quantity) AS total_items,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_country co
    ON f.country_key = co.country_key
GROUP BY
    co.country_name;

-- 16.2 Verify country sales data mart

SELECT *
FROM dw.mart_country_sales
ORDER BY total_revenue DESC;

-- 17. Create Product Sales Data Mart

-- 17.1 Aggregate sales by product

CREATE OR REPLACE VIEW dw.mart_product_sales AS
SELECT
    p.stock_code,
    p.description,
    SUM(f.quantity) AS total_quantity_sold,
    COUNT(DISTINCT f.invoice) AS total_invoices,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.stock_code,
    p.description;

-- 17.2 Verify product sales data mart

SELECT *
FROM dw.mart_product_sales
ORDER BY total_revenue DESC
LIMIT 20


-- 18. Create Customer Sales Data Mart

-- 18.1 Aggregate sales by customer

CREATE OR REPLACE VIEW dw.mart_customer_sales AS
SELECT
    c.customer_id,
    COUNT(DISTINCT f.invoice) AS total_invoices,
    SUM(f.quantity) AS total_items,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id;

-- 18.2 Verify customer sales data mart

SELECT *
FROM dw.mart_customer_sales
ORDER BY total_revenue DESC
LIMIT 20;

-- 19. Verify Data Mart Views

SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'dw'
  AND table_type = 'VIEW'
ORDER BY table_name;
