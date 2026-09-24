--[[
	Library
	Façade publique : fenêtres, thèmes, flags et configuration.
]]

local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Utility)
local Theme = require(script.Parent.Theme)
local Config = require(script.Parent.Config)
local Window = require(script.Parent.Objects.Window)
local WindowManager = require(script.Parent.Services.WindowManager)
local Notifications = require(script.Parent.Services.Notifications)
local Tooltip = require(script.Parent.Services.Tooltip)

local Library = {}
Library.__index = Library
Library.Version = "1.0.0"

function Library.new()
	local self = setmetatable({}, Library)
	self.Flags = {}
	self._flagObjects = {}
	self.Theme = Theme.new()
	self.WindowManager = WindowManager.new(self)
	self.Config = Config.new(self)
	self.Visible = true
	self.UnloadBind = Enum.KeyCode.RightShift
	self:_bindToggle()
	return self
end

function Library:_bindToggle()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == self.UnloadBind then
			self:Toggle()
		end
	end)
end

function Library:CreateWindow(options)
	local window = Window.new(self, options)
	self.WindowManager:Register(window)
	if not self.Notifications then
		self.Notifications = Notifications.new(self, window.NotifyHost)
	end
	if not self.Tooltip then
		self.Tooltip = Tooltip.new(self, window.Overlay)
	end
	return window
end

function Library:SetTheme(name)
	self.Theme:SetTheme(name)
	self.Config:MaybeAutoSave()
end

function Library:SetAccent(color)
	self.Theme:SetAccent(color)
	self.Config:MaybeAutoSave()
end

function Library:ToggleTheme()
	local nextName = self.Theme:GetName() == "Dark" and "Light" or "Dark"
	self:SetTheme(nextName)
end

function Library:Notify(options)
	if typeof(options) == "string" then
		options = { Title = "Notice", Content = options }
	end
	if not self.Notifications then
		warn("[MyUILibrary] Notify() requiert une fenêtre active.")
		return
	end
	return self.Notifications:Push(options)
end

function Library:RegisterFlag(component)
	if component.Flag then
		self._flagObjects[component.Flag] = component
		self.Flags[component.Flag] = component:Get()
	end
end

function Library:WriteFlag(flag, value)
	if flag then
		self.Flags[flag] = value
	end
end

function Library:SerializeFlags()
	local payload = {}
	for flag, component in pairs(self._flagObjects) do
		local value = component:Get()
		if typeof(value) == "Color3" then
			payload[flag] = Utility.colorToTable(value)
		elseif typeof(value) == "EnumItem" then
			payload[flag] = value.Name
		else
			payload[flag] = value
		end
	end
	return payload
end

function Library:_restoreFlag(flag, value)
	local component = self._flagObjects[flag]
	if not component then
		self.Flags[flag] = value
		return
	end
	if component.Value ~= nil and typeof(component.Value) == "Color3" then
		component:Set(Utility.tableToColor(value), true)
	elseif typeof(component.Get) == "function" and typeof(component.Value) == "EnumItem" then
		component:Set(value, true)
	else
		component:Set(value, true)
	end
end

function Library:ApplySerialized(data)
	if data.theme then
		self.Theme:SetTheme(data.theme)
	end
	if data.accent then
		self.Theme:SetAccent(Utility.tableToColor(data.accent))
	end
	if data.flags then
		for flag, value in pairs(data.flags) do
			self:_restoreFlag(flag, value)
		end
	end
	if data.windows then
		self.WindowManager:Apply(data.windows)
	end
end

function Library:SaveConfig(name)
	return self.Config:Save(name)
end

function Library:LoadConfig(name)
	return self.Config:Load(name)
end

function Library:SetAutoSave(enabled)
	self.Config:SetAutoSave(enabled)
end

function Library:Toggle()
	self.Visible = not self.Visible
	for _, window in ipairs(self.WindowManager.Windows) do
		if self.Visible then
			window:Show()
		else
			window:Hide()
		end
	end
end

function Library:Destroy()
	self.WindowManager:DestroyAll()
	if self.Notifications then
		self.Notifications:Clear()
	end
end

local singleton = Library.new()
return singleton
