--[[
	Tooltip
	Infobulle près du curseur au survol.
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(library, overlay)
	local self = setmetatable({}, Tooltip)
	self.Library = library
	self.Overlay = overlay
	self.Frame = self:_create()
	return self
end

function Tooltip:_create()
	local theme = self.Library.Theme:Get()
	local frame = Utility.create("TextLabel", {
		Parent = self.Overlay,
		Name = "Tooltip",
		BackgroundColor3 = theme.Tooltip,
		TextColor3 = Color3.fromRGB(245, 245, 250),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Visible = false,
		ZIndex = 200,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Utility.corner(frame, 6)
	Utility.padding(frame, 6)
	self.Library.Theme:Bind(frame, "BackgroundColor3", "Tooltip")
	return frame
end

function Tooltip:Bind(host, text)
	if not text or text == "" then
		return
	end
	host.MouseEnter:Connect(function()
		self:Show(text)
	end)
	host.MouseLeave:Connect(function()
		self:Hide()
	end)
end

function Tooltip:Show(text)
	self.Frame.Text = text
	self.Frame.Visible = true
	self:_follow()
	self._heartbeat = game:GetService("RunService").RenderStepped:Connect(function()
		self:_follow()
	end)
end

function Tooltip:_follow()
	local mouse = UserInputService:GetMouseLocation()
	local inset = game:GetService("GuiService"):GetGuiInset()
	self.Frame.Position = UDim2.fromOffset(mouse.X - inset.X + 14, mouse.Y - inset.Y + 14)
end

function Tooltip:Hide()
	self.Frame.Visible = false
	self._heartbeat = Utility.disconnect(self._heartbeat)
end

function Tooltip:Destroy()
	self:Hide()
	Utility.destroy(self.Frame)
end

return Tooltip
