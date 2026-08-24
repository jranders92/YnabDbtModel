
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select category_id as from_field
    from PERSONAL_FINANCE.analytics_prod.fct_monthly_budget_variance
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



  
  
      
    ) dbt_internal_test