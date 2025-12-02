-- Ultimate GUI V12 - Spike Shield & Force Field
-- Автор: Modified by User

-- Проверяем загрузку игры
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
local Debris = game:GetService("Debris")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChild("Humanoid")

-- Ждем персонажа если его нет
if not character then
    player.CharacterAdded:Wait()
    character = player.Character
    humanoid = character:WaitForChild("Humanoid")
end

-- Камера
local camera = workspace.CurrentCamera

-- Переменные состояния
local flyEnabled = false
local flightSpeed = 50
local godModeEnabled = false
local spikeEnabled = false
local forceFieldEnabled = false
local teleportClickEnabled = false
local antiPlayerEnabled = false

-- Переменные для систем
local flyBodyGyro, flyBodyVelocity, flyConnection
local godModeConnection, spikeConnection, forceFieldConnection, teleportConnection, antiPlayerConnection
local fakeCharacter = nil
local randomMapCorners = {
    Vector3.new(1000, 100, 1000),    -- Северо-восток
    Vector3.new(-1000, 100, 1000),   -- Северо-запад
    Vector3.new(1000, 100, -1000),   -- Юго-восток
    Vector3.new(-1000, 100, -1000)   -- Юго-запад
}
local originalCFrame = nil
local cursorPart = nil
local spikeHitbox = nil
local forceField = nil

-- Создание основного GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V12"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
mainFrame.BorderSizePixel = 3
mainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
mainFrame.Size = UDim2.new(0, 380, 0, 480)
mainFrame.Active = true
mainFrame.Draggable = true

-- =============================================
-- ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ GUI
-- =============================================
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
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = color
    end)
    
    return button
end

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 35)
title.Font = Enum.Font.SourceSansBold
title.Text = "⚡ ULTIMATE GUI V12 ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextScaled = true

-- =============================================
-- СЕКЦИЯ ПОЛЕТА
-- =============================================
local flyBtn = createButton(mainFrame, "✈️ ПОЛЕТ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.1, 0), UDim2.new(0.4, 0, 0, 35),
    Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80))

local speedDisplay = Instance.new("TextLabel")
speedDisplay.Parent = mainFrame
speedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
speedDisplay.BorderSizePixel = 0
speedDisplay.Position = UDim2.new(0.55, 0, 0.1, 0)
speedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
speedDisplay.Font = Enum.Font.SourceSansBold
speedDisplay.Text = "СКОРОСТЬ: 50"
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.TextSize = 14

