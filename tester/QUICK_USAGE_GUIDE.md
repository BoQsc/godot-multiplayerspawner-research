# Quick Usage Guide - Multiplayer Tester

## 🚀 Getting Started (30 seconds)

### **Start Testing Immediately**
```bash
# Navigate to project folder
cd godot-multiplayerspawner-research

# Quick smoke test (2 minutes)
tester/run_automated_tests.bat smoke

# OR start interactive mode
tester/run_tests.bat
```

---

## 🎯 Most Common Use Cases

### **1. "Did I break multiplayer?" - Quick Check**
```bash
run_automated_tests.bat smoke
```
**✅ PASS** = You're good to commit  
**❌ FAIL** = Check the HTML report for details

### **2. "Is it ready for release?" - Full Validation**  
```bash
run_automated_tests.bat full
```
**Result**: Complete 10-minute validation of all systems

### **3. "This bug is weird" - Problem Isolation**
```bash
# Start interactive tester
tester/run_tests.bat

# In tester, isolate specific issues:
isolate_problem pickup_desync
isolate_problem movement_lag
isolate_problem race_condition
```

### **4. "How fast is it?" - Performance Check**
```bash
run_automated_tests.bat performance
```
**Result**: Benchmarks connection time, update rates, memory usage

### **5. "Will it crash overnight?" - Stability Test**
```bash
run_automated_tests.bat stability
```
**Result**: 30-minute continuous stress test

---

## 🔧 Interactive Commands (Quick Reference)

### **Server & Clients**
```bash
start_server 4443                 # Start test server
spawn_clients 3 127.0.0.1 4443    # Spawn 3 test clients
list_clients                      # Show all active instances
```

### **Testing Actions**
```bash
client 0 move 100 100             # Move client 0
client server spawn_pickup health_potion 150 150  # Server spawns item
broadcast list_players            # All instances show players
broadcast status                  # Check all instance status
```

### **Problem Isolation**
```bash
isolate_problem pickup_desync     # Isolate pickup sync issues
isolate_problem movement_lag      # Isolate movement delays
collect_evidence network          # Collect network evidence
compare_states                    # Compare all client states
export_evidence html              # Export evidence as HTML report
```

### **Automated Scenarios**
```bash
run_scenario basic_connection     # Test connections
run_scenario movement_sync        # Test movement sync
run_scenario pickup_competition   # Test pickup collection
run_scenario stress_test          # Stress test
```

---

## 🔍 Problem Isolation Guide

### **When Things Go Wrong**

**Symptom**: Players don't see each other's movement
```bash
isolate_problem movement_lag
```

**Symptom**: Multiple players collect same item
```bash
isolate_problem pickup_desync
```

**Symptom**: Clients randomly disconnect
```bash
isolate_problem connection_stability
```

**Symptom**: Memory usage keeps growing
```bash
isolate_problem memory_leak
```

**Symptom**: Weird timing-related bugs
```bash
isolate_problem race_condition
```

### **Evidence Collection**
```bash
collect_evidence network          # Network events and latency
collect_evidence memory           # Memory usage patterns
collect_evidence state            # World state snapshots
collect_evidence performance      # Performance metrics
collect_evidence logs             # Detailed operation logs
```

---

## 📊 Understanding Results

### **Test Results Files** (saved to `%APPDATA%\Godot\app_userdata\godot-multiplayerspawner-research\`)

**JSON** (for scripts/CI):
```json
{
  "assertions_passed": 47,
  "assertions_failed": 2,
  "performance_metrics": {
    "connection_time_5_clients": 3.2,
    "movement_update_time": 0.45
  }
}
```

**HTML** (for humans):
- Visual dashboard with pass/fail status
- Performance charts
- Detailed logs with timestamps
- Evidence collection summaries

### **What to Look For**

**✅ Good Results**:
- All assertions passed
- Connection time < 5 seconds
- Movement updates < 100ms
- Memory stable over time

**❌ Problems**:
- Failed assertions (specific issues found)
- Connection time > 5 seconds (performance issue)
- Movement updates > 200ms (sync problems)
- Memory growing over time (memory leak)

---

## 🚦 Workflow Integration

### **Before Committing Code**
```bash
run_automated_tests.bat smoke     # 2-minute validation
```

### **Before Merging PR**
```bash
run_automated_tests.bat full      # 10-minute full validation
```

### **Before Release**
```bash
run_automated_tests.bat full
run_automated_tests.bat stability
```

### **When Debugging Issues**
```bash
# Start interactive mode
tester/run_tests.bat

# Isolate the specific problem
isolate_problem <issue_type>

# Collect evidence
export_evidence html

# Share HTML report with team
```

---

## 🎯 CI/CD Integration

### **GitHub Actions Example**
```yaml
- name: Test Multiplayer
  run: godot --headless tester/TestLauncher.tscn --test-suite full --export-results json
```

### **Local Pre-commit Hook**
```bash
#!/bin/bash
cd path/to/project
./tester/run_automated_tests.bat smoke
if [ $? -ne 0 ]; then
  echo "Multiplayer tests failed - commit blocked"
  exit 1
fi
```

---

## 🆘 Troubleshooting

### **"Tests won't start"**
- Check if Godot is in PATH
- Verify you're in project root directory
- Run simple validation first: `tester/run_simple_test.bat`
- Ensure main_scene.tscn exists (or Main.tscn)

### **"Clients won't connect"**
- Server must start before clients (automatic in test suites)
- Check firewall settings for port 4443
- Try different port: `start_server 4444`

### **"Tests are slow"**
- Normal: smoke (2min), full (10min), stability (30min)
- Slow machine: Add delays in test scripts
- Network issues: Check localhost connectivity

### **"Can't find results"**
- Windows: `%APPDATA%\Godot\app_userdata\godot-multiplayerspawner-research\`
- Linux: `~/.local/share/godot/app_userdata/godot-multiplayerspawner-research/`
- Look for: `test_results_*.json`, `test_report_*.html`

---

## ⚡ Power User Tips

### **Custom Problem Reproduction**
```bash
# Save failing steps to file
echo "start_server
spawn_clients 2
client 0 move 100 100
client 1 move 100 100
client server spawn_pickup health_potion 100 100" > user://my_bug.txt

# Reproduce exactly
reproduce_issue my_bug
```

### **Continuous Monitoring**
```bash
# Run validation every 30 minutes
run_automated_tests.bat continuous 30
```

### **Performance Baseline**
```bash
# Establish baseline
run_automated_tests.bat performance > baseline.txt

# Compare later
run_automated_tests.bat performance > current.txt
# Compare baseline.txt vs current.txt
```

### **Evidence Collection**
```bash
# Enable detailed tracing
network_trace
memory_profile

# Run problematic scenario
isolate_problem pickup_desync

# Export comprehensive evidence
export_evidence html
```

---

## 🎉 You're Ready!

**Most users need only**:
- `tester/run_simple_test.bat` (validate setup)
- `run_automated_tests.bat smoke` (before commits)
- `run_automated_tests.bat full` (before releases)  
- `isolate_problem <type>` (when debugging)

**Everything else is bonus features for power users and CI/CD integration.**

Happy testing! 🎮✨