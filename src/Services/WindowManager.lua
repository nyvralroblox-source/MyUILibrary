--[[
	WindowManager
	Z-index, sérialisation des fenêtres, focus.
]]

local WindowManager = {}
WindowManager.__index = WindowManager

function WindowManager.new(library)
	local self = setmetatable({}, WindowManager)
	self.Library = library
	self.Windows = {}
	self._z = 10
	return self
end

function WindowManager:Register(window)
	table.insert(self.Windows, window)
	self:Focus(window)
	return window
end

function WindowManager:Unregister(window)
	for index, item in ipairs(self.Windows) do
		if item == window then
			table.remove(self.Windows, index)
			break
		end
	end
end

function WindowManager:Focus(window)
	self._z += 1
	if window.Root then
		window.Root.ZIndex = self._z
	end
end

function WindowManager:Serialize()
	local data = {}
	for _, window in ipairs(self.Windows) do
		data[window.Title] = {
			position = {
				X = window.Root.Position.X.Offset,
				Y = window.Root.Position.Y.Offset,
			},
			size = {
				X = window.Root.Size.X.Offset,
				Y = window.Root.Size.Y.Offset,
			},
			visible = window.Root.Visible,
		}
	end
	return data
end

function WindowManager:Apply(data)
	if not data then
		return
	end
	for _, window in ipairs(self.Windows) do
		local saved = data[window.Title]
		if saved then
			if saved.position then
				window.Root.Position = UDim2.fromOffset(saved.position.X, saved.position.Y)
			end
			if saved.size then
				window.Root.Size = UDim2.fromOffset(saved.size.X, saved.size.Y)
			end
			if saved.visible ~= nil then
				window.Root.Visible = saved.visible
			end
		end
	end
end

function WindowManager:DestroyAll()
	local snapshot = {}
	for index, window in ipairs(self.Windows) do
		snapshot[index] = window
	end
	for _, window in ipairs(snapshot) do
		window:Destroy()
	end
	self.Windows = {}
end

return WindowManager
