-- Ultimate GUI V9 - Inventory Steal System
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
local MarketplaceService = game:GetService("MarketplaceService")

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
local antiPlayerEnabled = false
local teleportClickEnabled = false
local stealItemsEnabled = false
local hasInventorySystem = false

-- Проверяем наличие системы инвентаря
if player:FindFirstChild("Backpack") then
    hasInventorySystem = true
end

-- Переменные для систем
local flyBodyGyro, flyBodyVelocity, flyConnection
local godModeConnection, antiPlayerConnection, teleportConnection, stealConnection
local fakeCharacter = nil
local undergroundCFrame = CFrame.new(0, -50000, 0)
local originalCFrame = nil
local cursorPart = nil

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V9"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderColor3 = Color3.fromRGB(0, 180, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.Size = UDim2.new(0, 380, 0, 420)
mainFrame.Active = true
mainFrame.Draggable = true

-- Функция создания кнопок
local function createButton(parent, text, position, size, color, hoverColor, enabled)
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
    
    if enabled == false then
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        button.TextColor3 = Color3.fromRGB(150, 150, 150)
        button.AutoButtonColor = false
        button.Active = false
    else
        -- Эффект наведения только для активных кнопок
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = color
        end)
    end
    
    return button
end

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundColor3 = Color3.fromRGB(0, 140, 210)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 35)
title.Font = Enum.Font.SourceSansBold
title.Text = "⚡ ULTIMATE GUI V9 ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextScaled = true

-- Кнопка полета
local flyBtn = createButton(mainFrame, "✈️ ПОЛЕТ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.12, 0), UDim2.new(0.4, 0, 0, 35),
    Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80), true)

-- Дисплей скорости
local speedDisplay = Instance.new("TextLabel")
speedDisplay.Parent = mainFrame
speedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
speedDisplay.BorderSizePixel = 0
speedDisplay.Position = UDim2.new(0.55, 0, 0.12, 0)
speedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
speedDisplay.Font = Enum.Font.SourceSansBold
speedDisplay.Text = "СКОРОСТЬ: 50"
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.TextSize = 14
speedDisplay.TextScaled = true

