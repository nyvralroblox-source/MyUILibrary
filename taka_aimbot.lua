--[[
    Taka Aimbot Module
    Système d'aimbot basé sur TakaWare
    Compatible avec Obsidian UI
--]]

local TakaAimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Enabled = false,
    FOV = 150,
    Predict = 0,
    Smoothness = 0.3,
    WallCheck = true,
    TeamCheck = false,
    ShowFOVCircle = true,
    AimKey = Enum.UserInputType.MouseButton2,
    ToggleKey = nil,
    TargetPart = "Head",
    
    -- Friend System
    FriendCheck = true,
    Friends = {},
    
    -- FOV Circle Drawing
    FOVCircle = nil,
    
    -- État interne
    CurrentTarget = nil,
}

-- Créer le cercle FOV
local function CreateFOVCircle()
    if Config.FOVCircle then return end
    
    local Camera = Workspace.CurrentCamera
    Config.FOVCircle = Drawing.new("Circle")
    Config.FOVCircle.Thickness = 2
    Config.FOVCircle.Color = Color3.fromRGB(220, 40, 60)
    Config.FOVCircle.Filled = false
    Config.FOVCircle.Transparency = 0.6
    Config.FOVCircle.NumSides = 64
    Config.FOVCircle.Radius = Config.FOV
    Config.FOVCircle.Visible = Config.ShowFOVCircle and Config.Enabled
    Config.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end

-- Détruire le cercle FOV
local function DestroyFOVCircle()
    if Config.FOVCircle then
        Config.FOVCircle:Remove()
        Config.FOVCircle = nil
    end
end

-- Mettre à jour le cercle FOV
local function UpdateFOVCircle()
    if not Config.FOVCircle then return end
    
    local Camera = Workspace.CurrentCamera
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    Config.FOVCircle.Position = center
    Config.FOVCircle.Visible = Config.ShowFOVCircle and Config.Enabled
    Config.FOVCircle.Radius = Config.FOV
end

-- Vérifier si une partie est visible (Wall Check)
local function IsVisible(part)
    if not Config.WallCheck then return true end
    
    local Camera = Workspace.CurrentCamera
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local ray = Workspace:Raycast(origin, dir, RaycastParams.new({
        FilterDescendantsInstances = {LocalPlayer.Character},
        FilterType = Enum.RaycastFilterType.Exclude
    }))
    
    return not ray or ray.Instance:IsDescendantOf(part.Parent)
end

