
  
    

create or replace transient table PERSONAL_FINANCE.analytics_prod.dim_date
    
    
    
    
    

    as (

with generated_dates as (
    





with rawdata as (

    

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * power(2, 0)
     + 
    
    p1.generated_number * power(2, 1)
     + 
    
    p2.generated_number * power(2, 2)
     + 
    
    p3.generated_number * power(2, 3)
     + 
    
    p4.generated_number * power(2, 4)
     + 
    
    p5.generated_number * power(2, 5)
     + 
    
    p6.generated_number * power(2, 6)
     + 
    
    p7.generated_number * power(2, 7)
     + 
    
    p8.generated_number * power(2, 8)
     + 
    
    p9.generated_number * power(2, 9)
     + 
    
    p10.generated_number * power(2, 10)
     + 
    
    p11.generated_number * power(2, 11)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
     cross join 
    
    p as p11
    
    

    )

    select *
    from unioned
    where generated_number <= 2557
    order by generated_number



),

all_periods as (

    select (
        

    dateadd(
        day,
        row_number() over (order by generated_number) - 1,
        cast('2023-01-01' as date)
        )


    ) as date_day
    from rawdata

),

filtered as (

    select *
    from all_periods
    where date_day <= cast('2030-01-01' as date)

)

select * from filtered


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
    )
;


  