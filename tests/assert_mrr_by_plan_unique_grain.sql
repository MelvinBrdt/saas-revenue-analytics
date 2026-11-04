-- Return plan months that appear more than once.

select
    plan_code,
    mrr_month,
    count(*) as row_count
from {{ ref('mart_monthly_mrr_by_plan') }}
group by 1, 2
having count(*) > 1
