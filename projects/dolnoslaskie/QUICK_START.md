# 🏔️ Dolnośląskie Pelias - Quick Start

Ten projekt jest skonfigurowany dla **województwa dolnośląskiego** (Lower Silesian Voivodeship) i może działać **równolegle** z innymi instancjami Pelias.

## 📍 Region

- **Województwo**: Dolnośląskie
- **Stolica**: Wrocław (51.1079°N, 17.0385°E)
- **Populacja**: ~2.9 mln
- **Powierzchnia**: 19,947 km²
- **Główne miasta**: Wrocław, Wałbrzych, Legnica, Jelenia Góra, Lubin, Głogów

## 🔌 Porty

- **API**: http://localhost:4000
- **Elasticsearch**: http://localhost:9200
- Placeholder: 4100
- PIP: 4200
- Interpolation: 4300
- Libpostal: 4400

## 🐳 Kontenery

Wszystkie kontenery mają prefix `dolnoslaskie_`:
- `dolnoslaskie_api`
- `dolnoslaskie_elasticsearch`
- `dolnoslaskie_openstreetmap`
- itd.

## 🚀 Szybki Start

```bash
cd docker/projects/dolnoslaskie

# Ustaw zmienne środowiskowe
export DATA_DIR=/data/pelias-dolnoslaskie
export DOCKER_USER=$(id -u):$(id -g)

# Windows PowerShell:
# $env:DATA_DIR="C:\data\pelias-dolnoslaskie"
# $env:DOCKER_USER="1000:1000"

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

# 4. Pobierz i zaimportuj OpenStreetMap dla Dolnośląskiego
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openstreetmap npm start

# 5. Opcjonalnie: OpenAddresses dla województwa dolnośląskiego
docker-compose run --rm openaddresses npm run download
docker-compose run --rm openaddresses npm start

# 6. Uruchom API
docker-compose up -d api placeholder interpolation pip

# 7. Test - wyszukaj Wrocław
curl "http://localhost:4000/v1/search?text=Wrocław"

# Inne testy:
curl "http://localhost:4000/v1/search?text=Jelenia+Góra"
curl "http://localhost:4000/v1/search?text=Świdnicka+Wrocław"
curl "http://localhost:4000/v1/reverse?point.lat=51.1079&point.lon=17.0385"
```

## ✨ Funkcje

- ✅ **OSM Admin Priority** - `preferOsmAdmin: true`
- ✅ **Custom Image** - `tiskel/openstreetmap:v1.2`
- ✅ **Regional Extract** - tylko dane dla woj. dolnośląskiego (mniejszy rozmiar)
- ✅ **Geofabrik Extract** - automatyczne pobieranie z Geofabrik
- ✅ **OpenAddresses** - adresy dla województwa dolnośląskiego
- ✅ **Focus Point** - domyślne centrum w Wrocławiu (51.1079, 17.0385)

## 📊 Status

```bash
# Kontenery
docker ps --filter "name=dolnoslaskie_"

# Logi API
docker-compose logs -f api

# Stats Elasticsearch
curl "http://localhost:9200/_cat/indices?v"

# Liczba dokumentów
curl "http://localhost:9200/_cat/count/pelias?v"
```

## 🧪 Testy

```bash
# Uruchom fuzzy tester
docker-compose run --rm fuzzy-tester npm test

# Przykładowe zapytania testowe:
curl "http://localhost:4000/v1/search?text=Rynek+Wrocław"
curl "http://localhost:4000/v1/search?text=Uniwersytet+Wrocławski"
curl "http://localhost:4000/v1/search?text=Zamek+Książ"
curl "http://localhost:4000/v1/search?text=Śnieżka"
```

## 🛑 Zatrzymanie

```bash
# Zatrzymaj wszystkie serwisy
docker-compose down

# Zatrzymaj i usuń dane
docker-compose down -v
```

## 📦 Rozmiar Danych (przybliżony)

- OSM Extract: ~150 MB (dolnoslaskie-latest.osm.pbf)
- OpenAddresses: ~10 MB
- WhosOnFirst: ~50 MB
- Elasticsearch Index: ~500 MB - 1 GB (po imporcie)

**Łączny rozmiar**: ~1-2 GB

## 🗺️ Obszar Geograficzny

Projekt obejmuje:
- Wszystkie powiaty województwa dolnośląskiego
- Granice administracyjne z OSM
- POI (Points of Interest) z OpenStreetMap
- Adresy z OpenAddresses
- Karkonosze i Sudety
- Granice z Czechami i Niemcami

## 📚 Więcej Informacji

- [`README.md`](README.md) - Główna dokumentacja
- [`pelias.json`](pelias.json) - Konfiguracja
- [Geofabrik Downloads](http://download.geofabrik.de/europe/poland.html) - Źródło danych OSM
- [Pelias Documentation](https://github.com/pelias/pelias)

---

**⚠️ UWAGA**: Ten projekt używa **własnej sieci** `pelias_dolnoslaskie` i może działać równolegle z innymi projektami Pelias na tej samej maszynie.

**💡 TIP**: Dla jeszcze mniejszego rozmiaru możesz ograniczyć import tylko do wybranych powiatów modyfikując plik `pelias.json`.

