--[[
	Dropdown
	Liste déroulante simple ou multi-sélection.
]]

local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Signals = require(script.Parent.Parent.Signals)

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Dropdown)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "Dropdown"
	self.Flag = options.Flag
	self.Values = options.Values or {}
	self.Multi = options.Multi and true or false
	self.Changed = Signals.new()
	if self.Multi then
		self.Value = options.Default or {}
	else
		self.Value = options.Default or self.Values[1]
	end
	self.Open = false
	self.Instance = self:_build(parent)
	self:_bind()
	self:_refreshLabel()
	library:RegisterFlag(self)
	return self
end

function Dropdown:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 58)
	row.Name = "Dropdown"
	Utility.label(row, self.Library, self.Title)
	self.Trigger = Utility.create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.ElementHover,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 28),
		Text = "",
	})
	Utility.corner(self.Trigger, 6)
	Utility.padding(self.Trigger, 6)
	self.Library.Theme:Bind(self.Trigger, "BackgroundColor3", "ElementHover")
	self.List = Utility.create("Frame", {
		Parent = row,
		BackgroundColor3 = theme.Groupbox,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 54),
		ZIndex = 15,
	})
	Utility.corner(self.List, 6)
	self.Layout = Utility.list(self.List, 2)
	Utility.padding(self.List, 4)
	self:_rebuildItems()
	return row
end

function Dropdown:_rebuildItems()
	for _, child in ipairs(self.List:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, value in ipairs(self.Values) do
		self:_addItem(value)
	end
end

function Dropdown:_addItem(value)
	local theme = self.Library.Theme:Get()
	local item = Utility.create("TextButton", {
		Parent = self.List,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.Text,
		Text = tostring(value),
		Size = UDim2.new(1, 0, 0, 24),
	})
	Utility.corner(item, 4)
	item.MouseButton1Click:Connect(function()
		self:_pick(value)
	end)
end

function Dropdown:_pick(value)
	if self.Multi then
		local copy = Utility.copy(self.Value)
		local found = table.find(copy, value)
		if found then
			table.remove(copy, found)
		else
			table.insert(copy, value)
		end
		self:Set(copy)
	else
		self:Set(value)
		self:Toggle(false)
	end
end

function Dropdown:_refreshLabel()
	if self.Multi then
		self.Trigger.Text = table.concat(self.Value, ", ")
		if self.Trigger.Text == "" then
			self.Trigger.Text = self.Options.Placeholder or "Select..."
		end
	else
		self.Trigger.Text = tostring(self.Value or self.Options.Placeholder or "Select...")
	end
end

function Dropdown:_bind()
	self.Trigger.MouseButton1Click:Connect(function()
		self:Toggle(not self.Open)
	end)
end

function Dropdown:Toggle(open)
	self.Open = open
	local height = math.min(#self.Values * 26 + 8, 140)
	if open then
		self.Instance.Size = UDim2.new(1, -2, 0, 58 + height)
		Animation.openDropdown(self.List, height)
	else
		Animation.closeDropdown(self.List)
		self.Instance.Size = UDim2.new(1, -2, 0, 58)
	end
end

function Dropdown:Set(value, silent)
	self.Value = value
	self:_refreshLabel()
	self.Library:WriteFlag(self.Flag, self.Value)
	if not silent and self.Options.Callback then
		self.Options.Callback(self.Value)
	end
	self.Changed:Fire(self.Value)
	self.Library.Config:MaybeAutoSave()
end

function Dropdown:Refresh(values)
	self.Values = values or {}
	self:_rebuildItems()
end

function Dropdown:Get()
	return self.Value
end

function Dropdown:Destroy()
	Utility.destroy(self.Instance)
end

return Dropdown
