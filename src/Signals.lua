--[[
	Signals
	Mini-bus d'événements, sans dépendance externe.
]]

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
	local self = setmetatable({}, Connection)
	self.Connected = true
	self._signal = signal
	self._callback = callback
	return self
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	local list = self._signal._connections
	for index, item in ipairs(list) do
		if item == self then
			table.remove(list, index)
			break
		end
	end
end

--- Crée un signal.
function Signal.new()
	local self = setmetatable({}, Signal)
	self._connections = {}
	return self
end

--- Abonne un callback. Retourne une connexion.
function Signal:Connect(callback)
	assert(typeof(callback) == "function", "Signal:Connect attend une fonction")
	local connection = Connection.new(self, callback)
	table.insert(self._connections, connection)
	return connection
end

--- Déclenche tous les abonnés (asynchrone).
function Signal:Fire(...)
	local args = { ... }
	local snapshot = {}
	for index, connection in ipairs(self._connections) do
		snapshot[index] = connection
	end
	for _, connection in ipairs(snapshot) do
		if connection.Connected then
			task.spawn(function()
				connection._callback(table.unpack(args))
			end)
		end
	end
end

--- Attend la prochaine émission.
function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

--- Coupe toutes les connexions.
function Signal:Destroy()
	local snapshot = {}
	for index, connection in ipairs(self._connections) do
		snapshot[index] = connection
	end
	for _, connection in ipairs(snapshot) do
		connection:Disconnect()
	end
	self._connections = {}
end

return {
	new = function()
		return Signal.new()
	end,
	Signal = Signal,
}
