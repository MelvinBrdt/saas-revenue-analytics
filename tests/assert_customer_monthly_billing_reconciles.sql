-- Return differences only: a successful dbt singular test returns zero rows.
with customer_monthly as (
    select
        invoice_month,
        sum(billed_amount_eur) as billed_amount_eur,
        sum(issued_invoice_count) as issued_invoice_count,
        sum(paid_invoice_count) as paid_invoice_count,
        sum(open_invoice_count) as open_invoice_count,
        sum(void_invoice_count) as void_invoice_count
    from {{ ref('mart_customer_monthly_billing') }}
    group by 1
),

monthly as (
    select *
    from {{ ref('mart_monthly_billing') }}
)

select
    coalesce(c.invoice_month, m.invoice_month) as invoice_month,
    c.billed_amount_eur as customer_billed_amount_eur,
    m.billed_amount_eur as monthly_billed_amount_eur,
    c.issued_invoice_count as customer_issued_invoice_count,
    m.issued_invoice_count as monthly_issued_invoice_count,
    c.void_invoice_count as customer_void_invoice_count,
    m.void_invoice_count as monthly_void_invoice_count
from customer_monthly as c
full outer join monthly as m on c.invoice_month = m.invoice_month
where
    c.billed_amount_eur is distinct from m.billed_amount_eur
    or c.issued_invoice_count is distinct from m.issued_invoice_count
    or c.paid_invoice_count is distinct from m.paid_invoice_count
    or c.open_invoice_count is distinct from m.open_invoice_count
    or c.void_invoice_count is distinct from m.void_invoice_count
