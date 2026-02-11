#!/usr/bin/env python3
"""
Scrape sanatorium database from sanatoria.ru using Firecrawl API.
Produces a CSV file with contacts, director info, and org details.

Usage:
    # Test run (5 IDs):
    python3 scrape-sanatoriums.py --test

    # Full run (all 925 IDs):
    python3 scrape-sanatoriums.py

    # Custom range:
    python3 scrape-sanatoriums.py --start 100 --end 200

    # Resume from where you left off:
    python3 scrape-sanatoriums.py --resume

Requires: FIRECRAWL_API_KEY environment variable
"""

import argparse
import csv
import json
import os
import re
import sys
import time
import urllib.request
from html import unescape
from pathlib import Path

FIRECRAWL_API_URL = "https://api.firecrawl.dev/v1/scrape"
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
OUTPUT_DIR = PROJECT_DIR / "01_Projects" / "AGIency.pro - ИИ-автоматизация агентство" / "Prospecting"
CSV_FILE = OUTPUT_DIR / "sanatoriums_russia.csv"
PROGRESS_FILE = SCRIPT_DIR / ".scrape-sanatoriums-progress.json"

MAX_ORG_ID = 925
DELAY_SECONDS = 1
SAVE_EVERY = 50

TEST_IDS = [1, 200, 500, 693, 900]

CSV_COLUMNS = [
    "id", "name", "region", "city", "address", "website",
    "phone", "fax", "email", "director", "legal_form", "source_url"
]


def get_api_key():
    key = os.environ.get("FIRECRAWL_API_KEY")
    if not key:
        print("Error: FIRECRAWL_API_KEY environment variable not set")
        sys.exit(1)
    return key


