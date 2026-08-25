
  create or replace   view PERSONAL_FINANCE.staging.stg_fred_series_metadata
  
  
  
  
  as (
    with raw_data as (
    select
        series_id,
        payload,
        extracted_at
    from personal_finance.raw.raw_fred_payloads
    where endpoint_name = 'series_metadata'
    qualify row_number() over (
        partition by series_id 
        order by extracted_at desc
    ) = 1
)

select
    series_id,
    series_node.value:title::string as series_title,
    series_node.value:frequency::string as frequency,
    series_node.value:frequency_short::string as frequency_short,
    series_node.value:units::string as units,
    series_node.value:units_short::string as units_short,
    series_node.value:seasonal_adjustment::string as seasonal_adjustment,
    series_node.value:last_updated::timestamp_ntz as last_updated_at

from raw_data,
lateral flatten(input => payload:seriess) as series_node
  );

