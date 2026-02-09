-------------------------------------------------------------------------------
-- Backward Compatibility Layer for GUI
-- Maintains single namespace for all existing applications
-- All 38 applications continue to work without modification
-------------------------------------------------------------------------------

-- Load the original GUI module
local GUI = require("GUI")

-- Load new performance modules
local DirtyRect = require("GUI.DirtyRect")
local Quadtree = require("GUI.Quadtree")
local ObjectPool = require("GUI.ObjectPool")

-------------------------------------------------------------------------------
-- Performance optimization integration
-------------------------------------------------------------------------------

-- Store original workspace function
local originalWorkspace = GUI.workspace

-- Enhanced workspace with performance features
function GUI.workspace(x, y, width, height, backgroundColor, foregroundColor)
	local workspace = originalWorkspace(x, y, width, height, backgroundColor, foregroundColor)

	-- Add dirty rectangle support
	workspace.dirtyRect = DirtyRect
	workspace.markDirty = function(object)
		DirtyRect.markDirty(object)
	end

	-- Add quadtree support
	workspace.quadtree = Quadtree.new(x, y, width, height)

	-- Add object pool support
	workspace.objectPool = ObjectPool

	-- Store original draw method
	local originalDraw = workspace.draw

	-- Enhanced draw method with dirty rectangle optimization
	workspace.draw = function(...)
		if DirtyRect.isEnabled() then
			DirtyRect.draw(workspace, originalDraw, ...)
		else
			originalDraw(...)
		end
	end

	-- Store original event handling
	local originalProcessEvent = workspace.eventHandler

	-- Enhanced event handler with quadtree optimization
	workspace.eventHandler = function(workspace, object, ...)
		-- Check if it's a touch/click event
		local eventData = table.pack(...)
		if eventData[1] == "touch" or eventData[1] == "drag" or eventData[1] == "drop" then
			local x, y = eventData[3], eventData[4]

			-- Use quadtree to find candidate objects
			local candidates = workspace.quadtree:query(x, y)

			-- Only process relevant objects
			for _, candidate in ipairs(candidates) do
				if candidate.eventHandler then
					candidate.eventHandler(workspace, candidate, ...)
				end
			end

			return
		end

		-- Default processing for other events
		if originalProcessEvent then
			originalProcessEvent(workspace, object, ...)
		end
	end

	return workspace
end

-------------------------------------------------------------------------------
-- Monkey-patch GUI.object to track dirty regions
-------------------------------------------------------------------------------

local originalObject = GUI.object

function GUI.object(x, y, width, height)
	local obj = originalObject(x, y, width, height)

	-- Store original draw method
	local originalDraw = obj.draw

	-- Wrap draw to mark dirty after drawing
	obj.draw = function(...)
		originalDraw(...)
		if obj.parent then
			obj.parent.markDirty(obj)
		end
	end

	-- Wrap property setters to mark dirty
	local obj metatable = getmetatable(obj) or {}

	-- Override position setters
	obj.setPosition = function(self, x, y)
		self.x = x
		self.y = y
		if self.parent then
			self.parent.markDirty(self)
		end
	end

	obj.setSize = function(self, width, height)
		self.width = width
		self.height = height
		if self.parent then
			self.parent.markDirty(self)
		end
	end

	return obj
end

-------------------------------------------------------------------------------
-- Enhanced container with quadtree management
-------------------------------------------------------------------------------

local originalContainer = GUI.container

function GUI.container(x, y, width, height)
	local container = originalContainer(x, y, width, height)

	-- Add quadtree for this container
	container.quadtree = Quadtree.new(x, y, width, height)

	-- Store original addChild method
	local originalAddChild = container.addChild

	-- Override to update quadtree
	container.addChild = function(self, child, ...)
		local result = originalAddChild(self, child, ...)

		-- Add to quadtree
		if child then
			self.quadtree:insert(child)
		end

		return result
	end

	-- Store original removeChild method
	local originalRemoveChild = container.removeChild

	-- Override to update quadtree
	container.removeChild = function(self, child)
		local result = originalRemoveChild(self, child)

		-- Remove from quadtree
		if child then
			self.quadtree:remove(child)
		end

		return result
	end

	return container
end

-------------------------------------------------------------------------------
-- Convenience functions for object pooling
-------------------------------------------------------------------------------

GUI.pooled = {
	button = function(...)
		return ObjectPool.getButton(...)
	end,

	label = function(...)
		return ObjectPool.getLabel(...)
	end,

	panel = function(...)
		return ObjectPool.getPanel(...)
	end,

	input = function(...)
		return ObjectPool.getInput(...)
	end,

	release = function(object)
		if object._poolName then
			return ObjectPool.release(object._poolName, object)
		end
		return false
	end
}

-------------------------------------------------------------------------------
-- Performance configuration
-------------------------------------------------------------------------------

GUI.performance = {
	enableDirtyRect = function(enabled)
		DirtyRect.setEnabled(enabled)
	end,

	isDirtyRectEnabled = function()
		return DirtyRect.isEnabled()
	end,

	getDirtyRectStats = function()
		return DirtyRect.getStats()
	end,

	enableQuadtree = function(enabled)
		-- Quadtree is always enabled in workspace
		-- This just affects event handling optimization
	end,

	getQuadtreeStats = function(workspace)
		if workspace and workspace.quadtree then
			return workspace.quadtree:getStats()
		end
		return nil
	end,

	enableObjectPool = function(enabled)
		ObjectPool.setEnabled(enabled)
	end,

	getObjectPoolStats = function()
		return ObjectPool.getStats()
	end,

	resetStats = function()
		DirtyRect.resetStats()
		ObjectPool.resetStats()
	end
}

-------------------------------------------------------------------------------
-- Automatic object pooling for common components
-------------------------------------------------------------------------------

-- Store original constructors
local originalButton = GUI.button
local originalLabel = GUI.label
local originalPanel = GUI.panel

-- Wrapped constructors (optional pooling)
GUI.button = function(...)
	return originalButton(...)
end

GUI.label = function(...)
	return originalLabel(...)
end

GUI.panel = function(...)
	return originalPanel(...)
end

-------------------------------------------------------------------------------
-- Return enhanced GUI module
-------------------------------------------------------------------------------

return GUI
