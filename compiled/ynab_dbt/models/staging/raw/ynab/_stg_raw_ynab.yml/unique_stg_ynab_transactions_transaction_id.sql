
    
    

select
    transaction_id as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.staging.stg_ynab_transactions
where transaction_id is not null
group by transaction_id
having count(*) > 1


