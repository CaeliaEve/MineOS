-------------------------------------------------------------------------------
-- Example Application Using New High-Level API
-- Demonstrates simplified GUI and System API usage
-------------------------------------------------------------------------------

local GUI = require("GUI")
local SystemAPI = require("System.API")
local GUIAPI = require("GUI.API")
local Log = require("Log")

-------------------------------------------------------------------------------
-- Example 1: Simple Window with Button
-------------------------------------------------------------------------------

local function exampleSimpleWindow()
	-- Create window using high-level API
	local workspace = GUIAPI.workspace(60, 20, "Example Window")

	-- Add button
	local button = GUIAPI.button(20, 10, 20, 3, "Click Me!", function()
		SystemAPI.showNotification("Success!", "Button was clicked!", 3)
	end)
	GUIAPI.addToWorkspace(workspace, button)

	-- Start workspace
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 2: Form with Inputs
-------------------------------------------------------------------------------

local function exampleForm()
	local workspace = GUIAPI.workspace(60, 25, "User Input Form")

	-- Create form fields
	local fields = {
		{label = "Name", placeholder = "Enter your name", input = nil},
		{label = "Email", placeholder = "Enter your email", input = nil},
		{label = "Age", placeholder = "Enter your age", input = nil}
	}

	-- Create form
	local form = GUIAPI.form(5, 5, fields)
	GUIAPI.addToWorkspace(workspace, form)

	-- Submit button
	local submitButton = GUIAPI.button(20, 18, 20, 3, "Submit", function()
		local values = GUIAPI.getFormValues(fields)

		-- Log the values
		Log.info("Form submitted", values)

		-- Show notification
		SystemAPI.showNotification(
			"Form Submitted",
			"Name: " .. values.Name .. "\nEmail: " .. values.Email,
			5
		)
	end)
	GUIAPI.addToWorkspace(workspace, submitButton)

	-- Cancel button
	local cancelButton = GUIAPI.button(45, 18, 10, 3, "Cancel", function()
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, cancelButton)

	-- Draw and start
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 3: Dashboard with Progress Bars
-------------------------------------------------------------------------------

local function exampleDashboard()
	local workspace = GUIAPI.workspace(80, 30, "System Dashboard")

	-- Get system info
	local sysInfo = SystemAPI.getSystemInfo()
	local perfStats = SystemAPI.getPerformanceStats()

	-- Title
	local titleLabel = GUIAPI.label(5, 3, 70, 1, 0x000000, "System Performance")
	GUIAPI.addToWorkspace(workspace, titleLabel)

	-- Memory usage
	local memPercent = perfStats.memoryPercent or 0
	local memBar = GUIAPI.progressBar(5, 6, 70, memPercent, 100, {
		active = 0x66DBFF,
		passive = 0xCCCCCC,
		value = 0x000000
	})
	GUIAPI.addToWorkspace(workspace, memBar)

	local memLabel = GUIAPI.label(5, 5, 70, 1, 0x000000,
		string.format("Memory: %d%% (%d MB used / %d MB total)",
			memPercent,
			math.floor(perfStats.memoryUsage / 1024 / 1024),
			math.floor(sysInfo.totalMemory / 1024 / 1024)
		)
	)
	GUIAPI.addToWorkspace(workspace, memLabel)

	-- Uptime
	local uptimeLabel = GUIAPI.label(5, 9, 70, 1, 0x000000,
		string.format("Uptime: %s", SystemAPI.getDateTime())
	)
	GUIAPI.addToWorkspace(workspace, uptimeLabel)

	-- Buttons
	local refreshButton = GUIAPI.button(5, 15, 20, 3, "Refresh", function()
		workspace:stop()
		exampleDashboard()
	end)
	GUIAPI.addToWorkspace(workspace, refreshButton)

	local closeButton = GUIAPI.button(55, 15, 20, 3, "Close", function()
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, closeButton)

	-- Draw and start
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 4: Settings Panel
-------------------------------------------------------------------------------

local function exampleSettingsPanel()
	local workspace = GUIAPI.workspace(60, 25, "Settings")

	-- Language setting
	local langLabel = GUIAPI.label(5, 5, 20, 1, 0x000000, "Language:")
	GUIAPI.addToWorkspace(workspace, langLabel)

	local currentLang = SystemAPI.getLanguage()
	local langInput = GUIAPI.input(25, 5, 30, 1, currentLang, 0x000000, 0xFFFFFF)
	GUIAPI.addToWorkspace(workspace, langInput)

	-- Wallpaper setting
	local wallLabel = GUIAPI.label(5, 9, 20, 1, 0x000000, "Wallpaper:")
	GUIAPI.addToWorkspace(workspace, wallLabel)

	local currentWall = SystemAPI.getWallpaper() or "None"
	local wallInput = GUIAPI.input(25, 9, 30, 1, currentWall, 0x000000, 0xFFFFFF)
	GUIAPI.addToWorkspace(workspace, wallInput)

	-- Save button
	local saveButton = GUIAPI.button(15, 18, 15, 3, "Save", function()
		-- Save language
		SystemAPI.setLanguage(langInput.text)

		-- Save wallpaper
		if wallInput.text ~= "" and wallInput.text ~= "None" then
			SystemAPI.setWallpaper(wallInput.text)
		end

		-- Show notification
		SystemAPI.showNotification("Settings", "Settings saved successfully!", 3)

		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, saveButton)

	-- Cancel button
	local cancelButton = GUIAPI.button(35, 18, 15, 3, "Cancel", function()
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, cancelButton)

	-- Draw and start
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 5: File Browser
-------------------------------------------------------------------------------

