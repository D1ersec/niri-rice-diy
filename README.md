# NiriRiceDIY

给 [niri](https://github.com/YaLTeR/niri) 的 macOS 风格外壳：从 [Dux Modular Shell](https://github.com/duxlabs-dev/dux-shell)（`dux-shell`）分叉而来，按个人使用习惯重做顶栏、负一屏、磨砂与候选窗。

> A macOS-flavored niri desktop: a personal fork of Dux Modular Shell, pinned at v2.1.2.

## 这套桌面长什么样

- **顶栏**：贴边全宽、直角、半透明，左侧「当前应用名 + 工作区」，右侧「键盘布局 + 托盘 + 温度 + 通知 + 时钟」，中间留空。
- **负一屏**：六列栅格、八张卡（时钟 / 系统指标 / 天气 / 磁盘 / 网络 / 内存 / 媒体 / 日历），全部走主题中性灰，不用 Material 的 tonal 主色。
- **磨砂**：由 niri 的 `ext-background-effect` 在表面背后做真实模糊（xray 生效后按壁纸缓存，不逐帧重算）。
- **`Super+O`**：niri 原生 overview，背景是模糊壁纸（`blurWallpaperOnOverview`）。
- **候选窗**：fcitx5 主题 `rice-macos`，不透明深灰面板、大圆角、宽留白、蓝色高亮。
- **明确不做**：窗口的红绿灯按钮、最小化替身、真正的应用菜单、自研 overview。

设计取舍都写成了 ADR，见 [`docs/adr/`](docs/adr/)；术语表见 [`GLOSSARY.md`](GLOSSARY.md)；设置目标值见 [`docs/shell-settings.md`](docs/shell-settings.md)。

## 为什么不是直接装 dux-shell

分叉的原因是三处硬约束，不是偏好：

1. **版本固定**：基线钉在 v2.1.2，升级只手动触发，避免上游每周的改动把本地调整冲掉。
2. **运行时要自编**：Fedora 源里的 quickshell 是 0.2.1，加载 2.1.2 的 `shell.qml` 直接报 `Unrecognized pragma "AppId"`。本仓库用上游提交 `9b0f339b`（同 `dux-qt-base` 的基底）自编到 `~/.local`。
3. **设置由仓库持有**：顶栏形状、磨砂、负一屏卡片都以 `dotfiles/dms/settings.seed.json` 为准，系统包里的那份只作退路。

## 快速开始

```bash
git clone --recurse-submodules <this repo> ~/NiriRiceDIY
cd ~/NiriRiceDIY
./bootstrap.sh --dry-run   # 先看它会做什么
./bootstrap.sh             # 缺依赖会打印需要 sudo 的命令
tools/run-rice.sh          # 停系统 DMS → 跑本仓库外壳 → 退出自动恢复
```

`tools/run-rice.sh` 是安全的试用入口：Ctrl+C 出来就回到原来的外壳。完整恢复流程与验收标准见 [`RESTORE.md`](RESTORE.md)。

## 结构

```
bootstrap.sh              一次性恢复：子模块 → 依赖 → 编 dms → 编 quickshell → 链接配置
RESTORE.md                恢复步骤与三项验收
docs/adr/                 0001-0005 设计取舍
docs/shell-settings.md    顶栏/磨砂/负一屏的设置键与目标值
dotfiles/niri/            niri 配置与 Rice 覆盖层（必须在 DMS 片段之后 include）
dotfiles/dms/             外壳设置种子
dotfiles/fcitx5/          候选窗主题与 classicui 模板
tools/                    构建、启动、依赖安装脚本
quickshell/               上游 QML 外壳（改动见 git log）
core/                     上游 Go CLI 与守护进程
```

## 许可

上游 `dux-shell` 是 MIT；本仓库的改动同样以 MIT 发布，见 [`LICENSE`](LICENSE)。
上游 README 存档在 [`docs/upstream/dux-shell-README.md`](docs/upstream/dux-shell-README.md)。
