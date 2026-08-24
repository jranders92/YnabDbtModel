
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_gas_spent
from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
where total_gas_spent is null



  
  
      
    ) dbt_internal_test