# ============================================================
#  QuickStart Panel — 一键开工启动面板
#  Zero-dependency Windows launcher: PowerShell + WinForms only.
#  Reads config.json next to this script. A default config is
#  generated on first run — edit it to match your own apps.
#  License: MIT
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir 'config.json'

# ---- load / first-run config bootstrap --------------------
if (-not (Test-Path $ConfigPath)) {
    $default = @{
        title            = 'QuickStart'
        avatar           = ''
        launchIntervalMs = 700
        apps             = @(
            @{ name = 'Notepad';        exe = "$env:SystemRoot\System32\notepad.exe"; process = 'notepad' },
            @{ name = 'Calculator';     exe = 'calc.exe';                             process = 'ApplicationFrameHost' },
            @{ name = 'File Explorer';  exe = 'explorer.exe';                         process = 'explorer' }
        )
    }
    $default | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath -Encoding UTF8
}

$config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $config.apps -or $config.apps.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show('config.json 里没有任何应用，请至少添加一个。', 'QuickStart') | Out-Null
    exit 1
}

# ---- Win32: bring an existing window to the foreground ----
Add-Type -Namespace Native -Name Win32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@

function Test-AppWindow([string]$procName) {
    @(Get-Process -Name $procName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 }).Count -gt 0
}

function Invoke-App($app) {
    $procs = @(Get-Process -Name $app.process -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 })
    if ($procs.Count -gt 0) {
        # already open: restore if minimized, then focus it — never spawn a second copy
        $h = $procs[0].MainWindowHandle
        if ([Native.Win32]::IsIconic($h)) { [Native.Win32]::ShowWindow($h, 9) | Out-Null }  # SW_RESTORE
        [Native.Win32]::SetForegroundWindow($h) | Out-Null
        return 'focus'
    }
    if (-not (Test-Path $app.exe)) { return 'missing' }
    # launch via WMI Win32_Process.Create: the spawned process is parented to
    # WmiPrvSE (system service), fully severed from this panel — no handle or
    # console relationship survives, no matter how the console is hosted
    # (conhost / Windows Terminal) and no matter what the app does on startup
    # (some Electron launchers AttachConsole to the parent and pin it alive).
    $cmdline = '"' + $app.exe + '"'
    if ($app.args) { $cmdline += ' ' + $app.args }
    Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmdline } | Out-Null
    return 'start'
}

# ---- resolve optional avatar image ------------------------
$avatarPath = $null
if ($config.avatar) {
    $p = if ([System.IO.Path]::IsPathRooted($config.avatar)) { $config.avatar }
         else { Join-Path $ScriptDir $config.avatar }
    if (Test-Path $p) { $avatarPath = $p }
}

# ---- build the UI -----------------------------------------
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = $config.title
$form.StartPosition   = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox     = $false
$form.BackColor       = [System.Drawing.Color]::FromArgb(20, 22, 31)

$script:status                = New-Object System.Windows.Forms.Label
$script:status.ForeColor      = [System.Drawing.Color]::FromArgb(150, 165, 190)
$script:status.Font           = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)
$script:status.AutoSize       = $false
$script:status.Location       = New-Object System.Drawing.Point(14, 448)

function Set-Status([string]$text) {
    $script:status.Text = $text
    $form.Refresh()
}

$btnWidth = 218
if ($avatarPath) {
    $form.Size = New-Object System.Drawing.Size(490, 560)
    $imgBox          = New-Object System.Windows.Forms.PictureBox
    $imgBox.Image    = [System.Drawing.Image]::FromFile($avatarPath)
    $imgBox.SizeMode = 'Zoom'
    $imgBox.Size     = New-Object System.Drawing.Size(230, 470)
    $imgBox.Location = New-Object System.Drawing.Point(246, 6)
    $imgBox.BackColor= $form.BackColor
    $form.Controls.Add($imgBox)
    $statusSize = New-Object System.Drawing.Size(224, 60)
} else {
    $btnWidth = 300
    $form.Size = New-Object System.Drawing.Size(340, [Math]::Max(220, 70 + $config.apps.Count * 48 + 120))
    $statusSize = New-Object System.Drawing.Size($btnWidth, 60)
}
$script:status.Size = $statusSize

$y = 14
foreach ($app in $config.apps) {
    $btn          = New-Object System.Windows.Forms.Button
    $btn.Text     = $app.name
    $btn.Tag      = $app
    $btn.Size     = New-Object System.Drawing.Size($btnWidth, 40)
    $btn.Location = New-Object System.Drawing.Point(14, $y)
    $btn.FlatStyle= 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = [System.Drawing.Color]::FromArgb(42, 49, 66)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 240)
    $btn.Font      = New-Object System.Drawing.Font('Microsoft YaHei UI', 10)
    $btn.Cursor    = 'Hand'
    $btn.Add_Click({
        $a = $this.Tag
        $r = Invoke-App $a
        switch ($r) {
            'start'   { Set-Status ("已启动 " + $a.name) }
            'focus'   { Set-Status ($a.name + " 已在前台") }
            'missing' { Set-Status ("没找到 " + $a.name + "，检查 config.json 里的路径") }
        }
    })
    $form.Controls.Add($btn)
    $y += 48
}

$big                 = New-Object System.Windows.Forms.Button
$big.Text            = '全部启动 ▶'
$big.Size            = New-Object System.Drawing.Size($btnWidth, 52)
$big.Location        = New-Object System.Drawing.Point(14, ($y + 8))
$big.FlatStyle       = 'Flat'
$big.FlatAppearance.BorderSize = 0
$big.BackColor       = [System.Drawing.Color]::FromArgb(84, 134, 255)
$big.ForeColor       = [System.Drawing.Color]::White
$big.Font            = New-Object System.Drawing.Font('Microsoft YaHei UI', 12, [System.Drawing.FontStyle]::Bold)
$big.Cursor          = 'Hand'
$big.Add_Click({
    $big.Enabled = $false
    $launched = 0; $focused = 0
    foreach ($a in $config.apps) {
        $r = Invoke-App $a
        if ($r -eq 'start') { $launched++ } elseif ($r -eq 'focus') { $focused++ }
        Start-Sleep -Milliseconds ([int]$config.launchIntervalMs)
    }
    Set-Status ("全部完成：新开 $launched 个，聚焦已开 $focused 个")
    $big.Enabled = $true
})
$form.Controls.Add($big)

$form.Controls.Add($script:status)

[void]$form.ShowDialog()
