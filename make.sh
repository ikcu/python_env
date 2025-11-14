#!/usr/bin/env bash
# 指定使用 bash 解释器运行脚本（通过 env 查找）
set -euo pipefail # 开启严格模式：遇错退出(-e)、未定义变量报错(-u)、管道失败传播(-o pipefail)

FILE="Makefile" # 默认使用的 Makefile 路径
MODE="interactive" # 默认运行模式为交互式
TARGET="" # 预留的 make 目标变量

usage() { # 定义 usage 函数：打印命令行用法
  echo "用法: make.sh [--file 路径] [--list] [--run 目标] [--help]" # 打印主用法说明
  echo "--file 路径    指定 Makefile 路径, 默认为 Makefile" # 解释 --file 选项
  echo "--list         列出所有可用目标" # 解释 --list 选项
  echo "--run 目标     直接执行指定目标" # 解释 --run 选项
  echo "--help         显示帮助" # 解释 --help 选项
} # 结束 usage 函数

list_targets() { # 定义 list_targets 函数：从 Makefile 中提取目标列表
  awk -F":" '/^[a-zA-Z0-9_.-]+:[^=]/ {print $1}' "$FILE" | sort -u # awk 以 ":" 为分隔，匹配合法目标行（忽略赋值），输出目标并去重排序
} # 结束 list_targets 函数

while [ $# -gt 0 ]; do # 参数解析循环：逐个处理命令行参数
  case "$1" in # 根据当前参数值分支处理
    --file) # 处理 --file 选项
      FILE="$2" # 读取下一个参数作为 Makefile 路径
      shift 2 # 前移两个参数指针
      ;; # 结束该分支
    --list) # 处理 --list 选项
      MODE="list" # 设置模式为列出目标
      shift 1 # 前移一个参数指针
      ;; # 结束该分支
    --run) # 处理 --run 选项
      TARGET="$2" # 读取下一个参数作为要执行的目标
      MODE="run" # 设置模式为直接运行目标
      shift 2 # 前移两个参数指针
      ;; # 结束该分支
    --help) # 处理 --help 选项
      MODE="help" # 设置模式为帮助
      shift 1 # 前移一个参数指针
      ;; # 结束该分支
    *) # 遇到未知参数或位置参数，停止解析
      break # 跳出参数解析循环
      ;; # 默认分支结束
  esac # 结束 case 语句
done # 完成参数解析

if [ "$MODE" = "help" ]; then # 若为帮助模式，打印帮助后退出
  usage # 调用 usage 函数
  exit 0 # 正常退出
fi # 结束 if

if [ ! -f "$FILE" ]; then # 校验指定的 Makefile 是否存在
  echo "未找到 Makefile: $FILE" # 若不存在，提示错误
  exit 1 # 非零退出
fi # 结束 if

if [ "$MODE" = "list" ]; then # 若为列出模式，打印所有目标并退出
  list_targets # 调用 list_targets 输出目标
  exit 0 # 正常退出
fi # 结束 if

if [ "$MODE" = "run" ]; then # 若为运行模式，执行指定目标
  if [ -z "$TARGET" ]; then # 未提供目标时提示错误
    echo "缺少目标" # 打印缺少目标信息
    exit 1 # 非零退出
  fi # 结束内部 if
  exec make -f "$FILE" "$TARGET" # 使用 exec 直接运行 make 指定目标（替换当前进程）
fi # 结束外层 if

mapfile -t TARGETS < <(list_targets) # 交互模式：读取目标列表到数组 TARGETS（-t 去掉换行）

if [ ${#TARGETS[@]} -eq 0 ]; then # 若没有任何目标则报错退出
  echo "未检测到任何目标" # 打印提示信息
  exit 1 # 非零退出
fi # 结束 if

PS3="请选择要执行的目标编号: " # 设置 select 提示字符串 PS3
select t in "${TARGETS[@]}"; do # 使用 select 提供菜单选择目标
  if [ -n "${t:-}" ]; then # 若选择非空项目
    exec make -f "$FILE" "$t" # 使用 exec 运行所选 make 目标
  else # 选择为空（无效编号）
    echo "无效选择" # 提示无效选择
  fi # 结束 if
done # 结束 select 循环（用户按 Ctrl+C 退出）