-- Ultimate GUI V7 - Advanced Hacks
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
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- Переменные
local flyEnabled = false
local flightSpeed = 50
local walkSpeed = humanoid.WalkSpeed
local noclipEnabled = false
local invisibilityEnabled = false
local godModeEnabled = false
local antiPlayerEnabled = false
local teleportClickEnabled = false
local stealItemsEnabled = false
local savedPosition = nil
local hitboxSize = 10

-- Переменные для систем
local flyBodyGyro, flyBodyVelocity, flyConnection
local noclipConnection, godModeConnection, antiPlayerConnection
local teleportConnection, stealConnection
local originalTransparency = {}
local originalWalkSpeed = humanoid.WalkSpeed
local hiddenParts = {}
local fakeCharacter = nil
local undergroundCFrame = CFrame.new(0, -100000, 0) -- Глубже под землю

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V7"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
mainFrame.BorderColor3 = Color3.fromRGB(0, 220, 255)
mainFrame.BorderSizePixel = 3
mainFrame.Position = UDim2.new(0.03, 0, 0.15, 0)
mainFrame.Size = UDim2.new(0, 420, 0, 550)
mainFrame.Active = true
mainFrame.Draggable = true

-- Функция для создания элементов
local function createLabel(parent, text, position, size, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundColor3 = color or Color3.fromRGB(40, 40, 70)
    label.BackgroundTransparency = 0.3
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
    button.TextSize = 12
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
title.BackgroundColor3 = Color3.fromRGB(0, 160, 240)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 50)
title.Font = Enum.Font.SourceSansBold
title.Text = "🔥 ULTIMATE GUI V7 - ADVANCED 🔥"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.TextScaled = true

-- Разделитель
local divider = Instance.new("Frame")
divider.Parent = mainFrame
divider.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0.05, 0, 0.1, 0)
divider.Size = UDim2.new(0.9, 0, 0, 3)

-- =============================================
-- СЕКЦИЯ ДВИЖЕНИЯ
-- =============================================
createLabel(mainFrame, "✈️ СИСТЕМА ПОЛЕТА", UDim2.new(0.05, 0, 0.12, 0), UDim2.new(0.9, 0, 0, 25))

local flyBtn = createButton(mainFrame, "✈️ ПОЛЕТ: ВЫКЛ", UDim2.new(0.05, 0, 0.17, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80))

local speedDisplay = createLabel(mainFrame, "СКОРОСТЬ: 50", UDim2.new(0.52, 0, 0.17, 0), UDim2.new(0.43, 0, 0, 40))
speedDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
speedDisplay.TextScaled = true
speedDisplay.TextXAlignment = Enum.TextXAlignment.Center

-- =============================================
-- СЕКЦИЯ GOD MODE (ПОДЗЕМНЫЙ ХИТБОКС)
-- =============================================
createLabel(mainFrame, "💀 ADVANCED GOD MODE", UDim2.new(0.05, 0, 0.25, 0), UDim2.new(0.9, 0, 0, 25))

local godModeBtn = createButton(mainFrame, "💀 GOD MODE: ВЫКЛ\n(Хитбокс под землей)", UDim2.new(0.05, 0, 0.3, 0), 
    UDim2.new(0.9, 0, 0, 60), Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 120, 120))

local hitboxDisplay = createLabel(mainFrame, "📦 РАЗМЕР ХИТБОКСА: 10", UDim2.new(0.05, 0, 0.4, 0), UDim2.new(0.6, 0, 0, 35))
hitboxDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
hitboxDisplay.TextScaled = true

local hitboxUpBtn = createButton(mainFrame, "▲", UDim2.new(0.7, 0, 0.4, 0), 
    UDim2.new(0.1, 0, 0, 35), Color3.fromRGB(80, 200, 80), Color3.fromRGB(100, 220, 100))

local hitboxDownBtn = createButton(mainFrame, "▼", UDim2.new(0.82, 0, 0.4, 0), 
    UDim2.new(0.1, 0, 0, 35), Color3.fromRGB(200, 80, 80), Color3.fromRGB(220, 100, 100))

-- =============================================
-- СЕКЦИЯ ОТТАЛКИВАНИЯ ИГРОКОВ
-- =============================================
createLabel(mainFrame, "⚡ СИСТЕМА ОТТАЛКИВАНИЯ", UDim2.new(0.05, 0, 0.48, 0), UDim2.new(0.9, 0, 0, 25))

