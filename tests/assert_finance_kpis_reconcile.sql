-- Return differences only: a successful dbt singular test returns zero rows.
-- Compares the KPI row to totals read directly from the marts, and checks there is exactly one row.
with expected as (
    select
        (select sum(billed_amount_eur) from {{ ref('mart_monthly_billing') }}) as billed_amount_eur,
        (
            select sum(amount_eur) from {{ ref('stg_billing__invoices') }}
            where invoice_status = 'open')
            as open_amount_eur,
        (
            select closing_mrr_eur from {{ ref('mart_monthly_mrr') }}
            order by mrr_month desc
            limit 1
        ) as closing_mrr_eur
),

actual as (
    select
        count(*) as row_count,
        max(billed_amount_eur) as billed_amount_eur,
        max(open_amount_eur) as open_amount_eur,
        max(closing_mrr_eur) as closing_mrr_eur
    from {{ ref('mart_finance_kpis') }}
)

select
    a.row_count,
    e.billed_amount_eur as expected_billed_amount_eur,
    a.billed_amount_eur as actual_billed_amount_eur,
    e.open_amount_eur as expected_open_amount_eur,
    a.open_amount_eur as actual_open_amount_eur,
    e.closing_mrr_eur as expected_closing_mrr_eur,
    a.closing_mrr_eur as actual_closing_mrr_eur
from expected as e
cross join actual as a
where
    a.row_count != 1
    or e.billed_amount_eur is distinct from a.billed_amount_eur
    or e.open_amount_eur is distinct from a.open_amount_eur
    or e.closing_mrr_eur is distinct from a.closing_mrr_eur
