# MyUILibrary

Modern, modular Roblox UI library. Dark-first interface with rounded frames, strokes, gradients, and TweenService-only motion. Inspired by the *quality bar* of popular hubs — **original codebase**, no copied implementations.

![Lua](https://img.shields.io/badge/Lua-Luau-blue)
![Roblox](https://img.shields.io/badge/Roblox-UI-000)
![License](https://img.shields.io/badge/License-MIT-green)

```
┌──────────────────────────────────────────────┐
│  MyUI          My Hub        ⌕ Search   – □ ✕ │
│ ──────────┬───────────────────────────────────│
│ NAVIGATION│  Combat                           │
│  ◆ Main   │  ┌─────────────────────────────┐  │
│  ◆ Extra  │  │  Toggle        [ ●──── ]    │  │
│           │  │  Slider        ██████────   │  │
│           │  └─────────────────────────────┘  │
│           │                                   │
│───────────┴───────────────────────────────────│
│  MyUILibrary · Dark              ☾ Theme      │
└──────────────────────────────────────────────┘
```

## Features

- Windows: drag, resize, minimize, maximize, close, search  
- Tabs, sections, groupboxes  
- Button, Toggle, Slider, Dropdown, Textbox, Colorpicker, Keybind  
- Label, Paragraph, Divider, Image  
- Notifications, tooltips, context menu, modal, popup  
- Dark / Light palettes and live accent color  
- Flags, JSON config, optional auto-save  
- Centralized animations (`src/Animation.lua`)  
- Zero external dependencies  

## Installation

Copy `src` into your place as a ModuleScript tree (`init.lua` is the root). With [Rojo](https://rojo.space):

```json
{
  "name": "MyUILibrary",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "MyUILibrary": { "$path": "src" }
    }
  }
}
```

```lua
local Library = require(game.ReplicatedStorage.MyUILibrary)
```

`loadstring` works once you ship a **single bundled ModuleScript**. This repo is the maintainable source layout.

## Quick start

```lua
local Library = require(game.ReplicatedStorage.MyUILibrary)

local Window = Library:CreateWindow({
	Title = "My Hub",
	Size = UDim2.fromOffset(650, 420),
})

local Main = Window:AddTab("Main")
local Combat = Main:AddSection("Combat")

Combat:AddButton({ Title = "Hello", Callback = function() end })
Combat:AddToggle({ Title = "Aim", Flag = "Aim", Default = false })
Combat:AddSlider({ Title = "FOV", Flag = "FOV", Min = 10, Max = 120, Default = 70 })
Combat:AddDropdown({ Title = "Mode", Values = { "A", "B" }, Flag = "Mode" })
Combat:AddTextbox({ Title = "Name", Flag = "Name" })
Combat:AddColorpicker({ Title = "Accent", Flag = "Color" })
Combat:AddKeybind({ Title = "Menu", Default = Enum.KeyCode.RightShift })
```

See [`Example/Example.lua`](Example/Example.lua), [`docs/GettingStarted.md`](docs/GettingStarted.md), and [`docs/API.md`](docs/API.md).

## Project layout

```
src/           library modules (objects, components, services)
Example/       LocalScript demo
docs/          Getting started + API
configs/       JSON profiles (runtime)
```

## Config

```lua
Library:SetAutoSave(true)
Library:SaveConfig("default")
Library:LoadConfig("default")
print(Library.Flags.Aim)
```

Executor environments persist `configs/*.json`. Studio keeps the same payload in memory for the session.

## License

MIT — see [LICENSE](LICENSE).
