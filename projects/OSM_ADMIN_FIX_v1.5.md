# ✅ OSM Admin Priority - NAPRAWIONO w v1.5.0

## 🐛 Problem (v1.2 - v1.4.1)

Priorytetyzacja danych admin z OSM **NIE DZIAŁAŁA POPRAWNIE**:

- Adresy z `addr:city="Zacharzyce"` były **błędnie** klasyfikowane do innych miejscowości z WhosOnFirst
- `osm_admin_extractor.js` czytał z `doc.address_parts.city` - ale ta wartość była **zawsze pusta**!
- Tagi `addr:city`, `addr:state`, `addr:country` były zakomentowane w `address_karlsruhe.js` i **nigdy nie trafiały** do `address_parts`

### Przykład błędnego zachowania:

```bash
# Zapytanie:
curl "http://localhost:4000/v1/autocomplete?text=Akacjowa+10,+Zacharzyce&sources=openstreetmap"

# Wynik (BŁĘDNY):
"locality": "Siechnice Obszar Wiejski"  # ❌ z WhosOnFirst
"localadmin": "Gmina Siechnice"        # ❌ z WhosOnFirst

# Powinno być:
"locality": "Zacharzyce"  # ✅ z OSM (addr:city)
```

## ✨ Rozwiązanie w v1.5.0

**Zmieniono `osm_admin_extractor.js` aby czytać BEZPOŚREDNIO z tagów OSM:**

### Przed (v1.2 - v1.4.1):
```javascript
// ❌ Czytało z address_parts (PUSTE!)
const addressParts = doc.address_parts || {};
const value = addressParts['city'];  // undefined
```

### Po (v1.5.0):
```javascript
// ✅ Czyta bezpośrednio z tagów OSM
const tags = doc.getMeta('tags');
const value = tags['addr:city'];  // "Zacharzyce"
```

## 📊 Zmiany w kodzie

### Zmienione pliki:

1. **`openstreetmap/stream/osm_admin_extractor.js`**
   - Przepisany aby czytać z `doc.getMeta('tags')` zamiast `doc.address_parts`
   - Mapowanie: `addr:city` → `locality`, `addr:state` → `region`, `addr:country` → `country`
   - Ulepszone logi debug

2. **`openstreetmap/test/stream/osm_admin_extractor.js`**
   - Wszystkie testy zaktualizowane do użycia `doc.setMeta('tags', {...})`
   - Zamiast `doc.address_parts = {...}`

3. **`openstreetmap/MODIFICATIONS.md`**
   - Dodano changelog dla v1.5.0
   - Zaktualizowano numer wersji

4. **`docker/projects/*/docker-compose.yml`**
   - Zaktualizowano image na `tiskel/openstreetmap:v1.5`

## 🚀 Jak zaktualizować

### 1. Pull nowego obrazu

```bash
docker pull tiskel/openstreetmap:v1.5
```

### 2. Zaktualizuj docker-compose.yml (już zrobione)

```yaml
openstreetmap:
  image: tiskel/openstreetmap:v1.5
```

### 3. Zatrzymaj i usuń stare dane (jeśli chcesz pełny re-import)

```bash
cd docker/projects/dolnoslaskie  # lub poland, portland-metro, itp.

# Zatrzymaj kontenery
docker-compose down

# Usuń stare dane Elasticsearch (OPCJONALNE - tylko jeśli chcesz świeży import)
rm -rf ${DATA_DIR}/elasticsearch/*

# Usuń stary index
docker-compose run --rm elasticsearch curl -XDELETE localhost:9200/pelias
```

### 4. Re-import danych

```bash
# Utwórz nowy index
docker-compose run --rm schema ./bin/create_index

# Import WhosOnFirst (zawsze pierwszy!)
docker-compose run --rm whosonfirst npm start

# Import OpenStreetMap (z nową wersją v1.5)
docker-compose run --rm openstreetmap npm start

# Uruchom API
docker-compose up -d api placeholder interpolation pip
```

## 🧪 Testowanie

### Test 1: Zacharzyce (Polska)

```bash
curl "http://localhost:4000/v1/autocomplete?text=Akacjowa+10,+Zacharzyce&sources=openstreetmap" | jq '.features[0].properties | {name, locality, localadmin, county}'
```

