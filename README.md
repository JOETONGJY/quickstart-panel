# QuickStart Panel · 一键开工

> Windows 上零依赖的「每日例行启动面板」：一个窗口放着你每天要开的一组软件，单击启动单个、一键按顺序全部拉起，**已经打开的不会被重复打开，而是把窗口调回前台**。

![screenshot](docs/screenshot.png)

## 这是什么

开机之后，你要做的仅仅是双击一个图标，固定的一套工作软件（浏览器、编辑器、聊天工具……）会自动按照顺序被拉起。附：界面可以挂一张你喜欢的角色立绘当看板娘。

**零依赖需求**：只用 Windows 内置的 PowerShell + WinForms，不需要安装 .NET SDK / Python / 任何运行时，下载即用。

## 特性

- **可见窗口防重复**： `MainWindowHandle` 检测应用是否打开
- **聚焦而非跳过**：检测到已开窗口时，若已最小化会先还原、再把窗口调到前台（`SetForegroundWindow`）
- **立绘皮肤（可选）**：`config.json` 里指定一张透明 PNG 即可挂到面板右侧；默认为纯按钮面板
- **配置简单**，编辑 `config.json` 即可换成自己的软件

## 快速开始

```powershell
# 1. 克隆或下载本仓库
# 2. 编辑 config.json，填入你的软件（exe 完整路径 + 进程名）
# 3. 运行：
powershell -NoProfile -ExecutionPolicy Bypass -File .\gui.ps1
```

推荐做一个桌面快捷方式：

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "你的路径\gui.ps1"
```

（`-WindowStyle Hidden` PowerShell 控制台启动后自动隐藏。）

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

参考 `config.example.json`

## 把角色立绘当皮肤

`avatar` 支持任意透明背景 PNG（角色立绘、游戏角色、看板娘……）。本仓库**不附带任何版权立绘**——请自行准备你有权使用的图片。

## 已知限制
- 仅支持 Windows

## License

[MIT](LICENSE)
