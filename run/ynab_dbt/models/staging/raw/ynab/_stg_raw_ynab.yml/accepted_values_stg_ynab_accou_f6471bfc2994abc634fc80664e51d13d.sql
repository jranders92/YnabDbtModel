
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        account_type as value_field,
        count(*) as n_records

    from PERSONAL_FINANCE.staging.stg_ynab_accounts
    group by account_type

)

select *
from all_values
where value_field not in (
    'checking','savings','cash','creditCard','lineOfCredit','investment','mortgage','autoLoan','studentLoan','personalLoan','medicalDebt','otherAsset','otherLiability'
)



  
  
      
    ) dbt_internal_test