
    
    

with all_values as (

    select
        goal_type as value_field,
        count(*) as n_records

    from PERSONAL_FINANCE.staging.stg_ynab_categories
    group by goal_type

)

select *
from all_values
where value_field not in (
    'TB','MF','TBD','NEED','DEBT','NULL'
)