local function exampleFileBrowser()
	local workspace = GUIAPI.workspace(80, 30, "File Browser")

	-- Path input
	local pathLabel = GUIAPI.label(5, 3, 10, 1, 0x000000, "Path:")
	GUIAPI.addToWorkspace(workspace, pathLabel)

	local currentPath = SystemAPI.getCurrentUser() and "/Users/" .. SystemAPI.getCurrentUser() .. "/Desktop/" or "/"
	local pathInput = GUIAPI.input(15, 3, 55, 1, currentPath, 0x000000, 0xFFFFFF)
	GUIAPI.addToWorkspace(workspace, pathInput)

	-- Go button
	local goButton = GUIAPI.button(72, 2, 7, 3, "Go", function()
		-- Open file/folder
		local path = pathInput.text
		SystemAPI.openFile(path)
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, goButton)

	-- Info label
	local infoLabel = GUIAPI.label(5, 27, 70, 1, 0x666666,
		"Enter a path and click Go to open with default application"
	)
	GUIAPI.addToWorkspace(workspace, infoLabel)

	-- Close button
	local closeButton = GUIAPI.button(60, 25, 15, 3, "Close", function()
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, closeButton)

	-- Draw and start
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 6: Animated Progress
-------------------------------------------------------------------------------

local function exampleAnimatedProgress()
	local workspace = GUIAPI.workspace(60, 15, "Animated Progress")

	-- Progress bar
	local progressBar = GUIAPI.progressBar(10, 6, 40, 0, 100, {
		active = 0x66DBFF,
		passive = 0xCCCCCC,
		value = 0x000000
	})
	GUIAPI.addToWorkspace(workspace, progressBar)

	-- Status label
	local statusLabel = GUIAPI.label(10, 4, 40, 1, 0x000000, "Loading...")
	GUIAPI.addToWorkspace(workspace, statusLabel)

	-- Draw
	GUIAPI.drawWorkspace(workspace)

	-- Animate progress
	local progress = 0
	local eventHandler = workspace.eventHandler

	workspace.eventHandler = function(workspace, object, ...)
		-- Call original handler
		if eventHandler then
			eventHandler(workspace, object, ...)
		end

		-- Update progress
		progress = progress + 5
		if progress > 100 then
			progress = 100
			statusLabel.text = "Complete!"
			GUIAPI.drawWorkspace(workspace)
		else
			progressBar.value = progress
			statusLabel.text = "Loading... " .. progress .. "%"
			GUIAPI.drawWorkspace(workspace)
		end
	end

	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Example 7: Color Selector Demo
-------------------------------------------------------------------------------

local function exampleColorSelector()
	local GUI = require("GUI")
	local workspace = GUI.workspace(1, 1, 60, 25)

	-- Color selector
	local colorSelector = GUI.colorSelector(5, 5, 50, 25, 0xFF0000, "Select Color")
	workspace:addChild(colorSelector)

	-- Preview panel
	local previewPanel = GUI.panel(5, 15, 50, 5, 0xFF0000, 0.5)
	workspace:addChild(previewPanel)

	-- Update preview on color change
	colorSelector.onColorSelected = function(color)
		previewPanel.backgroundColor = color
		workspace:draw()
	end

	-- Close button
	local closeButton = GUI.button(20, 22, 20, 3, "Close", function()
		workspace:stop()
	end)
	workspace:addChild(closeButton)

	-- Draw and start
	workspace:draw()
	workspace:start()
end

-------------------------------------------------------------------------------
-- Main Menu
-------------------------------------------------------------------------------

local function mainMenu()
	local workspace = GUIAPI.workspace(50, 25, "API Examples")

	-- Title
	local titleLabel = GUIAPI.label(5, 3, 40, 1, 0x000000, "Select an Example:")
	titleLabel:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
	GUIAPI.addToWorkspace(workspace, titleLabel)

	-- Example buttons
	local examples = {
		{"Simple Window", exampleSimpleWindow},
		{"Form with Inputs", exampleForm},
		{"System Dashboard", exampleDashboard},
		{"Settings Panel", exampleSettingsPanel},
		{"File Browser", exampleFileBrowser},
		{"Animated Progress", exampleAnimatedProgress},
		{"Color Selector", exampleColorSelector}
	}

	local y = 6
	for _, example in ipairs(examples) do
		local button = GUIAPI.button(10, y, 30, 3, example[1], function()
			workspace:stop()
			example[2]()
		end)
		GUIAPI.addToWorkspace(workspace, button)
		y = y + 4
	end

	-- Exit button
	local exitButton = GUIAPI.button(10, y + 2, 30, 3, "Exit", function()
		workspace:stop()
	end)
	GUIAPI.addToWorkspace(workspace, exitButton)

	-- Draw and start
	GUIAPI.drawWorkspace(workspace)
	GUIAPI.startWorkspace(workspace)
end

-------------------------------------------------------------------------------
-- Run Example
-------------------------------------------------------------------------------

-- Log startup
Log.info("API Examples application started")

-- Show menu
mainMenu()

-- Log exit
Log.info("API Examples application exited")
