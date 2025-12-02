-- Fly GUI V3 Enhanced - Fixed Version
-- Автор: XNEO | Исправлено для работы

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Переменные
local nowe = false
local speeds = 1
local tpwalking = false
local noclip = false
local savedPosition = nil
local flyEnabled = false
local flyConnection = nil

-- Создание GUI
local main = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")

-- Настройка GUI
main.Name = "FlyGUIv3"
main.Parent = player:WaitForChild("PlayerGui")
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.ResetOnSpawn = false

-- Основной фрейм
Frame.Parent = main
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Frame.BorderColor3 = Color3.fromRGB(0, 150, 255)
Frame.BorderSizePixel = 2
Frame.Position = UDim2.new(0.05, 0, 0.3, 0)
Frame.Size = UDim2.new(0, 350, 0, 200)
Frame.Active = true
Frame.Draggable = true
Frame.ClipsDescendants = true

-- Функция создания кнопки
local function createButton(name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = Frame
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.SourceSansBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.AutoButtonColor = true
    
    -- Эффект при наведении
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 30, 255),
            math.min(color.G * 255 + 30, 255),
            math.min(color.B * 255 + 30, 255)
        ) / 255
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = color
    end)
    
    return button
end

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = Frame
title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 30)
title.Font = Enum.Font.SourceSansBold
title.Text = "✈️ FLY GUI V3 ENHANCED ✈️"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.TextSize = 16
title.TextWrapped = true

-- Создаем кнопки
local flyBtn = createButton("FlyButton", "🚀 FLY: OFF", UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(215, 50, 50))

local upBtn = createButton("UpButton", "🔼 UP", UDim2.new(0.55, 0, 0.2, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 180, 50))

