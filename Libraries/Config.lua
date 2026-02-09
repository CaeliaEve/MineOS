-------------------------------------------------------------------------------
-- Unified Configuration System for MineOS
-- Provides schema validation, defaults, type checking, and migrations
-------------------------------------------------------------------------------

local Config = {}
local filesystem = require("Filesystem")

-------------------------------------------------------------------------------
-- Registered schemas
-------------------------------------------------------------------------------

local schemas = {}

-------------------------------------------------------------------------------
-- Register a configuration schema
-------------------------------------------------------------------------------

function Config.registerSchema(name, schema)
	assert(type(name) == "string", "Schema name must be a string")
	assert(type(schema) == "table", "Schema must be a table")

	-- Validate schema structure
	assert(schema.defaults ~= nil, "Schema must have defaults")
	assert(type(schema.defaults) == "table", "Defaults must be a table")

	schemas[name] = schema
	return true
end

-------------------------------------------------------------------------------
-- Get a registered schema
-------------------------------------------------------------------------------

function Config.getSchema(name)
	return schemas[name]
end

-------------------------------------------------------------------------------
-- Create default configuration from schema
-------------------------------------------------------------------------------

function Config.createDefault(schemaName)
	local schema = schemas[schemaName]
	if not schema then
		error("Unknown schema: " .. tostring(schemaName))
	end

	-- Deep copy defaults
	return Config.deepCopy(schema.defaults)
end

-------------------------------------------------------------------------------
-- Deep copy a table
-------------------------------------------------------------------------------

function Config.deepCopy(obj)
	if type(obj) ~= "table" then
		return obj
	end

	local copy = {}
	for key, value in pairs(obj) do
		copy[Config.deepCopy(key)] = Config.deepCopy(value)
	end

	return copy
end

-------------------------------------------------------------------------------
-- Validate configuration against schema
-------------------------------------------------------------------------------

function Config.validate(config, schemaName, path)
	local schema = schemas[schemaName]
	if not schema then
		error("Unknown schema: " .. tostring(schemaName))
	end

	path = path or "root"

	-- Type checking
	if schema.types then
		for key, expectedType in pairs(schema.types) do
			local value = config[key]

			if value ~= nil then
				local actualType = type(value)

				-- Handle number subtypes
				if expectedType == "number" then
					if actualType ~= "number" then
						return false, string.format("Type mismatch at %s.%s: expected %s, got %s",
							path, key, expectedType, actualType)
					end
				elseif expectedType == "integer" then
					if actualType ~= "number" or math.floor(value) ~= value then
						return false, string.format("Type mismatch at %s.%s: expected integer, got %s",
							path, key, actualType)
					end
				elseif expectedType == "boolean" then
					if actualType ~= "boolean" then
						return false, string.format("Type mismatch at %s.%s: expected %s, got %s",
							path, key, expectedType, actualType)
					end
				elseif expectedType == "string" then
					if actualType ~= "string" then
						return false, string.format("Type mismatch at %s.%s: expected %s, got %s",
							path, key, expectedType, actualType)
					end
				elseif expectedType == "table" then
					if actualType ~= "table" then
						return false, string.format("Type mismatch at %s.%s: expected %s, got %s",
							path, key, expectedType, actualType)
					end
				end
			end
		end
	end

	-- Range validation
	if schema.ranges then
		for key, range in pairs(schema.ranges) do
			local value = config[key]

			if value ~= nil then
				if range.min and value < range.min then
					return false, string.format("Range validation failed at %s.%s: value %s is below minimum %s",
						path, key, tostring(value), tostring(range.min))
				end

				if range.max and value > range.max then
					return false, string.format("Range validation failed at %s.%s: value %s is above maximum %s",
						path, key, tostring(value), tostring(range.max))
				end
			end
		end
	end

	-- Custom validation
	if schema.validate then
		local success, err = schema.validate(config, path)
		if not success then
			return false, err
		end
	end

	return true
end

-------------------------------------------------------------------------------
-- Apply migrations to update config version
-------------------------------------------------------------------------------

function Config.migrate(config, schemaName)
	local schema = schemas[schemaName]
	if not schema then
		error("Unknown schema: " .. tostring(schemaName))
	end

	local currentVersion = config.version or 0
	local targetVersion = schema.latestVersion or 0

	-- No migrations needed
	if currentVersion >= targetVersion then
		return config
	end

	-- Apply migrations sequentially
	for version = currentVersion, targetVersion - 1 do
		local migration = schema.migrations and schema.migrations[version]

		if migration then
			local success, result = pcall(migration, config)

			if not success then
				error(string.format("Migration from version %d to %d failed: %s",
					version, version + 1, tostring(result)))
			end

			config = result or config
		end
	end

	-- Update version
	config.version = targetVersion

	return config
end

-------------------------------------------------------------------------------
-- Load configuration from file
-------------------------------------------------------------------------------

