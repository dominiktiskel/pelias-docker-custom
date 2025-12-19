# Custom Pelias Build dla Polski z OSM Admin Priority

Ten projekt używa zmodyfikowanej wersji Pelias, która priorytetyzuje dane administracyjne z OpenStreetMap nad Who's on First.

## Zmiany

- **OpenStreetMap Importer**: Używa `tiskel/openstreetmap:custom-admin`
  - Priorytetyzuje `addr:city`, `addr:state`, `addr:country` z OSM
  - Fallback do WOF dla brakujących pól
  - Dokładniejsze dane dla polskich miast

## Różnice względem oficjalnego Pelias

### docker-compose.yml
```yaml
# Oficjalny:
image: pelias/openstreetmap:master

# Custom:
image: tiskel/openstreetmap:custom-admin
```

## Konfiguracja

W `pelias.json` możesz kontrolować zachowanie:

```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": true  // domyślnie true
    }
  }
}
```

Ustaw `preferOsmAdmin: false` aby wrócić do standardowego zachowania (tylko WOF).

## Uruchomienie importu

```bash
# Standardowy proces, ale z custom image
pelias elastic start
pelias elastic wait
pelias elastic create
pelias download all
pelias prepare all
pelias import all
pelias compose up
```

## Aktualizacja do nowej wersji custom image

```bash
# Ściągnij najnowszą wersję
docker pull tiskel/openstreetmap:custom-admin

# Lub konkretną wersję
docker pull tiskel/openstreetmap:custom-admin-v1.0

# Restart importu
pelias import osm
```

## Weryfikacja

Sprawdź czy używasz właściwego obrazu:

```bash
docker-compose config | grep -A3 openstreetmap
```

Sprawdź logi podczas importu:

```bash
docker logs -f pelias_openstreetmap
```

Powinny pojawić się logi:
```
[osm_admin_extractor] OSM admin prioritization enabled
[osm_admin_extractor] Set parent.locality from OSM tag
```

## Testowanie wyników

Po imporcie możesz przetestować czy dane OSM są wykorzystywane:

```bash
# Przykładowe zapytanie dla Krakowa
curl "http://localhost:4000/v1/search?text=Restauracja+Grodzka+1+Kraków"
```

W wynikach sprawdź pole `parent.locality` - powinno być "Kraków" zamiast dzielnicy.

## Przywrócenie oficjalnej wersji

Jeśli chcesz wrócić do oficjalnej wersji Pelias:

1. Edytuj `docker-compose.yml`:
```yaml
image: pelias/openstreetmap:master
```

2. Pull i restart:
```bash
pelias compose pull openstreetmap
pelias import osm
```

## Troubleshooting

### Problem: Stare dane nadal w Elasticsearch

**Rozwiązanie:** Usuń index i reimportuj:
```bash
pelias elastic drop
pelias elastic create
pelias import all
```

### Problem: Brak logów o OSM admin

**Rozwiązanie:** Sprawdź czy używasz custom image:
```bash
docker inspect pelias_openstreetmap | grep Image
```

### Problem: Dane nadal z WOF

**Rozwiązanie:** Sprawdź czy OSM ma tagi addr:city:
- Nie wszystkie rekordy OSM mają te tagi
- WOF jest używany jako fallback
- To jest poprawne zachowanie

## Kontakt

W razie problemów sprawdź główny README: `BUILD_AND_RELEASE.md`

