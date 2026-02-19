# Województwo Mazowieckie (Masovian Voivodeship)

This project is configured to download/prepare/build a complete Pelias installation for Mazowieckie (Masovian) Voivodeship in Poland, with the capital city of Warsaw (Warszawa).

## Geographic Coverage

- **Region**: Mazowieckie (Masovian Voivodeship), Poland
- **Capital**: Warszawa (Warsaw)
- **Coordinates**: 52.2297°N, 21.0122°E (Warsaw city center)
- **Data Source**: Geofabrik extract for Mazowieckie region

## Data Sources

This project uses the following data sources:

- **OpenStreetMap**: Regional extract from Geofabrik (`poland/mazowieckie-latest.osm.pbf`)
- **OpenAddresses**: Address data for Mazowieckie voivodeship
- **Geonames**: Polish administrative boundaries and place names
- **Who's on First**: Administrative hierarchies for Poland

## Setup

Please refer to the instructions at <https://github.com/pelias/docker> in order to install and configure your docker environment.

The minimum configuration required in order to run this project are:
- [Installing prerequisites](https://github.com/pelias/docker#prerequisites)
- [Install the pelias command](https://github.com/pelias/docker#installing-the-pelias-command)
- [Configure the environment](https://github.com/pelias/docker#configure-environment)

Please ensure that's all working fine before continuing.

## Run a Build

To run a complete build, execute the following commands:

```bash
pelias compose pull
pelias elastic start
pelias elastic wait
pelias elastic create
pelias download all
pelias prepare all
pelias import all
pelias compose up
pelias test run
```

## Make Example Queries

You can now make queries against your new Pelias build:

### Search for Warszawa (capital city)
<http://localhost:24000/v1/search?text=warszawa>

### Search for other major cities in the region
<http://localhost:24000/v1/search?text=radom>
<http://localhost:24000/v1/search?text=płock>
<http://localhost:24000/v1/search?text=siedlce>

### Reverse geocoding in Warsaw city center
<http://localhost:24000/v1/reverse?point.lat=52.2297&point.lon=21.0122>

## Resources

- Population: ~5.4 million (2021)
- Area: 35,558 km²
- Major cities: Warszawa, Radom, Płock, Siedlce, Ostrołęka, Pruszków, Legionowo, Piaseczno