local antiPlayerBtn = createButton(mainFrame, "⚡ ОТТАЛКИВАНИЕ: ВЫКЛ\n(Игроки отлетают вверх)", UDim2.new(0.05, 0, 0.53, 0), 
    UDim2.new(0.9, 0, 0, 60), Color3.fromRGB(255, 60, 150), Color3.fromRGB(255, 90, 180))

-- =============================================
-- СЕКЦИЯ ТЕЛЕПОРТАЦИИ
-- =============================================
createLabel(mainFrame, "📍 ТЕЛЕПОРТАЦИЯ", UDim2.new(0.05, 0, 0.63, 0), UDim2.new(0.9, 0, 0, 25))

local teleportClickBtn = createButton(mainFrame, "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВЫКЛ\n(ЛКМ по земле)", UDim2.new(0.05, 0, 0.68, 0), 
    UDim2.new(0.9, 0, 0, 60), Color3.fromRGB(0, 180, 255), Color3.fromRGB(40, 210, 255))

-- =============================================
-- СЕКЦИЯ КРАЖИ ПРЕДМЕТОВ
-- =============================================
createLabel(mainFrame, "🎒 СИСТЕМА КРАЖИ", UDim2.new(0.05, 0, 0.78, 0), UDim2.new(0.9, 0, 0, 25))

local stealItemsBtn = createButton(mainFrame, "🎒 КРАЖА ИНВЕНТАРЯ: ВЫКЛ\n(Перенос предметов)", UDim2.new(0.05, 0, 0.83, 0), 
    UDim2.new(0.9, 0, 0, 60), Color3.fromRGB(180, 60, 255), Color3.fromRGB(200, 90, 255))

-- =============================================
-- КНОПКИ УПРАВЛЕНИЯ ОКНОМ
-- =============================================
local closeBtn = createButton(mainFrame, "✕", UDim2.new(0.95, -30, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50))

local minBtn = createButton(mainFrame, "−", UDim2.new(0.95, -65, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(255, 185, 0), Color3.fromRGB(255, 205, 40))

-- =============================================
-- СЕКЦИЯ ИНФОРМАЦИИ
-- =============================================
local infoLabel = createLabel(mainFrame, "ℹ️ УПРАВЛЕНИЕ: F-Полет | G-God Mode | R-Отталкивание | T-Телепорт | Y-Кража", 
    UDim2.new(0.05, 0, 0.95, 0), UDim2.new(0.9, 0, 0, 25))
infoLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 80)
infoLabel.TextScaled = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center

