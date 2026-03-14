-- ESP Script | Versão corrigida
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    EnemyColor   = Color3.fromRGB(255, 68, 68),
    AllyColor    = Color3.fromRGB(68, 255, 68),
    MaxDistance  = 500,
    ShowBox      = true,
    ShowName     = true,
    ShowHealth   = true,
    TeamCheck    = true,
    ShowAllies   = true,
    Thickness    = 1,
}

local ESPObjects = {}

local function isSameTeam(player)
    return player.Team ~= nil and player.Team == LocalPlayer.Team
end

local function createESP(player)
    if player == LocalPlayer then return end
    local obj = {}

    if Config.ShowBox then
        obj.Box = Drawing.new("Square")
        obj.Box.Thickness = Config.Thickness
        obj.Box.Filled = false
        obj.Box.Visible = false
        obj.Box.Color = Config.EnemyColor
    end

    if Config.ShowName then
        obj.Name = Drawing.new("Text")
        obj.Name.Size = 13
        obj.Name.Center = true
        obj.Name.Outline = true
        obj.Name.Visible = false
        obj.Name.Color = Color3.fromRGB(255, 255, 255)
    end

    if Config.ShowHealth then
        obj.HealthBG = Drawing.new("Square")
        obj.HealthBG.Thickness = 1
        obj.HealthBG.Filled = true
        obj.HealthBG.Color = Color3.fromRGB(0, 0, 0)
        obj.HealthBG.Visible = false

        obj.HealthBar = Drawing.new("Square")
        obj.HealthBar.Thickness = 1
        obj.HealthBar.Filled = true
        obj.HealthBar.Visible = false
    end

    ESPObjects[player] = obj
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function hideESP(obj)
    for _, v in pairs(obj) do
        v.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then createESP(player) end

        local obj = ESPObjects[player]
        if not obj then continue end

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not root or not hum or hum.Health <= 0 then
            hideESP(obj) continue
        end

        local dist = (root.Position - Camera.CFrame.Position).Magnitude
        if dist > Config.MaxDistance then hideESP(obj) continue end

        local isAlly = Config.TeamCheck and isSameTeam(player)
        if isAlly and not Config.ShowAllies then hideESP(obj) continue end

        local color = isAlly and Config.AllyColor or Config.EnemyColor

        local pos, visible, depth = Camera:WorldToViewportPoint(root.Position)
        if not visible then hideESP(obj) continue end

        local scale = 1 / depth * 1000
        local bW = scale * 1.8
        local bH = scale * 3.2
        local bX = pos.X - bW / 2
        local bY = pos.Y - bH / 2

        if obj.Box then
            obj.Box.Size     = Vector2.new(bW, bH)
            obj.Box.Position = Vector2.new(bX, bY)
            obj.Box.Color    = color
            obj.Box.Visible  = true
        end

        if obj.Name then
            obj.Name.Text     = player.Name .. "  [" .. math.floor(dist) .. "m]"
            obj.Name.Position = Vector2.new(pos.X, bY - 15)
            obj.Name.Color    = color
            obj.Name.Visible  = true
        end

        if obj.HealthBar then
            local hpRatio = hum.Health / hum.MaxHealth
            local barH    = bH * hpRatio
            local hpColor = hpRatio > 0.6 and Color3.fromRGB(68, 255, 68)
                         or hpRatio > 0.3 and Color3.fromRGB(255, 170, 0)
                         or Color3.fromRGB(255, 51, 51)

            obj.HealthBG.Size     = Vector2.new(4, bH)
            obj.HealthBG.Position = Vector2.new(bX - 7, bY)
            obj.HealthBG.Visible  = true

            obj.HealthBar.Size     = Vector2.new(4, barH)
            obj.HealthBar.Position = Vector2.new(bX - 7, bY + (bH - barH))
            obj.HealthBar.Color    = hpColor
            obj.HealthBar.Visible  = true
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    createESP(player)
end)

-- Inicializa ESP para players já na partida
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end
