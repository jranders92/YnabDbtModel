

with meet_condition as(
  select *
  from PERSONAL_FINANCE.analytics_prod.dim_date
),

validation_errors as (
  select *
  from meet_condition
  where
    -- never true, defaults to an empty result set. Exists to ensure any combo of the `or` clauses below succeeds
    1 = 2
    -- records with a value >= min_value are permitted. The `not` flips this to find records that don't meet the rule.
    or not date_day >= cast('2023-01-01' as date)
    -- records with a value <= max_value are permitted. The `not` flips this to find records that don't meet the rule.
    or not date_day <= cast('2030-01-01' as date)
)

select *
from validation_errors

