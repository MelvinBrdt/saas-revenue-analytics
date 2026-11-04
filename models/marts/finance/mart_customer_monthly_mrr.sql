-- Grain: one row per customer and month with MRR at the start or the end of the month.
-- A customer has one net movement per month. Contraction and churn amounts are negative.
-- MRR measures recurring subscription prices, not billing, cash collection, or recognized revenue.

with months as (

    select *
    from {{ ref('int_months') }}

),

customer_mrr as (

    select *
    from {{ ref('int_customer_monthly_mrr') }}

),

first_months as (

    select
        customer_id,
        min(mrr_month) as first_mrr_month
    from customer_mrr
    group by 1

),

-- Every month since the first one: without these rows, a churned customer has no row to carry the churn.
customer_months as (

    select
        f.customer_id,
        f.first_mrr_month,
        m.month_start as mrr_month
    from first_months as f
    inner join months as m
        on f.first_mrr_month <= m.month_start

),

balances as (

    select
        cm.customer_id,
        cm.first_mrr_month,
        cm.mrr_month,
        coalesce(
            lag(c.mrr_eur) over (
                partition by cm.customer_id
                order by cm.mrr_month
            ),
            0
        ) as opening_mrr_eur,
        coalesce(c.mrr_eur, 0) as closing_mrr_eur
    from customer_months as cm
    left join customer_mrr as c
        on
            cm.customer_id = c.customer_id
            and cm.mrr_month = c.mrr_month

),

classified as (

    select
        *,
        closing_mrr_eur - opening_mrr_eur as mrr_change_eur,

        case
            when opening_mrr_eur = 0 and mrr_month = first_mrr_month then 'new'
            when opening_mrr_eur = 0 then 'reactivation'
            when closing_mrr_eur = 0 then 'churn'
            when closing_mrr_eur > opening_mrr_eur then 'expansion'
            when closing_mrr_eur < opening_mrr_eur then 'contraction'
            else 'stable'
        end as movement_type

    from balances
    -- Drops the months between a churn and a possible return.
    where opening_mrr_eur > 0 or closing_mrr_eur > 0

)

select
    customer_id,
    mrr_month,
    movement_type,
    cast(opening_mrr_eur as decimal(14, 2)) as opening_mrr_eur,
    cast(case when movement_type = 'new' then mrr_change_eur else 0 end as decimal(14, 2)) as new_mrr_eur,
    cast(case when movement_type = 'expansion' then mrr_change_eur else 0 end as decimal(14, 2)) as expansion_mrr_eur,
    cast(case when movement_type = 'reactivation' then mrr_change_eur else 0 end as decimal(14, 2))
        as reactivation_mrr_eur,
    cast(case when movement_type = 'contraction' then mrr_change_eur else 0 end as decimal(14, 2))
        as contraction_mrr_eur,
    cast(case when movement_type = 'churn' then mrr_change_eur else 0 end as decimal(14, 2)) as churned_mrr_eur,
    cast(closing_mrr_eur as decimal(14, 2)) as closing_mrr_eur
from classified
