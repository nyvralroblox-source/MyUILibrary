--[[
	Colorpicker
	Sélecteur HSV compact (teinte + saturation/valeur).
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)
local Signals = require(script.Parent.Parent.Signals)

local Colorpicker = {}
Colorpicker.__index = Colorpicker

function Colorpicker.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Colorpicker)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Color"
	self.Flag = options.Flag
	self.Value = options.Default or Color3.fromRGB(88, 140, 255)
	self.H, self.S, self.V = self.Value:ToHSV()
	self.Open = false
	self.Changed = Signals.new()
	self.Instance = self:_build(parent)
	self:_bind()
	library:RegisterFlag(self)
	return self
end

function Colorpicker:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 38)
	row.Name = "Colorpicker"
	Utility.label(row, self.Library, self.Title)
	self.Swatch = Utility.create("TextButton", {
		Parent = row,
		BackgroundColor3 = self.Value,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromOffset(42, 22),
		Position = UDim2.new(1, -52, 0.5, -11),
	})
	Utility.corner(self.Swatch, 6)
	Utility.stroke(self.Swatch, theme.Stroke, 1)
	self.Panel = self:_buildPanel(row)
	return row
end

function Colorpicker:_buildPanel(row)
	local theme = self.Library.Theme:Get()
	local panel = Utility.create("Frame", {
		Parent = row,
		BackgroundColor3 = theme.Modal,
		Visible = false,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(180, 148),
		Position = UDim2.new(1, -190, 1, 6),
		ZIndex = 30,
	})
	Utility.corner(panel, 8)
	Utility.stroke(panel, theme.Stroke, 1)
	self.Sv = Utility.create("ImageButton", {
		Parent = panel,
		BackgroundColor3 = Color3.fromHSV(self.H, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		Size = UDim2.fromOffset(150, 110),
		Position = UDim2.fromOffset(8, 8),
		ZIndex = 31,
	})
	Utility.corner(self.Sv, 6)
	self.Hue = Utility.create("TextButton", {
		Parent = panel,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromOffset(12, 110),
		Position = UDim2.fromOffset(162, 8),
		ZIndex = 31,
	})
	Utility.corner(self.Hue, 4)
	Utility.create("UIGradient", {
		Parent = self.Hue,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	})
	return panel
end

function Colorpicker:_bind()
	self.Swatch.MouseButton1Click:Connect(function()
		self.Open = not self.Open
		self.Panel.Visible = self.Open
		self.Instance.Size = UDim2.new(1, -2, 0, self.Open and 196 or 38)
	end)
	self.Hue.InputBegan:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._hueDrag = true
			self:_sampleHue()
		end
	end)
	self.Sv.InputBegan:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._svDrag = true
			self:_sampleSv()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._hueDrag = false
			self._svDrag = false
		end
	end)
	UserInputService.InputChanged:Connect(function()
		if self._hueDrag then
			self:_sampleHue()
		end
		if self._svDrag then
			self:_sampleSv()
		end
	end)
end

function Colorpicker:_sampleHue()
	local mouse = Utility.guiMouse().Y
	local abs = self.Hue.AbsolutePosition.Y
	local alpha = Utility.clamp((mouse - abs) / math.max(self.Hue.AbsoluteSize.Y, 1), 0, 1)
	self.H = alpha
	self.Sv.BackgroundColor3 = Color3.fromHSV(self.H, 1, 1)
	self:_commit()
end

function Colorpicker:_sampleSv()
	local mouse = Utility.guiMouse()
	local pos = self.Sv.AbsolutePosition
	local size = self.Sv.AbsoluteSize
	self.S = Utility.clamp((mouse.X - pos.X) / math.max(size.X, 1), 0, 1)
	self.V = 1 - Utility.clamp((mouse.Y - pos.Y) / math.max(size.Y, 1), 0, 1)
	self:_commit()
end

function Colorpicker:_commit()
	self:Set(Color3.fromHSV(self.H, self.S, self.V))
end

function Colorpicker:Set(color, silent)
	self.Value = color
	self.H, self.S, self.V = color:ToHSV()
	self.Swatch.BackgroundColor3 = color
	self.Library:WriteFlag(self.Flag, Utility.colorToTable(color))
	if not silent and self.Options.Callback then
		self.Options.Callback(color)
	end
	self.Changed:Fire(color)
	self.Library.Config:MaybeAutoSave()
end

function Colorpicker:Get()
	return self.Value
end

function Colorpicker:Destroy()
	Utility.destroy(self.Instance)
end

return Colorpicker
