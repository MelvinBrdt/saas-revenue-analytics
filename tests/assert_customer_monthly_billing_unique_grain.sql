-- Return customer months that appear more than once.
-- Singular test: the built-in unique test covers one column, and dbt_utils is not worth adding for one check.

select
    customer_id,
    invoice_month,
    count(*) as row_count
from {{ ref('mart_customer_monthly_billing') }}
group by 1, 2
having count(*) > 1
