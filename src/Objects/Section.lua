--[[
	Section
	Bloc de page : titre + liste de composants / groupboxes.
]]

local Utility = require(script.Parent.Parent.Utility)
local Groupbox = require(script.Parent.Groupbox)

local Section = {}
Section.__index = Section

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

function Section.new(parent, library, title)
	local self = setmetatable({}, Section)
	self.Library = library
	self.Title = title or "Section"
	self.Components = loadComponents()
	self.Children = {}
	self.Instance = self:_build(parent)
	return self
end

function Section:_build(parent)
	local theme = self.Library.Theme:Get()
	local frame = Utility.create("Frame", {
		Parent = parent,
		Name = "Section",
		BackgroundColor3 = theme.Section,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -8, 0, 48),
	})
	Utility.corner(frame, 12)
	Utility.stroke(frame, theme.Stroke, 1)
	self.Library.Theme:Bind(frame, "BackgroundColor3", "Section")
	Utility.create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = self.Title,
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self.Content = Utility.create("Frame", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	Utility.list(self.Content, 8)
	Utility.create("UIPadding", {
		Parent = frame,
		PaddingBottom = UDim.new(0, 12),
	})
	return frame
end

function Section:_spawn(className, options)
	local class = self.Components[className]
	local component = class.new(self.Content, self.Library, options)
	component.SearchKey = string.lower(tostring((options and (options.Title or options.Text)) or className))
	table.insert(self.Children, component)
	return component
end

function Section:AddGroupbox(title)
	local box = Groupbox.new(self.Content, self.Library, title)
	table.insert(self.Children, box)
	return box
end

function Section:AddButton(options)
	return self:_spawn("Button", options)
end

function Section:AddToggle(options)
	return self:_spawn("Toggle", options)
end

function Section:AddSlider(options)
	return self:_spawn("Slider", options)
end

function Section:AddDropdown(options)
	return self:_spawn("Dropdown", options)
end

function Section:AddTextbox(options)
	return self:_spawn("Textbox", options)
end

function Section:AddColorpicker(options)
	return self:_spawn("Colorpicker", options)
end

function Section:AddKeybind(options)
	return self:_spawn("Keybind", options)
end

function Section:AddParagraph(options)
	return self:_spawn("Paragraph", options)
end

function Section:AddLabel(options)
	return self:_spawn("Label", options)
end

function Section:AddDivider(options)
	return self:_spawn("Divider", options or {})
end

function Section:AddImage(options)
	return self:_spawn("Image", options)
end

function Section:Search(query)
	for _, child in ipairs(self.Children) do
		if child.Search then
			child:Search(query)
		elseif child.Instance then
			child.Instance.Visible = Utility.contains(child.SearchKey, query)
		end
	end
end

return Section
