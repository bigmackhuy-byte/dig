-- Ultimate GUI V5 - True Invisibility & God Mode
-- Автор: Modified by User

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Переменные
local flyEnabled = false
local flightSpeed = 50
local noclipEnabled = false
local invisibilityEnabled = false
local godModeEnabled = false
local savedPosition = nil

-- Переменные для невидимости
local originalCFrame = nil
local fakeCharacter = nil
local invisibilityConnection = nil
local remoteFaker = nil

-- Переменные для God Mode
local godModeConnection = nil
local healthCheckConnection = nil
local originalMaxHealth = 100

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V5"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderColor3 = Color3.fromRGB(0, 180, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.Size = UDim2.new(0, 380, 0, 420)
mainFrame.Active = true
mainFrame.Draggable = true

-- Функция для создания элементов
local function createLabel(parent, text, position, size, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundColor3 = color or Color3.fromRGB(30, 30, 50)
    label.BackgroundTransparency = color and 0 or 0.7
    label.BorderSizePixel = 0
    label.Position = position
    label.Size = size
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function createButton(parent, text, position, size, color, hoverColor)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.SourceSansBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    
    -- Эффекты при наведении
    local originalColor = color
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor or Color3.fromRGB(
            math.min(color.R * 255 + 50, 255),
            math.min(color.G * 255 + 50, 255),
            math.min(color.B * 255 + 50, 255)
        ) / 255
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
    
    return button
end

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 45)
title.Font = Enum.Font.SourceSansBold
title.Text = "⚡ ULTIMATE GUI V5 ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.TextScaled = true

-- Разделитель
local divider = Instance.new("Frame")
divider.Parent = mainFrame
divider.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0.05, 0, 0.12, 0)
divider.Size = UDim2.new(0.9, 0, 0, 2)

-- Секция полета
createLabel(mainFrame, "✈️ FLIGHT SYSTEM", UDim2.new(0.05, 0, 0.15, 0), UDim2.new(0.9, 0, 0, 25))

local flyBtn = createButton(mainFrame, "FLY: OFF", UDim2.new(0.05, 0, 0.22, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80))

local speedDisplay = createLabel(mainFrame, "SPEED: 50", UDim2.new(0.52, 0, 0.22, 0), UDim2.new(0.43, 0, 0, 40))
speedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
speedDisplay.TextScaled = true
speedDisplay.TextXAlignment = Enum.TextXAlignment.Center

local speedUpBtn = createButton(mainFrame, "▲ SPEED +", UDim2.new(0.05, 0, 0.32, 0), 
    UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(60, 190, 60), Color3.fromRGB(80, 210, 80))

local speedDownBtn = createButton(mainFrame, "▼ SPEED -", UDim2.new(0.52, 0, 0.32, 0), 
    UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(190, 60, 60), Color3.fromRGB(210, 80, 80))

-- Секция способностей
createLabel(mainFrame, "🛡️ POWERFUL ABILITIES", UDim2.new(0.05, 0, 0.43, 0), UDim2.new(0.9, 0, 0, 25))

