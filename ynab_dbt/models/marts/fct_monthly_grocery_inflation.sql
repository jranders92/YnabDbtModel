with fred_seed as (
    -- Reference the CSV seed mapping directly
    select * from {{ ref('seed_fred_series_mapping') }}
    where macro_category = 'Groceries'
),

grocery_transactions as (
    select
        date_trunc('month', t.transaction_date) as spend_month,
        sum(t.outflow_amount) as total_grocery_spent,
        count(t.transaction_id) as transaction_count,
        avg(t.outflow_amount) as avg_transaction_size
    from {{ ref('fct_transactions') }} t
    inner join {{ ref('dim_categories') }} c
        on t.category_id = c.category_id
    -- Dynamic filter based on the YNAB group mapped in the FRED seed CSV
    where c.category_name in (select matching_ynab_category_group from fred_seed)
    group by 1
),

fred_cpi as (
    select
        date_trunc('month', o.observation_date) as cpi_month,
        s.series_id,
        s.series_name,
        s.units,
        avg(o.observation_value) as grocery_cpi_index
    from {{ ref('stg_fred_observations') }} o
    inner join fred_seed s
        on o.series_id = s.series_id
    group by 1, 2, 3, 4
)

select
    -- Primary Key
    md5(concat(cast(g.spend_month as string), '-', f.series_id)) as grocery_inflation_pk,
    g.spend_month as month_date,

    -- Metadata from Seed
    f.series_id as fred_series_id,
    f.series_name as fred_series_name,
    f.units as cpi_units,

    -- Personal Grocery Spending Metrics
    g.total_grocery_spent,
    g.transaction_count,
    round(g.avg_transaction_size, 2) as avg_transaction_size,

    -- National CPI Metric
    f.grocery_cpi_index,

    -- Prior Year Lagged Metrics (YoY)
    lag(g.total_grocery_spent, 12) over (order by g.spend_month) as total_grocery_spent_prior_year,
    lag(f.grocery_cpi_index, 12) over (order by g.spend_month) as cpi_index_prior_year,

    -- Year-over-Year (YoY) Percentage Growth Comparisons
    round(
        (g.total_grocery_spent - lag(g.total_grocery_spent, 12) over (order by g.spend_month)) 
        / nullif(lag(g.total_grocery_spent, 12) over (order by g.spend_month), 0) * 100, 
        2
    ) as personal_grocery_spend_yoy_pct,

    round(
        (f.grocery_cpi_index - lag(f.grocery_cpi_index, 12) over (order by g.spend_month)) 
        / nullif(lag(f.grocery_cpi_index, 12) over (order by g.spend_month), 0) * 100, 
        2
    ) as national_cpi_grocery_yoy_pct

from grocery_transactions g
left join fred_cpi f
    on g.spend_month = f.cpi_month
order by month_date desc