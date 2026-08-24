





with validation_errors as (

    select
        month_date, fred_series_id
    from PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
    group by month_date, fred_series_id
    having count(*) > 1

)

select *
from validation_errors


