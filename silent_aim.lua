--[[
    Silent Aim Module
    Système d'aim silencieux basé sur le système de ciblage du Shotgun Rage
    Compatible avec Obsidian UI
--]]

local SilentAimModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Enabled = false,
    FOV = 90,
    TargetPart = "Head",
    TeamCheck = true,
    Smoothness = 0.1, -- 0 = instant, 1 = très lent
    PredictionAmount = 0.05, -- Prédiction du mouvement
    VisibleCheck = true, -- Vérifier si la cible est visible
    Target = nil, -- Cible actuelle
    Connection = nil,
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    HoldMouseButton = false, -- Maintenir le clic pour activer
    MouseButton = Enum.UserInputType.MouseButton1, -- Bouton de souris
    AutoFire = false, -- Tir automatique
    FireRate = 0.1, -- Cadence de tir auto
    LastFireTime = 0,
}

-- Fonction pour trouver la partie ciblée avec variantes de noms
local function GetTargetPart(character, partName)
    local part = character:FindFirstChild(partName)
    if part then return part end
    
    -- Variantes de noms pour compatibilité
    local variants = {
        ["Head"] = {"Head", "head", "MeshPartHead", "HeadMesh"},
        ["HumanoidRootPart"] = {"HumanoidRootPart", "RootPart", "root", "Hips"},
        ["UpperTorso"] = {"UpperTorso", "UpperBody", "Torso", "Body"},
        ["LowerTorso"] = {"LowerTorso", "LowerBody", "Legs", "Lower"},
    }
    
    if variants[partName] then
        for _, variant in pairs(variants[partName]) do
            part = character:FindFirstChild(variant)
            if part then return part end
        end
    end
    
    -- Recherche dans les descendants
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant.Name:lower():find(partName:lower()) and descendant:IsA("BasePart") then
            return descendant
        end
    end
    
    return nil
end

-- Vérifier si un point est dans le FOV
local function IsInFOV(targetPosition, camera)
    local cameraPosition = camera.CFrame.Position
    local directionToTarget = (targetPosition - cameraPosition).Unit
    local cameraDirection = camera.CFrame.LookVector
    
    local dotProduct = directionToTarget:Dot(cameraDirection)
    local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))
    
    return angle <= Config.FOV / 2
end

-- Vérifier si la cible est visible (pas derrière un mur)
local function IsVisible(targetPosition)
    if not Config.VisibleCheck then return true end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character}
    
    local rayResult = workspace:Raycast(humanoidRootPart.Position, targetPosition - humanoidRootPart.Position, rayParams)
    
    -- Si le rayon atteint la cible sans obstruction
    return rayResult == nil or (rayResult.Position - targetPosition).Magnitude < 1
end

-- Prédire la position de la cible
local function PredictPosition(target, predictionAmount)
    if predictionAmount == 0 then return target.Position end
    
    local character = target.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
        local velocity = humanoid.MoveDirection * humanoid.WalkSpeed
        return target.Position + (velocity * predictionAmount)
    end
    
    return target.Position
end

-- Trouver la meilleure cible (basé sur le système du Shotgun Rage)
local function GetBestTarget()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local camera = workspace.CurrentCamera
    local bestTarget = nil
    local closestAngle = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Vérifier si c'est un allié
        if getgenv().RiftAllies and getgenv().RiftAllies.IsAlly(player.Name) then
            continue
        end
        
        local targetCharacter = player.Character
        if not targetCharacter then continue end
        
        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Team Check
        if Config.TeamCheck then
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end
            if player.TeamColor and LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor then
                continue
            end
        end
        
        local targetPart = GetTargetPart(targetCharacter, Config.TargetPart)
        if not targetPart then continue end
        
        -- Vérifier si dans le FOV
        if not IsInFOV(targetPart.Position, camera) then continue end
        
        -- Vérifier si visible
        if not IsVisible(targetPart.Position) then continue end
        
        -- Calculer l'angle par rapport au centre de l'écran
        local directionToTarget = (targetPart.Position - camera.CFrame.Position).Unit
        local cameraDirection = camera.CFrame.LookVector
        local dotProduct = directionToTarget:Dot(cameraDirection)
        local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))
        
        if angle < closestAngle then
            closestAngle = angle
            bestTarget = targetPart
        end
    end
    
    return bestTarget
end

