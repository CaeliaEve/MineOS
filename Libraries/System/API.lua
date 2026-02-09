-------------------------------------------------------------------------------
-- System High-Level API
-- Simplified API for common System operations
-- Provides wrapper functions for easier system interaction
-------------------------------------------------------------------------------

local system = require("System")
local API = {}

-------------------------------------------------------------------------------
-- User Management API
-------------------------------------------------------------------------------

-- Get current user
function API.getCurrentUser()
	return user
end

-- Check if user is logged in
function API.isLoggedIn()
	return user ~= nil
end

-- Get user settings
function API.getUserSettings()
	return userSettings
end

-- Save user settings
function API.saveUserSettings()
	local filesystem = require("Filesystem")
	local paths = require("Paths")
	local serializer = require("Serializer")

	local userPath = paths.system.users .. user .. "/"

	filesystem.makeDirectory(userPath)
	local file = io.open(userPath .. "Settings.cfg", "w")
	file:write(serializer.serialize(userSettings))
	file:close()

	return true
end

-------------------------------------------------------------------------------
-- Time API
-------------------------------------------------------------------------------

-- Get current time with timezone
function API.getTime(format)
	format = format or userSettings.timeFormat or "%d %b %Y %H:%M:%S"
	local timezone = userSettings.timeTimezone or 0
	return system.getTime(format, timezone)
end

-- Get formatted date/time
function API.getDateTime()
	return API.getTime()
end

-- Get timestamp
function API.getTimestamp()
	return computer.timestamp()
end

-------------------------------------------------------------------------------
-- Application API
-------------------------------------------------------------------------------

-- Launch an application
function API.launchApplication(path)
	return system.execute(path)
end

-- Launch application with arguments
function API.launchApplicationWithArgs(path, ...)
	return system.execute(path, ...)
end

-- Get application icon
function API.getApplicationIcon(path)
	local filesystem = require("Filesystem")
	local paths = require("Paths")
	local image = require("Image")

	-- Check if icon exists
	local iconPath = path .. "Icon.pic"
	if filesystem.exists(iconPath) then
		return image.load(iconPath)
	end

	-- Return default icon
	return image.load(paths.system.icons .. "Application.pic")
end

-------------------------------------------------------------------------------
-- Filesystem API
-------------------------------------------------------------------------------

-- Get file type icon
function API.getFileIcon(path)
	local filesystem = require("Filesystem")
	local paths = require("Paths")
	local image = require("Image")

	if filesystem.isDirectory(path) then
		return image.load(paths.system.icons .. "Folder.pic")
	elseif filesystem.exists(path) then
		-- Check extension
		local ext = filesystem.extension(path):lower()
		local iconMap = {
			[".lua"] = "Script.pic",
			[".pic"] = "Picture.pic",
			[".txt"] = "File.pic",
		}
		local iconName = iconMap[ext] or "File.pic"
		return image.load(paths.system.icons .. iconName)
	else
		return image.load(paths.system.icons .. "FileNotExists.pic")
	end
end

-- Open file with default application
function API.openFile(path)
	local filesystem = require("Filesystem")

	if filesystem.isDirectory(path) then
		-- Open in Finder
		API.launchApplication("/Applications/Finder.app/Main.lua", path)
	elseif filesystem.extension(path):lower() == ".lua" then
		-- Open in MineCode IDE
		API.launchApplication("/Applications/MineCode IDE.app/Main.lua", path)
	else
		-- Try to open with default application
		API.launchApplication(path)
	end
end

-------------------------------------------------------------------------------
-- Desktop API
-------------------------------------------------------------------------------

-- Add icon to desktop
function API.addDesktopIcon(path, x, y)
	local paths = require("Paths")
	local filesystem = require("Filesystem")

	-- Get user desktop path
	local desktopPath = paths.system.users .. user .. "/Desktop/"
	local iconPath = desktopPath .. filesystem.name(path) .. ".lnk"

	-- Create shortcut
	system.createShortcut(iconPath, path)

	return iconPath
end

-- Remove desktop icon
function API.removeDesktopIcon(path)
	local filesystem = require("Filesystem")
	if filesystem.exists(path) then
		filesystem.remove(path)
		return true
	end
	return false