-- =============================================
-- 1. ADVANCED GOD MODE (ПОДЗЕМНЫЙ ХИТБОКС)
-- =============================================
local function toggleAdvancedGodMode()
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💀 GOD MODE: ВКЛ\n(Хитбокс под землей)"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
        
        -- Сохраняем оригинальную позицию
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        originalCFrame = rootPart.CFrame
        
        -- Создаем фейковую модель на поверхности
        fakeCharacter = character:Clone()
        fakeCharacter.Name = "GodModeFake_" .. player.Name
        
        -- Делаем фейковую модель видимой
        for _, part in pairs(fakeCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                part.CanCollide = false
            end
        end
        
        -- Помещаем фейковую модель на оригинальную позицию
        local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart") or fakeCharacter:FindFirstChild("Torso")
        if fakeRoot then
            fakeRoot.CFrame = originalCFrame
        end
        
        fakeCharacter.Parent = Workspace
        
        -- Телепортируем реального персонажа глубоко под землю
        rootPart.CFrame = undergroundCFrame
        
        -- Создаем хитбокс под землей
        local hitbox = Instance.new("Part")
        hitbox.Name = "UndergroundHitbox"
        hitbox.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        hitbox.Transparency = 0.8
        hitbox.Color = Color3.fromRGB(255, 50, 50)
        hitbox.Material = Enum.Material.Neon
        hitbox.CanCollide = false
        hitbox.Anchored = false
        hitbox.Parent = character
        
        -- Привязываем хитбокс к персонажу
        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = hitbox
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = hitbox
        
        -- Устанавливаем бессмертие
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
        humanoid.BreakJointsOnDeath = false
        
        -- Включаем наблюдение камерой за фейковой моделью
        if fakeRoot then
            camera.CameraSubject = fakeRoot
            camera.CFrame = CFrame.new(fakeRoot.Position + Vector3.new(0, 10, -15), fakeRoot.Position)
        end
        
        -- Синхронизация движений
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not character or not fakeCharacter then return end
            
            local realRoot = character:FindFirstChild("HumanoidRootPart")
            local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
            
            if realRoot and fakeRoot then
                -- Копируем движения на поверхность
                fakeRoot.CFrame = CFrame.new(realRoot.Position.X, originalCFrame.Y, realRoot.Position.Z)
                
                -- Обновляем анимации
                local fakeHumanoid = fakeCharacter:FindFirstChild("Humanoid")
                if fakeHumanoid then
                    fakeHumanoid:Move(humanoid.MoveDirection)
                end
                
                -- Обновляем камеру
                camera.CFrame = CFrame.new(fakeRoot.Position + Vector3.new(0, 10, -15), fakeRoot.Position)
            end
        end)
        
        -- Защита от урона
        local healthProtection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled then return end
            humanoid.Health = humanoid.MaxHealth
            
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        
        print("✅ ADVANCED GOD MODE АКТИВИРОВАН")
        print("📌 Реальный персонаж: под землей с хитбоксом")
        print("📌 Камера наблюдает за: фейковой моделью на поверхности")
        
    else
        godModeBtn.Text = "💀 GOD MODE: ВЫКЛ\n(Хитбокс под землей)"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        -- Отключаем соединения
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        -- Возвращаем реального персонажа на поверхность
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart and originalCFrame then
            rootPart.CFrame = originalCFrame
        end
        
        -- Возвращаем камеру
        camera.CameraSubject = humanoid
        
        -- Удаляем хитбокс
        local hitbox = character:FindFirstChild("UndergroundHitbox")
        if hitbox then
            hitbox:Destroy()
        end
        
        -- Удаляем фейковую модель
        if fakeCharacter then
            fakeCharacter:Destroy()
            fakeCharacter = nil
        end
        
        -- Восстанавливаем здоровье
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = math.min(humanoid.Health, 100)
            humanoid.BreakJointsOnDeath = true
        end
        
        print("❌ ADVANCED GOD MODE ДЕАКТИВИРОВАН")
    end
end

-- Функции изменения размера хитбокса
hitboxUpBtn.MouseButton1Click:Connect(function()
    hitboxSize = math.min(hitboxSize + 5, 50)
    hitboxDisplay.Text = "📦 РАЗМЕР ХИТБОКСА: " .. hitboxSize
    
    if godModeEnabled then
        local hitbox = character:FindFirstChild("UndergroundHitbox")
        if hitbox then
            hitbox.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        end
    end
end)

hitboxDownBtn.MouseButton1Click:Connect(function()
    hitboxSize = math.max(hitboxSize - 5, 5)
    hitboxDisplay.Text = "📦 РАЗМЕР ХИТБОКСА: " .. hitboxSize
    
    if godModeEnabled then
        local hitbox = character:FindFirstChild("UndergroundHitbox")
        if hitbox then
            hitbox.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        end
    end
end)

