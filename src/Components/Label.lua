--[[
	Label
	Ligne de titre simple.
]]

local Utility = require(script.Parent.Parent.Utility)

local Label = {}
Label.__index = Label

function Label.new(parent, library, options)
	options = typeof(options) == "table" and options or { Text = tostring(options) }
	local self = setmetatable({}, Label)
	self.Library = library
	self.Options = options
	self.Instance = self:_build(parent)
	return self
end

function Label:_build(parent)
	local row = Utility.row(parent, self.Library, 28)
	row.Name = "Label"
	row.BackgroundTransparency = 1
	self.Text = Utility.label(row, self.Library, self.Options.Text or self.Options.Title or "")
	self.Text.Position = UDim2.fromOffset(4, 5)
	self.Text.Font = Enum.Font.GothamMedium
	return row
end

function Label:Set(text)
	self.Text.Text = text or ""
end

function Label:Destroy()
	Utility.destroy(self.Instance)
end

return Label
