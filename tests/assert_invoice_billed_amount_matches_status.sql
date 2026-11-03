-- Return invoices whose billed amount
-- does not match their business status.

with invoices as (

    select *
    from {{ ref('fct_invoices') }}

),

validated as (

    select
        invoice_id,
        invoice_status,
        amount_eur,
        billed_amount_eur,

        case
            when invoice_status in ('paid', 'open')
                then amount_eur
            else cast(0 as decimal(12, 2))
        end as expected_billed_amount_eur

    from invoices

)

select
    invoice_id,
    invoice_status,
    amount_eur,
    billed_amount_eur,
    expected_billed_amount_eur
from validated
where billed_amount_eur
    is distinct from expected_billed_amount_eur