-- =============================================
-- 2. УЛУЧШЕННАЯ СИСТЕМА ОТТАЛКИВАНИЯ ИГРОКОВ
-- =============================================
local function toggleAntiPlayer()
    antiPlayerEnabled = not antiPlayerEnabled
    
    if antiPlayerEnabled then
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ: ВКЛ\n(Игроки отлетают вверх)"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 180)
        
        antiPlayerConnection = RunService.Heartbeat:Connect(function()
            if not antiPlayerEnabled or not character then return end
            
            local myPosition = character:FindFirstChild("HumanoidRootPart")
            if not myPosition then return end
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    local otherHumanoid = otherChar:FindFirstChild("Humanoid")
                    
                    if otherRoot and otherHumanoid then
                        local distance = (myPosition.Position - otherRoot.Position).Magnitude
                        
                        -- Если игрок приблизился на расстояние хитбокса
                        if distance < hitboxSize * 2 then
                            -- Вычисляем силу отталкивания (только вверх)
                            local force = Vector3.new(0, 150, 0)
                            
                            -- Применяем взрывную силу вверх
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = force
                            bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                            bodyVelocity.P = 10000
                            bodyVelocity.Parent = otherRoot
                            
                            -- Визуальный эффект
                            local explosion = Instance.new("Explosion")
                            explosion.Position = otherRoot.Position
                            explosion.BlastPressure = 0
                            explosion.BlastRadius = 10
                            explosion.ExplosionType = Enum.ExplosionType.NoCraters
                            explosion.DestroyJointRadiusPercent = 0
                            explosion.Parent = Workspace
                            
                            -- Эффект частиц
                            local particles = Instance.new("ParticleEmitter")
                            particles.Size = NumberSequence.new(2)
                            particles.Transparency = NumberSequence.new(0.5)
                            particles.Lifetime = NumberRange.new(1)
                            particles.Rate = 50
                            particles.Speed = NumberRange.new(20)
                            particles.VelocitySpread = 50
                            particles.Parent = otherRoot
                            
                            -- Удаляем эффекты
                            game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
                            game:GetService("Debris"):AddItem(explosion, 1)
                            game:GetService("Debris"):AddItem(particles, 1)
                            
                            -- Звуковой эффект
                            local sound = Instance.new("Sound")
                            sound.SoundId = "rbxassetid://911846833"
                            sound.Volume = 0.7
                            sound.Parent = otherRoot
                            sound:Play()
                            game:GetService("Debris"):AddItem(sound, 2)
                        end
                    end
                end
            end
        end)
        
        print("✅ СИСТЕМА ОТТАЛКИВАНИЯ АКТИВИРОВАНА")
        print("📌 Игроки отлетают ВВЕРХ при приближении")
        
    else
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ: ВЫКЛ\n(Игроки отлетают вверх)"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 150)
        
        if antiPlayerConnection then
            antiPlayerConnection:Disconnect()
            antiPlayerConnection = nil
        end
        
        print("❌ СИСТЕМА ОТТАЛКИВАНИЯ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 3. ТЕЛЕПОРТ ПО КЛИКУ
-- =============================================
local function toggleTeleportClick()
    teleportClickEnabled = not teleportClickEnabled
    
    if teleportClickEnabled then
        teleportClickBtn.Text = "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВКЛ\n(ЛКМ по земле)"
        teleportClickBtn.BackgroundColor3 = Color3.fromRGB(40, 210, 255)
        
        -- Создаем курсор для телепорта
        local cursor = Instance.new("Part")
        cursor.Name = "TeleportCursor"
        cursor.Size = Vector3.new(2, 0.2, 2)
        cursor.Color = Color3.fromRGB(0, 255, 0)
        cursor.Material = Enum.Material.Neon
        cursor.Transparency = 0.5
        cursor.CanCollide = false
        cursor.Anchored = true
        cursor.Parent = Workspace
        
        teleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- Получаем позицию под курсором
                local mouse = player:GetMouse()
                local target = mouse.Hit
                
                -- Обновляем позицию курсора
                cursor.Position = target.Position + Vector3.new(0, 1, 0)
                
                -- Телепортируем персонажа
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                    
                    -- Визуальный эффект телепорта
                    local teleportEffect = Instance.new("Part")
                    teleportEffect.Size = Vector3.new(5, 5, 5)
                    teleportEffect.Color = Color3.fromRGB(0, 255, 255)
                    teleportEffect.Material = Enum.Material.Neon
                    teleportEffect.Transparency = 0.7
                    teleportEffect.CanCollide = false
                    teleportEffect.Anchored = true
                    teleportEffect.Position = rootPart.Position
                    teleportEffect.Parent = Workspace
                    
                    -- Эффект частиц
                    local particles = Instance.new("ParticleEmitter")
                    particles.Size = NumberSequence.new(3)
                    particles.Transparency = NumberSequence.new(0.5)
                    particles.Lifetime = NumberRange.new(1)
                    particles.Rate = 100
                    particles.Speed = NumberRange.new(10)
                    particles.Parent = teleportEffect
                    
                    -- Звук телепорта
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://138199580"
                    sound.Volume = 0.5
                    sound.Parent = rootPart
                    sound:Play()
                    
                    game:GetService("Debris"):AddItem(teleportEffect, 2)
                    game:GetService("Debris"):AddItem(sound, 2)
                    
                    print("📌 Телепортирован на позицию: " .. tostring(target.Position))
                end
            end
        end)
        
        print("✅ ТЕЛЕПОРТ ПО КЛИКУ АКТИВИРОВАН")
        print("📌 ЛКМ по земле для телепорта")
        
    else
        teleportClickBtn.Text = "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВЫКЛ\n(ЛКМ по земле)"
        teleportClickBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
        end
        
        -- Удаляем курсор
        local cursor = Workspace:FindFirstChild("TeleportCursor")
        if cursor then
            cursor:Destroy()
        end
        
        print("❌ ТЕЛЕПОРТ ПО КЛИКУ ДЕАКТИВИРОВАН")
    end
