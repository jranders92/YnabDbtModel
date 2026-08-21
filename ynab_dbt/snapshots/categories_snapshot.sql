{% snapshot snp_ynab_categories %}

{{
    config(
        unique_key='category_id',
        strategy='check',
        check_cols=['budgeted_amount', 'activity_amount', 'balance_amount']
    )
}}

select
    category_id,
    date_trunc('month', extracted_at::date) as budget_month,
    budgeted_amount,
    activity_amount,
    balance_amount,
    extracted_at
from {{ ref('stg_ynab_categories') }}

{% endsnapshot %}
