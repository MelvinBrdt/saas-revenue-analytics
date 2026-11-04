-- Return invoices with impossible dates, or paid after the closing date.
-- Also makes the date casts run: staging is a view, so a cast no query reads is never evaluated.

with closing as (

    select max(month_end) as closing_date
    from {{ ref('int_months') }}

)

select
    i.invoice_id,
    i.invoice_date,
    i.due_date,
    i.paid_date,
    c.closing_date
from {{ ref('stg_billing__invoices') }} as i
cross join closing as c
where i.due_date < i.invoice_date
    or i.paid_date < i.invoice_date
    or i.paid_date > c.closing_date
