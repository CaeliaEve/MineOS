-------------------------------------------------------------------------------
-- MineOS Optimization Testing Script
-- Tests all performance optimizations and backward compatibility
-------------------------------------------------------------------------------

local testResults = {
	passed = 0,
	failed = 0,
	tests = {}
}

local function test(name, testFn)
	print(string.format("Testing: %s...", name))
	local success, err = pcall(testFn)

	if success then
		testResults.passed = testResults.passed + 1
		table.insert(testResults.tests, {name = name, status = "PASS"})
		print("✓ PASS")
	else
		testResults.failed = testResults.failed + 1
		table.insert(testResults.tests, {name = name, status = "FAIL", error = err})
		print(string.format("✗ FAIL: %s", tostring(err)))
	end
	print()
end

-------------------------------------------------------------------------------
-- Test 1: Error Module Loading
-------------------------------------------------------------------------------

test("Error module loads successfully", function()
	local Error = require("Error")
	assert(Error ~= nil, "Error module is nil")
	assert(Error.parseTraceback ~= nil, "parseTraceback function missing")
	assert(Error.classify ~= nil, "classify function missing")
end)

-------------------------------------------------------------------------------
-- Test 2: Error Traceback Parsing (Multiple Strategies)
-------------------------------------------------------------------------------

test("Error parsing - Strategy 1 (standard traceback)", function()
	local Error = require("Error")
	local traceback = "\tLibraries/System.lua:123: error message here"
	local result = Error.parseTraceback(traceback)

	assert(result ~= nil, "Parse result is nil")
	assert(result.path == "Libraries/System.lua", "Path mismatch")
	assert(result.line == 123, "Line mismatch")
end)

test("Error parsing - Strategy 2 (flexible pattern)", function()
	local Error = require("Error")
	local traceback = "some/path/to/file.lua:456:some error"
	local result = Error.parseTraceback(traceback)

	assert(result ~= nil, "Parse result is nil")
	assert(result.path ~= nil, "Path is nil")
end)

test("Error parsing - Strategy 5 (fallback always works)", function()
	local Error = require("Error")
	local traceback = "totally invalid traceback without .lua extension"
	local result = Error.parseTraceback(traceback)

	assert(result ~= nil, "Fallback should always return a result")
	assert(result.path == "unknown", "Fallback should return unknown path")
end)

-------------------------------------------------------------------------------
-- Test 3: Error Classification
-------------------------------------------------------------------------------

test("Error classification - syntax errors", function()
	local Error = require("Error")
	local errorType = Error.classify("syntax error near 'end'")

	assert(errorType == Error.ErrorTypes.SYNTAX, "Should classify as syntax error")
end)

test("Error classification - filesystem errors", function()
	local Error = require("Error")
	local errorType = Error.classify("file not found: /path/to/file")

	assert(errorType == Error.ErrorTypes.FILESYSTEM, "Should classify as filesystem error")
end)

test("Error classification - network errors", function()
	local Error = require("Error")
	local errorType = Error.classify("connection timeout")

	assert(errorType == Error.ErrorTypes.NETWORK, "Should classify as network error")
end)

-------------------------------------------------------------------------------
-- Test 4: Dirty Rectangle Module Loading
-------------------------------------------------------------------------------

test("DirtyRect module loads successfully", function()
	local DirtyRect = require("GUI.DirtyRect")
	assert(DirtyRect ~= nil, "DirtyRect module is nil")
	assert(DirtyRect.markDirty ~= nil, "markDirty function missing")
	assert(DirtyRect.markRegion ~= nil, "markRegion function missing")
end)

-------------------------------------------------------------------------------
-- Test 5: Dirty Rectangle Region Tracking
-------------------------------------------------------------------------------

