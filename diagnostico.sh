#!/usr/bin/env bash
# Diagnóstico del Repositorio HGI (InvenioRDM + Docker)
#
# Uso:
#   ./diagnostico.sh prod     # producción (.env.prod + compose.prod.yml)
#   ./diagnostico.sh local    # local (.env + compose.yml)
#
# Genera un archivo diagnostico-AAAAMMDD-HHMMSS.txt con toda la salida.
set -u

MODE="${1:-prod}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR" || exit 1

case "$MODE" in
  local)
    ENV_FILE=".env"
    COMPOSE=(docker compose --env-file "$ENV_FILE")
    ;;
  prod)
    ENV_FILE=".env.prod"
    COMPOSE=(docker compose -f compose.yml -f compose.prod.yml --env-file "$ENV_FILE")
    ;;
  *)
    echo "Uso: $0 [local|prod]" >&2
    exit 2
    ;;
esac

dc() { "${COMPOSE[@]}" "$@"; }
section() { printf '\n===== %s =====\n' "$*"; }
mask() {
  sed -E \
    -e 's/(POSTGRES_PASSWORD|INVENIO_SECRET_KEY|INVENIO_SECURITY_PASSWORD_SALT|INVENIO_ADMIN_PASSWORD|INVENIO_MAIL_PASSWORD|INVENIO_S3_SECRET_ACCESS_KEY|INVENIO_S3_ACCESS_KEY_ID|INVENIO_OIDC_APP_CREDENTIALS_CONSUMER_SECRET)([:=]).*/\1\2***/g' \
    -e 's#(://[^:/@]+:)[^@]+@#\1***@#g'
}
cid() { dc ps -q "$1" 2>/dev/null | head -1; }
any_cid() { dc ps -aq "$1" 2>/dev/null | head -1; }

inspect_one() {
  local svc="$1" id
  id="$(cid "$svc")"
  [ -n "$id" ] || id="$(any_cid "$svc")"
  if [ -z "$id" ]; then
    printf '%-7s NO EXISTE\n' "$svc"
    return
  fi
  docker inspect -f '{{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} restarts={{.RestartCount}}' "$id" 2>/dev/null \
    || printf '%-7s inspect falló\n' "$svc"
}

env_get() {
  local key="$1"
  sed -n "s/^[[:space:]]*${key}=//p" "$ENV_FILE" 2>/dev/null | tail -1 \
    | sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/'
}

test_pg_isready() {
  local id user db
  id="$(cid db)"; [ -n "$id" ] || id="$(any_cid db)"
  user="$(env_get POSTGRES_USER)"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB)"; db="${db:-inveniordm}"
  if [ -z "$id" ]; then
    echo "db: contenedor no encontrado"
    return
  fi
  echo "db id: $id  (usuario=$user base=$db)"
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 docker exec "$id" pg_isready -U "$user" -d "$db"
    echo "pg_isready exit=$?"
  else
    docker exec "$id" pg_isready -U "$user" -d "$db"
    echo "pg_isready exit=$?"
  fi
}

test_sql() {
  local id user db out rc
  id="$(cid db)"; [ -n "$id" ] || id="$(any_cid db)"
  user="$(env_get POSTGRES_USER)"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB)"; db="${db:-inveniordm}"
  [ -n "$id" ] || return
  if command -v timeout >/dev/null 2>&1; then
    out="$(timeout 10 docker exec "$id" psql -U "$user" -d "$db" -tAc \
      "select 'sql_ok=' || current_user || '@' || current_database();" 2>&1)"
    rc=$?
  else
    out="$(docker exec "$id" psql -U "$user" -d "$db" -tAc \
      "select 'sql_ok=' || current_user || '@' || current_database();" 2>&1)"
    rc=$?
  fi
  printf '%s\n' "$out" | mask
  echo "psql exit=$rc"
}

