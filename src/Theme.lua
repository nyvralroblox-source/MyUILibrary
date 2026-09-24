--[[
	Theme
	Palettes, accent dynamique et liaisons de propriétés.
]]

local Utility = require(script.Parent.Utility)
local Dark = require(script.Parent.Styles.Dark)
local Light = require(script.Parent.Styles.Light)

local Theme = {}
Theme.__index = Theme

local PALETTES = {
	Dark = Dark,
	Light = Light,
}

local function clonePalette(source)
	return Utility.copy(source)
end

function Theme.new()
	local self = setmetatable({}, Theme)
	self._binds = {}
	self._listeners = {}
	self.Name = "Dark"
	self.Current = clonePalette(Dark)
	self.Palettes = PALETTES
	return self
end

--- Enregistre une propriété liée à une clé de palette.
function Theme:Bind(instance, property, key)
	table.insert(self._binds, {
		Instance = instance,
		Property = property,
		Key = key,
	})
	if self.Current[key] ~= nil then
		instance[property] = self.Current[key]
	end
	return instance
end

--- Abonne un callback appelé après chaque application de thème.
function Theme:OnChanged(callback)
	table.insert(self._listeners, callback)
end

--- Nettoie les liaisons dont l'instance a été détruite.
function Theme:Sweep()
	local alive = {}
	for _, bind in ipairs(self._binds) do
		if bind.Instance and bind.Instance.Parent then
			table.insert(alive, bind)
		end
	end
	self._binds = alive
end

--- Applique la palette courante à toutes les liaisons.
function Theme:Apply()
	self:Sweep()
	for _, bind in ipairs(self._binds) do
		local color = self.Current[bind.Key]
		if color ~= nil then
			pcall(function()
				bind.Instance[bind.Property] = color
			end)
		end
	end
	for _, listener in ipairs(self._listeners) do
		task.spawn(listener, self.Current, self.Name)
	end
end

--- Change de palette (Dark / Light ou table custom).
function Theme:SetTheme(nameOrPalette)
	if typeof(nameOrPalette) == "table" then
		self.Name = nameOrPalette.Name or "Custom"
		self.Current = clonePalette(nameOrPalette)
	else
		local palette = PALETTES[nameOrPalette]
		assert(palette, "Thème inconnu: " .. tostring(nameOrPalette))
		self.Name = nameOrPalette
		self.Current = clonePalette(palette)
	end
	self:Apply()
end

--- Remplace la couleur d'accent et une variante hover.
function Theme:SetAccent(color)
	assert(typeof(color) == "Color3", "SetAccent attend un Color3")
	self.Current.Accent = color
	local h, s, v = color:ToHSV()
	self.Current.AccentHover = Color3.fromHSV(h, Utility.clamp(s * 0.85, 0, 1), Utility.clamp(v * 1.08, 0, 1))
	self:Apply()
end

function Theme:Get()
	return self.Current
end

function Theme:GetName()
	return self.Name
end

return Theme
