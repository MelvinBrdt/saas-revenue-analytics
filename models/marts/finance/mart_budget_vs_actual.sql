-- Grain: one row per calendar month.
-- A positive variance means actuals are above budget. A month without budget fails the not_null tests.

with months as (

    select month_start
    from {{ ref('int_months') }}

),

budget as (

    select *
    from {{ ref('budget_monthly') }}

),

billing as (

    select *
    from {{ ref('mart_monthly_billing') }}

),

mrr as (

    select *
    from {{ ref('mart_monthly_mrr') }}

),

joined as (

    select
        m.month_start as budget_month,
        -- A calendar month without any invoice has no row in the billing mart.
        coalesce(bi.billed_amount_eur, 0) as billed_amount_eur,
        bu.budget_billed_eur,
        mr.closing_mrr_eur,
        bu.budget_closing_mrr_eur
    from months as m
    left join budget as bu
        on m.month_start = bu.budget_month
    left join billing as bi
        on m.month_start = bi.invoice_month
    left join mrr as mr
        on m.month_start = mr.mrr_month

)

select
    budget_month,
    cast(billed_amount_eur as decimal(14, 2)) as billed_amount_eur,
    budget_billed_eur,
    cast(billed_amount_eur - budget_billed_eur as decimal(14, 2)) as billed_variance_eur,
    cast((billed_amount_eur - budget_billed_eur) / nullif(budget_billed_eur, 0) as decimal(7, 4))
        as billed_variance_rate,
    closing_mrr_eur,
    budget_closing_mrr_eur,
    cast(closing_mrr_eur - budget_closing_mrr_eur as decimal(14, 2)) as mrr_variance_eur,
    cast((closing_mrr_eur - budget_closing_mrr_eur) / nullif(budget_closing_mrr_eur, 0) as decimal(7, 4))
        as mrr_variance_rate
from joined
