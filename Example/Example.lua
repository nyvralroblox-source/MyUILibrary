--[[
	Example.lua
	Démonstration complète de MyUILibrary.

	Studio :
	1. Synchronisez ce dépôt avec Rojo (dossier `src` = ModuleScript).
	2. Placez ce script en LocalScript (StarterPlayerScripts).
	3. Adaptez `require` vers l'emplacement réel du module.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function locateLibrary()
	local parent = script.Parent
	if parent and parent:FindFirstChild("src") then
		return require(parent.src)
	end
	local stored = ReplicatedStorage:FindFirstChild("MyUILibrary")
	if stored then
		return require(stored)
	end
	error("MyUILibrary introuvable. Placez `src` comme ModuleScript ou dans ReplicatedStorage.")
end

local Library = locateLibrary()

Library:SetTheme("Dark")
Library:SetAccent(Color3.fromRGB(88, 140, 255))
Library:SetAutoSave(true)

local Window = Library:CreateWindow({
	Title = "My Hub",
	Size = UDim2.fromOffset(650, 420),
})

local Main = Window:AddTab("Main")
local Combat = Main:AddSection("Combat")

Combat:AddParagraph({
	Title = "Welcome",
	Content = "Bibliothèque UI originale : composants, thème, config et animations TweenService.",
})

Combat:AddButton({
	Title = "Notify me",
	Tooltip = "Envoie une notification",
	Callback = function()
		Library:Notify({
			Title = "MyUILibrary",
			Content = "Callback bouton exécuté.",
			Type = "success",
			Duration = 3,
		})
	end,
})

Combat:AddToggle({
	Title = "Auto Parry",
	Flag = "AutoParry",
	Default = false,
	Callback = function(value)
		print("Auto Parry:", value)
	end,
})

Combat:AddSlider({
	Title = "Range",
	Flag = "Range",
	Min = 0,
	Max = 100,
	Default = 25,
	Increment = 1,
	Callback = function(value)
		print("Range:", value)
	end,
})

Combat:AddDropdown({
	Title = "Target",
	Flag = "Target",
	Values = { "Nearest", "Lowest HP", "Highest HP" },
	Default = "Nearest",
	Callback = function(value)
		print("Target:", value)
	end,
})

Combat:AddTextbox({
	Title = "Webhook",
	Flag = "Webhook",
	Placeholder = "https://...",
	Default = "",
	Callback = function(text)
		print("Webhook:", text)
	end,
})

Combat:AddColorpicker({
	Title = "ESP Color",
	Flag = "EspColor",
	Default = Color3.fromRGB(88, 140, 255),
	Callback = function(color)
		Library:SetAccent(color)
	end,
})

Combat:AddKeybind({
	Title = "Panic",
	Flag = "PanicKey",
	Default = Enum.KeyCode.X,
	Mode = "Toggle",
	Callback = function(active)
		print("Panic:", active)
	end,
})

local Visuals = Main:AddSection("Visuals")
Visuals:AddLabel({ Text = "Extras" })
Visuals:AddDivider()
Visuals:AddImage({ Title = "Preview", Height = 72 })

local Settings = Window:AddTab("Settings")
local Config = Settings:AddSection("Configuration")

Config:AddButton({
	Title = "Save config",
	Callback = function()
		Library:SaveConfig("default")
		Library:Notify({ Title = "Config", Content = "Sauvegardée.", Type = "success" })
	end,
})

Config:AddButton({
	Title = "Load config",
	Callback = function()
		local ok = Library:LoadConfig("default")
		Library:Notify({
			Title = "Config",
			Content = ok and "Chargée." or "Aucune sauvegarde.",
			Type = ok and "success" or "warning",
		})
	end,
})

Config:AddButton({
	Title = "Light theme",
	Callback = function()
		Library:SetTheme("Light")
	end,
})

Config:AddButton({
	Title = "Dark theme",
	Callback = function()
		Library:SetTheme("Dark")
	end,
})

Config:AddButton({
	Title = "Open modal",
	Callback = function()
		Window:ShowModal({
			Title = "Hello",
			Content = "Popup modal native de la bibliothèque.",
		})
	end,
})

Library:Notify({
	Title = "Ready",
	Content = "My Hub chargé. RightShift pour masquer.",
	Type = "info",
})
