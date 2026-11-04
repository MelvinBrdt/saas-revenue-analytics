-- Grain: one row per customer and month with at least one active subscription at month end.
-- MRR is a month-end snapshot of subscription prices, independent from invoices.

with months as (

    select *
    from {{ ref('int_months') }}

),

subscriptions as (

    select *
    from {{ ref('stg_billing__subscriptions') }}

)

select
    s.customer_id,
    m.month_start as mrr_month,
    cast(sum(s.monthly_price_eur) as decimal(14, 2)) as mrr_eur,
    count(*) as active_subscription_count

from months as m

inner join subscriptions as s
    on s.started_date <= m.month_end
    -- A subscription ending on the last day of the month will not recur, so it is already out.
    and (s.ended_date is null or s.ended_date > m.month_end)

group by 1, 2
