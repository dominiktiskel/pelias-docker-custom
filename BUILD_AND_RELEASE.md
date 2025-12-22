# Przewodnik budowania i publikacji zmodyfikowanego Pelias

## Przegląd zmian

Zmodyfikowane komponenty:
- **pelias/wof-admin-lookup** - biblioteka npm (używana przez openstreetmap)
- **pelias/openstreetmap** - importer OSM (wymaga nowego obrazu Docker)

## Krok 1: Przygotowanie wof-admin-lookup

Ponieważ wof-admin-lookup jest zależnością npm, musimy go najpierw przygotować:

### Opcja A: Użycie lokalnego linku (szybsze do testowania)

```bash
cd ../wof-admin-lookup
npm link
```

Następnie w openstreetmap:
```bash
cd ../openstreetmap
npm link pelias-wof-admin-lookup
```

### Opcja B: Opublikowanie do npm (zalecane dla produkcji)

**Uwaga:** To wymaga konta npm i uprawnień do publikacji pakietu z własnym scope.

Możesz utworzyć fork z własnym scope:
```bash
cd ../wof-admin-lookup

# Zmień nazwę pakietu w package.json na @tiskel/pelias-wof-admin-lookup
# Następnie:
npm publish --access public
```

Następnie w openstreetmap/package.json zmień:
```json
"pelias-wof-admin-lookup": "^7.17.0"
```
na:
```json
"@tiskel/pelias-wof-admin-lookup": "^7.17.0"
```

## Krok 2: Budowanie obrazu Docker dla OpenStreetMap

```bash
cd ../openstreetmap

# Zbuduj obraz z tagiem tiskel
docker build -t tiskel/openstreetmap:custom-admin .

# Opcjonalnie dodaj też tag z wersją
docker build -t tiskel/openstreetmap:custom-admin-v1.0 .
```

**Uwaga:** Jeśli używasz Opcji A (npm link), musisz zmodyfikować Dockerfile:

Dodaj przed `RUN npm install`:
```dockerfile
# Copy local wof-admin-lookup
COPY ../wof-admin-lookup /code/pelias/wof-admin-lookup
WORKDIR /code/pelias/wof-admin-lookup
RUN npm install && npm link

# Switch back to openstreetmap
WORKDIR ${WORKDIR}
```

## Krok 3: Testowanie obrazu lokalnie

```bash
# Uruchom kontener testowo
docker run -it --rm tiskel/openstreetmap:custom-admin npm test
```

## Krok 4: Publikacja na Docker Hub

```bash
# Zaloguj się do Docker Hub (już jesteś zalogowany)
docker login

# Wypchnij obraz
docker push tiskel/openstreetmap:custom-admin

# Opcjonalnie wypchnij wersjonowany tag
docker push tiskel/openstreetmap:custom-admin-v1.0
```

## Krok 5: Aktualizacja docker-compose.yml

Edytuj `projects/poland/docker-compose.yml`:

Zmień linię 45:
```yaml
# Przed:
image: pelias/openstreetmap:master

# Po:
image: tiskel/openstreetmap:custom-admin
```

## Krok 6: Przebudowanie importu

```bash
cd projects/poland

# Ściągnij nowy obraz
pelias compose pull openstreetmap

# Lub jeśli pelias command nie działa:
docker-compose pull openstreetmap

# Restart importu
pelias import osm
```

## Opcja prosta: Build i push w jednym kroku

Użyj gotowego skryptu PowerShell `build-custom-pelias.ps1`:

```powershell
# Z katalogu docker/
.\build-custom-pelias.ps1 v1.6.1

echo "Building Docker image: $IMAGE:$VERSION"
docker build -t $IMAGE:$VERSION .

echo "Testing image..."
docker run --rm $IMAGE:$VERSION npm test

echo "Pushing to Docker Hub..."
docker push $IMAGE:$VERSION

echo "✓ Done! Image published: $IMAGE:$VERSION"
echo ""
echo "Update your docker-compose.yml to use:"
echo "  image: $IMAGE:$VERSION"
```

Użycie:
```bash
./build-and-push.sh custom-admin-v1.0
```

## Opcja: Multi-platform build (opcjonalne, dla ARM + x86)

Jeśli chcesz wspierać różne architektury:

```bash
# Utwórz builder
docker buildx create --name pelias-builder --use

# Zbuduj i wypchnij dla wielu platform
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t tiskel/openstreetmap:custom-admin \
  --push \
  .
```

## Weryfikacja

Po zaktualizowaniu docker-compose.yml, sprawdź czy używa właściwego obrazu:

```bash
cd docker/projects/poland
docker-compose config | grep -A2 openstreetmap
```

Powinno pokazać:
```yaml
  openstreetmap:
    container_name: pelias_openstreetmap
    image: tiskel/openstreetmap:custom-admin
```

## Troubleshooting

### Problem: "npm ERR! 404 Not Found - GET https://registry.npmjs.org/pelias-wof-admin-lookup"

**Rozwiązanie:** Użyj Opcji A (npm link) lub upewnij się, że opublikowałeś pakiet.

### Problem: Dockerfile nie znajduje ../wof-admin-lookup

**Rozwiązanie:** Użyj docker build context:
```bash
cd w:\repos\pelias
docker build -f openstreetmap/Dockerfile -t tiskel/openstreetmap:custom-admin .
```

### Problem: Testy nie przechodzą

**Rozwiązanie:** Uruchom testy lokalnie najpierw:
```bash
cd openstreetmap
npm test
```

## Zalecana strategia

**Dla szybkiego testowania:**
1. Użyj npm link (Opcja A)
2. Zbuduj lokalnie bez pushowania
3. Testuj w docker-compose z local image

**Dla produkcji:**
1. Opcjonalnie opublikuj wof-admin-lookup jako @tiskel/pelias-wof-admin-lookup
2. Zbuduj openstreetmap z nową zależnością
3. Opublikuj jako tiskel/openstreetmap:v1.0
4. Użyj w docker-compose.yml

