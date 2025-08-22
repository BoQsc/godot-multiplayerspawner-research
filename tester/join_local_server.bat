@echo off
echo === Joining Your Local Server ===
echo.
echo This will connect a test client to your running local server
echo and let you control it to walk around your world.
echo.
echo Make sure your local server is running first!
echo Default connection: localhost:4443
echo.
echo Once connected, you can use commands like:
echo   client 0 move 100 100
echo   client 0 move 200 200
echo   client 0 status
echo   client 0 list_players
echo.
pause
echo.
echo Connecting to your server...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn