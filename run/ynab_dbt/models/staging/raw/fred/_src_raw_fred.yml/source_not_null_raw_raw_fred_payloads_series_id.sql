
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select series_id
from personal_finance.raw.raw_fred_payloads
where series_id is null



  
  
      
    ) dbt_internal_test