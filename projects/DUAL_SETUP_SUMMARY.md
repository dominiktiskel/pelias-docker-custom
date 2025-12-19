# ✅ Podsumowanie Konfiguracji Dual Instance

## 🎯 Co zostało zrobione

Skonfigurowałem **Poland** i **United Kingdom** Pelias do równoległego działania na jednej maszynie.

## 📊 Kluczowe Zmiany

### 1. **Rozdzielenie Portów**

| Serwis | Poland | UK | Zmiana |
|--------|--------|-----|--------|
| API | 4000 | **5000** | +1000 |
| Placeholder | 4100 | **5100** | +1000 |
| PIP | 4200 | **5200** | +1000 |
| Interpolation | 4300 | **5300** | +1000 |
| Libpostal | 4400 | **5400** | +1000 |
| Elasticsearch | 9200, 9300 | **9201, 9301** | +1 |

### 2. **Unikalne Nazwy Kontenerów**

- **Poland**: `poland_*` (np. `poland_api`, `poland_elasticsearch`)
- **UK**: `uk_*` (np. `uk_api`, `uk_elasticsearch`)

### 3. **Izolowane Sieci Docker**

- **Poland**: `pelias_poland`
- **UK**: `pelias_uk`

### 4. **Custom OSM Image dla UK**

- Zaktualizowano z `pelias/openstreetmap:master` na `tiskel/openstreetmap:v1.2`
- Dodano `preferOsmAdmin: true` w `pelias.json`

## 📁 Struktura Plików

```
docker/projects/
├── DUAL_INSTANCE_SETUP.md          # Główna dokumentacja
├── DUAL_SETUP_SUMMARY.md           # To podsumowanie
├── manage-dual.sh                  # Skrypt zarządzania (Linux)
│
├── poland/
│   ├── docker-compose.yml          # ✅ Zaktualizowany (network, nazwy, v1.2)
│   ├── pelias.json                 # ✅ Ma preferOsmAdmin: true
│   ├── QUICK_START_DUAL.md         # Instrukcja quick start
│   └── README_CUSTOM.md            # Dokumentacja custom features
│
└── united-kingdom/
    ├── docker-compose.yml          # ✅ Zaktualizowany (porty, network, nazwy, v1.2)
    ├── pelias.json                 # ✅ Dodano preferOsmAdmin: true
    ├── QUICK_START_DUAL.md         # Instrukcja quick start
    └── README.md                   # Oryginalna dokumentacja
```

## 🚀 Jak Uruchomić

### Opcja 1: Ręcznie

```bash
# Poland
cd docker/projects/poland
export DATA_DIR=/data/pelias-poland
docker-compose up -d

# UK
cd docker/projects/united-kingdom
export DATA_DIR=/data/pelias-uk
docker-compose up -d
```

### Opcja 2: Skrypt (Linux/Mac)

```bash
cd docker/projects

# Uruchom oba
./manage-dual.sh start all

# Status
./manage-dual.sh status all

# Test API
./manage-dual.sh test all
```

## 🧪 Weryfikacja

### Poland (port 4000)

```bash
curl "http://localhost:4000/v1/search?text=Warszawa"
curl "http://localhost:9200/_cat/indices?v"
docker ps --filter "name=poland_"
```

### UK (port 5000)

```bash
curl "http://localhost:5000/v1/search?text=London"
curl "http://localhost:9201/_cat/indices?v"
docker ps --filter "name=uk_"
```

## 📋 Checklist Przed Uruchomieniem

- [ ] Zainstalowany Docker & Docker Compose
- [ ] Minimum 16GB RAM (32GB zalecane)
- [ ] ~100GB wolnego miejsca na dysku
- [ ] Porty 4000, 5000, 9200-9201 są wolne
- [ ] `vm.max_map_count=262144` (Linux)
- [ ] Zmienne środowiskowe:
  - [ ] `DATA_DIR` ustawione dla Poland
  - [ ] `DATA_DIR` ustawione dla UK
  - [ ] `DOCKER_USER` (opcjonalnie)

## ⚙️ Zmienne Środowiskowe

### Poland

```bash
export DATA_DIR=/data/pelias-poland  # lub inna ścieżka
export DOCKER_USER=$(id -u):$(id -g)
```

### UK

```bash
export DATA_DIR=/data/pelias-uk      # lub inna ścieżka
export DOCKER_USER=$(id -u):$(id -g)
```

## 🔧 Konfiguracja Elasticsearch

### Poland

Plik: `docker/projects/poland/elasticsearch.yml`

```yaml
cluster.name: pelias-poland
node.name: pelias-poland-node
network.host: 0.0.0.0
```

### UK

Plik: `docker/projects/united-kingdom/elasticsearch.yml`

```yaml
cluster.name: pelias-uk
node.name: pelias-uk-node
network.host: 0.0.0.0
```

**⚠️ WAŻNE**: Każdy Elasticsearch musi mieć **unikalną nazwę klastra**!

## 📊 Monitorowanie Zasobów

```bash
# Użycie pamięci przez kontenery
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Miejsce na dysku
df -h $DATA_DIR

# Top procesów
docker top poland_elasticsearch
docker top uk_elasticsearch
```

## ⚠️ Znane Ograniczenia

1. **Pamięć**: Każda instancja Elasticsearch potrzebuje ~4-6GB RAM
2. **CPU**: Import OSM jest CPU-intensive
3. **Dysk I/O**: Równoległy import może być wolniejszy
4. **Network**: Kontenery w różnych sieciach nie mogą się komunikować

## 🐛 Troubleshooting

### Elasticsearch OOM (Out of Memory)

```bash
# Zwiększ heap size w docker-compose.yml
environment:
  - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
```

### Port Already in Use

```bash
# Sprawdź co używa portu
lsof -i :5000
# Zatrzymaj konfliktującą usługę lub zmień port w docker-compose.yml
```

### Kontenery się nie widzą

```bash
# Sprawdź sieć
docker network ls
docker network inspect pelias_poland
docker network inspect pelias_uk
```

## 📈 Rekomendacje Produkcyjne

1. **Używaj osobnych maszyn** dla każdego projektu (idealne rozwiązanie)
2. **Load Balancer** (nginx) przed API:
   ```nginx
   # Poland
   location /pl/ {
       proxy_pass http://localhost:4000/;
   }
   
   # UK
   location /uk/ {
       proxy_pass http://localhost:5000/;
   }
   ```
3. **Monitoring**: Prometheus + Grafana dla metryk
4. **Backup**: Regularne snapshoty Elasticsearch
5. **Logs**: Centralne logowanie (ELK stack)

## 🎓 Następne Kroki

1. **Przeczytaj**: [`DUAL_INSTANCE_SETUP.md`](DUAL_INSTANCE_SETUP.md)
2. **Uruchom**: Poland jako pierwszy projekt
3. **Zaimportuj**: Dane dla Poland
4. **Przetestuj**: API na porcie 4000
5. **Powtórz**: Dla UK (port 5000)
6. **Monitoruj**: Zasoby systemu

## 📞 Pomoc

Więcej informacji:
- [`poland/QUICK_START_DUAL.md`](poland/QUICK_START_DUAL.md)
- [`united-kingdom/QUICK_START_DUAL.md`](united-kingdom/QUICK_START_DUAL.md)
- [`poland/README_CUSTOM.md`](poland/README_CUSTOM.md)

---

**Wersja**: 1.0  
**Data**: 2025-12-19  
**Custom OSM Image**: `tiskel/openstreetmap:v1.2`  
**Status**: ✅ Gotowe do użycia

