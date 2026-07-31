with accounts as (
    select * from {{ ref('stg_ynab_accounts') }}
)

select
    account_id,
    account_name,
    account_type,

    -- Asset vs. Liability Grouping
    case
        when account_type in ('checking', 'savings', 'cash', 'otherAsset') then 'Asset'
        when account_type in ('creditCard', 'lineOfCredit', 'otherLiability', 'mortgage') then 'Liability'
        else 'Unknown'
    end as accounting_type,

    -- Liquidity Classification
    case
        when account_type in ('checking', 'savings', 'cash') then 'Liquid Cash'
        when account_type in ('otherAsset') then 'Illiquid / Investment'
        when account_type in ('creditCard') then 'Revolving Debt'
        when account_type in ('mortgage', 'otherLiability') then 'Long-Term Debt'
    end as liquidity_tier,

    is_on_budget,
    is_closed

from accounts