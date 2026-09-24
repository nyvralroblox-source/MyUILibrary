--[[
	Groupbox
	Carte intérieure regroupant des composants.
]]

local Utility = require(script.Parent.Parent.Utility)

local Groupbox = {}
Groupbox.__index = Groupbox

local function loadComponents()
	local folder = script.Parent.Parent.Components
	return {
		Button = require(folder.Button),
		Toggle = require(folder.Toggle),
		Slider = require(folder.Slider),
		Dropdown = require(folder.Dropdown),
		Keybind = require(folder.Keybind),
		Colorpicker = require(folder.Colorpicker),
		Textbox = require(folder.Textbox),
		Paragraph = require(folder.Paragraph),
		Label = require(folder.Label),
		Divider = require(folder.Divider),
		Image = require(folder.Image),
	}
end

function Groupbox.new(parent, library, title)
	local self = setmetatable({}, Groupbox)
	self.Library = library
	self.Title = title or "Group"
	self.Components = loadComponents()
	self.Children = {}
	self.Instance = self:_build(parent)
	return self
end

function Groupbox:_build(parent)
	local theme = self.Library.Theme:Get()
	local box = Utility.create("Frame", {
		Parent = parent,
		Name = "Groupbox",
		BackgroundColor3 = theme.Groupbox,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 40),
	})
	Utility.corner(box, 10)
	Utility.stroke(box, theme.Stroke, 1)
	self.Library.Theme:Bind(box, "BackgroundColor3", "Groupbox")
	Utility.label(box, self.Library, self.Title).Font = Enum.Font.GothamMedium
	self.Content = Utility.create("Frame", {
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 30),
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	Utility.list(self.Content, 6)
	Utility.create("Frame", {
		Parent = box,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.fromOffset(0, 0),
	})
	return box
end

function Groupbox:_spawn(className, options)
	local class = self.Components[className]
	local component = class.new(self.Content, self.Library, options)
	component.SearchKey = string.lower(tostring((options and (options.Title or options.Text)) or className))
	table.insert(self.Children, component)
	return component
end

function Groupbox:AddButton(options)
	return self:_spawn("Button", options)
end

function Groupbox:AddToggle(options)
	return self:_spawn("Toggle", options)
end

function Groupbox:AddSlider(options)
	return self:_spawn("Slider", options)
end

function Groupbox:AddDropdown(options)
	return self:_spawn("Dropdown", options)
end

function Groupbox:AddTextbox(options)
	return self:_spawn("Textbox", options)
end

function Groupbox:AddColorpicker(options)
	return self:_spawn("Colorpicker", options)
end

function Groupbox:AddKeybind(options)
	return self:_spawn("Keybind", options)
end

function Groupbox:AddParagraph(options)
	return self:_spawn("Paragraph", options)
end

function Groupbox:AddLabel(options)
	return self:_spawn("Label", options)
end

function Groupbox:AddDivider(options)
	return self:_spawn("Divider", options or {})
end

function Groupbox:AddImage(options)
	return self:_spawn("Image", options)
end

function Groupbox:Search(query)
	for _, child in ipairs(self.Children) do
		local visible = Utility.contains(child.SearchKey, query)
		if child.Instance then
			child.Instance.Visible = visible
		end
	end
end

return Groupbox
