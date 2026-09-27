-- Camera Mods Module
-- Compatible avec shift lock et view fps
-- Auteur: [VOTRE_USERNAME]

local CameraMods = {}
CameraMods.Enabled = false
CameraMods.Connection = nil
CameraMods.CameraOffset = Vector3.new(0, 0, 0)
CameraMods.FOV = 70
CameraMods.OriginalFOV = 70
CameraMods.CameraType = nil

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
    
    -- Changer le type de caméra sans casser shift lock
    -- On utilise Scriptable qui permet un contrôle total tout en préservant les contrôles
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    
    -- Synchroniser la caméra avec le personnage pour préserver shift lock
    CameraMods.Connection = RunService.RenderStepped:Connect(function()
        if not CameraMods.Enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        
        if humanoidRootPart and head then
            -- Calculer la position de la caméra en préservant la rotation du personnage
            local cameraCFrame = CFrame.new(
                humanoidRootPart.Position + CameraMods.CameraOffset,
                head.Position
            )
            
            -- Appliquer la rotation actuelle de la caméra pour préserver view fps
            local currentRotation = Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position
            Workspace.CurrentCamera.CFrame = CFrame.new(
                humanoidRootPart.Position + CameraMods.CameraOffset
            ) * currentRotation
            
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
    
    if CameraMods.CameraType then
        Workspace.CurrentCamera.CameraType = CameraMods.CameraType
    end
    
    Workspace.CurrentCamera.FieldOfView = CameraMods.OriginalFOV
    
    print("[CameraMods] Désactivé")
end

-- Fonction pour définir l'offset de la caméra
function CameraMods.SetOffset(offset)
    CameraMods.CameraOffset = offset
end

-- Fonction pour définir le FOV
function CameraMods.SetFOV(fov)
    CameraMods.FOV = fov
    if CameraMods.Enabled then
        Workspace.CurrentCamera.FieldOfView = fov
    end
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
