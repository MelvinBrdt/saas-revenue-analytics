-- Return customer months that appear more than once.

select
    customer_id,
    mrr_month,
    count(*) as row_count
from {{ ref('mart_customer_monthly_mrr') }}
group by 1, 2
having count(*) > 1
