-- Return customer months where opening MRR plus movements does not give closing MRR.

select
    customer_id,
    mrr_month,
    opening_mrr_eur,
    closing_mrr_eur
from {{ ref('mart_customer_monthly_mrr') }}
where opening_mrr_eur
    + new_mrr_eur
    + expansion_mrr_eur
    + reactivation_mrr_eur
    + contraction_mrr_eur
    + churned_mrr_eur
    is distinct from closing_mrr_eur
