
    
    

select
    observation_pk as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.staging.stg_fred_observations
where observation_pk is not null
group by observation_pk
having count(*) > 1


