#!/usr/bin/env bash
# =============================================================================
# Repositorio HGI — instalación desde cero
#
#   ./setup.sh local     -> entorno local con Caddy en https://localhost
#   ./setup.sh prod      -> servidor de producción (Apache delante, Caddy apagado)
#   ./setup.sh verify    -> comprueba que el entorno elegido esté sano
#
# Requisitos: Docker Engine + Docker Compose v2 y conexión a internet
# (la primera vez descarga la imagen de InvenioRDM y las dependencias).
#
# Variables opcionales:
#   ADMIN_EMAIL=...      correo del administrador inicial
#   ADMIN_PASSWORD=...   contraseña del administrador inicial
#   SEED_DEMO=1          además carga registros/comunidades de ejemplo
# =============================================================================
set -Eeuo pipefail

# SETUP_DEBUG=1 muestra cada comando ejecutado: sirve para ver exactamente
# dónde se queda trabado el script.
[ "${SETUP_DEBUG:-0}" = "1" ] && set -x

MODE="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; NC=$'\033[0m'
info()  { echo "${BOLD}==>${NC} $*"; }
ok()    { echo "${GREEN}  ✓${NC} $*"; }
warn()  { echo "${YELLOW}  !${NC} $*"; }
die()   { echo "${RED}  ✗${NC} $*" >&2; exit 1; }

# Pasos numerados: la instalación avanza por fases y cada una se anuncia antes
# de ejecutarse, para que nunca parezca que el script "se quedó ahí".
STEP=0
STEP_TOTAL=12
STEP_START=0

step() { # step "descripción de la fase"
  STEP=$((STEP + 1))
  STEP_START="$(date +%s 2>/dev/null || echo 0)"
  printf '\n%s==> [%d/%d]%s %s\n' "$BOLD" "$STEP" "$STEP_TOTAL" "$NC" "$*"
}

step_time() {
  local now secs
  now="$(date +%s 2>/dev/null || echo 0)"
  [ "${STEP_START:-0}" -gt 0 ] && [ "$now" -gt 0 ] || return 0
  secs=$((now - STEP_START))
  printf '      %s(esta fase tardó %ss)%s\n' "$DIM" "$secs" "$NC"
}

# Muestra el comando que se ejecuta dentro del contenedor, ocultando secretos.
show_cmd() {
  local args=("$@") out=() a mask_next=0
  for a in "${args[@]}"; do
    if [ "$mask_next" = 1 ]; then out+=("***"); mask_next=0; continue; fi
    case "$a" in
      --password|--secret|--token) out+=("$a"); mask_next=1 ;;
      *) out+=("$a") ;;
    esac
  done
  printf '      %s$ %s%s\n' "$DIM" "${out[*]}" "$NC"
}

show_plan() {
  printf '\n%sPlan de instalación (%s)%s\n' "$BOLD" "$MODE" "$NC"
  cat <<EOF
   1. Archivo de entorno ${ENV_FILE} (secretos, URL, base de datos)
   2. Ajustes del sistema: vm.max_map_count y swap
   3. Memoria de OpenSearch según la RAM del servidor
   4. Imagen de OpenSearch compatible con la CPU
   5. Contenedores: db, cache, search, web, worker
   6. PostgreSQL: esperar a que acepte conexiones
   7. OpenSearch: esperar a que publique el clúster
   8. Web: gunicorn escuchando en el puerto 5000
   9. InvenioRDM: tablas, roles, índices, campos personalizados
  10. Vocabularios obligatorios (communitytypes, licenses, languages…)
  11. Administrador inicial y sus permisos
  12. Verificación final (web, OpenSearch, contenedores)

No se borra nada: todos los pasos son idempotentes y se pueden repetir.
EOF
}

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

case "$MODE" in
  local|prod|verify) ;;
  -h|--help|help|"") usage ;;
  *) die "Modo desconocido: $MODE (usa: local | prod | verify)" ;;
esac

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
env_get() { # env_get CLAVE ARCHIVO
  local key="$1" file="$2"
  [ -f "$file" ] || return 0
  sed -n "s/^[[:space:]]*${key}=//p" "$file" | tail -1 \
    | sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/' \
    | tr -d '\r'
}

env_set() { # env_set CLAVE VALOR (usa $ENV_FILE)
  local key="$1" val="$2"
  if grep -qE "^[[:space:]]*${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i -E "s|^[[:space:]]*${key}=.*|${key}=${val}|" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$val" >> "$ENV_FILE"
  fi
}

rand_secret() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import secrets; print(secrets.token_urlsafe(48))"
  else
    head -c 48 /dev/urandom | base64 | tr -d '/+=\n'
  fi
}

check_docker() {
  command -v docker >/dev/null 2>&1 || die "Docker no está instalado."
  docker compose version >/dev/null 2>&1 || die "Falta Docker Compose v2 (docker compose)."
  docker info >/dev/null 2>&1 || die "El daemon de Docker no está corriendo o no tenés permisos."
  ok "Docker y Docker Compose disponibles"
}

