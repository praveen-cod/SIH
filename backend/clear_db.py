import sqlite3
import os

db_path = "healthcall.db"

def clear_patient_data():
    if not os.path.exists(db_path):
        print(f"Database {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    tables_to_clear = [
        'patient_demographics',
        'medical_history',
        'medications',
        'lab_results',
        'vital_signs',
        'diagnoses',
        'patient_documents',
        'allergies',
        'procedures',
        'family_history',
        'reproductive_status'
    ]

    for table in tables_to_clear:
        try:
            cursor.execute(f"DELETE FROM {table}")
            print(f"Cleared {table}")
        except sqlite3.OperationalError as e:
            print(f"Could not clear {table}: {e}")

    conn.commit()
    conn.close()
    print("All patient medical data and documents cleared successfully.")

if __name__ == "__main__":
    clear_patient_data()
