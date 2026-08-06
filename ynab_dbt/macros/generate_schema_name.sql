{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {# In dev or ci, force EVERYTHING into the target schema (or prefixed by it) #}
    {%- if target.name in ['dev', 'ci'] -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {# In prod, use the custom schema name directly (e.g., MARTS, STAGING) #}
    {%- else -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}