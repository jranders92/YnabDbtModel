
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select observation_pk
from PERSONAL_FINANCE.staging.stg_fred_observations
where observation_pk is null



  
  
      
    ) dbt_internal_test