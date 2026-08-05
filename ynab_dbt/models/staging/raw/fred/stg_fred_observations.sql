with raw_data as (
    select
        series_id,
        payload,
        extracted_at
    from {{ source('raw', 'raw_fred_payloads') }}
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