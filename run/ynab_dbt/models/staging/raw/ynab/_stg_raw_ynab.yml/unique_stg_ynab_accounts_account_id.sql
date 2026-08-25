
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    account_id as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.staging.stg_ynab_accounts
where account_id is not null
group by account_id
having count(*) > 1



  
  
      
    ) dbt_internal_test