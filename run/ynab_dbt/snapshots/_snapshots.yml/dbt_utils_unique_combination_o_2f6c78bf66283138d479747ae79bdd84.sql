
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        category_id, budget_month, dbt_valid_from
    from PERSONAL_FINANCE.snapshots.snp_ynab_categories
    group by category_id, budget_month, dbt_valid_from
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test