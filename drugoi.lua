-- Fly GUI V4 - Fully Working Version
-- Автор: XNEO | Исправлено для корректной работы

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
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Переменные
local flyEnabled = false
local flySpeed = 50
local displaySpeed = 1
local noclipEnabled = false
local savedPosition = nil
local flying = false
local upPressed = false
local downPressed = false

-- Создание GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")

-- Настройка GUI
ScreenGui.Name = "FlyGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

-- Функция создания кнопки
local function CreateButton(name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = MainFrame
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.SourceSansBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.AutoButtonColor = true
    button.TextScaled = true
    
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
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "✈️ FLY GUI V4 ✈️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 16

-- Создание кнопок
local FlyButton = CreateButton("FlyButton", "🚀 FLY: OFF", UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(215, 50, 50))

local UpButton = CreateButton("UpButton", "🔼 UP", UDim2.new(0.55, 0, 0.2, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 180, 50))

local DownButton = CreateButton("DownButton", "🔽 DOWN", UDim2.new(0.05, 0, 0.4, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(200, 100, 50))

local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Name = "SpeedDisplay"
SpeedDisplay.Parent = MainFrame
SpeedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SpeedDisplay.BorderSizePixel = 0
SpeedDisplay.Position = UDim2.new(0.55, 0, 0.4, 0)
SpeedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
SpeedDisplay.Font = Enum.Font.SourceSansBold
SpeedDisplay.Text = "SPEED: 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDisplay.TextScaled = true

local IncreaseButton = CreateButton("IncreaseBtn", "+", UDim2.new(0.05, 0, 0.6, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(50, 150, 50))

local DecreaseButton = CreateButton("DecreaseBtn", "-", UDim2.new(0.3, 0, 0.6, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(180, 50, 50))

local NoclipButton = CreateButton("NoclipBtn", "🚫 NOCLIP: OFF", UDim2.new(0.55, 0, 0.6, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(140, 50, 200))

local SavePosButton = CreateButton("SavePosBtn", "💾 SAVE POS", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(255, 140, 0))

local TeleportButton = CreateButton("TeleportBtn", "📍 TELEPORT", UDim2.new(0.55, 0, 0.8, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(0, 140, 255))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "X", UDim2.new(0.94, 0, 0.02, 0), UDim2.new(0.05, 0, 0.15, 0), Color3.fromRGB(215, 50, 50))

local MinButton = CreateButton("MinBtn", "_", UDim2.new(0.88, 0, 0.02, 0), UDim2.new(0.05, 0, 0.15, 0), Color3.fromRGB(255, 165, 0))

-- Функции полета
local bodyGyro, bodyVelocity
local flyConnection

local function ToggleFly()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        FlyButton.Text = "🚀 FLY: ON"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        humanoid.PlatformStand = true
        
        -- Создаем объекты для полета
        bodyGyro = Instance.new("BodyGyro")
        bodyVelocity = Instance.new("BodyVelocity")
        
        bodyGyro.Parent = humanoidRootPart
        bodyVelocity.Parent = humanoidRootPart
        
        bodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        bodyGyro.P = 10000
        bodyGyro.D = 1000
        bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        -- Обработка полета
        flyConnection = RunService.Heartbeat:Connect(function()
            if not character or not character:FindFirstChild("HumanoidRootPart") or not flyEnabled then
                return
            end
            
            local camera = workspace.CurrentCamera
            local root = character.HumanoidRootPart
            
            -- Определяем направление движения
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            
            local direction = Vector3.new(0, 0, 0)
            
            -- Движение WASD
            local moveDirection = humanoid.MoveDirection
            if moveDirection.Magnitude > 0 then
                direction = direction + (forward * moveDirection.Z * flySpeed) + (right * moveDirection.X * flySpeed)
            end
            
            -- Вертикальное движение
            if upPressed then
                direction = direction + Vector3.new(0, flySpeed, 0)
            elseif downPressed then
                direction = direction - Vector3.new(0, flySpeed, 0)
            end
            
            -- Применяем движение
            if direction.Magnitude > 0 then
                bodyVelocity.Velocity = direction
                bodyGyro.CFrame = CFrame.new(root.Position, root.Position + forward)
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyGyro.CFrame = CFrame.new(root.Position, root.Position + forward)
            end
        end)
        
    else
        FlyButton.Text = "🚀 FLY: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
        
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

local function ToggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        NoclipButton.Text = "🚫 NOCLIP: ON"
        NoclipButton.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
    else
        NoclipButton.Text = "🚫 NOCLIP: OFF"
        NoclipButton.BackgroundColor3 = Color3.fromRGB(140, 50, 200)
        
        -- Восстанавливаем коллизии
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

NoclipButton.MouseButton1Click:Connect(ToggleNoclip)

SavePosButton.MouseButton1Click:Connect(function()
    if character and humanoidRootPart then
        savedPosition = humanoidRootPart.CFrame
        SavePosButton.Text = "✓ SAVED!"
        
        task.wait(2)
        if SavePosButton then
            SavePosButton.Text = "💾 SAVE POS"
        end
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if savedPosition and character and humanoidRootPart then
        humanoidRootPart.CFrame = savedPosition
        TeleportButton.Text = "✓ TELEPORTED!"
        
        task.wait(2)
        if TeleportButton then
            TeleportButton.Text = "📍 TELEPORT"
        end
    else
        TeleportButton.Text = "NO POS SAVED!"
        
        task.wait(2)
        if TeleportButton then
            TeleportButton.Text = "📍 TELEPORT"
        end
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinButton.Text = MainFrame.Visible and "_" or "□"
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
    elseif input.KeyCode == Enum.KeyCode.T then
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

-- Обработка смерти персонажа
local function OnCharacterDeath()
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
    
    flyEnabled = false
    FlyButton.Text = "🚀 FLY: OFF"
    FlyButton.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
    upPressed = false
    downPressed = false
end

humanoid.Died:Connect(OnCharacterDeath)

-- Обработка смены персонажа
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    
    humanoid.Died:Connect(OnCharacterDeath)
end)

-- Уведомление о загрузке
StarterGui:SetCore("SendNotification", {
    Title = "FLY GUI V4",
    Text = "Успешно загружен!\nF - полет, E/Q - скорость\nT - ноклип",
    Duration = 5,
    Icon = "rbxassetid://4483345998"
})

print("✅ Fly GUI V4 успешно загружен и работает!")
