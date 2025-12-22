# Województwo Dolnośląskie (Lower Silesian Voivodeship)

This project is configured to download/prepare/build a complete Pelias installation for Dolnośląskie (Lower Silesian) Voivodeship in Poland, with the capital city of Wrocław.

## Geographic Coverage

- **Region**: Dolnośląskie (Lower Silesian Voivodeship), Poland
- **Capital**: Wrocław
- **Coordinates**: 51.1079°N, 17.0385°E (Wrocław city center)
- **Data Source**: Geofabrik extract for Dolnośląskie region

## Data Sources

This project uses the following data sources:

- **OpenStreetMap**: Regional extract from Geofabrik (`poland/dolnoslaskie-latest.osm.pbf`)
- **OpenAddresses**: Address data for Dolnośląskie voivodeship
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

### Search for Wrocław (capital city)
<http://localhost:4000/v1/search?text=wrocław>

### Search for other major cities in the region
<http://localhost:4000/v1/search?text=wałbrzych>
<http://localhost:4000/v1/search?text=legnica>
<http://localhost:4000/v1/search?text=jelenia góra>

### Reverse geocoding in Wrocław city center
<http://localhost:4000/v1/reverse?point.lat=51.1079&point.lon=17.0385>

## Resources

- Population: ~2.9 million (2021)
- Area: 19,947 km²
- Major cities: Wrocław, Wałbrzych, Legnica, Jelenia Góra, Lubin, Głogów

