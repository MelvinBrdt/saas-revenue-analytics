with source as (
    select * from {{ source('billing', 'invoices') }}
)

select
    trim(invoice_id) as invoice_id,
    trim(subscription_id) as subscription_id,
    cast(invoice_date as date) as invoice_date,
    cast(amount_eur as decimal(12, 2)) as amount_eur,
    lower(trim(invoice_status)) as invoice_status
from source