local speedUpBtn = createButton(mainFrame, "▲ +", 
    UDim2.new(0.05, 0, 0.18, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(60, 180, 60), Color3.fromRGB(80, 200, 80))

local speedDownBtn = createButton(mainFrame, "▼ -", 
    UDim2.new(0.3, 0, 0.18, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(180, 60, 60), Color3.fromRGB(200, 80, 80))

-- =============================================
-- ADVANCED GOD MODE (рандомный хитбокс)
-- =============================================
local godModeBtn = createButton(mainFrame, "💀 GOD MODE: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.26, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 120, 120))

local godModeInfo = Instance.new("TextLabel")
godModeInfo.Parent = mainFrame
godModeInfo.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
godModeInfo.BorderSizePixel = 0
godModeInfo.Position = UDim2.new(0.05, 0, 0.34, 0)
godModeInfo.Size = UDim2.new(0.9, 0, 0, 40)
godModeInfo.Font = Enum.Font.SourceSans
godModeInfo.Text = "📍 Хитбокс в случайном углу карты\n🎭 Вы управляете фейковой моделью"
godModeInfo.TextColor3 = Color3.fromRGB(200, 255, 200)
godModeInfo.TextSize = 11
godModeInfo.TextWrapped = true

-- =============================================
-- СИСТЕМА ШИПОВ (отражение урона)
-- =============================================
local spikeBtn = createButton(mainFrame, "🦔 ШИПЫ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.42, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 170, 40))

local spikeInfo = Instance.new("TextLabel")
spikeInfo.Parent = mainFrame
spikeInfo.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
spikeInfo.BorderSizePixel = 0
spikeInfo.Position = UDim2.new(0.05, 0, 0.5, 0)
spikeInfo.Size = UDim2.new(0.9, 0, 0, 40)
spikeInfo.Font = Enum.Font.SourceSans
spikeInfo.Text = "⚡ Полученный урон перенаправляется\n🎯 Атакующий получает урон обратно"
spikeInfo.TextColor3 = Color3.fromRGB(255, 200, 150)
spikeInfo.TextSize = 11
spikeInfo.TextWrapped = true

-- =============================================
-- СИЛОВОЕ ПОЛЕ (отталкивание)
-- =============================================
local forceFieldBtn = createButton(mainFrame, "🛡️ СИЛОВОЕ ПОЛЕ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.58, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(0, 180, 255), Color3.fromRGB(40, 210, 255))

local forceFieldInfo = Instance.new("TextLabel")
forceFieldInfo.Parent = mainFrame
forceFieldInfo.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
forceFieldInfo.BorderSizePixel = 0
forceFieldInfo.Position = UDim2.new(0.05, 0, 0.66, 0)
forceFieldInfo.Size = UDim2.new(0.9, 0, 0, 40)
forceFieldInfo.Font = Enum.Font.SourceSans
forceFieldInfo.Text = "🌀 Отталкивает других игроков\n🛡️ Защищает от приближения"
forceFieldInfo.TextColor3 = Color3.fromRGB(150, 200, 255)
forceFieldInfo.TextSize = 11
forceFieldInfo.TextWrapped = true

-- =============================================
-- ТЕЛЕПОРТ ПО КЛИКУ
-- =============================================
local teleportBtn = createButton(mainFrame, "📍 ТЕЛЕПОРТ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.74, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(180, 60, 255), Color3.fromRGB(200, 90, 255))

-- =============================================
-- КНОПКИ УПРАВЛЕНИЯ
-- =============================================
local closeBtn = createButton(mainFrame, "✕", 
    UDim2.new(0.94, -25, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50))

local minBtn = createButton(mainFrame, "−", 
    UDim2.new(0.94, -55, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 185, 40))

-- =============================================
-- ИНФОРМАЦИЯ
-- =============================================
local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = mainFrame
infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
infoLabel.BorderSizePixel = 0
infoLabel.Position = UDim2.new(0.05, 0, 0.86, 0)
infoLabel.Size = UDim2.new(0.9, 0, 0, 45)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Text = "F-Полет | G-God | S-Шипы | P-Поле | T-Телепорт"
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.TextScaled = true

-- =============================================
-- 1. ADVANCED GOD MODE (рандомный хитбокс)
-- =============================================
local function toggleGodMode()
    if not character then return end
    
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💀 GOD MODE: ВКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Сохраняем оригинальную позицию
        originalCFrame = rootPart.CFrame
        
        -- Выбираем случайный угол карты
        local randomCorner = randomMapCorners[math.random(1, #randomMapCorners)]
        
        -- Создаем фейковую модель для управления
        fakeCharacter = character:Clone()
        fakeCharacter.Name = "PlayerFake"
        
        -- Делаем фейковую модель видимой и интерактивной
        for _, part in pairs(fakeCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                part.CanCollide = true
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(100, 100, 255)
            end
        end
        
        -- Настраиваем фейковый Humanoid
        local fakeHumanoid = fakeCharacter:FindFirstChild("Humanoid")
        if fakeHumanoid then
            fakeHumanoid.WalkSpeed = humanoid.WalkSpeed
            fakeHumanoid.JumpPower = humanoid.JumpPower
            fakeHumanoid.MaxHealth = math.huge
            fakeHumanoid.Health = math.huge
        end
        
        -- Помещаем фейковую модель на оригинальную позицию
        local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
        if fakeRoot then
            fakeRoot.CFrame = originalCFrame
        end
        
        fakeCharacter.Parent = Workspace
        
        -- Телепортируем реального персонажа в случайный угол
        rootPart.CFrame = CFrame.new(randomCorner)
        
        -- Создаем невидимый и неуязвимый хитбокс
        local hitbox = Instance.new("Part")
        hitbox.Name = "GodModeHitbox"
        hitbox.Size = Vector3.new(10, 10, 10)
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = false
        hitbox.Parent = character
        
        -- Делаем хитбокс неуязвимым
        local hitboxHumanoid = Instance.new("Humanoid")
        hitboxHumanoid.Name = "HitboxHumanoid"
        hitboxHumanoid.MaxHealth = math.huge
        hitboxHumanoid.Health = math.huge
        hitboxHumanoid.Parent = character
        
        -- Привязываем хитбокс к персонажу
        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = hitbox
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = hitbox
        
        -- Устанавливаем бессмертие для реального персонажа
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
        humanoid.BreakJointsOnDeath = false
        
        -- Настраиваем камеру на фейковую модель
        if fakeRoot then
            camera.CameraSubject = fakeHumanoid
        end
        
        -- Синхронизация движений
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not character or not fakeCharacter then return end
            
            local realRoot = character:FindFirstChild("HumanoidRootPart")
            local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
            local fakeHumanoid = fakeCharacter:FindFirstChild("Humanoid")
            
            if realRoot and fakeRoot and fakeHumanoid then
                -- Копируем движения с реального персонажа на фейковый
                fakeRoot.CFrame = CFrame.new(realRoot.Position.X, originalCFrame.Y, realRoot.Position.Z)
                
                -- Копируем направление движения
                fakeHumanoid:Move(humanoid.MoveDirection)
                
                -- Обновляем камеру
                camera.CFrame = CFrame.new(fakeRoot.Position + Vector3.new(0, 10, -15), fakeRoot.Position)
                
                -- Защита здоровья реального персонажа
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        -- Защита от любых повреждений
        local damageProtection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled then return end
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                
                -- Защита от смерти
                if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
        
        print("✅ ADVANCED GOD MODE АКТИВИРОВАН")
        print("📍 Реальный персонаж: в случайном углу карты")
        print("🎭 Фейковая модель: под вашим контролем")
        print("🛡️ Хитбокс: неуязвим и невидим")
        
    else
        godModeBtn.Text = "💀 GOD MODE: ВЫКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        -- Отключаем соединения
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        -- Возвращаем реального персонажа на место
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart and originalCFrame then
            rootPart.CFrame = originalCFrame
        end
        
        -- Возвращаем камеру
        camera.CameraSubject = humanoid
        
        -- Удаляем хитбокс
        local hitbox = character:FindFirstChild("GodModeHitbox")
        if hitbox then
            hitbox:Destroy()
        end
        
        local hitboxHumanoid = character:FindFirstChild("HitboxHumanoid")
        if hitboxHumanoid then
            hitboxHumanoid:Destroy()
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

-- =============================================
-- 2. СИСТЕМА ШИПОВ (отражение урона)
-- =============================================
local function toggleSpike()
    spikeEnabled = not spikeEnabled
    
    if spikeEnabled then
        spikeBtn.Text = "🦔 ШИПЫ: ВКЛ"
        spikeBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
        
        -- Создаем визуальный эффект шипов
        spikeHitbox = Instance.new("Part")
        spikeHitbox.Name = "SpikeHitbox"
        spikeHitbox.Size = Vector3.new(8, 8, 8)
        spikeHitbox.Transparency = 0.7
        spikeHitbox.Color = Color3.fromRGB(255, 100, 0)
        spikeHitbox.Material = Enum.Material.Neon
        spikeHitbox.CanCollide = false
        spikeHitbox.Anchored = false
        spikeHitbox.Parent = character
        
        -- Эффект частиц для шипов
        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxassetid://242663622"
        particles.Size = NumberSequence.new(1)
        particles.Transparency = NumberSequence.new(0.5)
        particles.Lifetime = NumberRange.new(1)
        particles.Rate = 50
        particles.Speed = NumberRange.new(5)
        particles.VelocitySpread = 20
        particles.Parent = spikeHitbox
        
        -- Привязываем к персонажу
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local weld = Instance.new("Weld")
            weld.Part0 = rootPart
            weld.Part1 = spikeHitbox
            weld.C0 = CFrame.new(0, 0, 0)
            weld.Parent = spikeHitbox
        end
        
        -- Функция отражения урона
        spikeConnection = RunService.Heartbeat:Connect(function()
            if not spikeEnabled or not character then return end
            
            -- Проверяем получение урона
            if humanoid and humanoid.Health < humanoid.MaxHealth then
                -- Находим ближайшего игрока как потенциального атакующего
                local nearestPlayer = nil
                local nearestDistance = math.huge
                local myPosition = character:FindFirstChild("HumanoidRootPart")
                
                if myPosition then
                    for _, otherPlayer in pairs(Players:GetPlayers()) do
                        if otherPlayer ~= player and otherPlayer.Character then
                            local otherChar = otherPlayer.Character
                            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                            
                            if otherRoot then
                                local distance = (myPosition.Position - otherRoot.Position).Magnitude
                                if distance < 20 and distance < nearestDistance then
                                    nearestPlayer = otherPlayer
                                    nearestDistance = distance
                                end
                            end
                        end
                    end
                end
                
                -- Если нашли потенциального атакующего, наносим урон обратно
                if nearestPlayer and nearestPlayer.Character then
                    local targetHumanoid = nearestPlayer.Character:FindFirstChild("Humanoid")
                    if targetHumanoid then
                        -- Наносим урон (50% от максимального здоровья)
                        local damage = targetHumanoid.MaxHealth * 0.5
                        targetHumanoid:TakeDamage(damage)
                        
                        -- Визуальный эффект отражения
                        local effect = Instance.new("Part")
                        effect.Size = Vector3.new(3, 3, 3)
                        effect.Color = Color3.fromRGB(255, 50, 50)
                        effect.Material = Enum.Material.Neon
                        effect.Transparency = 0.5
                        effect.CanCollide = false
                        effect.Anchored = true
                        effect.Position = character.HumanoidRootPart.Position
                        effect.Parent = Workspace
                        
                        -- Эффект частиц
                        local sparkles = Instance.new("ParticleEmitter")
                        sparkles.Texture = "rbxassetid://242663622"
                        sparkles.Size = NumberSequence.new(2)
                        sparkles.Transparency = NumberSequence.new(0.5)
                        sparkles.Lifetime = NumberRange.new(0.5)
                        sparkles.Rate = 100
                        sparkles.Speed = NumberRange.new(20)
                        sparkles.Parent = effect
                        
                        -- Восстанавливаем здоровье
                        humanoid.Health = humanoid.MaxHealth
                        
                        -- Удаляем эффекты
                        Debris:AddItem(effect, 1)
                        
                        print("⚡ Урон отражен на: " .. nearestPlayer.Name)
                    end
                end
                
                -- Всегда восстанавливаем здоровье
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        print("✅ СИСТЕМА ШИПОВ АКТИВИРОВАНА")
        print("🔄 Полученный урон перенаправляется атакующему")
        
    else
        spikeBtn.Text = "🦔 ШИПЫ: ВЫКЛ"
        spikeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        
        if spikeConnection then
            spikeConnection:Disconnect()
            spikeConnection = nil
        end
        
        if spikeHitbox then
            spikeHitbox:Destroy()
            spikeHitbox = nil
        end
        
        print("❌ СИСТЕМА ШИПОВ ДЕАКТИВИРОВАНА")
    end
end

-- =============================================
-- 3. СИЛОВОЕ ПОЛЕ (отталкивание игроков)
-- =============================================
local function toggleForceField()
    forceFieldEnabled = not forceFieldEnabled
    
    if forceFieldEnabled then
        forceFieldBtn.Text = "🛡️ СИЛОВОЕ ПОЛЕ: ВКЛ"
        forceFieldBtn.BackgroundColor3 = Color3.fromRGB(40, 210, 255)
        
        -- Создаем видимое силовое поле
        forceField = Instance.new("Part")
        forceField.Name = "ForceField"
        forceField.Shape = Enum.PartType.Ball
        forceField.Size = Vector3.new(15, 15, 15)
        forceField.Transparency = 0.8
        forceField.Color = Color3.fromRGB(0, 150, 255)
        forceField.Material = Enum.Material.Neon
        forceField.CanCollide = false
        forceField.Anchored = false
        forceField.Parent = character
        
        -- Эффект частиц для поля
        local fieldParticles = Instance.new("ParticleEmitter")
        fieldParticles.Texture = "rbxassetid://242663598"
        fieldParticles.Size = NumberSequence.new(2)
        fieldParticles.Transparency = NumberSequence.new(0.7)
        fieldParticles.Lifetime = NumberRange.new(1)
        fieldParticles.Rate = 100
        fieldParticles.Speed = NumberRange.new(5)
        fieldParticles.Rotation = NumberRange.new(0, 360)
        fieldParticles.Parent = forceField
        
        -- Привязываем к персонажу
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local weld = Instance.new("Weld")
            weld.Part0 = rootPart
            weld.Part1 = forceField
            weld.C0 = CFrame.new(0, 0, 0)
            weld.Parent = forceField
        end
        
        -- Функция отталкивания игроков
        forceFieldConnection = RunService.Heartbeat:Connect(function()
            if not forceFieldEnabled or not character then return end
            
            local myPosition = character:FindFirstChild("HumanoidRootPart")
            if not myPosition then return end
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    
                    if otherRoot then
                        local distance = (myPosition.Position - otherRoot.Position).Magnitude
                        
                        -- Если игрок в зоне действия поля (10 studs)
                        if distance < 10 then
                            -- Вычисляем направление отталкивания
                            local direction = (otherRoot.Position - myPosition.Position).Unit
                            local force = direction * 50 + Vector3.new(0, 15, 0)
                            
                            -- Применяем силу
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = force
                            bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                            bodyVelocity.P = 10000
                            bodyVelocity.Parent = otherRoot
                            
                            -- Визуальный эффект отталкивания
                            local shockwave = Instance.new("Part")
                            shockwave.Shape = Enum.PartType.Ball
                            shockwave.Size = Vector3.new(5, 5, 5)
                            shockwave.Transparency = 0.7
                            shockwave.Color = Color3.fromRGB(0, 200, 255)
                            shockwave.Material = Enum.Material.Neon
                            shockwave.CanCollide = false
                            shockwave.Anchored = true
                            shockwave.Position = otherRoot.Position
                            shockwave.Parent = Workspace
                            
                            -- Анимация расширения
                            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            local tween = TweenService:Create(shockwave, tweenInfo, {Size = Vector3.new(15, 15, 15), Transparency = 1})
                            tween:Play()
                            
                            -- Удаляем эффекты
                            Debris:AddItem(bodyVelocity, 0.5)
                            Debris:AddItem(shockwave, 1)
                            
                            -- Звуковой эффект
                            if otherRoot:FindFirstChild("ForceFieldSound") == nil then
                                local sound = Instance.new("Sound")
                                sound.Name = "ForceFieldSound"
                                sound.SoundId = "rbxassetid://911846833"
                                sound.Volume = 0.3
                                sound.Parent = otherRoot
                                sound:Play()
                                Debris:AddItem(sound, 2)
                            end
                        end
                    end
                end
            end
        end)
        
        print("✅ СИЛОВОЕ ПОЛЕ АКТИВИРОВАНО")
        print("🌀 Игроки отталкиваются при приближении")
        
    else
        forceFieldBtn.Text = "🛡️ СИЛОВОЕ ПОЛЕ: ВЫКЛ"
        forceFieldBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        
        if forceFieldConnection then
            forceFieldConnection:Disconnect()
            forceFieldConnection = nil
        end
        
        if forceField then
            forceField:Destroy()
            forceField = nil
        end
        
        print("❌ СИЛОВОЕ ПОЛЕ ДЕАКТИВИРОВАНО")
    end
end

-- =============================================
-- 4. ФУНКЦИЯ ПОЛЕТА
-- =============================================
local function toggleFly()
    if not character then return end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        flyBtn.Text = "✈️ ПОЛЕТ: ВКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyVelocity = Instance.new("BodyVelocity")
        
        flyBodyGyro.Parent = rootPart
        flyBodyVelocity.Parent = rootPart
        
        flyBodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        flyBodyGyro.P = 10000
        flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        
        if humanoid then
            humanoid.PlatformStand = true
        end
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not flyEnabled or not character then return end
            
            local cam = workspace.CurrentCamera
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
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
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
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
        
        print("✅ Полет активирован")
        
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
        
        print("❌ Полет деактивирован")
    end
end

-- =============================================
-- 5. ТЕЛЕПОРТ ПО КЛИКУ
-- =============================================
local function toggleTeleport()
    teleportClickEnabled = not teleportClickEnabled
    
    if teleportClickEnabled then
        teleportBtn.Text = "📍 ТЕЛЕПОРТ: ВКЛ"
        teleportBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 255)
        
        cursorPart = Instance.new("Part")
        cursorPart.Name = "TeleportCursor"
        cursorPart.Size = Vector3.new(3, 0.2, 3)
        cursorPart.Color = Color3.fromRGB(0, 255, 0)
        cursorPart.Material = Enum.Material.Neon
        cursorPart.Transparency = 0.6
        cursorPart.CanCollide = false
        cursorPart.Anchored = true
        cursorPart.Parent = Workspace
        
        teleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            
            local mouse = player:GetMouse()
            local target = mouse.Hit
            
            cursorPart.Position = target.Position + Vector3.new(0, 0.5, 0)
            
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                
                local effect = Instance.new("Part")
                effect.Size = Vector3.new(5, 5, 5)
                effect.Color = Color3.fromRGB(0, 200, 255)
                effect.Material = Enum.Material.Neon
                effect.Transparency = 0.8
                effect.CanCollide = false
                effect.Anchored = true
                effect.Position = rootPart.Position
                effect.Parent = Workspace
                
                Debris:AddItem(effect, 1)
                
                print("📌 Телепортирован")
            end
        end)
        
        print("✅ Телепорт по клику активирован")
        
    else
        teleportBtn.Text = "📍 ТЕЛЕПОРТ: ВЫКЛ"
        teleportBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
        end
        
        if cursorPart then
            cursorPart:Destroy()
            cursorPart = nil
        end
        
        print("❌ Телепорт по клику деактивирован")
    end
end

-- =============================================
-- 6. ОБРАБОТЧИКИ КНОПОК
-- =============================================
flyBtn.MouseButton1Click:Connect(toggleFly)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)
spikeBtn.MouseButton1Click:Connect(toggleSpike)
forceFieldBtn.MouseButton1Click:Connect(toggleForceField)
teleportBtn.MouseButton1Click:Connect(toggleTeleport)

-- Кнопки скорости
speedUpBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.min(flightSpeed + 10, 200)
    speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
end)

speedDownBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.max(flightSpeed - 10, 10)
    speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
end)

-- Управление окном
closeBtn.MouseButton1Click:Connect(function()
    if flyEnabled then toggleFly() end
    if godModeEnabled then toggleGodMode() end
    if spikeEnabled then toggleSpike() end
    if forceFieldEnabled then toggleForceField() end
    if teleportClickEnabled then toggleTeleport() end
    
    screenGui:Destroy()
    print("📌 GUI закрыт")
end)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minBtn.Text = mainFrame.Visible and "−" or "+"
end)

-- =============================================
-- 7. ГОРЯЧИЕ КЛАВИШИ
-- =============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleGodMode()
    elseif input.KeyCode == Enum.KeyCode.S then
        toggleSpike()
    elseif input.KeyCode == Enum.KeyCode.P then
        toggleForceField()
    elseif input.KeyCode == Enum.KeyCode.T then
        toggleTeleport()
    elseif input.KeyCode == Enum.KeyCode.E then
        flightSpeed = math.min(flightSpeed + 10, 200)
        speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        flightSpeed = math.max(flightSpeed - 10, 10)
        speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
    end
end)

-- =============================================
-- 8. ЗАГРУЗОЧНОЕ УВЕДОМЛЕНИЕ
-- =============================================
StarterGui:SetCore("SendNotification", {
    Title = "⚡ ULTIMATE GUI V12",
    Text = "Загружен!\nG-God Mode | S-Шипы | P-Силовое поле",
    Duration = 5,
    Icon = "rbxassetid://6726578081"
})

print("=" .. string.rep("=", 60))
print("✅ ULTIMATE GUI V12 ЗАГРУЖЕН УСПЕШНО!")
print("=" .. string.rep("=", 60))
print("✈️  ПОЛЕТ: F")
print("💀 ADVANCED GOD MODE: G")
print("🦔 СИСТЕМА ШИПОВ: S")
print("🛡️ СИЛОВОЕ ПОЛЕ: P")
print("📍 ТЕЛЕПОРТ ПО КЛИКУ: T")
print("=" .. string.rep("=", 60))
print("🎮 ADVANCED GOD MODE ОСОБЕННОСТИ:")
print("📍 Хитбокс перемещен в случайный угол карты")
print("🎭 Вы управляете фейковой моделью")
print("🛡️ Хитбокс неуязвим для атак")
print("🏃 Вы можете бегать с фейковой моделью")
print("=" .. string.rep("=", 60))
print("⚡ СИСТЕМА ШИПОВ:")
print("🔄 Полученный урон перенаправляется атакующему")
print("🎯 Атакующий получает 50% урона обратно")
print("=" .. string.rep("=", 60))
print("🌀 СИЛОВОЕ ПОЛЕ:")
print("🛡️ Отталкивает других игроков при приближении")
print("🌀 Визуальные эффекты и анимации")
print("=" .. string.rep("=", 60))
