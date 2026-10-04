# QuickStart Panel · 一键开工

> Windows 上零依赖的「每日例行启动面板」：一个窗口放着你每天要开的一组软件，单击启动单个、一键按顺序全部拉起，**已经打开的不会被重复打开，而是把窗口调回前台**。

![screenshot](docs/screenshot.png)

## 这是什么

开机之后，双击一个图标，你固定的一套工作软件（浏览器、编辑器、聊天工具……）按顺序依次启动——已经开着的自动聚焦、没开的依次拉起。界面可以挂一张你喜欢的角色立绘当看板娘。

**零依赖**：只用 Windows 内置的 PowerShell + WinForms，不需要安装 .NET SDK / Python / 任何运行时，下载即用。

## 特性

- **可见窗口级防重复**：用 `MainWindowHandle` 检测应用是否真的开着（而不是进程是否存在），正确处理了两个经典坑：
  - Edge 的"启动加速"会在后台驻留进程——按进程判断会永远以为 Edge 开着；
  - 微信点 × 是缩到托盘——进程还在但窗口没了，此时应该把窗口拉回来而不是"跳过"。
- **聚焦而非跳过**：检测到已开窗口时，若已最小化会先还原、再把窗口调到前台（`SetForegroundWindow`），而不是无响应地什么都不做。
- **顺序启动**：全部启动时按配置顺序逐个拉起，间隔可配置，避免多个程序同时抢冷启动。
- **立绘皮肤（可选）**：`config.json` 里指定一张透明 PNG 即可挂到面板右侧；不配置就是纯按钮面板。
- **首次运行自动生成默认配置**，编辑 `config.json` 即可换成自己的软件。

## 快速开始

```powershell
# 1. 克隆或下载本仓库
# 2. 编辑 config.json，填入你的软件（exe 完整路径 + 进程名）
# 3. 运行：
powershell -NoProfile -ExecutionPolicy Bypass -File .\gui.ps1
```

推荐做一个桌面快捷方式，目标写：

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "你的路径\gui.ps1"
```

（`-WindowStyle Hidden` 让 PowerShell 控制台启动后自动隐藏。）

## 配置说明

`config.json`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `title` | string | 窗口标题 |
| `avatar` | string | 立绘图片路径（相对脚本目录或绝对路径），留空则不显示 |
| `launchIntervalMs` | number | 「全部启动」时两个应用之间的间隔毫秒数 |
| `apps[].name` | string | 按钮显示名 |
| `apps[].exe` | string | 程序完整路径 |
| `apps[].process` | string | 进程名（exe 文件名去掉 `.exe`，用于防重复检测；带空格也可以） |
| `apps[].args` | string | 可选，启动参数 |

参考 `config.example.json`。

## 把角色立绘当皮肤

`avatar` 支持任意透明背景 PNG（角色立绘、游戏角色、看板娘……）。本仓库**不附带任何版权立绘**——请自行准备你有权使用的图片。

## 为什么用 MainWindowHandle 而不是查进程？

很多同类脚本用 `tasklist` 或 `Get-Process` 判断"软件是否已打开"，这有两个真实场景的误判：

1. **Edge 的启动加速**：关闭所有 Edge 窗口后，后台仍驻留十几个 `msedge.exe` 进程——按进程判断会永远以为 Edge 开着，导致它永远点不开；
2. **微信/QQ 的关闭即托盘**：进程活着但窗口没了——用户此时想要的是把窗口唤回前台。

所以本工具的判定口径是 **`MainWindowHandle ≠ 0`（存在可见顶层窗口）**，并配合 `IsIconic` + `ShowWindow(SW_RESTORE)` + `SetForegroundWindow` 完成"已开 → 还原并聚焦"的完整行为。

## 已知限制

- PowerShell 控制台会在启动瞬间闪现约 0.3 秒（进程创建先于 `-WindowStyle Hidden` 生效，PowerShell 的固有限制）；
- 仅支持 Windows（WinForms）。

## License

[MIT](LICENSE)