**Oczekiwany wynik:**
```json
{
  "name": "Akacjowa 10",
  "locality": "Zacharzyce",        # ✅ z OSM (addr:city)
  "localadmin": "Gmina Siechnice", # z WOF (brak w OSM)
  "county": "Wrocławski"           # z WOF (brak w OSM)
}
```

### Test 2: Wrocław

```bash
curl "http://localhost:4000/v1/autocomplete?text=aleja+Akacjowa+10-12&sources=openstreetmap" | jq '.features[0].properties | {name, locality}'
```

**Oczekiwany wynik:**
```json
{
  "name": "aleja Akacjowa 10-12",
  "locality": "Wrocław"  # ✅ z OSM
}
```

### Test 3: Logi debug

Sprawdź logi podczas importu:

```bash
docker-compose logs openstreetmap | grep "osm_admin_extractor"
```

**Oczekiwane logi:**
```
info: [osm_admin_extractor] OSM admin prioritization enabled
debug: [osm_admin_extractor] Set parent.locality from OSM tag addr:city {"gid":"openstreetmap:address:...", "osmTag":"addr:city", "parentField":"locality", "value":"Zacharzyce"}
```

## 📈 Porównanie z WhosOnFirst

| Aspekt | WhosOnFirst (WOF) | OpenStreetMap (OSM v1.5) |
|--------|-------------------|---------------------------|
| **Aktualność** | Często przestarzałe | ✅ Na bieżąco aktualizowane |
| **Szczegółowość** | Ogólne granice admin | ✅ Konkretne adresy |
| **Polska** | Wiele błędów | ✅ Bardzo dokładne |
| **Zacharzyce** | ❌ Łączy z Siechnice | ✅ Prawidłowa miejscowość |
| **Małe miejscowości** | ❌ Często brak | ✅ Kompletne dane |

## ⚙️ Konfiguracja

Funkcja jest domyślnie **włączona**. Aby wyłączyć (użyć tylko WOF):

```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": false
    }
  }
}
```

## 🔍 Debugowanie

Jeśli OSM admin nie działa:

1. **Sprawdź logi:**
   ```bash
   docker-compose logs openstreetmap | grep osm_admin_extractor
   ```

2. **Sprawdź konfigurację:**
   ```bash
   cat pelias.json | grep preferOsmAdmin
   ```
   Powinno być: `"preferOsmAdmin": true`

3. **Sprawdź dane OSM:**
   - Czy plik PBF zawiera tagi `addr:city`?
   - Użyj: `osmium tags-filter data.osm.pbf t/addr:city -o /dev/stdout`

4. **Sprawdź WOF lookup:**
   ```bash
   docker-compose logs openstreetmap | grep "wof-admin-lookup"
   ```
   Powinno być: `"Skipping WOF lookup - using OSM data"`

## 📚 Dokumentacja

- **Główna dokumentacja**: [`openstreetmap/README.md`](../../openstreetmap/README.md#osm-administrative-data-priority)
- **Changelog**: [`openstreetmap/MODIFICATIONS.md`](../../openstreetmap/MODIFICATIONS.md#v150-2025-12-22)
- **Testy**: [`openstreetmap/test/stream/osm_admin_extractor.js`](../../openstreetmap/test/stream/osm_admin_extractor.js)

## ✅ Podsumowanie

### Przed v1.5.0:
- ❌ Zacharzyce → "Siechnice Obszar Wiejski" (WOF)
- ❌ Brak priorytetyzacji OSM
- ❌ `osm_admin_extractor` nie działał

### Po v1.5.0:
- ✅ Zacharzyce → "Zacharzyce" (OSM)
- ✅ Priorytetyzacja OSM działa poprawnie
- ✅ WOF wypełnia brakujące pola (county, localadmin)
- ✅ Ulepszone logi debug

---

**Wersja**: v1.5.1 (hotfix dla v1.5.0)  
**Data**: 2025-12-22  
**Docker Image**: `tiskel/openstreetmap:v1.5.1`  
**Status**: ✅ **NAPRAWIONO I PRZETESTOWANE**

---

## ⚠️ UWAGA: v1.5.0 miała bug!

Jeśli używasz v1.5.0, **natychmiast zaktualizuj do v1.5.1**!

v1.5.0 miała krytyczny bug gdzie `addParent()` otrzymywał `null` zamiast stringa dla `id` parametru, co powodowało warning:
```
warn: Failed to add parent field from OSM tag ... error=invalid document type, expecting: string got: null
```

v1.5.1 naprawia to generując poprawne ID w formacie `osm:locality:cityname`.

