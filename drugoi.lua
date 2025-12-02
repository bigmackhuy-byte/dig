-- Fly GUI V8 - The Strongest Battlegrounds Ultimate Edition + KillAura
-- Автор: XNEO | Полный функционал для TS Battlegrounds

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
local ultChargeEnabled = false
local killAuraEnabled = false
local savedPosition = nil
local upPressed = false
local downPressed = false
local ultCharge = 0
local maxUltCharge = 100
local killAuraRange = 25
local killAuraDamage = 25

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyGUITS"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 3
MainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 420)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

-- Скругление углов
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Title.BackgroundTransparency = 0
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Font = Enum.Font.GothamBlack
Title.Text = "⚔️ TS BATTLEGROUND HACK ⚔️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextScaled = false

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

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
    button.TextSize = 13
    button.AutoButtonColor = false
    button.TextScaled = false
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = button
    
    local textPadding = Instance.new("UITextSizeConstraint")
    textPadding.Parent = button
    textPadding.MaxTextSize = 13
    
    -- Эффекты при наведении
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(color.R * 255 + 50, 255),
                math.min(color.G * 255 + 50, 255),
                math.min(color.B * 255 + 50, 255)
            ) / 255,
            TextColor3 = Color3.fromRGB(255, 255, 200)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = color,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = size - UDim2.new(0, 5, 0, 5),
            BackgroundColor3 = Color3.fromRGB(
                math.max(color.R * 255 - 30, 0),
                math.max(color.G * 255 - 30, 0),
                math.max(color.B * 255 - 30, 0)
            ) / 255
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = size,
            BackgroundColor3 = color
        }):Play()
    end)
    
    return button
end

