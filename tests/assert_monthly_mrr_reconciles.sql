-- Return differences only: a successful dbt singular test returns zero rows.
-- Closing MRR is recomputed from int_customer_monthly_mrr, before any movement classification.
with expected as (
    select
        mrr_month,
        sum(mrr_eur) as closing_mrr_eur,
        count(*) as closing_customer_count
    from {{ ref('int_customer_monthly_mrr') }}
    group by 1
),

actual as (
    select
        mrr_month,
        closing_mrr_eur,
        closing_customer_count
    from {{ ref('mart_monthly_mrr') }}
    -- Months without MRR have no row in the intermediate model.
    where closing_mrr_eur > 0
)

select
    coalesce(e.mrr_month, a.mrr_month) as mrr_month,
    e.closing_mrr_eur as expected_closing_mrr_eur,
    a.closing_mrr_eur as actual_closing_mrr_eur,
    e.closing_customer_count as expected_closing_customer_count,
    a.closing_customer_count as actual_closing_customer_count
from expected as e
full outer join actual as a on e.mrr_month = a.mrr_month
where
    e.closing_mrr_eur is distinct from a.closing_mrr_eur
    or e.closing_customer_count is distinct from a.closing_customer_count
