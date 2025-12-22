# 🇵🇱 Poland Pelias - Quick Start (Dual Instance)

Ten projekt jest skonfigurowany do działania **równolegle** z innymi instancjami Pelias.

## 📝 Konfiguracja

Projekt używa **COMPOSE_PROJECT_NAME** dla czystej konfiguracji. Plik `.env`:
```bash
COMPOSE_PROJECT_NAME=pelias-poland
DATA_DIR=/data/pelias-poland
DOCKER_USER=1000:1000
```

## 🔌 Porty

- **API**: http://localhost:4000
- **Elasticsearch**: http://localhost:9200
- Placeholder: 4100
- PIP: 4200
- Interpolation: 4300
- Libpostal: 4400

## 🐳 Kontenery

Wszystkie kontenery mają prefix `pelias-poland_` i suffix `_1`:
- `pelias-poland_api_1`
- `pelias-poland_elasticsearch_1`
- `pelias-poland_openstreetmap_1`
- itd.

## 🚀 Szybki Start

```bash
cd docker/projects/poland

# Zmienne środowiskowe są już skonfigurowane w pliku .env
# Możesz je nadpisać jeśli potrzebne:
# export DATA_DIR=/custom/path
# export DOCKER_USER=$(id -u):$(id -g)

# Utwórz katalog danych
mkdir -p /data/pelias-poland

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
curl "http://localhost:4000/v1/search?text=Warszawa"
```

## ✨ Funkcje Custom

- ✅ **OSM Admin Priority** - `preferOsmAdmin: true`
- ✅ **Custom Image** - `tiskel/openstreetmap:v1.2`
- ✅ **Transit Support** - dane transportu publicznego

## 📊 Status

```bash
# Kontenery
docker ps --filter "name=pelias-poland_"

# Logi API
docker-compose logs -f api

# Stats Elasticsearch
curl "http://localhost:9200/_cat/indices?v"
```

## 🛑 Zatrzymanie

```bash
docker-compose down
```

## 📚 Więcej Informacji

- [`../DUAL_INSTANCE_SETUP.md`](../DUAL_INSTANCE_SETUP.md) - Pełna dokumentacja dual instance
- [`README_CUSTOM.md`](README_CUSTOM.md) - Dokumentacja custom features
- [`pelias.json`](pelias.json) - Konfiguracja

---

**⚠️ UWAGA**: Ten projekt używa:
- **COMPOSE_PROJECT_NAME**: `pelias-poland`
- **Własnej sieci**: `pelias-poland_default` (auto-generowanej)
- Może działać równolegle z `united-kingdom` na tej samej maszynie