end

-- =============================================
-- 4. СИСТЕМА КРАЖИ ИНВЕНТАРЯ
-- =============================================
local function toggleStealItems()
    stealItemsEnabled = not stealItemsEnabled
    
    if stealItemsEnabled then
        stealItemsBtn.Text = "🎒 КРАЖА ИНВЕНТАРЯ: ВКЛ\n(Перенос предметов)"
        stealItemsBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 255)
        
        -- Функция поиска и кражи предметов
        local function findAndStealItems()
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local backpack = otherPlayer:FindFirstChild("Backpack")
                    
                    if backpack then
                        -- Копируем все инструменты из чужого инвентаря
                        for _, tool in pairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") or tool:IsA("HopperBin") then
                                -- Создаем копию инструмента
                                local clonedTool = tool:Clone()
                                clonedTool.Parent = player.Backpack
                                
                                print("✅ Украден инструмент: " .. tool.Name .. " у игрока " .. otherPlayer.Name)
                                
                                -- Визуальный эффект
                                local effect = Instance.new("Part")
                                effect.Size = Vector3.new(1, 1, 1)
                                effect.Color = Color3.fromRGB(255, 100, 255)
                                effect.Material = Enum.Material.Neon
                                effect.Transparency = 0.5
                                effect.CanCollide = false
                                effect.Anchored = true
                                effect.Position = character.HumanoidRootPart.Position
                                effect.Parent = Workspace
                                
                                game:GetService("Debris"):AddItem(effect, 1)
                            end
                        end
                    end
                    
                    -- Поиск предметов в руках
                    for _, tool in pairs(otherChar:GetChildren()) do
                        if tool:IsA("Tool") then
                            -- Попытка забрать инструмент из рук
                            tool.Parent = player.Backpack
                            print("✅ Забран инструмент из рук: " .. tool.Name)
                        end
                    end
                end
            end
        end
        
        -- Запускаем автоматическую кражу каждые 3 секунды
        stealConnection = RunService.Heartbeat:Connect(function()
            if not stealItemsEnabled then return end
            findAndStealItems()
        end)
        
        -- Также кража при нажатии на игрока
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not stealItemsEnabled then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                local mouse = player:GetMouse()
                local target = mouse.Target
                
                if target and target.Parent then
                    local model = target.Parent
                    if model:IsA("Model") then
                        local targetPlayer = Players:GetPlayerFromCharacter(model)
                        if targetPlayer and targetPlayer ~= player then
                            findAndStealItems()
                            print("🎯 Целенаправленная кража у: " .. targetPlayer.Name)
                        end
                    end
                end
            end
        end)
        
        print("✅ СИСТЕМА КРАЖИ ИНВЕНТАРЯ АКТИВИРОВАНА")
        print("📌 Автоматическая кража каждые 3 секунды")
        print("📌 ПКМ по игроку для принудительной кражи")
        
    else
        stealItemsBtn.Text = "🎒 КРАЖА ИНВЕНТАРЯ: ВЫКЛ\n(Перенос предметов)"
        stealItemsBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        
        if stealConnection then
            stealConnection:Disconnect()
            stealConnection = nil
        end
        
        print("❌ СИСТЕМА КРАЖИ ИНВЕНТАРЯ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 5. ФУНКЦИЯ ПОЛЕТА
-- =============================================
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        flyBtn.Text = "✈️ ПОЛЕТ: ВКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 210, 60)
        
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
        
    else
        flyBtn.Text = "✈️ ПОЛЕТ: ВЫКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        
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
    end
end)

-- Кнопки скорости полета
local speedUpBtn = createButton(mainFrame, "▲ СКОРОСТЬ +", UDim2.new(0.05, 0, 0.23, 0), 
    UDim2.new(0.43, 0, 0, 30), Color3.fromRGB(80, 200, 80), Color3.fromRGB(100, 220, 100))

local speedDownBtn = createButton(mainFrame, "▼ СКОРОСТЬ -", UDim2.new(0.52, 0, 0.23, 0), 
    UDim2.new(0.43, 0, 0, 30),
