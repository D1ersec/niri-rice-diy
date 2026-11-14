# NiriRiceDIY

自定义 niri 桌面外壳的上下文：本仓库承载对 Dux Modular Shell 的分叉与本地改造。

## Language

**DMS (Dux Modular Shell)**:
这套桌面外壳的项目名，也是它命令行与守护进程的名字 `dms`。前身叫 DankMaterialShell。
_Avoid_: duxshell, DankShell, dank

**dux-shell**:
上游仓库 `duxlabs-dev/dux-shell`，MIT 许可，本仓库分叉的来源。
_Avoid_: dms 仓库, 上游 dms

**Shell 树**:
仓库内 `quickshell/` 目录，纯 QML 的界面层，含面板、启动器、控制中心等模块，不参与编译。
_Avoid_: qml 目录, 前端

**core**:
仓库内 `core/` 目录，Go 编写的 `dms` 命令行与守护进程，负责 IPC、系统集成、启动界面。
_Avoid_: 后端, daemon, 服务

**dux-qt-base**:
上游对 quickshell 的 C++ 分叉，提供 `libdux-qt-base.so.0` 作为 QML 运行时，LGPL-3.0。
_Avoid_: quickshell 补丁, qs 插件

**dux-qml-common**:
DMS 与 dux-greeter、dux-calendar、dux-files 共享的 QML 组件库，以子模块挂在仓库根，在 Shell 树里显示为 `DCommon`。
_Avoid_: 公共组件, common 库

**系统 DMS**:
Fedora 仓库安装的 `DankMaterialShell` / `dms` / `dms-cli` 包（当前 1.4.4），由用户级 systemd 服务 `dms.service` 启动。
_Avoid_: 已装版本, 旧版

## 界面术语

**顶栏**:
屏幕边缘那条常驻状态条，对应上游模块 `DBar`。
_Avoid_: bar, taskbar, 状态栏

**负一屏**:
挂在工作区左/右侧的整体面板，对应上游模块 `DDash`；哔哩哔哩演示里那块磨砂仪表盘就是它。
_Avoid_: 侧栏, dashboard, 仪表盘

**岛**:
顶栏中部可展开的活动胶囊，对应上游模块 `DIsland`。
_Avoid_: 灵动岛, pill, 胶囊

**帧框**:
包裹整个屏幕边缘的一圈圆角框，顶栏与 Dock 挂在它上面，对应上游模块 `Frame`。
_Avoid_: 边框, frame 窗口, 圆角容器

**合成器磨砂**:
由 niri 通过 `ext-background-effect` 在表面背后做的真实模糊，xray 生效时按壁纸缓存。
_Avoid_: 真模糊, GPU 模糊, backdrop blur

**快照模糊**:
QML 里用 `ShaderEffectSource` + `MultiEffect` 自己截屏再模糊，不依赖合成器，对应组件 `BackdropBlur`。
_Avoid_: 假模糊, QML 模糊, 模拟磨砂

**红绿灯**:
窗口标题栏左侧的关闭/最小化/最大化三色按钮，只存在于应用自己的客户端装饰里。
_Avoid_: 窗口按钮, close 按钮, traffic lights

**候选窗**:
输入法弹出的一列候选字窗口，由 fcitx5 的 classicui 绘制，形状来自 SVG、颜色来自主题文件。
_Avoid_: 输入法弹窗, IME 浮窗, 提示框
