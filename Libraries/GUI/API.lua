-------------------------------------------------------------------------------
-- GUI High-Level API
-- Simplified API for common GUI operations
-- Provides wrapper functions for easier GUI development
-------------------------------------------------------------------------------

local GUI = require("GUI")
local API = {}

-------------------------------------------------------------------------------
-- Factory shortcuts - Simplified component creation
-------------------------------------------------------------------------------

-- Create a basic window
function API.window(x, y, width, height, title)
	local workspace = GUI.workspace(x, y, width, height, 0xFFFFFF, 0x000000)
	local container = GUI.container(1, 1, width, height)

	-- Add title bar if title provided
	if title then
		local titleBar = GUI.panel(1, 1, width, 3, 0xE1E1E1, 1)
		local titleLabel = GUI.label(2, 2, width - 2, 1, 0x2D2D2D, title):setAlignment(
			GUI.ALIGNMENT_HORIZONTAL_LEFT,
			GUI.ALIGNMENT_VERTICAL_CENTER
		)
		container:addChild(titleBar)
		container:addChild(titleLabel)
	end

	workspace:addChild(container)
	return workspace, container
end

-- Create a button with callback
function API.button(x, y, width, height, text, callback, colors)
	colors = colors or {
		background = 0xCCCCCC,
		text = 0x000000,
	Pressed = 0x888888
	}

	local button = GUI.button(x, y, width, height, colors.background, colors.text, text)
	if callback then
		button.onTouch = function()
			callback(button)
		end
	end

	return button
end

-- Create a label with text
function API.label(x, y, width, height, text, color)
	color = color or 0x000000
	local label = GUI.label(x, y, width, height, color, text)
	return label
end

-- Create an input field
function API.input(x, y, width, height, placeholder, textColor, backgroundColor)
	textColor = textColor or 0x000000
	backgroundColor = backgroundColor or 0xFFFFFF

	local input = GUI.input(x, y, width, height, backgroundColor, textColor, placeholder)
	return input
end

-- Create a switch/toggle
function API.switch(x, y, width, state, colors, callback)
	colors = colors or {
		active = 0x66DBFF,
		passive = 0xCCCCCC,
		pipe = 0xFFFFFF
	}

	local switch = GUI.switch(x, y, width, colors.active, colors.passive, colors.pipe, state)
	if callback then
		switch.onStateChanged = function()
			callback(switch.state)
		end
	end

	return switch
end

-- Create a slider
function API.slider(x, y, width, min, max, value, colors, callback)
	colors = colors or {
		active = 0x66DBFF,
		passive = 0xCCCCCC,
		pipe = 0xFFFFFF,
		value = 0x000000
	}

	local slider = GUI.slider(x, y, width, colors.active, colors.passive, colors.pipe, colors.value, min, max, value, true, "", "")
	if callback then
		slider.onValueChanged = function()
			callback(slider.value)
		end
	end

	return slider
end

-- Create a progress bar
function API.progressBar(x, y, width, value, max, colors)
	colors = colors or {
		active = 0x66DBFF,
		passive = 0xCCCCCC,
		value = 0x000000
	}

	local progressBar = GUI.progressBar(x, y, width, colors.active, colors.passive, colors.value, value, max, false, true)
	return progressBar
end

-------------------------------------------------------------------------------
-- Layout helpers
-------------------------------------------------------------------------------

-- Create a horizontal layout container
function API.horizontalLayout(x, y, width, height, spacing, children)
	local container = GUI.container(x, y, width, height)
	spacing = spacing or 2

	local currentX = 1
	for _, child in ipairs(children) do
		child.localX = currentX
		child.localY = 1
		container:addChild(child)
		currentX = currentX + child.width + spacing
	end

	return container
end

-- Create a vertical layout container
function API.verticalLayout(x, y, width, height, spacing, children)
	local container = GUI.container(x, y, width, height)
	spacing = spacing or 2

	local currentY = 1
	for _, child in ipairs(children) do
		child.localX = 1
		child.localY = currentY
		container:addChild(child)
		currentY = currentY + child.height + spacing
	end

	return container
end

