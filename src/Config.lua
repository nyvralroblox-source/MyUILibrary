--[[
	Config
	Sauvegarde JSON des flags, thème, position et liaisons.
]]

local Utility = require(script.Parent.Utility)

local Config = {}
Config.__index = Config

local FOLDER_NAME = "configs"

function Config.new(library)
	local self = setmetatable({}, Config)
	self._library = library
	self.Folder = FOLDER_NAME
	self.AutoSave = false
	self.Name = "default"
	self._memory = {}
	return self
end

function Config:_path(name)
	return string.format("%s/%s.json", self.Folder, name or self.Name)
end

function Config:_payload()
	local library = self._library
	return {
		flags = library:SerializeFlags(),
		theme = library.Theme:GetName(),
		accent = Utility.colorToTable(library.Theme:Get().Accent),
		windows = library.WindowManager:Serialize(),
		savedAt = os.time(),
	}
end

function Config:SetAutoSave(enabled)
	self.AutoSave = enabled and true or false
end

--- Écrit le fichier JSON (exécuteur) ou conserve en mémoire.
function Config:Save(name)
	name = name or self.Name
	self.Name = name
	local payload = self:_payload()
	self._memory[name] = payload
	if Utility.hasFileApi() then
		Utility.ensureFolder(self.Folder)
		writefile(self:_path(name), Utility.toJson(payload))
	end
	return payload
end

function Config:Load(name)
	name = name or self.Name
	self.Name = name
	local data = self._memory[name]
	if Utility.hasFileApi() and isfile(self:_path(name)) then
		data = Utility.fromJson(readfile(self:_path(name))) or data
	end
	if not data then
		return false
	end
	self._library:ApplySerialized(data)
	return true
end

function Config:MaybeAutoSave()
	if self.AutoSave then
		self:Save(self.Name)
	end
end

function Config:List()
	local names = {}
	for key in pairs(self._memory) do
		table.insert(names, key)
	end
	return names
end

return Config
