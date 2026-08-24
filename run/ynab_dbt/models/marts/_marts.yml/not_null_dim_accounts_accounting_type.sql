
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select accounting_type
from PERSONAL_FINANCE.analytics_prod.dim_accounts
where accounting_type is null



  
  
      
    ) dbt_internal_test