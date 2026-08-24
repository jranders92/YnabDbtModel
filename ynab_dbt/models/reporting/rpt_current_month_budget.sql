with categories as (
    select * 
    from {{ref('snp_ynab_categories')}}
    where dbt_valid_to is null
    and budget_month = date_trunc('month', current_date)
),

category_names as (
    select * from {{ref('dim_categories')}}
    where is_deleted = false
    and is_hidden = false
    and category_name not in ('Uncategorized','Inflow: Ready to Assign', 'Work Reimbursements', 'Friend Reimbursments')
    and category_group_name != 'Credit Card Payments'
)

Select 
    c.category_id,
    cn.category_name,
    cn.category_group_name,
    c.budget_month,
    c.budgeted_amount,
    c.activity_amount,
    c.balance_amount 
from categories c
inner join category_names cn
on c.category_id = cn.category_id