# OpenSearch aborta si el kernel no permite mapear 262144 áreas de memoria.
# En Ubuntu el valor por defecto (65530) es demasiado bajo y el contenedor
# search se detiene, dejando el índice y los custom fields sin crear.
ensure_host_setup() {
  [ "$(uname -s)" = "Linux" ] || return 0
  command -v sysctl >/dev/null 2>&1 || return 0

  local want=262144 have
  have="$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)"
  if [ "${have:-0}" -ge "$want" ] 2>/dev/null; then
    ok "vm.max_map_count=$have (OpenSearch)"
    return 0
  fi

  info "Ajustando vm.max_map_count para OpenSearch (actual: ${have:-?}, mínimo: $want)…"
  if command -v sudo >/dev/null 2>&1 \
     && sudo sysctl -w vm.max_map_count="$want" >/dev/null 2>&1; then
    ok "vm.max_map_count=$want"
    printf 'vm.max_map_count=%s\n' "$want" \
      | sudo tee /etc/sysctl.d/99-opensearch.conf >/dev/null 2>&1 || true
  else
    die "OpenSearch necesita vm.max_map_count >= $want. Ejecutá:
      sudo sysctl -w vm.max_map_count=$want
      echo 'vm.max_map_count=$want' | sudo tee /etc/sysctl.d/99-opensearch.conf
    y volvé a ejecutar ./setup.sh $MODE"
  fi
}

