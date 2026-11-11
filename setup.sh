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

MODE="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BOLD=$'\033[1m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; NC=$'\033[0m'
info()  { echo "${BOLD}==>${NC} $*"; }
ok()    { echo "${GREEN}  ✓${NC} $*"; }
warn()  { echo "${YELLOW}  !${NC} $*"; }
die()   { echo "${RED}  ✗${NC} $*" >&2; exit 1; }

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
    | sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/'
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

CT() { # CT SERVICIO COMANDO...
  local service="$1"; shift
  local cid
  cid="$(service_cid "$service")"
  if [ -z "$cid" ]; then
    warn "El contenedor de $service no está corriendo."
    return 1
  fi
  docker exec -T "$cid" "$@"
}

CT_ROOT() { # CT_ROOT SERVICIO COMANDO...
  local service="$1"; shift
  local cid
  cid="$(service_cid "$service")"
  if [ -z "$cid" ]; then
    warn "El contenedor de $service no está corriendo."
    return 1
  fi
  docker exec -T -u root "$cid" "$@"
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

wait_db() {
  info "Esperando a PostgreSQL…"
  local user db i
  user="$(env_get POSTGRES_USER "$ENV_FILE")"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB "$ENV_FILE")"; db="${db:-inveniordm}"
  for i in $(seq 1 60); do
    if CT db pg_isready -U "$user" -d "$db" >/dev/null 2>&1; then
      ok "PostgreSQL listo"
      return 0
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

  local cmd=(docker exec -T "$cid" sh -c \
    "curl -fsS --connect-timeout 2 --max-time 5 'http://127.0.0.1:9200/_cluster/health'")
  if command -v timeout >/dev/null 2>&1; then
    timeout 15 "${cmd[@]}" >/dev/null 2>&1
  else
    "${cmd[@]}" >/dev/null 2>&1
  fi
}

# Sin OpenSearch la web arranca igual, pero fallan "invenio index init" y
# "invenio rdm-records custom-fields init". Por eso se espera y, si el
# contenedor murió, se aborta con la causa en vez de seguir a ciegas.
wait_search() {
  info "Esperando a OpenSearch…"
  local i state cid attempts=150
  for i in $(seq 1 "$attempts"); do
    if search_http_ok; then
      ok "OpenSearch listo"
      return 0
    fi

    cid="$(search_container_id)"
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
    docker exec -T "$cid" sh -c \
      "curl -v --connect-timeout 2 --max-time 5 'http://127.0.0.1:9200/_cluster/health'" \
      2>&1 | tail -15 || true
  fi
  warn "Últimos logs de OpenSearch:"
  compose logs --tail=60 search || true
  die "OpenSearch no respondió a tiempo. Revisá: docker compose logs search"
}

wait_web() {
  info "Esperando a la aplicación web…"
  local i cid state
  for i in $(seq 1 90); do
    if CT web python -c \
         "import socket; socket.create_connection(('127.0.0.1',5000),2)" \
         >/dev/null 2>&1; then
      ok "Web escuchando en el puerto 5000"
      return 0
    fi

    cid="$(service_cid web)"
    state=""
    [ -n "$cid" ] && state="$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || true)"
    if [ "$state" = "exited" ] || [ "$state" = "dead" ]; then
      warn "El contenedor web se detuvo. Últimos logs:"
      compose logs --tail=60 web || true
      die "La web no arrancó. Revisá: docker compose logs web"
    fi

    if [ $((i % 15)) -eq 0 ]; then
      info "La web aún no responde (${i}/90, estado: ${state:-desconocido})…"
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
  info "Inicializando base de datos, índices, roles y almacenamiento…"
  CT_ROOT web chown -R 1654:0 /opt/invenio/var/instance/data 2>/dev/null || true

  # Cada comando es idempotente en la práctica; si algo ya existe no se aborta.
  run_soft() { CT web "$@" || warn "Sin cambios: $*"; }

  run_soft invenio db init create
  if ! CT web invenio files location list 2>/dev/null | grep -qi "default"; then
    run_soft invenio files location create --default default \
      "file:///opt/invenio/var/instance/data"
  fi

  run_soft invenio roles create admin
  run_soft invenio access allow superuser-access role admin
  run_soft invenio roles create administration
  run_soft invenio access allow administration-access role administration
  run_soft invenio roles create administration-moderation
  run_soft invenio access allow administration-moderation role administration-moderation

  # Los índices viven en OpenSearch. Se crean solo si aún no existen, porque
  # "invenio index init" falla cuando los índices ya están creados.
  ensure_search_indexes

  # Vocabularios obligatorios. Sin ellos, páginas como los ajustes de una
  # comunidad o el formulario de depósito fallan con error 500/404 porque
  # invenio-vocabularies espera que existan los tipos (communitytypes,
  # resourcetypes, languages, licenses, ...). El comando es idempotente y no
  # crea registros de ejemplo (records.yaml/communities.yaml están vacíos).
  run_soft invenio rdm-records fixtures

  if [ "${SEED_DEMO:-0}" = "1" ]; then
    run_soft invenio rdm-records demo communities
    run_soft invenio rdm-records demo records
  fi

  run_soft invenio rdm rebuild-all-indices
  run_soft invenio queues declare
  ok "InvenioRDM inicializado"
}

