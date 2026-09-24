--[[
	Image
	ImageLabel dans une carte arrondie.
]]

local Utility = require(script.Parent.Parent.Utility)
local Icons = require(script.Parent.Parent.Assets.Icons)

local Image = {}
Image.__index = Image

function Image.new(parent, library, options)
	options = options or {}
	local self = setmetatable({}, Image)
	self.Library = library
	self.Options = options
	self.Instance = self:_build(parent)
	return self
end

function Image:_build(parent)
	local theme = self.Library.Theme:Get()
	local height = self.Options.Height or 96
	local row = Utility.row(parent, self.Library, height + 16)
	row.Name = "Image"
	if self.Options.Title then
		Utility.label(row, self.Library, self.Options.Title)
	end
	self.Picture = Utility.create("ImageLabel", {
		Parent = row,
		BackgroundColor3 = theme.ElementHover,
		BorderSizePixel = 0,
		Image = self.Options.Image or self.Options.ImageId or "",
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.new(1, -20, 0, height),
		Position = UDim2.fromOffset(10, self.Options.Title and 28 or 8),
	})
	Utility.corner(self.Picture, 8)
	if self.Picture.Image == "" then
		Utility.create("TextLabel", {
			Parent = self.Picture,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.Gotham,
			Text = Icons.Image,
			TextColor3 = theme.Muted,
			TextSize = 22,
		})
	end
	return row
end

function Image:Set(image)
	self.Picture.Image = image or ""
end

function Image:Destroy()
	Utility.destroy(self.Instance)
end

return Image
