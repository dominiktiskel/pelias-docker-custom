# Pelias na Windows — wariant Mini (OSM + własna baza WOF)

Uproszczona instrukcja dla projektu **mazowieckie-mini**: tylko OpenStreetMap, baza WOF przygotowana osobno (`wof-admin-lookup/tools`), bez placeholder, pip, interpolacji. Działają 3 kontenery: Elasticsearch, API, Libpostal.

## Wymagania

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend)
- PowerShell

## Konfiguracja

1. Wejdź do katalogu mini:
   ```powershell
   cd w:\repos\pelias\docker\projects\mazowieckie-mini
   ```

2. W pliku `.env` ustaw `DATA_DIR` (używaj `/`):
   ```
   DATA_DIR=C:/data/pelias-mazowieckie-mini
   ```

3. Utwórz katalog i (opcjonalnie) podkatalog na WOF SQLite:
   ```powershell
   New-Item -ItemType Directory -Force -Path C:\data\pelias-mazowieckie-mini
   New-Item -ItemType Directory -Force -Path C:\data\pelias-mazowieckie-mini\whosonfirst\sqlite
   ```

4. Przygotuj bazę WOF w `wof-admin-lookup/tools` (np. OSM → SQLite) i skopiuj plik `.db` do:
   ```
   C:\data\pelias-mazowieckie-mini\whosonfirst\sqlite\
   ```

## Build i uruchomienie

```powershell
cd w:\repos\pelias\docker\projects\mazowieckie-mini

# 1. Pobierz obrazy
docker compose pull

# 2. Uruchom Elasticsearch
docker compose up -d elasticsearch

# 3. Czekaj na ES (~15–30 s) — port 25200
do {
    Start-Sleep -Seconds 3
    try { $r = Invoke-WebRequest "http://localhost:25200/_cluster/health" -UseBasicParsing -ErrorAction Stop }
    catch { $r = $null }
} while (-not $r -or $r.StatusCode -ne 200)
Write-Host "Elasticsearch gotowy!"

# 4. Utwórz index
docker compose run --rm schema ./bin/create_index

# 5. Pobierz OSM
docker compose run -T --rm openstreetmap ./bin/download

# 6. Import OSM (używa WOF z DATA_DIR/whosonfirst/sqlite/)
docker compose run --rm openstreetmap ./bin/start

# 7. Uruchom API i Libpostal
docker compose up -d api libpostal
```

## Test

- **API:** `http://localhost:25000`
- Przykład: `http://localhost:25000/v1/search?text=Warszawa`

## Przydatne komendy

```powershell
# Status
docker compose ps

# Logi API
docker compose logs -f api

# Liczba dokumentów (ES na porcie 25200)
Invoke-RestMethod "http://localhost:25200/_cat/count/pelias?v"
```

## Zatrzymanie

```powershell
docker compose down
# Z usunięciem danych ES: docker compose down -v
```

## Różnice względem pełnego WINDOWS.md

| Aspekt        | Pełny (WINDOWS.md)     | Mini (ten plik)        |
|---------------|------------------------|-------------------------|
| Projekt       | np. mazowieckie        | mazowieckie-mini        |
| Port API      | 24000                  | 25000                   |
| Port ES       | 29200                  | 25200                   |
| Źródła danych | OSM + WOF + OpenAddresses | Tylko OSM           |
| WOF           | import whosonfirst     | Własna baza SQLite w `whosonfirst/sqlite/` |
| Kontenery na stałe | Wiele (m.in. placeholder, pip) | 3: elasticsearch, api, libpostal |
| Placeholder / interpolacja | Tak | Nie |

Szczegółowe mapowanie komend `pelias` → PowerShell: [WINDOWS.md](WINDOWS.md).
