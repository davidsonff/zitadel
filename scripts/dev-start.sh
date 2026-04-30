#!/usr/bin/env zsh
# Local Zitadel dev launcher.
# - Verifies Postgres is reachable
# - Ensures the `zitadel` database exists
# - Kills any stale zitadel process
# - Starts the binary in the background using tmp-local.yaml
# - Tails the log until the server is listening, then prints the demo URLs.
#
# Usage:  ./scripts/dev-start.sh           # start (build if missing)
#         ./scripts/dev-start.sh --rebuild # force rebuild of binary
#         ./scripts/dev-start.sh --stop    # stop the running server
#         ./scripts/dev-start.sh --logs    # tail the server log
#         ./scripts/dev-start.sh --status  # show pid + health

set -euo pipefail

REPO="${0:A:h:h}"
cd "$REPO"

CONFIG="tmp-local.yaml"
MASTERKEY="MasterkeyNeedsToHave32Characters"
LOG="/tmp/zitadel-run.log"
BIN="./zitadel"
PG_HOST="localhost"
PG_PORT="5432"
PG_ADMIN_USER="postgres"
PG_DB="zitadel"
EXTERNAL="http://localhost:8080"

# Bypass the corporate proxy for localhost (needed if Zscaler/PAC is active).
export NO_PROXY="localhost,127.0.0.1,::1,*.local"
export no_proxy="$NO_PROXY"

color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info()  { color "1;34" "▶ $*"; }
ok()    { color "1;32" "✔ $*"; }
warn()  { color "1;33" "! $*"; }
die()   { color "1;31" "✘ $*"; exit 1; }

cmd_stop() {
  if pgrep -f "zitadel start" >/dev/null; then
    info "Stopping zitadel..."
    pkill -f "zitadel start" || true
    sleep 1
    ok "Stopped."
  else
    warn "No running zitadel process."
  fi
}

cmd_logs() { tail -F "$LOG"; }

cmd_status() {
  if pgrep -af "zitadel start" >/dev/null; then
    pgrep -af "zitadel start"
    curl -fsS -o /dev/null -w "OIDC discovery: HTTP %{http_code}\n" \
      "$EXTERNAL/.well-known/openid-configuration" || true
  else
    warn "Not running."
  fi
}

ensure_postgres() {
  info "Checking Postgres at $PG_HOST:$PG_PORT..."
  if ! pg_isready -h "$PG_HOST" -p "$PG_PORT" >/dev/null 2>&1; then
    die "Postgres not reachable at $PG_HOST:$PG_PORT (start it: brew services start postgresql@18)"
  fi
  if ! psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d "$PG_DB" \
        -c "SELECT 1" >/dev/null 2>&1; then
    info "Creating database '$PG_DB'..."
    createdb -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" "$PG_DB"
  fi
  ok "Postgres ready."
}

ensure_binary() {
  if [[ "${1:-}" == "--rebuild" || ! -x "$BIN" ]]; then
    info "Building zitadel binary..."
    CGO_ENABLED=0 go build -o zitadel .
    ok "Built $(ls -lh $BIN | awk '{print $5}')."
  else
    ok "Using existing $BIN ($(ls -lh $BIN | awk '{print $5}'))."
  fi
}

start_server() {
  if pgrep -f "zitadel start" >/dev/null; then
    warn "zitadel already running (pid $(pgrep -f 'zitadel start')). Use --stop first."
    return 0
  fi
  info "Starting zitadel..."
  : > "$LOG"
  nohup "$BIN" start \
    --config "$CONFIG" \
    --masterkey "$MASTERKEY" \
    --tlsMode disabled \
    > "$LOG" 2>&1 &
  local pid=$!
  disown
  info "PID=$pid  log=$LOG"

  # Wait for "server is listening" or fatal.
  local i=0
  while (( i < 30 )); do
    if grep -q "server is listening" "$LOG" 2>/dev/null; then
      break
    fi
    if grep -qE "level=fatal" "$LOG" 2>/dev/null; then
      tail -30 "$LOG"
      die "Server failed to start. See $LOG"
    fi
    sleep 1
    (( i++ ))
  done
  curl -fsS -o /dev/null "$EXTERNAL/.well-known/openid-configuration" \
    || die "Server is not responding on $EXTERNAL"
  ok "Listening on $EXTERNAL"
}

print_demo() {
  cat <<EOF

$(color "1;36" "── Zitadel demo ──")
  Console : $EXTERNAL/ui/console
  Login   : $EXTERNAL/ui/login
  OIDC    : $EXTERNAL/.well-known/openid-configuration

  Admin login:
    user     : zitadel-admin@zitadel.localhost
    password : Password2!

  Demo flow:
    1. Open   $EXTERNAL/ui/console
    2. Sign in as the admin user above.
    3. Click  Users → New        to create a human user.
    4. Click  Projects → New     to scaffold an app/project.
    5. Click  Organization       to manage members & domains.

  Helpers:
    $0 --logs     # follow $LOG
    $0 --status   # pid + health probe
    $0 --stop     # stop the server
    $0 --rebuild  # rebuild the Go binary, then start

EOF
}

case "${1:-}" in
  --stop)    cmd_stop; exit 0 ;;
  --logs)    cmd_logs ;;
  --status)  cmd_status; exit 0 ;;
  --rebuild) ensure_postgres; ensure_binary --rebuild; start_server; print_demo ;;
  ""|--start) ensure_postgres; ensure_binary; start_server; print_demo ;;
  *) die "Unknown option: $1 (use --start|--stop|--logs|--status|--rebuild)" ;;
esac
