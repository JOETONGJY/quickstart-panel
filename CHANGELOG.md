## v1.2 (2026-10-05)

- fix: launch apps via WMI `Win32_Process.Create` — the spawned process is parented to a system service, fully severed from the panel. This survives Windows Terminal hosting and apps that attach to the parent console on startup (v1.1's ShellExecute fix was insufficient in those cases)

# Changelog

## v1.1 (2026-10-05)

- fix: launched apps are now fully detached from the panel console (explicit `UseShellExecute=$true`) — closing the panel no longer kills started apps, and no leftover console window in the taskbar

## v1.0 (2026-10-05)

- initial release: config-driven launcher panel, visible-window dedup with focus/restore, optional avatar image, sequential "launch all"
