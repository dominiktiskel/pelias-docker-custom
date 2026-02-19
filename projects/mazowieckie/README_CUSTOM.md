# Custom Pelias Build dla Województwa Mazowieckiego

Ten projekt jest dedykowaną instancją Pelias dla województwa mazowieckiego (Masovian Voivodeship) w Polsce. Używa regionalnego extractu OpenStreetMap i zoptymalizowanej konfiguracji.

## Główne Cechy

### Regional Extract
- **Źródło danych**: Geofabrik extract dla województwa mazowieckiego
- **URL**: `http://download.geofabrik.de/europe/poland/mazowieckie-latest.osm.pbf`
- **Rozmiar**: ~350 MB (zamiast ~1.5 GB dla całej Polski)
- **Aktualizacja**: Codziennie na Geofabrik

### Focus Point
Domyślne centrum wyszukiwania ustawione na Warszawę:
```json
"defaultParameters": {
  "focus.point.lat": 52.2297,
  "focus.point.lon": 21.0122
}
```

To oznacza, że zapytania bez określonej lokalizacji będą preferować wyniki z okolic Warszawy.

### OSM Admin Priority
Projekt używa custom image z priorytetem dla danych administracyjnych z OSM:

```yaml
# docker-compose.yml
openstreetmap:
  image: tiskel/openstreetmap:v2.8.3
```

```json
// pelias.json
"preferOsmAdmin": true
```

Dzięki temu:
- Nazwy miast i gmin są dokładniejsze
- Poprawna hierarchia administracyjna (gmina -> powiat -> województwo)
- Lepsze wyniki dla polskich adresów

### OpenAddresses
Tylko dane dla województwa mazowieckiego:
```json
"files": [
  "pl/mazowieckie"
]
```

## Pokrycie Geograficzne

### Powiaty
Projekt obejmuje wszystkie 42 powiaty województwa mazowieckiego:

**Miasta na prawach powiatu:**
- Warszawa (stolica Polski)
- Ostrołęka
- Płock
- Radom
- Siedlce

**Powiaty ziemskie:**
- białobrzeski
- ciechanowski
- garwoliński
- gostyniński
- grodziski
- grójecki
- kozienicki
- legionowski
- lipski
- łosicki
- makowski
- miński
- mławski
- nowodworski
- ostrołęcki
- ostrowski
- otwocki
- piaseczyński
- płocki
- płoński
- pruszkowski
- przasnyski
- przysuski
- pułtuski
- radomski
- siedlecki
- sierpecki
- sochaczewski
- sokołowski
- szydłowiecki
- warszawski zachodni
- węgrowski
- wołomiński
- wyszkowski
- żuromiński
- zwoleński
- żyrardowski

### Główne Miasta
- **Warszawa** (~1,860,000) - stolica Polski i województwa
- **Radom** (~210,000)
- **Płock** (~120,000)
- **Siedlce** (~77,000)
- **Ostrołęka** (~52,000)
- **Pruszków** (~62,000)
- **Legionowo** (~54,000)
- **Piaseczno** (~50,000)
- **Otwock** (~45,000)
- **Mińsk Mazowiecki** (~41,000)

### Ważne Miejsca
- Stare Miasto w Warszawie (UNESCO)
- Pałac Kultury i Nauki
- Łazienki Królewskie
- Wilanów
- Kampinos (Kampinoski Park Narodowy)
- Żelazowa Wola (miejsce urodzenia Chopina)
- Zamek Królewski w Warszawie
- Płock - najstarsze miasto Mazowsza

## Zmiany względem projektu "Poland"

| Aspekt | Poland | Mazowieckie |
|--------|--------|-------------|
| Rozmiar OSM | ~1.5 GB | ~350 MB |
| OpenAddresses | Wszystkie województwa | Tylko mazowieckie |
| Focus point | Brak | Warszawa (52.2297, 21.0122) |
| Network name | `pelias_poland` | `pelias_mazowieckie` |
| Container prefix | `poland_` | `mazowieckie_` |
| Porty API | 14000 | 24000 |
| Porty ES | 19200 | 29200 |
| Build time | ~2-3 godziny | ~30-45 minut |

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
- **Dysk**: 8 GB wolnego miejsca
- **CPU**: 2 cores

### Czas Budowania
Przybliżone czasy dla standardowego laptopa:

1. Download (z dobrym łączem): ~5-10 min
2. Import OSM: ~15-25 min
3. Import OpenAddresses: ~3-5 min
4. Import WhosOnFirst: ~1-2 min

**Łączny czas**: ~30-45 minut

## Uruchomienie

```bash
cd docker/projects/mazowieckie

# Ustaw zmienne
export DATA_DIR=/data/pelias-mazowieckie
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
# Warszawa - stolica
curl "http://localhost:24000/v1/search?text=Warszawa"

# Pałac Kultury i Nauki
curl "http://localhost:24000/v1/search?text=Pałac+Kultury+i+Nauki"

# Uniwersytet Warszawski
curl "http://localhost:24000/v1/search?text=Uniwersytet+Warszawski"

# Łazienki Królewskie
curl "http://localhost:24000/v1/search?text=Łazienki+Królewskie"

# Radom
curl "http://localhost:24000/v1/search?text=Radom"

# Płock
curl "http://localhost:24000/v1/search?text=Płock"

# Reverse geocoding w centrum Warszawy
curl "http://localhost:24000/v1/reverse?point.lat=52.2297&point.lon=21.0122"
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
    { "sourceURL": "http://download.geofabrik.de/europe/poland/mazowieckie-latest.osm.pbf" },
    { "sourceURL": "http://download.geofabrik.de/europe/poland/lodzkie-latest.osm.pbf" }
  ],
  "import": [
    { "filename": "mazowieckie-latest.osm.pbf" },
    { "filename": "lodzkie-latest.osm.pbf" }
  ]
}
```

## Troubleshooting

### Problem: Brak wyników dla niektórych miejscowości

**Przyczyna**: Dane mogą nie być dostępne w OpenAddresses lub OSM.

**Rozwiązanie**: Sprawdź dostępność na [OpenStreetMap](https://www.openstreetmap.org/) i [OpenAddresses](https://openaddresses.io/).

### Problem: Wyniki spoza województwa mazowieckiego

**Przyczyna**: Geofabrik extracts mogą zawierać dane z obszarów granicznych.

**Rozwiązanie**: To normalne zachowanie - obszary graniczne mogą być częściowo uwzględnione.

### Problem: Długi czas importu

**Rozwiązanie**:
- Sprawdź zasoby systemowe (RAM, CPU)
- Zwiększ wartość `refresh_interval` w Elasticsearch
- Wyłącz niepotrzebne importery
- Mazowieckie jest największym województwem w Polsce - import może trwać dłużej niż dla mniejszych regionów

## Kontakt i Wsparcie

- [Pelias Documentation](https://github.com/pelias/pelias)
- [Geofabrik Downloads](http://download.geofabrik.de/europe/poland.html)
- Main project: `w:/repos/pelias/`

---

**Autor**: Custom build dla Pelias
**Wersja**: 1.0
**Data**: Luty 2026
