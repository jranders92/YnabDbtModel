with monthly_budget as (    
    select
        category_id,
        budget_month,
        budgeted_amount
    from {{ ref('snp_ynab_categories') }}
    qualify row_number() over (
        partition by category_id, budget_month
        order by dbt_valid_from desc
    ) = 1),

monthly_actuals as (
    select
        date_trunc('month', transaction_date) as budget_month,
        category_id,
        sum(outflow_amount) as total_actual_outflow
    from {{ ref('fct_transactions') }}
    group by 1, 2
)

select
    md5(concat(coalesce(b.category_id, ''), '-', cast(b.budget_month as string))) as budget_variance_sk,
    b.budget_month,
    b.category_id,
    
    -- Measures
    b.budgeted_amount,
    coalesce(a.total_actual_outflow, 0) as actual_spent_amount,
    b.budgeted_amount - coalesce(a.total_actual_outflow, 0) as variance_amount

from monthly_budget b
left join monthly_actuals a 
    on b.category_id = a.category_id
    and b.budget_month = a.budget_month
