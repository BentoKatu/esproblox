--[[
    ESP Educacional para Arsenal (Roblox)
    PARA TESTES DE SEGURANÇA AUTORIZADOS
    Desenvolvido para fins educacionais
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP = {
    Enabled = true,
    TeamCheck = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowBoxes = true,
    MaxDistance = 500,
    ColorAlly = Color3.fromRGB(0, 255, 0),    -- Verde
    ColorEnemy = Color3.fromRGB(255, 0, 0),   -- Vermelho
    ColorNeutral = Color3.fromRGB(255, 255, 0) -- Amarelo
}

-- Armazenar os ESPs criados
local ESPObjects = {}

-- Função para criar um ESP para um jogador
function ESP:CreateESP(player)
    if ESPObjects[player] then return end
    
    local esp = {
        player = player,
        box = nil,
        nameLabel = nil,
        distanceLabel = nil,
        healthLabel = nil
    }
    
    -- Criar elementos visuais
    esp.box = Drawing.new("Square")
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.box.Visible = false
    
    if self.ShowNames then
        esp.nameLabel = Drawing.new("Text")
        esp.nameLabel.Size = 16
        esp.nameLabel.Center = true
        esp.nameLabel.Outline = true
        esp.nameLabel.Visible = false
    end
    
    if self.ShowDistance then
        esp.distanceLabel = Drawing.new("Text")
        esp.distanceLabel.Size = 14
        esp.distanceLabel.Center = true
        esp.distanceLabel.Outline = true
        esp.distanceLabel.Visible = false
    end
    
    if self.ShowHealth then
        esp.healthLabel = Drawing.new("Text")
        esp.healthLabel.Size = 14
        esp.healthLabel.Center = true
        esp.healthLabel.Outline = true
        esp.healthLabel.Visible = false
    end
    
    ESPObjects[player] = esp
end

-- Função para determinar a cor baseada no time
function ESP:GetTeamColor(player)
    if not self.TeamCheck then
        return self.ColorEnemy
    end
    
    local localTeam = LocalPlayer.Team
    local playerTeam = player.Team
    
    if not localTeam or not playerTeam then
        return self.ColorNeutral
    end
    
    if localTeam == playerTeam then
        return self.ColorAlly
    else
        return self.ColorEnemy
    end
end

-- Função para atualizar o ESP
function ESP:UpdateESP(player)
    local esp = ESPObjects[player]
    if not esp or not esp.box then return end
    
    local character = player.Character
    if not character then
        esp.box.Visible = false
        if esp.nameLabel then esp.nameLabel.Visible = false end
        if esp.distanceLabel then esp.distanceLabel.Visible = false end
        if esp.healthLabel then esp.healthLabel.Visible = false end
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
        esp.box.Visible = false
        if esp.nameLabel then esp.nameLabel.Visible = false end
        if esp.distanceLabel then esp.distanceLabel.Visible = false end
        if esp.healthLabel then esp.healthLabel.Visible = false end
        return
    end
    
    -- Calcular posição na tela
    local position, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > self.MaxDistance then
        esp.box.Visible = false
        if esp.nameLabel then esp.nameLabel.Visible = false end
        if esp.distanceLabel then esp.distanceLabel.Visible = false end
        if esp.healthLabel then esp.healthLabel.Visible = false end
        return
    end
    
    -- Calcular tamanho da caixa baseado na distância
    local scale = 1000 / distance
    local width = 4 * scale
    local height = 6 * scale
    
    -- Cor baseada no time
    local color = self:GetTeamColor(player)
    
    -- Atualizar caixa
    esp.box.Size = Vector2.new(width, height)
    esp.box.Position = Vector2.new(position.X - width/2, position.Y - height/2)
    esp.box.Color = color
    esp.box.Visible = self.Enabled and self.ShowBoxes
    
    -- Atualizar nome
    if esp.nameLabel then
        esp.nameLabel.Position = Vector2.new(position.X, position.Y - height/2 - 20)
        esp.nameLabel.Text = player.Name
        esp.nameLabel.Color = color
        esp.nameLabel.Visible = self.Enabled and self.ShowNames
    end
    
    -- Atualizar distância
    if esp.distanceLabel then
        esp.distanceLabel.Position = Vector2.new(position.X, position.Y - height/2 - 5)
        esp.distanceLabel.Text = string.format("[%dm]", math.floor(distance))
        esp.distanceLabel.Color = color
        esp.distanceLabel.Visible = self.Enabled and self.ShowDistance
    end
    
    -- Atualizar saúde
    if esp.healthLabel then
        esp.healthLabel.Position = Vector2.new(position.X, position.Y + height/2 + 5)
        esp.healthLabel.Text = string.format("HP: %d", math.floor(humanoid.Health))
        esp.healthLabel.Color = color
        esp.healthLabel.Visible = self.Enabled and self.ShowHealth
    end
end

-- Função para remover ESP
function ESP:RemoveESP(player)
    local esp = ESPObjects[player]
    if esp then
        if esp.box then esp.box:Remove() end
        if esp.nameLabel then esp.nameLabel:Remove() end
        if esp.distanceLabel then esp.distanceLabel:Remove() end
        if esp.healthLabel then esp.healthLabel:Remove() end
        ESPObjects[player] = nil
    end
end

-- Interface de controle
function ESP:CreateInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ESPControls"
    ScreenGui.Parent = game.CoreGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 250, 0, 200)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BackgroundTransparency = 0.3
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local function CreateLabel(text, position, parent)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = position
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = parent
        return label
    end
    
    CreateLabel("ESP Arsenal - Controles", UDim2.new(0, 5, 0, 5), Frame)
    CreateLabel("F1: ESP On/Off", UDim2.new(0, 5, 0, 25), Frame)
    CreateLabel("F2: Team Check", UDim2.new(0, 5, 0, 45), Frame)
    CreateLabel("F3: Nomes", UDim2.new(0, 5, 0, 65), Frame)
    CreateLabel("F4: Distância", UDim2.new(0, 5, 0, 85), Frame)
    CreateLabel("F5: Saúde", UDim2.new(0, 5, 0, 105), Frame)
    CreateLabel("F6: Caixas", UDim2.new(0, 5, 0, 125), Frame)
    CreateLabel("F7/F8: Distância Max", UDim2.new(0, 5, 0, 145), Frame)
    
    return ScreenGui
end

-- Controles de teclado
function ESP:HandleInput(input)
    if input.KeyCode == Enum.KeyCode.F1 then
        self.Enabled = not self.Enabled
        print("ESP: " .. (self.Enabled and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F2 then
        self.TeamCheck = not self.TeamCheck
        print("Team Check: " .. (self.TeamCheck and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F3 then
        self.ShowNames = not self.ShowNames
        print("Nomes: " .. (self.ShowNames and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F4 then
        self.ShowDistance = not self.ShowDistance
        print("Distância: " .. (self.ShowDistance and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F5 then
        self.ShowHealth = not self.ShowHealth
        print("Saúde: " .. (self.ShowHealth and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F6 then
        self.ShowBoxes = not self.ShowBoxes
        print("Caixas: " .. (self.ShowBoxes and "ON" or "OFF"))
        
    elseif input.KeyCode == Enum.KeyCode.F7 then
        self.MaxDistance = math.max(50, self.MaxDistance - 50)
        print("Distância Max: " .. self.MaxDistance .. "m")
        
    elseif input.KeyCode == Enum.KeyCode.F8 then
        self.MaxDistance = math.min(1000, self.MaxDistance + 50)
        print("Distância Max: " .. self.MaxDistance .. "m")
    end
end

-- Inicialização
function ESP:Initialize()
    -- Criar interface
    self:CreateInterface()
    
    -- Configurar inputs
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        self:HandleInput(input)
    end)
    
    -- Gerenciar jogadores
    Players.PlayerAdded:Connect(function(player)
        self:CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:RemoveESP(player)
    end)
    
    -- Criar ESP para jogadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:CreateESP(player)
        end
    end
    
    -- Loop de atualização
    RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        
        for player, esp in pairs(ESPObjects) do
            if player ~= LocalPlayer then
                self:UpdateESP(player)
            end
        end
    end)
    
    print("ESP Arsenal Carregado!")
    print("Controles: F1-F8 - Ver interface para detalhes")
end

-- Iniciar o ESP
ESP:Initialize()