-- Кнопки скорости
local speedUpBtn = createButton(mainFrame, "▲ +", 
    UDim2.new(0.05, 0, 0.23, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(60, 180, 60), Color3.fromRGB(80, 200, 80), true)

local speedDownBtn = createButton(mainFrame, "▼ -", 
    UDim2.new(0.3, 0, 0.23, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(180, 60, 60), Color3.fromRGB(200, 80, 80), true)

-- God Mode кнопка
local godModeBtn = createButton(mainFrame, "💀 GOD MODE: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.33, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 120, 120), true)

-- Кнопка отталкивания
local antiPlayerBtn = createButton(mainFrame, "⚡ ОТТАЛКИВАНИЕ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.43, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 60, 150), Color3.fromRGB(255, 90, 180), true)

-- Кнопка телепорта по клику
local teleportBtn = createButton(mainFrame, "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.53, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(0, 160, 255), Color3.fromRGB(40, 190, 255), true)

-- Кнопка кражи предметов
local stealBtnText = hasInventorySystem and "🎒 КРАЖА ПРЕДМЕТОВ: ВЫКЛ" or "🎒 ИНВЕНТАРЬ НЕДОСТУПЕН"
local stealBtn = createButton(mainFrame, stealBtnText, 
    UDim2.new(0.05, 0, 0.63, 0), UDim2.new(0.9, 0, 0, 40),
    Color3.fromRGB(180, 60, 255), Color3.fromRGB(200, 90, 255), hasInventorySystem)

-- Информация о системе кражи
local stealInfo = Instance.new("TextLabel")
stealInfo.Parent = mainFrame
stealInfo.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
stealInfo.BorderSizePixel = 0
stealInfo.Position = UDim2.new(0.05, 0, 0.73, 0)
stealInfo.Size = UDim2.new(0.9, 0, 0, 40)
stealInfo.Font = Enum.Font.SourceSans
stealInfo.Text = hasInventorySystem and "🖱️ ПКМ по игроку для кражи" or "⚠️ В этой игре нет системы инвентаря"
stealInfo.TextColor3 = hasInventorySystem and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 150, 150)
stealInfo.TextSize = 11
stealInfo.TextWrapped = true

-- Кнопки управления окном
local closeBtn = createButton(mainFrame, "✕", 
    UDim2.new(0.94, -25, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50), true)

local minBtn = createButton(mainFrame, "−", 
    UDim2.new(0.94, -55, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 185, 40), true)

-- Информация
local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = mainFrame
infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
infoLabel.BorderSizePixel = 0
infoLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
infoLabel.Size = UDim2.new(0.9, 0, 0, 45)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Text = "F-Полет | G-God | R-Отталкивание\nT-Телепорт | V-Кража (если доступно)"
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.TextScaled = true

-- =============================================
-- 1. ФУНКЦИЯ ПОЛЕТА
-- =============================================
local function toggleFly()
    if not character then return end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        flyBtn.Text = "✈️ ПОЛЕТ: ВКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Создаем физические объекты
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyVelocity = Instance.new("BodyVelocity")
        
        flyBodyGyro.Parent = rootPart
        flyBodyVelocity.Parent = rootPart
        
        flyBodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        flyBodyGyro.P = 10000
        flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        
        -- Включаем платформенный режим
        if humanoid then
            humanoid.PlatformStand = true
        end
        
        -- Подключаем обработку движения
        flyConnection = RunService.Heartbeat:Connect(function()
            if not flyEnabled or not character then return end
            
            local cam = workspace.CurrentCamera
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Собираем направление движения
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
            
            -- Применяем скорость
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
        
        -- Отключаем соединение
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        -- Удаляем физические объекты
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        
        -- Выключаем платформенный режим
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        print("❌ Полет деактивирован")
    end
end

-- =============================================
-- 2. GOD MODE (подземный хитбокс)
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
        
        -- Создаем фейковую модель
        fakeCharacter = character:Clone()
        fakeCharacter.Name = "GodModeFake"
        
        -- Делаем фейковую модель видимой
        for _, part in pairs(fakeCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                part.CanCollide = false
            end
        end
        
        -- Помещаем фейковую модель
        local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
        if fakeRoot then
            fakeRoot.CFrame = originalCFrame
        end
        
        fakeCharacter.Parent = Workspace
        
        -- Телепортируем реального персонажа под землю
        rootPart.CFrame = undergroundCFrame
        
        -- Устанавливаем бессмертие
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = humanoid.MaxHealth
            humanoid.BreakJointsOnDeath = false
        end
        
        -- Настраиваем камеру на фейковую модель
        if fakeRoot then
            camera.CameraSubject = fakeRoot
        end
        
        -- Синхронизация движений
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not character or not fakeCharacter then return end
            
            local realRoot = character:FindFirstChild("HumanoidRootPart")
            local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
            
            if realRoot and fakeRoot then
                -- Копируем движения на поверхность
                fakeRoot.CFrame = CFrame.new(realRoot.Position.X, originalCFrame.Y, realRoot.Position.Z)
                
                -- Обновляем камеру
                camera.CFrame = CFrame.new(fakeRoot.Position + Vector3.new(0, 10, -15), fakeRoot.Position)
            end
        end)
        
        -- Защита здоровья
        local healthProtect = RunService.Heartbeat:Connect(function()
            if not godModeEnabled then return end
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        print("✅ God Mode активирован")
        
    else
        godModeBtn.Text = "💀 GOD MODE: ВЫКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        -- Отключаем соединения
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        -- Возвращаем реального персонажа
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart and originalCFrame then
            rootPart.CFrame = originalCFrame
        end
        
        -- Возвращаем камеру
        camera.CameraSubject = humanoid
        
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
        
        print("❌ God Mode деактивирован")
    end
end

-- =============================================
-- 3. СИСТЕМА ОТТАЛКИВАНИЯ ИГРОКОВ
-- =============================================
local function toggleAntiPlayer()
    antiPlayerEnabled = not antiPlayerEnabled
    
    if antiPlayerEnabled then
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ: ВКЛ"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 180)
        
        antiPlayerConnection = RunService.Heartbeat:Connect(function()
            if not antiPlayerEnabled or not character then return end
            
            local myRoot = character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            -- Проверяем всех игроков
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    
                    if otherRoot then
                        local distance = (myRoot.Position - otherRoot.Position).Magnitude
                        
                        -- Если игрок близко (10 studs)
                        if distance < 10 then
                            -- Отталкиваем вверх
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = Vector3.new(0, 80, 0)
                            bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                            bodyVelocity.Parent = otherRoot
                            
                            -- Визуальный эффект
                            local explosion = Instance.new("Explosion")
                            explosion.Position = otherRoot.Position
                            explosion.BlastPressure = 0
                            explosion.BlastRadius = 8
                            explosion.ExplosionType = Enum.ExplosionType.NoCraters
                            explosion.Parent = Workspace
                            
                            -- Удаляем через время
                            game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
                            game:GetService("Debris"):AddItem(explosion, 1)
                        end
                    end
                end
            end
        end)
        
        print("✅ Отталкивание игроков активировано")
        
    else
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ: ВЫКЛ"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 150)
        
        if antiPlayerConnection then
            antiPlayerConnection:Disconnect()
            antiPlayerConnection = nil
        end
        
        print("❌ Отталкивание игроков деактивировано")
    end
end

-- =============================================
-- 4. ТЕЛЕПОРТ ПО КЛИКУ
-- =============================================
local function toggleTeleport()
    teleportClickEnabled = not teleportClickEnabled
    
    if teleportClickEnabled then
        teleportBtn.Text = "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВКЛ"
        teleportBtn.BackgroundColor3 = Color3.fromRGB(40, 190, 255)
        
        -- Создаем курсор
        cursorPart = Instance.new("Part")
        cursorPart.Name = "TeleportCursor"
        cursorPart.Size = Vector3.new(3, 0.2, 3)
        cursorPart.Color = Color3.fromRGB(0, 255, 0)
        cursorPart.Material = Enum.Material.Neon
        cursorPart.Transparency = 0.6
        cursorPart.CanCollide = false
        cursorPart.Anchored = true
        cursorPart.Parent = Workspace
        
        -- Обработчик кликов
        teleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            
            local mouse = player:GetMouse()
            local target = mouse.Hit
            
            -- Обновляем курсор
            cursorPart.Position = target.Position + Vector3.new(0, 0.5, 0)
            
            -- Телепортируем персонажа
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                
                -- Эффект телепорта
                local effect = Instance.new("Part")
                effect.Size = Vector3.new(5, 5, 5)
                effect.Color = Color3.fromRGB(0, 200, 255)
                effect.Material = Enum.Material.Neon
                effect.Transparency = 0.8
                effect.CanCollide = false
                effect.Anchored = true
                effect.Position = rootPart.Position
                effect.Parent = Workspace
                
                game:GetService("Debris"):AddItem(effect, 1)
                
                print("📌 Телепортирован")
            end
        end)
        
        print("✅ Телепорт по клику активирован")
        
    else
        teleportBtn.Text = "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВЫКЛ"
        teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
        
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
-- 5. СИСТЕМА КРАЖИ ПРЕДМЕТОВ ИЗ ИНВЕНТАРЯ
-- =============================================
local function toggleStealItems()
    if not hasInventorySystem then
        print("⚠️ Система инвентаря недоступна в этой игре")
        return
    end
    
    stealItemsEnabled = not stealItemsEnabled
    
    if stealItemsEnabled then
        stealBtn.Text = "🎒 КРАЖА ПРЕДМЕТОВ: ВКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 255)
        
        -- Функция для кражи предметов у выбранного игрока
        local function stealFromPlayer(targetPlayer)
            if not targetPlayer or targetPlayer == player then return end
            
            local targetBackpack = targetPlayer:FindFirstChild("Backpack")
            local targetCharacter = targetPlayer.Character
            
            if not targetBackpack and targetCharacter then
                -- Ищем инструменты в руках
                for _, tool in pairs(targetCharacter:GetChildren()) do
                    if tool:IsA("Tool") then
                        -- Создаем копию инструмента
                        local clonedTool = tool:Clone()
                        clonedTool.Parent = player.Backpack
                        
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
                        
                        print("✅ Украден инструмент: " .. tool.Name .. " у " .. targetPlayer.Name)
                        return true
                    end
                end
            elseif targetBackpack then
                -- Ищем в инвентаре
                for _, item in pairs(targetBackpack:GetChildren()) do
                    if item:IsA("Tool") or item:IsA("HopperBin") then
                        -- Создаем копию
                        local clonedItem = item:Clone()
                        clonedItem.Parent = player.Backpack
                        
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
                        
                        print("✅ Украден предмет: " .. item.Name .. " у " .. targetPlayer.Name)
                        return true
                    end
                end
            end
            
            return false
        end
        
        -- Обработчик ПКМ по игрокам
        stealConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not stealItemsEnabled or input.UserInputType ~= Enum.UserInputType.MouseButton2 then
                return
            end
            
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target and target.Parent then
                local model = target.Parent
                while model and model ~= Workspace do
                    local targetPlayer = Players:GetPlayerFromCharacter(model)
                    if targetPlayer then
                        -- Пытаемся украсть
                        local stolen = stealFromPlayer(targetPlayer)
                        if stolen then
                            -- Уведомление
                            StarterGui:SetCore("SendNotification", {
                                Title = "🎒 КРАЖА ПРЕДМЕТОВ",
                                Text = "Украдено у " .. targetPlayer.Name,
                                Duration = 3
                            })
                        else
                            StarterGui:SetCore("SendNotification", {
                                Title = "🎒 КРАЖА ПРЕДМЕТОВ",
                                Text = "Нет предметов для кражи",
                                Duration = 3
                            })
                        end
                        break
                    end
                    model = model.Parent
                end
            end
        end)
        
        print("✅ Система кражи предметов активирована")
        print("📌 ПКМ по игроку для кражи предметов")
        
    else
        stealBtn.Text = "🎒 КРАЖА ПРЕДМЕТОВ: ВЫКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        
        if stealConnection then
            stealConnection:Disconnect()
            stealConnection = nil
        end
        
        print("❌ Система кражи предметов деактивирована")
    end
end

-- =============================================
-- 6. ОБРАБОТЧИКИ КНОПОК
-- =============================================
flyBtn.MouseButton1Click:Connect(toggleFly)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)
antiPlayerBtn.MouseButton1Click:Connect(toggleAntiPlayer)
teleportBtn.MouseButton1Click:Connect(toggleTeleport)

-- Кнопка кражи (только если доступна)
if hasInventorySystem then
    stealBtn.MouseButton1Click:Connect(toggleStealItems)
else
    -- Если система недоступна, показываем сообщение при нажатии
    stealBtn.MouseButton1Click:Connect(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ СИСТЕМА НЕДОСТУПНА",
            Text = "В этой игре нет системы инвентаря",
            Duration = 3
        })
    end)
end

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
    -- Отключаем все системы
    if flyEnabled then toggleFly() end
    if godModeEnabled then toggleGodMode() end
    if antiPlayerEnabled then toggleAntiPlayer() end
    if teleportClickEnabled then toggleTeleport() end
    if stealItemsEnabled and hasInventorySystem then toggleStealItems() end
    
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
    elseif input.KeyCode == Enum.KeyCode.R then
        toggleAntiPlayer()
    elseif input.KeyCode == Enum.KeyCode.T then
        toggleTeleport()
    elseif input.KeyCode == Enum.KeyCode.V and hasInventorySystem then
        toggleStealItems()
    elseif input.KeyCode == Enum.KeyCode.E then
        flightSpeed = math.min(flightSpeed + 10, 200)
        speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        flightSpeed = math.max(flightSpeed - 10, 10)
        speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
    end
end)

