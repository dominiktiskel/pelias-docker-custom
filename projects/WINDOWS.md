# Uruchamianie Pelias na Windows (PowerShell + Docker Desktop)

Na Windows brakuje skryptu `pelias` (jest to skrypt Bash przeznaczony dla Linux/macOS).
Każda komenda `pelias` to jednak zwykłe wywołanie `docker compose` — poniżej znajdziesz
pełne mapowanie i gotowe polecenia dla PowerShell.

## Wymagania

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) z włączonym WSL2 backend
- PowerShell 5.1+ lub Windows Terminal

## Konfiguracja przed startem

1. Wejdź do katalogu projektu, np.:
   ```powershell
   cd w:\repos\pelias\docker\projects\mazowieckie
   ```

2. Otwórz plik `.env` i ustaw `DATA_DIR` na istniejący folder na twoim dysku
   (używaj `/`, nie `\`):
   ```
   DATA_DIR=C:/data/pelias-mazowieckie
   ```

3. Utwórz ten katalog:
   ```powershell
   New-Item -ItemType Directory -Force -Path C:\data\pelias-mazowieckie
   ```

## Pełny Build (kolejność ma znaczenie)

```powershell
# 1. Pobierz obrazy Docker
docker compose pull

# 2. Uruchom Elasticsearch
docker compose up -d elasticsearch

# 3. Czekaj aż Elasticsearch będzie gotowy (~15-30 s)
#    Uruchamiaj do skutku — oczekuj statusu 200
do {
    Start-Sleep -Seconds 3
    try { $r = Invoke-WebRequest "http://localhost:29200/_cluster/health" -UseBasicParsing -ErrorAction Stop }
    catch { $r = $null }
} while (-not $r -or $r.StatusCode -ne 200)
Write-Host "Elasticsearch gotowy!"

# 4. Utwórz index Pelias
docker compose run --rm schema ./bin/create_index

# 5. Pobierz dane
docker compose run -T --rm whosonfirst    ./bin/download
docker compose run -T --rm openstreetmap  ./bin/download
docker compose run -T --rm openaddresses  ./bin/download

# 6. Importuj dane (kolejno — nie równolegle)
docker compose run --rm whosonfirst   ./bin/start
docker compose run --rm openstreetmap ./bin/start
docker compose run --rm openaddresses "./bin/parallel 1"

# 7. Zbuduj placeholder i interpolację
docker compose run -T --rm placeholder ./cmd/extract.sh
docker compose run -T --rm placeholder ./cmd/build.sh
docker compose run -T --rm interpolation bash ./docker_build.sh

# 8. Uruchom wszystkie serwisy
docker compose up -d
```

## Mapowanie komend pelias → docker compose

| Komenda `pelias`           | Odpowiednik PowerShell                                                        |
|----------------------------|-------------------------------------------------------------------------------|
| `pelias compose pull`      | `docker compose pull`                                                         |
| `pelias elastic start`     | `docker compose up -d elasticsearch`                                          |
| `pelias elastic wait`      | pętla `do { ... } while` jak w kroku 3 powyżej                                |
| `pelias elastic create`    | `docker compose run --rm schema ./bin/create_index`                           |
| `pelias elastic drop`      | `docker compose run --rm schema node scripts/drop_index`                      |
| `pelias elastic status`    | `Invoke-WebRequest http://localhost:29200/_cluster/health`                    |
| `pelias download wof`      | `docker compose run -T --rm whosonfirst ./bin/download`                       |
| `pelias download osm`      | `docker compose run -T --rm openstreetmap ./bin/download`                     |
| `pelias download oa`       | `docker compose run -T --rm openaddresses ./bin/download`                     |
| `pelias import wof`        | `docker compose run --rm whosonfirst ./bin/start`                             |
| `pelias import osm`        | `docker compose run --rm openstreetmap ./bin/start`                           |
| `pelias import oa`         | `docker compose run --rm openaddresses "./bin/parallel 1"`                    |
| `pelias prepare placeholder` | `docker compose run -T --rm placeholder ./cmd/extract.sh` + `./cmd/build.sh` |
| `pelias prepare interpolation` | `docker compose run -T --rm interpolation bash ./docker_build.sh`         |
| `pelias compose up`        | `docker compose up -d`                                                        |
| `pelias compose down`      | `docker compose down`                                                         |
| `pelias compose logs`      | `docker compose logs -f`                                                      |
| `pelias test run`          | `docker compose run --rm fuzzy-tester npm test`                               |

## Przydatne komendy diagnostyczne

```powershell
# Status kontenerów
docker compose ps

# Logi API na żywo
docker compose logs -f api

# Liczba zaindeksowanych dokumentów
Invoke-RestMethod "http://localhost:29200/_cat/count/pelias?v"

# Statystyki per źródło/warstwa
Invoke-RestMethod "http://localhost:29200/pelias/_search?pretty" `
  -Method POST -ContentType "application/json" `
  -Body '{"aggs":{"sources":{"terms":{"field":"source","size":20}}},"size":0}'
```

## Zatrzymanie

```powershell
# Zatrzymaj serwisy (zachowaj dane)
docker compose down

# Zatrzymaj i usuń dane Elasticsearch
docker compose down -v
```

## Uwagi

- **Port API** różni się per projekt — sprawdź `docker-compose.yml` danego projektu.
  Dla mazowieckiego: `http://localhost:24000/v1/search?text=Warszawa`
- **`DATA_DIR`** — używaj zawsze slasha `/`, np. `C:/data/pelias-mazowieckie`.
  Backslash `\` może być traktowany jako znak ucieczki przez `docker compose`.
- **`DOCKER_USER`** — na Windows z Docker Desktop tę zmienną możesz usunąć z `.env`
  (Docker Desktop nie wymaga mapowania UID/GID).
