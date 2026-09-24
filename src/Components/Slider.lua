--[[
	Slider
	Curseur numérique avec fill animé.
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Signals = require(script.Parent.Parent.Signals)

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Slider)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Slider"
	self.Flag = options.Flag
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Increment = options.Increment or 1
	self.Value = options.Default or self.Min
	self.Changed = Signals.new()
	self._sliding = false
	self.Instance = self:_build(parent)
	self:_bind()
	self:_render(false)
	library:RegisterFlag(self)
	return self
end

function Slider:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 52)
	row.Name = "Slider"
	Utility.label(row, self.Library, self.Title)
	self.ValueLabel = Utility.create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -58, 0, 8),
		Size = UDim2.fromOffset(50, 18),
		Font = Enum.Font.GothamMedium,
		TextColor3 = theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(self.Value),
	})
	self.Track = Utility.create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.SliderTrack,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.new(1, -20, 0, 6),
		Position = UDim2.new(0, 10, 1, -16),
	})
	Utility.corner(self.Track, 4)
	self.Library.Theme:Bind(self.Track, "BackgroundColor3", "SliderTrack")
	self.Fill = Utility.create("Frame", {
		Parent = self.Track,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
	})
	Utility.corner(self.Fill, 4)
	self.Library.Theme:Bind(self.Fill, "BackgroundColor3", "Accent")
	return row
end

function Slider:_bind()
	self.Track.InputBegan:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._sliding = true
			self:_fromMouse()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._sliding = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if self._sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			self:_fromMouse()
		end
	end)
end

function Slider:_fromMouse()
	local mouse = Utility.guiMouse().X
	local abs = self.Track.AbsolutePosition.X
	local width = self.Track.AbsoluteSize.X
	local alpha = Utility.clamp((mouse - abs) / math.max(width, 1), 0, 1)
	local raw = self.Min + (self.Max - self.Min) * alpha
	local stepped = math.floor(raw / self.Increment + 0.5) * self.Increment
	self:Set(Utility.clamp(stepped, self.Min, self.Max))
end

function Slider:_render(animate)
	local alpha = 0
	if self.Max ~= self.Min then
		alpha = (self.Value - self.Min) / (self.Max - self.Min)
	end
	self.ValueLabel.Text = tostring(self.Value)
	if animate == false then
		self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
	else
		Animation.sliderFill(self.Fill, alpha)
	end
end

function Slider:Set(value, silent)
	self.Value = Utility.round(value, 4)
	self:_render(true)
	self.Library:WriteFlag(self.Flag, self.Value)
	if not silent and self.Options.Callback then
		self.Options.Callback(self.Value)
	end
	self.Changed:Fire(self.Value)
	self.Library.Config:MaybeAutoSave()
end

function Slider:Get()
	return self.Value
end

function Slider:Destroy()
	Utility.destroy(self.Instance)
end

return Slider
