#!/usr/bin/env bash
# 用本仓库的外壳替换系统 DMS 跑一次；退出时自动把系统 DMS 拉回来。
# 用法：
#   tools/run-rice.sh            # 停系统 DMS → 跑 Rice 外壳 → 退出后恢复
#   tools/run-rice.sh --keep-dms # 不动系统 DMS（只是看日志，会叠两条顶栏）
#
# 关键点（踩过的坑）：
#  1. 必须用本仓库的 core/bin/dms，而不是系统的 /usr/bin/dms：外壳会调用 `dms blur check`
#     探测 ext-background-effect-v1，1.4.4 里没有这个命令，会误判"合成器不支持模糊"。
#  2. `dms run` 内部 exec 的是 PATH 里的 `qs`。我们在仓库内造一个私有 `qs` 指向自编的
#     quickshell，只在本脚本的 PATH 里生效，绝不遮蔽 /usr/bin/qs（否则会弄坏 DMS 1.4.4）。
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
QS_BIN="${QS_BIN:-$PREFIX/bin/quickshell}"
KEEP=0
[[ "${1:-}" == "--keep-dms" ]] && { KEEP=1; shift; }

[[ -x $QS_BIN ]] || { echo "找不到 $QS_BIN，先跑 tools/build-quickshell.sh" >&2; exit 1; }
[[ -x $REPO/core/bin/dms ]] || { echo "找不到 core/bin/dms，先跑 make dev" >&2; exit 1; }

# 私有 qs：只在本次运行的 PATH 中生效
mkdir -p "$REPO/.bin"
ln -sfn "$QS_BIN" "$REPO/.bin/qs"
export PATH="$REPO/.bin:$REPO/core/bin:$PATH"

restore() {
  if (( KEEP == 0 )); then
    systemctl --user start dms.service 2>/dev/null || true
    echo "[rice] 已恢复系统 DMS" >&2
  fi
}
trap restore EXIT

if (( KEEP == 0 )); then
  systemctl --user stop dms.service 2>/dev/null || true
  echo "[rice] 已停系统 DMS" >&2
fi

echo "[rice] PATH 前缀: $REPO/.bin:$REPO/core/bin；运行时: $QS_BIN" >&2
exec "$REPO/core/bin/dms" run -c "$REPO/quickshell" "$@"
