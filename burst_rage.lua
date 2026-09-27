--[[
    Burst Rage Module
    Système de téléportation rapide dans le joueur le plus proche avec caméra Desync Anchor Part
    Compatible avec Obsidian UI
--]]

local BurstRageModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Enabled = false,
    Target = nil, -- Cible actuelle
    TeleportDistance = 2, -- Distance du joueur (dans le joueur)
    TeleportRate = 10, -- Nombre de téléportations par seconde
    LookAtHead = true, -- Regarder la tête de la cible
    TeamCheck = true,
    MinHealth = 1,
    BurstDuration = 0.5, -- Durée d'un burst (s)
    RestDuration = 0.2, -- Durée de repos entre bursts (s)
    
    -- Configuration caméra Desync Anchor Part
    CameraDesyncEnabled = true,
    CameraAnchorPart = nil, -- Part ancrée pour le desync
    CameraDesyncOffset = Vector3.new(0, 5, 0), -- Offset du desync
    CameraDesyncSpeed = 5, -- Vitesse de changement de position
    CameraPreserveSubject = true, -- Garder le CameraSubject original
    
    -- État interne
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    OriginalCameraSubject = nil,
    Connection = nil,
    CameraConnection = nil,
    LastTeleportTime = 0,
    LastBurstTime = 0,
    IsBursting = false,
    DesyncAngle = 0,
}

-- Trouver le joueur le plus proche (basé sur Shotgun Rage)
local function GetNearestPlayer()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearest, nearestDist = nil, math.huge
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        -- Vérifier si c'est un allié
        if getgenv().RiftAllies and getgenv().RiftAllies.IsAlly(plr.Name) then
            continue
        end
        
        local targetCharacter = plr.Character
        if not targetCharacter then continue end
        
        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Team Check
        if Config.TeamCheck then
            if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                continue
            end
            if plr.TeamColor and LocalPlayer.TeamColor and plr.TeamColor == LocalPlayer.TeamColor then
                continue
            end
        end
        
        -- Health check
        if humanoid.Health < Config.MinHealth then continue end
        
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local dist = (targetRoot.Position - humanoidRootPart.Position).Magnitude
            if dist < nearestDist and dist < 1000 then
                nearestDist = dist
                nearest = plr
            end
        end
    end
    
    return nearest
end

-- Téléporter dans le joueur le plus proche
local function TeleportToTarget()
    local targetPlayer = GetNearestPlayer()
    if not targetPlayer then return end
    
    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return end
    
    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local targetHead = targetCharacter:FindFirstChild("Head")
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Calculer la position dans le joueur
    local teleportPosition = targetHRP.Position + Vector3.new(
        math.random(-Config.TeleportDistance, Config.TeleportDistance),
        0,
        math.random(-Config.TeleportDistance, Config.TeleportDistance)
    )
    
    -- Orienter vers la tête si activé
    if Config.LookAtHead and targetHead then
        humanoidRootPart.CFrame = CFrame.new(teleportPosition, targetHead.Position)
    else
        humanoidRootPart.CFrame = CFrame.new(teleportPosition, targetHRP.Position)
    end
    
    -- Synchronisation serveur
    humanoid:MoveTo(teleportPosition)
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    
    Config.Target = targetPlayer
end

-- Créer la Part ancrée pour le desync de caméra
local function CreateCameraAnchorPart()
    if Config.CameraAnchorPart then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Créer une Part invisible ancrée
    local anchorPart = Instance.new("Part")
    anchorPart.Name = "CameraDesyncAnchor"
    anchorPart.Size = Vector3.new(1, 1, 1)
    anchorPart.Anchored = true -- Ancrée localement
    anchorPart.CanCollide = false
    anchorPart.CanQuery = false
    anchorPart.Transparency = 1
    anchorPart.Position = humanoidRootPart.Position + Config.CameraDesyncOffset
    anchorPart.Parent = workspace
    
    Config.CameraAnchorPart = anchorPart
end

-- Détruire la Part ancrée
local function DestroyCameraAnchorPart()
    if Config.CameraAnchorPart then
        Config.CameraAnchorPart:Destroy()
        Config.CameraAnchorPart = nil
    end
end

-- Mettre à jour le desync de caméra
local function UpdateCameraDesync()
    if not Config.CameraDesyncEnabled or not Config.CameraAnchorPart then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Mettre à jour la position de la Part ancrée pour créer le desync
    -- La Part reste ancrée localement mais sa position change pour le serveur
    Config.DesyncAngle = (Config.DesyncAngle + Config.CameraDesyncSpeed) % 360
    
    local angleRad = math.rad(Config.DesyncAngle)
    local desyncOffset = Vector3.new(
        math.cos(angleRad) * 3,
        Config.CameraDesyncOffset.Y,
        math.sin(angleRad) * 3
    )
    
    Config.CameraAnchorPart.CFrame = CFrame.new(
        humanoidRootPart.Position + desyncOffset,
        humanoidRootPart.Position
    )
    
    -- Utiliser la Part comme CameraSubject pour le desync
    camera.CameraSubject = Config.CameraAnchorPart
    
    -- Modifier la CFrame de la caméra pour créer un effet de désynchronisation
    local cameraOffset = Vector3.new(
        math.sin(angleRad) * 2,
        0,
        math.cos(angleRad) * 2
    )
    
    camera.CFrame = CFrame.new(
        Config.CameraAnchorPart.Position + cameraOffset,
        humanoidRootPart.Position
    )
