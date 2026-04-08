# Local Tooling

## Godot Executables

- GUI editor/runtime executable: `Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe`
- Console/headless-friendly executable: `Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe`
- Sandbox-safe headless wrapper: `Z:\RiskItMeow\risk-it-meow\scripts\tools\run_godot_headless.cmd`

## Usage Note

- For project automation, script parsing, imports, or command-line runs, prefer the console executable.
- For interactive editing and manual playtesting, use the GUI executable.
- In sandboxed environments, prefer the `.cmd` wrapper for headless runs because it redirects Godot's user-data folders into the repo's writable `.godot_user/` directory before launching the console executable.
