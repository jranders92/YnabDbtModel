
    
    

with all_values as (

    select
        endpoint_name as value_field,
        count(*) as n_records

    from personal_finance.raw.raw_ynab_payloads
    group by endpoint_name

)

select *
from all_values
where value_field not in (
    'accounts','categories','transactions'
)


