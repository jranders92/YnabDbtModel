
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select dbt_scd_id
from PERSONAL_FINANCE.snapshots.snp_ynab_categories
where dbt_scd_id is null



  
  
      
    ) dbt_internal_test