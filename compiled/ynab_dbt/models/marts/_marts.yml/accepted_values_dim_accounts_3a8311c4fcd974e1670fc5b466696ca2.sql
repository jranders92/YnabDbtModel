
    
    

with all_values as (

    select
        accounting_type as value_field,
        count(*) as n_records

    from PERSONAL_FINANCE.analytics_prod.dim_accounts
    group by accounting_type

)

select *
from all_values
where value_field not in (
    'Asset','Liability','Unknown'
)


