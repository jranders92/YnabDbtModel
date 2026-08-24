
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



with __dbt__cte__stg_ynab_transactions as (
with raw_data as (
    select payload
    from personal_finance.raw.raw_ynab_payloads
    where endpoint_name = 'transactions'
    order by extracted_at desc
    limit 1
)

select
    value:id::string as transaction_id,
    value:date::date as transaction_date,
    value:amount::number / 1000.0 as amount, -- Milliunits conversion
    value:payee_name::string as payee_name,
    value:category_id::string as category_id,
    value:account_id::string as account_id,
    value:cleared::string as cleared_status,
    value:approved::string as approved_status,
    value:deleted::boolean as is_deleted
from raw_data,
lateral flatten(input => payload:data:transactions)
) select transaction_id
from __dbt__cte__stg_ynab_transactions
where transaction_id is null



  
  
      
    ) dbt_internal_test