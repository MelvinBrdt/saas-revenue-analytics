-- Grain: one row per calendar month.
-- Ends at the last invoice month rather than current_date, so results do not change with the run date.

with subscriptions as (

    select *
    from {{ ref('stg_billing__subscriptions') }}

),

invoices as (

    select *
    from {{ ref('stg_billing__invoices') }}

),

bounds as (

    select
        (select min(started_date) from subscriptions) as first_date,
        (select max(invoice_date) from invoices) as last_date

),

months as (

    select
        unnest(generate_series(
            cast(date_trunc('month', first_date) as timestamp),
            cast(date_trunc('month', last_date) as timestamp),
            interval 1 month
        )) as month_start
    from bounds

)

select
    cast(month_start as date) as month_start,
    last_day(cast(month_start as date)) as month_end
from months
