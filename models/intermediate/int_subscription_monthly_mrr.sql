-- Grain: one row per subscription and month where it is active at month end.
-- The single definition of MRR: a month-end snapshot of subscription prices, independent from invoices.

with months as (

    select *
    from {{ ref('int_months') }}

),

subscriptions as (

    select *
    from {{ ref('stg_billing__subscriptions') }}

)

select
    s.subscription_id,
    s.customer_id,
    s.plan_code,
    m.month_start as mrr_month,
    s.monthly_price_eur as mrr_eur

from months as m

inner join subscriptions as s
    on s.started_date <= m.month_end
    -- A subscription ending on the last day of the month will not recur, so it is already out.
    and (s.ended_date is null or m.month_end < s.ended_date)
