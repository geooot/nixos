#!/usr/bin/env bash
# Restore a minimized window (parked on special:minimized by the
# MinimizeWindow() function in hyprland.lua) to its origin workspace.
# The origin is read from the window's "minimized-from-<id>" tag.
# Usage: hypr-restore <address|last>
set -uo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/layouts.json"

clients=$(hyprctl clients -j 2>/dev/null) || exit 1

addr="${1:-last}"
if [ "$addr" != "last" ]; then
  # Quickshell reports addresses without the 0x prefix; hyprctl needs it.
  addr="0x${addr#0x}"
fi
if [ "$addr" = "last" ]; then
  addr=$(printf '%s' "$clients" | jq -r '[.[] | select(.workspace.name == "special:minimized")] | sort_by(.focusHistoryID) | last | .address // empty')
  [ -n "$addr" ] || exit 0
fi

origin_tag=$(printf '%s' "$clients" | jq -r --arg a "$addr" '.[] | select(.address == $a) | [.tags[]? | select(startswith("minimized-from-")) | ltrimstr("minimized-from-")] | first // empty')
fs_tag=$(printf '%s' "$clients" | jq -r --arg a "$addr" '.[] | select(.address == $a) | [.tags[]? | select(startswith("minimized-fs-")) | ltrimstr("minimized-fs-")] | first // empty')
origin="$origin_tag"
if [ -z "$origin" ]; then
  origin=$(hyprctl activeworkspace -j | jq -r '.id')
fi

mode="dwindle"
if [ -f "$state_file" ]; then
  mode=$(jq -r --arg ws "$origin" '.[$ws] // "dwindle"' "$state_file" 2>/dev/null || echo dwindle)
fi

batch="dispatch hl.dsp.window.move({ window = \"address:$addr\", workspace = \"$origin\", follow = true })"
if [ "$mode" = "floating" ]; then
  batch="$batch;dispatch hl.dsp.window.float({ window = \"address:$addr\", action = \"enable\" })"
else
  batch="$batch;dispatch hl.dsp.window.float({ window = \"address:$addr\", action = \"disable\" })"
fi
if [ -n "$fs_tag" ]; then
  if [ "$fs_tag" = "2" ]; then
    fs_mode="fullscreen"
  else
    fs_mode="maximized"
  fi
  batch="$batch;dispatch hl.dsp.window.fullscreen({ window = \"address:$addr\", mode = \"$fs_mode\", action = \"set\" })"
  batch="$batch;dispatch hl.dsp.window.tag({ window = \"address:$addr\", tag = \"-minimized-fs-$fs_tag\" })"
fi
batch="$batch;dispatch hl.dsp.focus({ window = \"address:$addr\" })"
if [ -n "$origin_tag" ]; then
  batch="$batch;dispatch hl.dsp.window.tag({ window = \"address:$addr\", tag = \"-minimized-from-$origin_tag\" })"
fi

hyprctl --batch "$batch" >/dev/null
