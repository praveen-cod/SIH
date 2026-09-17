"""
HealthCall AI - SQLite Database Viewer Utility
Run this script to inspect tables and records in healthcall.db:
    python backend/view_db.py
Or inspect a specific table:
    python backend/view_db.py users
    python backend/view_db.py consultations
    python backend/view_db.py doctors
"""

import sys
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent / "healthcall.db"

def get_connection():
    if not DB_PATH.exists():
        print(f"[!] Database file not found at: {DB_PATH}")
        sys.exit(1)
    return sqlite3.connect(DB_PATH)

def show_overview():
    conn = get_connection()
    cur = conn.cursor()
    
    print("\n" + "=" * 60)
    print(f" HEALTHCALL AI - SQLITE DATABASE OVERVIEW")
    print(f" Location: {DB_PATH.resolve()}")
    print("=" * 60)

    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
    tables = [r[0] for r in cur.fetchall()]

    if not tables:
        print("No tables found.")
        return

    for table in tables:
        cur.execute(f"SELECT COUNT(*) FROM {table};")
        count = cur.fetchone()[0]
        cur.execute(f"PRAGMA table_info({table});")
        columns = [col[1] for col in cur.fetchall()]
        print(f"\n Table: {table.upper()} ({count} records)")
        print(f"   Columns: {', '.join(columns)}")

    print("\n" + "=" * 60)
    print("Tip: Run 'python backend/view_db.py <table_name>' to view table records.")
    print("=" * 60 + "\n")
    conn.close()

def show_table(table_name: str, limit: int = 15):
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        cur.execute(f"PRAGMA table_info({table_name});")
        cols_info = cur.fetchall()
        if not cols_info:
            print(f"[!] Table '{table_name}' does not exist.")
            return

        col_names = [col[1] for col in cols_info]
        cur.execute(f"SELECT COUNT(*) FROM {table_name};")
        total = cur.fetchone()[0]

        cur.execute(f"SELECT * FROM {table_name} ORDER BY 1 DESC LIMIT {limit};")
        rows = cur.fetchall()

        print("\n" + "=" * 70)
        print(f" TABLE: {table_name.upper()} (Total: {total} rows | Showing latest {min(len(rows), limit)})")
        print("=" * 70)
        
        for i, row in enumerate(rows, 1):
            print(f"\n--- [Row {i}] ---")
            for col, val in zip(col_names, row):
                # Truncate long strings (e.g. AI summaries or password hashes) for readability
                sval = str(val)
                if len(sval) > 100:
                    sval = sval[:97] + "..."
                print(f"  {col:<22}: {sval}")

        print("\n" + "=" * 70 + "\n")
    except Exception as e:
        print(f"[!] Error querying table '{table_name}': {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        show_table(sys.argv[1])
    else:
        show_overview()
