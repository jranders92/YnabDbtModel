
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select budget_variance_sk
from PERSONAL_FINANCE.analytics_prod.fct_monthly_budget_variance
where budget_variance_sk is null



  
  
      
    ) dbt_internal_test