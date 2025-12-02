-- Ultimate GUI V6 - Walk Speed + Anti-Player Push
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
local TweenService = game:GetService("TweenService")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Переменные
local flyEnabled = false
local flightSpeed = 50
local walkSpeed = humanoid.WalkSpeed
local jumpPower = humanoid.JumpPower
local noclipEnabled = false
local invisibilityEnabled = false
local godModeEnabled = false
local antiPlayerEnabled = false
local savedPosition = nil

-- Переменные для систем
local flyBodyGyro, flyBodyVelocity, flyConnection
local noclipConnection, godModeConnection, antiPlayerConnection
local originalTransparency = {}
local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpPower

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V6"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
mainFrame.BorderSizePixel = 3
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Active = true
mainFrame.Draggable = true

-- Функция для создания элементов
local function createLabel(parent, text, position, size, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundColor3 = color or Color3.fromRGB(35, 35, 60)
    label.BackgroundTransparency = 0.7
    label.BorderSizePixel = 0
    label.Position = position
    label.Size = size
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
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
    button.TextWrapped = true
    
    -- Эффекты при наведении
    local originalColor = color
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor or Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 40, 255),
            math.min(color.B * 255 + 40, 255)
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
title.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 50)
title.Font = Enum.Font.SourceSansBold
title.Text = "⚡ ULTIMATE GUI V6 ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.TextScaled = true

-- Разделитель
local divider = Instance.new("Frame")
divider.Parent = mainFrame
divider.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0.05, 0, 0.12, 0)
divider.Size = UDim2.new(0.9, 0, 0, 3)

-- =============================================
-- СЕКЦИЯ ДВИЖЕНИЯ
-- =============================================
createLabel(mainFrame, "🏃 ДВИЖЕНИЕ", UDim2.new(0.05, 0, 0.15, 0), UDim2.new(0.9, 0, 0, 25))

-- Кнопка полета
local flyBtn = createButton(mainFrame, "✈️ ПОЛЕТ: ВЫКЛ", UDim2.new(0.05, 0, 0.2, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80))

-- Дисплей скорости полета
local speedDisplay = createLabel(mainFrame, "СКОРОСТЬ ПОЛЕТА: 50", UDim2.new(0.52, 0, 0.2, 0), UDim2.new(0.43, 0, 0, 40))
speedDisplay.BackgroundColor3 = Color3.fromRGB(45, 45, 75)
speedDisplay.TextScaled = true
speedDisplay.TextXAlignment = Enum.TextXAlignment.Center

-- Кнопки скорости полета
local flySpeedUpBtn = createButton(mainFrame, "▲ +", UDim2.new(0.05, 0, 0.27, 0), 
    UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(60, 190, 60), Color3.fromRGB(80, 210, 80))

local flySpeedDownBtn = createButton(mainFrame, "▼ -", UDim2.new(0.27, 0, 0.27, 0), 
    UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(190, 60, 60), Color3.fromRGB(210, 80, 80))

-- Дисплей скорости ходьбы
local walkSpeedDisplay = createLabel(mainFrame, "СКОРОСТЬ ХОДЬБЫ: " .. humanoid.WalkSpeed, 
    UDim2.new(0.52, 0, 0.27, 0), UDim2.new(0.43, 0, 0, 30))
walkSpeedDisplay.BackgroundColor3 = Color3.fromRGB(45, 45, 75)
walkSpeedDisplay.TextScaled = true
walkSpeedDisplay.TextXAlignment = Enum.TextXAlignment.Center

-- Кнопки скорости ходьбы
local walkSpeedUpBtn = createButton(mainFrame, "▲ +", UDim2.new(0.05, 0, 0.34, 0), 
    UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(80, 180, 80), Color3.fromRGB(100, 200, 100))

local walkSpeedDownBtn = createButton(mainFrame, "▼ -", UDim2.new(0.27, 0, 0.34, 0), 
    UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(180, 80, 80), Color3.fromRGB(200, 100, 100))

-- =============================================
-- СЕКЦИЯ СПОСОБНОСТЕЙ
-- =============================================
createLabel(mainFrame, "🛡️ СПОСОБНОСТИ", UDim2.new(0.05, 0, 0.42, 0), UDim2.new(0.9, 0, 0, 25))

