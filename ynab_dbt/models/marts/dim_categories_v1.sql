with categories as (
    select * from {{ ref('stg_ynab_categories') }}
)

select
    category_id,
    category_name,
    category_group_id,
    category_group_name,

    -- Business Logic / Expense Classification
    case 
        when category_group_name in ('Fixed Expenses', 'Bills', 'Housing', 'Utilities') then 'Fixed / Essential'
        when category_group_name in ('Frequent', 'Variables', 'Fun Money', 'Dining Out') then 'Discretionary'
        when category_group_name in ('Savings Goals', 'Investments', 'Debt Repayment') then 'Financial Goals'
        else 'Other'
    end as expense_tier,

    -- Subscription Flagging
    case 
        when lower(category_name) in ('netflix', 'spotify', 'subscription') then true
        else false
    end as is_subscription_category,

    -- Mapping key to FRED CPI Data (For Macro Analysis)
    case 
        when lower(category_name) like '%grocery%' or lower(category_name) like '%food%' then 'CPIUFDSL' 
        when lower(category_name) like '%gas%' or lower(category_name) like '%fuel%' then 'GASREGW'
        when lower(category_name) like '%rent%' or lower(category_name) like '%housing%' then 'CUUR0000SEHA'
        else null
    end as fred_cpi_series_id,

    goal_type,
    is_hidden,
    is_deleted

from categories