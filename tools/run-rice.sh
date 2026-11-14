#!/usr/bin/env bash
# 用本仓库的外壳替换系统 DMS 跑一次；退出时自动把系统 DMS 拉回来。
# 用法：
#   tools/run-rice.sh            # 停系统 DMS → 跑 Rice 外壳 → 退出后恢复
#   tools/run-rice.sh --keep-dms # 不动系统 DMS（只是看日志，会叠两条顶栏）
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
QS="${QS:-$PREFIX/bin/qs}"
KEEP=0
[[ "${1:-}" == "--keep-dms" ]] && { KEEP=1; shift; }

[[ -x $QS ]] || { echo "找不到 $QS，先跑 tools/build-quickshell.sh" >&2; exit 1; }

QMLDIR="$(find "$PREFIX" -maxdepth 4 -type d -path '*/qt6/qml' -print -quit)"
[[ -n $QMLDIR ]] || { echo "在 $PREFIX 下找不到 qt6/qml，编译器可能装到了别处" >&2; exit 1; }
export QML_IMPORT_PATH="$QMLDIR${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export QML2_IMPORT_PATH="$QML_IMPORT_PATH"

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

echo "[rice] QML_IMPORT_PATH=$QML_IMPORT_PATH" >&2
exec "$QS" -p "$REPO/quickshell" "$@"
