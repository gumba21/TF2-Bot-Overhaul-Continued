#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTING="$ROOT/tf/addons/sourcemod/scripting"
SOURCE_DIR="$SCRIPTING/bot overhaul"
INCLUDE_DIR="$SCRIPTING/include"
ACTIVE_DIR="$ROOT/tf/addons/sourcemod/plugins/bot overhaul"
DISABLED_DIR="$ROOT/tf/addons/sourcemod/plugins/disabled"
CACHE_DIR="${TF2BOT_CACHE_DIR:-$ROOT/.cache/sourcemod}"
SM_VERSION="${SOURCEMOD_VERSION:-1.12}"

mkdir -p "$ACTIVE_DIR" "$DISABLED_DIR" "$CACHE_DIR"

find_spcomp() {
    if [[ -n "${SPCOMP:-}" && -x "${SPCOMP}" ]]; then
        printf '%s\n' "$SPCOMP"
        return
    fi
    if command -v spcomp >/dev/null 2>&1; then
        command -v spcomp
        return
    fi
    if [[ -x "$SCRIPTING/spcomp" ]]; then
        printf '%s\n' "$SCRIPTING/spcomp"
        return
    fi
    if [[ -x "$CACHE_DIR/addons/sourcemod/scripting/spcomp" ]]; then
        printf '%s\n' "$CACHE_DIR/addons/sourcemod/scripting/spcomp"
        return
    fi

    command -v curl >/dev/null 2>&1 || { echo "curl is required to download SourceMod" >&2; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo "tar is required to unpack SourceMod" >&2; exit 1; }

    latest="$(curl -fsSL "https://www.sourcemod.net/smdrop/${SM_VERSION}/sourcemod-latest-linux")"
    archive="$CACHE_DIR/sourcemod.tar.gz"
    curl -fsSL "https://www.sourcemod.net/smdrop/${SM_VERSION}/${latest}" -o "$archive"
    tar -xzf "$archive" -C "$CACHE_DIR"
    chmod +x "$CACHE_DIR/addons/sourcemod/scripting/spcomp"
    printf '%s\n' "$CACHE_DIR/addons/sourcemod/scripting/spcomp"
}

SPCOMP_BIN="$(find_spcomp)"
SM_INCLUDE="$(cd "$(dirname "$SPCOMP_BIN")/include" && pwd)"

compile_one() {
    local state="$1" source_name="$2" output_name="$3"
    local source="$SOURCE_DIR/${source_name}.sp"
    local output_dir="$ACTIVE_DIR"
    [[ "$state" == "disabled" ]] && output_dir="$DISABLED_DIR"

    [[ -f "$source" ]] || { echo "Missing source: $source" >&2; exit 1; }
    "$SPCOMP_BIN" \
        -i"$SM_INCLUDE" \
        -i"$INCLUDE_DIR" \
        -o"$output_dir/${output_name}.smx" \
        "$source"
}

while IFS='|' read -r state source_name output_name; do
    [[ -z "$state" || "$state" == \#* ]] && continue
    compile_one "$state" "$source_name" "$output_name"
done < "$ROOT/tools/plugin-layout.txt"

echo "Compiled SourcePawn plugins into tf/addons/sourcemod/plugins."
