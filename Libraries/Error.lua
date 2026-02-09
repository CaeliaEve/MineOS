-------------------------------------------------------------------------------
-- Error Handling Module for MineOS
-- Provides robust error parsing with multiple fallback strategies
-- Addresses TODO at System.lua:277
-------------------------------------------------------------------------------

local Error = {}

-------------------------------------------------------------------------------
-- Multi-strategy traceback parsing
-- Handles different server configurations and traceback formats
-------------------------------------------------------------------------------

-- Strategy 1: Original regex pattern (works for most cases)
local function parseTracebackStrategy1(traceback)
	local iter = traceback:gmatch("\t+([^:]+%.lua):(%d+):")
	iter()
	local path, line = iter()

	if path and line then
		return {
			path = path,
			line = tonumber(line),
			traceback = traceback,
			strategy = 1
		}
	end
	return nil
end

-- Strategy 2: More flexible pattern (handles varied formatting)
local function parseTracebackStrategy2(traceback)
	local path, line = traceback:match("([^\n]+%.lua):(%d+):")
	if path and line then
		return {
			path = path,
			line = tonumber(line),
			traceback = traceback,
			strategy = 2
		}
	end
	return nil
end

-- Strategy 3: Line-by-line analysis (handles unconventional formats)
local function parseTracebackStrategy3(traceback)
	for line in traceback:gmatch("[^\n]+") do
		-- Try to match various patterns
		local path, lineNum = line:match("(.+%.lua):(%d+)")
		if path and lineNum then
			return {
				path = path,
				line = tonumber(lineNum),
				traceback = traceback,
				strategy = 3
			}
		end

		-- Try pattern without colon
		path, lineNum = line:match("(.+%.lua)%s+(%d+)")
		if path and lineNum then
			return {
				path = path,
				line = tonumber(lineNum),
				traceback = traceback,
				strategy = 3
			}
		end
	end
	return nil
end

-- Strategy 4: Extract any .lua path (last resort)
local function parseTracebackStrategy4(traceback)
	local path = traceback:match("([a-zA-Z0-9/_-]+%.lua)")
	if path then
		-- Try to find any number nearby
		local lineNum = traceback:match("(%d+)")
		return {
			path = path,
			line = tonumber(lineNum) or 1,
			traceback = traceback,
			strategy = 4,
			partial = true
		}
	end
	return nil
end

-- Strategy 5: Ultimate fallback (always succeeds)
local function parseTracebackStrategy5(traceback)
	return {
		path = "unknown",
		line = 1,
		traceback = traceback,
		strategy = 5,
		partial = true
	}
end

-------------------------------------------------------------------------------
-- Main parse function with fallback chain
-------------------------------------------------------------------------------

function Error.parseTraceback(traceback, debugTraceback)
	if type(traceback) ~= "string" then
		traceback = tostring(traceback)
	end

	-- Remove tail calls (existing logic)
	local path = traceback
	while true do
		local tailCallsStart = path:find("%.%.%.tail calls%.%.%.%)")
		if tailCallsStart then
			path = path:sub(tailCallsStart + 17)
		else
			break
		end
	end

	-- Try each strategy in order
	local strategies = {
		parseTracebackStrategy1,
		parseTracebackStrategy2,
		parseTracebackStrategy3,
		parseTracebackStrategy4,
		parseTracebackStrategy5
	}

	for _, strategy in ipairs(strategies) do
		local result = strategy(path)
		if result then
			-- Append debugTraceback if available
			if debugTraceback then
				result.traceback = tostring(traceback) .. "\n" .. debugTraceback
			else
				result.traceback = traceback
			end
			return result
		end
	end

	-- This should never be reached due to strategy 5
	return {
		path = "unknown",
		line = 1,
		traceback = traceback,
		strategy = 0,
		partial = true
	}
end

-------------------------------------------------------------------------------
-- Error classification
-------------------------------------------------------------------------------

Error.ErrorTypes = {
	SYNTAX = "syntax",
	RUNTIME = "runtime",
	FILESYSTEM = "filesystem",
	NETWORK = "network",
	MEMORY = "memory",
	UNKNOWN = "unknown"
}

function Error.classify(errorReason)
	local errorStr = tostring(errorReason)

	if errorStr:match("syntax") or errorStr:match("parse") then
		return Error.ErrorTypes.SYNTAX
	elseif errorStr:match("file") or errorStr:match("directory") or errorStr:match("path") then
		return Error.ErrorTypes.FILESYSTEM
	elseif errorStr:match("network") or errorStr:match("connection") or errorStr:match("timeout") then
		return Error.ErrorTypes.NETWORK
	elseif errorStr:match("memory") or errorStr:match("heap") or errorStr:match("out of memory") then
		return Error.ErrorTypes.MEMORY
	elseif errorStr:match("interrupt") then
		return "interrupted"
	else
		return Error.ErrorTypes.RUNTIME
	end
end

-------------------------------------------------------------------------------
-- User-friendly error messages
-------------------------------------------------------------------------------

function Error.getUserMessage(errorReason, errorPath, errorLine)
	local errorType = Error.classify(errorReason)

	local messages = {
		[Error.ErrorTypes.SYNTAX] = {
			title = "Syntax Error",
			message = "There's a syntax error in the code.",
			hint = "Check for typos, missing brackets, or invalid syntax."
		},
		[Error.ErrorTypes.FILESYSTEM] = {
			title = "Filesystem Error",
			message = "Unable to access the requested file or directory.",
			hint = "Make sure the file exists and you have permission to access it."
		},
		[Error.ErrorTypes.NETWORK] = {
			title = "Network Error",
			message = "Unable to complete the network operation.",
			hint = "Check your internet connection and try again."
		},
		[Error.ErrorTypes.MEMORY] = {
			title = "Memory Error",
			message = "The system is out of memory.",
			hint = "Close some applications or free up memory and try again."
		},
		[Error.ErrorTypes.RUNTIME] = {
			title = "Runtime Error",
			message = "An error occurred while running the program.",
			hint = "Check the error details for more information."
		},
		["interrupted"] = {
			title = "Interrupted",
			message = "The operation was interrupted.",
			hint = "The operation was cancelled by the user or system."
		}
	}

	local msg = messages[errorType] or messages[Error.ErrorTypes.UNKNOWN]

	return string.format(
		"%s: %s\n\nLocation: %s:%d\n\nHint: %s\n\nDetails: %s",
		msg.title,
		msg.message,
		errorPath or "unknown",
		errorLine or 1,
		msg.hint,
		errorReason
	)
end

-------------------------------------------------------------------------------
-- Error recovery strategies
-------------------------------------------------------------------------------

function Error.shouldRetry(errorType)
	return errorType == Error.ErrorTypes.NETWORK or
	       errorType == Error.ErrorTypes.FILESYSTEM
end

function Error.getRetryDelay(attemptNumber)
	-- Exponential backoff: 1s, 2s, 4s, 8s, max 16s
	return math.min(2 ^ attemptNumber, 16)
end

return Error
