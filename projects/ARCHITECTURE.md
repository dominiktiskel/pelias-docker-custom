# 🏗️ Architektura Dual Instance

## 📊 Ogólny Schemat

```
┌─────────────────────────────────────────────────────────────┐
│                         Host Machine                         │
│                                                              │
│  ┌────────────────────────┐  ┌────────────────────────┐    │
│  │   Poland Instance      │  │   UK Instance          │    │
│  │   (Network: pelias_poland)│  (Network: pelias_uk)   │    │
│  │                        │  │                        │    │
│  │  Ports: 4xxx, 9200    │  │  Ports: 5xxx, 9201    │    │
│  │  Prefix: poland_      │  │  Prefix: uk_          │    │
│  └────────────────────────┘  └────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 🇵🇱 Poland Instance Detail

```
External Access                Docker Network: pelias_poland
───────────────               ─────────────────────────────

:4000 ──────────┐             ┌─────────────────────┐
                └─────────────┤  poland_api         │
                              │  (pelias/api)       │
                              └──┬────┬────┬────┬───┘
                                 │    │    │    │
                ┌────────────────┴────┴────┴────┴────────────┐
                │                                             │
        ┌───────▼──────┐  ┌────────▼─────┐  ┌──────▼───────┐
        │ poland_      │  │  poland_     │  │  poland_     │
        │ libpostal    │  │  placeholder │  │  pip         │
        │ :4400        │  │  :4100       │  │  :4200       │
        └──────────────┘  └──────────────┘  └──────────────┘

:9200 ──────────┐             ┌─────────────────────┐
                └─────────────┤ poland_             │
                              │ elasticsearch       │
                              │ Cluster: pelias-    │
                              │   poland            │
                              └──┬───────────────┬──┘
                                 │               │
                    ┌────────────▼──┐   ┌───────▼──────────┐
                    │  poland_      │   │  poland_         │
                    │  openstreetmap│   │  whosonfirst     │
                    │  (tiskel:v1.2)│   │                  │
                    └───────────────┘   └──────────────────┘
```

## 🇬🇧 UK Instance Detail

```
External Access                Docker Network: pelias_uk
───────────────               ─────────────────────────

:5000 ──────────┐             ┌─────────────────────┐
                └─────────────┤  uk_api             │
                              │  (pelias/api)       │
                              └──┬────┬────┬────┬───┘
                                 │    │    │    │
                ┌────────────────┴────┴────┴────┴────────────┐
                │                                             │
        ┌───────▼──────┐  ┌────────▼─────┐  ┌──────▼───────┐
        │ uk_          │  │  uk_         │  │  uk_         │
        │ libpostal    │  │  placeholder │  │  pip         │
        │ :5400→4400   │  │  :5100→4100  │  │  :5200→4200  │
        └──────────────┘  └──────────────┘  └──────────────┘

:9201 ──────────┐             ┌─────────────────────┐
                └─────────────┤ uk_                 │
                              │ elasticsearch       │
                              │ Cluster: pelias-uk  │
                              └──┬───────────────┬──┘
                                 │               │
                    ┌────────────▼──┐   ┌───────▼──────────┐
                    │  uk_          │   │  uk_             │
                    │  openstreetmap│   │  whosonfirst     │
                    │  (tiskel:v1.2)│   │                  │
                    └───────────────┘   └──────────────────┘
```

## 🔌 Port Mapping

### Poland (Host → Container)

| Service | Host Port | Container Port | Access |
|---------|-----------|----------------|--------|
| API | 4000 | 4000 | Public (0.0.0.0) |
| Libpostal | 4400 | 4400 | Local (127.0.0.1) |
| Placeholder | 4100 | 4100 | Local (127.0.0.1) |
| PIP | 4200 | 4200 | Local (127.0.0.1) |
| Interpolation | 4300 | 4300 | Local (127.0.0.1) |
| Elasticsearch | 9200 | 9200 | Local (127.0.0.1) |
| Elasticsearch | 9300 | 9300 | Local (127.0.0.1) |

### UK (Host → Container)

| Service | Host Port | Container Port | Access |
|---------|-----------|----------------|--------|
| API | **5000** | 4000 | Public (0.0.0.0) |
| Libpostal | **5400** | 4400 | Local (127.0.0.1) |
| Placeholder | **5100** | 4100 | Local (127.0.0.1) |
| PIP | **5200** | 4200 | Local (127.0.0.1) |
| Interpolation | **5300** | 4300 | Local (127.0.0.1) |
| Elasticsearch | **9201** | 9200 | Local (127.0.0.1) |
| Elasticsearch | **9301** | 9300 | Local (127.0.0.1) |

**Klucz**: Pogrubione = zmienione z domyślnych

## 🌐 Network Isolation

```
┌──────────────────────────────────────────────────────┐
│                   Docker Host                        │
│                                                      │
│  ┌─────────────────────┐  ┌──────────────────────┐  │
│  │ Network:            │  │ Network:             │  │
│  │ pelias_poland       │  │ pelias_uk            │  │
│  │                     │  │                      │  │
│  │  poland_api         │  │  uk_api              │  │
│  │  poland_elasticsearch│  │  uk_elasticsearch    │  │
│  │  poland_libpostal   │  │  uk_libpostal        │  │
│  │  poland_pip         │  │  uk_pip              │  │
│  │  poland_placeholder │  │  uk_placeholder      │  │
│  │  poland_interpolation│ │  uk_interpolation    │  │
│  │  poland_openstreetmap│ │  uk_openstreetmap    │  │
│  │  poland_whosonfirst │  │  uk_whosonfirst      │  │
│  │  poland_openaddresses│ │  uk_openaddresses    │  │
│  │  poland_polylines   │  │  uk_polylines        │  │
│  │  poland_csv_importer│  │  uk_csv_importer     │  │
│  │  poland_transit     │  │                      │  │
│  └─────────────────────┘  └──────────────────────┘  │
│           ▲                        ▲                 │
│           │                        │                 │
│           └────────────┬───────────┘                 │
│                        │                             │
└────────────────────────┼─────────────────────────────┘
                         │
                         ▼
                   Port Bindings
                  (4xxx, 5xxx, 9200-9201)
