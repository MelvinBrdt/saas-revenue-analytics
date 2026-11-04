-- Return differences only: a successful dbt singular test returns zero rows.
-- Totals are read directly from the budget seed and the billing mart.
with expected as (
    select
        (select sum(budget_billed_eur) from {{ ref('budget_monthly') }}) as budget_billed_eur,
        (select sum(billed_amount_eur) from {{ ref('mart_monthly_billing') }}) as billed_amount_eur
),

actual as (
    select
        sum(budget_billed_eur) as budget_billed_eur,
        sum(billed_amount_eur) as billed_amount_eur
    from {{ ref('mart_budget_vs_actual') }}
)

select
    e.budget_billed_eur as expected_budget_billed_eur,
    a.budget_billed_eur as actual_budget_billed_eur,
    e.billed_amount_eur as expected_billed_amount_eur,
    a.billed_amount_eur as actual_billed_amount_eur
from expected as e
cross join actual as a
where
    e.budget_billed_eur is distinct from a.budget_billed_eur
    or e.billed_amount_eur is distinct from a.billed_amount_eur
