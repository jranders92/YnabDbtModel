with transactions as (
    select * from {{ref('fct_transactions')}}
    where transaction_date >= dateadd(day, -30, current_date)
),

categories as (
    select * from {{ref('dim_categories')}}
),

accounts as (
    select * from {{ref('dim_accounts')}}
),

final as (
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
    where lower(t.payee_name) not like '%transfer%' and lower(t.payee_name) not like '%reimbursement%'
    order by t.transaction_date desc
)

Select * from final
