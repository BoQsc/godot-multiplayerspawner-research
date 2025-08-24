extends Node
class_name EvidenceAnalyzer

# Evidence Analysis Tool
# Analyzes collected evidence to identify patterns and root causes

func analyze_evidence_file(filepath: String) -> Dictionary:
	"""Analyze evidence file and return insights"""
	var analysis_results = {
		"file_analyzed": filepath,
		"timestamp": Time.get_datetime_string_from_system(),
		"insights": [],
		"recommendations": [],
		"severity": "unknown"
	}
	
	if not FileAccess.file_exists(filepath):
		analysis_results.insights.append("ERROR: Evidence file not found")
		return analysis_results
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# Try to parse as JSON first
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result == OK:
		var evidence_data = json.data
		_analyze_structured_evidence(evidence_data, analysis_results)
	else:
		# Fallback to text analysis
		_analyze_text_evidence(content, analysis_results)
	
	return analysis_results

func _analyze_structured_evidence(evidence_data: Dictionary, results: Dictionary):
	"""Analyze structured JSON evidence"""
	results.insights.append("Analyzing structured evidence data...")
	
	# Check for test type
	if evidence_data.has("isolation_test"):
		_analyze_isolation_test(evidence_data, results)
	elif evidence_data.has("test_suite"):
		_analyze_test_suite(evidence_data, results)
	
	# Analyze performance metrics
	if evidence_data.has("performance_metrics"):
		_analyze_performance_metrics(evidence_data.performance_metrics, results)
	
	# Analyze evidence collection
	if evidence_data.has("evidence"):
		_analyze_collected_evidence(evidence_data.evidence, results)
	
	# Analyze logs
	if evidence_data.has("detailed_logs"):
		_analyze_logs(evidence_data.detailed_logs, results)

func _analyze_isolation_test(evidence_data: Dictionary, results: Dictionary):
	"""Analyze isolation test results"""
	var test_type = evidence_data.get("isolation_test", "unknown")
	results.insights.append("Isolation test type: " + test_type)
	
	match test_type:
		"pickup_desync":
			_analyze_pickup_desync(evidence_data, results)
		"movement_lag":
			_analyze_movement_lag(evidence_data, results)
		"connection_stability":
			_analyze_connection_stability(evidence_data, results)
		"memory_leak":
			_analyze_memory_leak(evidence_data, results)
		"race_condition":
			_analyze_race_condition(evidence_data, results)

func _analyze_test_suite(evidence_data: Dictionary, results: Dictionary):
	"""Analyze test suite results"""
	var passed = evidence_data.get("assertions_passed", 0)
	var failed = evidence_data.get("assertions_failed", 0)
	var total = passed + failed
	
	if total > 0:
		var success_rate = (passed * 100.0) / total
		results.insights.append("Test success rate: " + str(success_rate) + "% (" + str(passed) + "/" + str(total) + ")")
		
		if success_rate < 70:
			results.severity = "critical"
			results.recommendations.append("CRITICAL: Test success rate below 70% - investigate immediately")
		elif success_rate < 90:
			results.severity = "warning"
			results.recommendations.append("WARNING: Test success rate below 90% - review failing tests")
		else:
			results.severity = "good"
			results.insights.append("Good test success rate")

func _analyze_performance_metrics(metrics: Dictionary, results: Dictionary):
	"""Analyze performance metrics"""
	results.insights.append("--- Performance Analysis ---")
	
	# Connection time analysis
	if metrics.has("connection_time_5_clients"):
		var conn_time = metrics.connection_time_5_clients
		if conn_time > 10.0:
			results.severity = _max_severity(results.severity, "critical")
			results.recommendations.append("CRITICAL: Connection time " + str(conn_time) + "s is too slow (>10s)")
		elif conn_time > 5.0:
			results.severity = _max_severity(results.severity, "warning")  
			results.recommendations.append("WARNING: Connection time " + str(conn_time) + "s is slow (>5s)")
		else:
			results.insights.append("Good connection time: " + str(conn_time) + "s")
	
	# Movement update analysis
	if metrics.has("movement_update_time"):
		var update_time = metrics.movement_update_time
		if update_time > 1.0:
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: Movement updates taking " + str(update_time) + "s (>1s)")
		else:
			results.insights.append("Good movement update time: " + str(update_time) + "s")
	
	# Memory analysis
	if metrics.has("memory_growth"):
		var growth = metrics.memory_growth
		if growth > 1000000:  # 1MB growth
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: Memory growth detected: " + str(growth) + " bytes")
		elif growth > 0:
			results.insights.append("Minor memory growth: " + str(growth) + " bytes")
		else:
			results.insights.append("No memory growth detected")

