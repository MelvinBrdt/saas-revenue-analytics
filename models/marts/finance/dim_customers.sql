-- Grain: one row per customer, including customers without any subscription.

with customers as (

    select *
    from {{ ref('stg_crm__customers') }}

),

subscriptions as (

    select *
    from {{ ref('stg_billing__subscriptions') }}

),

-- Aggregated before the join: a customer can have several subscriptions, which would duplicate rows.
first_subscriptions as (

    select
        customer_id,
        min(started_date) as first_subscription_date
    from subscriptions
    group by 1

)

select
    c.customer_id,
    c.customer_name,
    c.country_code,
    c.created_date,
    f.first_subscription_date
from customers as c
left join first_subscriptions as f
    on c.customer_id = f.customer_id
