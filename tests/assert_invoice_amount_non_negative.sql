-- Credit notes are out of scope, so a negative amount can only be bad data.
select
    invoice_id,
    amount_eur
from {{ ref('stg_billing__invoices') }}
where amount_eur < 0
