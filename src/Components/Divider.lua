--[[
	Divider
	Séparateur horizontal.
]]

local Utility = require(script.Parent.Parent.Utility)

local Divider = {}
Divider.__index = Divider

function Divider.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Divider)
	self.Library = library
	self.Options = options
	self.Instance = self:_build(parent)
	return self
end

function Divider:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.create("Frame", {
		Parent = parent,
		Name = "Divider",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
	})
	local line = Utility.create("Frame", {
		Parent = row,
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, 1),
		Position = UDim2.new(0, 4, 0.5, 0),
	})
	self.Library.Theme:Bind(line, "BackgroundColor3", "Stroke")
	return row
end

function Divider:Destroy()
	Utility.destroy(self.Instance)
end

return Divider
