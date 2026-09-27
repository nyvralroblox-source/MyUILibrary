-- Camera Mods Module
-- Compatible avec shift lock et view fps
-- Auteur: nyvralroblox

local CameraMods = {}
CameraMods.Enabled = false
CameraMods.Connection = nil
CameraMods.CameraOffset = Vector3.new(0, 0, 0)
CameraMods.FOV = 70
CameraMods.OriginalFOV = 70
CameraMods.CameraType = nil
CameraMods.OriginalCFrame = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Préserver les contrôles natifs
local function EnableCameraMods()
    if CameraMods.Enabled then return end
    
    CameraMods.Enabled = true
    
    -- Sauvegarder l'état original
    CameraMods.OriginalFOV = Workspace.CurrentCamera.FieldOfView
    CameraMods.CameraType = Workspace.CurrentCamera.CameraType
    CameraMods.OriginalCFrame = Workspace.CurrentCamera.CFrame
    
    -- IMPORTANT: Ne PAS changer le CameraType pour préserver shift lock
    -- On garde le type actuel et on modifie seulement la position
    
    -- Synchroniser la caméra avec le personnage pour préserver shift lock
    CameraMods.Connection = RunService.RenderStepped:Connect(function()
        if not CameraMods.Enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        
        if humanoidRootPart and head then
            -- Obtenir la rotation actuelle de la caméra (préserve view fps)
            local currentRotation = Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position
            
            -- Calculer la nouvelle position avec l'offset
            local cameraPosition = humanoidRootPart.Position + CameraMods.CameraOffset
            
            -- Appliquer la nouvelle position en préservant la rotation
            Workspace.CurrentCamera.CFrame = CFrame.new(cameraPosition) * currentRotation
            
            -- Appliquer le FOV
            Workspace.CurrentCamera.FieldOfView = CameraMods.FOV
        end
    end)
    
    print("[CameraMods] Activé - Shift lock et view fps préservés")
end

local function DisableCameraMods()
    if not CameraMods.Enabled then return end
    
    CameraMods.Enabled = false
    
    -- Restaurer l'état original
    if CameraMods.Connection then
        CameraMods.Connection:Disconnect()
        CameraMods.Connection = nil
    end
    
    -- Restaurer le FOV
    Workspace.CurrentCamera.FieldOfView = CameraMods.OriginalFOV
    
    -- Ne PAS restaurer le CameraType pour ne pas casser shift lock
    -- La caméra reste à sa position actuelle qui sera réinitialisée par le jeu
    
    print("[CameraMods] Désactivé")
end

-- Fonction pour définir l'offset de la caméra
function CameraMods.SetOffset(offset)
    CameraMods.CameraOffset = offset
end

-- Fonction pour obtenir l'offset actuel
function CameraMods.GetOffset()
    return CameraMods.CameraOffset
end

-- Fonction pour définir le FOV
function CameraMods.SetFOV(fov)
    CameraMods.FOV = fov
    if CameraMods.Enabled then
        Workspace.CurrentCamera.FieldOfView = fov
    end
end

-- Fonction pour obtenir le FOV actuel
function CameraMods.GetFOV()
    return CameraMods.FOV
end

-- Fonction pour déplacer la caméra
function CameraMods.MoveCamera(direction, distance)
    if direction == "up" then
        CameraMods.CameraOffset = CameraMods.CameraOffset + Vector3.new(0, distance, 0)
    elseif direction == "down" then
        CameraMods.CameraOffset = CameraMods.CameraOffset - Vector3.new(0, distance, 0)
    elseif direction == "left" then
        CameraMods.CameraOffset = CameraMods.CameraOffset - Vector3.new(distance, 0, 0)
    elseif direction == "right" then
        CameraMods.CameraOffset = CameraMods.CameraOffset + Vector3.new(distance, 0, 0)
    elseif direction == "forward" then
        CameraMods.CameraOffset = CameraMods.CameraOffset + Vector3.new(0, 0, distance)
    elseif direction == "backward" then
        CameraMods.CameraOffset = CameraMods.CameraOffset - Vector3.new(0, 0, distance)
    end
end

-- Fonction pour réinitialiser la caméra
function CameraMods.ResetCamera()
    CameraMods.CameraOffset = Vector3.new(0, 0, 0)
    CameraMods.FOV = CameraMods.OriginalFOV
    if CameraMods.Enabled then
        Workspace.CurrentCamera.FieldOfView = CameraMods.OriginalFOV
    end
end

-- API publique
CameraMods.Enable = EnableCameraMods
CameraMods.Disable = DisableCameraMods
CameraMods.IsEnabled = function() return CameraMods.Enabled end

return CameraMods
