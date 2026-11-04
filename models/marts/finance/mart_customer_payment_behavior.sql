-- Grain: one row per customer with at least one paid invoice.

with paid_invoices as (

    select *
    from {{ ref('fct_invoices') }}
    where invoice_status = 'paid'

)

select
    customer_id,
    count(*) as paid_invoice_count,
    sum(days_to_pay) as total_days_to_pay,
    cast(avg(days_to_pay) as decimal(7, 1)) as avg_days_to_pay,
    count(*) filter (where is_paid_late) as late_paid_invoice_count,
    cast(count(*) filter (where is_paid_late) * 1.0 / count(*) as decimal(7, 4)) as late_payment_rate
from paid_invoices
group by 1
