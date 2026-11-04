"""Create small, deterministic, explicitly synthetic SaaS billing CSVs."""
from __future__ import annotations

import csv
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "data" / "raw"

CUSTOMERS = [
    ("C001", "Aster Labs", "FR", "2025-11-04"),
    ("C002", "Birch Studio", "BE", "2025-12-10"),
    ("C003", "Cobalt Works", "FR", "2026-01-02"),
    ("C004", "Delta Services", "DE", "2026-01-15"),
    ("C005", "Elm Retail", "FR", "2026-02-11"),
    ("C006", "Fjord Analytics", "NL", "2026-03-07"),
]

# subscription_id, customer_id, plan_code, started_at, ended_at, monthly_price_eur
SUBSCRIPTIONS = [
    ("S001", "C001", "starter", "2026-01-01", "", "49.00"),
    ("S002", "C002", "growth", "2026-01-01", "", "149.00"),
    ("S003", "C003", "starter", "2026-02-01", "", "49.00"),
    ("S004", "C004", "growth", "2026-02-01", "2026-04-30", "149.00"),
    ("S005", "C005", "enterprise", "2026-03-01", "", "299.00"),
    ("S006", "C006", "growth", "2026-04-01", "", "149.00"),
    # Second subscription for C001: two invoices in the same customer month.
    ("S007", "C001", "growth", "2026-06-01", "", "149.00"),
]

# Cases the monthly loop cannot produce, appended after it so its invoice ids stay stable.
# subscription_id, invoice_date, amount_eur, invoice_status, paid_date
EDGE_CASE_INVOICES = [
    # Voided invoice next to a paid one in the same customer month.
    ("S002", "2026-03-15", "149.00", "void", ""),
    # Second invoice in the same customer month, on the last day of the month, long overdue.
    ("S003", "2026-03-31", "49.00", "open", ""),
    # Issued after the subscription ended on 2026-04-30.
    ("S004", "2026-05-10", "30.00", "paid", "2026-06-05"),
    # Open next to a paid invoice in the same customer month, with an unnormalized raw status.
    ("S005", "2026-05-20", "120.00", " OPEN", ""),
]

MONTHS = [date(2026, m, 1) for m in range(1, 7)]

PAYMENT_TERM_DAYS = 30

# Days each subscription takes to pay. Above the payment term, the customer pays late.
PAYMENT_DELAY_DAYS = {"S001": 14, "S002": 45, "S003": 28, "S004": 20, "S005": 35, "S006": 25, "S007": 10}


def due_date(invoice_date: date) -> str:
    return (invoice_date + timedelta(days=PAYMENT_TERM_DAYS)).isoformat()


def write_csv(name: str, header: list[str], rows: list[tuple[str, ...]]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / name
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)
    print(f"Generated {path.relative_to(ROOT)}: {len(rows)} rows")


def main() -> None:
    write_csv("customers.csv", ["customer_id", "customer_name", "country_code", "created_at"], CUSTOMERS)
    write_csv("subscriptions.csv", ["subscription_id", "customer_id", "plan_code", "started_at", "ended_at", "monthly_price_eur"], SUBSCRIPTIONS)
    invoices = []
    next_id = 1
    for month in MONTHS:
        for sub_id, _cust_id, _plan, start, end, price in SUBSCRIPTIONS:
            start_date = date.fromisoformat(start)
            end_date = date.fromisoformat(end) if end else None
            if start_date > month or (end_date is not None and end_date < month):
                continue
            # Fixed statuses keep the expected results in the README reproducible.
            status = "paid"
            # Unpaid at the June 30 close. S002 pays too slowly to settle its June invoice by then.
            if month == date(2026, 6, 1) and sub_id in ("S002", "S003", "S005"):
                status = "open"
            if month == date(2026, 4, 1) and sub_id == "S004":
                status = "void"
            paid_date = (month + timedelta(days=PAYMENT_DELAY_DAYS[sub_id])).isoformat() if status == "paid" else ""
            invoices.append((f"I{next_id:04}", sub_id, month.isoformat(), due_date(month), paid_date, price, status))
            next_id += 1
    for sub_id, invoice_date, price, status, paid_date in EDGE_CASE_INVOICES:
        invoices.append((f"I{next_id:04}", sub_id, invoice_date, due_date(date.fromisoformat(invoice_date)), paid_date, price, status))
        next_id += 1
    write_csv("invoices.csv", ["invoice_id", "subscription_id", "invoice_date", "due_date", "paid_date", "amount_eur", "invoice_status"], invoices)


if __name__ == "__main__":
    main()
