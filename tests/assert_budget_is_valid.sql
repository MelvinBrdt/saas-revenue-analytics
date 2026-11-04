-- Return budget rows outside the calendar or with a negative amount.
-- A month outside the calendar would silently never reach the variance mart.

select
    b.budget_month,
    b.budget_billed_eur,
    b.budget_closing_mrr_eur
from {{ ref('budget_monthly') }} as b
left join {{ ref('int_months') }} as m
    on b.budget_month = m.month_start
where m.month_start is null
    or b.budget_billed_eur < 0
    or b.budget_closing_mrr_eur < 0
