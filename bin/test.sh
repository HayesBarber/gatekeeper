#!/usr/bin/env bash
set -euo pipefail

MODE=${1:-all}

cleanup() {
  echo "cleaning up"
}

setup() {
  echo "setting up"
  if [[ "$(redis-cli ping 2>/dev/null)" != "PONG" ]]; then
    echo "No response from redis"
    exit 1
  fi
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
