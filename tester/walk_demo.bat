@echo off
echo === 1-MINUTE WALKING DEMO ===
echo.
echo This will connect to your server and walk around for 1 full minute
echo using different movement patterns:
echo.
echo Pattern 1 (0-12s):  Rectangle - walking in a square
echo Pattern 2 (12-24s): Circle - walking in a circle  
echo Pattern 3 (24-36s): Zigzag - back and forth movement
echo Pattern 4 (36-48s): Random - random positions
echo Pattern 5 (48-60s): Spiral - expanding spiral movement
echo.
echo WATCH YOUR GAME - You should see the test client moving around!
echo.
echo Make sure your server is running first!
echo.
pause
echo.
echo Starting 1-minute walking demo...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/WalkAroundDemo.tscn
pause