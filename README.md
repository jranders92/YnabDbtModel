# YNAB Personal Finance dbt Project

A personal finance analytics pipeline that ingests data from the [YNAB API](https://api.youneedabudget.com/) and [FRED (Federal Reserve Economic Data)](https://fred.stlouisfed.org/docs/api/fred/) into Snowflake, then transforms it using dbt into analytical models for budgeting, spending, and macroeconomic comparison.

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
```

---

## Data Sources

| Source | Description | Ingestion Script |
|--------|-------------|-----------------|
| YNAB API | Personal budget data — accounts, categories, transactions | `api_seed/ynab_to_snowflake.py` |
| FRED API | Macroeconomic CPI series — groceries, rent, gas, S&P 500 | `api_seed/fred_to_snowflake.py` |

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
│   │   └── marts/                   # Dimensional and fact models
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

Materialized as `table` in both dev and prod.

| Model | Description |
|-------|-------------|
| `dim_accounts` | Account dimension with asset/liability and liquidity classifications |
| `dim_categories` | Category dimension with expense tier and FRED CPI series mapping |
| `fct_transactions` | Core transaction fact table with inflow/outflow split |
| `fct_monthly_budget_variance` | Monthly budgeted vs. actual spending with utilization % by category |
| `fct_monthly_grocery_inflation` | Personal grocery spend vs. national CPI with YoY % comparisons |
| `fct_top_15_transactions` | Top 15 transactions by amount |

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
- Runs a full `dbt build` against the `analytics_prod` schema
- Uploads `manifest.json` as a GitHub artifact for Slim CI diffing on subsequent PRs

---

## Getting Started

### Prerequisites

- Python 3.11+
- Snowflake account
- YNAB API key ([generate here](https://app.ynab.com/settings/developer))
- FRED API key ([generate here](https://fred.stlouisfed.org/docs/api/api_key.html))

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```env
YNAB_API_KEY=<your_ynab_api_key>
YNAB_BUDGET_ID=<your_ynab_budget_id>

FRED_API_KEY=<your_fred_api_key>

SNOWFLAKE_USER=<your_snowflake_user>
SNOWFLAKE_PASSWORD=<your_snowflake_password>
SNOWFLAKE_ACCOUNT=<your_snowflake_account>
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=PERSONAL_FINANCE
SNOWFLAKE_SCHEMA=RAW
```

### 3. Ingest raw data

```bash
python api_seed/ynab_to_snowflake.py
python api_seed/fred_to_snowflake.py
```

### 4. Configure dbt profile

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
      role: ACCOUNTADMIN
      database: PERSONAL_FINANCE
      warehouse: COMPUTE_WH
      schema: dbt_<your_name>
      threads: 4
```

### 5. Run dbt

```bash
cd ynab_dbt
dbt deps        # Install dbt packages
dbt seed        # Load FRED series mapping CSV
dbt build       # Run models + tests
dbt docs generate && dbt docs serve   # View documentation
```