def scrape_page(org_id, api_key):
    """Scrape a single sanatoria.ru page via Firecrawl API."""
    url = f"https://sanatoria.ru/san.php?org={org_id}"
    payload = json.dumps({
        "url": url,
        "formats": ["html"],
        "includeTags": ["#description-item", "h1", "li"]
    }).encode("utf-8")

    req = urllib.request.Request(
        FIRECRAWL_API_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data
    except Exception as e:
        print(f"  Error scraping org={org_id}: {e}")
        return None


def clean_text(text: str) -> str:
    """Clean HTML entities and normalize whitespace."""
    text = unescape(text)
    text = text.replace("\xa0", " ")  # &nbsp;
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_response(org_id, data):
    """Parse Firecrawl response into structured record."""
    if not data:
        return None

    html = data.get("html", "")
    metadata = data.get("metadata", {})

    if not html or len(html) < 100:
        return None

    record = {
        "id": org_id,
        "name": "",
        "region": "",
        "city": "",
        "address": "",
        "website": "",
        "phone": "",
        "fax": "",
        "email": "",
        "director": "",
        "legal_form": "",
        "source_url": f"https://sanatoria.ru/san.php?org={org_id}"
    }

    # --- Name ---
    # Try <h1><span itemprop="name">...</span></h1>
    m = re.search(r'itemprop="name"[^>]*>([^<]+)', html)
    if m:
        record["name"] = clean_text(m.group(1))
    else:
        # Fallback to metadata title
        title = metadata.get("title", "")
        # Title format: "Санаторий «Русь», Ессентуки — отзывы, ..."
        m = re.match(r"^(.+?)(?:\s*[—–-]\s*отзывы)", title)
        if m:
            record["name"] = clean_text(m.group(1))
        elif title:
            record["name"] = clean_text(title)

    if not record["name"]:
        return None  # No name = page doesn't exist

    # --- Address ---
    # Format: <strong>Адрес (<a...>на карте</a>):</strong> ADDRESS_TEXT </p>
    m = re.search(r"Адрес.*?</strong>\s*:?\s*(.+?)\s*</p>", html, re.DOTALL)
    if m:
        addr = clean_text(re.sub(r"<[^>]+>", "", m.group(1)))
        record["address"] = addr
        # Extract region and city from address
        # Format: "357623, Ставропольский край, г. Ессентуки, ул. Пушкина, д. 16"
        parts = addr.split(",")
        for part in parts:
            part = part.strip()
            if re.search(r"(край|область|республик|округ|Москва|Санкт-Петербург|Севастополь)", part, re.IGNORECASE):
                record["region"] = part.lstrip("0123456789 ")
            if re.search(r"(^г\.\s*|город\s+)", part, re.IGNORECASE):
                record["city"] = re.sub(r"^г\.\s*|^город\s+", "", part.strip(), flags=re.IGNORECASE).strip()

    # --- Phone ---
    m = re.search(r"<strong>Контактный телефон:</strong>\s*(.+?)(?:<i|</p>)", html, re.DOTALL)
    if m:
        phone_block = clean_text(re.sub(r"<[^>]+>", "", m.group(1)))
        # Split phone and fax if fax is inline
        fax_split = re.split(r"\s*Факс:\s*", phone_block)
        record["phone"] = fax_split[0].strip().rstrip(",").strip()
        if len(fax_split) > 1:
            record["fax"] = fax_split[1].strip()

    # --- Fax (standalone) ---
    if not record["fax"]:
        m = re.search(r"Факс:\s*([^<]+)", html)
        if m:
            record["fax"] = clean_text(m.group(1))

    # --- Email ---
    m = re.search(r'href="mailto:([^"]+)"', html)
    if m:
        record["email"] = m.group(1).strip()

    # --- Website ---
    m = re.search(r"Официальный сайт санатория:</strong>.*?<a\s+href=\"([^\"]+)\"", html, re.DOTALL)
    if m:
        record["website"] = m.group(1).strip()

    # --- Director ---
    # Pattern: "возглавляет ... <strong>ФИО.</strong>"
    # The name is always inside <strong> tag after "возглавляет"
    m = re.search(
        r"возглавляет\s+.{0,100}?<strong[^>]*>\s*([^<]+)",
        html, re.IGNORECASE | re.DOTALL
    )
    if m:
        director = clean_text(m.group(1)).rstrip(".")
        # Validate: must look like a name (at least 2 words, starts with uppercase)
        words = director.split()
        if len(words) >= 2 and words[0][0].isupper():
            record["director"] = director

    # --- Legal form ---
    m = re.search(r"Организационно-правовая форма:\s*</strong>\s*([^<.]+)", html, re.DOTALL)
    if m:
        record["legal_form"] = clean_text(m.group(1)).rstrip(".")

    return record


def load_progress() -> list:
    """Load previously saved progress."""
    if PROGRESS_FILE.exists():
        with open(PROGRESS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []


def save_progress(records: list):
    """Save intermediate progress."""
    with open(PROGRESS_FILE, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)


def export_csv(records: list):
    """Export records to CSV."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(CSV_FILE, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS, delimiter=";")
        writer.writeheader()
        for r in records:
            writer.writerow(r)
    print(f"\nCSV saved to: {CSV_FILE}")
    print(f"Total records: {len(records)}")


def print_record(r: dict):
    """Pretty-print a single record for debugging."""
    print(f"  Name:     {r['name']}")
    print(f"  Address:  {r['address']}")
    print(f"  Region:   {r['region']}")
    print(f"  City:     {r['city']}")
    print(f"  Phone:    {r['phone']}")
    print(f"  Fax:      {r['fax']}")
    print(f"  Email:    {r['email']}")
    print(f"  Website:  {r['website']}")
    print(f"  Director: {r['director']}")
    print(f"  Legal:    {r['legal_form']}")


def print_stats(records: list):
    """Print completeness statistics."""
    total = len(records)
    if total == 0:
        print("No records.")
        return
    fields = ["phone", "email", "website", "director", "legal_form", "region"]
    print(f"\n--- Statistics ({total} records) ---")
    for field in fields:
        count = sum(1 for r in records if r.get(field))
        print(f"  {field:12s}: {count:4d} ({count*100//total}%)")


def main():
    parser = argparse.ArgumentParser(description="Scrape sanatoria.ru database")
    parser.add_argument("--test", action="store_true", help="Test run on 5 IDs")
    parser.add_argument("--start", type=int, default=1, help="Start org ID")
    parser.add_argument("--end", type=int, default=MAX_ORG_ID, help="End org ID")
    parser.add_argument("--resume", action="store_true", help="Resume from saved progress")
    parser.add_argument("--export-only", action="store_true", help="Only export existing progress to CSV")
    args = parser.parse_args()

    api_key = get_api_key()

    # Load existing progress
    records = load_progress() if (args.resume or args.export_only) else []
    scraped_ids = {r["id"] for r in records}

    if args.export_only:
        export_csv(records)
        print_stats(records)
        return

    # Determine which IDs to scrape
    if args.test:
        ids_to_scrape = [i for i in TEST_IDS if i not in scraped_ids]
        print(f"Test mode: scraping {len(ids_to_scrape)} IDs")
    else:
        ids_to_scrape = [i for i in range(args.start, args.end + 1) if i not in scraped_ids]
        print(f"Scraping {len(ids_to_scrape)} IDs ({args.start}-{args.end}), "
              f"{len(scraped_ids)} already done")

    if not ids_to_scrape:
        print("Nothing to scrape — all IDs already processed.")
        export_csv(records)
        print_stats(records)
        return

    new_count = 0
    empty_count = 0

    for i, org_id in enumerate(ids_to_scrape, 1):
        print(f"[{i}/{len(ids_to_scrape)}] org={org_id} ...", end=" ", flush=True)

        data = scrape_page(org_id, api_key)
        if data:
            record = parse_response(org_id, data.get("data", data))
            if record:
                records.append(record)
                new_count += 1
                print(f"OK — {record['name']}")
                if args.test:
                    print_record(record)
                    print()
            else:
                empty_count += 1
                print("EMPTY (no data)")
        else:
            empty_count += 1
            print("FAILED")

        # Save progress periodically
        if new_count > 0 and new_count % SAVE_EVERY == 0:
            save_progress(records)
            print(f"  --- Progress saved: {len(records)} records ---")

        # Rate limiting
        if i < len(ids_to_scrape):
            time.sleep(DELAY_SECONDS)

    # Final save
    save_progress(records)
    print(f"\nDone! New: {new_count}, Empty: {empty_count}")

    # Export CSV
    export_csv(records)
    print_stats(records)


if __name__ == "__main__":
    main()