local noclipBtn = createButton(mainFrame, "🚫 NOCLIP: OFF", UDim2.new(0.05, 0, 0.5, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(160, 60, 210), Color3.fromRGB(190, 80, 230))

-- Кнопка НЕВИДИМОСТИ (Истинная для других игроков)
local invisibilityBtn = createButton(mainFrame, "👻 TRUE INVIS: OFF", UDim2.new(0.52, 0, 0.5, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(120, 120, 120), Color3.fromRGB(170, 170, 170))

-- Кнопка GOD MODE (Бесконечное восстановление здоровья)
local godModeBtn = createButton(mainFrame, "💪 INFINITE GOD MODE", UDim2.new(0.05, 0, 0.6, 0), 
    UDim2.new(0.9, 0, 0, 45), Color3.fromRGB(255, 120, 0), Color3.fromRGB(255, 160, 40))

-- Секция позиции
createLabel(mainFrame, "📍 POSITION CONTROL", UDim2.new(0.05, 0, 0.73, 0), UDim2.new(0.9, 0, 0, 25))

local savePosBtn = createButton(mainFrame, "💾 SAVE POSITION", UDim2.new(0.05, 0, 0.8, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(255, 175, 0), Color3.fromRGB(255, 195, 40))

local loadPosBtn = createButton(mainFrame, "🚀 LOAD POSITION", UDim2.new(0.52, 0, 0.8, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(0, 150, 255), Color3.fromRGB(40, 180, 255))

-- Кнопки управления окном
local closeBtn = createButton(mainFrame, "✕", UDim2.new(0.93, -30, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(220, 20, 20), Color3.fromRGB(240, 40, 40))

local minBtn = createButton(mainFrame, "−", UDim2.new(0.93, -65, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(255, 175, 0), Color3.fromRGB(255, 195, 40))

-- Секция информации
local infoLabel = createLabel(mainFrame, "ℹ️ F: Fly | T: Noclip | G: God Mode | I: True Invis", 
    UDim2.new(0.05, 0, 0.92, 0), UDim2.new(0.9, 0, 0, 25))
infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
infoLabel.TextScaled = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center

-- =============================================
-- 1. ФУНКЦИЯ GOD MODE (БЕСКОНЕЧНОЕ ВОССТАНОВЛЕНИЕ)
-- =============================================
local function toggleGodMode()
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💪 GOD MODE: ACTIVE"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 40)
        
        -- Сохраняем оригинальные значения
        originalMaxHealth = humanoid.MaxHealth
        
        -- Устанавливаем бесконечное здоровье
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
        
        -- Отключаем получение урона
        humanoid.BreakJointsOnDeath = false
        
        -- Запускаем бесконечное восстановление здоровья
        godModeConnection = RunService.Heartbeat:Connect(function(delta)
            if not godModeEnabled or not humanoid or humanoid.Health <= 0 then return end
            
            -- Мгновенное восстановление здоровья
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            
            -- Предотвращение смерти
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        -- Дополнительная защита: проверка каждые 0.1 секунды
        healthCheckConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled then return end
            
            -- Если здоровье меньше 100% - мгновенно восстанавливаем
            if humanoid and humanoid.Health < humanoid.MaxHealth * 0.99 then
                humanoid.Health = humanoid.MaxHealth
            end
            
            -- Предотвращаем любые попытки убить персонажа
            if humanoid and humanoid.Health <= 0 then
                humanoid.Health = humanoid.MaxHealth
                if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
        
        -- Перехватываем повреждения
        local function preventDamage()
            if humanoid then
                humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                    if godModeEnabled and humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end)
            end
        end
        
        preventDamage()
        
        print("✅ GOD MODE АКТИВИРОВАН: Бесконечное здоровье + мгновенное восстановление")
        
    else
        godModeBtn.Text = "💪 INFINITE GOD MODE"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
        
        -- Отключаем соединения
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        if healthCheckConnection then
            healthCheckConnection:Disconnect()
            healthCheckConnection = nil
        end
        
        -- Возвращаем оригинальные значения
        if humanoid then
            humanoid.MaxHealth = originalMaxHealth
            humanoid.Health = math.min(humanoid.Health, originalMaxHealth)
            humanoid.BreakJointsOnDeath = true
        end
        
        print("❌ GOD MODE ДЕАКТИВИРОВАН")
    end
end

-- =============================================
-- 2. ФУНКЦИЯ ИСТИННОЙ НЕВИДИМОСТИ (для других игроков)
-- =============================================
local function toggleTrueInvisibility()
    invisibilityEnabled = not invisibilityEnabled
    
    if invisibilityEnabled then
        invisibilityBtn.Text = "👻 TRUE INVIS: ON"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        
        -- Метод 1: Телепортируем реального персонажа под карту
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if rootPart then
            -- Сохраняем оригинальную позицию
            originalCFrame = rootPart.CFrame
            
            -- Создаем копию персонажа для других игроков
            fakeCharacter = character:Clone()
            
            -- Устанавливаем копию на оригинальную позицию
            local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart") or fakeCharacter:FindFirstChild("Torso")
            if fakeRoot then
                fakeRoot.CFrame = originalCFrame
            end
            
            -- Делаем копию неактивной для нашего клиента
            for _, part in pairs(fakeCharacter:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
            
            -- Помещаем копию в Workspace
            fakeCharacter.Parent = Workspace
            fakeCharacter.Name = "Fake_" .. player.Name
            
            -- Телепортируем реального персонажа глубоко под землю
            local undergroundCFrame = CFrame.new(0, -10000, 0)
            rootPart.CFrame = undergroundCFrame
            
            -- Скрываем реального персонажа
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
            
            -- Метод 2: Синхронизируем движения
            invisibilityConnection = RunService.Heartbeat:Connect(function()
                if not character or not fakeCharacter then return end
                
                -- Обновляем позицию фейкового персонажа
                local realRoot = character:FindFirstChild("HumanoidRootPart")
                local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
                
                if realRoot and fakeRoot then
                    -- Копируем движения
                    fakeRoot.CFrame = CFrame.new(realRoot.Position.X, originalCFrame.Y, realRoot.Position.Z)
                    
                    -- Копируем анимации
                    local realHumanoid = character:FindFirstChild("Humanoid")
                    local fakeHumanoid = fakeCharacter:FindFirstChild("Humanoid")
                    
                    if realHumanoid and fakeHumanoid then
                        fakeHumanoid:Move(realHumanoid.MoveDirection)
                    end
                end
            end)
            
            print("✅ ИСТИННАЯ НЕВИДИМОСТЬ АКТИВИРОВАНА")
            print("📌 Реальный персонаж: под землей")
            print("📌 Другие игроки видят: копию на месте")
        end
        
    else
        invisibilityBtn.Text = "👻 TRUE INVIS: OFF"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
        
        -- Отключаем соединение
        if invisibilityConnection then
            invisibilityConnection:Disconnect()
            invisibilityConnection = nil
        end
        
        -- Возвращаем реального персонажа на место
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if rootPart and originalCFrame then
            rootPart.CFrame = originalCFrame
        end
        
        -- Восстанавливаем видимость
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
        
        -- Удаляем фейкового персонажа
        if fakeCharacter then
            fakeCharacter:Destroy()
            fakeCharacter = nil
        end
        
        print("❌ ИСТИННАЯ НЕВИДИМОСТЬ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 3. ФУНКЦИЯ ПОЛЕТА (остается без изменений)
-- =============================================
local flyBodyGyro, flyBodyVelocity, flyConnection

local function startFlying()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyVelocity = Instance.new("BodyVelocity")
    
    flyBodyGyro.Parent = rootPart
    flyBodyVelocity.Parent = rootPart
    
    flyBodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
    flyBodyGyro.P = 10000
    flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    
    humanoid.PlatformStand = true
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        
        local cam = workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * flightSpeed
            flyBodyVelocity.Velocity = direction
            flyBodyGyro.CFrame = cam.CFrame
        else
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
    
    flyBtn.Text = "FLY: ON"
    flyBtn.BackgroundColor3 = Color3.fromRGB(60, 210, 60)
    flyEnabled = true
end

local function stopFlying()
    flyEnabled = false
    
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
    
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    flyBtn.Text = "FLY: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end

local function toggleFly()
    if flyEnabled then
        stopFlying()
    else
        startFlying()
    end
end

-- =============================================
-- 4. ФУНКЦИЯ НОКЛИПА
-- =============================================
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        noclipBtn.Text = "🚫 NOCLIP: ON"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(190, 80, 230)
        
        RunService.Stepped:Connect(function()
            if noclipEnabled and character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        noclipBtn.Text = "🚫 NOCLIP: OFF"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 210)
        
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- =============================================
-- 5. ОБРАБОТЧИКИ КНОПОК
-- =============================================
flyBtn.MouseButton1Click:Connect(toggleFly)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)
invisibilityBtn.MouseButton1Click:Connect(toggleTrueInvisibility)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)

speedUpBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.min(flightSpeed + 10, 200)
    speedDisplay.Text = "SPEED: " .. flightSpeed
end)

speedDownBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.max(flightSpeed - 10, 10)
    speedDisplay.Text = "SPEED: " .. flightSpeed
end)

savePosBtn.MouseButton1Click:Connect(function()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        savedPosition = rootPart.CFrame
        savePosBtn.Text = "✓ SAVED!"
        delay(2, function() savePosBtn.Text = "💾 SAVE POSITION" end)
    end
end)

loadPosBtn.MouseButton1Click:Connect(function()
    if savedPosition then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = savedPosition
            loadPosBtn.Text = "✓ TELEPORTED!"
            delay(2, function() loadPosBtn.Text = "🚀 LOAD POSITION" end)
        end
    else
        loadPosBtn.Text = "❌ NO POS!"
        delay(2, function() loadPosBtn.Text = "🚀 LOAD POSITION" end)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if flyEnabled then stopFlying() end
    if godModeEnabled then toggleGodMode() end
    if invisibilityEnabled then toggleTrueInvisibility() end
    screenGui:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minBtn.Text = mainFrame.Visible and "−" or "+"
end)

-- =============================================
-- 6. ГОРЯЧИЕ КЛАВИШИ
-- =============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.T then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleGodMode()
    elseif input.KeyCode == Enum.KeyCode.I then
        toggleTrueInvisibility()
    elseif input.KeyCode == Enum.KeyCode.E then
        flightSpeed = math.min(flightSpeed + 10, 200)
        speedDisplay.Text = "SPEED: " .. flightSpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        flightSpeed = math.max(flightSpeed - 10, 10)
        speedDisplay.Text = "SPEED: " .. flightSpeed
    end
end)

-- =============================================
-- 7. АВТООБНОВЛЕНИЕ ПРИ РЕСПАВНЕ
-- =============================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    
    -- Переподключаем функции если они были активны
    if godModeEnabled then
        wait(0.5)
        toggleGodMode()
        toggleGodMode()
    end
    
    if invisibilityEnabled then
        wait(0.5)
        toggleTrueInvisibility()
        toggleTrueInvisibility()
    end
end)

-- =============================================
-- 8. ЗАГРУЗОЧНОЕ УВЕДОМЛЕНИЕ
-- =============================================
StarterGui:SetCore("SendNotification", {
    Title = "⚡ ULTIMATE GUI V5",
    Text = "Загружен!\nG - Бесконечное здоровье\nI - Истинная невидимость",
    Duration = 6
})

print("=" .. string.rep("=", 60))
print("⚡ ULTIMATE GUI V5 УСПЕШНО ЗАГРУЖЕН!")
print("=" .. string.rep("=", 60))
print("💪 GOD MODE: G - Бесконечное здоровье + мгновенное восстановление")
print("👻 ИСТИННАЯ НЕВИДИМОСТЬ: I - Другие игроки не видят вас")
print("✈️ ПОЛЕТ: F - Полная свобода передвижения")
print("🚫 НОКЛИП: T - Прохождение сквозь стены")
print("=" .. string.rep("=", 60))
print("🔧 Реальный персонаж скрыт под землей")
print("🔧 Другие игроки видят копию на вашем месте")
print("🔧 Здоровье восстанавливается мгновенно")
print("=" .. string.rep("=", 60))
