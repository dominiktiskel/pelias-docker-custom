# 🇬🇧 United Kingdom Pelias - Quick Start (Dual Instance)

Ten projekt jest skonfigurowany do działania **równolegle** z innymi instancjami Pelias.

## 📝 Konfiguracja

Projekt używa **COMPOSE_PROJECT_NAME** dla czystej konfiguracji. Plik `.env`:
```bash
COMPOSE_PROJECT_NAME=pelias-uk
DATA_DIR=/data/pelias-uk
DOCKER_USER=1000:1000
```

## 🔌 Porty

- **API**: http://localhost:5000 ⚠️ (zmieniony z 4000)
- **Elasticsearch**: http://localhost:9201 ⚠️ (zmieniony z 9200)
- Placeholder: 5100
- PIP: 5200
- Interpolation: 5300
- Libpostal: 5400

## 🐳 Kontenery

Wszystkie kontenery mają prefix `pelias-uk_` i suffix `_1`:
- `pelias-uk_api_1`
- `pelias-uk_elasticsearch_1`
- `pelias-uk_openstreetmap_1`
- itd.

## 🚀 Szybki Start

```bash
cd docker/projects/united-kingdom

# Zmienne środowiskowe są już skonfigurowane w pliku .env
# Możesz je nadpisać jeśli potrzebne:
# export DATA_DIR=/custom/path
# export DOCKER_USER=$(id -u):$(id -g)

# Utwórz katalog danych
mkdir -p /data/pelias-uk

# 1. Start Elasticsearch
docker-compose up -d elasticsearch
sleep 10

# 2. Utwórz index
docker-compose run --rm schema ./bin/create_index

# 3. Pobierz i zaimportuj WhosOnFirst
docker-compose run --rm whosonfirst npm run download
docker-compose run --rm whosonfirst npm start

# 4. Pobierz i zaimportuj OpenStreetMap (custom v1.2)
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openstreetmap npm start

# 5. Uruchom API
docker-compose up -d api placeholder interpolation pip

# 6. Test
curl "http://localhost:5000/v1/search?text=London"
```

## ✨ Funkcje Custom

- ✅ **OSM Admin Priority** - `preferOsmAdmin: true`
- ✅ **Custom Image** - `tiskel/openstreetmap:v1.2`
- ✅ **Postcode Import** - `importPostalcodes: true`

## 📊 Status

```bash
# Kontenery
docker ps --filter "name=pelias-uk_"

# Logi API
docker-compose logs -f api

# Stats Elasticsearch
curl "http://localhost:9201/_cat/indices?v"
```

## 🛑 Zatrzymanie

```bash
docker-compose down
```

## 🧪 Przykładowe Zapytania

```bash
# Search London
curl "http://localhost:5000/v1/search?text=London"

# Search address
curl "http://localhost:5000/v1/search?text=10+Downing+Street+London"

# Autocomplete
curl "http://localhost:5000/v1/autocomplete?text=Manchester"

# Reverse (London coordinates)
curl "http://localhost:5000/v1/reverse?point.lat=51.5074&point.lon=-0.1278"

# Nearby (pubs near London)
curl "http://localhost:5000/v1/search?text=pub&focus.point.lat=51.5074&focus.point.lon=-0.1278"
```

## 📚 Więcej Informacji

- [`../DUAL_INSTANCE_SETUP.md`](../DUAL_INSTANCE_SETUP.md) - Pełna dokumentacja dual instance
- [`pelias.json`](pelias.json) - Konfiguracja
- [`README.md`](README.md) - Oryginalna dokumentacja

---

**⚠️ UWAGA**: Ten projekt używa:
- **COMPOSE_PROJECT_NAME**: `pelias-uk`
- **Własnej sieci**: `pelias-uk_default` (auto-generowanej)
- **Przesuniętych portów**: (5xxx zamiast 4xxx)
- Może działać równolegle z `poland` na tej samej maszynie

