--[[
	Keybind
	Raccourci clavier avec mode Toggle / Hold.
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)
local Signals = require(script.Parent.Parent.Signals)

local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Keybind)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Keybind"
	self.Flag = options.Flag
	self.Mode = options.Mode or "Toggle"
	self.Value = options.Default or Enum.KeyCode.RightShift
	self.Listening = false
	self.Active = false
	self.Changed = Signals.new()
	self.Instance = self:_build(parent)
	self:_bind()
	self:_label()
	library:RegisterFlag(self)
	return self
end

function Keybind:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 38)
	row.Name = "Keybind"
	Utility.label(row, self.Library, self.Title)
	self.Chip = Utility.create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.ElementHover,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = theme.Text,
		Size = UDim2.fromOffset(88, 22),
		Position = UDim2.new(1, -98, 0.5, -11),
		Text = "",
	})
	Utility.corner(self.Chip, 6)
	return row
end

function Keybind:_label()
	if self.Listening then
		self.Chip.Text = "..."
		return
	end
	self.Chip.Text = self.Value and self.Value.Name or "None"
end

function Keybind:_bind()
	self.Chip.MouseButton1Click:Connect(function()
		self.Listening = true
		self:_label()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		self:_onInput(input, processed)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if self.Mode == "Hold" and input.KeyCode == self.Value then
			self.Active = false
			if self.Options.Callback then
				self.Options.Callback(false)
			end
		end
	end)
end

function Keybind:_onInput(input, processed)
	if self.Listening then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			self:Set(input.KeyCode)
			self.Listening = false
			self:_label()
		end
		return
	end
	if processed or input.KeyCode ~= self.Value then
		return
	end
	self:_trigger()
end

function Keybind:_trigger()
	if self.Mode == "Hold" then
		self.Active = true
		if self.Options.Callback then
			self.Options.Callback(true)
		end
		return
	end
	if self.Mode == "Toggle" then
		self.Active = not self.Active
	end
	if self.Options.Callback then
		self.Options.Callback(self.Active)
	end
	self.Changed:Fire(self.Value, self.Active)
end

function Keybind:Set(key, silent)
	if typeof(key) == "string" then
		key = Enum.KeyCode[key] or self.Value
	end
	self.Value = key
	self:_label()
	self.Library:WriteFlag(self.Flag, key and key.Name or "None")
	if not silent then
		self.Changed:Fire(self.Value, self.Active)
	end
	self.Library.Config:MaybeAutoSave()
end

function Keybind:Get()
	return self.Value
end

function Keybind:Destroy()
	Utility.destroy(self.Instance)
end

return Keybind