func _analyze_collected_evidence(evidence: Dictionary, results: Dictionary):
	"""Analyze collected evidence"""
	results.insights.append("--- Evidence Analysis ---")
	
	# Client state analysis
	if evidence.has("client_states"):
		var states = evidence.client_states
		var connected_count = 0
		var total_count = 0
		
		for client_id in states:
			total_count += 1
			if states[client_id].get("connected", false):
				connected_count += 1
		
		if connected_count < total_count:
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: " + str(total_count - connected_count) + " clients disconnected")
		else:
			results.insights.append("All " + str(total_count) + " clients connected")
	
	# Pickup state analysis
	if evidence.has("pickup_collection_verified"):
		var verified = evidence.pickup_collection_verified
		if verified:
			results.insights.append("Pickup collection verified successfully")
		else:
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: Pickup collection verification failed")

func _analyze_logs(logs: Array, results: Dictionary):
	"""Analyze log entries for patterns"""
	results.insights.append("--- Log Analysis ---")
	
	var error_count = 0
	var warning_count = 0
	var connection_issues = 0
	var sync_issues = 0
	
	for log_entry in logs:
		var entry_str = str(log_entry).to_lower()
		
		if "error" in entry_str:
			error_count += 1
		elif "warning" in entry_str:
			warning_count += 1
		
		if "connection" in entry_str and ("failed" in entry_str or "timeout" in entry_str):
			connection_issues += 1
		
		if "sync" in entry_str or "desync" in entry_str:
			sync_issues += 1
	
	# Report findings
	if error_count > 0:
		results.severity = _max_severity(results.severity, "critical")
		results.recommendations.append("CRITICAL: " + str(error_count) + " errors found in logs")
	
	if warning_count > 5:
		results.severity = _max_severity(results.severity, "warning")
		results.recommendations.append("WARNING: " + str(warning_count) + " warnings found in logs")
	
	if connection_issues > 0:
		results.severity = _max_severity(results.severity, "warning")
		results.recommendations.append("WARNING: " + str(connection_issues) + " connection issues detected")
	
	if sync_issues > 0:
		results.severity = _max_severity(results.severity, "warning")
		results.recommendations.append("WARNING: " + str(sync_issues) + " synchronization issues detected")
	
	if error_count == 0 and warning_count <= 2:
		results.insights.append("Clean logs - no significant issues found")

# Specific test analysis methods
func _analyze_pickup_desync(evidence_data: Dictionary, results: Dictionary):
	"""Analyze pickup desynchronization evidence"""
	results.insights.append("Analyzing pickup desynchronization...")
	
	var evidence = evidence_data.get("evidence", {})
	
	if evidence.has("pickup_collection_verified"):
		if not evidence.pickup_collection_verified:
			results.severity = "critical"
			results.recommendations.append("CRITICAL: Pickup desync confirmed - multiple clients collected same item")
		else:
			results.insights.append("Pickup collection working correctly")

func _analyze_movement_lag(evidence_data: Dictionary, results: Dictionary):
	"""Analyze movement lag evidence"""
	results.insights.append("Analyzing movement synchronization lag...")
	
	var evidence = evidence_data.get("evidence", {})
	
	if evidence.has("rapid_movement_duration"):
		var duration = evidence.rapid_movement_duration
		if duration > 2000:  # 2 seconds for rapid movements
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: Movement updates taking too long: " + str(duration) + "ms")
		else:
			results.insights.append("Movement update times acceptable: " + str(duration) + "ms")

func _analyze_connection_stability(evidence_data: Dictionary, results: Dictionary):
	"""Analyze connection stability evidence"""
	results.insights.append("Analyzing connection stability...")
	
	var evidence = evidence_data.get("evidence", {})
	
	if evidence.has("disconnected_client_id"):
		results.insights.append("Disconnection test performed on client " + str(evidence.disconnected_client_id))
	
	if evidence.has("state_recovery_verification_time"):
		results.insights.append("State recovery test completed")

