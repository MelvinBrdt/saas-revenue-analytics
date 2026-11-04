-- Grain: one row, at the closing date of the calendar.
-- Period KPIs cover the whole calendar. Retention compares the last month to three months earlier.

with calendar as (

    select
        min(month_start) as first_month,
        max(month_start) as last_month,
        max(month_end) as closing_date,
        cast(max(month_start) - interval 3 month as date) as retention_base_month
    from {{ ref('int_months') }}

),

closing_mrr as (

    select
        m.closing_mrr_eur,
        m.closing_customer_count
    from {{ ref('mart_monthly_mrr') }} as m
    inner join calendar as c
        on m.mrr_month = c.last_month

),

retention_base as (

    select
        m.customer_id,
        m.closing_mrr_eur as base_mrr_eur
    from {{ ref('mart_customer_monthly_mrr') }} as m
    inner join calendar as c
        on m.mrr_month = c.retention_base_month
    where m.closing_mrr_eur > 0

),

retention_end as (

    select
        m.customer_id,
        m.closing_mrr_eur as end_mrr_eur
    from {{ ref('mart_customer_monthly_mrr') }} as m
    inner join calendar as c
        on m.mrr_month = c.last_month

),

retention as (

    select
        sum(b.base_mrr_eur) as base_mrr_eur,
        -- Customers won after the base month are left out: only the base cohort counts.
        sum(coalesce(e.end_mrr_eur, 0)) as retained_mrr_eur,
        -- Gross retention ignores expansion: a customer cannot count for more than its base MRR.
        sum(least(coalesce(e.end_mrr_eur, 0), b.base_mrr_eur)) as retained_without_expansion_eur
    from retention_base as b
    left join retention_end as e
        on b.customer_id = e.customer_id

),

budget as (

    select
        sum(billed_amount_eur) as billed_amount_eur,
        sum(budget_billed_eur) as budget_billed_eur
    from {{ ref('mart_budget_vs_actual') }}

),

closing_budget as (

    select b.budget_closing_mrr_eur
    from {{ ref('mart_budget_vs_actual') }} as b
    inner join calendar as c
        on b.budget_month = c.last_month

),

receivables as (

    select
        coalesce(sum(amount_eur), 0) as open_amount_eur,
        coalesce(sum(amount_eur) filter (where days_overdue > 0), 0) as overdue_amount_eur
    from {{ ref('mart_open_invoices') }}

),

payments as (

    select
        count(*) as paid_invoice_count,
        avg(days_to_pay) as avg_days_to_pay,
        sum(days_to_pay * amount_eur) / sum(amount_eur) as amount_weighted_days_to_pay,
        count(*) filter (where is_paid_late) * 1.0 / count(*) as late_payment_rate
    from {{ ref('fct_invoices') }}
    where invoice_status = 'paid'

),

customer_billing as (

    select
        customer_id,
        sum(billed_amount_eur) as billed_amount_eur,
        row_number() over (order by sum(billed_amount_eur) desc) as billing_rank
    from {{ ref('mart_customer_monthly_billing') }}
    group by 1

),

concentration as (

    select
        sum(billed_amount_eur) filter (where billing_rank = 1) as top_customer_billed_eur,
        sum(billed_amount_eur) filter (where billing_rank <= 3) as top_3_customers_billed_eur
    from customer_billing

)

select
    c.closing_date,
    c.retention_base_month,
    m.closing_mrr_eur,
    m.closing_customer_count,
    cast(m.closing_mrr_eur * 12 as decimal(14, 2)) as arr_eur,
    cast(m.closing_mrr_eur / nullif(m.closing_customer_count, 0) as decimal(14, 2)) as arpa_eur,
    cast(r.retained_mrr_eur / nullif(r.base_mrr_eur, 0) as decimal(7, 4)) as net_revenue_retention_rate,
    cast(r.retained_without_expansion_eur / nullif(r.base_mrr_eur, 0) as decimal(7, 4)) as gross_revenue_retention_rate,
    b.billed_amount_eur,
    b.budget_billed_eur,
    cast(b.billed_amount_eur / nullif(b.budget_billed_eur, 0) as decimal(7, 4)) as billed_budget_attainment_rate,
    cast(m.closing_mrr_eur / nullif(cb.budget_closing_mrr_eur, 0) as decimal(7, 4)) as mrr_budget_attainment_rate,
    o.open_amount_eur,
    o.overdue_amount_eur,
    cast(o.overdue_amount_eur / nullif(o.open_amount_eur, 0) as decimal(7, 4)) as overdue_share_rate,
    -- Days of billing still unpaid at closing, over the whole calendar period.
    cast(
        o.open_amount_eur / nullif(b.billed_amount_eur, 0) * (c.closing_date - c.first_month + 1)
        as decimal(7, 1)
    ) as days_sales_outstanding,
    p.paid_invoice_count,
    cast(p.avg_days_to_pay as decimal(7, 1)) as avg_days_to_pay,
    cast(p.amount_weighted_days_to_pay as decimal(7, 1)) as amount_weighted_days_to_pay,
    cast(p.late_payment_rate as decimal(7, 4)) as late_payment_rate,
    cast(cn.top_customer_billed_eur / nullif(b.billed_amount_eur, 0) as decimal(7, 4)) as top_customer_share,
    cast(cn.top_3_customers_billed_eur / nullif(b.billed_amount_eur, 0) as decimal(7, 4)) as top_3_customers_share
from calendar as c
cross join closing_mrr as m
cross join retention as r
cross join budget as b
cross join closing_budget as cb
cross join receivables as o
cross join payments as p
cross join concentration as cn
