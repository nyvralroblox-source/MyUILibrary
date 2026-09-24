# Getting Started

MyUILibrary is a Roblox UI toolkit written in Lua. Import the `src` folder as a **ModuleScript** (Rojo maps `src/init.lua` to that module).

## Studio (Rojo)

```toml
# default.project.json (example)
# "MyUILibrary": { "$path": "src" }
```

1. Clone this repository.
2. Point Rojo at `src` as a ModuleScript.
3. `require` it from a LocalScript.
4. Run `Example/Example.lua` after adjusting the `require` path.

```lua
local Library = require(game.ReplicatedStorage.MyUILibrary)

local Window = Library:CreateWindow({
	Title = "My Hub",
	Size = UDim2.fromOffset(650, 420),
})

local Main = Window:AddTab("Main")
local Combat = Main:AddSection("Combat")

Combat:AddToggle({
	Title = "Enabled",
	Flag = "Enabled",
	Default = false,
	Callback = function(value)
		print(value)
	end,
})
```

## Themes

```lua
Library:SetTheme("Dark")
Library:SetTheme("Light")
Library:SetAccent(Color3.fromRGB(255, 90, 120))
```

Footer **Theme** and right-click on the topbar also switch themes.

## Config

Flags (`Flag = "..."`) are collected automatically.

```lua
Library:SetAutoSave(true)
Library:SaveConfig("default")
Library:LoadConfig("default")
```

When `writefile` / `readfile` exist, JSON is stored in `configs/`. Otherwise the session keeps an in-memory copy.

## Toggle UI

**RightShift** hides or shows every window. Change `Library.UnloadBind` if needed.

## Layout

- Sidebar: tab navigation  
- Topbar: title, search, min / max / close  
- Content: scrolling sections  
- Footer: theme switcher  
- Overlay: tooltips, context menu, modal, popup  
- Notifications: top-right toasts  

Search filters the active tab by component title.
