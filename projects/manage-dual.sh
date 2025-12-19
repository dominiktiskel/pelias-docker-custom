#!/bin/bash

# Kolorowe outputy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania nagłówków
header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Funkcja do wyświetlania statusu
status() {
    echo -e "${GREEN}✓${NC} $1"
}

# Funkcja do wyświetlania błędów
error() {
    echo -e "${RED}✗${NC} $1"
}

# Funkcja do wyświetlania ostrzeżeń
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Sprawdź parametry
if [ $# -eq 0 ]; then
    echo "Użycie: $0 [command] [project]"
    echo ""
    echo "Commands:"
    echo "  status      - Pokaż status kontenerów"
    echo "  start       - Uruchom projekt"
    echo "  stop        - Zatrzymaj projekt"
    echo "  restart     - Zrestartuj projekt"
    echo "  logs        - Pokaż logi"
    echo "  test        - Testuj API"
    echo "  stats       - Statystyki Elasticsearch"
    echo ""
    echo "Projects:"
    echo "  poland      - Poland instance (ports 4xxx, 9200)"
    echo "  uk          - United Kingdom instance (ports 5xxx, 9201)"
    echo "  all         - Both instances"
    echo ""
    echo "Przykłady:"
    echo "  $0 status all"
    echo "  $0 start poland"
    echo "  $0 logs uk"
    echo "  $0 test all"
    exit 1
fi

COMMAND=$1
PROJECT=$2

# Funkcja do sprawdzania statusu
check_status() {
    local project=$1
    local prefix=""
    
    if [ "$project" == "poland" ]; then
        prefix="poland_"
    elif [ "$project" == "uk" ]; then
        prefix="uk_"
    fi
    
    header "Status: $project"
    docker ps --filter "name=${prefix}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Funkcja do uruchamiania projektu
start_project() {
    local project=$1
    header "Starting: $project"
    cd "$project" || exit 1
    docker-compose up -d
    status "Project $project started"
    cd ..
}

# Funkcja do zatrzymywania projektu
stop_project() {
    local project=$1
    header "Stopping: $project"
    cd "$project" || exit 1
    docker-compose down
    status "Project $project stopped"
    cd ..
}

# Funkcja do restartowania projektu
restart_project() {
    stop_project "$1"
    sleep 2
    start_project "$1"
}

# Funkcja do wyświetlania logów
show_logs() {
    local project=$1
    header "Logs: $project"
    cd "$project" || exit 1
    docker-compose logs --tail=50 -f api
    cd ..
}

# Funkcja do testowania API
test_api() {
    local project=$1
    local port=""
    local query=""
    
    if [ "$project" == "poland" ]; then
        port="4000"
        query="Warszawa"
    elif [ "$project" == "uk" ]; then
        port="5000"
        query="London"
    fi
    
    header "Testing API: $project (port $port)"
    
    echo -e "${YELLOW}Search test:${NC}"
    curl -s "http://localhost:$port/v1/search?text=$query" | jq '.features[0].properties | {name, country, region, locality}' 2>/dev/null || echo "API not responding or jq not installed"
    
    echo ""
    echo -e "${YELLOW}Health check:${NC}"
    curl -s "http://localhost:$port" 2>/dev/null && status "API is responding" || error "API not responding"
}

# Funkcja do wyświetlania statystyk ES
show_stats() {
    local project=$1
    local port=""
    
    if [ "$project" == "poland" ]; then
        port="9200"
    elif [ "$project" == "uk" ]; then
        port="9201"
    fi
    
    header "Elasticsearch Stats: $project (port $port)"
    curl -s "http://localhost:$port/_cat/indices?v" 2>/dev/null || error "Elasticsearch not responding"
}

# Główna logika
case $COMMAND in
    status)
        if [ "$PROJECT" == "all" ]; then
            check_status "poland"
            echo ""
            check_status "uk"
        else
            check_status "$PROJECT"
        fi
        ;;
    
    start)
        if [ "$PROJECT" == "all" ]; then
            start_project "poland"
            start_project "united-kingdom"
        elif [ "$PROJECT" == "poland" ]; then
            start_project "poland"
        elif [ "$PROJECT" == "uk" ]; then
            start_project "united-kingdom"
        fi
        ;;
    
    stop)
        if [ "$PROJECT" == "all" ]; then
            stop_project "poland"
            stop_project "united-kingdom"
        elif [ "$PROJECT" == "poland" ]; then
            stop_project "poland"
        elif [ "$PROJECT" == "uk" ]; then
            stop_project "united-kingdom"
        fi
        ;;
    
    restart)
        if [ "$PROJECT" == "all" ]; then
            restart_project "poland"
            restart_project "united-kingdom"
        elif [ "$PROJECT" == "poland" ]; then
            restart_project "poland"
        elif [ "$PROJECT" == "uk" ]; then
            restart_project "united-kingdom"
        fi
        ;;
    
    logs)
        if [ "$PROJECT" == "poland" ]; then
            show_logs "poland"
        elif [ "$PROJECT" == "uk" ]; then
            show_logs "united-kingdom"
        else
            error "Cannot show logs for 'all'. Choose 'poland' or 'uk'"
        fi
        ;;
    
    test)
        if [ "$PROJECT" == "all" ]; then
            test_api "poland"
            echo ""
            test_api "uk"
        else
            test_api "$PROJECT"
        fi
        ;;
    
    stats)
        if [ "$PROJECT" == "all" ]; then
            show_stats "poland"
            echo ""
            show_stats "uk"
        else
            show_stats "$PROJECT"
        fi
        ;;
    
    *)
        error "Unknown command: $COMMAND"
        exit 1
        ;;
esac

