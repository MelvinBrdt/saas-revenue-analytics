-- Return months where the MRR per plan does not add up to the monthly MRR.
with by_plan as (
    select
        mrr_month,
        sum(closing_mrr_eur) as closing_mrr_eur
    from {{ ref('mart_monthly_mrr_by_plan') }}
    group by 1
),

monthly as (
    select
        mrr_month,
        closing_mrr_eur
    from {{ ref('mart_monthly_mrr') }}
    -- Months without MRR have no row per plan.
    where closing_mrr_eur > 0
)

select
    coalesce(p.mrr_month, m.mrr_month) as mrr_month,
    p.closing_mrr_eur as plan_closing_mrr_eur,
    m.closing_mrr_eur as monthly_closing_mrr_eur
from by_plan as p
full outer join monthly as m on p.mrr_month = m.mrr_month
where p.closing_mrr_eur is distinct from m.closing_mrr_eur
