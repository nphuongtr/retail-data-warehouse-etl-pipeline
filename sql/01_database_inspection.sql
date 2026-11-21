
-- =====================================================
-- RETAIL DATA WAREHOUSE & AUTOMATED ETL PIPELINE
-- Database: retail_sales
-- Purpose: Inspect existing database structure
-- =====================================================


-- 1. Check existing tables and views

SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- 2. Inspect existing table columns and data types

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- 3. Check the number of cleaned retail transactions

SELECT 
	COUNT(*) AS total_cleaned_transactions
FROM clean_sales;
