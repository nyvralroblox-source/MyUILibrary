--[[
	Window
	Fenêtre principale : chrome, navigation, overlay, cycle de vie.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Utility = require(script.Parent.Parent.Utility)
local Animation = require(script.Parent.Parent.Animation)
local Icons = require(script.Parent.Parent.Assets.Icons)
local Drag = require(script.Parent.Parent.Services.Drag)
local Resize = require(script.Parent.Parent.Services.Resize)
local Tab = require(script.Parent.Tab)

local Window = {}
Window.__index = Window

function Window.new(library, options)
	options = options or {}
	local self = setmetatable({}, Window)
	self.Library = library
	self.Options = options
	self.Title = options.Title or "MyUILibrary"
	self.Tabs = {}
	self.ActiveTab = nil
	self.Maximized = false
	self.Minimized = false
	self._restore = nil
	self.Gui = self:_createScreenGui()
	self:_createHosts()
	self.Root = self:_createRoot()
	self:_createTopbar()
	self:_createSidebar()
	self:_createContent()
	self:_createFooter()
	self:_createOverlayWidgets()
	self:_attachServices()
	self:_bindChrome()
	Animation.openWindow(self.Root)
	return self
end

function Window:_createScreenGui()
	local player = Players.LocalPlayer
	local parent = player and player:FindFirstChildOfClass("PlayerGui")
	if not parent then
		local ok, coreGui = pcall(function()
			return game:GetService("CoreGui")
		end)
		if ok then
			parent = coreGui
		elseif player then
			parent = player:WaitForChild("PlayerGui")
		end
	end
	return Utility.create("ScreenGui", {
		Name = "MyUILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = parent,
	})
end

function Window:_createHosts()
	local theme = self.Library.Theme:Get()
	self.NotifyHost = Utility.create("Frame", {
		Parent = self.Gui,
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
	})
	self.Overlay = Utility.create("Frame", {
		Parent = self.Gui,
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 80,
	})
	self.Dimmer = Utility.create("TextButton", {
		Parent = self.Overlay,
		BackgroundColor3 = theme.Overlay,
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 81,
	})
end

function Window:_createRoot()
	local theme = self.Library.Theme:Get()
	local size = self.Options.Size or UDim2.fromOffset(650, 420)
	local root = Utility.create("Frame", {
		Parent = self.Gui,
		Name = "Window",
		BackgroundColor3 = theme.Window,
		BorderSizePixel = 0,
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Active = true,
	})
	Utility.corner(root, 14)
	self.Stroke = Utility.stroke(root, theme.Stroke, 1)
	self.Library.Theme:Bind(root, "BackgroundColor3", "Window")
	self.Library.Theme:Bind(self.Stroke, "Color", "Stroke")
	Utility.create("UIGradient", {
		Parent = root,
		Rotation = 110,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 230)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(1, 0.97),
		}),
	})
	return root
end

function Window:_iconButton(parent, glyph, layout)
	local theme = self.Library.Theme:Get()
	local button = Utility.create("TextButton", {
		Parent = parent,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		Text = glyph,
		TextColor3 = theme.Text,
		TextSize = 12,
		Size = UDim2.fromOffset(28, 28),
		LayoutOrder = layout,
	})
	Utility.corner(button, 7)
	self.Library.Theme:Bind(button, "BackgroundColor3", "Element")
	return button
end

