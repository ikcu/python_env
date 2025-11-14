#!/usr/bin/env bash
set -euo pipefail

FILE="Makefile"
MODE="interactive"
TARGET=""

usage() {
  echo "用法: make.sh [--file 路径] [--list] [--run 目标] [--help]"
  echo "-f|--file 路径    指定 Makefile 路径, 默认为 Makefile"
  echo "-l|--list         列出所有可用目标"
  echo "-r|--run 目标     直接执行指定目标"
  echo "-h|--help         显示帮助"
}

list_targets() {
  awk -F":" '/^[a-zA-Z0-9_.-]+:[^=]/ {print $1}' "$FILE" | sort -u
}

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--file)
      FILE="$2"
      shift 2
      ;;
    -l|--list)
      MODE="list"
      shift 1
      ;;
    -r|--run)
      TARGET="$2"
      MODE="run"
      shift 2
      ;;
    -h|--help)
      MODE="help"
      shift 1
      ;;
    *)
      break
      ;;
  esac
done

if [ "$MODE" = "help" ]; then
  usage
  exit 0
fi

if [ ! -f "$FILE" ]; then
  echo "未找到 Makefile: $FILE"
  exit 1
fi

if [ "$MODE" = "list" ]; then
  list_targets
  exit 0
fi

if [ "$MODE" = "run" ]; then
  if [ -z "$TARGET" ]; then
    echo "缺少目标"
    exit 1
  fi
  exec make -f "$FILE" "$TARGET"
fi

mapfile -t TARGETS < <(list_targets)

if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "未检测到任何目标"
  exit 1
fi

PS3="请选择要执行的目标编号: "
select t in "${TARGETS[@]}"; do
  if [ -n "${t:-}" ]; then
    exec make -f "$FILE" "$t"
  else
    echo "无效选择"
  fi
done