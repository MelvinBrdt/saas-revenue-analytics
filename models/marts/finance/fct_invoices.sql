-- Grain: one row per invoice.
-- Voided invoices remain in the fact table but contribute
-- zero to billed_amount_eur.

with invoices as (

    select *
    from {{ ref('stg_billing__invoices') }}

),

subscriptions as (

    select *
    from {{ ref('stg_billing__subscriptions') }}

),

final as (

    select
        i.invoice_id,
        i.subscription_id,
        s.customer_id,
        i.invoice_date,
        i.invoice_status,
        i.amount_eur,

        case
            when i.invoice_status in ('paid', 'open')
                then i.amount_eur
            else cast(0 as decimal(12, 2))
        end as billed_amount_eur

    from invoices as i

    -- Left join: an invoice without a known subscription must stay in the fact so
    -- totals remain correct. The not_null test on customer_id reports it.
    left join subscriptions as s
        on i.subscription_id = s.subscription_id

)

select *
from final