local downBtn = createButton("DownButton", "🔽 DOWN", UDim2.new(0.05, 0, 0.4, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(200, 100, 50))

local speedDisplay = Instance.new("TextLabel")
speedDisplay.Name = "SpeedDisplay"
speedDisplay.Parent = Frame
speedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedDisplay.BorderSizePixel = 0
speedDisplay.Position = UDim2.new(0.55, 0, 0.4, 0)
speedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
speedDisplay.Font = Enum.Font.SourceSansBold
speedDisplay.Text = "SPEED: 1"
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.TextScaled = true
speedDisplay.TextSize = 14

local increaseBtn = createButton("IncreaseBtn", "+", UDim2.new(0.05, 0, 0.6, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(50, 150, 50))

local decreaseBtn = createButton("DecreaseBtn", "-", UDim2.new(0.3, 0, 0.6, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(180, 50, 50))

local noclipBtn = createButton("NoclipBtn", "🚫 NOCLIP: OFF", UDim2.new(0.55, 0, 0.6, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(140, 50, 200))

local savePosBtn = createButton("SavePosBtn", "💾 SAVE POS", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(255, 140, 0))

local teleportBtn = createButton("TeleportBtn", "📍 TELEPORT", UDim2.new(0.55, 0, 0.8, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(0, 140, 255))

-- Кнопки управления окном
local closeBtn = createButton("CloseBtn", "X", UDim2.new(0.94, 0, 0.02, 0), UDim2.new(0.05, 0, 0.15, 0), Color3.fromRGB(215, 50, 50))

local minBtn = createButton("MinBtn", "_", UDim2.new(0.88, 0, 0.02, 0), UDim2.new(0.05, 0, 0.15, 0), Color3.fromRGB(255, 165, 0))

-- Переменные для управления
local flyBodyGyro = nil
local flyBodyVelocity = nil
local upPressed = false
local downPressed = false

-- Функция включения/выключения полета
local function toggleFly()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        flyBtn.Text = "🚀 FLY: ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        -- Сохраняем контроль над персонажем
        humanoid.PlatformStand = true
        
        -- Создаем объекты для полета
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if not rootPart then return end
        
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyVelocity = Instance.new("BodyVelocity")
        
        flyBodyGyro.Parent = rootPart
        flyBodyVelocity.Parent = rootPart
        
        flyBodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        flyBodyGyro.P = 100000
        flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        
        flyConnection = RunService.Heartbeat:Connect(function(delta)
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            local cam = workspace.CurrentCamera
            local root = character.HumanoidRootPart
            
            -- Получаем направление от камеры
            local forward = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = Vector3.new(0, 1, 0)
            
            local direction = Vector3.new(0, 0, 0)
            
            -- Определяем направление движения
            local moveDirection = humanoid.MoveDirection
            if moveDirection.Magnitude > 0 then
                direction = direction + (forward * moveDirection.Z * speeds) + (right * moveDirection.X * speeds)
            end
            
            -- Вертикальное движение
            if upPressed then
                direction = direction + (up * speeds)
            elseif downPressed then
                direction = direction - (up * speeds)
            end
            
            -- Применяем движение
            if direction.Magnitude > 0 then
                flyBodyVelocity.Velocity = direction * 50
                flyBodyGyro.CFrame = cam.CFrame
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        
    else
        flyBtn.Text = "🚀 FLY: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
        
        humanoid.PlatformStand = false
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        
        upPressed = false
        downPressed = false
    end
end

-- Обработчики кнопок
flyBtn.MouseButton1Click:Connect(toggleFly)

upBtn.MouseButton1Down:Connect(function()
    upPressed = true
end)

upBtn.MouseButton1Up:Connect(function()
    upPressed = false
end)

upBtn.MouseLeave:Connect(function()
    upPressed = false
end)

downBtn.MouseButton1Down:Connect(function()
    downPressed = true
end)

downBtn.MouseButton1Up:Connect(function()
    downPressed = false
end)

downBtn.MouseLeave:Connect(function()
    downPressed = false
end)

increaseBtn.MouseButton1Click:Connect(function()
    speeds = speeds + 1
    if speeds > 10 then speeds = 10 end
    speedDisplay.Text = "SPEED: " .. speeds
end)

decreaseBtn.MouseButton1Click:Connect(function()
    speeds = speeds - 1
    if speeds < 1 then speeds = 1 end
    speedDisplay.Text = "SPEED: " .. speeds
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclip = not noclip
    
    if noclip then
        noclipBtn.Text = "🚫 NOCLIP: ON"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
        
        -- Включаем ноклип
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        noclipBtn.Text = "🚫 NOCLIP: OFF"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 200)
        
        -- Выключаем ноклип
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)

savePosBtn.MouseButton1Click:Connect(function()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        savedPosition = rootPart.CFrame
        savePosBtn.Text = "✓ SAVED!"
        
        -- Возвращаем текст через 2 секунды
        delay(2, function()
            if savePosBtn then
                savePosBtn.Text = "💾 SAVE POS"
            end
        end)
    end
end)

teleportBtn.MouseButton1Click:Connect(function()
    if savedPosition then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = savedPosition
            teleportBtn.Text = "✓ TELEPORTED!"
            
            delay(2, function()
                if teleportBtn then
                    teleportBtn.Text = "📍 TELEPORT"
                end
            end)
        end
    else
        teleportBtn.Text = "NO POS SAVED!"
        
        delay(2, function()
            if teleportBtn then
                teleportBtn.Text = "📍 TELEPORT"
            end
        end)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    main:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
    minBtn.Text = Frame.Visible and "_" or "□"
end)

-- Уведомление
StarterGui:SetCore("SendNotification", {
    Title = "FLY GUI V3 LOADED",
    Text = "Fixed and working version!\nControls: Click buttons to use",
    Duration = 5
})

-- Горячие клавиши
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.E then
        -- Увеличить скорость
        speeds = speeds + 1
        if speeds > 10 then speeds = 10 end
        speedDisplay.Text = "SPEED: " .. speeds
    elseif input.KeyCode == Enum.KeyCode.Q then
        -- Уменьшить скорость
        speeds = speeds - 1
        if speeds < 1 then speeds = 1 end
        speedDisplay.Text = "SPEED: " .. speeds
    elseif input.KeyCode == Enum.KeyCode.T then
        -- Ноклип
        noclipBtn:MouseButton1Click()
    end
end)

-- Автоматический ноклип если включен
RunService.Stepped:Connect(function()
    if noclip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Очистка при смерти
character:WaitForChild("Humanoid").Died:Connect(function()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    
    flyEnabled = false
    upPressed = false
    downPressed = false
end)

-- Переподключение при респавне
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        flyEnabled = false
    end)
end)

print("✅ Fly GUI V3 Enhanced загружен и работает!")
