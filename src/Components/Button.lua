--[[
	Button
	Bouton avec ripple, hover et callback.
]]

local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Signals = require(script.Parent.Parent.Signals)

local Button = {}
Button.__index = Button

function Button.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Button)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Button"
	self.Changed = Signals.new()
	self.Instance = self:_build(parent)
	self:_bind()
	return self
end

function Button:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 36)
	row.Name = "Button"
	self.Hit = Utility.create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 4),
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = self.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		ClipsDescendants = true,
	})
	Utility.corner(self.Hit, 7)
	self.Library.Theme:Bind(self.Hit, "BackgroundColor3", "Accent")
	if self.Options.Tooltip then
		self.Library.Tooltip:Bind(self.Hit, self.Options.Tooltip)
	end
	return row
end

function Button:_bind()
	local theme = self.Library.Theme
	self.Hit.MouseEnter:Connect(function()
		Animation.hover(self.Hit, theme:Get().AccentHover)
	end)
	self.Hit.MouseLeave:Connect(function()
		Animation.hover(self.Hit, theme:Get().Accent)
		Animation.release(self.Hit)
	end)
	self.Hit.MouseButton1Down:Connect(function()
		Animation.press(self.Hit)
	end)
	self.Hit.MouseButton1Up:Connect(function()
		Animation.release(self.Hit)
	end)
	self.Hit.MouseButton1Click:Connect(function()
		local mouse = Utility.mousePosition()
		local abs = self.Hit.AbsolutePosition
		local origin = UDim2.fromOffset(mouse.X - abs.X, mouse.Y - abs.Y)
		Animation.ripple(self.Hit, origin)
		self:Fire()
	end)
end

function Button:Fire()
	if self.Options.Callback then
		self.Options.Callback()
	end
	self.Changed:Fire()
end

function Button:SetTitle(text)
	self.Title = text
	self.Hit.Text = text
end

function Button:Destroy()
	Utility.destroy(self.Instance)
end

return Button
