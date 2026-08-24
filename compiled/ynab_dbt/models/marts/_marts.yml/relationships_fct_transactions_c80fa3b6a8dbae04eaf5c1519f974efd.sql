
    
    

with child as (
    select category_id as from_field
    from (select * from PERSONAL_FINANCE.analytics_prod.fct_transactions where category_id != 'cd891398-970b-4ae4-a758-3ba8841a8866') dbt_subquery
    where category_id is not null
),

parent as (
    select category_id as to_field
    from PERSONAL_FINANCE.analytics_prod.dim_categories
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