# Servidores pequeños (4 GB o menos) no tienen margen para OpenSearch.
# Se crea un swapfile para evitar que el OOM killer lo termine.
ensure_swap() {
  [ "$(uname -s)" = "Linux" ] || return 0

  local ram_mb swap_mb free_mb
  ram_mb="$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  swap_mb="$(awk '/^SwapTotal:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  [ "${ram_mb:-0}" -ge 7000 ] && return 0
  [ "${swap_mb:-0}" -ge 2048 ] && return 0

  warn "RAM: ${ram_mb} MB, swap: ${swap_mb} MB. OpenSearch necesita margen."
  if ! command -v sudo >/dev/null 2>&1; then
    warn "No hay sudo: se continúa sin swap."
    return 0
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    warn "No hay sudo sin contraseña: se continúa sin swap."
    return 0
  fi

  free_mb="$(df -Pm / | awk 'NR==2{print $4}')"
  if [ "${free_mb:-0}" -lt 5120 ]; then
    warn "Espacio libre insuficiente para swap (${free_mb} MB). Se continúa sin swap."
    return 0
  fi

  info "Creando swapfile de 4 GB…"
  if [ ! -f /swapfile ]; then
    if ! sudo fallocate -l 4G /swapfile 2>/dev/null; then
      sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=none \
        || { warn "No se pudo crear /swapfile. Se continúa sin swap."; return 0; }
    fi
    sudo chmod 600 /swapfile || true
    if ! sudo mkswap /swapfile >/dev/null 2>&1; then
      warn "No se pudo formatear /swapfile. Se continúa sin swap."
      return 0
    fi
  fi
  sudo swapon /swapfile >/dev/null 2>&1 || true

  if swapon --show=NAME 2>/dev/null | grep -qx /swapfile; then
    ok "Swap activo (4 GB)"
    grep -qE '^/swapfile[[:space:]]' /etc/fstab 2>/dev/null \
      || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null || true
  else
    warn "No se pudo activar el swap. Se continúa sin swap."
  fi
}

# Con poca RAM se evita el memory lock (impide usar swap) y se desactiva
# el agente de performance-analyzer.
tune_low_memory() {
  [ "$(uname -s)" = "Linux" ] || return 0

  local ram_mb
  ram_mb="$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  [ "${ram_mb:-0}" -ge 7000 ] && return 0

  info "Servidor con RAM limitada (${ram_mb} MB): ajustando OpenSearch…"
  if [ -z "$(env_get OPENSEARCH_JAVA_OPTS "$ENV_FILE")" ]; then
    # En menos de 4 GB, 256 MB de heap dejan margen para el resto del stack.
    local heap="512m"
    [ "${ram_mb:-0}" -lt 4096 ] && heap="256m"
    env_set OPENSEARCH_JAVA_OPTS "-Xms${heap} -Xmx${heap}"
  fi
  [ -z "$(env_get BOOTSTRAP_MEMORY_LOCK "$ENV_FILE")" ] \
    && env_set BOOTSTRAP_MEMORY_LOCK "false"
  [ -z "$(env_get DISABLE_PERFORMANCE_ANALYZER_AGENT_CLI "$ENV_FILE")" ] \
    && env_set DISABLE_PERFORMANCE_ANALYZER_AGENT_CLI "true"
  # Menos procesos = menos RAM. En 4 GB alcanza para un repositorio pequeño.
  [ -z "$(env_get GUNICORN_WORKERS "$ENV_FILE")" ] \
    && env_set GUNICORN_WORKERS "1"
  [ -z "$(env_get CELERY_CONCURRENCY "$ENV_FILE")" ] \
    && env_set CELERY_CONCURRENCY "1"
  ok "OpenSearch ajustado para poca RAM"
}

# Las imágenes oficiales de OpenSearch >= 2.10 (Amazon Linux 2023) exigen
# x86-64-v2. Sin SSE4.2/POPCNT el contenedor muere con:
#   Fatal glibc error: CPU does not support x86-64-v2
# En ese caso se construye y usa automáticamente una variante compatible
# (binarios oficiales sobre Ubuntu 22.04 + Temurin), salvo que el usuario
# haya definido OPENSEARCH_IMAGE a mano.
OPENSEARCH_COMPAT_IMAGE="invennio/opensearch:2.18.0-oldcpu-v2"

cpu_v2_ok() {
  [ "$(uname -m)" = "x86_64" ] || return 0
  grep -qw sse4_2 /proc/cpuinfo 2>/dev/null \
    && grep -qw popcnt /proc/cpuinfo 2>/dev/null
}

ensure_opensearch_image() {
  local configured
  configured="${OPENSEARCH_IMAGE:-$(env_get OPENSEARCH_IMAGE "$ENV_FILE")}"

  # Migración desde la primera variante compatible (incluía todos los plugins).
  if [ "$configured" = "invennio/opensearch:2.18.0-oldcpu" ]; then
    warn "Actualizando la imagen compatible de OpenSearch (versión sin plugins)…"
    configured=""
  fi

  if [ -n "$configured" ]; then
    ok "Imagen de OpenSearch: $configured"
    return 0
  fi

  if cpu_v2_ok; then
    return 0
  fi

  warn "La CPU/VM no expone x86-64-v2 (SSE4.2/POPCNT)."
  warn "Se usará una imagen de OpenSearch compatible con CPUs antiguas."
  if ! docker image inspect "$OPENSEARCH_COMPAT_IMAGE" >/dev/null 2>&1; then
    info "Construyendo $OPENSEARCH_COMPAT_IMAGE (puede tardar unos minutos)…"
    docker build -t "$OPENSEARCH_COMPAT_IMAGE" \
      -f docker/opensearch-oldcpu/Dockerfile . \
      || die "No se pudo construir la imagen compatible. Revisá la salida anterior."
    ok "Imagen compatible construida"
  else
    ok "Imagen compatible ya disponible: $OPENSEARCH_COMPAT_IMAGE"
  fi
  env_set OPENSEARCH_IMAGE "$OPENSEARCH_COMPAT_IMAGE"
  export OPENSEARCH_IMAGE="$OPENSEARCH_COMPAT_IMAGE"
}

ENV_FILE=".env"
COMPOSE_ARGS=(--env-file .env)
if [ "$MODE" = "prod" ]; then
  ENV_FILE=".env.prod"
  COMPOSE_ARGS=(-f compose.yml -f compose.prod.yml --env-file .env.prod)
fi

compose() { docker compose "${COMPOSE_ARGS[@]}" "$@"; }

service_cid() { # service_cid SERVICIO (solo contenedor en ejecución)
  compose ps -q "$1" 2>/dev/null | head -1
}

# En algunos servidores `docker exec` no devuelve el control aunque el comando
# de dentro ya haya terminado. Todos los exec pasan por `timeout` para que
# ningún paso pueda bloquear la instalación. Ajustable con CT_TIMEOUT=segundos.
CT_TIMEOUT="${CT_TIMEOUT:-300}"

exec_guard() { # exec_guard SEGUNDOS COMANDO...
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout -k 10 "$secs" "$@"
  else
    "$@"
  fi
}

CT() { # CT SERVICIO COMANDO...
  local service="$1"; shift
  local cid
  cid="$(service_cid "$service")"
  if [ -z "$cid" ]; then
    warn "El contenedor de $service no está corriendo."
    return 1
  fi
  exec_guard "$CT_TIMEOUT" docker exec "$cid" "$@"
}

CT_ROOT() { # CT_ROOT SERVICIO COMANDO...
  local service="$1"; shift
  local cid
  cid="$(service_cid "$service")"
  if [ -z "$cid" ]; then
    warn "El contenedor de $service no está corriendo."
    return 1
  fi
  exec_guard "$CT_TIMEOUT" docker exec -u root "$cid" "$@"
}

DB() { CT db "$@"; }

# ---------------------------------------------------------------------------
# 1. Archivo de entorno
# ---------------------------------------------------------------------------
prepare_env() {
  if [ "$MODE" = "prod" ]; then
    if [ ! -f .env.prod ]; then
      [ -f .env.prod.example ] || die "Falta .env.prod.example"
      cp .env.prod.example .env.prod
      warn "Creado .env.prod a partir del ejemplo: revisá dominio, correo y contraseñas."
    fi
  else
    if [ ! -f .env ]; then
      [ -f .env.example ] && cp .env.example .env || : > .env
      ok "Creado .env a partir de .env.example"
    fi
  fi

  # Un .env creado/pegado desde Windows trae CRLF: cada valor queda con un
  # "\r" invisible al final. Eso crea roles como "postgres\r" en PostgreSQL,
  # rompe contraseñas, URLs y TRUSTED_HOSTS. Se normaliza a LF antes de usarlo.
  if grep -q $'\r' "$ENV_FILE" 2>/dev/null; then
    sed -i 's/\r$//' "$ENV_FILE"
    ok "Normalizado $ENV_FILE: se quitaron los CR de Windows (CRLF → LF)"
  fi

  chmod 600 "$ENV_FILE" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 2. Secretos y valores por defecto (solo si faltan o son de ejemplo)
# ---------------------------------------------------------------------------
fill_env_defaults() {
  local changed=0
  set_kv() { # set_kv CLAVE VALOR
    local key="$1" val="$2"
    if grep -qE "^[[:space:]]*${key}=" "$ENV_FILE"; then
      sed -i -E "s|^[[:space:]]*${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
      printf '%s=%s\n' "$key" "$val" >> "$ENV_FILE"
    fi
    changed=1
  }

  local secret salt
  secret="$(env_get INVENIO_SECRET_KEY "$ENV_FILE")"
  salt="$(env_get INVENIO_SECURITY_PASSWORD_SALT "$ENV_FILE")"
  if [ -z "$secret" ] || [ "$secret" = "changeme" ]; then
    set_kv INVENIO_SECRET_KEY "$(rand_secret)"
  fi
  if [ -z "$salt" ]; then
    set_kv INVENIO_SECURITY_PASSWORD_SALT "$(rand_secret)"
  fi

  if [ "$MODE" = "local" ]; then
    [ -z "$(env_get INVENIO_ADMIN_EMAIL "$ENV_FILE")" ] && set_kv INVENIO_ADMIN_EMAIL "admin@inveniosoftware.org"
    [ -z "$(env_get INVENIO_ADMIN_PASSWORD "$ENV_FILE")" ] && set_kv INVENIO_ADMIN_PASSWORD "changeme"
    [ -z "$(env_get INVENIO_SITE_UI_URL "$ENV_FILE")" ] && set_kv INVENIO_SITE_UI_URL "https://localhost"
    # El login local por contraseña debe estar activo en desarrollo.
    set_kv INVENIO_ACCOUNTS_LOCAL_LOGIN_ENABLED "True"
  fi

  if [ "$changed" = 1 ]; then
    ok "Valores por defecto/secretos ajustados en $ENV_FILE"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# 3. Levantar servicios
# ---------------------------------------------------------------------------
up() {
  info "Levantando servicios ($MODE)…"
  compose config -q || die "La configuración de Docker Compose tiene errores."
  compose up -d
  ok "Contenedores iniciados"
}

# ¿PostgreSQL ya acepta conexiones? Se lee el log del contenedor desde su
# último arranque. No se usa `docker exec`/`compose exec`: en algunos
# servidores ese comando imprime el resultado y nunca devuelve el control,
# que es exactamente lo que dejaba el script esperando para siempre.
db_logs_ready() {
  local cid="$1" started logs
  started="$(docker inspect -f '{{.State.StartedAt}}' "$cid" 2>/dev/null || true)"
  if [ -n "$started" ]; then
    logs="$(exec_guard 20 docker logs --since "$started" "$cid" 2>&1 || true)"
  else
    logs="$(exec_guard 20 docker logs --tail 200 "$cid" 2>&1 || true)"
  fi
  case "$logs" in
    *"database system is ready to accept connections"*) return 0 ;;
    *) return 1 ;;
  esac
}

wait_db() {
  info "Esperando a PostgreSQL…"
  local i cid state health
  for i in $(seq 1 90); do
    cid="$(service_cid db)"
    [ -n "$cid" ] || cid="$(compose ps -aq db 2>/dev/null | head -1)"
    if [ -z "$cid" ]; then
      warn "El contenedor db no existe."
      compose logs --tail=60 db || true
      die "PostgreSQL no arrancó. Revisá: docker compose logs db"
    fi

    state="$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || true)"
    health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$cid" 2>/dev/null || true)"

    if [ "$state" = "running" ] && { [ "$health" = "healthy" ] || db_logs_ready "$cid"; }; then
      ok "PostgreSQL listo"
      return 0
    fi

    if [ "$state" = "exited" ] || [ "$state" = "dead" ] || [ "$health" = "unhealthy" ]; then
      warn "El contenedor db no está sano (estado: ${state:-?}, health: ${health:-?}). Últimos logs:"
      compose logs --tail=60 db || true
      die "PostgreSQL no arrancó. Revisá: docker compose logs db"
    fi

    if [ $((i % 5)) -eq 0 ]; then
      info "PostgreSQL aún no responde (${i}/90, estado: ${state:-desconocido}, health: ${health:-sin healthcheck})…"
    fi
    sleep 2
  done
  warn "PostgreSQL no respondió a tiempo. Últimos logs:"
  compose logs --tail=60 db || true
  die "PostgreSQL no respondió a tiempo. Revisá: docker compose logs db"
}

# Ejecuta la petición de salud dentro de search con un límite duro en el
# propio host. Usa `docker exec` sobre el ID (más fiable que compose exec)
# y acepta el estado "healthy" del healthcheck como confirmación.
search_container_id() {
  compose ps -q search 2>/dev/null | head -1
}

search_health_status() {
  local cid
  cid="$(search_container_id)"
  [ -n "$cid" ] || return 1
  docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$cid" 2>/dev/null
}

search_http_ok() {
  local cid
  cid="$(search_container_id)"
  [ -n "$cid" ] || return 1
  [ "$(search_health_status)" = "healthy" ] && return 0

  local cmd=(docker exec "$cid" sh -c \
    "curl -fsS --connect-timeout 2 --max-time 5 'http://127.0.0.1:9200/_cluster/health'")
  exec_guard 15 "${cmd[@]}" >/dev/null 2>&1
}

# Señal de disponibilidad sin usar `docker exec`: el log del arranque actual
# indica que el nodo ya publicó el cluster. El healthcheck (curl dentro del
# contenedor) puede quedarse "unhealthy" en servidores donde `docker exec`
# no devuelve el control aunque el comando de dentro termine.
search_logs_ready() {
  local cid="$1" started logs
  [ -n "$cid" ] || return 1
  started="$(docker inspect -f '{{.State.StartedAt}}' "$cid" 2>/dev/null || true)"
  if [ -n "$started" ]; then
    logs="$(exec_guard 20 docker logs --since "$started" "$cid" 2>&1 || true)"
  else
    logs="$(exec_guard 20 docker logs --tail 400 "$cid" 2>&1 || true)"
  fi
  case "$logs" in
    *"Cluster health status changed from [YELLOW] to [GREEN]"*) return 0 ;;
    *"Cluster health status changed from [RED] to [GREEN]"*) return 0 ;;
    *"Cluster health status changed from [RED] to [YELLOW]"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Sin OpenSearch la web arranca igual, pero fallan "invenio index init" y