# ¿Ya hay índices de Invenio en OpenSearch? Sirve para no repetir
# "invenio index init", que aborta con IndexAlreadyExistsError.
search_has_indexes() {
  local prefix cid
  prefix="$(env_get INVENIO_SEARCH_INDEX_PREFIX "$ENV_FILE")"
  prefix="${prefix:-invenio-rdm-}"
  cid="$(search_container_id)"
  [ -n "$cid" ] || return 1
  local cmd=(docker exec -T "$cid" sh -c \
    "curl -fsS --connect-timeout 2 --max-time 5 'http://127.0.0.1:9200/_cat/indices/${prefix}*?h=index'")
  if command -v timeout >/dev/null 2>&1; then
    timeout 15 "${cmd[@]}" 2>/dev/null | grep -q .
  else
    "${cmd[@]}" 2>/dev/null | grep -q .
  fi
}

# Repara instalaciones con la base de datos ya creada pero sin índices, por
# ejemplo si OpenSearch no estaba listo durante la primera ejecución. Es
# idempotente: no borra ni recrea índices existentes.
ensure_search_indexes() {
  info "Verificando índices y campos personalizados en OpenSearch…"
  if search_has_indexes; then
    ok "Índices de búsqueda ya presentes"
  else
    CT web invenio index init \
      || die "No se pudieron crear los índices en OpenSearch. Revisá: docker compose logs search"
  fi
  CT web invenio rdm-records custom-fields init \
    || die "No se pudieron crear los campos personalizados (requiere OpenSearch)."
  # Puede terminar en 0 aunque no haya campos configurados.
  CT web invenio communities custom-fields init >/dev/null 2>&1 || true
  ok "Índices y campos personalizados listos"
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
    CT web invenio users create "$email" --password "$pass" --active --confirm \
      || die "No se pudo crear el administrador. Revisá que el correo sea válido y la contraseña tenga al menos 8 caracteres."
    ok "Administrador creado"
  fi
  CT web invenio roles add "$email" admin >/dev/null 2>&1 || true
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

prepare_env
fill_env_defaults
ensure_host_setup
ensure_swap
tune_low_memory
ensure_opensearch_image
up
wait_db
wait_search
wait_web

if db_initialized; then
  ok "La base de datos ya estaba inicializada (se omite la instalación inicial)"
  # Puede faltar la creación de índices si OpenSearch no estaba listo antes.
  ensure_search_indexes
else
  init_invenio
fi

# También en instalaciones ya existentes: los vocabularios son imprescindibles
# para los ajustes de comunidad, el depósito de registros, etc.
ensure_vocabularies

create_admin

info "Verificando instalación…"
verify || die "La instalación terminó pero la verificación falló. Revisá los logs."

URL="$(public_url)"
echo
echo "${BOLD}${GREEN}Listo.${NC} Repositorio HGI funcionando en ${BOLD}${URL}${NC}"
echo "  Administrador : ${BOLD}${ADMIN_EMAIL:-$(env_get INVENIO_ADMIN_EMAIL "$ENV_FILE")}${NC}"
echo "  Contraseña    : (la definida en $ENV_FILE)"
if [ "$MODE" = "local" ]; then
  echo
  echo "  Nota: el certificado de Caddy es autofirmado. Para evitar el aviso del"
  echo "  navegador, importá data/caddy/pki/authorities/local/root.crt en tu sistema."
  echo "  Cambios de plantillas/CSS: docker compose restart web"
else
  echo
  echo "  Apache debe proxyear a 127.0.0.1:5000. Configuraciones listas en:"
  echo "    apache/repositorio-unae.conf          (Apache del sistema)"
  echo "    apache/repositorio-unae-aapanel.conf  (aaPanel)"
  echo "  Tras cambiar variables de entorno: docker compose ${COMPOSE_ARGS[*]} up -d web worker"
fi
