--[[
	Drag
	Déplacement d'une fenêtre via une poignée (topbar).
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)

local Drag = {}
Drag.__index = Drag

function Drag.new(target, handle, onMoved)
	local self = setmetatable({}, Drag)
	self.Target = target
	self.Handle = handle
	self.OnMoved = onMoved
	self.Enabled = true
	self._dragging = false
	self._startMouse = Vector2.new()
	self._startPos = UDim2.new()
	self:_bind()
	return self
end

function Drag:_bind()
	self._began = self.Handle.InputBegan:Connect(function(input)
		if not self.Enabled then
			return
		end
		if Utility.isLeftClick(input) then
			self._dragging = true
			self._startMouse = UserInputService:GetMouseLocation()
			self._startPos = self.Target.Position
		end
	end)

	self._ended = UserInputService.InputEnded:Connect(function(input)
		if Utility.isLeftClick(input) then
			self._dragging = false
			if self.OnMoved then
				self.OnMoved(self.Target.Position)
			end
		end
	end)

	self._changed = UserInputService.InputChanged:Connect(function(input)
		self:_onMove(input)
	end)
end

function Drag:_onMove(input)
	if not self._dragging or not self.Enabled then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local delta = mouse - self._startMouse
	self.Target.Position = UDim2.new(
		self._startPos.X.Scale,
		self._startPos.X.Offset + delta.X,
		self._startPos.Y.Scale,
		self._startPos.Y.Offset + delta.Y
	)
end

function Drag:SetEnabled(enabled)
	self.Enabled = enabled
end

function Drag:Destroy()
	self._began = Utility.disconnect(self._began)
	self._ended = Utility.disconnect(self._ended)
	self._changed = Utility.disconnect(self._changed)
end

return Drag
