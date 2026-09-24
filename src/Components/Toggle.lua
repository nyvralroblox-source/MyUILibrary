--[[
	Toggle
	Interrupteur on/off avec flag.
]]

local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Signals = require(script.Parent.Parent.Signals)

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Toggle)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Toggle"
	self.Flag = options.Flag
	self.Value = options.Default and true or false
	self.Changed = Signals.new()
	self.Instance = self:_build(parent)
	self:_bind()
	self:_paint(false)
	library:RegisterFlag(self)
	return self
end

function Toggle:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 38)
	row.Name = "Toggle"
	Utility.label(row, self.Library, self.Title)
	self.Track = Utility.create("Frame", {
		Parent = row,
		BackgroundColor3 = theme.ToggleOff,
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BorderSizePixel = 0,
	})
	Utility.corner(self.Track, 10)
	self.Knob = Utility.create("Frame", {
		Parent = self.Track,
		BackgroundColor3 = Color3.fromRGB(240, 240, 245),
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
	})
	Utility.corner(self.Knob, 8)
	self.Hit = Utility.create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})
	if self.Options.Tooltip then
		self.Library.Tooltip:Bind(self.Hit, self.Options.Tooltip)
	end
	return row
end

function Toggle:_bind()
	self.Hit.MouseButton1Click:Connect(function()
		self:Set(not self.Value)
	end)
end

function Toggle:_paint(animate)
	local theme = self.Library.Theme:Get()
	local color = self.Value and theme.Accent or theme.ToggleOff
	if animate == false then
		self.Track.BackgroundColor3 = color
		self.Knob.Position = UDim2.new(0, self.Value and 22 or 2, 0.5, 0)
	else
		Animation.tween(self.Track, { BackgroundColor3 = color }, Animation.Info.Fast)
		Animation.toggleKnob(self.Knob, self.Value, Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 240, 245))
	end
end

function Toggle:Set(value, silent)
	self.Value = value and true or false
	self:_paint(true)
	self.Library:WriteFlag(self.Flag, self.Value)
	if not silent then
		if self.Options.Callback then
			self.Options.Callback(self.Value)
		end
		self.Changed:Fire(self.Value)
	end
	self.Library.Config:MaybeAutoSave()
end

function Toggle:Get()
	return self.Value
end

function Toggle:Destroy()
	Utility.destroy(self.Instance)
end

return Toggle
