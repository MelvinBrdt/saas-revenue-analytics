# SaaS Revenue Analytics

[![dbt CI](https://github.com/MelvinBrdt/saas-revenue-analytics/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/MelvinBrdt/saas-revenue-analytics/actions/workflows/dbt-ci.yml)

**Combien facture-t-on, quel revenu récurrent en tire-t-on et combien en perd-on chaque mois ?**

Ce projet répond à ces questions pour une entreprise SaaS B2B fictive. Il part des exports bruts d'un CRM et d'un outil de facturation, puis les transforme en tables fiables, testées et documentées, prêtes pour un tableau de bord ou un reporting finance.

**Outils :** SQL, dbt Core, DuckDB, Python, Git et GitHub Actions.

Les données sont entièrement synthétiques : ce dépôt ne contient aucune donnée réelle ni personnelle.

## Ce que ce projet démontre

| Compétence | Dans ce projet |
|---|---|
| Modélisation analytique | Des couches distinctes (staging, intermédiaire, table de faits, marts) avec un grain explicite pour chaque modèle |
| Rigueur métier | Des définitions claires du montant facturé et du MRR, distincts de l'encaissé et du revenu comptabilisé |
| Qualité des données | 80 tests de données et 7 tests unitaires, dont des réconciliations entre les modèles |
| Automatisation | Un pipeline de CI qui reconstruit et teste tout le projet à chaque Pull Request |
| Reproductibilité | Des dépendances verrouillées et des données de démonstration identiques à chaque exécution |
| Méthode de travail | Des branches dédiées, des Pull Requests décrites et une branche `main` protégée |

## Le besoin métier

Une équipe finance veut suivre sa facturation et l'évolution de son revenu récurrent, par mois et par client. Le risque habituel dans ce type de reporting est que tout le monde parle de « revenu » sans parler de la même chose. Le projet fixe donc ce qu'il mesure et ce qu'il ne mesure pas :

| Indicateur | Définition | Mesuré ici |
|---|---|---|
| **Montant facturé** | Total des factures payées (`paid`) ou en attente (`open`), hors factures annulées (`void`) | Oui |
| **MRR** | Prix mensuel des abonnements actifs le dernier jour du mois | Oui |
| **Churn** | Perte de tout le MRR d'un client (s'il garde un abonnement sur deux, c'est une contraction) | Oui |
| Encaissé | Argent réellement reçu | Non |
| Revenu comptabilisé | Revenu rattaché à sa période comptable | Non |

## Les résultats

### La facturation

Facturation par mois, de janvier à juin 2026 :

| Mois | Montant facturé | Factures émises | Factures annulées |
|---|---:|---:|---:|
| Janvier | 198,00 € | 2 | 0 |
| Février | 396,00 € | 4 | 0 |
| Mars | 744,00 € | 6 | 1 |
| Avril | 695,00 € | 5 | 1 |
| Mai | 845,00 € | 7 | 0 |
| Juin | 844,00 € | 6 | 0 |
| **Total** | **3 722,00 €** | **30** | **2** |

La vue par client montre ce que le total ne montre pas. Le client C005 représente par exemple 35 % du montant facturé sur la période. Voici l'historique du client C004, dont l'abonnement a pris fin le 30 avril :

| Mois | Montant facturé | Factures émises | Factures annulées | Lecture |
|---|---:|---:|---:|---|
| Février | 149,00 € | 1 | 0 | Facturation normale |
| Mars | 149,00 € | 1 | 0 | Facturation normale |
| Avril | 0,00 € | 0 | 1 | Facture annulée, le client reste visible |
| Mai | 30,00 € | 1 | 0 | Facture émise après la fin de l'abonnement, bien comptée |

### Le revenu récurrent

Évolution du MRR sur la même période. Une ligne se lit de gauche à droite : le MRR d'ouverture, plus les mouvements du mois, donne le MRR de clôture.

| Mois | Ouverture | Nouveaux | Expansion | Churn | **Clôture** | Clients | Churn du MRR | Facturé |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Janvier | 0 € | 198 € | 0 € | 0 € | **198 €** | 2 | n/a | 198 € |
| Février | 198 € | 198 € | 0 € | 0 € | **396 €** | 4 | 0 % | 396 € |
| Mars | 396 € | 299 € | 0 € | 0 € | **695 €** | 5 | 0 % | 744 € |
| Avril | 695 € | 149 € | 0 € | -149 € | **695 €** | 5 | 21,44 % | 695 € |
| Mai | 695 € | 0 € | 0 € | 0 € | **695 €** | 5 | 0 % | 845 € |
| Juin | 695 € | 0 € | 149 € | 0 € | **844 €** | 5 | 0 % | 844 € |

Ce tableau montre pourquoi ces indicateurs doivent rester distincts :

- **Le facturé n'est pas le MRR.** En mars et en mai, des factures ponctuelles font passer le facturé au-dessus du MRR. En avril, les deux valent 695 € par coïncidence : le client C004 sort du MRR parce que son abonnement se termine, et du facturé parce que sa facture est annulée.
- **Un total stable peut cacher un départ.** En avril, le MRR ne bouge pas alors que C004 part, car C006 arrive au même prix. Le churn atteint pourtant 21,44 % du MRR et 20 % des clients.

## L'architecture

```mermaid
flowchart LR
    A[Exports CSV<br>CRM et facturation] -->|Python| B[Tables brutes<br>DuckDB]
    B --> C[Staging<br>nettoyage et typage]
    C --> D[fct_invoices<br>une ligne par facture]
    D --> E[mart_monthly_billing<br>une ligne par mois]
    D --> F[mart_customer_monthly_billing<br>une ligne par client et par mois]
    C --> J[dim_customers<br>une ligne par client]
    C --> G[int_customer_monthly_mrr<br>MRR de fin de mois par client]
    G --> H[mart_customer_monthly_mrr<br>mouvements par client et par mois]
    H --> I[mart_monthly_mrr<br>totaux et taux de churn par mois]
```

| Couche | Modèles | Rôle |
|---|---|---|
| Staging | `stg_crm__customers`, `stg_billing__subscriptions`, `stg_billing__invoices` | Nettoyer et typer les données brutes, sans règle métier |
| Intermédiaire | `int_months`, `int_customer_monthly_mrr` | Préparer le calendrier et le MRR de fin de mois, sans les exposer aux utilisateurs |
| Table de faits | `fct_invoices` | Rattacher chaque facture à son client et calculer le montant facturé, à un seul endroit |
| Dimension | `dim_customers` | Fournir le nom et le pays de chaque client aux analyses |
| Marts | `mart_monthly_billing`, `mart_customer_monthly_billing`, `mart_customer_monthly_mrr`, `mart_monthly_mrr` | Fournir des agrégats prêts à l'emploi pour la finance |

## Les décisions de modélisation

- **Les factures annulées restent dans `fct_invoices`.** Elles valent 0 € dans le montant facturé, mais restent comptées pour garder la trace des annulations.
- **Une facture sans abonnement connu n'est pas écartée.** Un `left join` la conserve pour que les totaux restent justes, et un test la signale au lieu de la faire disparaître en silence.
- **Une facture émise après la fin d'un abonnement reste comptée.** Filtrer sur les dates de résiliation ferait diverger le mart de la facturation réelle.
- **Le mart par client ne contient que les mois avec au moins une facture.** Ajouter les mois sans facture demande de définir la population suivie, ce qui reste à faire.
- **Le MRR vient des abonnements, pas des factures.** Il mesure ce qui se répète, alors qu'une facture peut être ponctuelle ou annulée.
- **Le MRR est mesuré le dernier jour du mois.** Un abonnement qui se termine ce jour-là n'en fait déjà plus partie, car il ne reviendra pas le mois suivant.
- **Le churn se mesure au niveau du client.** Perdre un abonnement sur deux est une contraction, et un client qui revient est une réactivation, pas un nouveau client.
- **Le calendrier s'arrête à la dernière facture, pas à la date du jour.** Les résultats restent ainsi identiques d'une exécution à l'autre.
- **DuckDB plutôt qu'un entrepôt cloud.** Le projet se lance en quelques minutes, sans compte ni serveur, et les principes de modélisation restent les mêmes.

## La qualité des données

| Type de contrôle | Ce qu'il protège | Exemple |
|---|---|---|
| Tests de colonnes | Les clés, les valeurs autorisées et les liens entre tables | Un statut de facture inconnu fait échouer le build |
| Tests singuliers | Les règles propres au projet | Un client ne peut apparaître qu'une fois par mois |
| Réconciliation | La cohérence entre les modèles | Les marts par client et mensuels donnent les mêmes totaux, et le MRR d'ouverture égale la clôture du mois précédent |
| Tests unitaires | La logique SQL, avec des résultats attendus écrits à la main | Une facture annulée vaut 0 € et plusieurs factures d'un même mois donnent une seule ligne |

Les données de démonstration contiennent volontairement des cas difficiles : plusieurs factures d'un même client sur un même mois, deux abonnements pour un même client, un mois où la seule facture est annulée, une facture émise le dernier jour du mois et un statut brut mal formaté. La contraction et la réactivation, absentes de ces données, sont couvertes par un test unitaire. Les tests ont aussi été éprouvés en cassant volontairement les modèles, pour vérifier qu'ils échouent bien quand il le faut.

Chaque Pull Request déclenche la [CI](.github/workflows/dbt-ci.yml), qui régénère les données, reconstruit le projet et lance tous les tests. Une règle GitHub protège `main` : chaque changement passe par une Pull Request, et cette CI doit réussir avant la fusion.

## Lancer le projet

Il faut Python 3.12, la version utilisée en CI. Depuis la racine du dépôt, sous Linux, macOS ou WSL :

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python scripts/generate_data.py
python scripts/load_raw.py
dbt build --profiles-dir .
```

Sous Windows PowerShell, activez l'environnement avec `.venv\Scripts\Activate.ps1`.

Pour parcourir la documentation des modèles et le graphe de dépendances dans le navigateur :

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## L'organisation du dépôt

```text
.github/workflows/   CI GitHub Actions
data/raw/            Exports CSV de démonstration
models/staging/      Nettoyage et typage des sources
models/intermediate/ Calendrier et MRR de fin de mois
models/marts/        Table de faits et marts finance
scripts/             Génération et chargement des données
tests/               Tests singuliers
```

## Les limites

Ce projet est une démonstration, pas un système en production :

- Les données sont peu nombreuses et générées par script.
- Les tables brutes sont remplacées à chaque chargement, sans traitement incrémental.
- Le périmètre est simplifié : tout est en euros, sans TVA, avoirs, remises ni factures multi-lignes.
- Un abonnement n'a qu'un seul prix, donc un changement de plan n'est pas modélisable, et un abonnement qui démarre et se termine dans le même mois n'entre jamais dans le MRR.
- Le churn involontaire, lié aux impayés, n'est pas mesuré.
- Le projet ne couvre pas les grands volumes ni l'historisation des changements.

## Les prochaines étapes

- Ajouter un lint SQL à la CI.
- Ajouter les mois sans facture au mart par client, avec une population définie.