func _analyze_memory_leak(evidence_data: Dictionary, results: Dictionary):
	"""Analyze memory leak evidence"""
	results.insights.append("Analyzing memory usage patterns...")
	
	var evidence = evidence_data.get("evidence", {})
	
	if evidence.has("memory_growth"):
		var growth = evidence.memory_growth
		if growth > 10000000:  # 10MB growth
			results.severity = "critical"
			results.recommendations.append("CRITICAL: Significant memory leak detected: " + str(growth) + " bytes")
		elif growth > 1000000:  # 1MB growth
			results.severity = _max_severity(results.severity, "warning")
			results.recommendations.append("WARNING: Possible memory leak: " + str(growth) + " bytes")
		else:
			results.insights.append("Memory usage stable: " + str(growth) + " bytes growth")

func _analyze_race_condition(evidence_data: Dictionary, results: Dictionary):
	"""Analyze race condition evidence"""
	results.insights.append("Analyzing race condition patterns...")
	
	var evidence = evidence_data.get("evidence", {})
	
	if evidence.has("simultaneous_action_time"):
		results.insights.append("Simultaneous action test performed")
	
	if evidence.has("consistency_check_time"):
		results.insights.append("State consistency verification completed")

func _analyze_text_evidence(content: String, results: Dictionary):
	"""Analyze plain text evidence"""
	results.insights.append("Analyzing text evidence...")
	
	var lines = content.split("\n")
	var error_patterns = ["ERROR", "FAIL", "❌"]
	var warning_patterns = ["WARNING", "WARN", "⚠️"]
	var success_patterns = ["PASS", "✅", "SUCCESS"]
	
	var errors = 0
	var warnings = 0
	var successes = 0
	
	for line in lines:
		for pattern in error_patterns:
			if pattern in line:
				errors += 1
				break
		for pattern in warning_patterns:
			if pattern in line:
				warnings += 1
				break
		for pattern in success_patterns:
			if pattern in line:
				successes += 1
				break
	
	if errors > 0:
		results.severity = "critical"
		results.recommendations.append("CRITICAL: " + str(errors) + " errors found")
	elif warnings > 3:
		results.severity = "warning"
		results.recommendations.append("WARNING: " + str(warnings) + " warnings found")
	else:
		results.severity = "good"
	
	results.insights.append("Text analysis: " + str(successes) + " successes, " + str(warnings) + " warnings, " + str(errors) + " errors")

func _max_severity(current: String, new: String) -> String:
	"""Return the more severe severity level"""
	var severity_levels = {"good": 0, "warning": 1, "critical": 2, "unknown": -1}
	
	var current_level = severity_levels.get(current, -1)
	var new_level = severity_levels.get(new, -1)
	
	if new_level > current_level:
		return new
	else:
		return current

func generate_analysis_report(analysis_results: Dictionary) -> String:
	"""Generate human-readable analysis report"""
	var report = "=== EVIDENCE ANALYSIS REPORT ===\n"
	report += "File: " + analysis_results.get("file_analyzed", "unknown") + "\n"
	report += "Analysis Date: " + analysis_results.get("timestamp", "unknown") + "\n"
	report += "Severity: " + analysis_results.get("severity", "unknown").to_upper() + "\n"
	report += "\n--- INSIGHTS ---\n"
	
	var insights = analysis_results.get("insights", [])
	for insight in insights:
		report += "• " + insight + "\n"
	
	report += "\n--- RECOMMENDATIONS ---\n"
	var recommendations = analysis_results.get("recommendations", [])
	if recommendations.is_empty():
		report += "• No specific recommendations\n"
	else:
		for recommendation in recommendations:
			report += "• " + recommendation + "\n"
	
	report += "\n=== END ANALYSIS ===\n"
	return report

func export_analysis(analysis_results: Dictionary, format: String = "txt"):
	"""Export analysis results to file"""
	var timestamp = str(Time.get_ticks_msec())
	var filename_base = "user://analysis_" + timestamp
	
	match format:
		"json":
			var file = FileAccess.open(filename_base + ".json", FileAccess.WRITE)
			file.store_string(JSON.stringify(analysis_results))
			file.close()
			print("Analysis exported to JSON: " + filename_base + ".json")
		
		"txt", _:
			var report = generate_analysis_report(analysis_results)
			var file = FileAccess.open(filename_base + ".txt", FileAccess.WRITE)
			file.store_string(report)
			file.close()
			print("Analysis exported to text: " + filename_base + ".txt")