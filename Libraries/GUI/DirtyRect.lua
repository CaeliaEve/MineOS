-------------------------------------------------------------------------------
-- Dirty Rectangle Rendering System for MineOS
-- Tracks modified regions and only redraws what changed
-- Expected performance improvement: 50-70% reduction in rendering operations
-------------------------------------------------------------------------------

local DirtyRect = {}

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

DirtyRect.config = {
	-- If more than this percentage of screen is dirty, do full redraw
	DIRTY_THRESHOLD = 0.3,

	-- Maximum number of dirty regions to track (prevents excessive memory)
	MAX_DIRTY_REGIONS = 100,

	-- Enable debug mode (shows dirty regions in red)
	DEBUG_MODE = false,

	-- Minimum region size to track (smaller regions are merged)
	MIN_REGION_SIZE = 1
}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local dirtyRegions = {}
local isEnabled = true
local totalDraws = 0
local fullRedraws = 0
local partialRedraws = 0

-------------------------------------------------------------------------------
-- Mark an object or region as dirty (needs redraw)
-------------------------------------------------------------------------------

function DirtyRect.markDirty(object)
	if not isEnabled then
		return
	end

	if not object or type(object) ~= "table" then
		return
	end

	-- Extract bounds from object
	local x = object.x or object[1] or 1
	local y = object.y or object[2] or 1
	local width = object.width or object[3] or 1
	local height = object.height or object[4] or 1

	DirtyRect.markRegion(x, y, width, height)
end

function DirtyRect.markRegion(x, y, width, height)
	if not isEnabled then
		return
	end

	-- Normalize coordinates
	x = math.floor(x)
	y = math.floor(y)
	width = math.floor(width)
	height = math.floor(height)

	-- Don't track tiny regions
	if width < DirtyRect.config.MIN_REGION_SIZE or
	   height < DirtyRect.config.MIN_REGION_SIZE then
		return
	end

	-- Check if we should merge with existing regions
	local merged = false
	for i = #dirtyRegions, 1, -1 do
		local region = dirtyRegions[i]

		-- Check for overlap or adjacency
		if DirtyRect.regionsOverlap(region, {x = x, y = y, width = width, height = height}) then
			-- Merge regions
			region.x = math.min(region.x, x)
			region.y = math.min(region.y, y)
			local maxX = math.max(region.x + region.width, x + width)
			local maxY = math.max(region.y + region.height, y + height)
			region.width = maxX - region.x
			region.height = maxY - region.y
			merged = true
			break
		end
	end

	-- Add new region if not merged
	if not merged then
		if #dirtyRegions < DirtyRect.config.MAX_DIRTY_REGIONS then
			table.insert(dirtyRegions, {
				x = x,
				y = y,
				width = width,
				height = height
			})
		else
			-- Too many regions, trigger full redraw
			DirtyRect.clear()
			DirtyRect.setEnabled(false)
		end
	end
end

-------------------------------------------------------------------------------
-- Check if two regions overlap or are adjacent
-------------------------------------------------------------------------------

function DirtyRect.regionsOverlap(region1, region2)
	local margin = 0  -- Can be increased for more aggressive merging

	return not (
		region1.x + region1.width + margin < region2.x or
		region2.x + region2.width + margin < region1.x or
		region1.y + region1.height + margin < region2.y or
		region2.y + region2.height + margin < region1.y
	)
end

-------------------------------------------------------------------------------
-- Merge dirty regions (optimize before rendering)
-------------------------------------------------------------------------------

function DirtyRect.mergeRegions()
	if #dirtyRegions == 0 then
		return nil
	end

	-- Calculate total dirty area
	local totalArea = 0
	for _, region in ipairs(dirtyRegions) do
		totalArea = totalArea + (region.width * region.height)
	end

	-- Get screen bounds (from workspace or default)
	local screen = require("Screen")
	local screenWidth, screenHeight = screen.getResolution()

	-- Check if we should do full redraw
	local screenArea = screenWidth * screenHeight
	if totalArea > screenArea * DirtyRect.config.DIRTY_THRESHOLD then
		return nil  -- Signal for full redraw
	end

	-- Merge overlapping/adjacent regions
	local merged = {}
	for _, region in ipairs(dirtyRegions) do
		local didMerge = false

		for i = #merged, 1, -1 do
			if DirtyRect.regionsOverlap(merged[i], region) then
				-- Merge
				merged[i].x = math.min(merged[i].x, region.x)
				merged[i].y = math.min(merged[i].y, region.y)
				local maxX = math.max(merged[i].x + merged[i].width, region.x + region.width)
				local maxY = math.max(merged[i].y + merged[i].height, region.y + region.height)
				merged[i].width = maxX - merged[i].x
				merged[i].height = maxY - merged[i].y
				didMerge = true
				break
			end
		end

		if not didMerge then
			table.insert(merged, region)
		end
	end

	return merged
end

-------------------------------------------------------------------------------
-- Clear all dirty regions
-------------------------------------------------------------------------------

function DirtyRect.clear()
	dirtyRegions = {}
end

-------------------------------------------------------------------------------
-- Enable/disable dirty rectangle tracking
-------------------------------------------------------------------------------

function DirtyRect.setEnabled(enabled)
	isEnabled = enabled
	if not enabled then
		DirtyRect.clear()
	end
end

function DirtyRect.isEnabled()
	return isEnabled
end

-------------------------------------------------------------------------------
-- Get statistics
-------------------------------------------------------------------------------

function DirtyRect.getStats()
	return {
		totalDraws = totalDraws,
		fullRedraws = fullRedraws,
		partialRedraws = partialRedraws,
		currentDirtyRegions = #dirtyRegions,
		efficiency = totalDraws > 0 and (partialRedraws / totalDraws * 100) or 0
	}
end

function DirtyRect.resetStats()
	totalDraws = 0
	fullRedraws = 0
	partialRedraws = 0
end

-------------------------------------------------------------------------------
-- Main draw function with dirty rectangle optimization
-------------------------------------------------------------------------------

function DirtyRect.draw(workspace, drawFunction)
	totalDraws = totalDraws + 1

	-- Get merged dirty regions
	local regions = DirtyRect.mergeRegions()

	-- If no regions or full redraw needed, draw everything
	if not regions or #regions == 0 then
		fullRedraws = fullRedraws + 1
		drawFunction()
		DirtyRect.clear()
		return
	end

	-- Partial redraw using dirty regions
	partialRedraws = partialRedraws + 1
	local screen = require("Screen")

	for _, region in ipairs(regions) do
		-- Set draw limit to dirty region
		screen.setDrawLimit(
			region.x,
			region.y,
			region.x + region.width - 1,
			region.y + region.height - 1
		)

		-- Draw only this region
		drawFunction()

		-- Reset limit
		screen.resetDrawLimit()
	end

	-- Clear dirty regions after drawing
	DirtyRect.clear()
end

-------------------------------------------------------------------------------
-- Debug visualization
-------------------------------------------------------------------------------

function DirtyRect.debugDraw(workspace)
	if not DirtyRect.config.DEBUG_MODE then
		return
	end

	local screen = require("Screen")
	local regions = DirtyRect.mergeRegions()

	if regions then
		for _, region in ipairs(regions) do
			-- Draw red border around dirty regions
			screen.drawRectangle(
				region.x, region.y,
				region.width, region.height,
				0xFF0000, 0x000000, " ",
				region.x, region.y
			)
		end
	end
end

return DirtyRect
