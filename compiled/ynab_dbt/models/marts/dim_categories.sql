with  __dbt__cte__stg_ynab_categories as (
with raw_data as (
    select payload, 
    extracted_at -- needed for category snapshot
    from personal_finance.raw.raw_ynab_payloads
    where endpoint_name = 'categories'
    order by extracted_at desc
    limit 1
),

category_groups as (
    select
        group_node.value:id::string as category_group_id,
        group_node.value:name::string as category_group_name,
        group_node.value:hidden::boolean as is_category_group_hidden,
        group_node.value:deleted::boolean as is_category_group_deleted,
        category_node.value as category_data,
        extracted_at 
    from raw_data,
    lateral flatten(input => payload:data:category_groups) as group_node,
    lateral flatten(input => group_node.value:categories) as category_node
)

select
    -- Primary & Foreign Keys
    category_data:id::string as category_id,
    category_group_id,

    -- Descriptive Attributes
    category_data:name::string as category_name,
    category_group_name,
    category_data:goal_type::string as goal_type,
    category_data:note::string as category_note,

    -- Status Flags
    category_data:hidden::boolean as is_hidden,
    category_data:deleted::boolean as is_deleted,
    is_category_group_hidden,
    is_category_group_deleted,

    -- Financial Metrics (Converted from Milliunits)
    category_data:budgeted::number(18,2) / 1000.0 as budgeted_amount,
    category_data:activity::number(18,2) / 1000.0 as activity_amount,
    category_data:balance::number(18,2) / 1000.0 as balance_amount,
    category_data:goal_target::number(18,2) / 1000.0 as goal_target_amount,

    -- Goal Attributes
    category_data:goal_creation_month::date as goal_creation_month,
    category_data:goal_target_month::date as goal_target_month,
    category_data:goal_percentage_complete::int as goal_percentage_complete,
    extracted_at

from category_groups
), categories as (
    select * from __dbt__cte__stg_ynab_categories
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