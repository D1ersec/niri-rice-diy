# 恢复这份桌面

目标：干净系统上 `git clone` 后一条命令回到可用状态。壁纸与截图不入库（体积），只记录位置与设置方式。

## 步骤

```bash
git clone <你的仓库地址> ~/NiriRiceDIY
cd ~/NiriRiceDIY
./bootstrap.sh --dry-run   # 先看要做什么
./bootstrap.sh             # 缺依赖时会打印需要 sudo 的命令，装完再跑一次
```

`bootstrap.sh` 做四件事：检查运行时/构建依赖 → `make dev` 编 `dms` → 编 quickshell v0.3.2 到 `~/.local` → 链接 niri 配置、覆盖层与 fcitx5 主题。

## 为什么不用系统的 quickshell

Fedora 只有 quickshell 0.2.1，加载本仓库的 `shell.qml` 会立刻报：

```
ERROR: Unrecognized pragma "AppId dev.duxlabs.shell"
```

自编的上游提交是 **`9b0f339b`（2026-10-21）**，它是 dux-shell 2.x 对应的基底（上游运行时 fork
`dux-qt-base` 就基于这个提交），比 v0.3.2 新。装到 `~/.local/bin/quickshell`，不替换系统包，
也**不安装 `qs` 这个名字**——避免遮蔽 `/usr/bin/qs` 而弄坏仍在跑的 DMS 1.4.4。

quickshell 0.3 起把 QML 模块静态编进可执行文件，因此没有 `qt6/qml` 目录，也不需要
`QML_IMPORT_PATH`。**Hyprland 插件必须编进去**（外壳的 `WallpaperBackground.qml` 会 import
`Quickshell.Hyprland`），即使我们只用 niri。

## 验收（三项都要过）

1. **配置合法**：`niri validate -c ~/.config/niri/config.kdl` 输出 `config is valid`。
2. **外壳自检**：`$REPO/core/bin/dms doctor` 无 error 级结论。
3. **观感一致**：顶栏贴边全宽、无圆角；负一屏八张卡；`Super+O` 的 overview 背景是模糊壁纸；候选窗是大圆角深灰面板。

## 壁纸

不入库。记录：壁纸文件放在哪里、用哪个工具设置（当前会话由 DMS 负责），换机后手动放回同一路径。

## 回滚

系统 DMS 1.4.4 的包没有被动过：`systemctl --user start dms.service` 就回到原样。
