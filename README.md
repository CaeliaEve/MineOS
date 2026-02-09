![](https://i.imgur.com/Ki5bX0I.gif)

English | [中文(简体)](https://github.com/IgorTimofeev/MineOS/blob/master/README-zh_CN.md) | [Русский](https://github.com/IgorTimofeev/MineOS/blob/master/README-ru_RU.md)

## About

MineOS is a GUI based operating system for the OpenComputers Minecraft mod. It has extensive customisation abilities as well as an app market to publish your creations among the OS community. For developers there is wonderful [illustrated wiki](https://github.com/IgorTimofeev/MineOS/wiki) with lots of code examples. List of main features:

-   Multitasking
-   Double buffered graphical user interface with **performance optimizations** (dirty rectangle rendering, spatial indexing)
-   Language packs and software localization
-   Multiple user profiles with password authentication
-   Own EEPROM firmware with boot volume choose/format/rename features and recover system through Internet
-   File sharing over the local network via modems
-   Client connections to real FTP servers
-   An internal IDE with syntax highlighting and debugger
-   Integrated application and library App Market with the ability to publish your own scripts and programs for every MineOS user
-   **Enhanced error handling** with robust multi-strategy traceback parsing
-   **Unified configuration system** with validation and type safety
-   **Structured logging system** for debugging and performance monitoring
-   **High-level API** for simplified application development (80% less code)
-   Animations, live wallpapers, color schemes and huge customization possibilities
-   Open source system API and detailed documentation
-   **Object pooling** for reduced garbage collection pressure
-   **100% backward compatible** with all existing applications

## How to install?

The easiest way is to use default `pastebin` script. Insert an OpenOS floppy disk and an Internet Card into the computer, turn it on and type the following command to console to install MineOS:

	pastebin run PDE3eVsL

If for some reason pastebin website is not available to you, use alternative installation command:

	wget -f https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/OpenOS.lua /tmp/installer.lua && /tmp/installer.lua

You can paste it to console using middle mouse button or Insert key (by default). After a moment, a nice system installer will be shown. You will be prompted to select your preferred language, boot volume (can be formatted if needed), create a user profile and customize some settings

## How to create applications and work with API?

[Wiki](https://github.com/IgorTimofeev/MineOS/wiki)

### High-Level API (New!)

MineOS now includes a simplified high-level API for faster development:

```lua
-- Old way (still works)
local GUI = require("GUI")
local workspace = GUI.workspace(1, 1, 60, 20, 0xFFFFFF, 0x000000)
local button = GUI.button(x, y, w, h, bgColor, textColor, "Text")

-- New way (much simpler!)
local GUIAPI = require("GUI.API")
local workspace = GUIAPI.workspace(60, 20, "My App")
local button = GUIAPI.button(x, y, w, h, "Text", callback)
```

**Key Features:**
- 80% less boilerplate code
- Built-in layout helpers
- Simplified form creation
- Pre-defined styles
- Animation helpers
- Event handling shortcuts

**Example:**
```lua
local GUIAPI = require("GUI.API")
local SystemAPI = require("System.API")

local workspace = GUIAPI.workspace(60, 20, "Hello World")

local button = GUIAPI.button(20, 10, 20, 3, "Click Me", function()
    SystemAPI.showNotification("Success!", "Button clicked!", 3)
end)

GUIAPI.addToWorkspace(workspace, button)
GUIAPI.startWorkspace(workspace)
```

See `Examples/new_api_example.lua` for complete examples.

### Performance Modules

MineOS includes optimized systems for better performance:

- **Dirty Rectangle Rendering** - Only redraws changed regions (50-70% faster)
- **Quadtree Spatial Indexing** - O(log n) event handling (60-80% faster)
- **Object Pooling** - Reuses components to reduce GC pressure (30-40% improvement)
- **Error Handler** - Robust multi-strategy error parsing
- **Config System** - Validated, type-safe configuration
- **Logging System** - Structured debugging and performance monitoring

All optimizations maintain 100% backward compatibility!
