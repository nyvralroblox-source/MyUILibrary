# API Reference

All public methods live on the singleton returned by `require` / `init.lua`.

```lua
local Library = require(path.to.MyUILibrary)
```

## Library

| Method | Description |
| --- | --- |
| `CreateWindow(options)` | Creates a window. `Title`, `Size`, `DestroyOnClose`. |
| `SetTheme("Dark" \| "Light")` | Applies a palette. |
| `SetAccent(Color3)` | Updates accent + hover variant. |
| `ToggleTheme()` | Swaps Dark / Light. |
| `Notify({ Title, Content, Type, Duration })` | Toast. `Type`: `info`, `success`, `warning`, `error`. |
| `SaveConfig(name?)` | Writes flags, theme, window geometry. |
| `LoadConfig(name?)` | Restores a saved profile. |
| `SetAutoSave(boolean)` | Saves after flag changes. |
| `Toggle()` | Hide / show all windows. |
| `Destroy()` | Destroys every window. |
| `Flags` | Table of current flag values. |
| `Version` | Semver string. |

## Window

| Method | Description |
| --- | --- |
| `AddTab(name, icon?)` | Sidebar tab. |
| `SelectTab(tab)` | Activates a tab. |
| `SetTitle(text)` | Updates the topbar. |
| `Search(query)` | Filters the active tab. |
| `Minimize()` | Collapses to the topbar. |
| `Maximize()` | Fills the screen / restores. |
| `Hide()` / `Show()` | Visibility without destroy. |
| `Close()` | Animated close. Destroys if `DestroyOnClose`. |
| `ShowModal({ Title, Content, Callback })` | Dimmed dialog. |
| `ShowPopup(text, position?)` | Small overlay. |
| `ShowContext()` | Context menu. |
| `Refresh()` | Re-selects the current tab. |
| `Destroy()` | Removes the ScreenGui. |

## Tab

| Method | Description |
| --- | --- |
| `AddSection(title)` | Card on the page. |
| `AddGroupbox(title)` | Nested group on the page. |
| `Search(query)` | Forwards to children. |

## Section & Groupbox

Shared component factories:

- `AddButton(options)`
- `AddToggle(options)`
- `AddSlider(options)`
- `AddDropdown(options)`
- `AddTextbox(options)`
- `AddColorpicker(options)`
- `AddKeybind(options)`
- `AddParagraph(options)`
- `AddLabel(options)`
- `AddDivider()`
- `AddImage(options)`
- `AddGroupbox(title)` (Section only)

Common option keys: `Title`, `Flag`, `Default`, `Callback`, `Tooltip`.

## Components

### Button

```lua
section:AddButton({
	Title = "Run",
	Callback = function() end,
})
```

`Fire()`, `SetTitle(text)`, `Destroy()`.

### Toggle

```lua
section:AddToggle({
	Title = "On",
	Flag = "On",
	Default = false,
	Callback = function(value) end,
})
```

`Set(boolean, silent?)`, `Get()`.

### Slider

```lua
section:AddSlider({
	Title = "Speed",
	Flag = "Speed",
	Min = 0, Max = 10, Increment = 0.1, Default = 1,
	Callback = function(value) end,
})
```

### Dropdown

```lua
section:AddDropdown({
	Title = "Mode",
	Values = { "A", "B" },
	Default = "A",
	Multi = false,
	Flag = "Mode",
	Callback = function(value) end,
})
```

`Refresh(values)`, `Toggle(open)`.

### Textbox

`Placeholder`, `Default` string, `Callback(text)`.

### Colorpicker

`Default = Color3`, `Callback(color)`.

### Keybind

```lua
section:AddKeybind({
	Title = "Menu",
	Default = Enum.KeyCode.RightShift,
	Mode = "Toggle", -- or "Hold"
	Callback = function(active) end,
})
```

### Paragraph / Label / Divider / Image

- Paragraph: `Title`, `Content`
- Label: `Text` or `Title`
- Divider: no options
- Image: `Image` (rbxassetid), `Height`, `Title`

## Signals

Each interactive component exposes `Changed` (`Connect` / `Fire` / `Wait`).

## Animation

All tweens go through `src/Animation.lua` (`fade`, `slide`, `resize`, `hover`, `press`, `ripple`, dropdown, toggle, slider, notify, window open/close).

## Theme tokens

`Background`, `Window`, `Sidebar`, `Topbar`, `Footer`, `Content`, `Section`, `Groupbox`, `Element`, `ElementHover`, `ElementActive`, `Stroke`, `Text`, `SubText`, `Muted`, `Accent`, `AccentHover`, `Success`, `Warning`, `Error`, `Shadow`, `Overlay`, `ToggleOff`, `SliderTrack`, `Tooltip`, `Modal`.
