
# =====================================================
# RETAIL DATA WAREHOUSE & AUTOMATED ETL PIPELINE
# File: etl_pipeline.py
# Purpose: Connect to PostgreSQL, extract and transform source data
# =====================================================

import os
import psycopg
import pandas as pd
from dotenv import load_dotenv

# 1. Connect to PostgreSQL
def connect_db():

    load_dotenv()

    conn = psycopg.connect(
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT", "5432"))
    )

    print("\nConnection successful!")

    return conn

# 2. Extract source data
def extract_data(conn):

    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
                invoice,
                stock_code,
                description,
                quantity,
                invoice_date,
                price,
                customer_id,
                country
            FROM clean_sales;
        """)

        rows = cursor.fetchall()
        columns = [column.name for column in cursor.description]

    print("\nExtracted records:", len(rows))

    return rows, columns

# 3. Transform extracted data
def transform_data(df):

    df["invoice_date"] = pd.to_datetime(df["invoice_date"])
    df["price"] = pd.to_numeric(df["price"])
    df["revenue"] = df["quantity"] * df["price"]

    print("\nData after transformation:")
    print(df.head(5).to_string(index=False))

    return df

# 4. Validate transformed data
def validate_data(df):

    print("\nData validation results:")

    # Check invalid quantities
    print("\nInvalid quantities:", (df["quantity"] <= 0).sum())

    # Check invalid prices
    print("Invalid prices:", (df["price"] <= 0).sum())

    # Check missing customer IDs
    print("Missing customer IDs:", df["customer_id"].isnull().sum())

    # Check invalid revenue
    print("Invalid revenue:", (df["revenue"] <= 0).sum())

    # Check missing values
    print("\nMissing values:")
    print(df.isnull().sum())

    # Check duplicate records
    print("\nDuplicate records:", df.duplicated().sum())

    # Check data types
    print("\nData types:")
    print(df.dtypes)

    # Check total revenue
    print("\nTotal revenue:", round(df["revenue"].sum(), 2))

# 5. Investigate duplicate records
def investigate_duplicates(df):

    duplicate_rows = df[df.duplicated(keep=False)]

    print("\nDuplicate record samples:")
    print(duplicate_rows.head(10).to_string(index=False))

    print("\nTotal duplicate rows:", df.duplicated().sum())

# 6. Check existing data warehouse records
def check_warehouse_records(conn):

    print("\nExisting data warehouse records:")

    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT COUNT(*) FROM dw.dim_customer;
        """)
        print("Customers:", cursor.fetchone()[0])

        cursor.execute("""
            SELECT COUNT(*) FROM dw.dim_product;
        """)
        print("Products:", cursor.fetchone()[0])

        cursor.execute("""
            SELECT COUNT(*) FROM dw.dim_country;
        """)
        print("Countries:", cursor.fetchone()[0])

        cursor.execute("""
            SELECT COUNT(*) FROM dw.dim_date;
        """)
        print("Dates:", cursor.fetchone()[0])

        cursor.execute("""
            SELECT COUNT(*) FROM dw.fact_sales;
        """)
        print("Fact sales:", cursor.fetchone()[0])

# 7. Load customer dimension
def load_customer_dimension(conn):

    print("\nLoading customer dimension...")

    with conn.cursor() as cursor:
        cursor.execute("""
            INSERT INTO dw.dim_customer (customer_id)
            SELECT DISTINCT customer_id
            FROM clean_sales
            WHERE customer_id IS NOT NULL
            ON CONFLICT (customer_id) DO NOTHING;
        """)

        print("New customers inserted:", cursor.rowcount)

# 8. Load product dimension
def load_product_dimension(conn):

    print("\nLoading product dimension...")

    with conn.cursor() as cursor:
        cursor.execute("""
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
            WHERE row_num = 1
            ON CONFLICT (stock_code) DO NOTHING;
        """)

        print("New products inserted:", cursor.rowcount)

# 9. Load country dimension
def load_country_dimension(conn):

    print("\nLoading country dimension...")

    with conn.cursor() as cursor:
        cursor.execute("""
            INSERT INTO dw.dim_country (country_name)
            SELECT DISTINCT country
            FROM clean_sales
            WHERE country IS NOT NULL
            ON CONFLICT (country_name) DO NOTHING;
        """)

        print("New countries inserted:", cursor.rowcount)

# 10. Load date dimension
def load_date_dimension(conn):

    print("\nLoading date dimension...")

    with conn.cursor() as cursor:
        cursor.execute("""
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
                TRIM(TO_CHAR(invoice_date, 'Month')),
                EXTRACT(QUARTER FROM invoice_date)::INTEGER,
                EXTRACT(YEAR FROM invoice_date)::INTEGER
            FROM clean_sales
            WHERE invoice_date IS NOT NULL
            ON CONFLICT (date_key) DO NOTHING;
        """)

        print("New dates inserted:", cursor.rowcount)

# 11. Refresh fact table
def refresh_fact_table(conn):

    print("\nRefreshing fact table...")

    with conn.cursor() as cursor:

        # Remove existing fact records
        cursor.execute("""
            DELETE FROM dw.fact_sales;
        """)

        deleted_rows = cursor.rowcount
        print("Existing fact records deleted:", deleted_rows)

        # Load sales transactions with dimension keys
        cursor.execute("""
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
        """)

        print("New fact records inserted:", cursor.rowcount)

# 12. Main pipeline
def main():

    conn = None

    try:
        conn = connect_db()

        # 1. Count source records
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT COUNT(*)
                FROM clean_sales;
            """)

            total_rows = cursor.fetchone()[0]

        print("Total source records:", total_rows)

        # 2. Extract all source records
        rows, columns = extract_data(conn)

        # 3. Convert records into a DataFrame
        df = pd.DataFrame(rows, columns=columns)

        print("\nDataFrame dimensions:", df.shape)
        print("\nExtracted data sample:")
        print(df.head(5).to_string(index=False))

        # 4. Transform extracted data
        df = transform_data(df)

        # 5. Validate transformed data
        validate_data(df)

        # 6. Investigate duplicate records
        investigate_duplicates(df)

        # 7. Check existing data warehouse records
        check_warehouse_records(conn)

        # 8. Load customer dimension
        load_customer_dimension(conn)

        # 9. Load product dimension
        load_product_dimension(conn)

        # 10. Load country dimension
        load_country_dimension(conn)

        # 11. Load date dimension
        load_date_dimension(conn)

        # 12. Refresh fact table
        refresh_fact_table(conn)

        conn.commit()
        print("Fact table refresh committed successfully.")

    except Exception as error:
        print("\nETL pipeline failed:", error)

        if conn is not None:
            conn.rollback()

    finally:
        if conn is not None and not conn.closed:
            conn.close()
            print("\nDatabase connection closed.")

# Run the ETL pipeline
if __name__ == "__main__":
    main()