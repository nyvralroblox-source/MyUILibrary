--[[
	Paragraph
	Bloc de texte descriptif, wrappé.
]]

local Utility = require(script.Parent.Parent.Utility)

local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Paragraph)
	self.Library = library
	self.Options = options
	self.Instance = self:_build(parent)
	return self
end

function Paragraph:_build(parent)
	local theme = self.Library.Theme:Get()
	local row = Utility.row(parent, self.Library, 20)
	row.Name = "Paragraph"
	row.AutomaticSize = Enum.AutomaticSize.Y
	self.TitleLabel = Utility.create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.GothamMedium,
		Text = self.Options.Title or "",
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = self.Options.Title ~= nil,
	})
	self.Body = Utility.create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, self.Options.Title and 26 or 8),
		Size = UDim2.new(1, -20, 0, 12),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = self.Options.Content or "",
		TextColor3 = theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	self.Library.Theme:Bind(self.TitleLabel, "TextColor3", "Text")
	self.Library.Theme:Bind(self.Body, "TextColor3", "SubText")
	Utility.create("Frame", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 8),
		LayoutOrder = 99,
	})
	return row
end

function Paragraph:Set(content)
	self.Body.Text = content or ""
end

function Paragraph:Destroy()
	Utility.destroy(self.Instance)
end

return Paragraph