function Config.load(path, schemaName)
	local schema = schemas[schemaName]
	if not schema then
		error("Unknown schema: " .. tostring(schemaName))
	end

	local config

	-- Try to load existing config
	if filesystem.exists(path) then
		local data, reason = filesystem.readTable(path)

		if data then
			config = data
		else
			-- File exists but is corrupted, create new
			config = Config.createDefault(schemaName)
		end
	else
		-- File doesn't exist, create new
		config = Config.createDefault(schemaName)
	end

	-- Apply migrations
	config = Config.migrate(config, schemaName)

	-- Validate
	local valid, err = Config.validate(config, schemaName)
	if not valid then
		error("Configuration validation failed: " .. tostring(err))
	end

	return config
end

-------------------------------------------------------------------------------
-- Save configuration to file
-------------------------------------------------------------------------------

function Config.save(path, config, schemaName)
	-- Validate before saving
	local schema = schemas[schemaName]
	if schema then
		local valid, err = Config.validate(config, schemaName)
		if not valid then
			error("Cannot save invalid configuration: " .. tostring(err))
		end
	end

	-- Ensure directory exists
	local dir = filesystem.path(path)
	if not filesystem.exists(dir) then
		filesystem.makeDirectory(dir)
	end

	-- Write to file
	filesystem.writeTable(path, config, true)

	return true
end

-------------------------------------------------------------------------------
-- Get configuration value with default fallback
-------------------------------------------------------------------------------

function Config.get(config, key, defaultValue)
	local keys = {}
	for k in key:gmatch("[^.]+") do
		table.insert(keys, k)
	end

	local value = config
	for _, k in ipairs(keys) do
		if type(value) == "table" then
			value = value[k]
		else
			return defaultValue
		end
	end

	if value == nil then
		return defaultValue
	end

	return value
end

-------------------------------------------------------------------------------
-- Set configuration value
-------------------------------------------------------------------------------

function Config.set(config, key, value)
	local keys = {}
	for k in key:gmatch("[^.]+") do
		table.insert(keys, k)
	end

	local obj = config
	for i = 1, #keys - 1 do
		local k = keys[i]
		if obj[k] == nil then
			obj[k] = {}
		elseif type(obj[k]) ~= "table" then
			obj[k] = {}
		end
		obj = obj[k]
	end

	obj[keys[#keys]] = value
	return config
end

-------------------------------------------------------------------------------
-- Register default schemas
-------------------------------------------------------------------------------

function Config.registerDefaultSchemas()
	-- System settings schema
	Config.registerSchema("systemSettings", {
		latestVersion = 1,
		defaults = {
			version = 1,
			localizationLanguage = "English",
			timeFormat = "%d %b %Y %H:%M:%S",
			timeTimezone = 0,
			timeShowSeconds = true,
			screenSaverEnabled = false,
			screenSaverDelay = 10,
			enableAnimations = true,
			animationDuration = 0.2,
			enableBlur = true,
			blurRadius = 3,
			enableTransparency = true,
			toolbarShowClock = true,
			toolbarShowCPU = false,
			toolbarShowRAM = false,
			dockEnabled = true,
			dockIconSize = 8,
			dockAutoHide = false,
			desktopIconSize = 8,
		桌面图标大小 = 8,
			windowSnapEnabled = true,
			windowSnapDistance = 10,
			workspaceDrawLimit = 0,
		},
		types = {
			localizationLanguage = "string",
			timeFormat = "string",
			timeTimezone = "integer",
			timeShowSeconds = "boolean",
			screenSaverEnabled = "boolean",
			screenSaverDelay = "integer",
			enableAnimations = "boolean",
			animationDuration = "number",
			enableBlur = "boolean",
			blurRadius = "integer",
			enableTransparency = "boolean",
			toolbarShowClock = "boolean",
			toolbarShowCPU = "boolean",
			toolbarShowRAM = "boolean",
			dockEnabled = "boolean",
			dockIconSize = "integer",
			dockAutoHide = "boolean",
			desktopIconSize = "integer",
			桌面图标大小 = "integer",
			windowSnapEnabled = "boolean",
			windowSnapDistance = "integer",
			workspaceDrawLimit = "integer",
		},
		ranges = {
			timeTimezone = {min = -12, max = 12},
			screenSaverDelay = {min = 1, max = 60},
			animationDuration = {min = 0, max = 2},
			blurRadius = {min = 1, max = 10},
			dockIconSize = {min = 4, max = 16},
			desktopIconSize = {min = 4, max = 16},
			windowSnapDistance = {min = 1, max = 50},
		}
	})

	-- GUI performance schema
	Config.registerSchema("guiPerformance", {
		latestVersion = 1,
		defaults = {
			version = 1,
			enableDirtyRectangle = true,
			dirtyThreshold = 0.3,
			enableQuadtree = true,
			enableObjectPool = true,
			objectPoolSize = 100,
			enableImageCache = true,
			imageCacheSize = 50,
			enableEventOptimization = true,
		},
		types = {
			enableDirtyRectangle = "boolean",
			dirtyThreshold = "number",
			enableQuadtree = "boolean",
			enableObjectPool = "boolean",
			objectPoolSize = "integer",
			enableImageCache = "boolean",
			imageCacheSize = "integer",
			enableEventOptimization = "boolean",
		},
		ranges = {
			dirtyThreshold = {min = 0.1, max = 1.0},
			objectPoolSize = {min = 10, max = 500},
			imageCacheSize = {min = 10, max = 200},
		}
	})
end

-- Register default schemas on load
Config.registerDefaultSchemas()

return Config
