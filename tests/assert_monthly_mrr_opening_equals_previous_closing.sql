-- Return months whose opening MRR differs from the previous closing MRR.

with monthly as (

    select
        mrr_month,
        opening_mrr_eur,
        coalesce(
            lag(closing_mrr_eur) over (order by mrr_month),
            0
        ) as previous_closing_mrr_eur
    from {{ ref('mart_monthly_mrr') }}

)

select *
from monthly
where opening_mrr_eur is distinct from previous_closing_mrr_eur
