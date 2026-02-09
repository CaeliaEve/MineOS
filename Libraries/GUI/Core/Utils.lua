-------------------------------------------------------------------------------
-- GUI Core Utils
-- Utility functions for alignment, margins, and coordinates
-- Extracted from GUI.lua for reusability
-------------------------------------------------------------------------------

local Utils = {}
local Constants = require("GUI.Core.Constants")

-------------------------------------------------------------------------------
-- Alignment functions
-------------------------------------------------------------------------------

function Utils.setAlignment(object, horizontalAlignment, verticalAlignment)
	object.horizontalAlignment = horizontalAlignment
	object.verticalAlignment = verticalAlignment
	return object
end

function Utils.getAlignmentCoordinates(x, y, width1, height1, horizontalAlignment, verticalAlignment, width2, height2)
	if horizontalAlignment == Constants.ALIGNMENT_HORIZONTAL_CENTER then
		x = x + width1 / 2 - width2 / 2
	elseif horizontalAlignment == Constants.ALIGNMENT_HORIZONTAL_RIGHT then
		x = x + width1 - width2
	elseif horizontalAlignment ~= Constants.ALIGNMENT_HORIZONTAL_LEFT then
		error("Unknown horizontal alignment: " .. tostring(horizontalAlignment))
	end

	if verticalAlignment == Constants.ALIGNMENT_VERTICAL_CENTER then
		y = y + height1 / 2 - height2 / 2
	elseif verticalAlignment == Constants.ALIGNMENT_VERTICAL_BOTTOM then
		y = y + height1 - height2
	elseif verticalAlignment ~= Constants.ALIGNMENT_VERTICAL_TOP then
		error("Unknown vertical alignment: " .. tostring(verticalAlignment))
	end

	return x, y
end

function Utils.getMarginCoordinates(x, y, horizontalAlignment, verticalAlignment, horizontalMargin, verticalMargin)
	if horizontalAlignment == Constants.ALIGNMENT_HORIZONTAL_RIGHT then
		x = x - horizontalMargin
	else
		x = x + horizontalMargin
	end

	if verticalAlignment == Constants.ALIGNMENT_VERTICAL_BOTTOM then
		y = y - verticalMargin
	else
		y = y + verticalMargin
	end

	return x, y
end

-------------------------------------------------------------------------------
-- Geometry functions
-------------------------------------------------------------------------------

function Utils.isPointInside(object, x, y)
	return
		x >= object.x and
		x < object.x + object.width and
		y >= object.y and
		y < object.y + object.height
end

function Utils.getRectangleBounds(R1X1, R1Y1, R1X2, R1Y2, R2X1, R2Y1, R2X2, R2Y2)
	if R2X1 <= R1X2 and R2Y1 <= R1Y2 and R2X2 >= R1X1 and R2Y2 >= R1Y1 then
		return
			math.max(R2X1, R1X1),
			math.max(R2Y1, R1Y1),
			math.min(R2X2, R1X2),
			math.min(R2Y2, R1Y2)
	else
		return
	end
end

-------------------------------------------------------------------------------
-- Color utilities
-------------------------------------------------------------------------------

function Utils.blendColors(color1, color2, coefficient)
	local r1, g1, b1 = color1 % 0x100, math.floor(color1 / 0x100) % 0x100, math.floor(color1 / 0x10000)
	local r2, g2, b2 = color2 % 0x100, math.floor(color2 / 0x100) % 0x100, math.floor(color2 / 0x10000)

	local r = r1 + (r2 - r1) * coefficient
	local g = g1 + (g2 - g1) * coefficient
	local b = b1 + (b2 - b1) * coefficient

	return r + g * 0x100 + b * 0x10000
end

-------------------------------------------------------------------------------
-- Text utilities
-------------------------------------------------------------------------------

function Utils.getWordLimit(text, width)
	local length = 0

	for word in text:gmatch("[^%s]+") do
		length = length + #word + 1
		if length > width then
			return width
		end
	end

	return length
end

function Utils.getTextLimit(text)
	return #text
end

-------------------------------------------------------------------------------
-- Container utilities
-------------------------------------------------------------------------------

function Utils.indexOf(object)
	if not object.parent then
		error("Object doesn't have a parent container")
	end

	for objectIndex = 1, #object.parent.children do
		if object.parent.children[objectIndex] == object then
			return objectIndex
		end
	end
end

return Utils
