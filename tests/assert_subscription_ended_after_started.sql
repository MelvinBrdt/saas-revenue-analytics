-- Return subscriptions that end before they start.
-- Also makes the date casts run: staging is a view, so a cast no query reads is never evaluated.

select
    subscription_id,
    started_date,
    ended_date
from {{ ref('stg_billing__subscriptions') }}
where ended_date < started_date