# "invenio rdm-records custom-fields init". Por eso se espera y, si el
# contenedor murió, se aborta con la causa en vez de seguir a ciegas.
wait_search() {
  info "Esperando a OpenSearch…"
  local i state cid health attempts=150
  for i in $(seq 1 "$attempts"); do
    cid="$(search_container_id)"
    health="$(search_health_status)"

    if [ "$health" = "healthy" ]; then
      ok "OpenSearch listo"
      return 0
    fi

    # El healthcheck usa `docker exec` (curl dentro del contenedor). Si no es
    # fiable en este servidor, el log del arranque es igual de concluyente.
    if search_logs_ready "$cid"; then
      ok "OpenSearch listo (según su log de arranque)"
      return 0
    fi

    [ -n "$cid" ] || cid="$(compose ps -aq search 2>/dev/null | head -1)"
    state=""
    if [ -n "$cid" ]; then
      state="$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || true)"
    else
      warn "El contenedor search no existe. Últimos logs:"
      compose logs --tail=40 search || true
      die "No se pudo crear el contenedor de OpenSearch. Revisá: docker compose logs search"
    fi
    if [ "$state" = "exited" ] || [ "$state" = "dead" ] || [ "$state" = "restarting" ]; then
      local code log
      code="$(docker inspect -f '{{.State.ExitCode}}' "$cid" 2>/dev/null || true)"
      log="$(compose logs --tail=40 search 2>/dev/null || true)"
      warn "El contenedor search se detuvo (código ${code:-?}). Últimos logs:"
      [ -n "$log" ] && printf '%s\n' "$log"
      if printf '%s' "$log" | grep -q "x86-64-v2"; then
        die "La CPU/VM no soporta x86-64-v2 (SSE4.2/POPCNT). OpenSearch oficial >= 2.10 no arranca en este servidor.
      Solución recomendada: en Proxmox, apagá la VM y poné Hardware > Processors > Type: host; luego encendé la VM.
      Si no controlás el hipervisor, definí OPENSEARCH_IMAGE en $ENV_FILE con una imagen compatible.
      Verificá la CPU con: grep -o 'sse4_2\\|popcnt' /proc/cpuinfo | sort -u"
      fi
      if [ "$code" = "137" ]; then
        die "OpenSearch se quedó sin memoria (OOM). Bajá OPENSEARCH_JAVA_OPTS (p. ej. -Xms512m -Xmx512m) y volvé a ejecutar ./setup.sh $MODE"
      fi
      die "OpenSearch no arrancó. Causa habitual: vm.max_map_count bajo o falta de memlock. Revisá: docker compose logs search"
    fi

    if [ $((i % 15)) -eq 0 ]; then
      info "OpenSearch aún no responde (${i}/${attempts}, estado: ${state:-desconocido})…"
    fi
    sleep 2
  done

  warn "OpenSearch no respondió tras $((attempts * 2)) segundos. Diagnóstico:"
  compose ps search || true
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null | head -5 || true
  sysctl vm.max_map_count 2>/dev/null || true
  free -h 2>/dev/null || true
  if [ -n "$cid" ]; then
    warn "Prueba directa a OpenSearch:"
    exec_guard 15 docker exec "$cid" sh -c \
      "curl -v --connect-timeout 2 --max-time 5 'http://127.0.0.1:9200/_cluster/health'" \
      2>&1 | tail -15 || true
  fi
  warn "Últimos logs de OpenSearch:"
  compose logs --tail=60 search || true
  die "OpenSearch no respondió a tiempo. Revisá: docker compose logs search"
}

