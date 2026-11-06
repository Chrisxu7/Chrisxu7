#!/usr/bin/env bash
# Levanta la Oficina Virtual DEMO con Hermes3D:
#   1. Descarga Hermes3D (versión fijada) en .hermes3d/
#   2. Instala dependencias (solo la primera vez)
#   3. Arranca el gateway demo con el equipo de gateway/equipo.json
#   4. Compila Hermes3D (solo la primera vez) y arranca Studio en
#      http://localhost:3000 apuntando a ese gateway
#
# Uso: ./scripts/oficina-demo.sh [--dev] [--rebuild]
#   --dev      modo desarrollo de Next.js (recarga en caliente, más lento)
#   --rebuild  fuerza recompilar Hermes3D
set -euo pipefail

MODE="prod"
REBUILD=0
for arg in "$@"; do
  case "$arg" in
    --dev) MODE="dev" ;;
    --rebuild) REBUILD=1 ;;
    -h|--help) sed -n 2,13p "$0"; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES3D_REPO="${HERMES3D_REPO:-https://github.com/iamlukethedev/Hermes3D.git}"
# Commit de Hermes3D probado con esta demo. Cámbialo para actualizar.
HERMES3D_REF="${HERMES3D_REF:-beb76292747b816ef317aa6f9a3992e0014f81d9}"
HERMES3D_DIR="${HERMES3D_DIR:-$ROOT/.hermes3d}"
STUDIO_PORT="${PORT:-3000}"
GATEWAY_PORT="${DEMO_ADAPTER_PORT:-18789}"

log() { printf '\033[1;36m[oficina]\033[0m %s\n' "$*"; }

command -v node >/dev/null || { echo "Necesitas Node.js 20+ (recomendado 22)." >&2; exit 1; }
command -v git >/dev/null || { echo "Necesitas git." >&2; exit 1; }
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "Node.js $NODE_MAJOR es demasiado antiguo: Hermes3D necesita Node 20+." >&2
  exit 1
fi

if [ ! -d "$HERMES3D_DIR/.git" ]; then
  log "Descargando Hermes3D en $HERMES3D_DIR ..."
  git init -q "$HERMES3D_DIR"
  git -C "$HERMES3D_DIR" remote add origin "$HERMES3D_REPO"
fi
if [ "$(git -C "$HERMES3D_DIR" rev-parse HEAD 2>/dev/null || true)" != "$HERMES3D_REF" ]; then
  log "Fijando Hermes3D en $HERMES3D_REF ..."
  git -C "$HERMES3D_DIR" fetch -q --depth 1 origin "$HERMES3D_REF"
  git -C "$HERMES3D_DIR" checkout -q --detach FETCH_HEAD
  rm -f "$HERMES3D_DIR/.oficina-deps-ok" "$HERMES3D_DIR/.oficina-build-ok"
fi

if [ ! -f "$HERMES3D_DIR/.oficina-deps-ok" ]; then
  log "Instalando dependencias de Hermes3D (tarda unos minutos la primera vez) ..."
  (cd "$HERMES3D_DIR" && npm ci --ignore-scripts --no-audit --no-fund)
  touch "$HERMES3D_DIR/.oficina-deps-ok"
fi

# El gateway usa el paquete "ws" que ya instala Hermes3D.
export NODE_PATH="$HERMES3D_DIR/node_modules${NODE_PATH:+:$NODE_PATH}"
export DEMO_ADAPTER_PORT="$GATEWAY_PORT"
export OFICINA_EQUIPO="${OFICINA_EQUIPO:-$ROOT/gateway/equipo.json}"

PIDS=()
cleanup() {
  log "Cerrando la oficina ..."
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

log "Arrancando el gateway demo en ws://localhost:$GATEWAY_PORT ..."
node "$ROOT/gateway/oficina-demo-gateway.js" &
PIDS+=($!)

# Studio se conecta automáticamente a este gateway en modo "demo".
export HERMES3D_GATEWAY_URL="ws://localhost:$GATEWAY_PORT"
export HERMES3D_GATEWAY_ADAPTER_TYPE="demo"
export HERMES3D_GATEWAY_TOKEN="${HERMES3D_GATEWAY_TOKEN:-demo}"
export PORT="$STUDIO_PORT"
export HOST="${HOST:-127.0.0.1}"
export NEXT_TELEMETRY_DISABLED=1
# En producción Studio solo se conecta a gateways de hosts permitidos.
export UPSTREAM_ALLOWLIST="${UPSTREAM_ALLOWLIST:-localhost,127.0.0.1}"

if [ "$MODE" = "prod" ]; then
  if [ "$REBUILD" = 1 ] || [ ! -f "$HERMES3D_DIR/.oficina-build-ok" ]; then
    log "Compilando Hermes3D (solo la primera vez, unos minutos) ..."
    (cd "$HERMES3D_DIR" && NEXT_PUBLIC_GATEWAY_URL="$HERMES3D_GATEWAY_URL" npm run build)
    touch "$HERMES3D_DIR/.oficina-build-ok"
  fi
  STUDIO_ARGS=()
  export NODE_ENV=production
else
  STUDIO_ARGS=(--dev)
fi

log "Arrancando Hermes3D Studio ($MODE) en http://localhost:$STUDIO_PORT ..."
log "Abre http://localhost:$STUDIO_PORT/office  ·  Ctrl+C para salir."
(cd "$HERMES3D_DIR" && node server/index.js "${STUDIO_ARGS[@]}") &
PIDS+=($!)

wait -n "${PIDS[@]}"
