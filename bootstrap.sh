#!/usr/bin/env bash
# 从零恢复这台机器的 niri + Rice 外壳。
# 幂等：可重复执行；不自动 sudo，缺包时只打印需要执行的命令。
#
# 顺序：子模块 → 依赖检查 → 编 dms → 编 quickshell → 链接配置 → 写设置种子
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
QS_SRC="${QUICKSHELL_SRC:-$PREFIX/src/quickshell}"
QS_COMMIT="9b0f339b19057f4731bf3b48293307d7ef241671"   # dux-shell 2.x 对应的上游基底
DRY=0
RESET_SETTINGS=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --reset-settings) RESET_SETTINGS=1 ;;
  esac
done

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
missing() {  # missing <pkg...> -> 打印缺失的包
  local out=()
  for p in "$@"; do rpm -q "$p" >/dev/null 2>&1 || out+=("$p"); done
  (( ${#out[@]} )) && printf '%s\n' "${out[@]}"
}

# ── 0. 子模块（DCommon 是 shell 树的一部分，缺了外壳起不来）──────────
say "== 子模块 =="
if [[ -d "$REPO/dux-qml-common/DCommon/Common" ]]; then
  note "dux-qml-common 已就位"
else
  run git -C "$REPO" submodule update --init --depth 1
fi

# ── 1. 依赖 ────────────────────────────────────────────────────────
say "== 运行时包 =="
RT_MISSING="$(missing niri xwayland-satellite fcitx5 fcitx5-chinese-addons matugen dgop danksearch qt6-qtmultimedia quickshell || true)"
if [[ -n $RT_MISSING ]]; then
  say "缺运行时包，请先执行："
  say "  sudo dnf install $(echo $RT_MISSING)"
else
  note "运行时包齐全"
fi

say "== 构建依赖 =="
BD_MISSING="$(missing qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
  qt6-qtwayland-devel cli11-devel libdrm-devel mesa-libgbm-devel pipewire-devel pam-devel polkit-devel \
  jemalloc-devel wayland-devel wayland-protocols-devel glib2-devel spirv-tools vulkan-headers \
  gcc-c++ cmake ninja-build || true)"
if [[ -n $BD_MISSING ]]; then
  say "缺构建依赖，请先执行（或用仓库里的脚本）："
  say "  sudo bash $REPO/tools/install-build-deps.sh"
else
  note "构建依赖齐全"
fi

# ── 2. 编 dms（Go，纯静态，不用 Qt）────────────────────────────────
say "== 编译 dms =="
run make -C "$REPO" dev
note "产物：$REPO/core/bin/dms"

# ── 3. 编 quickshell（上游基底提交）────────────────────────────────
say "== 编译 quickshell $QS_COMMIT =="
if [[ -f "$QS_SRC/CMakeLists.txt" ]]; then
  run env QUICKSHELL_SRC="$QS_SRC" PREFIX="$PREFIX" "$REPO/tools/build-quickshell.sh"
else
  say "缺源码，请先："
  say "  git clone --depth 1 https://github.com/quickshell-mirror/quickshell.git $QS_SRC"
  say "  git -C $QS_SRC checkout $QS_COMMIT"
fi

# 私有 qs：只在 run-rice.sh 的 PATH 里生效，绝不遮蔽 /usr/bin/qs
mkdir -p "$REPO/.bin"
run ln -sfn "$PREFIX/bin/quickshell" "$REPO/.bin/qs"

# ── 4. 链接配置 ───────────────────────────────────────────────────
say "== 配置 =="
link "$REPO/dotfiles/niri/config.kdl"           "$HOME/.config/niri/config.kdl"
link "$REPO/dotfiles/niri/rice/overrides.kdl"  "$HOME/.config/niri/rice/overrides.kdl"
link "$REPO/dotfiles/fcitx5/themes/rice-macos" "$HOME/.local/share/fcitx5/themes/rice-macos"

CUI="$HOME/.config/fcitx5/conf/classicui.conf"
if [[ -f $CUI ]]; then
  note "保留已有 $CUI（fcitx5 会自己改写，仓库里那份是模板）"
else
  mkdir -p "$(dirname "$CUI")"
  run cp "$REPO/dotfiles/fcitx5/classicui.conf" "$CUI"
  note "复制 classicui.conf 模板"
fi

# ── 5. 外壳设置种子（顶栏形状 / 磨砂 / 负一屏卡片）──────────────────
SETTINGS="$HOME/.config/dms/settings.json"
if [[ -f $SETTINGS && $RESET_SETTINGS -eq 0 ]]; then
  note "保留已有 $SETTINGS（要覆盖成仓库里的目标外观：--reset-settings）"
else
  mkdir -p "$(dirname "$SETTINGS")"
  [[ -f $SETTINGS ]] && run cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  run cp "$REPO/dotfiles/dms/settings.seed.json" "$SETTINGS"
  note "写入设置种子"
fi

# ── 6. 验收提示 ───────────────────────────────────────────────────
say
say "完成。接下来："
say "  1) niri validate -c ~/.config/niri/config.kdl"
say "  2) $REPO/tools/run-rice.sh    # 用 Rice 外壳替换系统 DMS"
say "  3) 详见 RESTORE.md"
