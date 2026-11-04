-- Return customer months that appear more than once.

select
    customer_id,
    invoice_month,
    count(*) as row_count
from {{ ref('mart_customer_monthly_billing') }}
group by 1, 2
having count(*) > 1
