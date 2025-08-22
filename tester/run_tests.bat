@echo off
echo === Multiplayer Test System ===
echo.
echo This will launch the multiplayer testing system.
echo You can run multiple test clients and scenarios.
echo.
echo Available test scenarios:
echo - basic_connection: Test client connections
echo - movement_sync: Test player movement synchronization
echo - pickup_competition: Test pickup collection between clients
echo - world_persistence: Test save/load functionality  
echo - stress_test: Stress test with multiple rapid actions
echo.
echo Commands you can use:
echo - start_server [port]: Start test server
echo - spawn_clients ^<count^> [ip] [port]: Spawn multiple clients
echo - run_scenario ^<name^>: Run test scenario
echo - broadcast ^<command^>: Send command to all clients
echo - client ^<id^> ^<command^>: Send command to specific client
echo.
pause
echo.
echo Starting test system...
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tester/TestLauncher.tscn