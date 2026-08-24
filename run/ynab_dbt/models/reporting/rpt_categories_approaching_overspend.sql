
  create or replace   view PERSONAL_FINANCE.analytics_prod.rpt_categories_approaching_overspend
  
  
  
  
  as (
    -- Note: this view refs rpt_current_month_budget to reuse category exclusion logic.
-- If query performance becomes a concern, refactor to ref fct_monthly_budget_variance directly
-- and duplicate the category filter.
with current_month_budget as (
    select * from PERSONAL_FINANCE.analytics_prod.rpt_current_month_budget
    where budgeted_amount > 0
)

select
    category_name,
    category_group_name,
    budget_month,
    budgeted_amount,
    actual_spent_amount,
    variance_amount
from current_month_budget
where actual_spent_amount / budgeted_amount >= 0.8
  );

