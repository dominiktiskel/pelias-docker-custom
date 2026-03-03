#!/bin/bash
# prepare-pbf.sh
# Pobiera pliki PBF dla wybranych krajów i scala je w jeden plik za pomocą osmium-tool.
# Wymagania: osmium-tool, wget
# Użycie: bash prepare-pbf.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBF_DIR="$SCRIPT_DIR/pbf"
OUTPUT_FILE="$PBF_DIR/merged.osm.pbf"
THREADS=16

PBF_URLS=(
    "https://download.geofabrik.de/europe/poland-latest.osm.pbf"
    "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf"
    "https://download.geofabrik.de/europe/germany-latest.osm.pbf"
    "https://download.geofabrik.de/europe/spain-latest.osm.pbf"
)

# ─────────────────────────────────────────────
# Funkcje pomocnicze
# ─────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

check_deps() {
    log "Sprawdzanie zależności..."
    command -v wget    >/dev/null 2>&1 || fail "wget nie jest zainstalowany. Uruchom: apt-get install -y wget"
    command -v osmium  >/dev/null 2>&1 || fail "osmium-tool nie jest zainstalowany. Uruchom: apt-get install -y osmium-tool"
    log "Zależności OK."
}

download_pbf() {
    mkdir -p "$PBF_DIR"
    log "Pobieranie plików PBF do: $PBF_DIR"

    for url in "${PBF_URLS[@]}"; do
        filename="$(basename "$url")"
        dest="$PBF_DIR/$filename"

        if [[ -f "$dest" ]]; then
            log "  Plik już istnieje, pomijam: $filename"
        else
            log "  Pobieranie: $filename"
            wget --progress=bar:force:noscroll -O "$dest" "$url"
            log "  Pobrano: $filename"
        fi
    done
}

merge_pbf() {
    log "Scalanie plików PBF..."
    log "  Wyjście: $OUTPUT_FILE"
    log "  Wątki:   $THREADS"

    local files=()
    for url in "${PBF_URLS[@]}"; do
        files+=("$PBF_DIR/$(basename "$url")")
    done

    # Wyświetl rozmiary plików wejściowych
    for f in "${files[@]}"; do
        size=$(du -sh "$f" | cut -f1)
        log "  Plik wejściowy: $(basename "$f") ($size)"
    done

    osmium merge \
        "${files[@]}" \
        --output="$OUTPUT_FILE" \
        --overwrite \
        --progress

    local out_size
    out_size=$(du -sh "$OUTPUT_FILE" | cut -f1)
    log "Scalanie zakończone. Plik wynikowy: $OUTPUT_FILE ($out_size)"
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
log "=== Przygotowanie PBF dla: Polska, Wielka Brytania, Niemcy, Hiszpania ==="
check_deps
download_pbf
merge_pbf
log "=== Gotowe. Uruchom teraz: docker compose up -d ==="
