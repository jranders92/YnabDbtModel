with monthly_budget as (
    select * from {{ ref('stg_ynab_categories') }}
),

monthly_actuals as (
    select
        date_trunc('month', transaction_date) as budget_month,
        category_id,
        sum(outflow_amount) as total_actual_outflow
    from {{ ref('fct_transactions') }}
    group by 1, 2
)

select
    md5(concat(coalesce(b.category_id, ''), '-', cast(a.budget_month as string))) as budget_variance_pk,
    a.budget_month,
    b.category_id,
    
    -- Measures
    b.budgeted_amount,
    coalesce(a.total_actual_outflow, 0) as actual_spent_amount,
    b.budgeted_amount - coalesce(a.total_actual_outflow, 0) as variance_amount,

    -- Pacing / Utilization %
    case 
        when b.budgeted_amount > 0 
        then round((coalesce(a.total_actual_outflow, 0) / b.budgeted_amount) * 100, 2)
        else null 
    end as budget_utilization_pct

from monthly_budget b
left join monthly_actuals a 
    on b.category_id = a.category_id