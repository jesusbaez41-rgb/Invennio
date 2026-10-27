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
#   SEED_DEMO=1          carga registros/comunidades de ejemplo
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

ENV_FILE=".env"
COMPOSE_ARGS=(--env-file .env)
if [ "$MODE" = "prod" ]; then
  ENV_FILE=".env.prod"
  COMPOSE_ARGS=(-f compose.yml -f compose.prod.yml --env-file .env.prod)
fi

compose() { docker compose "${COMPOSE_ARGS[@]}" "$@"; }
CT() { compose exec -T "$@"; }

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
    if compose exec -T db pg_isready -U "$user" -d "$db" >/dev/null 2>&1; then
      ok "PostgreSQL listo"
      return 0
    fi
    sleep 2
  done
  die "PostgreSQL no respondió a tiempo. Revisá: docker compose logs db"
}

wait_web() {
  info "Esperando a la aplicación web…"
  local i
  for i in $(seq 1 90); do
    if compose exec -T web python -c "import socket; socket.create_connection(('127.0.0.1',5000),2)" >/dev/null 2>&1; then
      ok "Web escuchando en el puerto 5000"
      return 0
    fi
    sleep 2
  done
  die "La web no arrancó. Revisá: docker compose logs web"
}

db_initialized() {
  local user db
  user="$(env_get POSTGRES_USER "$ENV_FILE")"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB "$ENV_FILE")"; db="${db:-inveniordm}"
  local out
  out="$(compose exec -T db psql -U "$user" -d "$db" -tAc \
        "select to_regclass('public.accounts_user')" 2>/dev/null | tr -d '[:space:]')"
  [ "$out" = "accounts_user" ]
}

# ---------------------------------------------------------------------------
# 4. Inicialización de InvenioRDM (solo la primera vez)
# ---------------------------------------------------------------------------
init_invenio() {
  info "Inicializando base de datos, índices, roles y almacenamiento…"
  compose exec -T -u root web chown -R 1654:0 /opt/invenio/var/instance/data 2>/dev/null || true

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

  run_soft invenio index init
  run_soft invenio rdm-records custom-fields init
  run_soft invenio communities custom-fields init

  if [ "${SEED_DEMO:-0}" = "1" ]; then
    run_soft invenio rdm-records fixtures
  fi

  run_soft invenio rdm rebuild-all-indices
  run_soft invenio queues declare
  ok "InvenioRDM inicializado"
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

  exists="$(compose exec -T db psql -U "$user" -d "$db" -tAc \
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
  local url code direct_ok=1
  url="$(public_url)"

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
    [ "$direct_ok" = "1" ] && return 0
  else
    [ "$code" = "200" ] && return 0
  fi

  echo
  warn "Últimos errores del contenedor web:"
  compose logs --tail=30 web || true
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
up
wait_db
wait_web

if db_initialized; then
  ok "La base de datos ya estaba inicializada (se omite la instalación inicial)"
else
  init_invenio
fi

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
