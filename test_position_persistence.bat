@echo off
echo Testing Position Persistence - Multiple Restarts
echo ================================================

set GODOT_PATH="C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
set PLAYER_NAME=myserverfirsttimeplayerhere

for /L %%i in (1,1,10) do (
    echo.
    echo === RESTART %%i ===
    echo Starting server...
    
    rem Start server in background and capture output
    start /B %GODOT_PATH% --headless --server --player %PLAYER_NAME% --force-device-transfer > server_output_%%i.txt 2>&1
    
    rem Wait 8 seconds for startup and first auto-save
    timeout /t 8 >nul
    
    echo Stopping server...
    taskkill /f /im godot.windows.opt.tools.64.exe >nul 2>&1
    
    rem Wait 2 seconds between restarts
    timeout /t 2 >nul
    
    echo Checking output for position...
    findstr /C:"Getting spawn position" server_output_%%i.txt
    findstr /C:"EXISTING" server_output_%%i.txt
    findstr /C:"NEW" server_output_%%i.txt
)

echo.
echo Test complete. Check server_output_*.txt files for details.
pause