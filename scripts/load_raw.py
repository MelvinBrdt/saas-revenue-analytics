"""Rebuild raw DuckDB source tables from local CSVs. Idempotent by design."""
from __future__ import annotations

from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "saas.duckdb"
CSV_DIR = ROOT / "data" / "raw"


def main() -> None:
    if not all((CSV_DIR / f"{name}.csv").exists() for name in ("customers", "subscriptions", "invoices")):
        raise SystemExit("Missing CSVs: run `python scripts/generate_data.py` first.")
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with duckdb.connect(str(DB_PATH)) as conn:
        conn.execute("CREATE SCHEMA IF NOT EXISTS raw")
        for name in ("customers", "subscriptions", "invoices"):
            path = (CSV_DIR / f"{name}.csv").resolve().as_posix().replace("'", "''")
            # Keep raw values as VARCHAR; dbt staging owns type conversion.
            conn.execute(f"CREATE OR REPLACE TABLE raw.{name} AS SELECT * FROM read_csv('{path}', header=true, all_varchar=true)")
            count = conn.execute(f"SELECT COUNT(*) FROM raw.{name}").fetchone()[0]
            print(f"Loaded raw.{name}: {count} rows")


if __name__ == "__main__":
    main()
