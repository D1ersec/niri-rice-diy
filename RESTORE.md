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

v0.3.2 才同时具备 `pragma AppId` 与 `ext-background-effect`（合成器磨砂的协议实现），所以自编到 `~/.local`，不替换系统包。

## 验收（三项都要过）

1. **配置合法**：`niri validate -c ~/.config/niri/config.kdl` 输出 `config is valid`。
2. **外壳自检**：`$REPO/core/bin/dms doctor` 无 error 级结论。
3. **观感一致**：顶栏贴边全宽、无圆角；负一屏八张卡；`Super+O` 的 overview 背景是模糊壁纸；候选窗是大圆角深灰面板。

## 壁纸

不入库。记录：壁纸文件放在哪里、用哪个工具设置（当前会话由 DMS 负责），换机后手动放回同一路径。

## 回滚

系统 DMS 1.4.4 的包没有被动过：`systemctl --user start dms.service` 就回到原样。
