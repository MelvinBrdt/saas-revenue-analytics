# SaaS Revenue Analytics — dbt + DuckDB

Projet pédagogique **100 % synthétique** pour apprendre les fondamentaux dbt dans un contexte SaaS B2B. Aucun jeu de données réel, aucune donnée personnelle.

## Périmètre V1

- Sources : `raw.customers`, `raw.subscriptions`, `raw.invoices`
- Staging : nettoyage, conversion de types, tests d'intégrité
- Mart : `mart_monthly_billing`, **une ligne par mois d'émission**
- KPI : montant facturé, incluant `paid` et `open`, excluant `void`
- **Important** : facturé != MRR != reconnu en comptabilité != encaissé.
- Hypothèses simplificatrices : EUR, sans TVA, avoirs, remises ni factures multi-lignes.

## Prérequis

Python 3.11+ conseillé. Utiliser un terminal à la racine du dépôt.

```bash
python -m venv .venv
# Linux/macOS : source .venv/bin/activate
# Windows (PowerShell) : .venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python scripts/generate_data.py
python scripts/load_raw.py
dbt debug --profiles-dir .
dbt build --profiles-dir .
dbt docs generate --profiles-dir .
```

La base locale se trouve dans `data/saas.duckdb` (non versionnée). Les vues staging sont créées dans `analytics_staging`, et le mart dans `analytics_marts`. DuckDB est un moteur local, sans serveur ni compte.

## Architecture

`CSV synthétiques -> Python (ingestion) -> DuckDB raw -> dbt staging -> dbt marts`

Les CSV de démonstration sont de petits fixtures versionnés. Chaque exécution de `generate_data.py` produit les mêmes données. `load_raw.py` est relançable : il remplace les tables brutes (chargement **full refresh**, pas CDC/incrémental dans cette itération).

## Résultat attendu sur les fixtures

| Mois | Montant facturé EUR | Factures admissibles |
| --- | ---: | ---: |
| Janvier 2026 | 198,00 | 2 |
| Février 2026 | 396,00 | 4 |
| Mars 2026 | 695,00 | 5 |
| Avril 2026 | 695,00 | 5 |
| Mai 2026 | 695,00 | 5 |
| Juin 2026 | 695,00 | 5 |

La facture annulée (`void`) d’avril ne contribue pas aux 695,00 EUR.

## Contrôles

- Tests sources et staging : clés `unique`, `not_null`, valeurs permises, relations clients/abonnements/factures
- Test singulier : le total du mart se réconcilie avec les factures admissibles en staging
- Test singulier `assert_invoice_amount_non_negative` : vérifie qu'aucune facture ne possède un montant négatif. Ce test a été validé en introduisant volontairement une anomalie, puis en restaurant les données.
- Commande : `dbt build --profiles-dir .`

## Travail personnel suggéré

1. Expliquer le `source()` et le `ref()` de chaque modèle.
2. Vérifier que les factures `void` n'augmentent pas le montant facturé.
3. Ajouter un test qui rejette les montants négatifs.
4. Modifier volontairement une donnée source pour provoquer un test en échec, puis corriger le problème.
5. Documenter dans le README les décisions et limites métier.

## Itérations futures (hors V1)

- I2 : modélisation `fct_invoices`, découpage explicite grain facture / agrégation, contrôles métier renforcés
- I3 : CI sur Pull Request, tests automatiques, qualité de code
- I4 (facultatif) : abonnement temporel, analyse churn/MRR avec définition métier rigoureuse

## Limites

Ce dépôt est une **simulation pédagogique**, pas un système de production. Les événements sont générés, les tables raw sont remplacées intégralement et les règles de facturation sont volontairement simplifiées.