test_web_to_db() {
  local id out rc
  id="$(cid web)"
  [ -n "$id" ] || { echo "web: contenedor no encontrado"; return; }
  if command -v timeout >/dev/null 2>&1; then
    out="$(timeout 10 docker exec "$id" python -c \
      "import socket; socket.create_connection(('db', 5432), 3); print('web->db OK')" 2>&1)"
    rc=$?
  else
    out="$(docker exec "$id" python -c \
      "import socket; socket.create_connection(('db', 5432), 3); print('web->db OK')" 2>&1)"
    rc=$?
  fi
  printf '%s\n' "$out" | mask
  echo "web->db exit=$rc"
}

test_http() {
  local url code
  url="$(env_get INVENIO_SITE_UI_URL)"
  [ -n "$url" ] || { echo "INVENIO_SITE_UI_URL no definido"; return; }
  code="$(curl -k -sS -o /dev/null -w '%{http_code}' --max-time 20 "$url/" 2>/dev/null || true)"
  echo "$url -> HTTP ${code:-sin respuesta}"
}

main() {
  section "INFORMACIÓN GENERAL"
  echo "fecha: $(date -Is 2>/dev/null || date)"
  echo "host: $(hostname 2>/dev/null || echo '?')"
  uname -a 2>/dev/null || true
  echo "modo: $MODE"
  echo "directorio: $ROOT_DIR"
  echo "env: $ENV_FILE"
  echo "git: $(git log -1 --oneline 2>/dev/null || echo 'no disponible')"
  echo
  echo "docker: $(docker version --format 'cliente={{.Client.Version}} servidor={{.Server.Version}}' 2>/dev/null || echo 'no disponible')"
  echo "compose: $(docker compose version 2>/dev/null || echo 'no disponible')"
  echo
  echo "--- disco ---"
  df -h / 2>/dev/null || true
  echo
  echo "--- memoria ---"
  free -h 2>/dev/null || true
  echo
  echo "--- swap ---"
  swapon --show 2>/dev/null || true

  section "CONTENEDORES"
  dc ps -a 2>&1 || true

  section "ESTADO / HEALTH"
  for svc in db web search worker cache proxy; do
    inspect_one "$svc"
  done

  section "CONFIGURACIÓN (secretos ocultos)"
  if [ -f "$ENV_FILE" ]; then
    grep -E '^[[:space:]]*(INVENIO_SITE_UI_URL|INVENIO_SITE_API_URL|INVENIO_TRUSTED_HOSTS|POSTGRES_HOST|POSTGRES_DB|POSTGRES_USER|POSTGRES_PASSWORD|INVENIO_ADMIN_EMAIL|OPENSEARCH_JAVA_OPTS|GUNICORN_WORKERS|CELERY_CONCURRENCY|BOOTSTRAP_MEMORY_LOCK)=' "$ENV_FILE" 2>/dev/null | mask || true
  else
    echo "No existe $ENV_FILE"
  fi
  echo
  echo "--- compose config (db, secretos ocultos) ---"
  dc config 2>/dev/null | sed -n '/^  db:/,/^  [a-z]/p' | mask || true

  section "POSTGRESQL: pg_isready"
  test_pg_isready

  section "POSTGRESQL: consulta real"
  test_sql

  section "WEB -> DB (TCP 5432)"
  test_web_to_db

  section "HTTP PÚBLICO"
  test_http

  section "PUERTOS ESCUCHANDO"
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | grep -E ':(80|443|5000|5432|9200)\b' || echo "sin puertos relevantes"
  else
    echo "ss no disponible"
  fi

  section "VOLÚMENES"
  docker volume ls 2>/dev/null | grep -E 'db-data|instance-data|search-data' || true

  section "LOGS: db"
  dc logs --tail=80 db 2>&1 | mask || true

  section "LOGS: web"
  dc logs --tail=100 web 2>&1 | mask || true

  section "LOGS: search"
  dc logs --tail=60 search 2>&1 | mask || true

  section "LOGS: worker"
  dc logs --tail=60 worker 2>&1 | mask || true

  section "RESUMEN"
  inspect_one db
  inspect_one web
  inspect_one search
  test_pg_isready
  test_web_to_db
  test_http
}

REPORT="$ROOT_DIR/diagnostico-$(date +%Y%m%d-%H%M%S).txt"
main 2>&1 | tee "$REPORT"
printf '\nReporte guardado en: %s\n' "$REPORT" >&2
