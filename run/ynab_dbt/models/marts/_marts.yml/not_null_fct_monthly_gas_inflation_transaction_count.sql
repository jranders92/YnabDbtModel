
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transaction_count
from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
where transaction_count is null



  
  
      
    ) dbt_internal_test