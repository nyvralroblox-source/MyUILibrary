--[[
	Utility
	Helpers partagés : création d'instances, maths, couleurs, flags.
]]

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Utility = {}

local PARENT_KEY = "Parent"
local CHILDREN_KEY = "Children"

--- Crée une instance Roblox et applique ses propriétés.
-- @param className string
-- @param props table|nil
-- @return Instance
function Utility.create(className, props)
	local instance = Instance.new(className)
	props = props or {}

	for key, value in pairs(props) do
		if key ~= PARENT_KEY and key ~= CHILDREN_KEY then
			instance[key] = value
		end
	end

	if props[CHILDREN_KEY] then
		for _, child in ipairs(props[CHILDREN_KEY]) do
			child.Parent = instance
		end
	end

	if props[PARENT_KEY] then
		instance.Parent = props[PARENT_KEY]
	end

	return instance
end

--- Borne une valeur numérique.
function Utility.clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

--- Interpolation linéaire.
function Utility.lerp(a, b, alpha)
	return a + (b - a) * alpha
end

--- Arrondit à `digits` décimales.
function Utility.round(value, digits)
	digits = digits or 0
	local factor = 10 ^ digits
	return math.floor(value * factor + 0.5) / factor
end

--- Convertit Color3 vers une table JSON-friendly.
function Utility.colorToTable(color)
	return {
		R = Utility.round(color.R, 4),
		G = Utility.round(color.G, 4),
		B = Utility.round(color.B, 4),
	}
end

--- Inverse de colorToTable.
function Utility.tableToColor(value)
	if typeof(value) == "Color3" then
		return value
	end
	return Color3.new(value.R or 0, value.G or 0, value.B or 0)
end

--- Color3 vers hexadécimal (#RRGGBB).
function Utility.colorToHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

--- Parse un hex (#RGB ou #RRGGBB).
function Utility.hexToColor(hex)
	hex = string.gsub(hex or "", "#", "")
	if #hex == 3 then
		hex = string.sub(hex, 1, 1):rep(2)
			.. string.sub(hex, 2, 2):rep(2)
			.. string.sub(hex, 3, 3):rep(2)
	end
	local n = tonumber(hex, 16) or 0
	local r = math.floor(n / 65536) % 256
	local g = math.floor(n / 256) % 256
	local b = n % 256
	return Color3.fromRGB(r, g, b)
end

--- HSV (0-1) vers Color3.
function Utility.hsvToColor(h, s, v)
	return Color3.fromHSV(Utility.clamp(h, 0, 1), Utility.clamp(s, 0, 1), Utility.clamp(v, 0, 1))
end

--- Color3 vers HSV.
function Utility.colorToHsv(color)
	return color:ToHSV()
end

--- Encode une table Lua en JSON.
function Utility.toJson(data)
	return HttpService:JSONEncode(data)
end

--- Decode JSON vers une table Lua.
function Utility.fromJson(text)
	local ok, result = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	if ok then
		return result
	end
	return nil
end

--- Génère un identifiant unique.
function Utility.guid()
	return HttpService:GenerateGUID(false)
end

--- Fusionne `override` dans une copie de `base`.
function Utility.merge(base, override)
	local output = {}
	for key, value in pairs(base or {}) do
		output[key] = value
	end
	for key, value in pairs(override or {}) do
		output[key] = value
	end
	return output
end

--- Copie superficielle.
function Utility.copy(source)
	local output = {}
	for key, value in pairs(source or {}) do
		output[key] = value
	end
	return output
end

--- Détecte si l'environnement expose writefile (exécuteurs).
function Utility.hasFileApi()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(isfile) == "function"
end

--- Crée un dossier si l'API fichiers est disponible.
function Utility.ensureFolder(path)
	if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
		if not isfolder(path) then
			makefolder(path)
		end
		return true
	end
	return false
end

--- Position de la souris en offset.
function Utility.mousePosition()
	return UserInputService:GetMouseLocation()
end

--- Souris corrigée de l'inset GUI (alignée sur AbsolutePosition).
function Utility.guiMouse()
	local inset = game:GetService("GuiService"):GetGuiInset()
	return UserInputService:GetMouseLocation() - inset
end

--- Vrai si l'input est un clic gauche.
function Utility.isLeftClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

--- Applique un coin arrondi uniforme.
function Utility.corner(parent, radius)
	return Utility.create("UICorner", {
		Parent = parent,
		CornerRadius = UDim.new(0, radius or 8),
	})
end

--- Applique un contour.
function Utility.stroke(parent, color, thickness)
	return Utility.create("UIStroke", {
		Parent = parent,
		Color = color or Color3.fromRGB(40, 40, 48),
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

--- Padding uniforme.
function Utility.padding(parent, pixels)
	pixels = pixels or 8
	return Utility.create("UIPadding", {
		Parent = parent,
		PaddingTop = UDim.new(0, pixels),
		PaddingBottom = UDim.new(0, pixels),
		PaddingLeft = UDim.new(0, pixels),
		PaddingRight = UDim.new(0, pixels),
	})
end

--- Liste verticale par défaut.
function Utility.list(parent, padding)
	return Utility.create("UIListLayout", {
		Parent = parent,
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, padding or 6),
	})
end

--- Déconnecte une connexion si elle existe.
function Utility.disconnect(connection)
	if connection then
		connection:Disconnect()
	end
	return nil
end

--- Détruit une instance en sécurité.
function Utility.destroy(instance)
	if instance and instance.Parent then
		instance:Destroy()
	end
end

--- Rangée de composant standard.
function Utility.row(parent, library, height)
	local theme = library.Theme:Get()
	local row = Utility.create("Frame", {
		Parent = parent,
		Name = "Element",
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 0, height or 38),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
	})
	Utility.corner(row, 8)
	library.Theme:Bind(row, "BackgroundColor3", "Element")
	return row
end

--- Libellé de composant.
function Utility.label(parent, library, text, extra)
	local theme = library.Theme:Get()
	local props = Utility.merge({
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.fromOffset(10, 8),
		Font = Enum.Font.Gotham,
		Text = text or "",
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, extra or {})
	local label = Utility.create("TextLabel", props)
	library.Theme:Bind(label, "TextColor3", "Text")
	return label
end

--- Recherche insensible à la casse.
function Utility.contains(haystack, needle)
	haystack = string.lower(tostring(haystack or ""))
	needle = string.lower(tostring(needle or ""))
	if needle == "" then
		return true
	end
	return string.find(haystack, needle, 1, true) ~= nil
end

return Utility