-- Кнопка ноклипа
local noclipBtn = createButton(mainFrame, "🚫 НОКЛИП: ВЫКЛ", UDim2.new(0.05, 0, 0.47, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(170, 70, 220), Color3.fromRGB(190, 90, 240))

-- Кнопка невидимости
local invisibilityBtn = createButton(mainFrame, "👻 НЕВИДИМОСТЬ: ВЫКЛ", UDim2.new(0.52, 0, 0.47, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(130, 130, 130), Color3.fromRGB(160, 160, 160))

-- Кнопка God Mode
local godModeBtn = createButton(mainFrame, "💪 GOD MODE: ВЫКЛ", UDim2.new(0.05, 0, 0.56, 0), 
    UDim2.new(0.9, 0, 0, 45), Color3.fromRGB(255, 130, 0), Color3.fromRGB(255, 170, 50))

-- Кнопка анти-игрок (отталкивание)
local antiPlayerBtn = createButton(mainFrame, "⚡ ОТТАЛКИВАНИЕ ИГРОКОВ: ВЫКЛ", UDim2.new(0.05, 0, 0.65, 0), 
    UDim2.new(0.9, 0, 0, 45), Color3.fromRGB(255, 50, 100), Color3.fromRGB(255, 80, 130))

-- =============================================
-- СЕКЦИЯ ПОЗИЦИИ
-- =============================================
createLabel(mainFrame, "📍 УПРАВЛЕНИЕ ПОЗИЦИЕЙ", UDim2.new(0.05, 0, 0.74, 0), UDim2.new(0.9, 0, 0, 25))

local savePosBtn = createButton(mainFrame, "💾 СОХРАНИТЬ ПОЗИЦИЮ", UDim2.new(0.05, 0, 0.79, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(255, 185, 0), Color3.fromRGB(255, 205, 40))

local loadPosBtn = createButton(mainFrame, "🚀 ТЕЛЕПОРТ НА ПОЗИЦИЮ", UDim2.new(0.52, 0, 0.79, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(0, 160, 255), Color3.fromRGB(40, 190, 255))

-- =============================================
-- КНОПКИ УПРАВЛЕНИЯ ОКНОМ
-- =============================================
local closeBtn = createButton(mainFrame, "✕", UDim2.new(0.94, -30, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50))

local minBtn = createButton(mainFrame, "−", UDim2.new(0.94, -65, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(255, 185, 0), Color3.fromRGB(255, 205, 40))

-- =============================================
-- СЕКЦИЯ ИНФОРМАЦИИ
-- =============================================
local infoLabel = createLabel(mainFrame, "ℹ️ УПРАВЛЕНИЕ: F-Полет | T-Ноклип | G-God Mode | R-Отталкивание", 
    UDim2.new(0.05, 0, 0.9, 0), UDim2.new(0.9, 0, 0, 25))
infoLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
infoLabel.TextScaled = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center

-- =============================================
-- 1. ФУНКЦИЯ РЕГУЛИРОВКИ СКОРОСТИ ХОДЬБЫ/БЕГА
-- =============================================
local function updateWalkSpeed(value)
    if humanoid then
        walkSpeed = math.clamp(value, 16, 500) -- Ограничиваем от 16 до 500
        humanoid.WalkSpeed = walkSpeed
        walkSpeedDisplay.Text = "СКОРОСТЬ ХОДЬБЫ: " .. walkSpeed
        
        -- Визуальная обратная связь
        if walkSpeed >= 100 then
            walkSpeedDisplay.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        elseif walkSpeed >= 50 then
            walkSpeedDisplay.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
        else
            walkSpeedDisplay.BackgroundColor3 = Color3.fromRGB(45, 45, 75)
        end
    end
end

-- Обработчики кнопок скорости ходьбы
walkSpeedUpBtn.MouseButton1Click:Connect(function()
    updateWalkSpeed(walkSpeed + 10)
end)

walkSpeedDownBtn.MouseButton1Click:Connect(function()
    updateWalkSpeed(walkSpeed - 10)
end)

-- Обработчик зажатия кнопок (для быстрой регулировки)
local speedAdjusting = false
walkSpeedUpBtn.MouseButton1Down:Connect(function()
    speedAdjusting = true
    while speedAdjusting and wait(0.1) do
        updateWalkSpeed(walkSpeed + 5)
    end
end)

walkSpeedUpBtn.MouseButton1Up:Connect(function()
    speedAdjusting = false
end)

walkSpeedDownBtn.MouseButton1Down:Connect(function()
    speedAdjusting = true
    while speedAdjusting and wait(0.1) do
        updateWalkSpeed(walkSpeed - 5)
    end
end)

walkSpeedDownBtn.MouseButton1Up:Connect(function()
    speedAdjusting = false
end)

-- =============================================
-- 2. ФУНКЦИЯ ОТТАЛКИВАНИЯ ИГРОКОВ
-- =============================================
local function toggleAntiPlayer()
    antiPlayerEnabled = not antiPlayerEnabled
    
    if antiPlayerEnabled then
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ ИГРОКОВ: ВКЛ"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 130)
        
        -- Создаем невидимый хитбокс
        local hitbox = Instance.new("Part")
        hitbox.Name = "AntiPlayerHitbox"
        hitbox.Size = Vector3.new(15, 15, 15) -- Большой радиус
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = false
        hitbox.Parent = character
        
        -- Привязываем хитбокс к персонажу
        local weld = Instance.new("Weld")
        weld.Part0 = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        weld.Part1 = hitbox
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = hitbox
        
        antiPlayerConnection = RunService.Heartbeat:Connect(function()
            if not antiPlayerEnabled or not character then return end
            
            local myPosition = character:FindFirstChild("HumanoidRootPart")
            if not myPosition then return end
            
            -- Проверяем всех игроков
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    
                    if otherRoot then
                        local distance = (myPosition.Position - otherRoot.Position).Magnitude
                        
                        -- Если игрок приблизился на 10 studs
                        if distance < 10 then
                            -- Вычисляем направление отталкивания
                            local direction = (otherRoot.Position - myPosition.Position).Unit
                            local force = direction * 100 + Vector3.new(0, 50, 0) -- Отталкивание вверх и в сторону
                            
                            -- Применяем силу
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = force
                            bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                            bodyVelocity.P = 10000
                            bodyVelocity.Parent = otherRoot
                            
                            -- Удаляем через короткое время
                            game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
                            
                            -- Визуальный эффект
                            local explosion = Instance.new("Explosion")
                            explosion.Position = myPosition.Position
                            explosion.BlastPressure = 0
                            explosion.BlastRadius = 5
                            explosion.ExplosionType = Enum.ExplosionType.NoCraters
                            explosion.DestroyJointRadiusPercent = 0
                            explosion.Parent = Workspace
                            
                            game:GetService("Debris"):AddItem(explosion, 1)
                            
                            -- Звуковой эффект (опционально)
                            if character:FindFirstChild("HumanoidRootPart") then
                                local sound = Instance.new("Sound")
                                sound.SoundId = "rbxassetid://911846833" -- Звук толчка
                                sound.Volume = 0.5
                                sound.Parent = character.HumanoidRootPart
                                sound:Play()
                                game:GetService("Debris"):AddItem(sound, 2)
                            end
                        end
                    end
                end
            end
        end)
        
        print("✅ СИСТЕМА ОТТАЛКИВАНИЯ АКТИВИРОВАНА")
        print("📌 Игроки будут отбрасываться при приближении")
        
    else
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ ИГРОКОВ: ВЫКЛ"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
        
        -- Отключаем соединение
        if antiPlayerConnection then
            antiPlayerConnection:Disconnect()
            antiPlayerConnection = nil
        end
        
        -- Удаляем хитбокс
        local hitbox = character:FindFirstChild("AntiPlayerHitbox")
        if hitbox then
            hitbox:Destroy()
        end
        
        print("❌ СИСТЕМА ОТТАЛКИВАНИЯ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 3. ФУНКЦИЯ ПОЛЕТА (с измененной скоростью)
-- =============================================
local function toggleFly()
    if flyEnabled then
        -- Выключаем полет
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
        
        flyBtn.Text = "✈️ ПОЛЕТ: ВЫКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        
    else
        -- Включаем полет
        flyEnabled = true
        
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
            if not flyEnabled or not character then return end
            
            local cam = workspace.CurrentCamera
            local direction = Vector3.new(0, 0, 0)
            
            -- Управление WASD + Space/Shift
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
        
        flyBtn.Text = "✈️ ПОЛЕТ: ВКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 210, 60)
    end
end

-- Обработчики кнопок скорости полета
flySpeedUpBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.min(flightSpeed + 10, 200)
    speedDisplay.Text = "СКОРОСТЬ ПОЛЕТА: " .. flightSpeed
end)

flySpeedDownBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.max(flightSpeed - 10, 10)
    speedDisplay.Text = "СКОРОСТЬ ПОЛЕТА: " .. flightSpeed
end)

-- =============================================
-- 4. ФУНКЦИЯ GOD MODE (бесконечное здоровье)
-- =============================================
local function toggleGodMode()
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💪 GOD MODE: ВКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
        
        -- Сохраняем оригинальное здоровье
        local originalHealth = humanoid.Health
        
        -- Устанавливаем бесконечное здоровье
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
        
        -- Запускаем восстановление здоровья
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not humanoid then return end
            
            -- Мгновенное восстановление
            humanoid.Health = humanoid.MaxHealth
            
            -- Защита от смерти
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        
        print("✅ GOD MODE АКТИВИРОВАН")
        
    else
        godModeBtn.Text = "💪 GOD MODE: ВЫКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
        
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        -- Возвращаем нормальное здоровье
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = math.min(humanoid.Health, 100)
        end
        
        print("❌ GOD MODE ДЕАКТИВИРОВАН")
    end
end

-- =============================================
-- 5. ФУНКЦИЯ НЕВИДИМОСТИ
-- =============================================
local function toggleInvisibility()
    invisibilityEnabled = not invisibilityEnabled
    
    if invisibilityEnabled then
        invisibilityBtn.Text = "👻 НЕВИДИМОСТЬ: ВКЛ"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
        
        -- Сохраняем и скрываем все части
        originalTransparency = {}
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalTransparency[part] = part.Transparency
                part.Transparency = 1
            elseif part:IsA("Decal") then
                originalTransparency[part] = part.Transparency
                part.Transparency = 1
            end
        end
        
        print("✅ НЕВИДИМОСТЬ АКТИВИРОВАНА")
        
    else
        invisibilityBtn.Text = "👻 НЕВИДИМОСТЬ: ВЫКЛ"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 130)
        
        -- Восстанавливаем видимость
        for part, transparency in pairs(originalTransparency) do
            if part and part.Parent then
                part.Transparency = transparency
            end
        end
        
        originalTransparency = {}
        print("❌ НЕВИДИМОСТЬ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 6. ФУНКЦИЯ НОКЛИПА
-- =============================================
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        noclipBtn.Text = "🚫 НОКЛИП: ВКЛ"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(190, 90, 240)
        
        -- Включаем ноклип
        RunService.Stepped:Connect(function()
            if noclipEnabled and character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        print("✅ НОКЛИП АКТИВИРОВАН")
        
    else
        noclipBtn.Text = "🚫 НОКЛИП: ВЫКЛ"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(170, 70, 220)
        
        -- Выключаем ноклип
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        
        print("❌ НОКЛИП ДЕАКТИВИРОВАН")
    end
end

-- =============================================
-- 7. ОБРАБОТЧИКИ КНОПОК
-- =============================================
flyBtn.MouseButton1Click:Connect(toggleFly)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)
invisibilityBtn.MouseButton1Click:Connect(toggleInvisibility)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)
antiPlayerBtn.MouseButton1Click:Connect(toggleAntiPlayer)

savePosBtn.MouseButton1Click:Connect(function()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        savedPosition = rootPart.CFrame
        savePosBtn.Text = "✓ СОХРАНЕНО!"
        delay(2, function() savePosBtn.Text = "💾 СОХРАНИТЬ ПОЗИЦИЮ" end)
    end
end)

loadPosBtn.MouseButton1Click:Connect(function()
    if savedPosition then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = savedPosition
            loadPosBtn.Text = "✓ ТЕЛЕПОРТИРОВАН!"
            delay(2, function() loadPosBtn.Text = "🚀 ТЕЛЕПОРТ НА ПОЗИЦИЮ" end)
        end
    else
        loadPosBtn.Text = "❌ НЕТ ПОЗИЦИИ!"
        delay(2, function() loadPosBtn.Text = "🚀 ТЕЛЕПОРТ НА ПОЗИЦИЮ" end)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    -- Отключаем все системы
    if flyEnabled then toggleFly() end
    if godModeEnabled then toggleGodMode() end
    if antiPlayerEnabled then toggleAntiPlayer() end
    
    -- Восстанавливаем скорость ходьбы
    if humanoid then
        humanoid.WalkSpeed = originalWalkSpeed
    end
    
    screenGui:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minBtn.Text = mainFrame.Visible and "−" or "+"
end)

-- =============================================
-- 8. ГОРЯЧИЕ КЛАВИШИ
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
        toggleInvisibility()
    elseif input.KeyCode == Enum.KeyCode.R then
        toggleAntiPlayer()
    elseif input.KeyCode == Enum.KeyCode.U then
        -- Увеличить скорость ходьбы
        updateWalkSpeed(walkSpeed + 20)
    elseif input.KeyCode == Enum.KeyCode.J then
        -- Уменьшить скорость ходьбы
        updateWalkSpeed(walkSpeed - 20)
    elseif input.KeyCode == Enum.KeyCode.Y then
        -- Увеличить скорость полета
        flightSpeed = math.min(flightSpeed + 20, 200)
        speedDisplay.Text = "СКОРОСТЬ ПОЛЕТА: " .. flightSpeed
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Уменьшить скорость полета
        flightSpeed = math.max(flightSpeed - 20, 10)
        speedDisplay.Text = "СКОРОСТЬ ПОЛЕТА: " .. flightSpeed
    end
end)

-- =============================================
-- 9. АВТООБНОВЛЕНИЕ ПРИ РЕСПАВНЕ
-- =============================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    
    -- Обновляем скорость ходьбы на новом персонаже
    updateWalkSpeed(walkSpeed)
    
    -- Переподключаем активные функции
    wait(0.5)
    if godModeEnabled then
        toggleGodMode()
        toggleGodMode()
    end
    if antiPlayerEnabled then
        toggleAntiPlayer()
        toggleAntiPlayer()
    end
    if invisibilityEnabled then
        toggleInvisibility()
        toggleInvisibility()
    end
    if noclipEnabled then
        toggleNoclip()
        toggleNoclip()
    end
end)

-- =============================================
-- 10. ЗАГРУЗОЧНОЕ УВЕДОМЛЕНИЕ
-- =============================================
StarterGui:SetCore("SendNotification", {
    Title = "⚡ ULTIMATE GUI V6",
    Text = "Загружен!\nR - Отталкивание игроков\nU/J - Скорость ходьбы",
    Duration = 6
})

print("=" .. string.rep("=", 60))
print("⚡ ULTIMATE GUI V6 УСПЕШНО ЗАГРУЖЕН!")
print("=" .. string.rep("=", 60))
print("🏃 РЕГУЛИРОВКА СКОРОСТИ ХОДЬБЫ: " .. walkSpeed)
print("⚡ ОТТАЛКИВАНИЕ ИГРОКОВ: R (приближение = отбрасывание)")
print("✈️ ПОЛЕТ: F | 🚫 НОКЛИП: T | 💪 GOD MODE: G | 👻 НЕВИДИМОСТЬ: I")
print("=" .. string.rep("=", 60))
print("📊 ГОРЯЧИЕ КЛАВИШИ:")
print("   U - Увеличить скорость ходьбы")
print("   J - Уменьшить скорость ходьбы")
print("   Y - Увеличить скорость полета")
print("   H - Уменьшить скорость полета")
print("=" .. string.rep("=", 60))
