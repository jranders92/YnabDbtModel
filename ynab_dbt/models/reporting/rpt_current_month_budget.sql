with budget as (
    select * 
    from {{ref('fct_monthly_budget_variance')}}
    where budget_month = date_trunc('month', current_date)
),

category_names as (
    select * from {{ref('dim_categories')}}
    where is_deleted = false
    and is_hidden = false
    and category_name not in ('Uncategorized','Inflow: Ready to Assign', 'Work Reimbursements', 'Friend Reimbursments')
    and category_group_name != 'Credit Card Payments'
)

select 
    cn.category_name,
    cn.category_group_name,
    b.budget_month,
    b.budgeted_amount,
    b.actual_spent_amount,
    b.variance_amount 
from budget b
inner join category_names cn
on b.category_id = cn.category_id