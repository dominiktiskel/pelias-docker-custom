# Custom Pelias Docker Configurations

> **Custom Docker configurations for Pelias with dual-instance support and OSM admin priority**

This repository contains custom Docker Compose configurations for running Pelias geocoder with enhanced features and multi-instance support.

## Features

- ✨ **Dual Instance Support**: Run multiple Pelias instances (e.g., Poland + UK) on the same machine
- ✨ **OSM Admin Priority**: Use OpenStreetMap administrative data as primary source with WOF fallback
- ✨ **Pre-configured Projects**: Ready-to-use configurations for Poland, UK, and Portland Metro
- ✨ **Comprehensive Documentation**: Complete guides in Polish and English
- ✨ **Isolated Networks**: Each instance runs in its own Docker network with unique ports
- ✨ **Custom Docker Images**: Uses `tiskel/openstreetmap:v1.2` with OSM admin enhancements

## Repository Structure

```
pelias-docker-custom/
├── projects/
│   ├── poland/              # Poland configuration (ports 4000+)
│   ├── united-kingdom/      # UK configuration (ports 5000+)
│   ├── portland-metro/      # Test environment
│   ├── DUAL_INSTANCE_SETUP.md     # Detailed dual setup guide
│   ├── DUAL_SETUP_SUMMARY.md      # Quick reference
│   └── README_DUAL.md             # Overview
├── cmd/                     # Pelias command scripts
├── images/                  # Custom Docker images
└── common/                  # Shared resources
```

## Quick Start

### Single Instance (Portland Metro - for testing)

```bash
cd projects/portland-metro
export DATA_DIR=./data

# Start Elasticsearch
pelias elastic start
pelias elastic wait
pelias elastic create

# Download and import data
pelias download all
pelias prepare all
pelias import all

# Start API
pelias compose up
```

Test: `curl "http://localhost:4000/v1/search?text=Portland"`

### Dual Instance Setup

See [projects/DUAL_INSTANCE_SETUP.md](projects/DUAL_INSTANCE_SETUP.md) for detailed instructions.

## Projects

### 1. Portland Metro

**Purpose**: Quick testing environment (~5-10 min import)

- **Dataset**: Portland, Oregon metropolitan area
- **Size**: ~100MB
- **Use case**: Testing custom features before large imports
- **Documentation**: [README_CUSTOM.md](projects/portland-metro/README_CUSTOM.md)

### 2. Poland

**Purpose**: Production deployment for Poland

- **Dataset**: Full Poland OSM + OpenAddresses
- **Ports**: 4000 (API), 9200 (ES)
- **Features**: OSM admin priority, custom blacklists, dual-ready
- **Documentation**: [README_CUSTOM.md](projects/poland/README_CUSTOM.md)

### 3. United Kingdom

**Purpose**: Production deployment for UK (dual-instance compatible)

- **Dataset**: Full UK OSM + OpenAddresses  
- **Ports**: 5000 (API), 9201 (ES)
- **Features**: Port-shifted for dual deployment
- **Documentation**: [QUICK_START_DUAL.md](projects/united-kingdom/QUICK_START_DUAL.md)

## Custom Docker Images

This repository uses custom-built Docker images with OSM admin priority feature:

- **`tiskel/openstreetmap:v1.2`**: Enhanced OSM importer with `preferOsmAdmin` support

### Related Repositories

- [dominiktiskel/openstreetmap](https://github.com/dominiktiskel/openstreetmap) - Custom OSM importer source
- [dominiktiskel/model](https://github.com/dominiktiskel/model) - Pelias data model fork
- [dominiktiskel/wof-admin-lookup](https://github.com/dominiktiskel/wof-admin-lookup) - WOF lookup fork

## Configuration

### OSM Admin Priority

In `pelias.json`:

```json
{
  "imports": {
    "openstreetmap": {
      "preferOsmAdmin": true,
      "download": [...],
      "import": [...]
    }
  }
}
```

This enables prioritization of OSM `addr:*` tags over Who's on First data.

### Docker Compose

Each project uses `tiskel/openstreetmap:v1.2`:

```yaml
services:
  openstreetmap:
    image: tiskel/openstreetmap:v1.2
    container_name: pelias_openstreetmap
    ...
```

## Documentation

- **[DUAL_INSTANCE_SETUP.md](projects/DUAL_INSTANCE_SETUP.md)** - Complete guide for running multiple Pelias instances
- **[DUAL_SETUP_SUMMARY.md](projects/DUAL_SETUP_SUMMARY.md)** - Quick reference summary
- **[README_DUAL.md](projects/README_DUAL.md)** - Overview and architecture
- **[ARCHITECTURE.md](projects/ARCHITECTURE.md)** - System architecture details

## Requirements

- Docker & Docker Compose
- Minimum 16GB RAM (32GB recommended for dual instances)
- ~100GB free disk space per instance
- Linux: `vm.max_map_count=262144` for Elasticsearch

## System Resources

| Component | RAM | Disk | Notes |
|-----------|-----|------|-------|
| Elasticsearch | 4-6GB | 30-50GB | Per instance |
| OpenStreetMap Import | 2-4GB | - | During import only |
| API Services | 1-2GB | - | Combined |
| **Total per instance** | **8-12GB** | **50-100GB** | Approximate |

## Ports

### Poland Instance (Default)

- 4000: API
- 4100: Placeholder
- 4200: PIP
- 4300: Interpolation
- 4400: Libpostal
- 9200, 9300: Elasticsearch

### UK Instance (Dual)

- 5000: API
- 5100: Placeholder
- 5200: PIP
- 5300: Interpolation
- 5400: Libpostal
- 9201, 9301: Elasticsearch

## Management Scripts

### manage-dual.sh (Linux/Mac)

```bash
cd projects

# Start both instances
./manage-dual.sh start all

# Check status
./manage-dual.sh status all

# Test APIs
./manage-dual.sh test all

# Stop both
./manage-dual.sh stop all
```

## Troubleshooting

### Elasticsearch OOM

Increase heap size in `docker-compose.yml`:

```yaml
environment:
  - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
```

### Port Conflicts

Check what's using a port:

```bash
# Linux/Mac
lsof -i :4000

# Windows
netstat -ano | findstr :4000
```

### Containers Not Communicating

Verify they're in the same network:

```bash
docker network inspect pelias_poland
docker network inspect pelias_uk
```

## Version History

- **v1.0.0** (2025-12-19)
  - Initial release
  - Dual instance support
  - OSM admin priority integration
  - Poland, UK, Portland Metro configurations
  - Comprehensive documentation

## Support

- **Issues**: [GitHub Issues](https://github.com/dominiktiskel/pelias-docker-custom/issues)
- **Upstream**: [pelias/docker](https://github.com/pelias/docker)

## License

MIT License (same as upstream Pelias)

## Acknowledgments

Built on top of [Pelias](https://github.com/pelias/pelias) - open source geocoding by Mapzen/Geocode Earth.

Special thanks to the Pelias community for the excellent foundation.
