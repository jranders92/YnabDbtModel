with transactions as (
    select * from {{ ref('fct_transactions') }}
)

Select * from transactions
order by transaction_amount desc
limit 15