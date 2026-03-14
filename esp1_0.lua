-- ESP Script | Gerado pelo ESP Config Tool
-- Uso autorizado para fins de teste e detecção

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Camera       = workspace.CurrentCamera
local LocalPlayer  = Players.LocalPlayer
local DrawLib      = loadstring(game:HttpGet("https://raw.githubusercontent.com/example/drawlib/main/draw.lua"))()

-- Configurações geradas automaticamente
local Config = {
    EnemyColor  = Color3.new{1, 0.26666666666666666, 0.26666666666666666, 1},
    AllyColor   = Color3.new{0.26666666666666666, 1, 0.26666666666666666, 1},
    MaxDistance = 500,
    MinHealth   = 0,
    BoxStyle    = "full",
    Thickness   = 1,
    ShowBox     = true,
    ShowName    = true,
    ShowHealth  = true,
    ShowDist    = false,
    ShowSnapline = false,
    TeamCheck   = true,
    ShowAllies  = true,
    IgnoreSelf  = true,
    LOSOnly     = false,
    IgnoreNPCs  = true,
    LogSuspects = true,
    AlertSuspects = true,
}

local ESPObjects = {}
local SuspectLog = {}

function isSameTeam(player)
    return player.Team == game.Players.LocalPlayer.Team
end

function getCharacterRoot(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

function getScreenPosition(position)
    local pos, visible = Camera:WorldToViewportPoint(position)
    return Vector2.new(pos.X, pos.Y), visible, pos.Z
end

function createESP(player)
    local obj = {}
        obj.Box = DrawLib.new("Square", { Thickness = Config.Thickness, Filled = false, Visible = false })
        obj.Name = DrawLib.new("Text", { Size = 13, Center = true, Outline = true, Visible = false })
        obj.HealthBar = DrawLib.new("Line", { Thickness = 3, Visible = false })
        -- Snapline desativada
    ESPObjects[player] = obj
end

function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end

function detectSuspect(player, root)
    -- Detecta comportamento suspeito de ESP (visibilidade anormal)
    local ray = Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 1000)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    local hasLOS = hit == nil or hit:IsDescendantOf(player.Character)
    if not hasLOS and not SuspectLog[player.UserId] then
        SuspectLog[player.UserId] = { name = player.Name, time = tick(), flags = 0 }
        warn("[ESP-DETECT] Suspeito: " .. player.Name .. " | UserId: " .. player.UserId)
    elseif SuspectLog[player.UserId] then
        SuspectLog[player.UserId].flags += 1
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then createESP(player) end

        local root, hum = getCharacterRoot(player)
        if not root or not hum or hum.Health <= 0 then
            removeESP(player) continue
        end

        local dist = (root.Position - Camera.CFrame.Position).Magnitude
        if dist > Config.MaxDistance then removeESP(player) continue end
        if hum.Health / hum.MaxHealth * 100 < Config.MinHealth then continue end

        local isAlly = isSameTeam(player)
        if isAlly and not Config.ShowAllies then removeESP(player) continue end
        local color = isAlly and Config.AllyColor or Config.EnemyColor

        detectSuspect(player, root)

        local screenPos, visible, depth = getScreenPosition(root.Position)
        if not visible then removeESP(player) continue end

        local scale = 1 / depth * 1000
        local bW, bH = scale * 1.8, scale * 3.2
        local bX = screenPos.X - bW / 2
        local bY = screenPos.Y - bH / 2

        local obj = ESPObjects[player]
                if obj.Box then
            obj.Box.Size = Vector2.new(bW, bH)
            obj.Box.Position = Vector2.new(bX, bY)
            obj.Box.Color = SuspectLog[player.UserId] and Color3.fromRGB(255,50,50) or color
            obj.Box.Visible = true
        end
                if obj.Name then
            obj.Name.Position = Vector2.new(screenPos.X, bY - 14)
            obj.Name.Text = player.Name .. (dist > 10 and "" or " (local)")
            obj.Name.Color = color
            obj.Name.Visible = true
        end
                if obj.HealthBar then
            local hpRatio = hum.Health / hum.MaxHealth
            local barH = bH * hpRatio
            local hpColor = hpRatio > 0.6 and Color3.fromRGB(68,255,68) or hpRatio > 0.3 and Color3.fromRGB(255,170,0) or Color3.fromRGB(255,51,51)
            obj.HealthBar.From = Vector2.new(bX - 5, bY + bH)
            obj.HealthBar.To = Vector2.new(bX - 5, bY + bH - barH)
            obj.HealthBar.Color = hpColor
            obj.HealthBar.Visible = true
        end
        
    end
end)

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(createESP)
