
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        category_id, budget_month
    from PERSONAL_FINANCE.analytics_prod.fct_monthly_budget_variance
    group by category_id, budget_month
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test