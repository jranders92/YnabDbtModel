import json
import os
import sys
import requests
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

# ==========================================
# 1. CONFIGURATION
# ==========================================
FRED_API_KEY = os.environ.get("FRED_API_KEY")

SNOWFLAKE_CONFIG = {
    "user": os.environ.get("SNOWFLAKE_USER"),
    "password": os.environ.get("SNOWFLAKE_PASSWORD"),
    "account": os.environ.get("SNOWFLAKE_ACCOUNT"),
    "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
    "database": os.environ.get("SNOWFLAKE_DATABASE", "PERSONAL_FINANCE"),
    "schema": os.environ.get("SNOWFLAKE_SCHEMA", "RAW"),
    "role": os.environ.get("SNOWFLAKE_ROLE", "fred_ingestion_role"),
}

FRED_BASE_URL = "https://api.stlouisfed.org/fred"

# Key Macro Economic Series IDs to fetch:
# - CPIUFDSL: Consumer Price Index - Food at Home (Groceries)
# - GASREGW: Regular Gasoline Retail Prices
# - CUUR0000SEHA: Consumer Price Index - Primary Rent
# - SP500: S&P 500 Index
SERIES_IDS = [
    "CPIUFDSL",
    "GASREGW",
    "CUUR0000SEHA",
    "SP500"
]


# ==========================================
# 2. FRED API FETCH FUNCTIONS
# ==========================================
def fetch_fred_endpoint(endpoint: str, series_id: str, extra_params: dict = None) -> dict:
    """Fetch raw JSON payload from a specific FRED API endpoint."""
    url = f"{FRED_BASE_URL}/{endpoint}"
    
    params = {
        "series_id": series_id,
        "api_key": FRED_API_KEY,
        "file_type": "json"
    }
    if extra_params:
        params.update(extra_params)

    print(f"Fetching FRED data for series '{series_id}' from endpoint: {endpoint}")

    response = requests.get(url, params=params)
    if response.status_code != 200:
        print(f"Error fetching {endpoint} for {series_id}: {response.status_code} - {response.text}")
        sys.exit(1)

    return response.json()


# ==========================================
# 3. SNOWFLAKE LOAD FUNCTIONS
# ==========================================
def init_snowflake_environment(cursor):
    """Ensure database, schema, and raw target table exist in Snowflake."""
    cursor.execute(f"USE ROLE {SNOWFLAKE_CONFIG['role']};")
    cursor.execute(f"USE DATABASE {SNOWFLAKE_CONFIG['database']};")
    cursor.execute(f"USE SCHEMA {SNOWFLAKE_CONFIG['schema']};")

    # Raw landing table with VARIANT columns for raw FRED JSON storage
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS RAW_FRED_PAYLOADS (
        SERIES_ID VARCHAR(50),
        ENDPOINT_NAME VARCHAR(100),
        EXTRACTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
        PAYLOAD VARIANT
    );
    """
    cursor.execute(create_table_sql)
    print("Snowflake target table 'RAW_FRED_PAYLOADS' is ready.")


def load_payload_to_snowflake(cursor, series_id: str, endpoint_name: str, data: dict):
    """Insert JSON payload directly into Snowflake as a VARIANT object."""
    json_string = json.dumps(data)

    # Use PARSE_JSON to safely store the raw payload into a VARIANT column
    insert_sql = """
    INSERT INTO RAW_FRED_PAYLOADS (SERIES_ID, ENDPOINT_NAME, PAYLOAD)
    SELECT %s, %s, PARSE_JSON(%s);
    """
    cursor.execute(insert_sql, (series_id, endpoint_name, json_string))
    print(f"Successfully loaded '{series_id}' ({endpoint_name}) payload into Snowflake.")


# ==========================================
# 4. MAIN EXECUTION PIPELINE
# ==========================================
def main():
    if not FRED_API_KEY or not SNOWFLAKE_CONFIG["user"]:
        print("Error: Missing required environment variables (FRED_API_KEY or SNOWFLAKE_USER). Check your .env file.")
        sys.exit(1)

    # Step 1: Extract data from FRED REST API
    # We fetch both metadata (series info) and the observations (the actual data points)
    extracted_payloads = []

    for series_id in SERIES_IDS:
        # Fetch Metadata
        metadata_payload = fetch_fred_endpoint("series", series_id)
        extracted_payloads.append({
            "series_id": series_id,
            "endpoint_name": "series_metadata",
            "payload": metadata_payload
        })

        # Fetch Observations (Data points from 2020 onward)
        observations_payload = fetch_fred_endpoint(
            "series/observations", 
            series_id, 
            extra_params={"observation_start": "2020-01-01"}
        )
        extracted_payloads.append({
            "series_id": series_id,
            "endpoint_name": "series_observations",
            "payload": observations_payload
        })

    # Step 2: Connect to Snowflake & Load
    print("\nConnecting to Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    cursor = conn.cursor()

    try:
        init_snowflake_environment(cursor)

        for item in extracted_payloads:
            load_payload_to_snowflake(
                cursor, 
                series_id=item["series_id"], 
                endpoint_name=item["endpoint_name"], 
                data=item["payload"]
            )

        conn.commit()
        print("\nAll FRED endpoints successfully ingested into Snowflake Raw Layer.")

    except Exception as e:
        print(f"An error occurred during Snowflake execution: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()