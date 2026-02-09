-------------------------------------------------------------------------------
-- Logging System for MineOS
-- Provides structured logging with multiple levels and outputs
-------------------------------------------------------------------------------

local Log = {}
local filesystem = require("Filesystem")
local computer = require("Computer")

-------------------------------------------------------------------------------
-- Log levels
-------------------------------------------------------------------------------

Log.levels = {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	FATAL = 4
}

-- Reverse lookup for level names
local levelNames = {
	[0] = "DEBUG",
	[1] = "INFO",
	[2] = "WARN",
	[3] = "ERROR",
	[4] = "FATAL"
}

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

local config = {
	currentLevel = Log.levels.INFO,

	-- Output destinations
	logToConsole = true,
	logToFile = false,
	logFilePath = "/var/log/mineos.log",

	-- Log format
	includeTimestamp = true,
	includeLevel = true,
	includeContext = true,

	-- File logging
	autoFlush = true,
	maxFileSize = 1024 * 1024,  -- 1MB
	maxFiles = 5
}

-- Current log file handle
local logFile = nil

-------------------------------------------------------------------------------
-- Set log level
-------------------------------------------------------------------------------

function Log.setLevel(level)
	if type(level) == "string" then
		level = Log.levels[level:upper()] or Log.levels.INFO
	end

	config.currentLevel = level
end

function Log.getLevel()
	return config.currentLevel
end

-------------------------------------------------------------------------------
-- Configure logging
-------------------------------------------------------------------------------

function Log.setConfig(key, value)
	if config[key] ~= nil then
		config[key] = value

		-- Handle file logging changes
		if key == "logToFile" then
			if value and not logFile then
				Log.openLogFile()
			elseif not value and logFile then
				Log.closeLogFile()
			end
		end
	end
end

function Log.getConfig(key)
	return config[key]
end

-------------------------------------------------------------------------------
-- File management
-------------------------------------------------------------------------------

function Log.openLogFile()
	if config.logToFile and not logFile then
		-- Ensure directory exists
		local dir = filesystem.path(config.logFilePath)
		if not filesystem.exists(dir) then
			filesystem.makeDirectory(dir)
		end

		-- Open file in append mode
		logFile = io.open(config.logFilePath, "a")
	end
end

function Log.closeLogFile()
	if logFile then
		logFile:close()
		logFile = nil
	end
end

function Log.rotateLogFile()
	if not filesystem.exists(config.logFilePath) then
		return
	end

	-- Get file size
	local size = filesystem.size(config.logFilePath)

	if size > config.maxFileSize then
		Log.closeLogFile()

		-- Rotate existing log files
		for i = config.maxFiles - 1, 1, -1 do
			local oldPath = config.logFilePath .. "." .. i
			local newPath = config.logFilePath .. "." .. (i + 1)

			if filesystem.exists(oldPath) then
				if i == config.maxFiles - 1 then
					filesystem.remove(newPath)
				end
				filesystem.rename(oldPath, newPath)
			end
		end

		-- Rotate current log
		filesystem.rename(config.logFilePath, config.logFilePath .. ".1")

		-- Open new log file
		Log.openLogFile()
	end
end

-------------------------------------------------------------------------------
-- Format log entry
-------------------------------------------------------------------------------

function Log.formatEntry(level, message, context)
	local parts = {}

	if config.includeTimestamp then
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		table.insert(parts, timestamp)
	end

	if config.includeLevel then
		table.insert(parts, string.format("[%s]", levelNames[level]))
	end

	table.insert(parts, message)

	if config.includeContext and context then
		local contextStr = Log.formatContext(context)
		if contextStr ~= "" then
			table.insert(parts, "|")
			table.insert(parts, contextStr)
		end
	end

	return table.concat(parts, " ")
end

function Log.formatContext(context)
	if type(context) ~= "table" then
		return tostring(context)
	end

	local parts = {}
	for key, value in pairs(context) do
		local valueStr
		if type(value) == "table" then
			valueStr = "{...}"
		elseif type(value) == "string" then
			valueStr = string.format("\"%s\"", value)
		else
			valueStr = tostring(value)
		end
		table.insert(parts, string.format("%s=%s", key, valueStr))
	end

	return table.concat(parts, ", ")
end

-------------------------------------------------------------------------------
-- Core logging function
-------------------------------------------------------------------------------