-- Orienter la caméra vers la cible avec smoothness
local function AimAtTarget(target)
    if not target then return end
    
    local camera = workspace.CurrentCamera
    local predictedPosition = PredictPosition(target, Config.PredictionAmount)
    
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, predictedPosition)
    
    -- Appliquer la smoothness
    if Config.Smoothness > 0 then
        camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - Config.Smoothness)
    else
        camera.CFrame = targetCFrame
    end
end

-- Mettre à jour le silent aim
local function UpdateSilentAim()
    if not Config.Enabled then return end
    
    -- Vérifier si le bouton de souris est maintenu (si activé)
    if Config.HoldMouseButton then
        local mouseHeld = UserInputService:IsMouseButtonPressed(Config.MouseButton)
        if not mouseHeld then
            Config.Target = nil
            return
        end
    end
    
    -- Trouver la meilleure cible
    local target = GetBestTarget()
    Config.Target = target
    
    if target then
        AimAtTarget(target)
        
        -- Tir automatique si activé
        if Config.AutoFire then
            local currentTime = tick()
            if currentTime - Config.LastFireTime >= Config.FireRate then
                if mouse1click then
                    mouse1click()
                end
                Config.LastFireTime = currentTime
            end
        end
    end
end

-- Activer le silent aim
local function EnableSilentAim()
    if Config.Enabled then return end
    
    Config.Enabled = true
    
    -- Sauvegarder l'état original de la caméra
    local camera = workspace.CurrentCamera
    Config.OriginalCameraType = camera.CameraType
    Config.OriginalCameraCFrame = camera.CFrame
    
    -- Passer en mode Scriptable pour contrôler la caméra
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Démarrer la boucle d'aim
    if Config.Connection then
        Config.Connection:Disconnect()
    end
    
    Config.Connection = RunService.RenderStepped:Connect(function()
        UpdateSilentAim()
    end)
    
    print("[SilentAim] Activé")
end

-- Désactiver le silent aim
local function DisableSilentAim()
    Config.Enabled = false
    Config.Target = nil
    
    -- Restaurer l'état original de la caméra
    local camera = workspace.CurrentCamera
    if Config.OriginalCameraType then
        camera.CameraType = Config.OriginalCameraType
    end
    
    if Config.Connection then
        Config.Connection:Disconnect()
        Config.Connection = nil
    end
    
    print("[SilentAim] Désactivé")
end

-- Fonctions d'API publique
function SilentAimModule.Enable()
    EnableSilentAim()
end

function SilentAimModule.Disable()
    DisableSilentAim()
end

function SilentAimModule.IsEnabled()
    return Config.Enabled
end

function SilentAimModule.GetCurrentTarget()
    return Config.Target
end

function SilentAimModule.SetFOV(fov)
    Config.FOV = fov
end

function SilentAimModule.GetFOV()
    return Config.FOV
end

function SilentAimModule.SetTargetPart(partName)
    Config.TargetPart = partName
end

function SilentAimModule.GetTargetPart()
    return Config.TargetPart
end

function SilentAimModule.SetTeamCheck(enabled)
    Config.TeamCheck = enabled
end

function SilentAimModule.GetTeamCheck()
    return Config.TeamCheck
end

function SilentAimModule.SetSmoothness(smoothness)
    Config.Smoothness = smoothness
end

function SilentAimModule.GetSmoothness()
    return Config.Smoothness
end

function SilentAimModule.SetPredictionAmount(amount)
    Config.PredictionAmount = amount
end

function SilentAimModule.GetPredictionAmount()
    return Config.PredictionAmount
end

function SilentAimModule.SetVisibleCheck(enabled)
    Config.VisibleCheck = enabled
end

function SilentAimModule.GetVisibleCheck()
    return Config.VisibleCheck
end

function SilentAimModule.SetHoldMouseButton(enabled)
    Config.HoldMouseButton = enabled
end

function SilentAimModule.GetHoldMouseButton()
    return Config.HoldMouseButton
end

function SilentAimModule.SetMouseButton(button)
    Config.MouseButton = button
end

function SilentAimModule.GetMouseButton()
    return Config.MouseButton
end

function SilentAimModule.SetAutoFire(enabled)
    Config.AutoFire = enabled
end

function SilentAimModule.GetAutoFire()
    return Config.AutoFire
end

function SilentAimModule.SetFireRate(rate)
    Config.FireRate = rate
end

function SilentAimModule.GetFireRate()
    return Config.FireRate
end

-- Retourner le module
return SilentAimModule
