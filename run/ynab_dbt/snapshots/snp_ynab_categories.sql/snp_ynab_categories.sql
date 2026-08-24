
      begin;
    merge into "PERSONAL_FINANCE"."SNAPSHOTS"."SNP_YNAB_CATEGORIES" as DBT_INTERNAL_DEST
    using "PERSONAL_FINANCE"."SNAPSHOTS"."SNP_YNAB_CATEGORIES__dbt_tmp" as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.dbt_scd_id = DBT_INTERNAL_DEST.dbt_scd_id

    when matched
     
       and DBT_INTERNAL_DEST.dbt_valid_to is null
     
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert ("CATEGORY_ID", "BUDGET_MONTH", "BUDGETED_AMOUNT", "ACTIVITY_AMOUNT", "BALANCE_AMOUNT", "EXTRACTED_AT", "DBT_UPDATED_AT", "DBT_VALID_FROM", "DBT_VALID_TO", "DBT_SCD_ID")
        values ("CATEGORY_ID", "BUDGET_MONTH", "BUDGETED_AMOUNT", "ACTIVITY_AMOUNT", "BALANCE_AMOUNT", "EXTRACTED_AT", "DBT_UPDATED_AT", "DBT_VALID_FROM", "DBT_VALID_TO", "DBT_SCD_ID")

;
    commit;
  