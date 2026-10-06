#!/usr/bin/env bash
# JEV serving entrypoint: System 1 (POST /v1/decide) + System 2 (OpenAI API) on one vLLM engine.
#
# Usage: <model-path> [vllm serve flags...]
#   The model flag list is identical for both paths, so compose files pass one command.
#
# Resolution order for serve_decide.py (the model-repo server that adds POST /v1/decide):
#   1. $JEV_DECIDE_SCRIPT                     (explicit, e.g. JEV-9B vision mode)
#   2. <model-path>/serve_decide.py           (autotrust/JEV-27B-VL layout)
#   3. <model-path>/vl/serve_decide.py        (autotrust/JEV-9B vision layout)
#   4. not found -> plain `vllm serve`         (System 1 stays available client-side)
set -euo pipefail

# Compose `${VAR:+--flag}` yields an empty argv entry when VAR is unset; drop it.
if [[ $# -gt 0 ]]; then
  _args=()
  for _a in "$@"; do
    [[ -n "${_a}" ]] && _args+=("${_a}")
  done
  set -- ${_args[@]+"${_args[@]}"}
fi

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec vllm serve --help
fi

MODEL="$1"
shift

script="${JEV_DECIDE_SCRIPT:-}"
if [[ ! -f "${script}" ]]; then
  script=""
  for candidate in "${MODEL}/serve_decide.py" "${MODEL}/vl/serve_decide.py"; do
    if [[ -f "${candidate}" ]]; then
      script="${candidate}"
      break
    fi
  done
fi

if [[ -n "${script}" ]]; then
  echo "[jev] System 1 endpoint enabled: ${script}" >&2
  exec python3 "${script}" --model "${MODEL}" "$@"
fi

echo "[jev] serve_decide.py not found next to '${MODEL}'; falling back to plain 'vllm serve'" >&2
exec vllm serve "${MODEL}" "$@"
