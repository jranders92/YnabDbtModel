
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month_date
from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
where month_date is null



  
  
      
    ) dbt_internal_test