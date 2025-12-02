-- Fly GUI V6 - The Strongest Battleground Edition
-- Автор: XNEO | Оптимизировано для TS Battlegrounds

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Переменные
local flyEnabled = false
local flySpeed = 50
local displaySpeed = 1
local forceFieldEnabled = false
local damageRedirectEnabled = false
local noclipEnabled = false
local savedPosition = nil
local upPressed = false
local downPressed = false
local flyConnection = nil
local forceFieldConnection = nil

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyGUITS"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderColor3 = Color3.fromRGB(0, 180, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

-- Функция создания кнопок
local function CreateButton(name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = MainFrame
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.AutoButtonColor = false
    button.TextScaled = true
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = button
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 30, 255),
            math.min(color.G * 255 + 30, 255),
            math.min(color.B * 255 + 30, 255)
        ) / 255}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = size - UDim2.new(0, 4, 0, 4)}):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = size}):Play()
    end)
    
    return button
end

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚔️ FLY GUI TS BATTLEGROUND ⚔️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = MainFrame

-- Создание кнопок
local FlyButton = CreateButton("FlyButton", "🚀 FLY: OFF", UDim2.new(0.05, 0, 0.16, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(200, 50, 50))

local UpButton = CreateButton("UpButton", "↑ UP", UDim2.new(0.55, 0, 0.16, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(50, 170, 50))

local DownButton = CreateButton("DownButton", "↓ DOWN", UDim2.new(0.05, 0, 0.27, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(220, 120, 50))

local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Name = "SpeedDisplay"
SpeedDisplay.Parent = MainFrame
SpeedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SpeedDisplay.BorderSizePixel = 0
SpeedDisplay.Position = UDim2.new(0.55, 0, 0.27, 0)
SpeedDisplay.Size = UDim2.new(0.4, 0, 0, 36)
SpeedDisplay.Font = Enum.Font.GothamBold
SpeedDisplay.Text = "SPEED: 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDisplay.TextScaled = true
local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 6)
SpeedCorner.Parent = SpeedDisplay

local IncreaseButton = CreateButton("IncreaseBtn", "+", UDim2.new(0.05, 0, 0.38, 0), UDim2.new(0.2, 0, 0, 36), Color3.fromRGB(50, 150, 50))

local DecreaseButton = CreateButton("DecreaseBtn", "-", UDim2.new(0.3, 0, 0.38, 0), UDim2.new(0.2, 0, 0, 36), Color3.fromRGB(180, 50, 50))

local ForceFieldButton = CreateButton("ForceFieldBtn", "🛡️ FORCE FIELD: OFF", UDim2.new(0.55, 0, 0.38, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(50, 100, 200))

local DamageRedirectButton = CreateButton("DamageRedirectBtn", "⚡ DMG REDIRECT: OFF", UDim2.new(0.05, 0, 0.49, 0), UDim2.new(0.9, 0, 0, 36), Color3.fromRGB(180, 50, 150))

local NoclipButton = CreateButton("NoclipBtn", "🚫 NOCLIP: OFF", UDim2.new(0.05, 0, 0.6, 0), UDim2.new(0.9, 0, 0, 36), Color3.fromRGB(130, 50, 200))

local SavePosButton = CreateButton("SavePosBtn", "💾 SAVE POSITION", UDim2.new(0.05, 0, 0.71, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(255, 165, 0))

local TeleportButton = CreateButton("TeleportBtn", "📍 TELEPORT", UDim2.new(0.55, 0, 0.71, 0), UDim2.new(0.4, 0, 0, 36), Color3.fromRGB(0, 160, 255))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "✖", UDim2.new(0.92, 0, 0.02, 0), UDim2.new(0.06, 0, 0.12, 0), Color3.fromRGB(200, 50, 50))

local MinButton = CreateButton("MinBtn", "–", UDim2.new(0.84, 0, 0.02, 0), UDim2.new(0.06, 0, 0.12, 0), Color3.fromRGB(255, 165, 0))

-- Переменные для полета
local bodyGyro, bodyVelocity

-- Исправленная функция полета для TS Battlegrounds
local function ToggleFly()
    if not character or not humanoidRootPart then
        return
    end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        FlyButton.Text = "🚀 FLY: ON"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        humanoid.PlatformStand = true
        
        -- Создаем BodyGyro и BodyVelocity
        bodyGyro = Instance.new("BodyGyro")
        bodyVelocity = Instance.new("BodyVelocity")
        
        bodyGyro.Parent = humanoidRootPart
        bodyVelocity.Parent = humanoidRootPart
        
        bodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        bodyGyro.P = 10000
        bodyGyro.D = 1000
        bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        -- Соединение для полета
        flyConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not flyEnabled then
                return
            end
            
            local camera = workspace.CurrentCamera
            local root = humanoidRootPart
            
            -- Определяем направление движения
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Управление WASD
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            
            -- Вертикальное управление
            if upPressed then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            elseif downPressed then
                moveDirection = moveDirection + Vector3.new(0, -1, 0)
            end
            
            -- Нормализация и применение скорости
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
                local velocity = moveDirection * flySpeed
                bodyVelocity.Velocity = velocity
                
                -- Поворачиваем персонажа в направлении движения (кроме вертикального)
                local horizontalDir = Vector3.new(moveDirection.X, 0, moveDirection.Z)
                if horizontalDir.Magnitude > 0.1 then
                    bodyGyro.CFrame = CFrame.new(root.Position, root.Position + horizontalDir)
                end
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        
    else
        FlyButton.Text = "🚀 FLY: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        humanoid.PlatformStand = false
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
        
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        
        upPressed = false
        downPressed = false
    end
end

-- Силовое поле для TS Battlegrounds
local function ToggleForceField()
    forceFieldEnabled = not forceFieldEnabled
    
    if forceFieldEnabled then
        ForceFieldButton.Text = "🛡️ FORCE FIELD: ON"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        
        -- Создаем силовое поле
        forceFieldConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not forceFieldEnabled then
                return
            end
            
            local myPosition = humanoidRootPart.Position
            
            -- Отталкиваем других игроков
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherChar = otherPlayer.Character
                    if otherChar then
                        local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        
                        if otherRoot and otherHum and otherHum.Health > 0 then
                            local distance = (myPosition - otherRoot.Position).Magnitude
                            
                            -- Если игрок в радиусе 10 studs
                            if distance < 10 then
                                local direction = (otherRoot.Position - myPosition).Unit
                                local pushForce = 15
                                
                                -- Применяем отталкивание
                                local bv = Instance.new("BodyVelocity")
                                bv.Velocity = direction * pushForce
                                bv.MaxForce = Vector3.new(5000, 5000, 5000)
                                bv.Parent = otherRoot
                                Debris:AddItem(bv, 0.2)
                            end
                        end
                    end
                end
            end
        end)
        
    else
        ForceFieldButton.Text = "🛡️ FORCE FIELD: OFF"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        
        if forceFieldConnection then
            forceFieldConnection:Disconnect()
            forceFieldConnection = nil
        end
    end
end

-- Перенаправление урона для TS Battlegrounds
local function ToggleDamageRedirect()
    damageRedirectEnabled = not damageRedirectEnabled
    
    if damageRedirectEnabled then
        DamageRedirectButton.Text = "⚡ DMG REDIRECT: ON"
        DamageRedirectButton.BackgroundColor3 = Color3.fromRGB(200, 60, 160)
        
        -- Защищаем от урона
        spawn(function()
            while damageRedirectEnabled and character do
                humanoid.Health = humanoid.MaxHealth
                task.wait(0.1)
            end
        end)
        
        -- Отслеживаем получение урона
        humanoid.HealthChanged:Connect(function()
            if damageRedirectEnabled then
                -- Ищем ближайшего игрока для перенаправления урона
                local closestPlayer = nil
                local closestDistance = math.huge
                local myPos = humanoidRootPart.Position
                
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player then
                        local otherChar = otherPlayer.Character
                        if otherChar then
                            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                            if otherRoot then
                                local distance = (myPos - otherRoot.Position).Magnitude
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = otherPlayer
                                end
                            end
                        end
                    end
                end
                
                -- Наносим урон ближайшему игроку
                if closestPlayer then
                    local otherChar = closestPlayer.Character
                    if otherChar then
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        if otherHum then
                            -- Наносим случайный урон (10-30)
                            otherHum:TakeDamage(math.random(10, 30))
                        end
                    end
                end
            end
        end)
        
    else
        DamageRedirectButton.Text = "⚡ DMG REDIRECT: OFF"
        DamageRedirectButton.BackgroundColor3 = Color3.fromRGB(180, 50, 150)
    end
end

-- Ноклип
local function ToggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        NoclipButton.Text = "🚫 NOCLIP: ON"
        NoclipButton.BackgroundColor3 = Color3.fromRGB(170, 70, 220)
    else
        NoclipButton.Text = "🚫 NOCLIP: OFF"
        NoclipButton.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
    end
end

-- Обработчики кнопок
FlyButton.MouseButton1Click:Connect(ToggleFly)

UpButton.MouseButton1Down:Connect(function()
    upPressed = true
end)

UpButton.MouseButton1Up:Connect(function()
    upPressed = false
end)

UpButton.MouseLeave:Connect(function()
    upPressed = false
end)

DownButton.MouseButton1Down:Connect(function()
    downPressed = true
end)

DownButton.MouseButton1Up:Connect(function()
    downPressed = false
end)

DownButton.MouseLeave:Connect(function()
    downPressed = false
end)

IncreaseButton.MouseButton1Click:Connect(function()
    displaySpeed = displaySpeed + 1
    if displaySpeed > 10 then displaySpeed = 10 end
    flySpeed = displaySpeed * 10
    SpeedDisplay.Text = "SPEED: " .. displaySpeed
end)

DecreaseButton.MouseButton1Click:Connect(function()
    displaySpeed = displaySpeed - 1
    if displaySpeed < 1 then displaySpeed = 1 end
    flySpeed = displaySpeed * 10
    SpeedDisplay.Text = "SPEED: " .. displaySpeed
end)

ForceFieldButton.MouseButton1Click:Connect(ToggleForceField)
DamageRedirectButton.MouseButton1Click:Connect(ToggleDamageRedirect)
NoclipButton.MouseButton1Click:Connect(ToggleNoclip)

SavePosButton.MouseButton1Click:Connect(function()
    if character and humanoidRootPart then
        savedPosition = humanoidRootPart.CFrame
        SavePosButton.Text = "✓ SAVED!"
        task.wait(2)
        SavePosButton.Text = "💾 SAVE POSITION"
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if savedPosition and character and humanoidRootPart then
        humanoidRootPart.CFrame = savedPosition
        TeleportButton.Text = "✓ TELEPORTED!"
        task.wait(2)
        TeleportButton.Text = "📍 TELEPORT"
    else
        TeleportButton.Text = "NO SAVED POS!"
        task.wait(2)
        TeleportButton.Text = "📍 TELEPORT"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinButton.Text = MainFrame.Visible and "–" or "+"
end)

-- Обработка ноклипа
RunService.Stepped:Connect(function()
    if noclipEnabled and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Горячие клавиши
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        ToggleFly()
    elseif input.KeyCode == Enum.KeyCode.E then
        displaySpeed = displaySpeed + 1
        if displaySpeed > 10 then displaySpeed = 10 end
        flySpeed = displaySpeed * 10
        SpeedDisplay.Text = "SPEED: " .. displaySpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        displaySpeed = displaySpeed - 1
        if displaySpeed < 1 then displaySpeed = 1 end
        flySpeed = displaySpeed * 10
        SpeedDisplay.Text = "SPEED: " .. displaySpeed
    elseif input.KeyCode == Enum.KeyCode.R then
        ToggleForceField()
    elseif input.KeyCode == Enum.KeyCode.T then
        ToggleDamageRedirect()
    elseif input.KeyCode == Enum.KeyCode.Y then
        ToggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.Space then
        if flyEnabled then
            upPressed = true
        end
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        if flyEnabled then
            downPressed = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        upPressed = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        downPressed = false
    end
end)

-- Обработка смерти
humanoid.Died:Connect(function()
    if flyEnabled then ToggleFly() end
    if forceFieldEnabled then ToggleForceField() end
    if damageRedirectEnabled then ToggleDamageRedirect() end
    if noclipEnabled then ToggleNoclip() end
end)

-- Обработка нового персонажа
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    
    -- Восстанавливаем функции при респавне
    task.wait(1)
    if flyEnabled then
        FlyButton.Text = "🚀 FLY: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        flyEnabled = false
    end
end)

-- Уведомление
task.wait(2)
StarterGui:SetCore("SendNotification", {
    Title = "FLY GUI TS BATTLEGROUND",
    Text = "Successfully loaded!\nF - Fly, E/Q - Speed\nR - Force Field, T - Damage Redirect",
    Duration = 5
})

print("✅ Fly GUI for The Strongest Battleground loaded!")
