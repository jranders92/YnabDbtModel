
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    budget_variance_sk as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.analytics_prod.fct_monthly_budget_variance
where budget_variance_sk is not null
group by budget_variance_sk
having count(*) > 1



  
  
      
    ) dbt_internal_test