end

-- Set wallpaper
function API.setWallpaper(path)
	local filesystem = require("Filesystem")
	local paths = require("Paths")

	if filesystem.exists(path) then
		userSettings.wallpaper = path
		API.saveUserSettings()
		system.updateDesktop()
		return true
	end
	return false
end

-- Get wallpaper
function API.getWallpaper()
	return userSettings.wallpaper
end

-------------------------------------------------------------------------------
-- Window Management API
-------------------------------------------------------------------------------

-- Create window
function API.createWindow(x, y, width, height, title)
	local GUI = require("GUI")
	local container = GUI.container(x, y, width, height)

	-- Add window to desktop
	system.addWindow(container)

	return container
end

-- Close window
function API.closeWindow(window)
	system.removeWindow(window)
end

-- Maximize window
function API.maximizeWindow(window)
	if window.maximize then
		window:maximize()
	end
end

-- Minimize window
function API.minimizeWindow(window)
	if window.minimize then
		window:minimize()
	end
end

-------------------------------------------------------------------------------
-- Screenshot API
-------------------------------------------------------------------------------

-- Take screenshot
function API.takeScreenshot()
	local paths = require("Paths")
	local filesystem = require("Filesystem")

	-- Generate filename
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local filename = "Screenshot_" .. timestamp .. ".pic"
	local filepath = paths.system.users .. user .. "/Pictures/" .. filename

	-- Ensure directory exists
	filesystem.makeDirectory(paths.system.users .. user .. "/Pictures/")

	-- Take screenshot
	system.takeScreenshot(filepath)

	return filepath
end

-------------------------------------------------------------------------------
-- Localization API
-------------------------------------------------------------------------------

-- Get current language
function API.getLanguage()
	return userSettings.localizationLanguage or "English"
end

-- Set language
function API.setLanguage(language)
	userSettings.localizationLanguage = language
	API.saveUserSettings()

	-- Reload localization
	local paths = require("Paths")
	localization = system.getLocalization(paths.system.localizations .. language .. ".lang")

	return true
end

-- Translate text
function API.translate(key)
	if localization then
		return localization[key] or key
	end
	return key
end

-------------------------------------------------------------------------------
-- Notification API
-------------------------------------------------------------------------------

