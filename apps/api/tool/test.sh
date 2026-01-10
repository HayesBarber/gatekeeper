#!/usr/bin/env bash
set -euo pipefail

MODE=${1:-all}

cleanup() {
  echo "cleaning up"
  echo "deleting redis key devices:${DEVICE_ID}"
  redis-cli DEL "devices:${DEVICE_ID}"
  
  echo "restoring original gatekeeper.json"
  if [ -f gatekeeper.json.bak ]; then
    mv gatekeeper.json.bak gatekeeper.json
  fi
  
  kill "$SERVER_PID"
  kill "$ECHO_PID"
  kill "$GITHUB_WEBHOOK_PID"
}

setup() {
  echo "setting up"

  if [[ "$(redis-cli ping 2>/dev/null)" != "PONG" ]]; then
    echo "No response from redis"
    exit 1
  fi

  DEVICE_ID="it-$(openssl rand -hex 6)"
  export DEVICE_ID

  GITHUB_WEBHOOK_SECRET="$(openssl rand -hex 16)"
  export GITHUB_WEBHOOK_SECRET

  KEY_PAIR_JSON=$(dart run tool/keygen.dart)
  export KEY_PAIR_JSON

  PUBLIC_KEY=$(echo "$KEY_PAIR_JSON" | jq -r '.publicKey')

  echo "creating redis key devices:${DEVICE_ID}"
  redis-cli SET "devices:${DEVICE_ID}" "$PUBLIC_KEY"

  echo "substituting GitHub webhook secret and disabling logging in config"
  sed -i.bak -e "s/{{GITHUB_WEBHOOK_SECRET}}/$GITHUB_WEBHOOK_SECRET/g" -e "s/\"enabled\": true/\"enabled\": false/g" gatekeeper.json

  echo "creating build"
  dart_frog build

  echo "starting server"
  dart build/bin/server.dart &
  SERVER_PID=$!
  echo "server PID: $SERVER_PID"

  echo "starting FastAPI echo server"
  uvicorn tool.echo_server:app --host 127.0.0.1 --port 3000 --log-level critical &
  ECHO_PID=$!
  echo "echo server PID: $ECHO_PID"

  echo "starting FastAPI github webhook server"
  uvicorn tool.echo_server:app --host 127.0.0.1 --port 6000 --log-level critical &
  GITHUB_WEBHOOK_PID=$!
  echo "github webhook server PID: $GITHUB_WEBHOOK_PID"

  API_BASE_URL="http://localhost:8080"
  export API_BASE_URL

  REDIS_HOST="127.0.0.1"
  export REDIS_HOST

  echo "waiting for server"
  until curl -sf http://127.0.0.1:8080/health >/dev/null; do
    sleep 0.2
  done

  echo "waiting for echo server"
  until curl -sf http://127.0.0.1:3000/ >/dev/null; do
    sleep 0.2
  done

  echo "waiting for github webhook server"
  until curl -sf http://127.0.0.1:6000/ >/dev/null; do
    sleep 0.2
  done

  trap cleanup EXIT
}

run_unit() {
  dart test test/unit
}

run_integration() {
  setup
  dart test test/integration --concurrency=1
}

run_all() {
  setup
  dart test --concurrency=1
}

case "$MODE" in
  unit|ut)
    run_unit
    ;;
  integration|it)
    run_integration
    ;;
  all)
    run_all
    ;;
  *)
    echo "usage: test.sh [unit|ut|integration|it|all]"
    exit 1
    ;;
esac
