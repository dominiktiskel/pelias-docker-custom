# 🌍 Pelias Dual Instance Projects

Katalog zawiera skonfigurowane projekty Pelias do równoległego działania na jednej maszynie.

## 📁 Projekty

### 🇵🇱 [Poland](./poland/)
- **Porty**: 4000 (API), 9200 (ES)
- **Prefixy**: `poland_*`
- **Sieć**: `pelias_poland`
- **Custom**: `tiskel/openstreetmap:v1.2` z OSM Admin Priority

### 🇬🇧 [United Kingdom](./united-kingdom/)
- **Porty**: 5000 (API), 9201 (ES)
- **Prefixy**: `uk_*`
- **Sieć**: `pelias_uk`
- **Custom**: `tiskel/openstreetmap:v1.2` z OSM Admin Priority

### 🇺🇸 [Portland Metro](./portland-metro/) (Produkcja)
- **Status**: Działający, używany do testów
- **Nie konfigurowany** do dual instance (osobna maszyna VPS)

## 📚 Dokumentacja

| Dokument | Opis |
|----------|------|
| **[DUAL_INSTANCE_SETUP.md](./DUAL_INSTANCE_SETUP.md)** | 📖 Główna dokumentacja - START TUTAJ |
| [DUAL_SETUP_SUMMARY.md](./DUAL_SETUP_SUMMARY.md) | ✅ Podsumowanie zmian i checklist |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 🏗️ Diagramy i architektura |
| [manage-dual.sh](./manage-dual.sh) | 🔧 Skrypt zarządzania (Linux) |
| [poland/QUICK_START_DUAL.md](./poland/QUICK_START_DUAL.md) | 🚀 Quick start - Poland |
| [united-kingdom/QUICK_START_DUAL.md](./united-kingdom/QUICK_START_DUAL.md) | 🚀 Quick start - UK |

## 🚀 Quick Start

### 1. Przeczytaj Dokumentację

```bash
# Zacznij tutaj!
cat DUAL_INSTANCE_SETUP.md
```

### 2. Uruchom Poland

```bash
cd poland
export DATA_DIR=/data/pelias-poland
docker-compose up -d
```

### 3. Uruchom UK

```bash
cd united-kingdom
export DATA_DIR=/data/pelias-uk
docker-compose up -d
```

### 4. Testuj

```bash
# Poland
curl "http://localhost:4000/v1/search?text=Warszawa"

# UK
curl "http://localhost:5000/v1/search?text=London"
```

## 🔧 Zarządzanie (Linux)

```bash
# Status obu projektów
./manage-dual.sh status all

# Uruchom oba
./manage-dual.sh start all

# Zatrzymaj oba
./manage-dual.sh stop all

# Testuj API
./manage-dual.sh test all
```

## 📊 Kluczowe Różnice vs Standardowy Setup

| Aspekt | Standardowy | Dual Instance |
|--------|-------------|---------------|
| **Porty** | 4000, 9200 | 4000/5000, 9200/9201 |
| **Kontenery** | `pelias_*` | `poland_*` / `uk_*` |
| **Sieci** | `default` | `pelias_poland` / `pelias_uk` |
| **ES Cluster** | `pelias` | `pelias-poland` / `pelias-uk` |
| **DATA_DIR** | Jedna ścieżka | Dwie osobne ścieżki |

## ⚙️ Konfiguracja

### Porty API

- **Poland**: http://localhost:4000
- **UK**: http://localhost:5000

### Elasticsearch

- **Poland**: http://localhost:9200
- **UK**: http://localhost:9201

### Wszystkie Porty

| Serwis | Poland | UK |
|--------|--------|-----|
| API | 4000 | **5000** |
| Libpostal | 4400 | **5400** |
| Placeholder | 4100 | **5100** |
| PIP | 4200 | **5200** |
| Interpolation | 4300 | **5300** |
| Elasticsearch | 9200, 9300 | **9201, 9301** |

## 💡 Kiedy Używać Dual Instance?

### ✅ Dobre przypadki użycia:

- **Development/Testing**: Testowanie różnych konfiguracji
- **Multi-Region**: Różne dane geograficzne (Poland + UK)
- **Comparison**: Porównanie wyników między regionami
- **Demo**: Pokazanie działania dla różnych krajów
- **Resource Optimization**: Lepsze wykorzystanie jednej dużej maszyny niż dwie małe

### ❌ Kiedy NIE używać:

- **Production High-Load**: Lepiej osobne maszyny
- **Limited Resources**: < 16GB RAM
- **Simple Setup**: Jeden kraj = jedna instancja
- **High Availability**: Lepiej rozproszone instancje

## ⚠️ Wymagania

### Minimalne
- **RAM**: 16GB
- **CPU**: 4 rdzenie
- **Disk**: 100GB
- **Docker**: 20.10+
- **Docker Compose**: 1.29+

### Zalecane
- **RAM**: 32GB
- **CPU**: 8 rdzeni
- **Disk**: 200GB SSD
- **Network**: 1Gbps

## 🐛 Troubleshooting

### Problem: Port już używany

```bash
# Sprawdź co używa portu
lsof -i :5000
# Lub zmień port w docker-compose.yml
```

### Problem: Brak pamięci

```bash
# Uruchom tylko jeden projekt
cd poland && docker-compose down
cd united-kingdom && docker-compose up -d
```

### Problem: Elasticsearch nie startuje

```bash
# Zwiększ limity (Linux)
sudo sysctl -w vm.max_map_count=262144
```

## 📈 Monitoring

```bash
# Zasoby kontenerów
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Logi
docker-compose logs -f api

# Elasticsearch stats
curl "http://localhost:9200/_cat/indices?v"  # Poland
curl "http://localhost:9201/_cat/indices?v"  # UK
```

## 🔄 Aktualizacje

### Custom OSM Image

Oba projekty używają `tiskel/openstreetmap:v1.2`:

```bash
# Pull nowej wersji
docker pull tiskel/openstreetmap:v1.2

# Restart projektów
cd poland && docker-compose up -d openstreetmap
cd united-kingdom && docker-compose up -d openstreetmap
```

## 📞 Wsparcie

- **Dokumentacja**: [`DUAL_INSTANCE_SETUP.md`](./DUAL_INSTANCE_SETUP.md)
- **Custom OSM**: [`poland/README_CUSTOM.md`](./poland/README_CUSTOM.md)
- **Architecture**: [`ARCHITECTURE.md`](./ARCHITECTURE.md)

## 📝 Changelog

### 2025-12-19 - Initial Dual Instance Setup

- ✅ Skonfigurowano Poland (porty 4xxx, 9200)
- ✅ Skonfigurowano UK (porty 5xxx, 9201)
- ✅ Dodano własne sieci Docker
- ✅ Zaktualizowano UK do `tiskel/openstreetmap:v1.2`
- ✅ Dodano `preferOsmAdmin: true` dla UK
- ✅ Unikalne nazwy kontenerów (`poland_*`, `uk_*`)
- ✅ Unikalne nazwy klastrów ES
- ✅ Pełna dokumentacja

---

**Status**: ✅ Gotowe do użycia  
**Wersja**: 1.0  
**Data**: 2025-12-19  
**Custom OSM**: `tiskel/openstreetmap:v1.2`