-- Show notification
function API.showNotification(title, message, duration)
	local GUI = require("GUI")

	-- Create notification window
	local width = math.max(#title, #message) + 4
	local height = 5
	local x = math.floor((160 - width) / 2)
	local y = 2

	local workspace = GUI.workspace(x, y, width, height)
	local container = GUI.container(1, 1, width, height)

	-- Background
	local background = GUI.panel(1, 1, width, height, 0x1E1E1E, 0.9)
	container:addChild(background)

	-- Title
	local titleLabel = GUI.label(2, 2, width - 2, 1, 0xFFFFFF, title)
	container:addChild(titleLabel)

	-- Message
	local msgLabel = GUI.label(2, 3, width - 2, 1, 0xD2D2D2, message)
	container:addChild(msgLabel)

	workspace:addChild(container)
	workspace:draw()

	-- Auto-hide after duration
	if duration and duration > 0 then
		system.setTimeout(duration, function()
			workspace:stop()
		end)
	end

	return workspace
end

-------------------------------------------------------------------------------
-- Settings API
-------------------------------------------------------------------------------

-- Get setting value
function API.getSetting(key, default)
	return userSettings[key] or default
end

-- Set setting value
function API.setSetting(key, value)
	userSettings[key] = value
	API.saveUserSettings()
	return true
end

-- Get all settings
function API.getAllSettings()
	return userSettings
end

-- Reset settings to default
function API.resetSettings()
	local paths = require("Paths")
	local system = require("System")

	userSettings = system.getDefaultUserSettings()
	API.saveUserSettings()

	return userSettings
end

-------------------------------------------------------------------------------
-- System Info API
-------------------------------------------------------------------------------

-- Get system information
function API.getSystemInfo()
	local computer = require("Computer")

	return {
		uptime = computer.uptime(),
		totalMemory = computer.totalMemory(),
		freeMemory = computer.freeMemory(),
		users = computer.users(),
		screenResolution = "{screen.getResolution()}",
		gpuMemory = "{gpu.getMemory()}"
	}
end

-- Get battery level (if available)
function API.getBatteryLevel()
	local computer = require("Computer")

	if computer.energy then
		return computer.energy()
	end
	return nil
end

-------------------------------------------------------------------------------
-- Network API
-------------------------------------------------------------------------------

-- Check if network is available
function API.isNetworkAvailable()
	local component = require("Component")
	return component.isAvailable("internet") or component.isAvailable("modem")
end

-- Download file
function API.downloadFile(url, path)
	local internet = require("Internet")
	local filesystem = require("Filesystem")

	local result, reason = internet.download(url, path)
	if result then
		return true
	else
		return false, reason
	end
end

-- Check for updates
function API.checkForUpdates()
	-- This would connect to update server
	-- For now, return placeholder
	return {
		available = false,
		currentVersion = "1.0",
		latestVersion = "1.0"
	}
end

-------------------------------------------------------------------------------
-- Task Management API
-------------------------------------------------------------------------------

-- Get running tasks
function API.getRunningTasks()
	-- This would return list of running applications
	-- For now, return placeholder
	return {}
end

-- Kill task
function API.killTask(taskId)
	-- This would terminate a running task
	-- For now, return placeholder
	return false
end

-------------------------------------------------------------------------------
-- Performance API
-------------------------------------------------------------------------------

-- Get performance statistics
function API.getPerformanceStats()
	local computer = require("Computer")

	return {
		uptime = computer.uptime(),
		memoryUsage = computer.totalMemory() - computer.freeMemory(),
		memoryPercent = math.floor((computer.totalMemory() - computer.freeMemory()) / computer.totalMemory() * 100)
	}
end

-- Clear cache
function API.clearCache()
	local computer = require("Computer")
	computer.pushSignal("system", "clearCache")
	return true
end

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

-- Play sound
function API.playSound(frequency, duration)
	local component = require("Component")

	if component.isAvailable("computer") then
		computer.beep(frequency, duration)
		return true
	end
	return false
end

-- Vibrate (if available)
function API.vibrate(duration)
	local component = require("Component")

	-- Check if vibration is available
	-- This is hardware dependent
	return false
end

-- Shutdown
function API.shutdown()
	local computer = require("Computer")
	computer.shutdown()
end

-- Reboot
function API.reboot()
	local computer = require("Computer")
	computer.shutdown(true)
end

-------------------------------------------------------------------------------
-- Quick Access Functions
-------------------------------------------------------------------------------

-- Open Finder
function API.openFinder(path)
	path = path or paths.system.users .. user .. "/Desktop/"
	API.launchApplication("/Applications/Finder.app/Main.lua", path)
end

-- Open Settings
function API.openSettings()
	API.launchApplication("/Applications/Settings.app/Main.lua")
end

-- Open App Market
function API.openAppMarket()
	API.launchApplication("/Applications/App Market.app/Main.lua")
end

-- Open MineCode IDE
function API.openMineCode(path)
	path = path or ""
	API.launchApplication("/Applications/MineCode IDE.app/Main.lua", path)
end

-- Open Console
function API.openConsole()
	API.launchApplication("/Applications/Console.app/Main.lua")
end

-------------------------------------------------------------------------------
-- Batch Operations
-------------------------------------------------------------------------------

-- Execute multiple system operations
function API.batch(operations)
	local results = {}

	for i, operation in ipairs(operations) do
		local success, result = pcall(operation.fn, table.unpack(operation.args or {}))
		results[i] = {
			success = success,
			result = result,
			error = not success and result or nil
		}
	end

	return results
end

-------------------------------------------------------------------------------
-- Event Callbacks
-------------------------------------------------------------------------------

-- Register callback for event
function API.onEvent(eventName, callback)
	-- This would register a system-wide event callback
	-- For now, return placeholder
	return true
end

-- Unregister callback
function API.offEvent(eventName, callback)
	-- This would unregister a system-wide event callback
	-- For now, return placeholder
	return true
end

return API
