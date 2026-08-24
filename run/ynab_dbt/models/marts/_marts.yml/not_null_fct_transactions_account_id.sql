
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select account_id
from PERSONAL_FINANCE.analytics_prod.fct_transactions
where account_id is null



  
  
      
    ) dbt_internal_test