test("Dirty rectangle - mark and merge regions", function()
	local DirtyRect = require("GUI.DirtyRect")
	DirtyRect.clear()

	-- Mark some regions
	DirtyRect.markRegion(1, 1, 10, 10)
	DirtyRect.markRegion(15, 15, 5, 5)

	local regions = DirtyRect.mergeRegions()
	assert(regions ~= nil, "Should have dirty regions")
	assert(#regions >= 1, "Should have at least one region")

	DirtyRect.clear()
end)

test("Dirty rectangle - auto-merge overlapping regions", function()
	local DirtyRect = require("GUI.DirtyRect")
	DirtyRect.clear()

	-- Mark overlapping regions (should merge)
	DirtyRect.markRegion(1, 1, 10, 10)
	DirtyRect.markRegion(5, 5, 10, 10)

	local regions = DirtyRect.mergeRegions()
	assert(regions ~= nil, "Should have dirty regions")
	assert(#regions == 1, "Should merge into one region")

	DirtyRect.clear()
end)

-------------------------------------------------------------------------------
-- Test 6: Dirty Rectangle Statistics
-------------------------------------------------------------------------------

test("Dirty rectangle - statistics tracking", function()
	local DirtyRect = require("GUI.DirtyRect")
	DirtyRect.resetStats()
	DirtyRect.clear()

	-- Perform some operations
	DirtyRect.markRegion(1, 1, 10, 10)
	local stats = DirtyRect.getStats()

	assert(stats ~= nil, "Stats should not be nil")
	assert(type(stats.totalDraws) == "number", "totalDraws should be number")
	assert(type(stats.fullRedraws) == "number", "fullRedraws should be number")

	DirtyRect.clear()
end)

-------------------------------------------------------------------------------
-- Test 7: Quadtree Module Loading
-------------------------------------------------------------------------------

test("Quadtree module loads successfully", function()
	local Quadtree = require("GUI.Quadtree")
	assert(Quadtree ~= nil, "Quadtree module is nil")
	assert(Quadtree.new ~= nil, "new function missing")
end)

-------------------------------------------------------------------------------
-- Test 8: Quadtree Creation and Insertion
-------------------------------------------------------------------------------

test("Quadtree - create and insert objects", function()
	local Quadtree = require("GUI.Quadtree")
	local qt = Quadtree.new(0, 0, 100, 100)

	assert(qt ~= nil, "Quadtree should not be nil")
	assert(qt.x == 0, "X coordinate should be 0")
	assert(qt.y == 0, "Y coordinate should be 0")
	assert(qt.width == 100, "Width should be 100")
	assert(qt.height == 100, "Height should be 100")

	-- Insert test object
	local obj = {x = 10, y = 10, width = 5, height = 5}
	local success = qt:insert(obj)

	assert(success == true, "Insert should succeed")
	assert(qt.objectCount == 1, "Should have 1 object")
end)

-------------------------------------------------------------------------------
-- Test 9: Quadtree Point Queries
-------------------------------------------------------------------------------

test("Quadtree - point query returns objects", function()
	local Quadtree = require("GUI.Quadtree")
	local qt = Quadtree.new(0, 0, 100, 100)

	-- Insert test objects
	qt:insert({x = 10, y = 10, width = 5, height = 5, id = "obj1"})
	qt:insert({x = 50, y = 50, width = 10, height = 10, id = "obj2"})

	-- Query point that should hit first object
	local results = qt:query(12, 12)

	assert(results ~= nil, "Results should not be nil")
	assert(#results >= 1, "Should find at least one object")
end)

test("Quadtree - point query misses objects", function()
	local Quadtree = require("GUI.Quadtree")
	local qt = Quadtree.new(0, 0, 100, 100)

	-- Insert test object
	qt:insert({x = 10, y = 10, width = 5, height = 5, id = "obj1"})

	-- Query point that should miss
	local results = qt:query(50, 50)

	assert(#results == 0, "Should not find any objects")
end)

-------------------------------------------------------------------------------
-- Test 10: Quadtree Statistics
-------------------------------------------------------------------------------

test("Quadtree - statistics", function()
	local Quadtree = require("GUI.Quadtree")
	local qt = Quadtree.new(0, 0, 100, 100)

	-- Insert some objects
	for i = 1, 5 do
		qt:insert({x = i * 10, y = i * 10, width = 5, height = 5})
	end

	local stats = qt:getStats()
	assert(stats ~= nil, "Stats should not be nil")
	assert(stats.totalObjects >= 5, "Should have at least 5 objects")
	assert(stats.nodeCount >= 1, "Should have at least 1 node")
end)

-------------------------------------------------------------------------------
-- Test 11: ObjectPool Module Loading
-------------------------------------------------------------------------------

test("ObjectPool module loads successfully", function()
	local ObjectPool = require("GUI.ObjectPool")
	assert(ObjectPool ~= nil, "ObjectPool module is nil")
	assert(ObjectPool.registerFactory ~= nil, "registerFactory function missing")
	assert(ObjectPool.acquire ~= nil, "acquire function missing")
	assert(ObjectPool.release ~= nil, "release function missing")
end)

-------------------------------------------------------------------------------
-- Test 12: ObjectPool Factory Registration
-------------------------------------------------------------------------------

test("ObjectPool - register and use factory", function()
	local ObjectPool = require("GUI.ObjectPool")

	-- Register a simple factory
	ObjectPool.registerFactory("test", function(x, y)
		return {x = x, y = y, id = "test"}
	end, function(obj, x, y)
		obj.x = x
		obj.y = y
	end)

	-- Acquire object
	local obj1 = ObjectPool.acquire("test", 10, 20)
	assert(obj1 ~= nil, "Should acquire object")
	assert(obj1.x == 10, "X should be 10")
	assert(obj1.y == 20, "Y should be 20")

	-- Release object
	local released = ObjectPool.release("test", obj1)
	assert(released == true, "Should release successfully")

	-- Acquire again (should reuse)
	local obj2 = ObjectPool.acquire("test", 30, 40)
	assert(obj2 ~= nil, "Should acquire from pool")

	ObjectPool.clearPool("test")
end)

-------------------------------------------------------------------------------
-- Test 13: ObjectPool Statistics
-------------------------------------------------------------------------------

test("ObjectPool - statistics tracking", function()
	local ObjectPool = require("GUI.ObjectPool")
	ObjectPool.resetStats()
	ObjectPool.clearAll()

	-- Register factory
	ObjectPool.registerFactory("statTest", function()
		return {id = "statTest"}
	end)

	-- Perform operations
	local obj = ObjectPool.acquire("statTest")
	ObjectPool.release("statTest", obj)

	local stats = ObjectPool.getStats()
	assert(stats ~= nil, "Stats should not be nil")
	assert(stats.totalAcquire >= 1, "Should have at least 1 acquire")
	assert(stats.totalRelease >= 1, "Should have at least 1 release")

	ObjectPool.clearPool("statTest")
end)

-------------------------------------------------------------------------------
-- Test 14: Config Module Loading
-------------------------------------------------------------------------------

test("Config module loads successfully", function()
	local Config = require("Config")
	assert(Config ~= nil, "Config module is nil")
	assert(Config.registerSchema ~= nil, "registerSchema function missing")
	assert(Config.load ~= nil, "load function missing")
	assert(Config.validate ~= nil, "validate function missing")
end)

-------------------------------------------------------------------------------
-- Test 15: Config Schema Registration
-------------------------------------------------------------------------------

test("Config - register and use schema", function()
	local Config = require("Config")

	-- Register test schema
	local schemaName = "testSchema"
	Config.registerSchema(schemaName, {
		latestVersion = 1,
		defaults = {
			version = 1,
			testValue = 42,
			testString = "hello"
		},
		types = {
			testValue = "integer",
			testString = "string"
		}
	})

	-- Create default config
	local config = Config.createDefault(schemaName)
	assert(config ~= nil, "Config should not be nil")
	assert(config.testValue == 42, "testValue should be 42")
	assert(config.testString == "hello", "testString should be 'hello'")
end)

-------------------------------------------------------------------------------
-- Test 16: Config Validation
-------------------------------------------------------------------------------

test("Config - validate configuration", function()
	local Config = require("Config")

	-- Register test schema
	Config.registerSchema("validateTest", {
		defaults = {value = 10},
		types = {value = "integer"},
		ranges = {value = {min = 1, max = 100}}
	})

	-- Valid config
	local valid, err = Config.validate({value = 50}, "validateTest")
	assert(valid == true, "Should validate successfully")

	-- Invalid type
	valid, err = Config.validate({value = "not a number"}, "validateTest")
	assert(valid == false, "Should fail type validation")

	-- Invalid range
	valid, err = Config.validate({value = 150}, "validateTest")
	assert(valid == false, "Should fail range validation")
end)

-------------------------------------------------------------------------------
-- Test 17: Log Module Loading
-------------------------------------------------------------------------------

test("Log module loads successfully", function()
	local Log = require("Log")
	assert(Log ~= nil, "Log module is nil")
	assert(Log.info ~= nil, "info function missing")
	assert(Log.error ~= nil, "error function missing")
	assert(Log.setLevel ~= nil, "setLevel function missing")
end)

-------------------------------------------------------------------------------
-- Test 18: Log Level Filtering
-------------------------------------------------------------------------------

test("Log - level filtering works", function()
	local Log = require("Log")

	-- Set to ERROR level
	Log.setLevel(Log.levels.ERROR)

	-- These should not output (filtered)
	Log.debug("Debug message")
	Log.info("Info message")
	Log.warn("Warning message")

	-- This should output
	-- Note: We can't easily test console output, so just test no crash
	local success, err = pcall(Log.error, "Error message")
	assert(success == true, "Should log error without crashing")
end)

-------------------------------------------------------------------------------
-- Test 19: Log Format Entry
-------------------------------------------------------------------------------

test("Log - format entry", function()
	local Log = require("Log")

	local entry = Log.formatEntry(Log.levels.INFO, "Test message", {key = "value"})
	assert(type(entry) == "string", "Entry should be string")
	assert(entry:find("Test message") ~= nil, "Entry should contain message")
	assert(entry:find("key=value") ~= nil, "Entry should contain context")
end)

-------------------------------------------------------------------------------
-- Test 20: Backward Compatibility
-------------------------------------------------------------------------------

test("Backward compatibility - GUI module loads", function()
	local GUI = require("GUI")
	assert(GUI ~= nil, "GUI module is nil")
	assert(GUI.button ~= nil, "button function missing")
	assert(GUI.label ~= nil, "label function missing")
	assert(GUI.workspace ~= nil, "workspace function missing")
end)

test("Backward compatibility - create basic GUI objects", function()
	local GUI = require("GUI")

	-- Create button
	local button = GUI.button(1, 1, 20, 3, 0xCCCCCC, 0x000000, "Test")
	assert(button ~= nil, "Button should be created")
	assert(button.x == 1, "Button X should be 1")

	-- Create label
	local label = GUI.label(1, 5, 20, 1, 0xFFFFFF, "Label")
	assert(label ~= nil, "Label should be created")

	-- Create panel
	local panel = GUI.panel(1, 7, 20, 5, 0x000000, 0.5)
	assert(panel ~= nil, "Panel should be created")
end)

-------------------------------------------------------------------------------
-- Test 21: System Module Integration
-------------------------------------------------------------------------------

test("System module - uses Error module", function()
	local system = require("System")
	assert(system ~= nil, "System module is nil")
	assert(system.call ~= nil, "system.call function missing")

	-- Test that Error module is integrated (no crashes)
	local success, err = pcall(system.call, function() return "test" end)
	assert(success == true, "system.call should work")
end)

-------------------------------------------------------------------------------
-- Test 22: GUI Performance Interface
-------------------------------------------------------------------------------

test("GUI performance - interface exists", function()
	local GUI = require("GUI")
	assert(GUI.performance ~= nil, "GUI.performance should exist")
	assert(GUI.performance.enableDirtyRect ~= nil, "enableDirtyRect missing")
	assert(GUI.performance.getDirtyRectStats ~= nil, "getDirtyRectStats missing")
	assert(GUI.performance.getObjectPoolStats ~= nil, "getObjectPoolStats missing")
end)

-------------------------------------------------------------------------------
-- Print Summary
-------------------------------------------------------------------------------

print("\n" .. string.rep("=", 60))
print("TEST SUMMARY")
print(string.rep("=", 60))
print(string.format("Total: %d tests", testResults.passed + testResults.failed))
print(string.format("Passed: %d ✓", testResults.passed))
print(string.format("Failed: %d ✗", testResults.failed))
print(string.format("Success Rate: %.1f%%", (testResults.passed / (testResults.passed + testResults.failed)) * 100))
print(string.rep("=", 60))

if testResults.failed > 0 then
	print("\nFailed tests:")
	for _, test in ipairs(testResults.tests) do
		if test.status == "FAIL" then
			print(string.format("  ✗ %s: %s", test.name, test.error or "Unknown error"))
		end
	end
end

print("\n" .. string.rep("=", 60))
if testResults.failed == 0 then
	print("ALL TESTS PASSED! ✓")
else
	print(string.format("SOME TESTS FAILED: %d failures", testResults.failed))
end
print(string.rep("=", 60))

return testResults.failed == 0
