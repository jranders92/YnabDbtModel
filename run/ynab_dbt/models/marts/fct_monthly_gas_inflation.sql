
  
    

create or replace transient table PERSONAL_FINANCE.analytics_prod.fct_monthly_gas_inflation
    
    
    
    
    

    as (with  __dbt__cte__stg_fred_observations as (
with raw_data as (
    select
        series_id,
        payload,
        extracted_at
    from personal_finance.raw.raw_fred_payloads
    where endpoint_name = 'series_observations'
    -- Quality filter: grab the most recent extraction for each series_id
    qualify row_number() over (
        partition by series_id 
        order by extracted_at desc
    ) = 1
),

flattened_observations as (
    select
        raw_data.series_id,
        obs_node.value:date::date as observation_date,
        obs_node.value:value::string as raw_value,
        obs_node.value:realtime_start::date as realtime_start_date,
        obs_node.value:realtime_end::date as realtime_end_date
    from raw_data,
    lateral flatten(input => payload:observations) as obs_node
)

select
    -- Primary Surrogate Key (combination of series_id and date)
    md5(concat(series_id, '-', cast(observation_date as string))) as observation_pk,
    
    -- Natural Keys & Foreign Keys
    series_id,
    observation_date,

    -- Data Cleaning: FRED returns '.' when value is missing (e.g. holidays / weekends for daily stock prices)
    case 
        when raw_value = '.' then null 
        else raw_value::number(18, 4)
    end as observation_value,

    -- Metadata Dates
    realtime_start_date,
    realtime_end_date

from flattened_observations
-- Filter out future placeholder dates if returned by API
where observation_date <= current_date()
), fred_seed as (
    select * from PERSONAL_FINANCE.analytics_prod.seed_fred_series_mapping
    where macro_category = 'Transportation'
),

gas_transactions as (
    select
        date_trunc('month', t.transaction_date) as spend_month,
        sum(t.outflow_amount)                   as total_gas_spent,
        count(t.transaction_id)                 as transaction_count,
        avg(t.outflow_amount)                   as avg_transaction_size
    from PERSONAL_FINANCE.analytics_prod.fct_transactions t
    inner join PERSONAL_FINANCE.analytics_prod.dim_categories c
        on t.category_id = c.category_id
    where c.category_name in (select matching_ynab_category_group from fred_seed)
    group by 1
),

-- GASREGW is weekly so average up to monthly
fred_gas_prices as (
    select
        date_trunc('month', o.observation_date) as price_month,
        s.series_id,
        s.series_name,
        s.units,
        avg(o.observation_value)                as avg_gas_price_per_gallon
    from __dbt__cte__stg_fred_observations o
    inner join fred_seed s
        on o.series_id = s.series_id
    group by 1, 2, 3, 4
)

select
    -- Primary Key
    md5(concat(cast(g.spend_month as string), '-', f.series_id)) as gas_inflation_sk,
    g.spend_month                                                 as month_date,

    -- Metadata from Seed
    f.series_id                                                   as fred_series_id,
    f.series_name                                                 as fred_series_name,
    f.units                                                       as price_units,

    -- Personal Gas Spending Metrics
    g.total_gas_spent,
    g.transaction_count,
    round(g.avg_transaction_size, 2)                              as avg_transaction_size,

    -- National Gas Price Metric ($/gallon)
    f.avg_gas_price_per_gallon,

    -- Personal Implied Price per Gallon (each transaction ~10 gallons, Toyota Corolla filled at 1/4 tank)
    round(g.total_gas_spent / nullif(g.transaction_count * 10, 0), 2)                                          as my_implied_price_per_gallon,

    -- Price vs National Average (positive = paying more, negative = paying less)
    round(
        (g.total_gas_spent / nullif(g.transaction_count * 10, 0)) - f.avg_gas_price_per_gallon,
        2
    )                                                                                                           as price_vs_national_avg,

    -- Prior Year Lagged Metrics (YoY)
    lag(g.total_gas_spent, 12) over (order by g.spend_month)              as total_gas_spent_prior_year,
    lag(f.avg_gas_price_per_gallon, 12) over (order by g.spend_month)     as avg_gas_price_prior_year,

    -- Year-over-Year (YoY) Percentage Growth Comparisons
    round(
        (g.total_gas_spent - lag(g.total_gas_spent, 12) over (order by g.spend_month))
        / nullif(lag(g.total_gas_spent, 12) over (order by g.spend_month), 0) * 100,
        2
    ) as personal_gas_spend_yoy_pct,

    round(
        (f.avg_gas_price_per_gallon - lag(f.avg_gas_price_per_gallon, 12) over (order by g.spend_month))
        / nullif(lag(f.avg_gas_price_per_gallon, 12) over (order by g.spend_month), 0) * 100,
        2
    ) as national_gas_price_yoy_pct

from gas_transactions g
left join fred_gas_prices f
    on g.spend_month = f.price_month
    )
;


  