# Pelias usa-mini

Lokalny wycinek Midtown Manhattanu do sprawdzania skrzyżowań. Nie jest kopiowany na VPS.

API: `http://localhost:33000`. Elasticsearch: `33200`.

Dane: `/Users/dominik/data/pelias-usa-mini`. Import to `midtown.osm.pbf`, bbox `-73.98,40.75,-73.96,40.77`, wycięty z pliku Nowego Jorku. Obraz OSM to lokalny `tiskel/openstreetmap:v4.2.0`.

```bash
cd docker/projects/usa-mini
docker compose up -d elasticsearch
docker compose run --rm schema ./bin/create_index
docker compose run --rm --entrypoint node whosonfirst ./utils/download_sqlite_all.js --admin-only
docker compose run --rm openstreetmap ./bin/start
docker compose up -d libpostal api
```

Sprawdzenie: `http://localhost:33000/v1/search?text=Lex+and+53rd`
