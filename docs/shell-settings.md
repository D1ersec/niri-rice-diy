# 外壳设置目标值（v2.1.2）

这份表是"顶栏重排 + 磨砂 + 主题"落地时的**唯一依据**。键名全部取自
`quickshell/Common/settings/SettingsSpec.js`，默认值也是从那里读的，不是在设置界面里猜的。
应用方式：设置界面逐项改，或首次运行后直接改 `~/.config/dms/settings.json`（后者快但要等 schema 生成）。

## 全局键

| 键 | 默认 | 目标 | 理由 |
|---|---|---|---|
| `currentThemeName` | `purple` | `ricemacos` | 中性灰阶层级 + 系统蓝 accent（`StockThemes.js` 里新增的色板）。键名不是 `currentTheme`——那个是 `Theme.qml` 的内部属性，写进 settings.json 无效 |
| `currentThemeCategory` | `generic` | `generic` | 与内置主题同组 |
| `blurEnabled` | `false` | `true` | 打开合成器磨砂的开关（`BlurService` 会探测 `ext-background-effect-v1`） |
| `blurStrength` | `0` | `0` | 0 = 用 niri 侧 `blur{}` 的强度，不在 QML 里再叠一层 |
| `blurredWallpaperLayer` | `false` | `true` | 让 `dms:blurwallpaper` 层真的渲染模糊壁纸 |
| `blurWallpaperOnOverview` | `false` | `true` | **`Super+O` 灰底的解药**：overview 打开时用模糊壁纸做 backdrop |
| `frameEnabled` | `false` | `false` | 顶栏"与屏幕对齐"的前提：不开帧框，就没有内缩与圆角 |
| `barElevationEnabled` | `true` | `false` | 去掉 Material 的抬高阴影，macOS 菜单栏没有悬浮感 |

## 单条 bar（`barConfigs[0]`）

| 键 | 默认 | 目标 | 理由 |
|---|---|---|---|
| `attachToScreenEdge` | `false` | `true` | 贴边全宽，不再悬浮 |
| `barLengthMode` | `full` | `full` | 拉满整条屏幕 |
| `barInsetPadding` | `-1` | `0` | `-1` 是自动内缩，正是"没对齐"的来源 |
| `barLengthPadding` | `0` | `0` | — |
| `bottomGap` | `0` | `0` | — |
| `squareCorners` | `false` | `true` | 直角；圆角是 Material 观感的一部分 |
| `gothCornersEnabled` | `false` | `false` | 那种"内凹角"不要 |
| `widgetStyle` | `pills` | `flat` | 去掉每个图标外面的胶囊底，macOS 是纯图标 |
| `widgetPadding` | `8` | `6` | flat 之后留白可以收紧 |
| `spacing` | `4` | `10` | 图标之间靠间距分组，而不是靠背景块 |
| `transparency` | `1.0` | `0.75` | 磨砂可见的前提 |
| `borderEnabled` | `false` | `false` | 贴边条不需要描边 |
| `shadowIntensity` | `0` | `0` | — |
| `showOnWindowsOpen` | `false` | `true` | 常驻（macOS 菜单栏永远在） |
| `hideOnFullscreen` | `false` | `false` | 全屏也不隐藏 |

### 部件排布

```json
{
  "leftWidgets": ["focusedWindow", "workspaceSwitcher"],
  "centerWidgets": [],
  "rightWidgets": ["layout", "systemTray", "cpuTemp", "notificationButton", "clock"]
}
```

`leftWidgets` 的 `focusedWindow` 就是"菜单栏左侧显示当前应用"那格；`workspaceSwitcher` 紧挨着，
用 `dots`/`dots` 样式而不是 Material 胶囊（见 `WorkspaceSwitcherOptions.qml` 的 style 列表）。

**一处必须修正之前的设想**：2.1.2 的部件目录里**没有音量和网络部件**（30 个 id 全表在
`BarWidgetCatalog.qml`）。`layout` 是键盘布局，`systemTray` 承载输入法与其他托盘图标，
音量与网络只存在于控制中心。所以右侧最终是"布局 + 托盘 + 温度 + 通知 + 时钟"，
不再追求右上角单独的音量/网络图标——这反而更接近 macOS 的克制。

## 负一屏（DDash）

八张卡的目标清单（时钟、系统、存储、网络、电池、天气、日历、媒体）落地时对应
`dash` 的标签页与卡片注册表（`Modules/DDash/DashRegistry.qml`）；本轮先记目标，等外壳跑起来后按实际卡片能力裁剪。

## 运行时接线（实测踩出来的三条）

1. **必须用本仓库的 `core/bin/dms`**。外壳调用 `dms blur check` 探测 `ext-background-effect-v1`；
   系统 `/usr/bin/dms` 是 1.4.4，没有这个子命令，会误判成"合成器不支持模糊"，磨砂全局失效。
2. **`dms run` 内部 exec PATH 里的 `qs`**。仓库内造 `.bin/qs -> ~/.local/bin/quickshell`，只在
   `tools/run-rice.sh` 的 PATH 前缀里生效；不要往 `~/.local/bin` 放名为 `qs` 的链接，否则会遮蔽
   `/usr/bin/qs` 并弄坏仍在跑的 DMS 1.4.4。
3. **quickshell 用上游 `9b0f339b`，且 Hyprland 插件必须编进去**。`WallpaperBackground.qml` 会
   `import Quickshell.Hyprland`，关掉该插件会导致 `Configuration Loaded` 失败。

## 已验证（2026-11-14）

- 顶栏：贴边全宽、直角、无胶囊，左侧「应用名 + 工作区」、右侧「布局 + 托盘 + 温度 + 通知 + 时钟」。
- 磨砂：`dms blur check` 返回 supported，`BlurService` 启用。
- `Super+O`：开启 `blurWallpaperOnOverview` 时 backdrop 是模糊壁纸，关闭时是锐利原图（A/B 实测）。
