with transactions as (
    select * from {{ref('fct_transactions')}}
    where transaction_date >= dateadd(day, -30, current_date)
    and lower(payee_name) not like '%transfer%' and lower(payee_name) not like '%reimbursement%'
),

categories as (
    select * from {{ref('dim_categories')}}
),

accounts as (
    select * from {{ref('dim_accounts')}}
)

select
    t.payee_name,
    t.transaction_date,
    t.transaction_amount,
    c.category_name,
    c.category_group_name,
    a.account_name
from transactions t
left join categories c on t.category_id = c.category_id
left join accounts a on t.account_id = a.account_id
