-- Grain: one row per plan and month with MRR at month end.

with subscription_mrr as (

    select *
    from {{ ref('int_subscription_monthly_mrr') }}

),

plan_mrr as (

    select
        plan_code,
        mrr_month,
        sum(mrr_eur) as closing_mrr_eur,
        count(*) as active_subscription_count
    from subscription_mrr
    group by 1, 2

)

select
    plan_code,
    mrr_month,
    cast(closing_mrr_eur as decimal(14, 2)) as closing_mrr_eur,
    active_subscription_count,
    cast(closing_mrr_eur / sum(closing_mrr_eur) over (partition by mrr_month) as decimal(7, 4)) as mrr_share
from plan_mrr
