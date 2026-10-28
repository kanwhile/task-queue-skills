#!/usr/bin/env bash
# ติดตั้งสกิลใน repo นี้ตามแบบแผนของเครื่อง: ไฟล์จริงอยู่ใน repo → ~/.agents/skills/<ชื่อ> ชี้มาที่นี่ →
# ~/.claude/skills/<ชื่อ> และทุก ~/.claude-*/skills/<ชื่อ> ชี้ไป ../../.agents/skills/<ชื่อ>
# รันซ้ำได้ · --uninstall ถอด symlink ที่สคริปต์นี้สร้าง
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
lib="$HOME/.agents/skills"
mode="${1:-install}"

targets=("$HOME/.claude/skills")
for d in "$HOME"/.claude-*/; do [ -d "$d" ] && targets+=("${d%/}/skills"); done

link() { # link <path> <target>
  local path="$1" target="$2"
  if [ -L "$path" ]; then
    [ "$(readlink "$path")" = "$target" ] && { echo "  = $path"; return; }
    ln -sfn "$target" "$path"; echo "  ~ $path -> $target"
  elif [ -e "$path" ]; then
    echo "  ! $path มีอยู่แล้วและไม่ใช่ symlink ข้าม (ลบเองถ้าต้องการให้ชี้มาที่ repo นี้)"
  else
    ln -s "$target" "$path"; echo "  + $path -> $target"
  fi
}

unlink_if_ours() { # unlink_if_ours <path> <target>
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ] && { rm "$1"; echo "  - $1"; } || true
}

mkdir -p "$lib"
for s in "$here"/skills/*/; do
  name="$(basename "$s")"
  case "$name" in _*) continue ;; esac
  echo "$name"
  if [ "$mode" = "--uninstall" ]; then
    for t in "${targets[@]}"; do unlink_if_ours "$t/$name" "../../.agents/skills/$name"; done
    unlink_if_ours "$lib/$name" "${s%/}"
    continue
  fi
  link "$lib/$name" "${s%/}"
  for t in "${targets[@]}"; do mkdir -p "$t"; link "$t/$name" "../../.agents/skills/$name"; done
done
