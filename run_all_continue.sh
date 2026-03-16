#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

SELF="$(basename "$0")"

# 只取当前目录下的 .sh，按名字排序，排除自己
mapfile -t scripts < <(ls -1 *.sh 2>/dev/null | sort | grep -v "^${SELF}$" || true)

if ((${#scripts[@]} == 0)); then
  echo "未找到可执行的 .sh 脚本"
  exit 1
fi

failed=0
failed_list=()

for s in "${scripts[@]}"; do
  echo "===== 开始执行: $s ====="
  bash "./$s"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "!!!!! 脚本失败: $s (exit=$rc) 继续执行下一个..."
    failed=$((failed + 1))
    failed_list+=("$s:$rc")
  else
    echo "===== 执行完成: $s ====="
  fi
done

echo "=========================="
echo "全部脚本执行完成 ✅"
if [[ $failed -ne 0 ]]; then
  echo "失败数量: $failed"
  printf '失败列表:\n'
  printf ' - %s\n' "${failed_list[@]}"
  exit 1
fi
