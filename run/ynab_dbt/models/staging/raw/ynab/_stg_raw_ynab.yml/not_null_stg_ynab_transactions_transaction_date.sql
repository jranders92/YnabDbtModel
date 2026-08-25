
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transaction_date
from PERSONAL_FINANCE.staging.stg_ynab_transactions
where transaction_date is null



  
  
      
    ) dbt_internal_test