# ¿Hay algo escuchando en ese puerto del host? No usa docker exec.
port_open() { # port_open HOST PUERTO
  (exec 3<>"/dev/tcp/$1/$2") >/dev/null 2>&1
}

# gunicorn anuncia "Listening at: http://0.0.0.0:5000" al arrancar.
web_logs_ready() {
  local cid="$1" started logs
  [ -n "$cid" ] || return 1
  started="$(docker inspect -f '{{.State.StartedAt}}' "$cid" 2>/dev/null || true)"
  if [ -n "$started" ]; then
    logs="$(exec_guard 15 docker logs --since "$started" "$cid" 2>&1 || true)"
  else
    logs="$(exec_guard 15 docker logs --tail 200 "$cid" 2>&1 || true)"
  fi
  case "$logs" in
    *"Listening at:"*) return 0 ;;
    *) return 1 ;;
  esac
}

web_url_ok() {
  local url code
  url="$(public_url)"
  [ -n "$url" ] || return 1
  code="$(curl -k -sL -o /dev/null -w '%{http_code}' --max-time 10 \
          "$url/" 2>/dev/null || true)"
  [ "$code" = "200" ]
}

wait_web() {
  info "Esperando a la aplicación web…"
  info "La web puede tardar hasta 2 minutos en arrancar. Ctrl+C es seguro: no borra nada."
  local i cid state last
  for i in $(seq 1 60); do
    if [ "$MODE" = "prod" ] && port_open 127.0.0.1 5000; then
      ok "Web escuchando en 127.0.0.1:5000"
      return 0
    fi
    if web_url_ok; then
      ok "Web respondiendo en $(public_url)"
      return 0
    fi

    cid="$(service_cid web)"
    if [ -z "$cid" ]; then
      cid="$(compose ps -aq web 2>/dev/null | head -1)"
      if [ -z "$cid" ]; then
        warn "El contenedor web no existe. Últimos logs:"
        compose logs --tail=80 web || true
        die "La web no arrancó. Revisá: docker compose logs web"
      fi
    fi
    state=""
    [ -n "$cid" ] && state="$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || true)"
    if [ "$state" = "exited" ] || [ "$state" = "dead" ] || [ "$state" = "restarting" ]; then
      local code
      code="$(docker inspect -f '{{.State.ExitCode}}' "$cid" 2>/dev/null || true)"
      warn "El contenedor web se detuvo (código ${code:-?}). Últimos logs:"
      exec_guard 20 docker logs --tail=80 "$cid" 2>&1 || true
      die "La web no arrancó. Revisá: docker compose logs web"
    fi

    # El arranque de gunicorn se ve en el log del contenedor y no necesita exec.
    if web_logs_ready "$cid"; then
      ok "Web arrancada (gunicorn escuchando en el puerto 5000)"
      return 0
    fi

    if [ $((i % 5)) -eq 0 ]; then
      info "La web aún no responde (${i}/60, estado: ${state:-desconocido})…"
      last="$(exec_guard 15 docker logs --tail 4 "$cid" 2>&1 | tail -3 || true)"
      [ -n "$last" ] && printf '%s\n' "$last" | sed 's/^/      /'
    fi
    sleep 2
  done

  warn "La web no respondió a tiempo. Últimos logs:"
  compose logs --tail=80 web || true
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null | head -6 || true
  die "La web no arrancó. Revisá: docker compose logs web"
}

