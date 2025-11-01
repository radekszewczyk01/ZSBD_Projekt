import os
import json
import csv

# --- Konfiguracja ---
# Folder główny z plikami JSON
BASE_DIR = r"."
OUTPUT_FILE_MAIN = "dane_bazodanowe.csv"
OUTPUT_FILE_TEXTS = "dane_tekstowe.csv"
WARN_FILE = "ostrzezenia.txt"

# Pełna lista pól z JSON
FIELDS_ALL = [
    "doi", "coreId", "oai", "title", "authors", "publisher",
    "datePublished", "year", "topics", "subject", "downloadUrl",
    "fullTextIdentifier", "journals", "contributors", "abstract",
    "fullText", "enrichments", "rawRecordXml", "identifiers",
    "pdfHashValue", "language", "relations",
]

# Pola krótkie (baza danych)
FIELDS_SHORT = [
    "doi", "coreId", "oai", "title", "authors", "publisher",
    "datePublished", "year", "topics", "subject", "downloadUrl",
    "fullTextIdentifier", "journals", "contributors",
    "pdfHashValue", "language", "relations",
]

# Pola tekstowe (długie treści)
FIELDS_TEXT = ["abstract", "fullText", "enrichments", "rawRecordXml"]
# --- Koniec Konfiguracji ---

records_main = []
records_texts = []
warnings = []

print(f"Rozpoczynam przetwarzanie plików JSON z folderu: {os.path.abspath(BASE_DIR)}")

for root, dirs, files in os.walk(BASE_DIR):
    for file in files:
        if file.lower().endswith(".json"):
            json_path = os.path.join(root, file)
            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                # Sprawdzenie nieznanych pól
                extra_fields = set(data.keys()) - set(FIELDS_ALL)
                if extra_fields:
                    warnings.append(f"{json_path} -> zawiera dodatkowe pola: {', '.join(extra_fields)}")

                # --- Tworzymy rekord bazodanowy (FIELDS_SHORT) ---
                record_main = {}
                for field in FIELDS_SHORT:
                    value = data.get(field, None)
                    
                    # POPRAWKA: Konsekwentnie serializuj listy i słowniki do JSON
                    if isinstance(value, (list, dict)):
                        value = json.dumps(value, ensure_ascii=False)
                    
                    record_main[field] = value
                records_main.append(record_main)

                # --- Tworzymy rekord tekstowy (FIELDS_TEXT) ---
                record_text = {"doi": data.get("doi", None)}
                for field in FIELDS_TEXT:
                    value = data.get(field, None)

                    # POPRAWKA: Konsekwentnie serializuj listy i słowniki do JSON
                    if isinstance(value, (list, dict)):
                        value = json.dumps(value, ensure_ascii=False)
                        
                    record_text[field] = value
                records_texts.append(record_text)

            except Exception as e:
                warnings.append(f"BŁĄD przy pliku {json_path}: {e}")

# --- Zapis wyników ---

# Zapis ostrzeżeń
if warnings:
    with open(WARN_FILE, "w", encoding="utf-8") as wf:
        wf.write("\n".join(warnings))
    print(f"⚠️  Zapisano {len(warnings)} ostrzeżeń do pliku {WARN_FILE}")
else:
    print("✅ Brak ostrzeżeń.")

# Zapis CSV (TSV) dla danych bazodanowych
if records_main:
    try:
        with open(OUTPUT_FILE_MAIN, "w", newline="", encoding="utf-8") as csvfile:
            # POPRAWKA: Użyj tabulatora jako separatora
            writer = csv.DictWriter(csvfile, fieldnames=FIELDS_SHORT, delimiter='\t')
            writer.writeheader()
            writer.writerows(records_main)
        print(f"✅ Zapisano {len(records_main)} rekordów do {OUTPUT_FILE_MAIN} (użyto separatora TAB)")
    except Exception as e:
        print(f"❌ BŁĄD podczas zapisu pliku {OUTPUT_FILE_MAIN}: {e}")
else:
    print("⚠️  Brak danych do zapisania w pliku głównym.")

# Zapis CSV (TSV) dla treści
if records_texts:
    try:
        with open(OUTPUT_FILE_TEXTS, "w", newline="", encoding="utf-8") as csvfile:
            # POPRAWKA: Użyj tabulatora jako separatora
            writer = csv.DictWriter(csvfile, fieldnames=["doi"] + FIELDS_TEXT, delimiter='\t')
            writer.writeheader()
            writer.writerows(records_texts)
        print(f"✅ Zapisano {len(records_texts)} rekordów z treściami do {OUTPUT_FILE_TEXTS} (użyto separatora TAB)")
    except Exception as e:
        print(f"❌ BŁĄD podczas zapisu pliku {OUTPUT_FILE_TEXTS}: {e}")
else:
    print("⚠️  Brak danych tekstowych do zapisania.")

print("--- Zakończono ---")