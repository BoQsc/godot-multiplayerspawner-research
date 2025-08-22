@echo off
echo === WINDOWED TEST CLIENT ===
echo.
echo This will run a test client with a visible window.
echo The client should be able to move using input controls.
echo.
echo Features:
echo - Connects to your server (127.0.0.1:4443)
echo - Runs automated movement demo
echo - Stays running for manual control testing  
echo - Uses arrow keys and spacebar/enter for movement
echo.
echo Make sure your server is running first!
echo.
pause
echo.
echo Starting windowed test client...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" tester/WindowedClient.tscn
pause