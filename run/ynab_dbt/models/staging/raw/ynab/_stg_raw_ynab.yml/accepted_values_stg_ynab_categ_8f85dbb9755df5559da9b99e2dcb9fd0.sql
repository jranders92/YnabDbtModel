
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

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



  
  
      
    ) dbt_internal_test