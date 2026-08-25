# YNAB Personal Finance dbt Project

A personal finance analytics pipeline that ingests data from the [YNAB API](https://api.youneedabudget.com/) and [FRED (Federal Reserve Economic Data)](https://fred.stlouisfed.org/docs/api/fred/) into Snowflake, then transforms it using dbt into analytical models for budgeting, spending, and macroeconomic comparison for gas spending. Roles are created for ingestion, dbt usage, and for analysts.

---

## Architecture Overview

```
YNAB API ──────────────────────────────────────────────────────────────────┐
                                                                            │
                                                                            ▼
                                                              Snowflake RAW Schema
FRED API ──────────────────────────────────────────────────► (raw_ynab_payloads,
  (CPI, Gas, Rent, S&P 500)                                   raw_fred_payloads)
                                                                            │
                                                                            ▼
                                                              dbt Staging Layer
                                                              (stg_ynab_*, stg_fred_*)
                                                                            │
                                                                            ▼
                                                              dbt Marts Layer
                                                              (dim_*, fct_*)
                                                                            │
                                                                            ▼
                                                           dbt Reporting Layer
                                                           (rpt_* analyst views)
                                                                            │
                                                                            ▼
                                                            dbt Snapshot Layer
                                                            (snp_* SCD Type 2)
```

---

## Data Sources

| Source | Description | Ingestion Script |
|--------|-------------|-----------------|
| YNAB API | Personal budget data — accounts, categories, transactions | `api_seed/ynab_to_snowflake.py` |
| FRED API | Macroeconomic series — groceries, rent, gas, and the S&P 500 | `api_seed/fred_to_snowflake.py` |

### FRED Series Tracked

| Series ID | Description | Frequency |
|-----------|-------------|-----------|
| `CPIUFDSL` | Consumer Price Index — Food at Home (Groceries) | Monthly |
| `GASREGW` | US Regular Gasoline Retail Prices | Weekly |
| `CUUR0000SEHA` | Consumer Price Index — Primary Rent | Monthly |
| `SP500` | S&P 500 Market Index | Daily |

---

## Project Structure

```
YnabDbtModel/
├── api_seed/                        # Python ingestion scripts
│   ├── ynab_to_snowflake.py         # Extracts YNAB API → Snowflake RAW
│   └── fred_to_snowflake.py         # Extracts FRED API → Snowflake RAW
├── ynab_dbt/                        # dbt project root
│   ├── models/
│   │   ├── staging/raw/
│   │   │   ├── ynab/                # Staging models for YNAB source data
│   │   │   └── fred/                # Staging models for FRED source data
│   │   ├── marts/                   # Dimensional and fact models
│   │   └── reporting/               # Analyst-ready reporting views
│   ├── macros/                      # Custom dbt macros
│   ├── seeds/                       # Static reference data (FRED series mapping)
│   └── snapshots/                   # dbt snapshots (SCD Type 2)
└── .github/workflows/               # CI/CD pipelines
```

---

## dbt Models

### Staging Layer

Staging models parse raw JSON `VARIANT` payloads from Snowflake using `LATERAL FLATTEN`, apply type casting, and convert YNAB milliunits to dollars. Materialized as `view` in dev and `ephemeral` in prod.

| Model | Description |
|-------|-------------|
| `stg_ynab_accounts` | Account details, balances, and status flags |
| `stg_ynab_categories` | Category and category group hierarchy with goal metadata |
| `stg_ynab_transactions` | Individual transactions with milliunits → dollar conversion |
| `stg_fred_observations` | Time-series CPI/economic observations per series |
| `stg_fred_series_metadata` | Metadata for each FRED series (title, units, frequency) |

### Marts Layer

Materialized as tables in both dev and prod; `fct_transactions` uses an incremental merge strategy.

| Model | Description |
|-------|-------------|
| `dim_date` | Date dimension from 2023–2030 with calendar attributes |
| `dim_accounts` | Account dimension with asset/liability and liquidity classifications |
| `dim_categories` | Category dimension with expense tier and FRED CPI series mapping |
| `fct_transactions` | Core transaction fact table with inflow/outflow split. Incremental merge on trailing 30 days |
| `fct_monthly_budget_variance` | Monthly budgeted vs. actual spending by category |
| `fct_monthly_gas_inflation` | Personal gas spend vs. FRED national average with YoY comparisons |

### Reporting Layer

Analyst-ready views for dashboards and recurring analysis.

| Model | Description |
|-------|-------------|
| `rpt_current_month_budget` | Current-month budgeted vs. actual spending by category |
| `rpt_categories_approaching_overspend` | Categories at 80% or more of their monthly budget |
| `rpt_net_worth_snapshot` | Current balances grouped by accounting type and liquidity tier |
| `rpt_recent_transactions` | Recent transaction activity for analysis |

### Snapshots

| Model | Description |
|-------|-------------|
| `snp_ynab_categories` | SCD Type 2 snapshot tracking monthly budget, activity, and balance changes per category |

---

## CI/CD

Two GitHub Actions workflows manage the deployment lifecycle:

### `dbt_ci.yml` — Pull Request Validation
- Triggers on PRs targeting `main`
- Creates an isolated Snowflake schema per PR (`ci_pr_<number>`) to avoid conflicts
- Runs **Slim CI** using `dbt build --select state:modified+` against the production manifest, so only changed models and their downstream dependencies are built and tested
- Falls back to a full build if no production manifest exists yet
- Drops the temporary CI schema on completion (even on failure)

### `dbt_prod.yml` — Production Deployment
- Triggers on merge to `main`
- Runs `dbt snapshot` then a full `dbt build` against the `analytics_prod` schema
- Uploads `manifest.json` as a GitHub artifact for Slim CI diffing on subsequent PRs

---

## Getting Started

### Prerequisites

- Python 3.11+
- Snowflake account (can create free 30 day trial)
- YNAB API key ([generate here](https://app.ynab.com/settings/developer))
- FRED API key ([generate here, need to create a free account](https://fred.stlouisfed.org/docs/api/api_key.html))

### 1. Snowflake Infrastructure Setup

Run the following once in Snowflake as `ACCOUNTADMIN` to create the required warehouse, database, schemas, and roles.

```sql
-- Warehouse and database
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS PERSONAL_FINANCE;
CREATE SCHEMA IF NOT EXISTS PERSONAL_FINANCE.RAW;
CREATE SCHEMA IF NOT EXISTS PERSONAL_FINANCE.ANALYTICS_PROD;
CREATE SCHEMA IF NOT EXISTS PERSONAL_FINANCE.SNAPSHOTS;

-- Ingestion role (used by Python scripts to write raw data)
CREATE ROLE IF NOT EXISTS raw_ingestion_role;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE raw_ingestion_role;
GRANT USAGE ON DATABASE PERSONAL_FINANCE TO ROLE raw_ingestion_role;
GRANT USAGE ON SCHEMA PERSONAL_FINANCE.RAW TO ROLE raw_ingestion_role;
GRANT CREATE TABLE ON SCHEMA PERSONAL_FINANCE.RAW TO ROLE raw_ingestion_role;
GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.RAW TO ROLE raw_ingestion_role;
GRANT INSERT, SELECT ON FUTURE TABLES IN SCHEMA PERSONAL_FINANCE.RAW TO ROLE raw_ingestion_role;

-- dbt role (used by dbt for transformations and CI/CD)
CREATE ROLE IF NOT EXISTS ynab_dbt_role;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ynab_dbt_role;
GRANT USAGE ON DATABASE PERSONAL_FINANCE TO ROLE ynab_dbt_role;
GRANT CREATE SCHEMA ON DATABASE PERSONAL_FINANCE TO ROLE ynab_dbt_role;
GRANT USAGE ON SCHEMA PERSONAL_FINANCE.RAW TO ROLE ynab_dbt_role;
GRANT SELECT ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.RAW TO ROLE ynab_dbt_role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PERSONAL_FINANCE.RAW TO ROLE ynab_dbt_role;
GRANT ALL ON SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE ynab_dbt_role;
GRANT ALL ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE ynab_dbt_role;
GRANT ALL ON FUTURE TABLES IN SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE ynab_dbt_role;
GRANT ALL ON SCHEMA PERSONAL_FINANCE.SNAPSHOTS TO ROLE ynab_dbt_role;
GRANT ALL ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.SNAPSHOTS TO ROLE ynab_dbt_role;
GRANT ALL ON FUTURE TABLES IN SCHEMA PERSONAL_FINANCE.SNAPSHOTS TO ROLE ynab_dbt_role;

-- Analyst role (read-only access to analytics and snapshots)
CREATE ROLE analyst_role;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE analyst_role;
GRANT USAGE ON DATABASE PERSONAL_FINANCE TO ROLE analyst_role;
GRANT USAGE ON SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE analyst_role;
GRANT USAGE ON SCHEMA PERSONAL_FINANCE.SNAPSHOTS TO ROLE analyst_role;
GRANT SELECT ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE analyst_role;
GRANT SELECT ON ALL TABLES IN SCHEMA PERSONAL_FINANCE.SNAPSHOTS TO ROLE analyst_role;
GRANT SELECT ON ALL VIEWS IN SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE analyst_role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PERSONAL_FINANCE.ANALYTICS_PROD TO ROLE analyst_role;

-- Assign roles to your user
GRANT ROLE raw_ingestion_role TO USER <your_snowflake_user>;
GRANT ROLE ynab_dbt_role TO USER <your_snowflake_user>;

-- Optional test user
GRANT ROLE analyst_role TO USER <your_snowflake_user>;
CREATE USER analyst_user;
GRANT ROLE analyst_role TO USER analyst_user;
ALTER USER analyst_user SET PASSWORD = '<create_password>';
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure environment variables

Create a `.env` file in the project root:

```env
YNAB_API_KEY=<your_ynab_api_key>
YNAB_BUDGET_ID=<your_ynab_budget_id> (Found in URL)

FRED_API_KEY=<your_fred_api_key>

SNOWFLAKE_USER=<your_snowflake_user>
SNOWFLAKE_PASSWORD=<your_snowflake_password>
SNOWFLAKE_ACCOUNT=<your_snowflake_account>
SNOWFLAKE_ROLE=raw_ingestion_role
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=PERSONAL_FINANCE
SNOWFLAKE_SCHEMA=RAW
```

### 4. Ingest raw data

```bash
python api_seed/ynab_to_snowflake.py
python api_seed/fred_to_snowflake.py
```

### 5. Configure dbt profile

Add the following to `~/.dbt/profiles.yml`:

```yaml
ynab_dbt:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_snowflake_account>
      user: <your_snowflake_user>
      password: <your_snowflake_password>
      role: ynab_dbt_role
      database: PERSONAL_FINANCE
      warehouse: COMPUTE_WH
      schema: dbt_<your_name>
      threads: 4
```

### 6. Run dbt

```bash
cd ynab_dbt
dbt deps        # Install dbt packages
dbt seed        # Load FRED series mapping CSV
dbt snapshot    # Run SCD Type 2 snapshots
dbt build       # Run models + tests
dbt docs generate && dbt docs serve   # View documentation
```
