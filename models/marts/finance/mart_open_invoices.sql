-- Grain: one row per invoice awaiting payment at the closing date.
-- The closing date is the last day of the calendar, not current_date, so results do not change with the run date.

with invoices as (

    select *
    from {{ ref('fct_invoices') }}
    where invoice_status = 'open'

),

closing as (

    select max(month_end) as closing_date
    from {{ ref('int_months') }}

),

aged as (

    select
        i.invoice_id,
        i.customer_id,
        i.invoice_date,
        i.due_date,
        i.amount_eur,
        c.closing_date,
        c.closing_date - i.due_date as days_past_due
    from invoices as i
    cross join closing as c

)

select
    invoice_id,
    customer_id,
    invoice_date,
    due_date,
    amount_eur,
    closing_date,
    greatest(days_past_due, 0) as days_overdue,

    case
        when days_past_due <= 0 then 'not_due'
        when days_past_due <= 30 then '1_30_days'
        when days_past_due <= 60 then '31_60_days'
        when days_past_due <= 90 then '61_90_days'
        else 'over_90_days'
    end as aging_bucket

from aged
