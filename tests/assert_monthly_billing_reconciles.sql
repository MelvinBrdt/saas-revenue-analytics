-- Return differences only: a successful dbt singular test returns zero rows.
-- Recomputed from staging, not fct_invoices, so an error in the billed amount rule is caught.
with expected as (
    select
        cast(date_trunc('month', invoice_date) as date) as invoice_month,
        sum(amount_eur) as expected_amount_eur
    from {{ ref('stg_billing__invoices') }}
    where invoice_status <> 'void'
    group by 1
),

actual as (
    select
        invoice_month,
        billed_amount_eur
    from {{ ref('mart_monthly_billing') }}
)

select
    coalesce(e.invoice_month, a.invoice_month) as invoice_month,
    e.expected_amount_eur,
    a.billed_amount_eur
from expected as e
full outer join actual as a on e.invoice_month = a.invoice_month
where e.expected_amount_eur is distinct from a.billed_amount_eur
