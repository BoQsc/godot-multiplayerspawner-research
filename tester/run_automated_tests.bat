@echo off
setlocal enabledelayedexpansion

echo === Automated Multiplayer Testing Suite ===
echo.

if "%1"=="" (
    echo Usage: run_automated_tests.bat [test_type] [options]
    echo.
    echo Test Types:
    echo   smoke      - Quick smoke test ^(~2 minutes^)
    echo   full       - Complete test suite ^(~10 minutes^)  
    echo   regression - Regression tests ^(~5 minutes^)
    echo   performance - Performance benchmarks ^(~3 minutes^)
    echo   stability  - Long stability test ^(~30 minutes^)
    echo   continuous - Continuous testing ^(specify duration^)
    echo.
    echo Examples:
    echo   run_automated_tests.bat smoke
    echo   run_automated_tests.bat full
    echo   run_automated_tests.bat continuous 60
    echo.
    exit /b 1
)

set TEST_TYPE=%1
set DURATION=%2

echo Starting %TEST_TYPE% test...
echo Timestamp: %date% %time%
echo.

if "%TEST_TYPE%"=="smoke" (
    echo Running quick smoke test...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --test-suite smoke --export-results json
) else if "%TEST_TYPE%"=="full" (
    echo Running complete test suite...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --test-suite full --export-results json
) else if "%TEST_TYPE%"=="regression" (
    echo Running regression tests...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --test-suite regression --export-results json
) else if "%TEST_TYPE%"=="performance" (
    echo Running performance benchmarks...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --performance-test --export-results json
) else if "%TEST_TYPE%"=="stability" (
    echo Running stability test...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --test-suite stability --export-results json
) else if "%TEST_TYPE%"=="continuous" (
    if "%DURATION%"=="" (
        echo ERROR: Duration required for continuous test
        echo Usage: run_automated_tests.bat continuous [minutes]
        exit /b 1
    )
    echo Running continuous test for %DURATION% minutes...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --continuous-test %DURATION% --export-results json
) else if "%TEST_TYPE%"=="validate" (
    echo Running multiplayer validation...
    "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn --validate-multiplayer --export-results json
) else (
    echo ERROR: Unknown test type '%TEST_TYPE%'
    exit /b 1
)

echo.
echo Test completed at: %date% %time%
echo.
echo Test results saved to: %APPDATA%\Godot\app_userdata\godot-multiplayerspawner-research\
echo Look for files: test_results_*.json, test_report_*.txt, test_report_*.html
echo.
pause