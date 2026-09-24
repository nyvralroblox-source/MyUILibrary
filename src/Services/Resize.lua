--[[
	Resize
	Poignée bas-droite pour redimensionner la fenêtre.
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)
local Icons = require(script.Parent.Parent.Assets.Icons)

local Resize = {}
Resize.__index = Resize

function Resize.new(target, parent, options)
	options = options or {}
	local self = setmetatable({}, Resize)
	self.Target = target
	self.Min = options.Min or Vector2.new(420, 280)
	self.Max = options.Max or Vector2.new(1200, 800)
	self.Enabled = true
	self._resizing = false
	self._start = Vector2.new()
	self._size = Vector2.new()
	self.Grip = self:_createGrip(parent)
	self:_bind()
	return self
end

function Resize:_createGrip(parent)
	local grip = Utility.create("TextButton", {
		Parent = parent,
		Name = "ResizeGrip",
		BackgroundTransparency = 1,
		Text = Icons.Resize,
		TextSize = 12,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -18, 1, -18),
		ZIndex = 20,
	})
	return grip
end

function Resize:_bind()
	self._began = self.Grip.InputBegan:Connect(function(input)
		if not self.Enabled then
			return
		end
		if Utility.isLeftClick(input) then
			self._resizing = true
			self._start = UserInputService:GetMouseLocation()
			self._size = self.Target.AbsoluteSize
		end
	end)

	self._ended = UserInputService.InputEnded:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._resizing = false
		end
	end)

	self._changed = UserInputService.InputChanged:Connect(function(input)
		self:_onMove(input)
	end)
end

function Resize:_onMove(input)
	if not self._resizing or not self.Enabled then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local delta = mouse - self._start
	local width = Utility.clamp(self._size.X + delta.X, self.Min.X, self.Max.X)
	local height = Utility.clamp(self._size.Y + delta.Y, self.Min.Y, self.Max.Y)
	self.Target.Size = UDim2.fromOffset(width, height)
end

function Resize:SetEnabled(enabled)
	self.Enabled = enabled
	self.Grip.Visible = enabled
end

function Resize:Destroy()
	self._began = Utility.disconnect(self._began)
	self._ended = Utility.disconnect(self._ended)
	self._changed = Utility.disconnect(self._changed)
	Utility.destroy(self.Grip)
end

return Resize
