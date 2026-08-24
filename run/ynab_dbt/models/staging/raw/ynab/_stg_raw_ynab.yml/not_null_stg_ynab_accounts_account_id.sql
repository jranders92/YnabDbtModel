
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



with __dbt__cte__stg_ynab_accounts as (
with raw_data as (
    select payload
    from personal_finance.raw.raw_ynab_payloads
    where endpoint_name = 'accounts'
    order by extracted_at desc
    limit 1
)

select
    -- Primary Keys
    account_node.value:id::string as account_id,

    -- Attributes
    account_node.value:name::string as account_name,
    account_node.value:type::string as account_type,
    account_node.value:note::string as account_note,

    -- Classification & Status Flags
    account_node.value:on_budget::boolean as is_on_budget,
    account_node.value:closed::boolean as is_closed,
    account_node.value:deleted::boolean as is_deleted,

    -- Balances (Converted from Milliunits)
    account_node.value:cleared_balance::number(18,2) / 1000.0 as cleared_balance,
    account_node.value:uncleared_balance::number(18,2) / 1000.0 as uncleared_balance,
    account_node.value:balance::number(18,2) / 1000.0 as total_balance,

    -- Tracking / Transfer Properties
    account_node.value:transfer_payee_id::string as transfer_payee_id,
    account_node.value:direct_import_linked::boolean as is_direct_import_linked,
    account_node.value:direct_import_in_error::boolean as is_direct_import_in_error

from raw_data,
lateral flatten(input => payload:data:accounts) as account_node
) select account_id
from __dbt__cte__stg_ynab_accounts
where account_id is null



  
  
      
    ) dbt_internal_test