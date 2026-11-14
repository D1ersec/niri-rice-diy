#!/usr/bin/env bash
# 用本仓库的外壳替换系统 DMS 跑一次；退出时按原来的状态恢复。
# 用法：
#   tools/run-rice.sh            # 停系统 DMS（若在跑）→ 跑 Rice 外壳 → 退出后恢复原状
#   tools/run-rice.sh --keep-dms # 不动系统 DMS（systemd 单元就是这么调用的）
#
# 关键点（踩过的坑）：
#  1. 必须用本仓库的 core/bin/dms，而不是系统的 /usr/bin/dms：外壳会调用 `dms blur check`
#     探测 ext-background-effect-v1，1.4.4 里没有这个命令，会误判"合成器不支持模糊"。
#  2. `dms run` 内部 exec 的是 PATH 里的 `qs`。我们在仓库内造一个私有 `qs` 指向自编的
#     quickshell，只在本脚本的 PATH 里生效，绝不遮蔽 /usr/bin/qs。
#  3. 系统的 qs 进程 argv[0] 是 `qs`，`pkill -f 'quickshell -p …'` 匹配不到它；
#     清理残留实例要按 PID 或 `pgrep -f 'qs -p <dir>'`。
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
QS_BIN="${QS_BIN:-$PREFIX/bin/quickshell}"
KEEP=0
[[ "${1:-}" == "--keep-dms" ]] && { KEEP=1; shift; }

[[ -x $QS_BIN ]] || { echo "找不到 $QS_BIN，先跑 tools/build-quickshell.sh" >&2; exit 1; }
[[ -x $REPO/core/bin/dms ]] || { echo "找不到 core/bin/dms，先跑 make dev" >&2; exit 1; }

# 由 systemd 单元托管时，别再手动起第二个实例
if (( KEEP == 0 )) && systemctl --user is-active --quiet rice-shell.service; then
  cat >&2 <<'EOF'
rice-shell.service 正在托管外壳，手动再起会变成两个实例（两条顶栏）。
  · 想重启外壳：systemctl --user restart rice-shell
  · 只看日志：systemctl --user stop rice-shell 之后再跑本脚本
EOF
  exit 1
fi

# 私有 qs：只在本次运行的 PATH 中生效
mkdir -p "$REPO/.bin"
ln -sfn "$QS_BIN" "$REPO/.bin/qs"
export PATH="$REPO/.bin:$REPO/core/bin:$PATH"

# 只在系统 DMS 原本活着时才恢复它，避免把已被 disable 的 1.4.4 又拉起来
DMS_WAS_ACTIVE=0
systemctl --user is-active --quiet dms.service && DMS_WAS_ACTIVE=1

restore() {
  if (( KEEP == 0 && DMS_WAS_ACTIVE == 1 )); then
    systemctl --user start dms.service 2>/dev/null || true
    echo "[rice] 已恢复系统 DMS" >&2
  fi
}
trap restore EXIT

if (( KEEP == 0 && DMS_WAS_ACTIVE == 1 )); then
  systemctl --user stop dms.service 2>/dev/null || true
  echo "[rice] 已停系统 DMS" >&2
fi

echo "[rice] PATH 前缀: $REPO/.bin:$REPO/core/bin；运行时: $QS_BIN" >&2
exec "$REPO/core/bin/dms" run -c "$REPO/quickshell" "$@"
