--[[
	MyUILibrary
	Point d'entrée ModuleScript.

	Studio / Rojo :
		local Library = require(path.to.MyUILibrary)

	Le dossier `src` doit être un ModuleScript (init.lua)
	contenant les modules enfants listés dans ce dépôt.
]]

local Library = require(script.Library)

Library.Utility = require(script.Utility)
Library.Signals = require(script.Signals)
Library.Animation = require(script.Animation)
Library.ThemeModule = require(script.Theme)

return Library
