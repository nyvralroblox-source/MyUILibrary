--[[
	Tab
	Page de navigation : scrolling + sections.
]]

local Utility = require(script.Parent.Parent.Utility)
local Section = require(script.Parent.Section)
local Groupbox = require(script.Parent.Groupbox)
local Icons = require(script.Parent.Parent.Assets.Icons)

local Tab = {}
Tab.__index = Tab

function Tab.new(window, name, icon)
	local self = setmetatable({}, Tab)
	self.Window = window
	self.Library = window.Library
	self.Name = name
	self.Icon = icon or Icons.Tab
	self.Sections = {}
	self.Button = self:_createButton()
	self.Page = self:_createPage()
	self:_bind()
	return self
end

function Tab:_createButton()
	local theme = self.Library.Theme:Get()
	local button = Utility.create("TextButton", {
		Parent = self.Window.TabList,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "  " .. self.Icon .. "  " .. self.Name,
		TextColor3 = theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -12, 0, 34),
	})
	Utility.corner(button, 8)
	self.Library.Theme:Bind(button, "BackgroundColor3", "Element")
	self.Accent = Utility.create("Frame", {
		Parent = button,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 0.55, 0),
		Position = UDim2.new(0, 4, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Visible = false,
	})
	Utility.corner(self.Accent, 2)
	self.Library.Theme:Bind(self.Accent, "BackgroundColor3", "Accent")
	return button
end

function Tab:_createPage()
	local page = Utility.create("ScrollingFrame", {
		Parent = self.Window.Pages,
		Name = self.Name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		Visible = false,
		ClipsDescendants = true,
	})
	Utility.create("UIPadding", {
		Parent = page,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})
	self.Layout = Utility.list(page, 10)
	return page
end

function Tab:_bind()
	self.Button.MouseButton1Click:Connect(function()
		self.Window:SelectTab(self)
	end)
end

function Tab:SetActive(active)
	local theme = self.Library.Theme:Get()
	self.Page.Visible = active
	self.Accent.Visible = active
	self.Button.TextColor3 = active and theme.Text or theme.SubText
	self.Button.BackgroundColor3 = active and theme.ElementActive or theme.Element
end

function Tab:AddSection(title)
	local section = Section.new(self.Page, self.Library, title)
	table.insert(self.Sections, section)
	return section
end

function Tab:AddGroupbox(title)
	local box = Groupbox.new(self.Page, self.Library, title)
	table.insert(self.Sections, box)
	return box
end

function Tab:Search(query)
	for _, section in ipairs(self.Sections) do
		if section.Search then
			section:Search(query)
		end
	end
end

function Tab:Destroy()
	Utility.destroy(self.Button)
	Utility.destroy(self.Page)
end

return Tab
