#!/usr/bin/env bash
set -euo pipefail

MODE=${1:-all}

cleanup() {
  echo "cleaning up"
  echo "deleting redis key users:${CLIENT_ID}"
  redis-cli DEL "users:${CLIENT_ID}"
}

setup() {
  echo "setting up"

  if [[ "$(redis-cli ping 2>/dev/null)" != "PONG" ]]; then
    echo "No response from redis"
    exit 1
  fi

  CLIENT_ID="it-$(openssl rand -hex 6)"
  export CLIENT_ID
  echo "creating redis key users:${CLIENT_ID}"
  redis-cli SET "users:${CLIENT_ID}" "todo"

  echo "creating build"
  dart_frog build

  echo "starting server"
  dart build/bin/server.dart &
  SERVER_PID=$!

  echo "waiting for server"
  until curl -sf http://127.0.0.1:8080/health >/dev/null; do
    sleep 0.2
  done

  trap cleanup EXIT
}

run_unit() {
  dart test test/unit
}

run_integration() {
  setup
  dart test test/integration
}

run_all() {
  setup
  dart test
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
