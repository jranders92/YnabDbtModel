
    
    

select
    series_id as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.staging.stg_fred_series_metadata
where series_id is not null
group by series_id
having count(*) > 1


