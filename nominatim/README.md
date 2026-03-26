# Nominatim – Polska, Wielka Brytania, Niemcy, Hiszpania

## Wymagania serwera

| Parametr | Wartość |
|----------|---------|
| RAM | 64 GB (zalecane minimum dla 4 krajów) |
| CPU | 16 rdzeni |
| Dysk (PBF) | ~10 GB |
| Dysk (dane PostgreSQL) | ~120–200 GB |

---

## Pierwsze uruchomienie

### 1. Zainstaluj zależności

```bash
apt-get update && apt-get install -y osmium-tool wget
```

### 2. Pobierz i scal pliki PBF

```bash
chmod +x prepare-pbf.sh
bash prepare-pbf.sh
```

Skrypt pobiera pliki do katalogu `pbf/` i scala je w `pbf/merged.osm.pbf`.  
Czas: ~30–60 min (zależy od łącza i dysku).

### 3. Uruchom Nominatim

```bash
docker compose up -d
```

Import bazy danych trwa **6–12 godzin**. Postęp możesz śledzić:

```bash
docker logs -f nominatim-multi
```

### 4. Testowe zapytanie

```bash
curl "http://localhost:18080/search?q=Warsaw&format=json&limit=1"
curl "http://localhost:18080/search?q=Berlin&format=json&limit=1"
curl "http://localhost:18080/search?q=London&format=json&limit=1"
curl "http://localhost:18080/search?q=Madrid&format=json&limit=1"
```

---

## Ponowne uruchomienie (po restarcie serwera)

Dane są zapisane w `./data/`, więc import nie jest powtarzany:

```bash
docker compose up -d
```

---

## Struktura katalogu

```
nominatim/
├── prepare-pbf.sh       # skrypt pobierający i scalający PBF
├── docker-compose.yml   # konfiguracja kontenera
├── README.md
├── pbf/                 # tworzone przez prepare-pbf.sh
│   ├── poland-latest.osm.pbf
│   ├── great-britain-latest.osm.pbf
│   ├── germany-latest.osm.pbf
│   ├── spain-latest.osm.pbf
│   └── merged.osm.pbf   # plik wejściowy dla Nominatim
└── data/                # dane PostgreSQL (tworzone przez Docker)
```
