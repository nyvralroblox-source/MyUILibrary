--[[
    UE Counter Module
    Système de déplacement rapide autour d'un point d'activation
    Compatible avec Obsidian UI
--]]

local UECounterModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Enabled = false,
    ActivationPoint = nil, -- Point d'activation (Vector3)
    MoveSpeed = 500, -- Vitesse de déplacement
    ForwardDistance = 10, -- Distance avant/arrière
    SideDistance = 10, -- Distance gauche/droite
    Pattern = "ZigZag", -- "ZigZag", "Circle", "Square", "Random"
    PatternSpeed = 0.1, -- Vitesse de changement de pattern
    FaceTarget = true, -- Regarder vers le point d'activation
    ForceSync = true, -- Forcer la synchronisation serveur
    CurrentPatternIndex = 0,
    CurrentDirection = Vector3.new(1, 0, 0),
    LastPatternChange = 0,
    Connection = nil,
    OriginalWalkSpeed = nil,
}

-- Patterns de déplacement
local Patterns = {
    ZigZag = {
        {offset = Vector3.new(1, 0, 0), duration = 0.1},
        {offset = Vector3.new(-1, 0, 0), duration = 0.1},
        {offset = Vector3.new(0, 0, 1), duration = 0.1},
        {offset = Vector3.new(0, 0, -1), duration = 0.1},
    },
    Circle = {
        function(angle)
            return Vector3.new(math.cos(angle), 0, math.sin(angle))
        end,
    },
    Square = {
        {offset = Vector3.new(1, 0, 0), duration = 0.15},
        {offset = Vector3.new(0, 0, 1), duration = 0.15},
        {offset = Vector3.new(-1, 0, 0), duration = 0.15},
        {offset = Vector3.new(0, 0, -1), duration = 0.15},
    },
    Random = {
        function()
            return Vector3.new(
                math.random(-1, 1),
                0,
                math.random(-1, 1)
            ).Unit
        end,
    },
}

local function GetCurrentPosition()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    return humanoidRootPart.Position
end

local function SetPosition(position, lookAt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Utiliser CFrame pour téléportation rapide
    if lookAt then
        humanoidRootPart.CFrame = CFrame.new(position, lookAt)
    else
        humanoidRootPart.CFrame = CFrame.new(position)
    end
    
    -- Force sync
    if Config.ForceSync then
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function CalculateNextPosition()
    if not Config.ActivationPoint then return nil end
    
    local currentTime = tick()
    local pattern = Patterns[Config.Pattern]
    
    if not pattern then return nil end
    
    if Config.Pattern == "Circle" then
        -- Pattern circulaire continu
        local angle = (currentTime * Config.MoveSpeed * 0.1) % (math.pi * 2)
        local offset = pattern[1](angle)
        return Config.ActivationPoint + (offset * Config.ForwardDistance)
        
    elseif Config.Pattern == "Random" then
        -- Pattern aléatoire
        if currentTime - Config.LastPatternChange >= Config.PatternSpeed then
            Config.CurrentDirection = pattern[1]()
            Config.LastPatternChange = currentTime
        end
        return Config.ActivationPoint + (Config.CurrentDirection * Config.ForwardDistance)
        
    else
        -- Pattern discret (ZigZag, Square)
        if currentTime - Config.LastPatternChange >= Config.PatternSpeed then
            Config.CurrentPatternIndex = (Config.CurrentPatternIndex % #pattern) + 1
            Config.LastPatternChange = currentTime
        end
        
        local currentStep = pattern[Config.CurrentPatternIndex]
        if type(currentStep) == "table" then
            Config.PatternSpeed = currentStep.duration or Config.PatternSpeed
            return Config.ActivationPoint + (currentStep.offset * Config.ForwardDistance)
        end
    end
    
    return Config.ActivationPoint
end

local function UpdateMovement()
    if not Config.Enabled then return end
    
    local nextPosition = CalculateNextPosition()
    if not nextPosition then return end
    
    local lookAtPosition = Config.FaceTarget and Config.ActivationPoint or nil
    SetPosition(nextPosition, lookAtPosition)
end

local function EnableUECounter()
    if Config.Enabled then return end
    
    -- Définir le point d'activation comme position actuelle
    local currentPosition = GetCurrentPosition()
    if not currentPosition then
        warn("[UECounter] Impossible d'obtenir la position actuelle")
        return
    end
    
    Config.ActivationPoint = currentPosition
    Config.Enabled = true
    Config.CurrentPatternIndex = 0
    Config.LastPatternChange = tick()
    
    -- Sauvegarder la vitesse originale
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            Config.OriginalWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = Config.MoveSpeed
        end
    end
    
    -- Démarrer la boucle de mouvement
    if Config.Connection then
        Config.Connection:Disconnect()
    end
    
    Config.Connection = RunService.RenderStepped:Connect(function()
        UpdateMovement()
    end)
    
    print("[UECounter] Activé au point:", Config.ActivationPoint)
end

local function DisableUECounter()
    Config.Enabled = false
    Config.ActivationPoint = nil
    
    -- Restaurer la vitesse originale
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and Config.OriginalWalkSpeed then
            humanoid.WalkSpeed = Config.OriginalWalkSpeed
        end
    end
    
    if Config.Connection then
        Config.Connection:Disconnect()
        Config.Connection = nil
    end
    
    print("[UECounter] Désactivé")
end

-- Fonctions d'API publique
function UECounterModule.Enable()
    EnableUECounter()
end

function UECounterModule.Disable()
    DisableUECounter()
end

function UECounterModule.IsEnabled()
    return Config.Enabled
end

function UECounterModule.SetActivationPoint(position)
    Config.ActivationPoint = position
    print("[UECounter] Point d'activation défini:", position)
end

function UECounterModule.GetActivationPoint()
    return Config.ActivationPoint
end

function UECounterModule.SetPattern(patternName)
    if Patterns[patternName] then
        Config.Pattern = patternName
        Config.CurrentPatternIndex = 0
        print("[UECounter] Pattern changé:", patternName)
    else
        warn("[UECounter] Pattern invalide:", patternName)
    end
end

function UECounterModule.GetPattern()
    return Config.Pattern
end

function UECounterModule.SetMoveSpeed(speed)
    Config.MoveSpeed = speed
end

function UECounterModule.GetMoveSpeed()
    return Config.MoveSpeed
end

function UECounterModule.SetForwardDistance(distance)
    Config.ForwardDistance = distance
end

function UECounterModule.GetForwardDistance()
    return Config.ForwardDistance
end

function UECounterModule.SetSideDistance(distance)
    Config.SideDistance = distance
end

function UECounterModule.GetSideDistance()
    return Config.SideDistance
end

function UECounterModule.SetPatternSpeed(speed)
    Config.PatternSpeed = speed
end

function UECounterModule.GetPatternSpeed()
    return Config.PatternSpeed
end

function UECounterModule.SetFaceTarget(enabled)
    Config.FaceTarget = enabled
end

function UECounterModule.GetFaceTarget()
    return Config.FaceTarget
end

function UECounterModule.SetForceSync(enabled)
    Config.ForceSync = enabled
end

function UECounterModule.GetForceSync()
    return Config.ForceSync
end

function UECounterModule.GetAvailablePatterns()
    local patterns = {}
    for name, _ in pairs(Patterns) do
        table.insert(patterns, name)
    end
    return patterns
end

-- Retourner le module
return UECounterModule
