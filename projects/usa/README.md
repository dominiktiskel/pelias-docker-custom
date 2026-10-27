# Pelias USA

Nowy Jork, Connecticut i New Jersey. OSM plus OpenAddresses (pliki statewide) plus oficjalny Who's on First. Lista numerów na ulicy jest w `addendum.osm.house_numbers` i łączy oba źródła. Importer OSM to `tiskel/openstreetmap:v4.1.0`.

API: port **32000**. Elasticsearch: **32200**.

Import OSM zapisuje też skrzyżowania nazwanych ulic (`layer: intersection`). Żeby pojawiły się na vps24, po wgraniu obrazu z tą funkcją trzeba powtórzyć `pelias import osm`.

Nie dodawaj plików miejskich ani hrabstw obok `statewide`. Te adresy już tam są. Nie uruchamiaj `pelias import wof` ani `pelias import all`. Baza Who's on First służy tylko do hierarchii przy imporcie i zostaje w `DATA_DIR/whosonfirst/sqlite/`.

## Przed startem

W `.env` jest `DATA_DIR=/data/pelias-usa`. Jeśli dysk na VPS jest gdzie indziej, zmień tę ścieżkę. Katalog musi istnieć, zanim odpalisz `pelias`.

```bash
cd docker/projects/usa
mkdir -p /data/pelias-usa
```

Import OSM bierze 16 GB sterty (`NODE_MAX_HEAP`). Nie uruchamiaj go równolegle z przebudową innego projektu.

## Import

Katalog z komendami to `docker/projects/usa`. Pliki OpenAddresses muszą być pobrane przed `pelias import osm`, bo importer OSM czyta je i dopisuje numery do ulic.

```bash
pelias compose pull
pelias elastic start
pelias elastic wait
pelias elastic create

pelias download wof
pelias download osm
pelias download oa

pelias import osm
pelias import oa

pelias compose up
```

## Po starcie

```bash
pelias compose ps
pelias elastic stats
```

Przykład: `http://localhost:32000/v1/search?text=165+Church+Street+New+Haven`

Ulica, z listą numerów: `http://localhost:32000/v1/search?text=Chapel+Street&layers=street&focus.point.lat=41.31&focus.point.lon=-72.93`