```

## 📦 Data Volumes

```
Host Filesystem                 Container Mount
───────────────                 ───────────────

Poland:
  $DATA_DIR/
  ├── elasticsearch/     →     /usr/share/elasticsearch/data
  ├── openstreetmap/     →     /data/openstreetmap
  ├── whosonfirst/       →     /data/whosonfirst
  ├── openaddresses/     →     /data/openaddresses
  ├── polylines/         →     /data/polylines
  └── geonames/          →     /data/geonames

UK:
  $DATA_DIR/
  ├── elasticsearch/     →     /usr/share/elasticsearch/data
  ├── openstreetmap/     →     /data/openstreetmap
  ├── whosonfirst/       →     /data/whosonfirst
  ├── openaddresses/     →     /data/openaddresses
  ├── polylines/         →     /data/polylines
  └── geonames/          →     /data/geonames
```

**⚠️ WAŻNE**: Każdy projekt musi mieć **osobny** `DATA_DIR`!

## 🔄 Data Flow

### Import Pipeline

```
1. Download
   ─────────
   OSM PBF File → poland_openstreetmap:/data/openstreetmap/
   WOF Data     → poland_whosonfirst:/data/whosonfirst/
   
2. Processing
   ──────────
   poland_openstreetmap:
     - Read PBF
     - Extract features
     - OSM Admin Priority (NEW!)
     - WOF Admin Lookup (fallback)
   
3. Indexing
   ─────────
   Features → poland_elasticsearch:9200/pelias
   
4. Serving
   ────────
   User → poland_api:4000 → poland_elasticsearch:9200
```

### Search Request Flow

```
Client Request
     │
     ▼
localhost:4000 (Poland) or :5000 (UK)
     │
     ▼
poland_api / uk_api
     │
     ├──→ poland_libpostal / uk_libpostal (parse)
     │
     ├──→ poland_elasticsearch / uk_elasticsearch (search)
     │
     ├──→ poland_pip / uk_pip (point-in-polygon)
     │
     └──→ poland_placeholder / uk_placeholder (admin lookup)
     │
     ▼
JSON Response
```

## 🔐 Security Considerations

### Port Exposure

- **Public (0.0.0.0)**:
  - `4000` (Poland API)
  - `5000` (UK API)
  
- **Localhost Only (127.0.0.1)**:
  - All other services (Elasticsearch, Libpostal, etc.)

### Network Isolation

- Poland containers **cannot** communicate with UK containers
- Each project is completely isolated
- Shared services (if needed) must use host networking

## 💾 Resource Requirements

### Per Instance

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 8GB | 16GB |
| CPU | 2 cores | 4 cores |
| Disk | 50GB | 100GB |
| Network | 100Mbps | 1Gbps |

### Both Instances Combined

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 16GB | **32GB** |
| CPU | 4 cores | **8 cores** |
| Disk | 100GB | **200GB** |
| Network | 100Mbps | 1Gbps |

## 🎯 Best Practices

1. **Separate Data Directories**: Zawsze używaj różnych `DATA_DIR`
2. **Monitoring**: Monitoruj użycie RAM i CPU
3. **Backups**: Regularnie backupuj katalogi Elasticsearch
4. **Updates**: Aktualizuj oba projekty równolegle
5. **Testing**: Testuj każdy projekt osobno przed równoległym uruchomieniem

## 🔧 Maintenance

### Backup

```bash
# Poland
tar -czf poland-es-backup.tar.gz $DATA_DIR/elasticsearch/

# UK
tar -czf uk-es-backup.tar.gz $DATA_DIR/elasticsearch/
```

### Updates

```bash
# Pull latest images
cd docker/projects/poland && docker-compose pull
cd docker/projects/united-kingdom && docker-compose pull

# Restart
./manage-dual.sh restart all
```

### Cleanup

```bash
# Remove old data
docker system prune -a --volumes

# Remove specific project
cd docker/projects/poland && docker-compose down -v
```

---

**Last Updated**: 2025-12-19  
**Architecture Version**: 1.0  
**Custom OSM Image**: `tiskel/openstreetmap:v1.2`

