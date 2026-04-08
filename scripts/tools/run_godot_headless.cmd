@echo off
setlocal

for %%I in ("%~dp0..\..") do set "REPO_ROOT=%%~fI"
set "USER_ROOT=%REPO_ROOT%\.godot_user"
set "ROAMING_DIR=%USER_ROOT%\Roaming"
set "LOCAL_DIR=%USER_ROOT%\Local"
set "TEMP_DIR=%USER_ROOT%\Temp"
set "GODOT_EXE=Z:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe"

if not exist "%ROAMING_DIR%" mkdir "%ROAMING_DIR%"
if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

set "APPDATA=%ROAMING_DIR%"
set "LOCALAPPDATA=%LOCAL_DIR%"
set "TEMP=%TEMP_DIR%"
set "TMP=%TEMP_DIR%"

if "%~1"=="" (
	"%GODOT_EXE%" --headless --path "%REPO_ROOT%" --quit
) else (
	"%GODOT_EXE%" %*
)

exit /b %ERRORLEVEL%
