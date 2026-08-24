
    
    

select
    category_id as unique_field,
    count(*) as n_records

from PERSONAL_FINANCE.analytics_prod.dim_categories
where category_id is not null
group by category_id
having count(*) > 1


