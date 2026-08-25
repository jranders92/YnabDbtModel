
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select category_id
from PERSONAL_FINANCE.staging.stg_ynab_categories
where category_id is null



  
  
      
    ) dbt_internal_test