





with validation_errors as (

    select
        category_id, budget_month
    from PERSONAL_FINANCE.analytics_prod.fct_monthly_budget_variance
    group by category_id, budget_month
    having count(*) > 1

)

select *
from validation_errors


