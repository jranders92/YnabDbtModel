



select
    category_id,
    date_trunc('month', extracted_at::date) as budget_month,
    budgeted_amount,
    activity_amount,
    balance_amount,
    extracted_at
from PERSONAL_FINANCE.staging.stg_ynab_categories
