-- =====================================================
-- RETAIL DATA WAREHOUSE & AUTOMATED ETL PIPELINE
-- Purpose: Profile cleaned sales data
-- =====================================================

-- 1. Preview sample records

SELECT *
FROM clean_sales
LIMIT 10;


-- 2. Check missing values

SELECT
    COUNT(*) FILTER (WHERE invoice IS NULL) AS missing_invoice,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS missing_stock_code,
    COUNT(*) FILTER (WHERE invoice_date IS NULL) AS missing_invoice_date,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE country IS NULL) AS missing_country
FROM clean_sales;


-- 3. Check duplicate records

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        invoice,
        stock_code,
        invoice_date,
        customer_id
    )) AS unique_transaction_lines
FROM clean_sales;

-- 3.1 Investigate repeated transaction lines

SELECT
    invoice,
    stock_code,
    invoice_date,
    customer_id,
    COUNT(*) AS occurrence_count
FROM clean_sales
GROUP BY
    invoice,
    stock_code,
    invoice_date,
    customer_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 20;

-- 3.2 Check identical transaction records

SELECT
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country,
    COUNT(*) AS occurrence_count
FROM clean_sales
GROUP BY
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 20;


-- 4. Check unusual quantities and prices

SELECT
    COUNT(*) FILTER (WHERE quantity <= 0) AS non_positive_quantity,
    COUNT(*) FILTER (WHERE price <= 0) AS non_positive_price
FROM clean_sales;

-- 5. Check for exact duplicate records

SELECT
    COUNT(*) AS duplicate_groups,
    SUM(record_count - 1) AS duplicate_records
FROM (
    SELECT COUNT(*) AS record_count
    FROM clean_sales
    GROUP BY
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
) AS duplicates;