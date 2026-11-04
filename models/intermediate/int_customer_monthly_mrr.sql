-- Grain: one row per customer and month with at least one active subscription at month end.

with subscription_mrr as (

    select *
    from {{ ref('int_subscription_monthly_mrr') }}

)

select
    customer_id,
    mrr_month,
    cast(sum(mrr_eur) as decimal(14, 2)) as mrr_eur,
    count(*) as active_subscription_count
from subscription_mrr
group by 1, 2
