--[[
	Animation
	Toutes les animations passent par TweenService.
]]

local TweenService = game:GetService("TweenService")
local Utility = require(script.Parent.Utility)

local Animation = {}

local DEFAULT_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

Animation.Info = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = DEFAULT_INFO,
	Slow = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Spring = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Linear = TweenInfo.new(0.2, Enum.EasingStyle.Linear),
}

--- Tween générique.
function Animation.tween(instance, properties, info)
	info = info or Animation.Info.Normal
	local tween = TweenService:Create(instance, info, properties)
	tween:Play()
	return tween
end

--- Fondu d'un GuiObject via BackgroundTransparency et/ou TextTransparency.
function Animation.fade(instance, transparency, info)
	local props = {}
	if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1 then
		props.BackgroundTransparency = transparency
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		props.TextTransparency = transparency
	end
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		props.ImageTransparency = transparency
	end
	if instance:IsA("UIStroke") then
		props.Transparency = transparency
	end
	return Animation.tween(instance, props, info or Animation.Info.Fast)
end

--- Glisse un GuiObject vers une position.
function Animation.slide(instance, position, info)
	return Animation.tween(instance, { Position = position }, info or Animation.Info.Spring)
end

--- Redimensionne via Size.
function Animation.resize(instance, size, info)
	return Animation.tween(instance, { Size = size }, info or Animation.Info.Normal)
end

--- Survol : éclaircit le fond.
function Animation.hover(instance, color)
	return Animation.tween(instance, { BackgroundColor3 = color }, Animation.Info.Fast)
end

--- Enfoncement : réduit légèrement l'échelle.
function Animation.press(instance, scale)
	scale = scale or 0.97
	local constraint = instance:FindFirstChildOfClass("UIScale")
	if not constraint then
		constraint = Utility.create("UIScale", { Parent = instance, Scale = 1 })
	end
	return Animation.tween(constraint, { Scale = scale }, Animation.Info.Fast)
end

function Animation.release(instance)
	local constraint = instance:FindFirstChildOfClass("UIScale")
	if not constraint then
		return
	end
	return Animation.tween(constraint, { Scale = 1 }, Animation.Info.Fast)
end

--- Onde (ripple) au clic.
function Animation.ripple(parent, origin)
	local circle = Utility.create("Frame", {
		Parent = parent,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = origin or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		ZIndex = (parent.ZIndex or 1) + 1,
	})
	Utility.corner(circle, 999)
	local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
	Animation.tween(circle, {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
	}, Animation.Info.Slow).Completed:Connect(function()
		circle:Destroy()
	end)
	return circle
end

--- Ouverture d'une fenêtre (fade + scale).
function Animation.openWindow(frame)
	local scale = frame:FindFirstChildOfClass("UIScale") or Utility.create("UIScale", {
		Parent = frame,
		Scale = 0.94,
	})
	frame.Visible = true
	scale.Scale = 0.94
	Animation.tween(scale, { Scale = 1 }, Animation.Info.Spring)
	return Animation.fade(frame, frame.BackgroundTransparency, Animation.Info.Fast)
end

--- Fermeture d'une fenêtre.
function Animation.closeWindow(frame, callback)
	local scale = frame:FindFirstChildOfClass("UIScale") or Utility.create("UIScale", {
		Parent = frame,
		Scale = 1,
	})
	Animation.tween(scale, { Scale = 0.94 }, Animation.Info.Fast)
	local tween = Animation.tween(frame, { BackgroundTransparency = 0.2 }, Animation.Info.Fast)
	tween.Completed:Connect(function()
		frame.Visible = false
		if callback then
			callback()
		end
	end)
	return tween
end

--- Déploiement d'un dropdown.
function Animation.openDropdown(frame, height)
	frame.Visible = true
	frame.ClipsDescendants = true
	frame.Size = UDim2.new(1, 0, 0, 0)
	return Animation.resize(frame, UDim2.new(1, 0, 0, height), Animation.Info.Normal)
end

function Animation.closeDropdown(frame)
	local tween = Animation.resize(frame, UDim2.new(1, 0, 0, 0), Animation.Info.Fast)
	tween.Completed:Connect(function()
		frame.Visible = false
	end)
	return tween
end

--- Curseur du toggle (on/off).
function Animation.toggleKnob(knob, on, onColor, offColor)
	local offset = on and 18 or 2
	Animation.tween(knob, {
		Position = UDim2.new(0, offset, 0.5, 0),
		BackgroundColor3 = on and onColor or offColor,
	}, Animation.Info.Fast)
end

--- Fill d'un slider.
function Animation.sliderFill(fill, scale)
	return Animation.tween(fill, {
		Size = UDim2.new(scale, 0, 1, 0),
	}, Animation.Info.Fast)
end

--- Entrée d'une notification.
function Animation.notifyIn(frame)
	frame.BackgroundTransparency = 1
	frame.Visible = true
	return Animation.tween(frame, { BackgroundTransparency = 0 }, Animation.Info.Fast)
end

function Animation.notifyOut(frame, callback)
	local tween = Animation.tween(frame, { BackgroundTransparency = 1 }, Animation.Info.Fast)
	tween.Completed:Connect(function()
		if callback then
			callback()
		end
	end)
	return tween
end

return Animation
