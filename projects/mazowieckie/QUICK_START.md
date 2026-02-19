# Mazowieckie Pelias - Quick Start

Ten projekt jest skonfigurowany dla **województwa mazowieckiego** (Masovian Voivodeship) i może działać **równolegle** z innymi instancjami Pelias.

## Region

- **Województwo**: Mazowieckie
- **Stolica**: Warszawa (52.2297°N, 21.0122°E)
- **Populacja**: ~5.4 mln
- **Powierzchnia**: 35,558 km²
- **Główne miasta**: Warszawa, Radom, Płock, Siedlce, Ostrołęka, Pruszków, Legionowo

## Porty

- **API**: http://localhost:24000
- **Elasticsearch**: http://localhost:29200
- Placeholder: 24100
- PIP: 24200
- Interpolation: 24300
- Libpostal: 24400

## Kontenery

Wszystkie kontenery mają prefix `mazowieckie_`:
- `mazowieckie_api`
- `mazowieckie_elasticsearch`
- `mazowieckie_openstreetmap`
- itd.

## Szybki Start

```bash
cd docker/projects/mazowieckie

# Ustaw zmienne środowiskowe
export DATA_DIR=/data/pelias-mazowieckie
export DOCKER_USER=$(id -u):$(id -g)

# Windows PowerShell:
# $env:DATA_DIR="C:\data\pelias-mazowieckie"
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

# 4. Pobierz i zaimportuj OpenStreetMap dla Mazowieckiego
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openstreetmap npm start

# 5. Opcjonalnie: OpenAddresses dla województwa mazowieckiego
docker-compose run --rm openaddresses npm run download
docker-compose run --rm openaddresses npm start

# 6. Uruchom API
docker-compose up -d api placeholder interpolation pip

# 7. Test - wyszukaj Warszawę
curl "http://localhost:24000/v1/search?text=Warszawa"

# Inne testy:
curl "http://localhost:24000/v1/search?text=Radom"
curl "http://localhost:24000/v1/search?text=Nowy+Świat+Warszawa"
curl "http://localhost:24000/v1/reverse?point.lat=52.2297&point.lon=21.0122"
```

## Funkcje

- **OSM Admin Priority** - `preferOsmAdmin: true`
- **Custom Image** - `tiskel/openstreetmap:v2.8.3`
- **Regional Extract** - tylko dane dla woj. mazowieckiego (mniejszy rozmiar)
- **Geofabrik Extract** - automatyczne pobieranie z Geofabrik
- **OpenAddresses** - adresy dla województwa mazowieckiego
- **Focus Point** - domyślne centrum w Warszawie (52.2297, 21.0122)

## Status

```bash
# Kontenery
docker ps --filter "name=mazowieckie_"

# Logi API
docker-compose logs -f api

# Stats Elasticsearch
curl "http://localhost:29200/_cat/indices?v"

# Liczba dokumentów
curl "http://localhost:29200/_cat/count/pelias?v"
```

## Testy

```bash
# Uruchom fuzzy tester
docker-compose run --rm fuzzy-tester npm test

# Przykładowe zapytania testowe:
curl "http://localhost:24000/v1/search?text=Pałac+Kultury+i+Nauki"
curl "http://localhost:24000/v1/search?text=Uniwersytet+Warszawski"
curl "http://localhost:24000/v1/search?text=Łazienki+Królewskie"
curl "http://localhost:24000/v1/search?text=Żelazowa+Wola"
```

## Zatrzymanie

```bash
# Zatrzymaj wszystkie serwisy
docker-compose down

# Zatrzymaj i usuń dane
docker-compose down -v
```

## Rozmiar Danych (przybliżony)

- OSM Extract: ~350 MB (mazowieckie-latest.osm.pbf)
- OpenAddresses: ~15 MB
- WhosOnFirst: ~50 MB
- Elasticsearch Index: ~1-2 GB (po imporcie)

**Łączny rozmiar**: ~2-3 GB

## Obszar Geograficzny

Projekt obejmuje:
- Wszystkie powiaty województwa mazowieckiego
- Granice administracyjne z OSM
- POI (Points of Interest) z OpenStreetMap
- Adresy z OpenAddresses
- Kampinoski Park Narodowy
- Puszcza Kampinoska
- Dolina Wisły

## Więcej Informacji

- [`README.md`](README.md) - Główna dokumentacja
- [`README_CUSTOM.md`](README_CUSTOM.md) - Szczegółowa dokumentacja
- [`pelias.json`](pelias.json) - Konfiguracja
- [Geofabrik Downloads](http://download.geofabrik.de/europe/poland.html) - Źródło danych OSM
- [Pelias Documentation](https://github.com/pelias/pelias)

---

**UWAGA**: Ten projekt używa **własnej sieci** `pelias_mazowieckie` i może działać równolegle z innymi projektami Pelias na tej samej maszynie.

**TIP**: Mazowieckie jest największym województwem w Polsce, więc import może trwać dłużej niż dla mniejszych regionów. Zarezerwuj co najmniej 30-45 minut na pełny build.