db_initialized() {
  local user db
  user="$(env_get POSTGRES_USER "$ENV_FILE")"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB "$ENV_FILE")"; db="${db:-inveniordm}"
  local out
  out="$(DB psql -U "$user" -d "$db" -tAc \
        "select to_regclass('public.accounts_user')" 2>/dev/null | tr -d '[:space:]')"
  [ "$out" = "accounts_user" ]
}

# ---------------------------------------------------------------------------
# 4. Inicialización de InvenioRDM (solo la primera vez)
# ---------------------------------------------------------------------------
init_invenio() {
  info "Se preparan tablas, roles, índices y almacenamiento de archivos."
  T0="$(date +%s 2>/dev/null || echo 0)"
  CT_ROOT web chown -R 1654:0 /opt/invenio/var/instance/data 2>/dev/null || true

  # Cada comando es idempotente en la práctica; si algo ya existe no se aborta.
  run_soft() { # run_soft "descripción" COMANDO...
    local desc="$1"; shift
    local t0 t1 rc
    show_cmd "$@"
    t0="$(date +%s 2>/dev/null || echo 0)"
    if CT web "$@"; then rc=0; else rc=$?; fi
    t1="$(date +%s 2>/dev/null || echo 0)"
    if [ "$rc" -eq 0 ]; then
      ok "$desc ($((t1 - t0))s)"
    else
      warn "Sin cambios: $desc (código $rc; normalmente significa que ya existía)"
    fi
    return 0
  }

  run_soft "Base de datos: tablas y extensiones" invenio db init create

  show_cmd invenio files location list
  if ! CT web invenio files location list 2>/dev/null | grep -qi "default"; then
    run_soft "Almacenamiento local de archivos" invenio files location create --default default \
      "file:///opt/invenio/var/instance/data"
  else
    ok "Ubicación de archivos ya configurada"
  fi

  run_soft "Rol admin" invenio roles create admin
  run_soft "Permiso superusuario para admin" invenio access allow superuser-access role admin
  run_soft "Rol administration" invenio roles create administration
  run_soft "Permiso de administración" invenio access allow administration-access role administration
  run_soft "Rol administration-moderation" invenio roles create administration-moderation
  run_soft "Permiso de moderación" invenio access allow administration-moderation role administration-moderation

  # Los índices viven en OpenSearch. Se crean solo si aún no existen, porque
  # "invenio index init" falla cuando los índices ya están creados.
  ensure_search_indexes

  # Vocabularios obligatorios. Sin ellos, páginas como los ajustes de una
  # comunidad o el formulario de depósito fallan con error 500/404 porque
  # invenio-vocabularies espera que existan los tipos (communitytypes,
  # resourcetypes, languages, licenses, ...). El comando es idempotente y no
  # crea registros de ejemplo (records.yaml/communities.yaml están vacíos).
  run_soft "Vocabularios y fixtures de InvenioRDM" invenio rdm-records fixtures

  if [ "${SEED_DEMO:-0}" = "1" ]; then
    run_soft "Comunidades de ejemplo" invenio rdm-records demo communities
    run_soft "Registros de ejemplo" invenio rdm-records demo records
  fi

  run_soft "Reconstruyendo índices de búsqueda" invenio rdm rebuild-all-indices
  run_soft "Colas de tareas (Celery)" invenio queues declare

  local t1
  t1="$(date +%s 2>/dev/null || echo 0)"
  ok "InvenioRDM inicializado en $((t1 - T0))s"
}

