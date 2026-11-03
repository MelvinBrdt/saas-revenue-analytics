with source as (
    select * from {{ source('billing', 'subscriptions') }}
)

select
    trim(subscription_id) as subscription_id,
    trim(customer_id) as customer_id,
    lower(trim(plan_code)) as plan_code,
    cast(started_at as date) as started_date,
    try_cast(nullif(trim(ended_at), '') as date) as ended_date,
    cast(monthly_price_eur as decimal(12, 2)) as monthly_price_eur
from source