-- =============================================
-- 8. АВТООБНОВЛЕНИЕ ПРИ СМЕНЕ ПЕРСОНАЖА
-- =============================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    
    -- Ждем загрузки
    wait(0.5)
    
    -- Переподключаем активные функции
    if godModeEnabled then
        toggleGodMode()
        wait(0.1)
        toggleGodMode()
    end
    
    if antiPlayerEnabled then
        toggleAntiPlayer()
        wait(0.1)
        toggleAntiPlayer()
    end
    
    if flyEnabled then
        toggleFly()
        wait(0.1)
        toggleFly()
    end
end)

-- =============================================
-- 9. ЗАГРУЗОЧНОЕ УВЕДОМЛЕНИЕ
-- =============================================
StarterGui:SetCore("SendNotification", {
    Title = "⚡ ULTIMATE GUI V9",
    Text = hasInventorySystem and "Загружен! V-Кража предметов" or "Загружен! Нет системы инвентаря",
    Duration = 5
})

print("=" .. string.rep("=", 50))
print("✅ ULTIMATE GUI V9 ЗАГРУЖЕН УСПЕШНО!")
print("=" .. string.rep("=", 50))
print("✈️  ПОЛЕТ: F")
print("💀 GOD MODE: G (подземный хитбокс)")
print("⚡ ОТТАЛКИВАНИЕ: R")
print("📍 ТЕЛЕПОРТ ПО КЛИКУ: T")
if hasInventorySystem then
    print("🎒 КРАЖА ПРЕДМЕТОВ: V (ПКМ по игроку)")
else
    print("⚠️ КРАЖА ПРЕДМЕТОВ: НЕДОСТУПНА")
end
print("=" .. string.rep("=", 50))
print("🎮 Управление полетом: WASD + Space/Shift")
print("💨 Скорость полета: E/Q или кнопки + -")
print("=" .. string.rep("=", 50))
