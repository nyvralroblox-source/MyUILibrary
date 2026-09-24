--[[
	Textbox
	Champ texte avec confirmation Entrée.
]]

local Utility = require(script.Parent.Parent.Utility)
local Signals = require(script.Parent.Parent.Signals)

local Textbox = {}
Textbox.__index = Textbox

function Textbox.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Textbox)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Textbox"
	self.Flag = options.Flag
	self.Value = options.Default or ""
	self.Changed = Signals.new()
	self.Instance = self:_build(parent)
	self:_bind()
	library:RegisterFlag(self)
	return self
end

function Textbox:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 58)
	row.Name = "Textbox"
	Utility.label(row, self.Library, self.Title)
	self.Box = Utility.create("TextBox", {
		Parent = row,
		BackgroundColor3 = theme.ElementHover,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderText = self.Options.Placeholder or "Type...",
		PlaceholderColor3 = theme.Muted,
		Text = self.Value,
		TextColor3 = theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 28),
	})
	Utility.corner(self.Box, 6)
	Utility.padding(self.Box, 6)
	self.Library.Theme:Bind(self.Box, "BackgroundColor3", "ElementHover")
	self.Library.Theme:Bind(self.Box, "TextColor3", "Text")
	return row
end

function Textbox:_bind()
	self.Box.FocusLost:Connect(function(enter)
		self:Set(self.Box.Text, false)
	end)
end

function Textbox:Set(value, silent)
	self.Value = tostring(value or "")
	self.Box.Text = self.Value
	self.Library:WriteFlag(self.Flag, self.Value)
	if not silent and self.Options.Callback then
		self.Options.Callback(self.Value)
	end
	self.Changed:Fire(self.Value)
	self.Library.Config:MaybeAutoSave()
end

function Textbox:Get()
	return self.Value
end

function Textbox:Destroy()
	Utility.destroy(self.Instance)
end

return Textbox