# Crea los índices que falten sin tocar los existentes. `invenio index init`
# no sirve aquí: aborta con IndexAlreadyExistsError si ya hay algún índice.
# La API `current_search.create(ignore_existing=True)` sí es idempotente.
ensure_search_indexes() {
  info "Verificando índices y campos personalizados en OpenSearch…"
  show_cmd invenio shell --no-term-title -c "current_search.create(ignore_existing=True)"
  CT web invenio shell --no-term-title -c \
    "from invenio_search.proxies import current_search; list(current_search.create(ignore=[400], ignore_existing=True))" \
    || die "No se pudieron crear/verificar los índices en OpenSearch. Revisá: docker compose logs search"
  ok "Índices de búsqueda listos (se crean solo los que faltan)"

  show_cmd invenio rdm-records custom-fields init
  CT web invenio rdm-records custom-fields init \
    || die "No se pudieron crear los campos personalizados (requiere OpenSearch)."
  # Puede terminar en 0 aunque no haya campos configurados.
  CT web invenio communities custom-fields init >/dev/null 2>&1 || true
  ok "Campos personalizados de registros y comunidades listos"
}

# Comprueba que los tipos de vocabulario esenciales existan en la base de datos.
db_has_vocabularies() {
  local user db out
  user="$(env_get POSTGRES_USER "$ENV_FILE")"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB "$ENV_FILE")"; db="${db:-inveniordm}"
  out="$(DB psql -U "$user" -d "$db" -tAc \
        "select count(distinct id) from vocabularies_types
         where id in ('creatorsroles','contributorsroles','licenses','languages',
                      'relationtypes','resourcetypes','communitytypes')" \
        2>/dev/null | tr -d '[:space:]')"
  [ "${out:-0}" = "7" ]
}