function Window:_createTopbar()
	local theme = self.Library.Theme:Get()
	self.Topbar = Utility.create("Frame", {
		Parent = self.Root,
		Name = "Topbar",
		BackgroundColor3 = theme.Topbar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
	})
	self.Library.Theme:Bind(self.Topbar, "BackgroundColor3", "Topbar")
	self.TitleLabel = Utility.create("TextLabel", {
		Parent = self.Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(168, 8),
		Size = UDim2.new(1, -280, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = self.Title,
		TextColor3 = theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self.Library.Theme:Bind(self.TitleLabel, "TextColor3", "Text")
	self:_createSearch()
	self.Chrome = Utility.create("Frame", {
		Parent = self.Topbar,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(100, 28),
		Position = UDim2.new(1, -112, 0, 12),
	})
	Utility.create("UIListLayout", {
		Parent = self.Chrome,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	self.MinButton = self:_iconButton(self.Chrome, Icons.Minimize, 1)
	self.MaxButton = self:_iconButton(self.Chrome, Icons.Maximize, 2)
	self.CloseButton = self:_iconButton(self.Chrome, Icons.Close, 3)
end

function Window:_createSearch()
	local theme = self.Library.Theme:Get()
	self.SearchBox = Utility.create("TextBox", {
		Parent = self.Topbar,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderText = Icons.Search .. "  Search",
		PlaceholderColor3 = theme.Muted,
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -290, 0, 24),
		Position = UDim2.fromOffset(168, 30),
	})
	Utility.corner(self.SearchBox, 7)
	Utility.padding(self.SearchBox, 6)
	self.Library.Theme:Bind(self.SearchBox, "BackgroundColor3", "Element")
	self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:Search(self.SearchBox.Text)
	end)
end

function Window:_createSidebar()
	local theme = self.Library.Theme:Get()
	self.Sidebar = Utility.create("Frame", {
		Parent = self.Root,
		Name = "Sidebar",
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 156, 1, -52),
		Position = UDim2.fromOffset(0, 52),
	})
	self.Library.Theme:Bind(self.Sidebar, "BackgroundColor3", "Sidebar")
	Utility.create("TextLabel", {
		Parent = self.Sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -16, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = "NAVIGATION",
		TextColor3 = theme.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self.Brand = Utility.create("TextLabel", {
		Parent = self.Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.fromOffset(140, 28),
		Font = Enum.Font.GothamBold,
		Text = "MyUI",
		TextColor3 = theme.Accent,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self.Library.Theme:Bind(self.Brand, "TextColor3", "Accent")
	self.TabList = Utility.create("ScrollingFrame", {
		Parent = self.Sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -28),
		Position = UDim2.fromOffset(0, 22),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
	})
	Utility.list(self.TabList, 6)
	Utility.create("UIPadding", {
		Parent = self.TabList,
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
	})
end

function Window:_createContent()
	local theme = self.Library.Theme:Get()
	self.Content = Utility.create("Frame", {
		Parent = self.Root,
		Name = "Content",
		BackgroundColor3 = theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(156, 52),
		Size = UDim2.new(1, -156, 1, -86),
		ClipsDescendants = true,
	})
	self.Library.Theme:Bind(self.Content, "BackgroundColor3", "Content")
	self.Pages = Utility.create("Folder", {
		Parent = self.Content,
		Name = "Pages",
	})
end

function Window:_createFooter()
	local theme = self.Library.Theme:Get()
	self.Footer = Utility.create("Frame", {
		Parent = self.Root,
		Name = "Footer",
		BackgroundColor3 = theme.Footer,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -156, 0, 34),
		Position = UDim2.new(0, 156, 1, -34),
	})
	self.Library.Theme:Bind(self.Footer, "BackgroundColor3", "Footer")
	self.FooterLabel = Utility.create("TextLabel", {
		Parent = self.Footer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -90, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Font = Enum.Font.Gotham,
		Text = "MyUILibrary  ·  " .. self.Library.Theme:GetName(),
		TextColor3 = theme.Muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self.ThemeButton = Utility.create("TextButton", {
		Parent = self.Footer,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		Text = Icons.Moon .. " Theme",
		TextColor3 = theme.Text,
		TextSize = 11,
		Size = UDim2.fromOffset(78, 22),
		Position = UDim2.new(1, -88, 0.5, -11),
	})
	Utility.corner(self.ThemeButton, 6)
end

function Window:_createOverlayWidgets()
	local theme = self.Library.Theme:Get()
	self.ContextMenu = Utility.create("Frame", {
		Parent = self.Overlay,
		Name = "ContextMenu",
		BackgroundColor3 = theme.Modal,
		Visible = false,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(160, 88),
		ZIndex = 90,
	})
	Utility.corner(self.ContextMenu, 8)
	Utility.stroke(self.ContextMenu, theme.Stroke, 1)
	Utility.list(self.ContextMenu, 2)
	Utility.padding(self.ContextMenu, 6)
	self:_contextItem("Switch Theme", function()
		self.Library:ToggleTheme()
	end)
	self:_contextItem("Save Config", function()
		self.Library:SaveConfig()
	end)
	self:_contextItem("Load Config", function()
		self.Library:LoadConfig()
	end)
	self.Modal = Utility.create("Frame", {
		Parent = self.Overlay,
		Name = "Modal",
		BackgroundColor3 = theme.Modal,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 180),
		ZIndex = 92,
	})
	Utility.corner(self.Modal, 12)
	self.Popup = Utility.create("Frame", {
		Parent = self.Overlay,
		Name = "Popup",
		BackgroundColor3 = theme.Modal,
		Visible = false,
		Size = UDim2.fromOffset(220, 64),
		ZIndex = 91,
	})
	Utility.corner(self.Popup, 10)
end

function Window:_contextItem(text, callback)
	local theme = self.Library.Theme:Get()
	local item = Utility.create("TextButton", {
		Parent = self.ContextMenu,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = theme.Text,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 24),
	})
	Utility.corner(item, 5)
	item.MouseButton1Click:Connect(function()
		self.ContextMenu.Visible = false
		callback()
	end)
end

function Window:_attachServices()
	self.Drag = Drag.new(self.Root, self.Topbar, function()
		self.Library.Config:MaybeAutoSave()
	end)
	self.ResizeService = Resize.new(self.Root, self.Root, {
		Min = Vector2.new(480, 320),
		Max = Vector2.new(1400, 900),
	})
	self.Library.Theme:Bind(self.ResizeService.Grip, "TextColor3", "Muted")
end

function Window:_bindChrome()
	self.Root.InputBegan:Connect(function()
		self.Library.WindowManager:Focus(self)
	end)
	self.MinButton.MouseButton1Click:Connect(function()
		self:Minimize()
	end)
	self.MaxButton.MouseButton1Click:Connect(function()
		self:Maximize()
	end)
	self.CloseButton.MouseButton1Click:Connect(function()
		self:Close()
	end)
	self.ThemeButton.MouseButton1Click:Connect(function()
		self.Library:ToggleTheme()
	end)
	self.Topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:ShowContext()
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.ContextMenu.Visible = false
		end
	end)
	self.Library.Theme:OnChanged(function(_, name)
		self.FooterLabel.Text = "MyUILibrary  ·  " .. name
	end)
end

function Window:AddTab(name, icon)
	local tab = Tab.new(self, name, icon)
	table.insert(self.Tabs, tab)
	if not self.ActiveTab then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	self.ActiveTab = tab
	for _, item in ipairs(self.Tabs) do
		item:SetActive(item == tab)
	end
end

function Window:Search(query)
	if self.ActiveTab then
		self.ActiveTab:Search(query)
	end
end

function Window:SetTitle(text)
	self.Title = text
	self.TitleLabel.Text = text
end

function Window:Minimize()
	self.Minimized = not self.Minimized
	self.Sidebar.Visible = not self.Minimized
	self.Content.Visible = not self.Minimized
	self.Footer.Visible = not self.Minimized
	if self.Minimized then
		self._miniSize = self.Root.Size
		Animation.resize(self.Root, UDim2.fromOffset(self.Root.AbsoluteSize.X, 52))
	else
		Animation.resize(self.Root, self._miniSize or self.Options.Size or UDim2.fromOffset(650, 420))
	end
end

function Window:Maximize()
	if self.Maximized then
		self.Root.Position = self._restore.Position
		self.Root.AnchorPoint = self._restore.AnchorPoint or Vector2.new(0.5, 0.5)
		Animation.resize(self.Root, self._restore.Size)
		self.Maximized = false
		self.Drag:SetEnabled(true)
		self.ResizeService:SetEnabled(true)
		self.MaxButton.Text = Icons.Maximize
		return
	end
	self._restore = { Position = self.Root.Position, Size = self.Root.Size, AnchorPoint = self.Root.AnchorPoint }
	self.Root.Position = UDim2.fromOffset(0, 0)
	self.Root.AnchorPoint = Vector2.new(0, 0)
	self.Root.Size = UDim2.fromScale(1, 1)
	self.Maximized = true
	self.Drag:SetEnabled(false)
	self.ResizeService:SetEnabled(false)
	self.MaxButton.Text = Icons.Restore
end

function Window:ShowContext()
	local mouse = Utility.guiMouse()
	self.ContextMenu.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	self.ContextMenu.Visible = true
end

function Window:ShowModal(options)
	options = options or {}
	self.Dimmer.Visible = true
	self.Modal.Visible = true
	self.Modal:ClearAllChildren()
	Utility.corner(self.Modal, 12)
	local theme = self.Library.Theme:Get()
	Utility.create("TextLabel", {
		Parent = self.Modal,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.new(1, -32, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = options.Title or "Modal",
		TextColor3 = theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Utility.create("TextLabel", {
		Parent = self.Modal,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 48),
		Size = UDim2.new(1, -32, 0, 70),
		Font = Enum.Font.Gotham,
		Text = options.Content or "",
		TextColor3 = theme.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local close = Utility.create("TextButton", {
		Parent = self.Modal,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = "OK",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		Size = UDim2.fromOffset(88, 28),
		Position = UDim2.new(1, -108, 1, -44),
	})
	Utility.corner(close, 7)
	close.MouseButton1Click:Connect(function()
		self:HideModal()
		if options.Callback then
			options.Callback()
		end
	end)
end

function Window:HideModal()
	self.Modal.Visible = false
	self.Dimmer.Visible = false
end

function Window:ShowPopup(text, position)
	self.Popup.Visible = true
	if not self.Popup:FindFirstChild("Text") then
		Utility.create("TextLabel", {
			Parent = self.Popup,
			Name = "Text",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = self.Library.Theme:Get().Text,
		})
	end
	self.Popup.Text.Text = text
	self.Popup.Position = position or UDim2.fromScale(0.5, 0.2)
end

function Window:Hide()
	self.Root.Visible = false
end

function Window:Show()
	self.Root.Visible = true
	Animation.openWindow(self.Root)
end

function Window:Close()
	Animation.closeWindow(self.Root, function()
		if self.Options.DestroyOnClose then
			self:Destroy()
		end
	end)
end

function Window:Refresh()
	if self.ActiveTab then
		self:SelectTab(self.ActiveTab)
	end
end

function Window:Destroy()
	self.Library.WindowManager:Unregister(self)
	self.Drag:Destroy()
	self.ResizeService:Destroy()
	Utility.destroy(self.Gui)
end

return Window