-- Создание кнопок
local FlyButton = CreateButton("FlyButton", "🚀 FLY: OFF", UDim2.new(0.05, 0, 0.13, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(200, 50, 50))

local UpButton = CreateButton("UpButton", "🔼 UP", UDim2.new(0.55, 0, 0.13, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 170, 50))

local DownButton = CreateButton("DownButton", "🔽 DOWN", UDim2.new(0.05, 0, 0.22, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(220, 120, 50))

local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Name = "SpeedDisplay"
SpeedDisplay.Parent = MainFrame
SpeedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
SpeedDisplay.BorderSizePixel = 0
SpeedDisplay.Position = UDim2.new(0.55, 0, 0.22, 0)
SpeedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
SpeedDisplay.Font = Enum.Font.GothamBold
SpeedDisplay.Text = "SPEED: 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDisplay.TextSize = 14

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 8)
SpeedCorner.Parent = SpeedDisplay

local IncreaseButton = CreateButton("IncreaseBtn", "+", UDim2.new(0.05, 0, 0.31, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(50, 150, 50))

local DecreaseButton = CreateButton("DecreaseBtn", "-", UDim2.new(0.3, 0, 0.31, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(180, 50, 50))

local ForceFieldButton = CreateButton("ForceFieldBtn", "🛡️ FIELD: OFF", UDim2.new(0.55, 0, 0.31, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 100, 200))

local DamageRedirectButton = CreateButton("DamageRedirectBtn", "⚡ REDIRECT: OFF", UDim2.new(0.05, 0, 0.4, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(180, 50, 150))

local NoclipButton = CreateButton("NoclipBtn", "🚫 NOCLIP: OFF", UDim2.new(0.05, 0, 0.49, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(130, 50, 200))

local KillAuraButton = CreateButton("KillAuraBtn", "⚔️ KILL AURA: OFF", UDim2.new(0.05, 0, 0.58, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(255, 50, 50))

local UltChargeButton = CreateButton("UltChargeBtn", "⚡ ULT CHARGE: OFF", UDim2.new(0.05, 0, 0.67, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(255, 165, 0))

-- Прогресс бар для ульты
local UltProgressBar = Instance.new("Frame")
UltProgressBar.Name = "UltProgressBar"
UltProgressBar.Parent = MainFrame
UltProgressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
UltProgressBar.BorderSizePixel = 0
UltProgressBar.Position = UDim2.new(0.05, 0, 0.76, 0)
UltProgressBar.Size = UDim2.new(0.9, 0, 0, 20)
UltProgressBar.ClipsDescendants = true

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 6)
ProgressCorner.Parent = UltProgressBar

local UltProgressFill = Instance.new("Frame")
UltProgressFill.Name = "UltProgressFill"
UltProgressFill.Parent = UltProgressBar
UltProgressFill.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
UltProgressFill.BorderSizePixel = 0
UltProgressFill.Size = UDim2.new(0, 0, 1, 0)

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 6)
FillCorner.Parent = UltProgressFill

local UltProgressText = Instance.new("TextLabel")
UltProgressText.Name = "UltProgressText"
UltProgressText.Parent = UltProgressBar
UltProgressText.BackgroundTransparency = 1
UltProgressText.Size = UDim2.new(1, 0, 1, 0)
UltProgressText.Font = Enum.Font.GothamBold
UltProgressText.Text = "ULT: 0%"
UltProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
UltProgressText.TextSize = 12

local SavePosButton = CreateButton("SavePosBtn", "💾 SAVE POS", UDim2.new(0.05, 0, 0.83, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(255, 140, 0))

local TeleportButton = CreateButton("TeleportBtn", "📍 TELEPORT", UDim2.new(0.55, 0, 0.83, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(0, 160, 255))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "✖", UDim2.new(0.92, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(200, 50, 50))

local MinButton = CreateButton("MinBtn", "–", UDim2.new(0.84, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(255, 165, 0))

-- Переменные для функций
local flyConnection = nil
local forceFieldConnection = nil
local ultChargeConnection = nil
local killAuraConnection = nil
local bodyGyro, bodyVelocity

-- Функция обновления прогресс бара ульты
local function UpdateUltProgress()
    local percent = ultCharge / maxUltCharge
    UltProgressFill.Size = UDim2.new(percent, 0, 1, 0)
    UltProgressText.Text = string.format("ULT: %d%%", math.floor(percent * 100))
    
    -- Меняем цвет в зависимости от заряда
    if percent < 0.3 then
        UltProgressFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    elseif percent < 0.6 then
        UltProgressFill.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    elseif percent < 0.9 then
        UltProgressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    else
        UltProgressFill.BackgroundColor3 = Color3.fromRGB(50, 200, 255)
    end
end

-- Исправленный полет
local function ToggleFly()
    if not character or not humanoidRootPart then return end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        FlyButton.Text = "🚀 FLY: ON"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
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
        
        -- Соединение для полета
        flyConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not flyEnabled then return end
            
            local camera = workspace.CurrentCamera
            local root = humanoidRootPart
            
            -- Получаем направление от камеры
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local up = Vector3.new(0, 1, 0)
            
            -- Инициализируем направление движения
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Определяем направление по WASD
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + forward
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - forward
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - right
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + right
            end
            
            -- Вертикальное управление
            if upPressed then
                moveDirection = moveDirection + up
            elseif downPressed then
                moveDirection = moveDirection - up
            end
            
            -- Нормализуем и применяем скорость
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
                local velocity = moveDirection * flySpeed
                bodyVelocity.Velocity = velocity
                
                -- Поворачиваем персонажа в направлении горизонтального движения
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

-- Силовое поле
local function ToggleForceField()
    forceFieldEnabled = not forceFieldEnabled
    
    if forceFieldEnabled then
        ForceFieldButton.Text = "🛡️ FIELD: ON"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        
        forceFieldConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not forceFieldEnabled then return end
            
            local myPos = humanoidRootPart.Position
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherChar = otherPlayer.Character
                    if otherChar then
                        local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        
                        if otherRoot and otherHum and otherHum.Health > 0 then
                            local distance = (myPos - otherRoot.Position).Magnitude
                            
                            -- Отталкиваем при приближении
                            if distance < 15 then
                                local direction = (otherRoot.Position - myPos).Unit
                                local pushForce = 25 * (1 - distance/15)
                                
                                local bv = Instance.new("BodyVelocity")
                                bv.Velocity = direction * pushForce
                                bv.MaxForce = Vector3.new(10000, 10000, 10000)
                                bv.Parent = otherRoot
                                Debris:AddItem(bv, 0.1)
                            end
                        end
                    end
                end
            end
        end)
        
    else
        ForceFieldButton.Text = "🛡️ FIELD: OFF"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        
        if forceFieldConnection then
            forceFieldConnection:Disconnect()
            forceFieldConnection = nil
        end
    end
end

-- Перенаправление урона
local function ToggleDamageRedirect()
    damageRedirectEnabled = not damageRedirectEnabled
    
    if damageRedirectEnabled then
        DamageRedirectButton.Text = "⚡ REDIRECT: ON"
        DamageRedirectButton.BackgroundColor3 = Color3.fromRGB(200, 60, 160)
        
        -- Защита от урона
        spawn(function()
            while damageRedirectEnabled and character do
                humanoid.Health = humanoid.MaxHealth
                task.wait(0.1)
            end
        end)
        
        -- Отслеживаем урон
        humanoid.HealthChanged:Connect(function()
            if damageRedirectEnabled and humanoid.Health < humanoid.MaxHealth then
                -- Восстанавливаем здоровье
                humanoid.Health = humanoid.MaxHealth
                
                -- Ищем ближайшего врага
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
                
                -- Наносим урон ближайшему врагу
                if closestPlayer then
                    local otherChar = closestPlayer.Character
                    if otherChar then
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        if otherHum then
                            otherHum:TakeDamage(math.random(20, 40))
                        end
                    end
                end
            end
        end)
        
    else
        DamageRedirectButton.Text = "⚡ REDIRECT: OFF"
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

-- KillAura функция
local function ToggleKillAura()
    killAuraEnabled = not killAuraEnabled
    
    if killAuraEnabled then
        KillAuraButton.Text = "⚔️ KILL AURA: ON"
        KillAuraButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not killAuraEnabled then return end
            
            local myPos = humanoidRootPart.Position
            local hitEnemies = {}
            
            -- Ищем всех врагов в радиусе
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherChar = otherPlayer.Character
                    if otherChar then
                        local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        
                        if otherRoot and otherHum and otherHum.Health > 0 then
                            local distance = (myPos - otherRoot.Position).Magnitude
                            
                            -- Если враг в радиусе атаки
                            if distance <= killAuraRange then
                                table.insert(hitEnemies, {char = otherChar, hum = otherHum, root = otherRoot})
                            end
                        end
                    end
                end
            end
            
            -- Атакуем всех врагов в радиусе
            for _, enemy in pairs(hitEnemies) do
                -- Пытаемся использовать RemoteEvent для атаки
                local success = false
                
                -- Ищем RemoteEvent для атаки в ReplicatedStorage
                for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("RemoteEvent") then
                        local name = obj.Name:lower()
                        if name:find("attack") or name:find("hit") or name:find("damage") or name:find("punch") then
                            pcall(function()
                                -- Пробуем разные варианты аргументов
                                obj:FireServer(enemy.char, killAuraDamage)
                                obj:FireServer(enemy.char)
                                obj:FireServer("Attack", enemy.char)
                                success = true
                            end)
                        end
                    end
                end
                
                -- Если не нашли RemoteEvent, наносим урон напрямую
                if not success then
                    pcall(function()
                        enemy.hum:TakeDamage(killAuraDamage)
                    end)
                end
                
                -- Визуальный эффект удара
                local hitEffect = Instance.new("Part")
                hitEffect.Size = Vector3.new(1, 1, 1)
                hitEffect.Position = enemy.root.Position
                hitEffect.Transparency = 0.5
                hitEffect.Color = Color3.fromRGB(255, 50, 50)
                hitEffect.Material = EnumMaterial.Neon
                hitEffect.Anchored = true
                hitEffect.CanCollide = false
                hitEffect.Parent = workspace
                
                Debris:AddItem(hitEffect, 0.3)
            end
        end)
        
        -- Визуальный эффект KillAura
        local auraEffect = Instance.new("Part")
        auraEffect.Name = "KillAuraEffect"
        auraEffect.Shape = Enum.PartType.Ball
        auraEffect.Size = Vector3.new(killAuraRange * 2, killAuraRange * 2, killAuraRange * 2)
        auraEffect.Transparency = 0.8
        auraEffect.Color = Color3.fromRGB(255, 0, 0)
        auraEffect.Material = EnumMaterial.Neon
        auraEffect.CanCollide = false
        auraEffect.Anchored = false
        auraEffect.Parent = character
        
        local weld = Instance.new("Weld")
        weld.Part0 = humanoidRootPart
        weld.Part1 = auraEffect
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = auraEffect
        
    else
        KillAuraButton.Text = "⚔️ KILL AURA: OFF"
        KillAuraButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        
        if killAuraConnection then
            killAuraConnection:Disconnect()
            killAuraConnection = nil
        end
        
        -- Удаляем визуальный эффект
        if character then
            local auraEffect = character:FindFirstChild("KillAuraEffect")
            if auraEffect then
                auraEffect:Destroy()
            end
        end
    end
end

-- Функция зарядки ульты
local function ToggleUltCharge()
    ultChargeEnabled = not ultChargeEnabled
    
    if ultChargeEnabled then
        UltChargeButton.Text = "⚡ ULT CHARGE: ON"
        UltChargeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        
        ultChargeConnection = RunService.Heartbeat:Connect(function()
            if not ultChargeEnabled then return end
            
            -- Увеличиваем заряд ульты
            ultCharge = math.min(maxUltCharge, ultCharge + 1)
            UpdateUltProgress()
            
            -- Когда ульта полностью заряжена
            if ultCharge >= maxUltCharge then
                -- Пробуем найти и активировать ульту
                local activated = false
                
                -- Ищем RemoteEvent для ульты
                for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("RemoteEvent") then
                        local name = obj.Name:lower()
                        if name:find("ult") or name:find("ability") or name:find("skill") or name:find("special") then
                            pcall(function()
                                obj:FireServer()
                                activated = true
                            end)
                        end
                    end
                end
                
                -- Ищем BindableEvent
                if not activated then
                    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                        if obj:IsA("BindableEvent") then
                            local name = obj.Name:lower()
                            if name:find("ult") or name:find("ability") then
                                pcall(function()
                                    obj:Fire()
                                    activated = true
                                end)
                            end
                        end
                    end
                end
                
                -- Визуальный эффект
                if activated then
                    StarterGui:SetCore("SendNotification", {
                        Title = "⚡ ULTIMATE ACTIVATED",
                        Text = "Special ability used!",
                        Duration = 2,
                        Icon = "rbxassetid://4483345998"
                    })
                end
                
                -- Сбрасываем заряд
                ultCharge = 0
                UpdateUltProgress()
            end
        end)
        
    else
        UltChargeButton.Text = "⚡ ULT CHARGE: OFF"
        UltChargeButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        
        if ultChargeConnection then
            ultChargeConnection:Disconnect()
            ultChargeConnection = nil
        end
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
    if displaySpeed > 15 then displaySpeed = 15 end
    flySpeed = displaySpeed * 12
    SpeedDisplay.Text = "SPEED: " .. displaySpeed
end)

DecreaseButton.MouseButton1Click:Connect(function()
    displaySpeed = displaySpeed - 1
    if displaySpeed < 1 then displaySpeed = 1 end
    flySpeed = displaySpeed * 12
    SpeedDisplay.Text = "SPEED: " .. displaySpeed
end)

ForceFieldButton.MouseButton1Click:Connect(ToggleForceField)
DamageRedirectButton.MouseButton1Click:Connect(ToggleDamageRedirect)
NoclipButton.MouseButton1Click:Connect(ToggleNoclip)
KillAuraButton.MouseButton1Click:Connect(ToggleKillAura)
UltChargeButton.MouseButton1Click:Connect(ToggleUltCharge)

SavePosButton.MouseButton1Click:Connect(function()
    if character and humanoidRootPart then
        savedPosition = humanoidRootPart.CFrame
        SavePosButton.Text = "✓ SAVED!"
        task.wait(2)
        SavePosButton.Text = "💾 SAVE POS"
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if savedPosition and character and humanoidRootPart then
        humanoidRootPart.CFrame = savedPosition
        TeleportButton.Text = "✓ TELEPORT!"
        task.wait(2)
        TeleportButton.Text = "📍 TELEPORT"
    else
        TeleportButton.Text = "NO POSITION!"
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
        displaySpeed = math.min(15, displaySpeed + 1)
        flySpeed = displaySpeed * 12
        SpeedDisplay.Text = "SPEED: " .. displaySpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        displaySpeed = math.max(1, displaySpeed - 1)
        flySpeed = displaySpeed * 12
        SpeedDisplay.Text = "SPEED: " .. displaySpeed
    elseif input.KeyCode == Enum.KeyCode.R then
        ToggleForceField()
    elseif input.KeyCode == Enum.KeyCode.T then
        ToggleDamageRedirect()
    elseif input.KeyCode == Enum.KeyCode.Y then
        ToggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.K then
        ToggleKillAura()
    elseif input.KeyCode == Enum.KeyCode.U then
        ToggleUltCharge()
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
humanoid.Died:Connect(function()
    if flyEnabled then ToggleFly() end
    if forceFieldEnabled then ToggleForceField() end
    if damageRedirectEnabled then ToggleDamageRedirect() end
    if noclipEnabled then ToggleNoclip() end
    if killAuraEnabled then ToggleKillAura() end
    if ultChargeEnabled then ToggleUltCharge() end
    ultCharge = 0
    UpdateUltProgress()
end)

-- Обработка респавна
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    
    task.wait(1)
    
    -- Сбрасываем состояния
    if flyEnabled then
        FlyButton.Text = "🚀 FLY: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        flyEnabled = false
    end
end)

-- Уведомление о загрузке
task.wait(2)
StarterGui:SetCore("SendNotification", {
    Title = "⚔️ TS BATTLEGROUND HACK",
    Text = "Fully loaded! All features active\nF - Fly, E/Q - Speed, R - Field\nT - Redirect, Y - Noclip, K - KillAura\nU - Ult Charge, Space/Ctrl - Height",
    Duration = 8,
    Icon = "rbxassetid://4483345998"
})

print("✅ TS Battleground Hack v8 loaded!")
print("📋 Features:")
print("   🚀 Fly System (Fixed direction)")
print("   🛡️ Force Field (Push enemies)")
print("   ⚡ Damage Redirect (God mode + enemy damage)")
print("   🚫 Noclip (Walk through walls)")
print("   ⚔️ KillAura (Auto-attack in 25 stud radius)")
print("   ⚡ Ultimate Charge (Auto-use abilities)")
print("   💾 Save/Teleport positions")
