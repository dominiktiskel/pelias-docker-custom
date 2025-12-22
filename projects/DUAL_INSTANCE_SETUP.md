# 🌍 Uruchamianie Wielu Instancji Pelias Równolegle

Przewodnik konfiguracji do uruchamiania **Poland** i **United Kingdom** Pelias na jednej maszynie.

## 📊 Konfiguracja Portów

| Serwis | Poland | UK |
|--------|--------|-----|
| **API** (publiczny) | `0.0.0.0:4000` | `0.0.0.0:5000` |
| **Placeholder** | `127.0.0.1:4100` | `127.0.0.1:5100` |
| **PIP Service** | `127.0.0.1:4200` | `127.0.0.1:5200` |
| **Interpolation** | `127.0.0.1:4300` | `127.0.0.1:5300` |
| **Libpostal** | `127.0.0.1:4400` | `127.0.0.1:5400` |
| **Elasticsearch** | `127.0.0.1:9200, 9300` | `127.0.0.1:9201, 9301` |

## 🐳 Nazwy Kontenerów

| Serwis | Poland | UK |
|--------|--------|-----|
| API | `pelias-poland_api_1` | `pelias-uk_api_1` |
| Elasticsearch | `pelias-poland_elasticsearch_1` | `pelias-uk_elasticsearch_1` |
| OpenStreetMap | `pelias-poland_openstreetmap_1` | `pelias-uk_openstreetmap_1` |
| Libpostal | `pelias-poland_libpostal_1` | `pelias-uk_libpostal_1` |
| Placeholder | `pelias-poland_placeholder_1` | `pelias-uk_placeholder_1` |
| PIP | `pelias-poland_pip_1` | `pelias-uk_pip_1` |
| Interpolation | `pelias-poland_interpolation_1` | `pelias-uk_interpolation_1` |
| WhosOnFirst | `pelias-poland_whosonfirst_1` | `pelias-uk_whosonfirst_1` |
| OpenAddresses | `pelias-poland_openaddresses_1` | `pelias-uk_openaddresses_1` |
| CSV Importer | `pelias-poland_csv-importer_1` | `pelias-uk_csv-importer_1` |
| Polylines | `pelias-poland_polylines_1` | `pelias-uk_polylines_1` |
| Schema | `pelias-poland_schema_1` | `pelias-uk_schema_1` |
| Fuzzy Tester | `pelias-poland_fuzzy-tester_1` | `pelias-uk_fuzzy-tester_1` |

**Uwaga**: Suffix `_1` jest automatycznie dodawany przez Docker Compose (numeracja instancji).

## 🌐 Sieci Docker

- **Poland**: `pelias-poland_default`
- **UK**: `pelias-uk_default`

Każdy projekt ma własną izolowaną sieć Docker, automatycznie tworzoną przez Docker Compose.

## 📝 Pliki Konfiguracyjne .env

Każdy projekt używa pliku `.env` do konfiguracji `COMPOSE_PROJECT_NAME`:

**Poland** (`docker/projects/poland/.env`):
```bash
COMPOSE_PROJECT_NAME=pelias-poland
DATA_DIR=/data/pelias-poland
DOCKER_USER=1000:1000
```

**UK** (`docker/projects/united-kingdom/.env`):
```bash
COMPOSE_PROJECT_NAME=pelias-uk
DATA_DIR=/data/pelias-uk
DOCKER_USER=1000:1000
```

## 🚀 Uruchamianie

### Poland

```bash
cd docker/projects/poland

# Zmienne środowiskowe są skonfigurowane w pliku .env
# Możesz je nadpisać jeśli potrzebne:
# export DATA_DIR=/custom/path
# export DOCKER_USER=$(id -u):$(id -g)

# Uruchom wszystkie serwisy
docker-compose up -d

# Sprawdź status
docker-compose ps

# Logi
docker-compose logs -f api
```

**API dostępne na**: http://localhost:4000

### United Kingdom

```bash
cd docker/projects/united-kingdom

# Zmienne środowiskowe są skonfigurowane w pliku .env
# Możesz je nadpisać jeśli potrzebne:
# export DATA_DIR=/custom/path
# export DOCKER_USER=$(id -u):$(id -g)

# Uruchom wszystkie serwisy
docker-compose up -d

# Sprawdź status
docker-compose ps

# Logi
docker-compose logs -f api
```

**API dostępne na**: http://localhost:5000

## 📥 Import Danych

### Poland

```bash
cd docker/projects/poland

# 1. Przygotuj Elasticsearch
docker-compose run --rm schema ./bin/create_index

# 2. Pobierz dane
docker-compose run --rm whosonfirst npm run download
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openaddresses npm run download

# 3. Przygotuj dane
docker-compose run --rm polylines bash -c "npm start"
docker-compose run --rm interpolation npm run download && \
  docker-compose run --rm interpolation npm run import

# 4. Import
docker-compose run --rm whosonfirst npm start
docker-compose run --rm openstreetmap npm start
docker-compose run --rm openaddresses npm start
docker-compose run --rm polylines npm run import

# 5. Uruchom serwisy
docker-compose up -d api placeholder interpolation pip
```

