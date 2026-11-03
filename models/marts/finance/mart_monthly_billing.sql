-- Grain: one row per invoice month.
-- Billed amount includes paid/open invoices; void invoices are excluded.
-- This is NOT MRR, cash collection, or recognized revenue.

with invoices as (

    select *
    from {{ ref('fct_invoices') }}

)

select
    cast(date_trunc('month', invoice_date) as date)
        as invoice_month,

    cast(sum(billed_amount_eur) as decimal(14, 2))
        as billed_amount_eur,

    count(*) filter (where invoice_status <> 'void')
        as issued_invoice_count,

    count(*) filter (where invoice_status = 'paid')
        as paid_invoice_count,

    count(*) filter (where invoice_status = 'open')
        as open_invoice_count,

    count(*) filter (where invoice_status = 'void')
        as void_invoice_count

from invoices
group by 1
