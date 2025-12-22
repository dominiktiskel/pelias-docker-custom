# Custom Pelias Build dla Województwa Dolnośląskiego

Ten projekt jest dedykowaną instancją Pelias dla województwa dolnośląskiego (Lower Silesian Voivodeship) w Polsce. Używa regionalnego extractu OpenStreetMap i zoptymalizowanej konfiguracji.

## Główne Cechy

### 🗺️ Regional Extract
- **Źródło danych**: Geofabrik extract dla województwa dolnośląskiego
- **URL**: `http://download.geofabrik.de/europe/poland/dolnoslaskie-latest.osm.pbf`
- **Rozmiar**: ~150 MB (zamiast ~1.5 GB dla całej Polski)
- **Aktualizacja**: Codziennie na Geofabrik

### 🎯 Focus Point
Domyślne centrum wyszukiwania ustawione na Wrocław:
```json
"defaultParameters": {
  "focus.point.lat": 51.1079,
  "focus.point.lon": 17.0385
}
```

To oznacza, że zapytania bez określonej lokalizacji będą preferować wyniki z okolic Wrocławia.

### 🏛️ OSM Admin Priority
Projekt używa custom image z priorytetem dla danych administracyjnych z OSM:

```yaml
# docker-compose.yml
openstreetmap:
  image: tiskel/openstreetmap:v1.5.1
```

```json
// pelias.json
"preferOsmAdmin": true
```

Dzięki temu:
- Nazwy miast i gmin są dokładniejsze
- Poprawna hierarchia administracyjna (gmina → powiat → województwo)
- Lepsze wyniki dla polskich adresów

### 📮 OpenAddresses
Tylko dane dla województwa dolnośląskiego:
```json
"files": [
  "pl/dolnoslaskie"
]
```

## Pokrycie Geograficzne

### Powiaty
Projekt obejmuje wszystkie 30 powiatów województwa dolnośląskiego:

**Miasta na prawach powiatu:**
- Jelenia Góra
- Legnica
- Wałbrzych
- Wrocław

**Powiaty ziemskie:**
- bolesławiecki
- dzierżoniowski
- głogowski
- górowski
- jaworzymport
- jeleniogórski
- kamiennogórski
- kłodzki
- legnicki
- lubański
- lubiński
- lwówecki
- milicki
- oleśnicki
- oławski
- polkowicki
- strzeliński
- średzki
- świdnicki
- trzebnicki
- wałbrzyski
- wołowski
- wrocławski
- ząbkowicki
- zgorzelecki
- złotoryjski

### Główne Miasta
- **Wrocław** (~640,000) - stolica województwa
- **Wałbrzych** (~110,000)
- **Legnica** (~100,000)
- **Jelenia Góra** (~80,000)
- **Lubin** (~70,000)
- **Głogów** (~65,000)
- **Świdnica** (~55,000)
- **Bolesławiec** (~38,000)

### Obszary Turystyczne
- Karkonosze (w tym Śnieżka)
- Góry Sowie
- Góry Stołowe
- Góry Sowie
- Sudety Zachodnie i Środkowe
- Kotlina Jeleniogórska
- Kotlina Kłodzka

## Zmiany względem projektu "Poland"

| Aspekt | Poland | Dolnośląskie |
|--------|--------|--------------|
| Rozmiar OSM | ~1.5 GB | ~150 MB |
| OpenAddresses | Wszystkie województwa | Tylko dolnośląskie |
| Focus point | Brak | Wrocław (51.1079, 17.0385) |
| Network name | `pelias_poland` | `pelias_dolnoslaskie` |
| Container prefix | `poland_` | `dolnoslaskie_` |
| Build time | ~2-3 godziny | ~20-30 minut |

## Optymalizacja Wydajności

### Elasticsearch Settings
```json
"number_of_replicas": "0",  // single node
"number_of_shards": "1",    // regionalny dataset
"refresh_interval": "10s"   // szybsze importy
```

### Pamięć
Rekomendowane minimum:
- **RAM**: 4 GB (8 GB zalecane)
- **Dysk**: 5 GB wolnego miejsca
- **CPU**: 2 cores

### Czas Budowania
Przybliżone czasy dla standardowego laptopa:

