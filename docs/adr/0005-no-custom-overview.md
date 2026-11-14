# 不复刻 Overview

`Super+O` 的预览界面继续用 niri 原生 overview，模糊背景由设置拿到：`blurWallpaperOnOverview`。
不引自研全屏层。

**验证（2026-11-14，v2.1.2 + 自编 quickshell 9b0f339b）**：同一台机器同一张壁纸做 A/B——
开关打开时 overview backdrop 是模糊过的壁纸（形状边缘发柔），关闭时是同一张壁纸的锐利原图。
所以 Q11 的"(a) 修好现有机制"成立，回退到纯色 backdrop 的方案不需要启用。

**Considered Options**：自研全屏层（要重写工作区缩放、拖拽与鼠标操作，成本十倍于修复）；把入口改成负一屏（等于废掉 niri 最核心的交互）。