function Log.log(level, message, context)
	-- Check if level is enabled
	if level < config.currentLevel then
		return
	end

	-- Format entry
	local entry = Log.formatEntry(level, message, context)

	-- Output to console
	if config.logToConsole then
		print(entry)
	end

	-- Output to file
	if config.logToFile then
		Log.openLogFile()

		if logFile then
			logFile:write(entry .. "\n")

			if config.autoFlush then
				logFile:flush()
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Convenience logging functions
-------------------------------------------------------------------------------

function Log.debug(message, context)
	Log.log(Log.levels.DEBUG, message, context)
end

function Log.info(message, context)
	Log.log(Log.levels.INFO, message, context)
end

function Log.warn(message, context)
	Log.log(Log.levels.WARN, message, context)
end

function Log.error(message, context)
	Log.log(Log.levels.ERROR, message, context)
end

function Log.fatal(message, context)
	Log.log(Log.levels.FATAL, message, context)
end

-------------------------------------------------------------------------------
-- Performance logging
-------------------------------------------------------------------------------

function Log.logPerformance(name, duration, context)
	context = context or {}
	context.duration = string.format("%.4f", duration)
	context.unit = "seconds"

	Log.debug(string.format("Performance: %s completed in", name), context)
end

function Log.measure(name, func)
	local startTime = computer.uptime()
	local success, result = pcall(func)
	local duration = computer.uptime() - startTime

	if success then
		Log.logPerformance(name, duration, {status = "success"})
	else
		Log.error(string.format("Performance: %s failed after", name), {
			duration = string.format("%.4f", duration),
			error = result
		})
	end

	return success, result, duration
end

-------------------------------------------------------------------------------
-- Error logging with context
-------------------------------------------------------------------------------

function Log.logError(methodName, success, result, ...)
	if not success then
		Log.error(string.format("Method failed: %s", methodName), {
			error = type(result) == "table" and result.traceback or tostring(result),
			arguments = {...}
		})
	end

	return success, result
end

-------------------------------------------------------------------------------
-- Wrap function for automatic error logging
-------------------------------------------------------------------------------

function Log.wrap(method, methodName)
	return function(...)
		local success, result = pcall(method, ...)

		if not success then
			Log.error(string.format("Method failed: %s", methodName), {
				error = tostring(result)
			})
			error(result, 2)
		end

		return result
	end
end

function Log.wrapSafe(method, methodName)
	return function(...)
		local success, result = pcall(method, ...)

		if not success then
			Log.error(string.format("Method failed: %s", methodName), {
				error = tostring(result)
			})
			return nil, result
		end

		return result
	end
end

-------------------------------------------------------------------------------
-- System integration
-------------------------------------------------------------------------------

-- Integrate with system.call()
function Log.integrateWithSystem(system)
	if not system then
		return
	end

	-- Store original system.call
	local originalCall = system.call

	-- Wrap with logging
	system.call = function(method, ...)
		local args = {...}
		local methodName = debug.getinfo(method, "n").name or "anonymous"

		Log.debug("system.call: " .. methodName, {
			arguments = #args
		})

		local success, result = originalCall(method, ...)

		if not success then
			Log.error("system.call failed: " .. methodName, {
				error = type(result) == "table" and result.traceback or tostring(result)
			})
		else
			Log.debug("system.call success: " .. methodName)
		end

		return success, result
	end
end

-------------------------------------------------------------------------------
-- Benchmarking
-------------------------------------------------------------------------------

local benchmarks = {}

function Log.startBenchmark(name)
	benchmarks[name] = {
		startTime = computer.uptime(),
		operations = 0
	}
end

function Log.stopBenchmark(name)
	local benchmark = benchmarks[name]
	if not benchmark then
		return nil
	end

	local duration = computer.uptime() - benchmark.startTime
	benchmarks[name] = nil

	return duration
end

function Log.incrementBenchmark(name, count)
	count = count or 1
	if benchmarks[name] then
		benchmarks[name].operations = benchmarks[name].operations + count
	end
end

function Log.getBenchmarkStats(name)
	local benchmark = benchmarks[name]
	if not benchmark then
		return nil
	end

	local duration = computer.uptime() - benchmark.startTime
	local opsPerSecond = benchmark.operations / duration

	return {
		duration = duration,
		operations = benchmark.operations,
		opsPerSecond = opsPerSecond
	}
end

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

function Log.cleanup()
	Log.closeLogFile()
end

-- Register cleanup on exit
-- Note: OpenComputers doesn't have os.exit, so this may not be called

return Log
