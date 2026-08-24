

with  __dbt__cte__stg_ynab_transactions as (
with raw_data as (
    select payload
    from personal_finance.raw.raw_ynab_payloads
    where endpoint_name = 'transactions'
    order by extracted_at desc
    limit 1
)

select
    value:id::string as transaction_id,
    value:date::date as transaction_date,
    value:amount::number / 1000.0 as amount, -- Milliunits conversion
    value:payee_name::string as payee_name,
    value:category_id::string as category_id,
    value:account_id::string as account_id,
    value:cleared::string as cleared_status,
    value:approved::string as approved_status,
    value:deleted::boolean as is_deleted
from raw_data,
lateral flatten(input => payload:data:transactions)
), transactions as (
    select * from __dbt__cte__stg_ynab_transactions
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
