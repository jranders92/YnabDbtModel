
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select gas_inflation_sk
from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
where gas_inflation_sk is null



  
  
      
    ) dbt_internal_test