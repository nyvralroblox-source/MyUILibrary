--[[
	FREECAM ROBLOX
	Emplacement : StarterPlayer > StarterPlayerScripts (LocalScript)

	CONTRÔLES
	  P ............ activer / désactiver la freecam
	  Souris ....... regarder autour (automatique, plus besoin de cliquer)
	  Alt gauche ... libérer / reverrouiller la souris (pour cliquer sur l'UI)
	  W A S D ...... avancer / gauche / reculer / droite
	  E / Q ........ monter / descendre
	  Molette ...... changer la vitesse
	  Shift ........ boost de vitesse
	  Ctrl ......... vitesse lente (précision)
	  Z / X ........ zoom avant / arrière (FOV)
	  R ............ réinitialiser le zoom
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
	ToggleKey = Enum.KeyCode.P,
	MouseReleaseKey = Enum.KeyCode.LeftAlt,
	BaseSpeed = 40,          -- studs/seconde
	MinSpeed = 2,
	MaxSpeed = 500,
	BoostMultiplier = 3,
	SlowMultiplier = 0.25,
	Sensitivity = 0.0035,    -- sensibilité souris
	Smoothness = 12,         -- plus haut = mouvement plus sec
	DefaultFOV = 70,
	MinFOV = 5,
	MaxFOV = 120,
	ZoomSpeed = 60,          -- degrés/seconde
}

----------------------------------------------------------------
-- ÉTAT
----------------------------------------------------------------
local enabled = false
local mouseLook = true
local position = Vector3.zero
local yaw, pitch = 0, 0
local velocity = Vector3.zero
local speed = CONFIG.BaseSpeed
local fov = CONFIG.DefaultFOV

local saved = {}

local RENDER_NAME = "FreecamUpdate"
local ACTION_NAME = "FreecamSink"

----------------------------------------------------------------
-- UTILITAIRES
----------------------------------------------------------------
local function isDown(key)
	return UserInputService:IsKeyDown(key)
end

local function getRotation()
	return CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end

local function sinkInput()
	return Enum.ContextActionResult.Sink
end

local blockedInputs = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Space,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
	Enum.KeyCode.Thumbstick1,
}

-- Contrôles par défaut du personnage (pour le geler complètement)
local function getControls()
	local ok, controls = pcall(function()
		local scripts = player:FindFirstChild("PlayerScripts")
		local module = scripts and scripts:FindFirstChild("PlayerModule")
		return module and require(module):GetControls()
	end)
	return ok and controls or nil
end

local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyMouseState()
	if mouseLook then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

----------------------------------------------------------------
-- BOUCLE PRINCIPALE
----------------------------------------------------------------
local function update(dt)
	-- On réapplique chaque frame : Roblox peut remettre le curseur par défaut
	applyMouseState()

	if mouseLook then
		local delta = UserInputService:GetMouseDelta()
		yaw -= delta.X * CONFIG.Sensitivity
		pitch = math.clamp(
			pitch - delta.Y * CONFIG.Sensitivity,
			math.rad(-89),
			math.rad(89)
		)
	end

	local rot = getRotation()
	local cf = CFrame.new(position) * rot

	local x, y, z = 0, 0, 0
	if isDown(Enum.KeyCode.D) then x += 1 end
	if isDown(Enum.KeyCode.A) then x -= 1 end
	if isDown(Enum.KeyCode.W) then z += 1 end
	if isDown(Enum.KeyCode.S) then z -= 1 end
	if isDown(Enum.KeyCode.E) then y += 1 end
	if isDown(Enum.KeyCode.Q) then y -= 1 end

	local currentSpeed = speed
	if isDown(Enum.KeyCode.LeftShift) then
		currentSpeed *= CONFIG.BoostMultiplier
	elseif isDown(Enum.KeyCode.LeftControl) then
		currentSpeed *= CONFIG.SlowMultiplier
	end

	local direction = cf.RightVector * x + cf.LookVector * z + Vector3.yAxis * y
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end

	local alpha = 1 - math.exp(-CONFIG.Smoothness * dt)
	velocity = velocity:Lerp(direction * currentSpeed, alpha)
	position += velocity * dt

	if isDown(Enum.KeyCode.Z) then
		fov -= CONFIG.ZoomSpeed * dt
	end
	if isDown(Enum.KeyCode.X) then
		fov += CONFIG.ZoomSpeed * dt
	end
	fov = math.clamp(fov, CONFIG.MinFOV, CONFIG.MaxFOV)

	camera.CFrame = CFrame.new(position) * rot
	camera.FieldOfView = fov
end

----------------------------------------------------------------
-- ACTIVER / DÉSACTIVER
----------------------------------------------------------------
local function enable()
	if enabled then return end
	enabled = true
	mouseLook = true

	saved.CameraType = camera.CameraType
	saved.CFrame = camera.CFrame
	saved.FOV = camera.FieldOfView
	saved.MouseBehavior = UserInputService.MouseBehavior
	saved.MouseIcon = UserInputService.MouseIconEnabled

	-- Le personnage ne doit ni bouger ni tourner
	local humanoid = getHumanoid()
	if humanoid then
		saved.AutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
	end
	local controls = getControls()
	if controls then
		controls:Disable()
	end

	position = camera.CFrame.Position
	local lx, ly = camera.CFrame:ToOrientation()
	pitch, yaw = lx, ly
	velocity = Vector3.zero
	fov = camera.FieldOfView

	camera.CameraType = Enum.CameraType.Scriptable

	ContextActionService:BindActionAtPriority(
		ACTION_NAME,
		sinkInput,
		false,
		Enum.ContextActionPriority.High.Value + 100,
		table.unpack(blockedInputs)
	)

	RunService:BindToRenderStep(
		RENDER_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		update
	)
end

local function disable()
	if not enabled then return end
	enabled = false

	RunService:UnbindFromRenderStep(RENDER_NAME)
	ContextActionService:UnbindAction(ACTION_NAME)

	UserInputService.MouseBehavior = saved.MouseBehavior or Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = saved.MouseIcon ~= false

	local humanoid = getHumanoid()
	if humanoid and saved.AutoRotate ~= nil then
		humanoid.AutoRotate = saved.AutoRotate
	end
	local controls = getControls()
	if controls then
		controls:Enable()
	end

	camera.CameraType = saved.CameraType or Enum.CameraType.Custom
	camera.FieldOfView = saved.FOV or CONFIG.DefaultFOV
	if saved.CFrame then
		camera.CFrame = saved.CFrame
	end
end

----------------------------------------------------------------
-- ENTRÉES
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == CONFIG.ToggleKey and not gameProcessed then
		if enabled then disable() else enable() end
		return
	end

	if not enabled then return end

	if input.KeyCode == CONFIG.MouseReleaseKey then
		mouseLook = not mouseLook
		applyMouseState()
	elseif input.KeyCode == Enum.KeyCode.R and not gameProcessed then
		fov = CONFIG.DefaultFOV
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if not enabled or gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		speed = math.clamp(
			speed * (1.15 ^ input.Position.Z),
			CONFIG.MinSpeed,
			CONFIG.MaxSpeed
		)
	end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	if enabled then
		camera.CameraType = Enum.CameraType.Scriptable
	end
end)

-- Si le personnage respawn pendant la freecam, on le regèle
player.CharacterAdded:Connect(function(char)
	if not enabled then return end
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid and enabled then
		saved.AutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
	end
end)
