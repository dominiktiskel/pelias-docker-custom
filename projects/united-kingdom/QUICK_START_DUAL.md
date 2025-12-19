# 🇬🇧 United Kingdom Pelias - Quick Start (Dual Instance)

Ten projekt jest skonfigurowany do działania **równolegle** z innymi instancjami Pelias.

## 🔌 Porty

- **API**: http://localhost:5000 ⚠️ (zmieniony z 4000)
- **Elasticsearch**: http://localhost:9201 ⚠️ (zmieniony z 9200)
- Placeholder: 5100
- PIP: 5200
- Interpolation: 5300
- Libpostal: 5400

## 🐳 Kontenery

Wszystkie kontenery mają prefix `uk_`:
- `uk_api`
- `uk_elasticsearch`
- `uk_openstreetmap`
- itd.

## 🚀 Szybki Start

```bash
cd docker/projects/united-kingdom

# Ustaw zmienne środowiskowe
export DATA_DIR=/data/pelias-uk
export DOCKER_USER=$(id -u):$(id -g)

# Utwórz katalog danych
mkdir -p $DATA_DIR

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
docker ps --filter "name=uk_"

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

**⚠️ UWAGA**: Ten projekt używa **własnej sieci** `pelias_uk` i **przesuniętych portów** (5xxx zamiast 4xxx) aby działać równolegle z `poland` na tej samej maszynie.