end

-- Restaurer la caméra normale
local function RestoreCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    -- Restaurer le CameraSubject original
    if Config.OriginalCameraSubject then
        camera.CameraSubject = Config.OriginalCameraSubject
    end
    
    -- Restaurer le CameraType original
    if Config.OriginalCameraType then
        camera.CameraType = Config.OriginalCameraType
    end
end

-- Cycle principal du Burst Rage
local function BurstRageCycle()
    if not Config.Enabled then return end
    
    local currentTime = tick()
    
    -- Gérer les phases de burst et de repos
    if Config.IsBursting then
        -- Phase de burst : téléportations rapides
        if currentTime - Config.LastTeleportTime >= (1 / Config.TeleportRate) then
            TeleportToTarget()
            Config.LastTeleportTime = currentTime
        end
        
        -- Passer en repos après la durée du burst
        if currentTime - Config.LastBurstTime >= Config.BurstDuration then
            Config.IsBursting = false
            Config.LastBurstTime = currentTime
        end
    else
        -- Phase de repos : pas de téléportation
        if currentTime - Config.LastBurstTime >= Config.RestDuration then
            Config.IsBursting = true
            Config.LastBurstTime = currentTime
            Config.LastTeleportTime = currentTime
        end
    end
    
    -- Mettre à jour le desync de caméra en continu
    UpdateCameraDesync()
end

-- Activer le Burst Rage
local function EnableBurstRage()
    if Config.Enabled then return end
    
    Config.Enabled = true
    Config.IsBursting = true
    Config.LastBurstTime = tick()
    Config.LastTeleportTime = tick()
    Config.DesyncAngle = 0
    
    -- Sauvegarder l'état original de la caméra
    local camera = workspace.CurrentCamera
    Config.OriginalCameraType = camera.CameraType
    Config.OriginalCameraCFrame = camera.CFrame
    Config.OriginalCameraSubject = camera.CameraSubject
    
    -- Créer la Part ancrée pour le desync
    CreateCameraAnchorPart()
    
    -- Démarrer la boucle principale
    if Config.Connection then
        Config.Connection:Disconnect()
    end
    
    Config.Connection = RunService.RenderStepped:Connect(function()
        BurstRageCycle()
    end)
    
    print("[BurstRage] Activé")
end

-- Désactiver le Burst Rage
local function DisableBurstRage()
    Config.Enabled = false
    Config.IsBursting = false
    Config.Target = nil
    
    -- Restaurer la caméra
    RestoreCamera()
    
    -- Détruire la Part ancrée
    DestroyCameraAnchorPart()
    
    if Config.Connection then
        Config.Connection:Disconnect()
        Config.Connection = nil
    end
    
    print("[BurstRage] Désactivé")
end

-- Fonctions d'API publique
function BurstRageModule.Enable()
    EnableBurstRage()
end

function BurstRageModule.Disable()
    DisableBurstRage()
end

function BurstRageModule.IsEnabled()
    return Config.Enabled
end

function BurstRageModule.GetCurrentTarget()
    return Config.Target
end

function BurstRageModule.SetTeleportDistance(distance)
    Config.TeleportDistance = distance
end

function BurstRageModule.GetTeleportDistance()
    return Config.TeleportDistance
end

function BurstRageModule.SetTeleportRate(rate)
    Config.TeleportRate = rate
end

function BurstRageModule.GetTeleportRate()
    return Config.TeleportRate
end

function BurstRageModule.SetLookAtHead(enabled)
    Config.LookAtHead = enabled
end

function BurstRageModule.GetLookAtHead()
    return Config.LookAtHead
end

function BurstRageModule.SetTeamCheck(enabled)
    Config.TeamCheck = enabled
end

function BurstRageModule.GetTeamCheck()
    return Config.TeamCheck
end

function BurstRageModule.SetMinHealth(health)
    Config.MinHealth = health
end

function BurstRageModule.GetMinHealth()
    return Config.MinHealth
end

function BurstRageModule.SetBurstDuration(duration)
    Config.BurstDuration = duration
end

function BurstRageModule.GetBurstDuration()
    return Config.BurstDuration
end

function BurstRageModule.SetRestDuration(duration)
    Config.RestDuration = duration
end

function BurstRageModule.GetRestDuration()
    return Config.RestDuration
end

function BurstRageModule.SetCameraDesyncEnabled(enabled)
    Config.CameraDesyncEnabled = enabled
end

function BurstRageModule.GetCameraDesyncEnabled()
    return Config.CameraDesyncEnabled
end

function BurstRageModule.SetCameraDesyncOffset(offset)
    Config.CameraDesyncOffset = offset
end

function BurstRageModule.GetCameraDesyncOffset()
    return Config.CameraDesyncOffset
end

function BurstRageModule.SetCameraDesyncSpeed(speed)
    Config.CameraDesyncSpeed = speed
end

function BurstRageModule.GetCameraDesyncSpeed()
    return Config.CameraDesyncSpeed
end

function BurstRageModule.SetCameraPreserveSubject(enabled)
    Config.CameraPreserveSubject = enabled
end

function BurstRageModule.GetCameraPreserveSubject()
    return Config.CameraPreserveSubject
end

-- Retourner le module
return BurstRageModule
