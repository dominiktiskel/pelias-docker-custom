# Custom Pelias Build dla Portland Metro z OSM Admin Priority

Ten projekt używa zmodyfikowanej wersji Pelias, która priorytetyzuje dane administracyjne z OpenStreetMap nad Who's on First.

## Zmiany

- **OpenStreetMap Importer**: Używa `tiskel/openstreetmap:v1.0`
  - Priorytetyzuje `addr:city`, `addr:state`, `addr:country` z OSM
  - Fallback do WOF dla brakujących pól
  - Dokładniejsze dane lokalne

## Szybki start

```bash
cd docker/projects/portland-metro

# Ustaw DATA_DIR jeśli jeszcze nie
mkdir -p ./data
echo "DATA_DIR=./data" >> .env

# Uruchom import
pelias elastic start
pelias elastic wait
pelias elastic create
pelias download all
pelias prepare all
pelias import all
pelias compose up
```

## Testowanie

Portland Metro to mniejszy zbiór danych (~100MB), idealny do szybkiego testowania:

**Czas importu**: ~5-10 minut (vs ~1 godzina dla Polski)

### Przykładowe testy

```bash
# Test 1: Adres w Portland
curl "http://localhost:4000/v1/search?text=1901+Main+St+Portland"

# Test 2: Reverse geocoding
curl "http://localhost:4000/v1/reverse?point.lon=-122.650095&point.lat=45.533467"

# Test 3: Autocomplete
curl "http://localhost:4000/v1/autocomplete?text=Powell"
```

### Sprawdzenie logów OSM admin

```bash
# Zobacz czy OSM admin działa
docker logs pelias_openstreetmap 2>&1 | Select-String "osm_admin"

# Powinny pojawić się linie:
# [osm_admin_extractor] OSM admin prioritization enabled
# [osm_admin_extractor] Set parent.locality from OSM tag
```

## Konfiguracja

W `pelias.json`:

```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": true  // ← WŁĄCZONE
    }
  }
}
```

## Różnice względem oficjalnego Pelias

### docker-compose.yml
```yaml
# Oficjalny:
image: pelias/openstreetmap:master

# Custom:
image: tiskel/openstreetmap:v1.0
```

## Porównanie przed/po

### Przed (tylko WOF):
Adres w Portland może mieć nieprecyzyjną lokalizację administracyjną z nieaktualnych danych WOF.

### Po (OSM + WOF):
- Dane z OSM tags (`addr:city`, `addr:state`) są używane jako pierwsze
- WOF uzupełnia brakujące pola (region, county, neighbourhood)
- Dokładniejsze i bardziej aktualne wyniki

## Wyłączenie funkcji

Aby wrócić do standardowego zachowania (tylko WOF):

**Opcja 1**: Zmień w `pelias.json`:
```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": false
    }
  }
}
```

**Opcja 2**: Użyj oficjalnego obrazu:
```yaml
# docker-compose.yml
image: pelias/openstreetmap:master
```

## Troubleshooting

### Problem: Import trwa bardzo długo
**Rozwiązanie**: Portland Metro powinien zaimportować się w 5-10 minut. Jeśli dłużej:
- Sprawdź `docker stats` - czy Elasticsearch ma wystarczająco RAM
- Zwiększ `refresh_interval` w pelias.json

### Problem: Brak danych OSM admin w wynikach
**Rozwiązanie**: 
1. Sprawdź logi: `docker logs pelias_openstreetmap`
2. Nie wszystkie rekordy OSM mają tagi `addr:city` - to normalne
3. WOF będzie używany jako fallback

### Problem: API nie odpowiada
**Rozwiązanie**:
```bash
# Sprawdź status wszystkich serwisów
pelias compose ps

# Sprawdź logi API
docker logs pelias_api
```

## Testowanie modyfikacji

Portland Metro jest idealny do:
- ✅ Szybkiego testowania zmian (mały dataset)
- ✅ Weryfikacji działania OSM admin priority
- ✅ Debugowania przed uruchomieniem większego importu

Po sukcesie możesz użyć tego samego obrazu dla:
- Większych regionów (np. Polska)
- Produkcyjnych deploymentów
- Innych projektów

## Następne kroki

1. ✅ Przetestuj na Portland Metro
2. ✅ Sprawdź wyniki w API
3. ✅ Użyj tego samego obrazu dla Polski
4. ✅ Dostosuj według potrzeb

## Więcej informacji

- `/BUILD_AND_RELEASE.md` - jak zbudować własny obraz
- `/QUICK_START.md` - szybki przewodnik
- `/docker/projects/poland/README_CUSTOM.md` - przykład dla Polski

