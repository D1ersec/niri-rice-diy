#!/usr/bin/env bash
# 从零恢复这台机器的 niri + Rice 外壳。
# 幂等：可重复执行；不自动 sudo，缺包时只打印需要执行的命令。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
QS_SRC="${QUICKSHELL_SRC:-$HOME/.local/src/quickshell}"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

say()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }
run()  { if (( DRY )); then say "would: $*"; else "$@"; fi; }
link() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    note "已链接 $dst"
  else
    run ln -sfn "$src" "$dst"
    note "链接 $dst -> $src"
  fi
}

# ── 1. 依赖 ────────────────────────────────────────────────────────
say "== 运行时包 =="
RUNTIME=(niri xwayland-satellite fcitx5 fcitx5-chinese-addons matugen dgop danksearch qt6-qtmultimedia quickshell)
MISSING_RT=()
for p in "${RUNTIME[@]}"; do rpm -q "$p" >/dev/null 2>&1 || MISSING_RT+=("$p"); done
if (( ${#MISSING_RT[@]} )); then
  say "缺运行时包，请先执行："
  say "  sudo dnf install ${MISSING_RT[*]}"
else
  note "运行时包齐全"
fi

say "== 构建依赖（编 quickshell 用）=="
BUILD_PKGS=(qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel
            qt6-qtwayland-devel cli11-devel libdrm-devel mesa-libgbm-devel pipewire-devel pam-devel
            polkit-devel jemalloc-devel wayland-devel wayland-protocols-devel glib2-devel spirv-tools
            vulkan-headers gcc-c++ cmake ninja-build)
MISSING_BD=()
for p in "${BUILD_PKGS[@]}"; do rpm -q "$p" >/dev/null 2>&1 || MISSING_BD+=("$p"); done
if (( ${#MISSING_BD[@]} )); then
  say "缺构建依赖，请先执行："
  say "  sudo dnf install --setopt=install_weak_deps=False ${MISSING_BD[*]}"
else
  note "构建依赖齐全"
fi

# ── 2. 编 dms（Go，纯静态）─────────────────────────────────────────
say "== 编译 dms =="
run make -C "$REPO" dev
note "产物：$REPO/core/bin/dms"

# ── 3. 编 quickshell v0.3.2 ───────────────────────────────────────
say "== 编译 quickshell v0.3.2 =="
if [[ -f "$QS_SRC/CMakeLists.txt" ]]; then
  run env QUICKSHELL_SRC="$QS_SRC" PREFIX="$PREFIX" "$REPO/tools/build-quickshell.sh"
else
  say "缺源码，请先："
  say "  git clone --depth 1 --branch v0.3.2 https://github.com/quickshell-mirror/quickshell.git $QS_SRC"
fi

# ── 4. 链接配置 ───────────────────────────────────────────────────
say "== 配置 =="
link "$REPO/dotfiles/niri/config.kdl"            "$HOME/.config/niri/config.kdl"
link "$REPO/dotfiles/niri/rice/overrides.kdl"   "$HOME/.config/niri/rice/overrides.kdl"
link "$REPO/dotfiles/fcitx5/themes/rice-macos"  "$HOME/.local/share/fcitx5/themes/rice-macos"
CUI="$HOME/.config/fcitx5/conf/classicui.conf"
if [[ -f $CUI ]]; then
  note "保留已有 $CUI（fcitx5 会自己改写，仓库里那份是模板）"
else
  mkdir -p "$(dirname "$CUI")"
  run cp "$REPO/dotfiles/fcitx5/classicui.conf" "$CUI"
  note "复制 classicui.conf 模板"
fi

# ── 5. 验收提示 ───────────────────────────────────────────────────
say
say "完成。接下来："
say "  1) niri validate -c ~/.config/niri/config.kdl"
say "  2) $REPO/tools/run-rice.sh    # 用 Rice 外壳替换系统 DMS"
say "  3) 详见 RESTORE.md"
