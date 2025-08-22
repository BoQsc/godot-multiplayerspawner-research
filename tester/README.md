# Multiplayer Test System

This folder contains a comprehensive **automated testing system** for the multiplayer game project, enabling real-world validation, performance monitoring, and continuous integration.

## Files Overview

### Core Testing System
- **`multi_client_tester.gd`** - Main multi-client testing system
- **`test_client.gd`** - Individual test client implementation
- **`test_launcher.gd`** - Test launcher and coordinator
- **`TestLauncher.tscn`** - Scene file for test launcher

### Automated Testing System
- **`automated_test_runner.gd`** - Automated test suites with validation and reporting
- **`run_automated_tests.bat`** - Automated testing script with multiple test types
- **`AUTOMATED_TESTING_GUIDE.md`** - Complete guide to automated testing benefits

### Problem Isolation & Debugging
- **`problem_isolator.gd`** - Isolate specific issues and collect detailed evidence
- **`evidence_analyzer.gd`** - Analyze collected evidence to identify root causes
- **`QUICK_USAGE_GUIDE.md`** - Quick reference for common testing scenarios
- **`bug_examples/`** - Example bug reproduction scenarios

### Configuration & Examples  
- **`run_tests.bat`** - Interactive testing script
- **`example_test_commands.txt`** - Example commands for manual testing
- **`.github_workflows_tests.yml`** - Example CI/CD configuration

## Quick Start

### **Interactive Testing**
```bash
# From project root
godot --headless tester/TestLauncher.tscn

# Or use the batch file
tester/run_tests.bat

# Basic testing flow:
start_server 4443
spawn_clients 3 127.0.0.1 4443
broadcast status
run_scenario basic_connection
```

### **Automated Testing** ⭐
```bash
# Quick smoke test (2 minutes)
run_automated_tests.bat smoke

# Full test suite (10 minutes) 
run_automated_tests.bat full

# Performance benchmarks
run_automated_tests.bat performance

# Continuous integration
godot --headless tester/TestLauncher.tscn --test-suite full --export-results json
```

## Available Commands

### Server Management
- `start_server [port]` - Start test server with server player
- `stop_server` - Stop the test server

### Client Management  
- `spawn_clients <count> [ip] [port]` - Spawn multiple test clients
- `stop_clients` - Stop all test clients
- `list_clients` - Show all active clients and server

### Individual Commands
- `client <id|server> <command>` - Send command to specific client or server
- `broadcast <command>` - Send command to all clients and server

### Test Scenarios
- `run_scenario <name>` - Run automated test scenario
- `list_scenarios` - Show available scenarios
- `results` - Show test results

## Test Scenarios

### `basic_connection`
Tests basic client connections and server setup.

### `movement_sync` 
Tests player movement synchronization between clients.

### `pickup_competition`
Tests pickup collection with multiple clients competing for items.

### `world_persistence`
Tests save/load functionality across clients.

### `stress_test`
Stress tests with multiple clients performing rapid actions.

## Example Usage

### Testing Server + Multiple Clients
```
# Start server with its own player
start_server 4443

# Spawn 2 test clients  
spawn_clients 2 127.0.0.1 4443

# Server spawns a pickup
client server spawn_pickup health_potion 150 150

# Client 0 moves to pickup
client 0 move 150 150

# Check world state from all perspectives
broadcast list_pickups
broadcast list_players
```

### Server Commands
The server acts as a special client with ID "server":
```
client server spawn_pickup health_potion 100 100
client server list_players
client server list_pickups  
client server status
```

### Automated Testing
```
# Run predefined scenarios
run_scenario movement_sync
run_scenario pickup_competition
run_scenario stress_test

# Check results
results
```

## Architecture

- **MultiClientTester** - Orchestrates multiple game instances
- **TestClient** - Individual client that can connect and interact
- **Server Instance** - Full game server with its own player
- **Command System** - Unified command interface for testing
- **Problem Isolator** - Isolates specific issues and collects evidence
- **Evidence Analyzer** - Analyzes collected evidence for root cause identification

## Key Features

### **Interactive Testing**
✅ **Multiple Clients** - Spawn up to 10 test clients simultaneously  
✅ **Server Player** - Server includes its own player instance  
✅ **Command Interface** - Send commands to individual clients or broadcast  
✅ **Automated Scenarios** - Predefined test scenarios for common cases  
✅ **Real-time Monitoring** - Live status and results tracking  
✅ **Headless Operation** - Runs without GUI for automated testing

### **Automated Testing** ⭐
✅ **Test Suites** - Smoke, full, regression, performance, stability tests  
✅ **Result Validation** - Automated assertions with pass/fail tracking  
✅ **Performance Metrics** - Connection times, update rates, memory usage  
✅ **Multiple Formats** - Export results as JSON, CSV, HTML reports  
✅ **CI/CD Ready** - Command-line interface for automated pipelines  
✅ **Issue Detection** - Catch multiplayer bugs before they reach users

### **Problem Isolation & Evidence Collection** 🔍
✅ **Targeted Issue Isolation** - Isolate specific problems (pickup desync, movement lag, etc.)  
✅ **Evidence Collection** - Detailed logging and state capture during issue reproduction  
✅ **Bug Reproduction** - Step-by-step reproduction from files for consistent testing  
✅ **Evidence Analysis** - Automated analysis of collected evidence to identify root causes  
✅ **Multiple Evidence Formats** - JSON, HTML, text exports for different use cases  
✅ **State Comparison** - Compare client states to detect inconsistencies  

## Problem Isolation & Evidence Collection

### **Isolate Specific Issues**
```bash
# Isolate pickup synchronization problems
isolate_problem pickup_desync

# Isolate movement lag issues
isolate_problem movement_lag

# Isolate connection stability problems  
isolate_problem connection_stability

# Isolate memory leaks
isolate_problem memory_leak

# Isolate race conditions
isolate_problem race_condition
```

### **Reproduce Known Bugs**
```bash
# Reproduce specific bug from steps file
reproduce_issue pickup_duplication_bug

# Compare states across all clients
compare_states

# Collect evidence for analysis
collect_evidence network
collect_evidence memory
collect_evidence state

# Export evidence for sharing
export_evidence html
```

### **Evidence Analysis**
Evidence is automatically analyzed to identify patterns and root causes:
- **Performance Issues**: Connection times, update delays, memory growth
- **Synchronization Problems**: State inconsistencies, timing issues
- **Network Issues**: Connection drops, packet loss, latency spikes
- **Resource Leaks**: Memory growth, object count increases

## Troubleshooting

**Clients not connecting:**
- Ensure server is started before spawning clients
- Check IP and port configuration
- Verify GameManager.tscn exists and is properly configured

**Commands not working:**
- Use `list_clients` to see active clients
- Check client IDs (0, 1, 2... or "server")
- Ensure proper command syntax

**Performance issues:**
- Limit concurrent clients (max 10 recommended)
- Add delays between rapid commands
- Monitor system resources during stress tests