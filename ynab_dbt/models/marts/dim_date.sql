-- I only need to build this table once
{{ config(
    materialized='table',
    ) 
}}

with generated_dates as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2023-01-01' as date)",
        end_date="cast('2030-01-01' as date)"
    ) }}
),

date_table as (
    select 
        date_day,
        extract(year from date_day) as year,
        extract(month from date_day) as month,

        case
            when month = 1 then 'January'
            when month = 2 then 'February'
            when month = 3 then 'March'
            when month = 4 then 'April'
            when month = 5 then 'May'
            when month = 6 then 'June'
            when month = 7 then 'July'
            when month = 8 then 'August'
            when month = 9 then 'September'
            when month = 10 then 'October'
            when month = 11 then 'November'
            when month = 12 then 'December'
        end as month_name,

        extract(day from date_day) as day_of_month,
        extract(dow from date_day) as day_of_week,
        extract(week from date_day) as week_of_year,
        extract(quarter from date_day) as quarter,
        case 
            when extract(dow from date_day) in (0, 6) then 'Weekend'
            else 'Weekday'
        end as day_type
    from generated_dates
)

select * from date_table
