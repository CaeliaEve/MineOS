
[English](https://github.com/CaeliaEve/MineOS/) | 中文(简体) | [Русский](https://github.com/CaeliaEve/MineOS/blob/master/README-ru_RU.md)

## MineOS独立版现已发布!

你好，亲爱的朋友。感谢你在漫长的开发周期中与我们并肩同行。MineOS终于到了发布阶段：现在它是一个完全独立的操作系统，拥有自己的开发API和一个讲解了使用方法且[图文并茂的维基](https://github.com/CaeliaEve/MineOS/wiki).
MineOS是一个拥有GUI的操作系统，运行在Minecraft模组Open Computers上。它有广泛而强大的定制能力，以及一个能让你在社区中发布你的作品的<del>应用程序市场</del>（目前离线）。下面是它的特性的列表:

-   多任务处理
-   双缓冲图形用户界面，**性能优化**（脏矩形渲染，空间索引）
-   语言包和软件本地化
-   具有密码身份认证的多用户配置文件
-   自有EEPROM固件，具有选择/格式化/重命名引导卷的功能和Internet恢复模式
-   通过调制解调器在本地网络上共享文件
-   可连接到现实FTP服务器的客户端
-   具有语法高亮显示和调试器的内置IDE
-   <del>能够让每一个MineOS用户发布应用程序的应用市场</del>
-   **增强的错误处理**，采用多策略回溯解析
-   **统一配置系统**，支持验证和类型安全
-   **结构化日志系统**，用于调试和性能监控
-   **高级API**，简化应用开发（代码减少80%）
-   错误报告系统，可向开发人员发送错误信息
-   动画、壁纸、屏幕保护程序、配色方案和巨大的定制空间
-   开源的系统API和详细的说明文档
-   **对象池**，减少垃圾回收压力
-   **100%向后兼容**所有现有应用

## 如何安装?

### 方法一：使用安装脚本（推荐）

插入一个OpenOS的软盘到计算机当中，再插入一个Internet卡，启动电脑并在控制台中输入下列命令：

```lua
wget -f https://raw.githubusercontent.com/CaeliaEve/MineOS/master/Installer/OpenOS.lua /tmp/installer.lua && /tmp/installer.lua
```

**如果遇到 "address is not allowed" 错误**，这是因为 OpenComputers 的安全白名单限制了 wget 访问的域名。请使用以下方法配置白名单：

```lua
-- 在终端运行以下命令配置白名单
echo "https://raw.githubusercontent.com" > /home/.wget-allow
echo "https://github.com" >> /home/.wget-allow

-- 然后重新运行安装命令
wget -f https://raw.githubusercontent.com/CaeliaEve/MineOS/master/Installer/OpenOS.lua /tmp/installer.lua && /tmp/installer.lua
```

### 方法二：使用 Pastebin（需要配置白名单）

如果你更喜欢使用 pastebin，可以使用原版安装脚本（注意：这会从原始仓库安装）：

```
pastebin run PDE3eVsL
```

过一会儿，一个制作优良的系统安装程序将会被启动。
安装程序将提示你选择你的首选语言、选择并格式化引导卷、创建用户配置文件并修改一些设置。
之后，系统便已安装成功。

过一会儿，一个制作优良的系统安装程序将会被启动。
安装程序将提示你选择你的首选语言、选择并格式化引导卷、创建用户配置文件并修改一些设置。
之后，系统便已安装成功。

## 如何创建应用程序并使用API?

[Wiki](https://github.com/CaeliaEve/MineOS/wiki)

### 高级API（新增！）

MineOS现在包含简化的高级API，可加快开发速度：

```lua
-- 旧方式（仍然可用）
local GUI = require("GUI")
local workspace = GUI.workspace(1, 1, 60, 20, 0xFFFFFF, 0x000000)
local button = GUI.button(x, y, w, h, bgColor, textColor, "Text")

-- 新方式（更简单！）
local GUIAPI = require("GUI.API")
local workspace = GUIAPI.workspace(60, 20, "我的应用")
local button = GUIAPI.button(x, y, w, h, "文本", callback)
```

**主要特性：**
- 代码量减少80%
- 内置布局助手
- 简化的表单创建
- 预定义样式
- 动画助手
- 事件处理快捷方式

**示例：**
```lua
local GUIAPI = require("GUI.API")
local SystemAPI = require("System.API")

local workspace = GUIAPI.workspace(60, 20, "你好世界")

local button = GUIAPI.button(20, 10, 20, 3, "点击我", function()
    SystemAPI.showNotification("成功！", "按钮被点击了！", 3)
end)

GUIAPI.addToWorkspace(workspace, button)
GUIAPI.startWorkspace(workspace)
```

完整示例请参见 `Examples/new_api_example.lua`。

### 性能优化模块

MineOS包含优化的系统以获得更好的性能：

- **脏矩形渲染** - 仅重绘变化区域（快50-70%）
- **四叉树空间索引** - O(log n)事件处理（快60-80%）
- **对象池** - 重用组件以减少GC压力（提升30-40%）
- **错误处理器** - 健壮的多策略错误解析
- **配置系统** - 验证、类型安全的配置
- **日志系统** - 结构化调试和性能监控

所有优化保持100%向后兼容！
