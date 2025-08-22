@echo off
echo === Quick Join Test ===
echo.
echo Testing connection to your local server...
echo.

REM Try to run minimal test first
echo Running minimal test to check if Godot works...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --version

echo.
echo If that worked, now testing with minimal tester...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --quit-after 5000 tester/MinimalTester.tscn

echo.
echo Test completed. Check output above for any errors.