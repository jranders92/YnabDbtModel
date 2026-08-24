
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    gas_inflation_sk as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
where gas_inflation_sk is not null
group by gas_inflation_sk
having count(*) > 1



  
  
      
    ) dbt_internal_test