
    
    

select
    dbt_scd_id as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.snapshots.snp_ynab_categories
where dbt_scd_id is not null
group by dbt_scd_id
having count(*) > 1


