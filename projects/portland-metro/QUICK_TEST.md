# 🚀 Szybki test Custom Pelias - Portland Metro

Portland Metro to idealny projekt do przetestowania modyfikacji - mały, szybki import (~5-10 minut).

## Przygotowanie

```powershell
cd w:\repos\pelias\docker\projects\portland-metro

# Ustaw DATA_DIR jeśli jeszcze nie masz
mkdir data
echo "DATA_DIR=./data" > .env

# Lub edytuj .env i dodaj:
# DATA_DIR=W:\pelias-data\portland-metro
```

## Krok 1: Start Elasticsearch

```powershell
pelias elastic start
pelias elastic wait
pelias elastic create
```

**Czas**: ~30 sekund

## Krok 2: Pobierz dane

```powershell
# Pobierz WhosOnFirst (baseline)
pelias download wof

# Pobierz OpenStreetMap (~100MB)
pelias download osm

# Opcjonalnie: OpenAddresses
# pelias download oa
```

**Czas**: ~2-5 minut (zależnie od prędkości internetu)

## Krok 3: Prepare

```powershell
# Przygotuj placeholder (WOF)
pelias prepare placeholder

# Opcjonalnie: interpolacja (zajmuje dłużej)
# pelias prepare interpolation
```

**Czas**: ~1-2 minuty

## Krok 4: Import z NOWĄ LOGIKĄ! 🎉

```powershell
# Import WOF
pelias import wof

# Import OSM z priorytetem OSM admin!
pelias import osm

# Opcjonalnie: OpenAddresses
# pelias import oa
```

**Czas**: ~5-10 minut

### Co się dzieje podczas importu:

```
[osm_admin_extractor] OSM admin prioritization enabled  ← NOWA LOGIKA WŁĄCZONA!
[osm_admin_extractor] Set parent.locality from OSM tag  ← Używa danych z OSM
[wof-admin-lookup] Skipping WOF - using OSM data       ← WOF pominięty dla OSM danych
```

## Krok 5: Uruchom API

```powershell
pelias compose up
```

API będzie dostępne na: http://localhost:4000

## 🧪 Testowanie

### Test 1: Podstawowe wyszukiwanie

```powershell
# PowerShell
Invoke-WebRequest "http://localhost:4000/v1/search?text=Portland" | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Lub w przeglądarce:
# http://localhost:4000/v1/search?text=Portland
```

### Test 2: Konkretny adres

```powershell
curl "http://localhost:4000/v1/search?text=1901+Main+St+Portland"
```

Sprawdź pole `parent` w wynikach - powinno zawierać dane z OSM jeśli były dostępne.

### Test 3: Reverse Geocoding

```powershell
curl "http://localhost:4000/v1/reverse?point.lon=-122.650095&point.lat=45.533467"
```

### Test 4: Autocomplete

```powershell
curl "http://localhost:4000/v1/autocomplete?text=Powell+Blvd"
```

## 🔍 Weryfikacja OSM Admin Priority

### Sprawdź logi importu:

```powershell
docker logs pelias_openstreetmap | Select-String "osm_admin"
```

Powinny pokazać się:
```
[osm_admin_extractor] OSM admin prioritization enabled
[osm_admin_extractor] Set parent.locality from OSM tag
[osm_admin_extractor] Populated admin fields from OSM
```

### Sprawdź statystyki Elasticsearch:

```powershell
curl "http://localhost:9200/pelias/_count?pretty"
```

### Zobacz przykładowy dokument:

```powershell
curl "http://localhost:9200/pelias/_search?pretty&size=1"
```

Sprawdź czy `parent.locality`, `parent.region`, `parent.country` są wypełnione.

## 📊 Oczekiwane wyniki

### Import Portland Metro:

- **WhosOnFirst**: ~200 dokumentów (miasta, dzielnice)
- **OpenStreetMap**: ~40,000-60,000 dokumentów (adresy, POI)
- **Czas całkowity**: ~10-15 minut
- **Rozmiar**: ~500MB z danymi

### Statystyki:

```bash
pelias elastic stats
```

Powinno pokazać coś jak:
```
openstreetmap  address    25000
openstreetmap  venue      20000
whosonfirst    locality     150
whosonfirst    region        50
```

## ✅ Co sprawdzić:

1. ✅ Logi pokazują "OSM admin prioritization enabled"
2. ✅ API odpowiada na porcie 4000
3. ✅ Wyszukiwanie Portland zwraca wyniki
4. ✅ Parent fields są wypełnione
5. ✅ Elasticsearch ma dokumenty (curl stats)

## 🐛 Troubleshooting

### Problem: "ERROR: Docker is not running"
**Rozwiązanie**: Uruchom Docker Desktop

### Problem: "Port 9200 already in use"
**Rozwiązanie**: 
```powershell
pelias elastic stop
# lub
docker stop pelias_elasticsearch
docker rm pelias_elasticsearch
```

### Problem: Import bardzo wolny
**Rozwiązanie**: 
- Zwiększ RAM dla Docker (Docker Desktop → Settings → Resources)
- Zalecane minimum: 8GB RAM

### Problem: Brak wyników w API
**Rozwiązanie**:
```powershell
# Sprawdź czy indexowanie się zakończyło
curl "http://localhost:9200/_cat/indices?v"

# Sprawdź logi API
docker logs pelias_api
```

## 🎯 Następne kroki

Po sukcesie z Portland Metro:

1. **Przetestuj inne miasto**: Zmień w pelias.json na inne OSM PBF
2. **Przetestuj Polskę**: Użyj tego samego obrazu dla `/docker/projects/poland`
3. **Dostosuj konfigurację**: Dodaj więcej źródeł danych (OpenAddresses, Transit)

## ⚡ Szybkie komendy

```powershell
# Restart wszystkiego od zera
pelias compose down
pelias elastic drop
rm -r data/* -Force
# Potem zacznij od Krok 1

# Sprawdź status
pelias compose ps

# Zobacz logi wszystkich serwisów
pelias compose logs

# Import tylko OSM (bez WOF, bez OA)
pelias import osm

# Zatrzymaj wszystko
pelias compose down
```

## 📝 Notatki

- Portland Metro ma dobre pokrycie OSM tags
- Idealny do testowania przed większym importem
- Wyniki powinny być widoczne w ~15 minut od rozpoczęcia
- Custom image `tiskel/openstreetmap:v1.0` jest gotowy na Docker Hub

---

**Powodzenia z testem!** 🚀

Jeśli wszystko działa, to samo rozwiązanie zadziała dla Polski i innych regionów.

