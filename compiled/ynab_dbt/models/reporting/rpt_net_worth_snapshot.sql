with accounts as (
    select * from PERSONAL_FINANCE.analytics_prod.dim_accounts
    where is_closed = false
)

select
    accounting_type,
    liquidity_tier,
    count(account_id)        as account_count,
    sum(total_balance)       as total_balance
from accounts
group by 1, 2