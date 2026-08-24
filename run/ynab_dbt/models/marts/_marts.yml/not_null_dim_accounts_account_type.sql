
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select account_type
from PERSONAL_FINANCE.analytics_prod.dim_accounts
where account_type is null



  
  
      
    ) dbt_internal_test