-- Center an object in its parent
function API.center(object)
	if not object.parent then
		return object
	end

	local parent = object.parent
	object.localX = math.floor((parent.width - object.width) / 2) + 1
	object.localY = math.floor((parent.height - object.height) / 2) + 1

	return object
end

-------------------------------------------------------------------------------
-- Dialog helpers
-------------------------------------------------------------------------------

-- Create a simple alert dialog
function API.alert(message, buttons)
	buttons = buttons or {{"OK", function() end}}

	local width = math.min(#message + 4, 60)
	local height = #buttons * 3 + 4

	local workspace = GUI.workspace(1, 1, width, height)
	local container = GUI.container(1, 1, width, height)

	-- Message
	local msgLabel = GUI.label(2, 2, width - 2, 1, 0x000000, message)
	msgLabel:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	container:addChild(msgLabel)

	-- Buttons
	local buttonY = 4
	local buttonSpacing = math.floor((width - #buttons * 10) / (#buttons + 1))

	for i, buttonData in ipairs(buttons) do
		local button = GUI.button(
			buttonSpacing + (i - 1) * (10 + buttonSpacing),
			buttonY,
			10, 3,
			0xCCCCCC, 0x000000, buttonData[1]
		)
		button.onTouch = buttonData[2]
		container:addChild(button)
	end

	workspace:addChild(container)
	workspace:draw()

	return workspace
end

-- Create a confirmation dialog
function API.confirm(message, onConfirm, onCancel)
	local buttons = {
		{"Yes", onConfirm or function() end},
		{"No", onCancel or function() end}
	}

	return API.alert(message, buttons)
end

-------------------------------------------------------------------------------
-- Form helpers
-------------------------------------------------------------------------------

-- Create a form with labeled inputs
function API.form(x, y, fields)
	local container = GUI.container(x, y, 60, #fields * 3 + 2)
	local fieldHeight = 3

	local currentY = 1
	for _, field in ipairs(fields) do
		-- Label
		local label = GUI.label(1, currentY, 15, 1, 0x000000, field.label .. ":")
		label:setAlignment(GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_CENTER)
		container:addChild(label)

		-- Input
		local input = GUI.input(17, currentY, 40, fieldHeight or 3, 0xFFFFFF, 0x000000, field.placeholder or "")
		if field.value then
			input.text = field.value
		end
		container:addChild(input)

		-- Store input reference
		field.input = input

		currentY = currentY + fieldHeight + 1
	end

	return container
end

-- Get form values
function API.getFormValues(form)
	local values = {}
	for _, field in ipairs(form) do
		if field.input then
			values[field.label] = field.input.text
		end
	end
	return values
end

-------------------------------------------------------------------------------
-- Color helpers
-------------------------------------------------------------------------------

function API.color(r, g, b)
	return r + g * 0x100 + b * 0x10000
end

function API.parseColor(hex)
	local b = hex % 0x100
	local g = math.floor(hex / 0x100) % 0x100
	local r = math.floor(hex / 0x10000)
	return r, g, b
end

-------------------------------------------------------------------------------
-- Utility functions
-------------------------------------------------------------------------------

-- Add tooltip to object
function API.addTooltip(object, text)
	local GUI = require("GUI")

	object.hoverEvent = function()
		-- Show tooltip
		local tooltip = GUI.container(object.x + object.width, object.y, #text + 2, 1)
		local label = GUI.label(1, 1, #text, 1, 0xFFFFFF, text)
		local background = GUI.panel(1, 1, #text + 2, 1, 0x000000, 0.8)

		tooltip:addChild(background)
		tooltip:addChild(label)

		return tooltip
	end
end

-- Add context menu to object
function API.addContextMenu(object, menuItems)
	local GUI = require("GUI")

	object.contextMenu = function()
		-- Create context menu
		local menuWidth = 20
		local menuHeight = #menuItems * 3 + 2

		local menu = GUI.container(object.x, object.y + object.height, menuWidth, menuHeight)
		local background = GUI.panel(1, 1, menuWidth, menuHeight, 0x1E1E1E, 0.9)
		menu:addChild(background)

		local y = 2
		for _, item in ipairs(menuItems) do
			local button = GUI.button(2, y, menuWidth - 2, 3, 0x1E1E1E, 0xD2D2D2, item.text)
			button.onTouch = item.action
			menu:addChild(button)
			y = y + 3
		end

		return menu
	end
end

-------------------------------------------------------------------------------
-- Animation helpers
-------------------------------------------------------------------------------

function API.fadeIn(object, duration)
	local GUI = require("GUI")

	return object:addAnimation(
		function(object, position)
			-- Fade in animation
			if object.transparency then
				object.transparency = 1 - position
			end
		end,
		duration or 0.2
	)
end

function API.fadeOut(object, duration)
	local GUI = require("GUI")

	return object:addAnimation(
		function(object, position)
			-- Fade out animation
			if object.transparency then
				object.transparency = position
			end
		end,
		duration or 0.2
	)
end

function API.slideIn(object, from, duration)
	local GUI = require("GUI")
	local startX, startY

	if from == "left" then
		startX = -object.width
		startY = object.localY
	elseif from == "right" then
		startX = object.parent.width
		startY = object.localY
	elseif from == "top" then
		startX = object.localX
		startY = -object.height
	elseif from == "bottom" then
		startX = object.localX
		startY = object.parent.height
	end

	return object:addAnimation(
		function(obj, position)
			obj.localX = startX + (object.localX - startX) * position
			obj.localY = startY + (object.localY - startY) * position
		end,
		duration or 0.2
	)
end

-------------------------------------------------------------------------------
-- Workspace helpers
-------------------------------------------------------------------------------

function API.workspace(width, height, title)
	local GUI = require("GUI")
	local workspace = GUI.workspace(1, 1, width, height, 0xFFFFFF, 0x000000)

	if title then
		local titleBar = GUI.panel(1, 1, width, 3, 0xE1E1E1, 1)
		local titleLabel = GUI.label(2, 2, width - 2, 1, 0x2D2D2D, title)
		titleLabel:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
		workspace:addChild(titleBar)
		workspace:addChild(titleLabel)
	end

	return workspace
end

function API.addToWorkspace(workspace, object)
	workspace:addChild(object)
	return object
end

function API.drawWorkspace(workspace)
	workspace:draw()
	return workspace
end

function API.startWorkspace(workspace)
	workspace:start()
	return workspace
end

-------------------------------------------------------------------------------
-- Event handling helpers
-------------------------------------------------------------------------------

function API.onEvent(object, eventType, callback)
	object["on" .. eventType] = callback
	return object
end

function API.onClick(object, callback)
	object.onTouch = callback
	return object
end

function API.onDoubleClick(object, callback)
	object.onDoubleClick = callback
	return object
end

function API.onHover(object, callback)
	object.hoverEvent = callback
	return object
end

function API.onDrag(object, callback)
	object.onDrag = callback
	return object
end

-------------------------------------------------------------------------------
-- Style helpers
-------------------------------------------------------------------------------

function API.setStyle(object, style)
	if style.backgroundColor then
		object.backgroundColor = style.backgroundColor
	end
	if style.textColor then
		object.textColor = style.textColor
	end
	if style.font then
		object.font = style.font
	end
	if style.alignment then
		object:setAlignment(style.alignment.horizontal, style.alignment.vertical)
	end
	if style.transparency then
		object.transparency = style.transparency
	end

	return object
end

-- Predefined styles
API.styles = {
	default = {
		backgroundColor = 0xFFFFFF,
		textColor = 0x000000
	},
	dark = {
		backgroundColor = 0x2D2D2D,
		textColor = 0xFFFFFF
	},
	light = {
		backgroundColor = 0xF0F0F0,
		textColor = 0x000000
	},
	primary = {
		backgroundColor = 0x66DBFF,
		textColor = 0x000000
	},
	success = {
		backgroundColor = 0x99FF80,
		textColor = 0x000000
	},
	warning = {
		backgroundColor = 0xFFFF98,
		textColor = 0x000000
	},
	error = {
		backgroundColor = 0xFF8080,
		textColor = 0x000000
	}
}

return API
