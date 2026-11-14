# niri 配置只用末尾覆盖层接管

DMS 会持续重写 `~/.config/niri/dms/` 下的 `colors`、`layout`、`alttab`、`wpblur`、`binds`、`outputs`、`cursor` 七个片段，且主配置把它们 include 在最后。我们不改 DMS 的写入逻辑，而是在其后追加一条 `include optional=true "~/.config/niri/rice/overrides.kdl"`，把自己要控的字段（边框与焦点环、gaps、圆角、layer 规则）逐字段覆盖。

**Consequences**：任何"想在 niri 侧生效"的改动都必须写进覆盖层，而不是手改主配置或 DMS 片段；DMS 的设置界面仍可继续用于生成 outputs 与 cursor。
