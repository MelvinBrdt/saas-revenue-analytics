with source as (
    select * from {{ source('crm', 'customers') }}
)

select
    trim(customer_id) as customer_id,
    trim(customer_name) as customer_name,
    upper(trim(country_code)) as country_code,
    cast(created_at as date) as created_date
from source
