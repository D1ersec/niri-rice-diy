# 不复刻 Overview

`Super+O` 的预览界面继续用 niri 原生 overview。模糊背景的修复失败时，回退到把 `overview.backdrop-color` 设为壁纸主色的纯色，而不是自研全屏层。

**Considered Options**：自研全屏层（要重写工作区缩放、拖拽与鼠标操作，成本十倍于修复）；把入口改成负一屏（等于废掉 niri 最核心的交互）。
