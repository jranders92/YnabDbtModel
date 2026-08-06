{% macro drop_schema_if_exists(schema_name) %}
  {% set drop_query %}
    DROP SCHEMA IF EXISTS {{ target.database }}.{{ schema_name }} CASCADE;
  {% endset %}
  
  {% do run_query(drop_query) %}
  {% do log("Dropped temporary CI schema: " ~ schema_name, info=True) %}
{% endmacro %}