1. Download (z dobrym łączem): ~2-5 min
2. Import OSM: ~10-15 min
3. Import OpenAddresses: ~2-3 min
4. Import WhosOnFirst: ~1-2 min

**Łączny czas**: ~20-30 minut

## Uruchomienie

```bash
cd docker/projects/dolnoslaskie

# Ustaw zmienne
export DATA_DIR=/data/pelias-dolnoslaskie
export DOCKER_USER=$(id -u):$(id -g)

# Pełny build
docker-compose up -d elasticsearch
sleep 10
docker-compose run --rm schema ./bin/create_index
docker-compose run --rm whosonfirst npm run download
docker-compose run --rm whosonfirst npm start
docker-compose run --rm openstreetmap ./bin/download
docker-compose run --rm openstreetmap npm start
docker-compose run --rm openaddresses npm run download
docker-compose run --rm openaddresses npm start
docker-compose up -d api placeholder interpolation pip
```

## Testowanie

### Podstawowe Zapytania

```bash
# Wrocław - główne miasto
curl "http://localhost:4000/v1/search?text=Wrocław"

# Rynek we Wrocławiu
curl "http://localhost:4000/v1/search?text=Rynek+Wrocław"

# Uniwersytet Wrocławski
curl "http://localhost:4000/v1/search?text=Uniwersytet+Wrocławski"

# Zamek Książ w Wałbrzychu
curl "http://localhost:4000/v1/search?text=Zamek+Książ"

# Śnieżka (najwyższy szczyt Karkonoszy)
curl "http://localhost:4000/v1/search?text=Śnieżka"

# Jelenia Góra
curl "http://localhost:4000/v1/search?text=Jelenia+Góra"

# Reverse geocoding w centrum Wrocławia
curl "http://localhost:4000/v1/reverse?point.lat=51.1079&point.lon=17.0385"
```

### Fuzzy Tests

```bash
docker-compose run --rm fuzzy-tester npm test
```

## Aktualizacja Danych

Dane OSM na Geofabrik są aktualizowane codziennie:

```bash
# Pobierz nowe dane
docker-compose run --rm openstreetmap ./bin/download

# Usuń stare dane z ES
docker-compose run --rm schema node scripts/drop_index.js

# Utwórz nowy index
docker-compose run --rm schema ./bin/create_index

# Reimportuj
docker-compose run --rm whosonfirst npm start
docker-compose run --rm openstreetmap npm start
docker-compose run --rm openaddresses npm start

# Restart API
docker-compose restart api
```

## Rozszerzenie Pokrycia

Jeśli chcesz rozszerzyć pokrycie na sąsiednie województwa, możesz zmodyfikować `pelias.json`:

```json
"openstreetmap": {
  "download": [
    { "sourceURL": "http://download.geofabrik.de/europe/poland/dolnoslaskie-latest.osm.pbf" },
    { "sourceURL": "http://download.geofabrik.de/europe/poland/opolskie-latest.osm.pbf" }
  ],
  "import": [
    { "filename": "dolnoslaskie-latest.osm.pbf" },
    { "filename": "opolskie-latest.osm.pbf" }
  ]
}
```

## Troubleshooting

### Problem: Brak wyników dla niektórych miejscowości

**Przyczyna**: Dane mogą nie być dostępne w OpenAddresses lub OSM.

**Rozwiązanie**: Sprawdź dostępność na [OpenStreetMap](https://www.openstreetmap.org/) i [OpenAddresses](https://openaddresses.io/).

### Problem: Wyniki spoza województwa dolnośląskiego

**Przyczyna**: Geofabrik extracts mogą zawierać dane z obszarów granicznych.

**Rozwiązanie**: To normalne zachowanie - obszary graniczne mogą być częściowo uwzględnione.

### Problem: Długi czas importu

**Rozwiązanie**: 
- Sprawdź zasoby systemowe (RAM, CPU)
- Zwiększ wartość `refresh_interval` w Elasticsearch
- Wyłącz niepotrzebne importery

## Kontakt i Wsparcie

- [Pelias Documentation](https://github.com/pelias/pelias)
- [Geofabrik Downloads](http://download.geofabrik.de/europe/poland.html)
- Main project: `w:/repos/pelias/`

---

**Autor**: Custom build dla Pelias  
**Wersja**: 1.0  
**Data**: Grudzień 2025