### United Kingdom

```bash
cd docker/projects/united-kingdom

# 1. Przygotuj Elasticsearch
docker-compose run --rm schema ./bin/create_index

# 2. Pobierz dane
docker-compose run --rm whosonfirst npm run download
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openaddresses npm run download

# 3. Przygotuj dane
docker-compose run --rm polylines bash -c "npm start"
docker-compose run --rm interpolation npm run download && \
  docker-compose run --rm interpolation npm run import

# 4. Import
docker-compose run --rm whosonfirst npm start
docker-compose run --rm openstreetmap npm start
docker-compose run --rm openaddresses npm start
docker-compose run --rm polylines npm run import

# 5. Uruchom serwisy
docker-compose up -d api placeholder interpolation pip
```

## 🧪 Testowanie

### Poland API (port 4000)

```bash
# Search
curl "http://localhost:4000/v1/search?text=Warszawa"

# Autocomplete
curl "http://localhost:4000/v1/autocomplete?text=Kraków"

# Reverse
curl "http://localhost:4000/v1/reverse?point.lat=52.2297&point.lon=21.0122"
```

### UK API (port 5000)

```bash
# Search
curl "http://localhost:5000/v1/search?text=London"

# Autocomplete
curl "http://localhost:5000/v1/autocomplete?text=Manchester"

# Reverse
curl "http://localhost:5000/v1/reverse?point.lat=51.5074&point.lon=-0.1278"
```

## 📊 Monitorowanie

### Sprawdź wszystkie kontenery

```bash
# Poland
docker ps --filter "name=pelias-poland_"

# UK
docker ps --filter "name=pelias-uk_"
```

### Elasticsearch stats

```bash
# Poland
curl "http://localhost:9200/_cat/indices?v"

# UK
curl "http://localhost:9201/_cat/indices?v"
```

### Logi wszystkich serwisów

```bash
# Poland
cd docker/projects/poland && docker-compose logs -f

# UK
cd docker/projects/united-kingdom && docker-compose logs -f
```

## 🛑 Zatrzymywanie

### Poland

```bash
cd docker/projects/poland
docker-compose down
```

### UK

```bash
cd docker/projects/united-kingdom
docker-compose down
```

### Wszystko naraz

```bash
cd docker/projects/poland && docker-compose down
cd docker/projects/united-kingdom && docker-compose down
```

## 🗑️ Czyszczenie Danych

### Poland

```bash
cd docker/projects/poland
docker-compose down -v  # Usuwa wolumeny
rm -rf ${DATA_DIR}/*    # Usuwa dane
```

### UK

```bash
cd docker/projects/united-kingdom
docker-compose down -v  # Usuwa wolumeny
rm -rf ${DATA_DIR}/*    # Usuwa dane
```

## ⚠️ Wymagania Systemowe

Dla dwóch równoległych instancji:

- **RAM**: Minimum 16GB (zalecane 32GB)
- **CPU**: Minimum 4 rdzenie (zalecane 8)
- **Dysk**: 
  - Poland: ~50GB (OSM + WOF + OA)
  - UK: ~20GB (OSM + WOF + OA)
  - Elasticsearch: ~30GB (oba indexy)
  - **TOTAL**: ~100GB wolnego miejsca

## 🔧 Troubleshooting

### Konflikt portów

Jeśli widzisz błąd:
```
Error: port is already allocated
```

Sprawdź czy porty są wolne:
```bash
# Linux/Mac
lsof -i :4000
lsof -i :5000

# Windows
netstat -ano | findstr :4000
netstat -ano | findstr :5000
```

### Elasticsearch nie startuje

Zwiększ limity pamięci:
```bash
# Linux
sudo sysctl -w vm.max_map_count=262144

# Docker Desktop
# Settings → Resources → Advanced → Memory: 8GB+
```

### Brak pamięci

Jeśli system ma mało RAM, uruchom tylko jeden projekt naraz:
```bash
# Zatrzymaj Poland
cd docker/projects/poland && docker-compose down

# Uruchom UK
cd docker/projects/united-kingdom && docker-compose up -d
```

## 📝 Różnice między projektami

### Poland
- ✅ Custom OSM image: `tiskel/openstreetmap:v1.2`
- ✅ OSM Admin Priority: `preferOsmAdmin: true`
- ✅ Transit data support
- ✅ COMPOSE_PROJECT_NAME: `pelias-poland`
- Porty: 4000, 4100-4400, 9200-9300
- Kontenery: `pelias-poland_*_1`

### United Kingdom
- ✅ Custom OSM image: `tiskel/openstreetmap:v1.2`
- ✅ OSM Admin Priority: `preferOsmAdmin: true`
- ✅ Postcode import enabled
- ✅ COMPOSE_PROJECT_NAME: `pelias-uk`
- Porty: 5000, 5100-5400, 9201, 9301
- Kontenery: `pelias-uk_*_1`

---

**Aktualizacja**: 2025-12-19  
**Wersja Custom OSM**: v1.2

