import json
import os
import sys
import requests
import snowflake.connector

# ==========================================
# 1. CONFIGURATION
# ==========================================
YNAB_API_KEY = os.environ.get("YNAB_API_KEY")
YNAB_BUDGET_ID = os.environ.get("YNAB_BUDGET_ID", "last-used")

SNOWFLAKE_CONFIG = {
    "user": os.environ.get("SNOWFLAKE_USER"),
    "password": os.environ.get("SNOWFLAKE_PASSWORD"),
    "account": os.environ.get("SNOWFLAKE_ACCOUNT"),
    "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
    "database": os.environ.get("SNOWFLAKE_DATABASE", "PERSONAL_FINANCE"),
    "schema": os.environ.get("SNOWFLAKE_SCHEMA", "RAW"),
}

YNAB_BASE_URL = "https://api.ynab.com/v1"
HEADERS = {
    "Authorization": f"Bearer {YNAB_API_KEY}",
    "Accept": "application/json",
}


# ==========================================
# 2. YNAB API FETCH FUNCTIONS
# ==========================================
def fetch_ynab_endpoint(endpoint: str) -> dict:
    """Fetch raw JSON payload from a specific YNAB endpoint."""
    url = f"{YNAB_BASE_URL}/budgets/{YNAB_BUDGET_ID}/{endpoint}"
    print(f"Fetching YNAB data from: {url}")

    response = requests.get(url, headers=HEADERS)
    if response.status_code != 200:
        print(f"Error fetching {endpoint}: {response.status_code} - {response.text}")
        sys.exit(1)

    return response.json()


# ==========================================
# 3. SNOWFLAKE LOAD FUNCTIONS
# ==========================================
def init_snowflake_environment(cursor):
    """Ensure database, schema, and raw target table exist in Snowflake."""
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {SNOWFLAKE_CONFIG['database']};")
    cursor.execute(f"USE DATABASE {SNOWFLAKE_CONFIG['database']};")
    cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {SNOWFLAKE_CONFIG['schema']};")
    cursor.execute(f"USE SCHEMA {SNOWFLAKE_CONFIG['schema']};")

    # Raw landing table with VARIANT columns for raw JSON storage
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS RAW_YNAB_PAYLOADS (
        ENDPOINT_NAME VARCHAR(100),
        EXTRACTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
        PAYLOAD VARIANT
    );
    """
    cursor.execute(create_table_sql)
    print("Snowflake target table 'RAW_YNAB_PAYLOADS' is ready.")


def load_payload_to_snowflake(cursor, endpoint_name: str, data: dict):
    """Insert JSON payload directly into Snowflake as a VARIANT object."""
    json_string = json.dumps(data)

    # Use PARSE_JSON to safely store the raw payload into a VARIANT column
    insert_sql = """
    INSERT INTO RAW_YNAB_PAYLOADS (ENDPOINT_NAME, PAYLOAD)
    SELECT %s, PARSE_JSON(%s);
    """
    cursor.execute(insert_sql, (endpoint_name, json_string))
    print(f"Successfully loaded '{endpoint_name}' payload into Snowflake.")


# ==========================================
# 4. MAIN EXECUTION PIPELINE
# ==========================================
def main():
    if not YNAB_API_KEY or not SNOWFLAKE_CONFIG["user"]:
        print("Error: Missing required environment variables. Please check your settings.")
        sys.exit(1)

    # Step 1: Extract data from YNAB REST API
    endpoints_to_extract = ["accounts", "categories", "transactions"]
    extracted_data = {}

    for endpoint in endpoints_to_extract:
        extracted_data[endpoint] = fetch_ynab_endpoint(endpoint)

    # Step 2: Connect to Snowflake & Load
    print("\nConnecting to Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    cursor = conn.cursor()

    try:
        init_snowflake_environment(cursor)

        for endpoint_name, payload in extracted_data.items():
            load_payload_to_snowflake(cursor, endpoint_name, payload)

        conn.commit()
        print("\nAll YNAB endpoints successfully ingested into Snowflake Raw Layer.")

    except Exception as e:
        print(f"An error occurred during Snowflake execution: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()