# Repara instalaciones existentes a las que nunca se les cargaron los
# vocabularios (p. ej. porque setup.sh se ejecutó sin SEED_DEMO). Es
# idempotente y no toca registros ni usuarios.
ensure_vocabularies() {
  if db_has_vocabularies; then
    ok "Vocabularios de InvenioRDM presentes"
    return 0
  fi

  info "Cargando vocabularios requeridos (communitytypes, resourcetypes, languages…)"
  show_cmd invenio rdm-records fixtures
  CT web invenio rdm-records fixtures

  if db_has_vocabularies; then
    ok "Vocabularios cargados"
  else
    warn "No se pudieron verificar los vocabularios; revisá: docker compose logs web"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# 5. Administrador inicial
# ---------------------------------------------------------------------------
create_admin() {
  local email pass user db exists
  email="${ADMIN_EMAIL:-$(env_get INVENIO_ADMIN_EMAIL "$ENV_FILE")}"
  pass="${ADMIN_PASSWORD:-$(env_get INVENIO_ADMIN_PASSWORD "$ENV_FILE")}"
  user="$(env_get POSTGRES_USER "$ENV_FILE")"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB "$ENV_FILE")"; db="${db:-inveniordm}"

  [ -n "$email" ] && [ -n "$pass" ] || { warn "Sin INVENIO_ADMIN_EMAIL/PASSWORD: no se creó administrador"; return 0; }

  exists="$(DB psql -U "$user" -d "$db" -tAc \
            "select 1 from accounts_user where email='${email//\'/\'\'}'" 2>/dev/null | tr -d '[:space:]')"
  if [ "$exists" = "1" ]; then
    ok "El administrador $email ya existe"
  else
    info "Creando administrador $email…"
    show_cmd invenio users create "$email" --password "***" --active --confirm
    CT web invenio users create "$email" --password "$pass" --active --confirm \
      || die "No se pudo crear el administrador. Revisá que el correo sea válido y la contraseña tenga al menos 8 caracteres."
    ok "Administrador creado"
  fi
  show_cmd invenio roles add "$email" admin
  CT web invenio roles add "$email" admin >/dev/null 2>&1 || true
  show_cmd invenio roles add "$email" administration
  CT web invenio roles add "$email" administration >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# 6. Verificación
# ---------------------------------------------------------------------------
public_url() {
  local url
  url="$(env_get INVENIO_SITE_UI_URL "$ENV_FILE")"
  if [ -z "$url" ]; then
    if [ "$MODE" = "prod" ]; then url="http://127.0.0.1:5000"; else url="https://localhost"; fi
  fi
  printf '%s' "$url"
}

verify() {
  local url code direct_ok=1 search_ok=1
  url="$(public_url)"

  info "Comprobando OpenSearch…"
  if search_http_ok; then
    ok "OpenSearch responde"
  else
    warn "OpenSearch no responde (la búsqueda y la creación de índices fallarán)"
    search_ok=0
  fi

  if [ "$MODE" = "prod" ]; then
    info "Comprobando la app directo en 127.0.0.1:5000…"
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 \
            -H 'X-Forwarded-Proto: https' -H 'X-Forwarded-Host: localhost' \
            http://127.0.0.1:5000/ || true)"
    if [ "$code" = "200" ]; then
      ok "InvenioRDM responde 200"
    else
      warn "InvenioRDM respondió ${code:-sin respuesta}"
      direct_ok=0
    fi
  fi

  info "Comprobando $url…"
  code="$(curl -k -sL -o /dev/null -w '%{http_code}' --max-time 25 "$url/" || true)"
  if [ "$code" = "200" ]; then
    ok "Sitio público responde 200"
  else
    warn "El sitio público respondió ${code:-sin respuesta} (revisá el proxy/Apache)"
  fi

  info "Estado de contenedores:"
  compose ps --format 'table {{.Name}}\t{{.Status}}'

  if [ "$MODE" = "prod" ]; then
    if [ "$direct_ok" = "1" ] && [ "$search_ok" = "1" ]; then
      return 0
    fi
  else
    if [ "$code" = "200" ] && [ "$search_ok" = "1" ]; then
      return 0
    fi
  fi

  echo
  warn "Últimos errores del contenedor web:"
  compose logs --tail=30 web || true
  [ "$search_ok" = "1" ] || { echo; warn "Últimos errores de OpenSearch:"; compose logs --tail=30 search || true; }
  return 1
}

# ---------------------------------------------------------------------------
# Flujo principal
# ---------------------------------------------------------------------------
check_docker

if [ "$MODE" = "verify" ]; then
  [ -f "$ENV_FILE" ] || die "No existe $ENV_FILE"
  verify
  exit $?
fi

show_plan

step "Preparando el archivo de entorno ($ENV_FILE)"
prepare_env
fill_env_defaults
step_time

step "Ajustes del sistema: vm.max_map_count y swap"
ensure_host_setup
ensure_swap
step_time

step "Ajustando OpenSearch a la memoria disponible"
tune_low_memory
step_time

step "Comprobando la imagen de OpenSearch para esta CPU"
ensure_opensearch_image
step_time

step "Levantando los contenedores (db, cache, search, web, worker)"
up
step_time

step "Esperando a PostgreSQL (normalmente 10–30 s)"
wait_db
step_time

step "Esperando a OpenSearch (1–3 min la primera vez)"
wait_search
step_time

step "Esperando a la aplicación web (30 s – 2 min)"
wait_web
step_time

if db_initialized; then
  step "Base de datos ya inicializada: comprobando índices y campos"
  ok "La base de datos ya existía (se omite la instalación inicial)"
  ensure_search_indexes
else
  step "Inicializando InvenioRDM (tablas, roles, índices: 3–10 min)"
  init_invenio
fi
step_time

step "Comprobando los vocabularios obligatorios"
ensure_vocabularies
step_time

step "Creando el administrador inicial"
create_admin
step_time

step "Verificación final"
verify || die "La instalación terminó pero la verificación falló. Revisá los logs de arriba."
step_time

URL="$(public_url)"
ADMIN_SHOW="${ADMIN_EMAIL:-$(env_get INVENIO_ADMIN_EMAIL "$ENV_FILE")}"
echo
echo "${BOLD}${GREEN}Listo.${NC} Repositorio HGI funcionando en ${BOLD}${URL}${NC}"
echo
printf '  %-14s %s\n' "Sitio" "$URL"
printf '  %-14s %s\n' "Administrador" "${ADMIN_SHOW:-sin definir}"
printf '  %-14s %s\n' "Contraseña" "la definida en $ENV_FILE"
printf '  %-14s %s\n' "Modo" "$MODE"
printf '  %-14s %s\n' "Datos" "volúmenes db-data, instance-data y search-data"
echo
echo "  Contenedores:"
compose ps --format '    {{.Name}}  {{.Status}}' || true
echo
echo "  Comandos útiles:"
printf '    %sestado   %s docker compose %s ps\n' "$DIM" "$NC" "${COMPOSE_ARGS[*]}"
printf '    %slogs web %s docker compose %s logs -f web\n' "$DIM" "$NC" "${COMPOSE_ARGS[*]}"
printf '    %sreiniciar%s docker compose %s restart web\n' "$DIM" "$NC" "${COMPOSE_ARGS[*]}"
printf '    %sreparar  %s ./setup.sh %s\n' "$DIM" "$NC" "$MODE"
echo
if [ "$MODE" = "local" ]; then
  echo "  Nota: el certificado de Caddy es autofirmado. Para evitar el aviso del"
  echo "  navegador, importá data/caddy/pki/authorities/local/root.crt en tu sistema."
  echo "  Cambios de plantillas/CSS: docker compose restart web"
else
  echo "  Apache/aaPanel debe proxyear a 127.0.0.1:5000. Configuraciones listas en:"
  echo "    apache/repositorio-unae.conf          (Apache del sistema)"
  echo "    apache/repositorio-unae-aapanel.conf  (aaPanel)"
  echo "  Tras cambiar variables de entorno: docker compose ${COMPOSE_ARGS[*]} up -d web worker"
fi
