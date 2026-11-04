-- Return differences only: a successful dbt singular test returns zero rows.
-- The count comes from the billing mart and the amount from staging, both independent from the aging logic.
with expected as (
    select
        (select sum(open_invoice_count) from {{ ref('mart_monthly_billing') }}) as invoice_count,
        (select sum(amount_eur) from {{ ref('stg_billing__invoices') }} where invoice_status = 'open') as amount_eur
),
actual as (
    select
        count(*) as invoice_count,
        sum(amount_eur) as amount_eur
    from {{ ref('mart_open_invoices') }}
)
select
    e.invoice_count as expected_invoice_count,
    a.invoice_count as actual_invoice_count,
    e.amount_eur as expected_amount_eur,
    a.amount_eur as actual_amount_eur
from expected e
cross join actual a
where e.invoice_count is distinct from a.invoice_count
    or e.amount_eur is distinct from a.amount_eur
