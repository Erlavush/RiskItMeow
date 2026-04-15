# Local Tooling

## Godot Executables

The Godot executables live in the project root:

- GUI editor/runtime executable: `.\Godot_v4.6.1-stable_win64.exe`
- Console/headless-friendly executable: `.\Godot_v4.6.1-stable_win64_console.exe`

Absolute paths:
- `z:\RiskItMeow\risk-it-meow\Godot_v4.6.1-stable_win64.exe`
- `z:\RiskItMeow\risk-it-meow\Godot_v4.6.1-stable_win64_console.exe`

## Usage Note

- For project automation, script parsing, imports, or command-line runs, prefer the console executable.
- For interactive editing and manual playtesting, use the GUI executable.
- To run a headless script: `.\Godot_v4.6.1-stable_win64.exe --path . -s <script_path> --headless`
