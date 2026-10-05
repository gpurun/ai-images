#!/usr/bin/env bash
# Ollama engine entrypoint — performance-tuned serving with long-context defaults
set -euo pipefail

MODE="${1:-serve}"
shift || true

MODEL="${OLLAMA_MODEL:-}"
PULL="${OLLAMA_PULL:-}"
GGUF_PATH="${GGUF_PATH:-}"
AUTO_DOWNLOAD="${AUTO_DOWNLOAD_WEIGHTS:-0}"

SERVER_PID=""

log() { echo "[ollama] $*"; }

model_exists() {
  [[ -n "${MODEL}" ]] || return 1
  ollama show "${MODEL}" >/dev/null 2>&1
}

start_server_bg() {
  log "starting ollama serve (host=${OLLAMA_HOST:-0.0.0.0:11434} context=${OLLAMA_CONTEXT_LENGTH:-4096} kv_cache=${OLLAMA_KV_CACHE_TYPE:-f16} flash_attn=${OLLAMA_FLASH_ATTENTION:-0} parallel=${OLLAMA_NUM_PARALLEL:-1} models=${OLLAMA_MODELS:-/root/.ollama/models})"
  ollama serve &
  SERVER_PID=$!

  local tries=0
  until ollama list >/dev/null 2>&1; do
    if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
      echo "ERROR: 'ollama serve' exited unexpectedly" >&2
      exit 1
    fi
    tries=$((tries + 1))
    if (( tries > 120 )); then
      echo "ERROR: ollama server did not become ready within 120s" >&2
      exit 1
    fi
    sleep 1
  done
  log "server ready"
}

stop_server() {
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
  SERVER_PID=""
}

find_gguf() {
  local target="$1"
  if [[ -f "${target}" && "${target}" == *.gguf ]]; then
    printf '%s\n' "${target}"
    return 0
  fi
  if [[ -d "${target}" ]]; then
    local gguf
    while IFS= read -r gguf; do
      [[ -n "${gguf}" ]] || continue
      printf '%s\n' "${gguf}"
      return 0
    done < <(find "${target}" -type f -name '*.gguf' | sort | head -n 1)
  fi
  return 1
}

create_from_source() {
  local source="$1"
  local modelfile
  modelfile="$(mktemp)"
  printf 'FROM %s\n' "${source}" > "${modelfile}"
  ollama create "${MODEL}" -f "${modelfile}" >/dev/null
  rm -f "${modelfile}"
}

# ensure_model [force]
# 1) local GGUF (GGUF_PATH) takes precedence, 2) OLLAMA_PULL registry/HF pull
ensure_model() {
  local force="${1:-}"

  if [[ -z "${MODEL}" ]]; then
    log "OLLAMA_MODEL not set; skipping model bootstrap"
    return 0
  fi
  if model_exists; then
    log "model '${MODEL}' already available"
    return 0
  fi

  if [[ -n "${GGUF_PATH}" && -e "${GGUF_PATH}" ]]; then
    local gguf=""
    if gguf="$(find_gguf "${GGUF_PATH}")"; then
      log "creating '${MODEL}' from local GGUF: ${gguf}"
      if create_from_source "${gguf}"; then
        log "model '${MODEL}' created from GGUF"
        return 0
      fi
      echo "ERROR: failed to create '${MODEL}' from ${gguf}" >&2
      return 1
    fi
    log "GGUF_PATH=${GGUF_PATH} has no .gguf file; falling through"
  elif [[ -n "${GGUF_PATH}" ]]; then
    log "GGUF_PATH=${GGUF_PATH} not found; falling through"
  fi

  if [[ "${force}" != "force" && "${AUTO_DOWNLOAD}" != "1" && "${AUTO_DOWNLOAD}" != "true" ]]; then
    log "model '${MODEL}' not present and AUTO_DOWNLOAD_WEIGHTS!=1; skipping download"
    return 0
  fi

  if [[ -z "${PULL}" ]]; then
    log "no source for '${MODEL}': mount a GGUF via GGUF_PATH, or set OLLAMA_PULL=<registry|huggingface id>"
    return 1
  fi

  log "pulling ${PULL}"
  ollama pull "${PULL}"

  if [[ "${PULL}" != "${MODEL}" ]]; then
    log "creating alias '${MODEL}' -> ${PULL}"
    create_from_source "${PULL}"
  fi
  log "model '${MODEL}' ready"
}

case "${MODE}" in
  serve|api)
    start_server_bg
    if ! ensure_model; then
      echo "WARNING: model bootstrap failed; server continues without '${MODEL}'" >&2
    fi
    trap 'log "shutting down"; stop_server; exit 0' INT TERM
    set +e
    wait "${SERVER_PID}"
    rc=$?
    set -e
    stop_server
    exit "${rc}"
    ;;
  download|pull)
    start_server_bg
    ensure_model force
    stop_server
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