-- Vérifier si une cible est valide
local function IsTargetValid(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character.Humanoid or player.Character.Humanoid.Health <= 0 then return false
    
    -- Team Check
    if Config.TeamCheck then
        local localPlayer = LocalPlayer
        if localPlayer.Team and player.Team and localPlayer.Team == player.Team then
            return false
        end
    end
    
    -- Friend Check
    if Config.FriendCheck and Config.Friends[tostring(player.UserId)] then
        return false
    end
    
    return true
end

-- Trouver la cible la plus proche
local function GetClosest()
    local Camera = Workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local closest, dist = nil, math.huge
    
    for _, plr in Players:GetPlayers() do
        if IsTargetValid(plr) and plr.Character and plr.Character:FindFirstChild(Config.TargetPart) then
            local targetPart = plr.Character[Config.TargetPart]
            local pos, onScr = Camera:WorldToViewportPoint(targetPart.Position)
            if onScr then
                local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if d < Config.FOV and d < dist and IsVisible(targetPart) then
                    dist = d
                    closest = plr
                end
            end
        end
    end
    
    return closest
end

-- Fonction principale de l'aimbot
local function AimbotCycle()
    if not Config.Enabled then return end
    
    local Camera = Workspace.CurrentCamera
    
    -- Mettre à jour le cercle FOV
    UpdateFOVCircle()
    
    -- Vérifier si la touche est pressée
    local isKeyPressed = false
    if Config.AimKey then
        if typeof(Config.AimKey) == "EnumItem" then
            if Config.AimKey.EnumType == Enum.KeyCode then
                isKeyPressed = UserInputService:IsKeyDown(Config.AimKey)
            elseif Config.AimKey.EnumType == Enum.UserInputType then
                isKeyPressed = UserInputService:IsMouseButtonPressed(Config.AimKey)
            end
        end
    end
    
    if isKeyPressed then
        local target = GetClosest()
        Config.CurrentTarget = target
        
        if target and target.Character and target.Character:FindFirstChild(Config.TargetPart) then
            local targetPart = target.Character[Config.TargetPart]
            local headPos = targetPart.Position
            
            -- Prediction
            if Config.Predict > 0 then
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    headPos = headPos + root.Velocity * Config.Predict
                end
            end
            
            local pos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen then
                local mouse = UserInputService:GetMouseLocation()
                local dx = pos.X - mouse.X
                local dy = pos.Y - mouse.Y
                local s = math.max(Config.Smoothness, 0.1)
                mousemoverel(dx / s, dy / s)
            end
        end
    else
        Config.CurrentTarget = nil
    end
end

-- Ajouter un ami
local function AddFriend(userId)
    Config.Friends[tostring(userId)] = true
end

-- Retirer un ami
local function RemoveFriend(userId)
    Config.Friends[tostring(userId)] = nil
end

-- Vérifier si c'est un ami
local function IsFriend(userId)
    return Config.Friends[tostring(userId)] == true
end

-- Activer l'aimbot
local function EnableTakaAimbot()
    if Config.Enabled then return end
    
    Config.Enabled = true
    CreateFOVCircle()
    
    print("[TakaAimbot] Activé")
end

-- Désactiver l'aimbot
local function DisableTakaAimbot()
    Config.Enabled = false
    Config.CurrentTarget = nil
    DestroyFOVCircle()
    
    print("[TakaAimbot] Désactivé")
end

-- Fonctions d'API publique
function TakaAimbotModule.Enable()
    EnableTakaAimbot()
end

function TakaAimbotModule.Disable()
    DisableTakaAimbot()
end

function TakaAimbotModule.IsEnabled()
    return Config.Enabled
end

function TakaAimbotModule.GetCurrentTarget()
    return Config.CurrentTarget
end

function TakaAimbotModule.SetFOV(fov)
    Config.FOV = fov
    UpdateFOVCircle()
end

function TakaAimbotModule.GetFOV()
    return Config.FOV
end

function TakaAimbotModule.SetPredict(predict)
    Config.Predict = predict
end

function TakaAimbotModule.GetPredict()
    return Config.Predict
end

function TakaAimbotModule.SetSmoothness(smoothness)
    Config.Smoothness = smoothness
end

function TakaAimbotModule.GetSmoothness()
    return Config.Smoothness
end

function TakaAimbotModule.SetWallCheck(enabled)
    Config.WallCheck = enabled
end

function TakaAimbotModule.GetWallCheck()
    return Config.WallCheck
end

function TakaAimbotModule.SetTeamCheck(enabled)
    Config.TeamCheck = enabled
end

function TakaAimbotModule.GetTeamCheck()
    return Config.TeamCheck
end

function TakaAimbotModule.SetShowFOVCircle(enabled)
    Config.ShowFOVCircle = enabled
    UpdateFOVCircle()
end

function TakaAimbotModule.GetShowFOVCircle()
    return Config.ShowFOVCircle
end

function TakaAimbotModule.SetAimKey(key)
    Config.AimKey = key
end

function TakaAimbotModule.GetAimKey()
    return Config.AimKey
end

function TakaAimbotModule.SetToggleKey(key)
    Config.ToggleKey = key
end

function TakaAimbotModule.GetToggleKey()
    return Config.ToggleKey
end

function TakaAimbotModule.SetTargetPart(partName)
    Config.TargetPart = partName
end

function TakaAimbotModule.GetTargetPart()
    return Config.TargetPart
end

function TakaAimbotModule.SetFriendCheck(enabled)
    Config.FriendCheck = enabled
end

function TakaAimbotModule.GetFriendCheck()
    return Config.FriendCheck
end

function TakaAimbotModule.AddFriend(userId)
    AddFriend(userId)
end

function TakaAimbotModule.RemoveFriend(userId)
    RemoveFriend(userId)
end

function TakaAimbotModule.IsFriend(userId)
    return IsFriend(userId)
end

function TakaAimbotModule.GetFriends()
    return Config.Friends
end

function TakaAimbotModule.SetFriends(friendsTable)
    Config.Friends = friendsTable or {}
end

-- Fonction de mise à jour pour RenderStepped
function TakaAimbotModule.Update()
    AimbotCycle()
end

-- Retourner le module
return TakaAimbotModule
