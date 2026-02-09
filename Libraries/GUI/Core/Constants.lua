-------------------------------------------------------------------------------
-- GUI Core Constants
-- Exports all GUI constants for use in modular code
-- Extracted from GUI.lua for better organization
-------------------------------------------------------------------------------

local Constants = {}

-- Alignment constants
Constants.ALIGNMENT_HORIZONTAL_LEFT = 1
Constants.ALIGNMENT_HORIZONTAL_CENTER = 2
Constants.ALIGNMENT_HORIZONTAL_RIGHT = 3
Constants.ALIGNMENT_VERTICAL_TOP = 4
Constants.ALIGNMENT_VERTICAL_CENTER = 5
Constants.ALIGNMENT_VERTICAL_BOTTOM = 6

-- Direction constants
Constants.DIRECTION_HORIZONTAL = 7
Constants.DIRECTION_VERTICAL = 8

-- Size policy constants
Constants.SIZE_POLICY_ABSOLUTE = 9
Constants.SIZE_POLICY_RELATIVE = 10

-- IO mode constants
Constants.IO_MODE_FILE = 11
Constants.IO_MODE_DIRECTORY = 12
Constants.IO_MODE_BOTH = 13
Constants.IO_MODE_OPEN = 14
Constants.IO_MODE_SAVE = 15

-- Animation durations
Constants.BUTTON_PRESS_DURATION = 0.2
Constants.BUTTON_ANIMATION_DURATION = 0.2
Constants.SWITCH_ANIMATION_DURATION = 0.3
Constants.FILESYSTEM_DIALOG_ANIMATION_DURATION = 0.5

-- Context menu colors
Constants.CONTEXT_MENU_DEFAULT_BACKGROUND_COLOR = 0x1E1E1E
Constants.CONTEXT_MENU_DEFAULT_ICON_COLOR = 0x696969
Constants.CONTEXT_MENU_DEFAULT_TEXT_COLOR = 0xD2D2D2
Constants.CONTEXT_MENU_PRESSED_BACKGROUND_COLOR = 0x3366CC
Constants.CONTEXT_MENU_PRESSED_ICON_COLOR = 0xB4B4B4
Constants.CONTEXT_MENU_PRESSED_TEXT_COLOR = 0xFFFFFF
Constants.CONTEXT_MENU_DISABLED_ICON_COLOR = 0x5A5A5A
Constants.CONTEXT_MENU_DISABLED_TEXT_COLOR = 0x5A5A5A
Constants.CONTEXT_MENU_BACKGROUND_TRANSPARENCY = nil
Constants.CONTEXT_MENU_SHADOW_TRANSPARENCY = 0.4
Constants.CONTEXT_MENU_SEPARATOR_COLOR = 0x2D2D2D

-- Background container colors
Constants.BACKGROUND_CONTAINER_PANEL_COLOR = 0x0
Constants.BACKGROUND_CONTAINER_TITLE_COLOR = 0xE1E1E1
Constants.BACKGROUND_CONTAINER_PANEL_TRANSPARENCY = 0.3

-- Window colors
Constants.WINDOW_BACKGROUND_PANEL_COLOR = 0xF0F0F0
Constants.WINDOW_SHADOW_TRANSPARENCY = 0.6
Constants.WINDOW_TITLE_BACKGROUND_COLOR = 0xE1E1E1
Constants.WINDOW_TITLE_TEXT_COLOR = 0x2D2D2D
Constants.WINDOW_TAB_BAR_DEFAULT_BACKGROUND_COLOR = 0x2D2D2D
Constants.WINDOW_TAB_BAR_DEFAULT_TEXT_COLOR = 0xF0F0F0
Constants.WINDOW_TAB_BAR_SELECTED_BACKGROUND_COLOR = 0xF0F0F0
Constants.WINDOW_TAB_BAR_SELECTED_TEXT_COLOR = 0x2D2D2D

-- Lua syntax color scheme
Constants.LUA_SYNTAX_COLOR_SCHEME = {
	background = 0x1E1E1E,
	text = 0xE1E1E1,
	strings = 0x99FF80,
	loops = 0xFFFF98,
	comments = 0x898989,
	boolean = 0xFFDB40,
	logic = 0xFFCC66,
	numbers = 0x66DBFF,
	functions = 0xFFCC66,
	compares = 0xFFCC66,
	lineNumbersBackground = 0x2D2D2D,
	lineNumbersText = 0xC3C3C3,
	scrollBarBackground = 0x2D2D2D,
	scrollBarForeground = 0x5A5A5A,
	selection = 0x4B4B4B,
	indentation = 0x2D2D2D
}

-- Lua syntax patterns
Constants.LUA_SYNTAX_PATTERNS = {
	"[%.%,%>%<%=%~%+%-%*%/%^%#%%%&]", "compares", 0, 0,
	"[^%a%d][%.%d]+[^%a%d]", "numbers", 1, 1,
	"[^%a%d][%.%d]+$", "numbers", 1, 0,
	"0x%w+", "numbers", 0, 0,
	" not ", "logic", 0, 1,
	" or ", "logic", 0, 1,
	" and ", "logic", 0, 1,
	"function%(", "functions", 0, 1,
	"function%s[^%s%(%)%{%}%[%]]+%(", "functions", 9, 1,
	"nil", "boolean", 0, 0,
	"false", "boolean", 0, 0,
	"true", "boolean", 0, 0,
	" break$", "loops", 0, 0,
	"elseif ", "loops", 0, 1,
	"else[%s%;]", "loops", 0, 1,
	"else$", "loops", 0, 0,
	"function ", "loops", 0, 1,
	"local ", "loops", 0, 1,
	"return", "loops", 0, 0,
	"until ", "loops", 0, 1,
	"then", "loops", 0, 0,
	"if ", "loops", 0, 1,
	"repeat$", "loops", 0, 0,
	" in ", "loops", 0, 1,
	"for ", "loops", 0, 1,
	"end[%s%;]", "loops", 0, 1,
	"end$", "loops", 0, 0,
	"do ", "loops", 0, 1,
	"do$", "loops", 0, 0,
	"while ", "loops", 0, 1,
	"\'[^\']+\'", "strings", 0, 0,
	"\"[^\"]+\"", "strings", 0, 0,
	"%-%-.+", "comments", 0, 0,
}

return Constants
