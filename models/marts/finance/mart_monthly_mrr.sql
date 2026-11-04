-- Grain: one row per month of the calendar, including months without any MRR.
-- Contraction and churn amounts are negative. Rates are NULL when the month opens without MRR.
-- MRR measures recurring subscription prices, not billing, cash collection, or recognized revenue.

with months as (

    select month_start as mrr_month
    from {{ ref('int_months') }}

),

customer_mrr as (

    select *
    from {{ ref('mart_customer_monthly_mrr') }}

),

aggregated as (

    select
        mrr_month,
        sum(opening_mrr_eur) as opening_mrr_eur,
        sum(new_mrr_eur) as new_mrr_eur,
        sum(expansion_mrr_eur) as expansion_mrr_eur,
        sum(reactivation_mrr_eur) as reactivation_mrr_eur,
        sum(contraction_mrr_eur) as contraction_mrr_eur,
        sum(churned_mrr_eur) as churned_mrr_eur,
        sum(closing_mrr_eur) as closing_mrr_eur,
        count(*) filter (where opening_mrr_eur > 0) as opening_customer_count,
        count(*) filter (where movement_type = 'new') as new_customer_count,
        count(*) filter (where movement_type = 'reactivation') as reactivated_customer_count,
        count(*) filter (where movement_type = 'churn') as churned_customer_count,
        count(*) filter (where closing_mrr_eur > 0) as closing_customer_count
    from customer_mrr
    group by 1

),

filled as (

    select
        m.mrr_month,
        cast(coalesce(a.opening_mrr_eur, 0) as decimal(14, 2)) as opening_mrr_eur,
        cast(coalesce(a.new_mrr_eur, 0) as decimal(14, 2)) as new_mrr_eur,
        cast(coalesce(a.expansion_mrr_eur, 0) as decimal(14, 2)) as expansion_mrr_eur,
        cast(coalesce(a.reactivation_mrr_eur, 0) as decimal(14, 2)) as reactivation_mrr_eur,
        cast(coalesce(a.contraction_mrr_eur, 0) as decimal(14, 2)) as contraction_mrr_eur,
        cast(coalesce(a.churned_mrr_eur, 0) as decimal(14, 2)) as churned_mrr_eur,
        cast(coalesce(a.closing_mrr_eur, 0) as decimal(14, 2)) as closing_mrr_eur,
        coalesce(a.opening_customer_count, 0) as opening_customer_count,
        coalesce(a.new_customer_count, 0) as new_customer_count,
        coalesce(a.reactivated_customer_count, 0) as reactivated_customer_count,
        coalesce(a.churned_customer_count, 0) as churned_customer_count,
        coalesce(a.closing_customer_count, 0) as closing_customer_count
    from months as m
    left join aggregated as a
        on m.mrr_month = a.mrr_month

)

select
    *,
    cast(
        -(churned_mrr_eur + contraction_mrr_eur) / nullif(opening_mrr_eur, 0)
        as decimal(7, 4)
    ) as gross_mrr_churn_rate,
    cast(
        churned_customer_count * 1.0 / nullif(opening_customer_count, 0)
        as decimal(7, 4)
    ) as customer_churn_rate
from filled
