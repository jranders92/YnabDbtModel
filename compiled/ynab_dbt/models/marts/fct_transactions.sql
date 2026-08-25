

with transactions as (
    select * from PERSONAL_FINANCE.staging.stg_ynab_transactions
)

select
    transaction_id,
    transaction_date,
    account_id,
    category_id,
    payee_name,

    -- Numerical Measures
    amount as transaction_amount,
    
    -- Inflow / Outflow Split
    case when amount > 0 then amount else 0 end as inflow_amount,
    case when amount < 0 then abs(amount) else 0 end as outflow_amount,

    -- Flags
    cleared_status,
    approved_status,
    is_deleted

from transactions
 -- upserting past 30 days of transactions to avoid unnecessary compute
    where transaction_date >= dateadd('day', -30, current_date())
