@echo off
echo === JOIN YOUR RUNNING SERVER ===
echo.
echo This will connect a test client to your existing server
echo and demonstrate walking around your world.
echo.
echo IMPORTANT: Make sure your game server is running first!
echo.
echo What this will do:
echo 1. Connect test client to localhost:4443
echo 2. You should see a new player appear in your game
echo 3. The test client will walk around automatically
echo 4. You can watch it move in your game client
echo.
pause
echo.
echo Connecting to your server...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/ConnectToExistingServer.tscn
pause