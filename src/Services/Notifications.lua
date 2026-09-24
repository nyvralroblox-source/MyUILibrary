--[[
	Notifications
	Pile de toasts en haut à droite.
]]

local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Icons = require(script.Parent.Parent.Assets.Icons)

local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(library, host)
	local self = setmetatable({}, Notifications)
	self.Library = library
	self.Host = host
	self._items = {}
	self._layout = Utility.create("UIListLayout", {
		Parent = host,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	Utility.create("UIPadding", {
		Parent = host,
		PaddingTop = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
	})
	return self
end

function Notifications:_toneColor(kind)
	local theme = self.Library.Theme:Get()
	if kind == "success" then
		return theme.Success
	end
	if kind == "warning" then
		return theme.Warning
	end
	if kind == "error" then
		return theme.Error
	end
	return theme.Accent
end

function Notifications:_makeCard(options, color)
	local theme = self.Library.Theme:Get()
	local card = Utility.create("Frame", {
		Parent = self.Host,
		Name = "Notification",
		BackgroundColor3 = theme.Section,
		Size = UDim2.fromOffset(280, 64),
		BorderSizePixel = 0,
	})
	Utility.corner(card, 10)
	Utility.stroke(card, theme.Stroke, 1)
	local bar = Utility.create("Frame", {
		Parent = card,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	})
	Utility.corner(bar, 10)
	Utility.create("TextLabel", {
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -28, 0, 20),
		Font = Enum.Font.GothamMedium,
		Text = options.Title or Icons.Bell,
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Utility.create("TextLabel", {
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 30),
		Size = UDim2.new(1, -28, 0, 26),
		Font = Enum.Font.Gotham,
		Text = options.Content or "",
		TextColor3 = theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	return card
end

function Notifications:Push(options)
	options = options or {}
	local color = self:_toneColor(options.Type)
	local card = self:_makeCard(options, color)
	table.insert(self._items, card)
	Animation.notifyIn(card)
	local duration = options.Duration or 4
	task.delay(duration, function()
		self:Dismiss(card)
	end)
	return card
end

function Notifications:Dismiss(card)
	Animation.notifyOut(card, function()
		Utility.destroy(card)
	end)
end

function Notifications:Clear()
	for _, card in ipairs(self._items) do
		Utility.destroy(card)
	end
	self._items = {}
end

return Notifications
