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

# Sin buffer: el progreso y el reporte se ven en vivo y en orden, aunque la
# salida pase por `tee` hacia un archivo.
if [ -z "${__DIAG_UNBUF:-}" ] && command -v stdbuf >/dev/null 2>&1; then
  __DIAG_UNBUF=1 exec stdbuf -oL -eL "$ROOT_DIR/$(basename "$0")" "$@"
fi

dc() { guard "${DC_TIMEOUT:-60}" "${COMPOSE[@]}" "$@"; }
dk() { guard "${DK_TIMEOUT:-30}" docker "$@"; }

# Ningún comando externo puede bloquear el diagnóstico: en algunos servidores
# `docker exec`/`docker compose exec` imprimen el resultado y no devuelven el
# control nunca. Con `timeout` el reporte sigue aunque eso pase.
guard() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout -k 5 "$secs" "$@" </dev/null
  else
    "$@" </dev/null
  fi
}

# Progreso en vivo: cada sección se anuncia antes de ejecutarse.
note() { printf '[%s] %s\n' "$(date +%H:%M:%S 2>/dev/null || echo '--:--:--')" "$*"; }
section() { note "sección: $*"; printf '\n===== %s =====\n' "$*"; }
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
  dk inspect -f '{{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} restarts={{.RestartCount}}' "$id" 2>/dev/null \
    || printf '%-7s inspect falló\n' "$svc"
}

env_get() {
  local key="$1"
  sed -n "s/^[[:space:]]*${key}=//p" "$ENV_FILE" 2>/dev/null | tail -1 \
    | sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/' \
    | tr -d '\r'
}

# Un .env con CRLF deja un "\r" invisible en cada valor: el rol de PostgreSQL
# se llama "postgres\r", la contraseña no coincide y las URLs fallan.
check_env_files() {
  local f cr
  for f in .env .env.prod .env.prod.save .env.example; do
    [ -f "$f" ] || continue
    cr="$(tr -cd '\r' < "$f" | wc -c | tr -d ' ')"
    if [ "${cr:-0}" -gt 0 ]; then
      printf '%s: TIENE %s CR (CRLF de Windows) -> los valores llevan \\r al final\n' "$f" "$cr"
      printf '      arreglo: sed -i '"'"'s/\\r$//'"'"' %s\n' "$f"
    else
      printf '%s: LF correcto\n' "$f"
    fi
  done
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
  note "pg_isready…"
  guard 30 docker exec "$id" pg_isready -U "$user" -d "$db" 2>&1
  echo "pg_isready exit=$?"
}

test_sql() {
  local id user db out rc
  id="$(cid db)"; [ -n "$id" ] || id="$(any_cid db)"
  user="$(env_get POSTGRES_USER)"; user="${user:-postgres}"
  db="$(env_get POSTGRES_DB)"; db="${db:-inveniordm}"
  [ -n "$id" ] || return
  note "consulta SQL…"
  out="$(guard 30 docker exec "$id" psql -U "$user" -d "$db" -tAc \
    "select 'sql_ok=' || current_user || '@' || current_database();" 2>&1)"
  rc=$?
  printf '%s\n' "$out" | mask
  echo "psql exit=$rc"
}

test_web_to_db() {
  local id out rc
  id="$(cid web)"
  [ -n "$id" ] || { echo "web: contenedor no encontrado"; return; }
  note "web -> db…"
  out="$(guard 30 docker exec "$id" python -c \
    "import socket; socket.create_connection(('db', 5432), 3); print('web->db OK')" 2>&1)"
  rc=$?
  printf '%s\n' "$out" | mask
  echo "web->db exit=$rc"
}

test_http() {
  local url code
  url="$(env_get INVENIO_SITE_UI_URL)"
  [ -n "$url" ] || { echo "INVENIO_SITE_UI_URL no definido"; return; }
  note "HTTP $url…"
  code="$(guard 25 curl -k -sS -o /dev/null -w '%{http_code}' --max-time 20 "$url/" 2>/dev/null || true)"
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
  echo "docker: $(guard 20 docker version --format 'cliente={{.Client.Version}} servidor={{.Server.Version}}' 2>/dev/null || echo 'no disponible')"
  echo "compose: $(guard 20 docker compose version 2>/dev/null || echo 'no disponible')"
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

  section "ARCHIVOS DE ENTORNO (finales de línea)"
  check_env_files

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
  guard 20 docker volume ls 2>/dev/null | grep -E 'db-data|instance-data|search-data' || true

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
note "inicio del diagnóstico ($MODE) — cada comando tiene límite de tiempo"
main 2>&1 | tee "$REPORT"
note "reporte guardado en: $REPORT"
printf '\nReporte guardado en: %s\n' "$REPORT" >&2
