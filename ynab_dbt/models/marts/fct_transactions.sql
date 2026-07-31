with transactions as (
    select * from {{ ref('stg_ynab_transactions') }}
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
    cleared_status

from transactions
-- Exclude internal account transfers for pure cash-flow reporting
-- where not is_transfer