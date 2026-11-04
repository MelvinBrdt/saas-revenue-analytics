-- Return invoices whose payment date contradicts their status:
-- a paid invoice needs a payment date, an open or void invoice cannot have one.

select
    invoice_id,
    invoice_status,
    paid_date
from {{ ref('stg_billing__invoices') }}
where (invoice_status = 'paid') is distinct from (paid_date is not null)
