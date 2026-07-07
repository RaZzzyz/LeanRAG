#!/usr/bin/env bash
set -euo pipefail

# Download source files for the four benchmark datasets into datasets/<name>/.
# Usage:
#   bash dataset.sh               # skip files that already exist
#   FORCE=1 bash dataset.sh       # overwrite existing files
#   MAX_JOBS=2 bash dataset.sh    # limit parallel downloads

BASE_URL="https://huggingface.co/datasets/TommyChien/UltraDomain/resolve/main"
DATASET_ROOT="${DATASET_ROOT:-datasets}"
FORCE="${FORCE:-0}"
MAX_JOBS="${MAX_JOBS:-4}"

DATASETS=(
  "agriculture|${BASE_URL}/agriculture.jsonl|agriculture.jsonl"
  "cs|${BASE_URL}/cs.jsonl|cs.jsonl"
  "legal|${BASE_URL}/legal.jsonl|legal.jsonl"
  "mix|${BASE_URL}/mix.jsonl|mix.jsonl"
)

download_file() {
  local url="$1"
  local output="$2"
  local tmp="${output}.tmp"

  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --retry-delay 2 -o "$tmp" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$tmp" "$url"
  else
    echo "Error: curl or wget is required." >&2
    return 1
  fi

  mv "$tmp" "$output"
}

mkdir -p "$DATASET_ROOT"

active_jobs=0
pids=()

for item in "${DATASETS[@]}"; do
  IFS="|" read -r name url filename <<< "$item"
  target_dir="${DATASET_ROOT}/${name}"
  target_file="${target_dir}/${filename}"

  mkdir -p "$target_dir"

  if [[ -f "$target_file" && "$FORCE" != "1" ]]; then
    echo "Skip existing: $target_file"
    continue
  fi

  echo "Downloading ${name}: ${url}"
  (
    download_file "$url" "$target_file"
    echo "Saved to: $target_file"
  ) &
  pids+=("$!")
  active_jobs=$((active_jobs + 1))

  if (( active_jobs >= MAX_JOBS )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
    active_jobs=$((active_jobs - 1))
  fi
done

for pid in "${pids[@]}"; do
  wait "$pid"
done

echo "Done."
