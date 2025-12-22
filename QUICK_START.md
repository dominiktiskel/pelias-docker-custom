# 🚀 Szybki Start - Build i Deployment

## TL;DR - Najszybsza ścieżka

```powershell
# 1. Zbuduj i wypchnij obraz (z katalogu docker/)
.\build-custom-pelias.ps1 v1.6.1

# 2. Gotowe! docker-compose.yml już zaktualizowany
cd projects\poland

# 3. Uruchom import
pelias compose pull openstreetmap
pelias import osm
```

## Szczegółowe kroki

### Krok 1: Zbudowanie obrazu Docker

Użyj gotowego skryptu PowerShell:

```powershell
# Z konkretną wersją (zalecane)
.\build-custom-pelias.ps1 v1.6.1

# Lub z domyślną wersją
.\build-custom-pelias.ps1

# Tylko build, bez pushowania (do testów lokalnych)
.\build-custom-pelias.ps1 -NoPush

# Bez testów (szybsze)
.\build-custom-pelias.ps1 -NoTest
```

Skrypt automatycznie:
- ✓ Zbuduje obraz `tiskel/openstreetmap:v1.6.1`
- ✓ Uruchomi testy
- ✓ Wypchnie do Docker Hub
- ✓ Pokaże instrukcje dalszych kroków

### Krok 2: Weryfikacja

Sprawdź czy obraz jest na Docker Hub:

```powershell
docker pull tiskel/openstreetmap:custom-admin
```

### Krok 3: Import danych

```bash
cd projects\poland

# Ściągnij nowy obraz (jeśli jeszcze nie)
pelias compose pull openstreetmap

# Uruchom Elasticsearch
pelias elastic start
pelias elastic wait

# Stwórz index
pelias elastic create

# Pobierz dane
pelias download osm

# Importuj z nowym kodem
pelias import osm
```

### Krok 4: Testowanie

Po imporcie sprawdź czy działa:

```bash
# Przykładowy adres w Krakowie
curl "http://localhost:4000/v1/search?text=Grodzka+1+Kraków" | jq '.features[0].properties.locality'
```

Powinno zwrócić `"Kraków"` zamiast nazwy dzielnicy.

## Szybkie debugowanie

### Sprawdź wersję obrazu

```powershell
docker inspect pelias_openstreetmap | Select-String "Image"
```

Powinno pokazać: `tiskel/openstreetmap:custom-admin`

### Sprawdź logi podczas importu

```powershell
docker logs -f pelias_openstreetmap
```

Szukaj linii:
```
[osm_admin_extractor] OSM admin prioritization enabled
[osm_admin_extractor] Set parent.locality from OSM tag
```

### Test lokalny bez Docker Hub

Jeśli chcesz przetestować przed pushowaniem:

```powershell
# Build lokalnie
.\build-custom-pelias.ps1 -NoPush

# W docker-compose.yml użyj:
image: tiskel/openstreetmap:custom-admin

# Import działa z lokalnego image
pelias import osm
```

## Co jeśli coś pójdzie nie tak?

### Problem: Build fails

```powershell
# Wyczyść cache Docker
docker system prune -a

# Spróbuj ponownie
.\build-custom-pelias.ps1 v1.6.1
```

### Problem: Testy nie przechodzą

```powershell
# Uruchom testy lokalnie najpierw
cd ..\openstreetmap
npm test

# Jeśli przechodzą lokalnie, zignoruj błędy Docker:
cd ..\docker
.\build-custom-pelias.ps1 v1.6.1 -NoTest
```

### Problem: Push fails (błąd autoryzacji)

```powershell
# Zaloguj się ponownie
docker login

# Podaj username: tiskel
# Podaj hasło: [twoje hasło Docker Hub]

# Spróbuj ponownie
.\build-custom-pelias.ps1
```

### Problem: Import używa starych danych

```powershell
# Wymuś reimport
pelias elastic drop
pelias elastic create
pelias import osm
```

## Aktualizacja do nowej wersji

Gdy wprowadzisz więcej zmian:

```powershell
# Zbuduj z nowym numerem wersji
.\build-custom-pelias.ps1 v1.7.0

# Zaktualizuj docker-compose.yml
# image: tiskel/openstreetmap:v1.7.0

# Reimportuj
cd projects\poland
pelias compose pull openstreetmap
pelias import osm
```

## Konfiguracja opcjonalna

W `projects/poland/pelias.json` możesz dodać:

```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": true,
      "datapath": "/data/openstreetmap",
      "leveldbpath": "/tmp",
      "import": [
        {
          "filename": "poland-latest.osm.pbf"
        }
      ]
    }
  }
}
```

## Czas trwania

- **Build obrazu**: ~5-10 minut
- **Push do Docker Hub**: ~2-5 minut  
- **Import Polski**: ~30-60 minut (zależnie od CPU)

## Następne kroki

Po sukcesie możesz:
1. ✓ Użyć tego samego procesu dla innych krajów
2. ✓ Stworzyć więcej tagów (v1.0, v1.1, latest)
3. ✓ Automatyzować przez GitHub Actions
4. ✓ Udostępnić innym użytkownikom

## Przydatne komendy

```powershell
# Sprawdź rozmiar obrazu
docker images tiskel/openstreetmap

# Zobacz historię obrazu
docker history tiskel/openstreetmap:custom-admin

# Sprawdź wszystkie tagi
docker images tiskel/openstreetmap --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Usuń stare obrazy
docker rmi tiskel/openstreetmap:old-version
```

## Potrzebujesz pomocy?

Sprawdź:
- `BUILD_AND_RELEASE.md` - szczegółowy przewodnik
- `projects/poland/README_CUSTOM.md` - dokumentacja projektu
- GitHub Issues w repozytorium dominiktiskel/openstreetmap

