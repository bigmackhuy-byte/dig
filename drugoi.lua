-- Fly GUI V5 - Ultimate Edition
-- Автор: XNEO | Полный функционал

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

-- Эффекты
local forceFieldPart = nil
local flyEffect = nil
local redirectionConnections = {}

-- Создание GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local EffectPart = Instance.new("Part")

-- Настройка GUI
ScreenGui.Name = "FlyGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 180, 255)
MainFrame.BorderSizePixel = 3
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 400, 0, 320)
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
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 40, 255),
            math.min(color.B * 255 + 40, 255)
        ) / 255}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return button
end

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "🚀 FLY GUI ULTIMATE 🛡️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true

-- Создание кнопок
local FlyButton = CreateButton("FlyButton", "🚀 ПОЛЕТ: ВЫКЛ", UDim2.new(0.05, 0, 0.15, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(215, 50, 50))

local UpButton = CreateButton("UpButton", "🔼 ВВЕРХ", UDim2.new(0.55, 0, 0.15, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 180, 50))

local DownButton = CreateButton("DownButton", "🔽 ВНИЗ", UDim2.new(0.05, 0, 0.25, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(200, 100, 50))

local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Name = "SpeedDisplay"
SpeedDisplay.Parent = MainFrame
SpeedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
SpeedDisplay.BorderSizePixel = 0
SpeedDisplay.Position = UDim2.new(0.55, 0, 0.25, 0)
SpeedDisplay.Size = UDim2.new(0.4, 0, 0, 35)
SpeedDisplay.Font = Enum.Font.SourceSansBold
SpeedDisplay.Text = "СКОРОСТЬ: 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDisplay.TextScaled = true

local IncreaseButton = CreateButton("IncreaseBtn", "+", UDim2.new(0.05, 0, 0.35, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(50, 150, 50))

local DecreaseButton = CreateButton("DecreaseBtn", "-", UDim2.new(0.3, 0, 0.35, 0), UDim2.new(0.2, 0, 0, 35), Color3.fromRGB(180, 50, 50))

local ForceFieldButton = CreateButton("ForceFieldBtn", "🛡️ СИЛОВОЕ ПОЛЕ: ВЫКЛ", UDim2.new(0.55, 0, 0.35, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(50, 100, 200))

local DamageRedirectButton = CreateButton("DamageRedirectBtn", "⚡ ПЕРЕНАПРЯВЛЕНИЕ: ВЫКЛ", UDim2.new(0.05, 0, 0.45, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(200, 50, 150))

local NoclipButton = CreateButton("NoclipBtn", "🚫 НОКЛИП: ВЫКЛ", UDim2.new(0.05, 0, 0.55, 0), UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(140, 50, 200))

local SavePosButton = CreateButton("SavePosBtn", "💾 СОХРАНИТЬ ПОЗИЦИЮ", UDim2.new(0.05, 0, 0.65, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(255, 165, 0))

local TeleportButton = CreateButton("TeleportBtn", "📍 ТЕЛЕПОРТ", UDim2.new(0.55, 0, 0.65, 0), UDim2.new(0.4, 0, 0, 35), Color3.fromRGB(0, 180, 255))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "✖", UDim2.new(0.93, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(215, 50, 50))

local MinButton = CreateButton("MinBtn", "➖", UDim2.new(0.86, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(255, 165, 0))

-- Функция исправленного полета
local bodyGyro, bodyVelocity
local flyConnection

local function ToggleFly()
    if not character or not humanoidRootPart then
        return
    end
    
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        FlyButton.Text = "🚀 ПОЛЕТ: ВКЛ"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        
        humanoid.PlatformStand = true
        
        -- Создаем объекты для полета
        bodyGyro = Instance.new("BodyGyro")
        bodyVelocity = Instance.new("BodyVelocity")
        
        bodyGyro.Parent = humanoidRootPart
        bodyVelocity.Parent = humanoidRootPart
        
        bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
        bodyGyro.P = 100000
        bodyGyro.D = 1000
        bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        -- Создаем визуальный эффект полета
        if not flyEffect then
            flyEffect = Instance.new("ParticleEmitter")
            flyEffect.Parent = humanoidRootPart
            flyEffect.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
            flyEffect.LightEmission = 0.5
            flyEffect.Size = NumberSequence.new(0.5)
            flyEffect.Texture = "rbxassetid://242842579"
            flyEffect.Transparency = NumberSequence.new(0.5)
            flyEffect.Rate = 50
            flyEffect.Lifetime = NumberRange.new(0.5)
            flyEffect.Speed = NumberRange.new(5)
            flyEffect.VelocitySpread = 180
            flyEffect.Rotation = NumberRange.new(0, 360)
        end
        
        -- Обработка полета с правильным направлением
        flyConnection = RunService.Heartbeat:Connect(function(delta)
            if not character or not humanoidRootPart or not flyEnabled then
                return
            end
            
            local camera = workspace.CurrentCamera
            local root = humanoidRootPart
            
            -- Получаем ввод от игрока
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Проверяем клавиши WASD
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
            
            -- Нормализуем направление
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
            end
            
            -- Добавляем вертикальное движение
            if upPressed then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            elseif downPressed then
                moveDirection = moveDirection + Vector3.new(0, -1, 0)
            end
            
            -- Обновляем скорость и направление
            if moveDirection.Magnitude > 0 then
                local velocity = moveDirection * flySpeed
                bodyVelocity.Velocity = velocity
                
                -- Поворачиваем персонажа в направлении движения (кроме вертикального)
                local horizontalDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
                if horizontalDirection.Magnitude > 0.1 then
                    bodyGyro.CFrame = CFrame.new(root.Position, root.Position + horizontalDirection)
                end
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        
    else
        FlyButton.Text = "🚀 ПОЛЕТ: ВЫКЛ"
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
        
        if flyEffect then
            flyEffect:Destroy()
            flyEffect = nil
        end
        
        upPressed = false
        downPressed = false
    end
end

-- Функция силового поля
local forceFieldConnection = nil
local function ToggleForceField()
    forceFieldEnabled = not forceFieldEnabled
    
    if forceFieldEnabled then
        ForceFieldButton.Text = "🛡️ СИЛОВОЕ ПОЛЕ: ВКЛ"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        
        -- Создаем визуальное силовое поле
        forceFieldPart = Instance.new("Part")
        forceFieldPart.Name = "ForceField"
        forceFieldPart.Size = Vector3.new(15, 15, 15)
        forceFieldPart.Shape = Enum.PartType.Ball
        forceFieldPart.Transparency = 0.7
        forceFieldPart.Material = EnumMaterial.Neon
        forceFieldPart.Color = Color3.fromRGB(0, 150, 255)
        forceFieldPart.CanCollide = false
        forceFieldPart.Anchored = false
        forceFieldPart.Parent = workspace
        
        local weld = Instance.new("Weld")
        weld.Part0 = humanoidRootPart
        weld.Part1 = forceFieldPart
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = forceFieldPart
        
        -- Эффект частиц
        local particles = Instance.new("ParticleEmitter")
        particles.Parent = forceFieldPart
        particles.Color = ColorSequence.new(Color3.fromRGB(0, 100, 255))
        particles.LightEmission = 0.8
        particles.Size = NumberSequence.new(0.3)
        particles.Texture = "rbxassetid://242842579"
        particles.Transparency = NumberSequence.new(0.3)
        particles.Rate = 100
        particles.Lifetime = NumberRange.new(0.5)
        particles.Speed = NumberRange.new(2)
        
        -- Отталкивание игроков
        forceFieldConnection = RunService.Heartbeat:Connect(function()
            if not character or not humanoidRootPart or not forceFieldEnabled then
                return
            end
            
            local myPosition = humanoidRootPart.Position
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherCharacter = otherPlayer.Character
                    if otherCharacter then
                        local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
                        local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
                        
                        if otherHumanoid and otherRoot and otherHumanoid.Health > 0 then
                            local distance = (myPosition - otherRoot.Position).Magnitude
                            
                            -- Если игрок слишком близко, отталкиваем его
                            if distance < 15 then
                                local direction = (otherRoot.Position - myPosition).Unit
                                local force = direction * 100 * (1 - distance/15)
                                
                                -- Применяем импульс
                                local bodyVelocity = Instance.new("BodyVelocity")
                                bodyVelocity.Velocity = force
                                bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                                bodyVelocity.Parent = otherRoot
                                Debris:AddItem(bodyVelocity, 0.1)
                            end
                        end
                    end
                end
            end
        end)
        
    else
        ForceFieldButton.Text = "🛡️ СИЛОВОЕ ПОЛЕ: ВЫКЛ"
        ForceFieldButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        
        if forceFieldConnection then
            forceFieldConnection:Disconnect()
            forceFieldConnection = nil
        end
        
        if forceFieldPart then
            forceFieldPart:Destroy()
            forceFieldPart = nil
        end
    end
end

-- Функция перенаправления урона
local function ToggleDamageRedirect()
    damageRedirectEnabled = not damageRedirectEnabled
    
    if damageRedirectEnabled then
        DamageRedirectButton.Text = "⚡ ПЕРЕНАПРЯВЛЕНИЕ: ВКЛ"
        DamageRedirectButton.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
        
        -- Защищаем от урона
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        
        -- Создаем эффект защиты
        local shieldEffect = Instance.new("ForceField")
        shieldEffect.Visible = false
        shieldEffect.Parent = character
        
        -- Перехватываем получение урона
        for _, connection in pairs(redirectionConnections) do
            connection:Disconnect()
        end
        redirectionConnections = {}
        
        -- Мониторинг урона
        local function redirectDamage(damage)
            if not damageRedirectEnabled or not character then return end
            
            -- Ищем ближайшего игрока
            local closestPlayer = nil
            local closestDistance = math.huge
            local myPosition = humanoidRootPart.Position
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherCharacter = otherPlayer.Character
                    if otherCharacter then
                        local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
                        local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
                        
                        if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
                            local distance = (myPosition - otherRoot.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = otherPlayer
                            end
                        end
                    end
                end
            end
            
            -- Перенаправляем урон
            if closestPlayer then
                local otherCharacter = closestPlayer.Character
                if otherCharacter then
                    local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
                    if otherHumanoid then
                        -- Наносим урон другому игроку
                        otherHumanoid:TakeDamage(damage)
                        
                        -- Визуальный эффект
                        local beam = Instance.new("Beam")
                        beam.Attachment0 = Instance.new("Attachment")
                        beam.Attachment0.Parent = humanoidRootPart
                        beam.Attachment1 = Instance.new("Attachment")
                        beam.Attachment1.Parent = otherCharacter:FindFirstChild("HumanoidRootPart")
                        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                        beam.Width0 = 0.5
                        beam.Width1 = 0.5
                        beam.Parent = workspace
                        
                        Debris:AddItem(beam.Attachment0, 0.5)
                        Debris:AddItem(beam.Attachment1, 0.5)
                        Debris:AddItem(beam, 0.5)
                    end
                end
            end
        end
        
        -- Отслеживаем получение урона
        table.insert(redirectionConnections, humanoid.HealthChanged:Connect(function(health)
            if health < humanoid.MaxHealth then
                local damage = humanoid.MaxHealth - health
                humanoid.Health = humanoid.MaxHealth
                redirectDamage(damage)
            end
        end))
        
        table.insert(redirectionConnections, humanoid.Touched:Connect(function(part)
            if part:IsA("BasePart") and part.Parent ~= character then
                -- Проверяем, может ли часть наносить урон
                local humanoidFromPart = part.Parent:FindFirstChild("Humanoid")
                if not humanoidFromPart then
                    humanoidFromPart = part.Parent.Parent:FindFirstChild("Humanoid")
                end
                
                if humanoidFromPart then
                    redirectDamage(10) -- Стандартный урон при касании
                end
            end
        end))
        
    else
        DamageRedirectButton.Text = "⚡ ПЕРЕНАПРЯВЛЕНИЕ: ВЫКЛ"
        DamageRedirectButton.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
        
        -- Восстанавливаем нормальное здоровье
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        
        -- Отключаем все соединения
        for _, connection in pairs(redirectionConnections) do
            connection:Disconnect()
        end
        redirectionConnections = {}
    end
end

-- Функция ноклипа
local function ToggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        NoclipButton.Text = "🚫 НОКЛИП: ВКЛ"
        NoclipButton.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
    else
        NoclipButton.Text = "🚫 НОКЛИП: ВЫКЛ"
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
    SpeedDisplay.Text = "СКОРОСТЬ: " .. displaySpeed
end)

DecreaseButton.MouseButton1Click:Connect(function()
    displaySpeed = displaySpeed - 1
    if displaySpeed < 1 then displaySpeed = 1 end
    flySpeed = displaySpeed * 10
    SpeedDisplay.Text = "СКОРОСТЬ: " .. displaySpeed
end)

ForceFieldButton.MouseButton1Click:Connect(ToggleForceField)
DamageRedirectButton.MouseButton1Click:Connect(ToggleDamageRedirect)
NoclipButton.MouseButton1Click:Connect(ToggleNoclip)

SavePosButton.MouseButton1Click:Connect(function()
    if character and humanoidRootPart then
        savedPosition = humanoidRootPart.CFrame
        SavePosButton.Text = "✓ СОХРАНЕНО!"
        
        task.wait(2)
        if SavePosButton then
            SavePosButton.Text = "💾 СОХРАНИТЬ ПОЗИЦИЮ"
        end
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if savedPosition and character and humanoidRootPart then
        humanoidRootPart.CFrame = savedPosition
        TeleportButton.Text = "✓ ТЕЛЕПОРТИРОВАН!"
        
        task.wait(2)
        if TeleportButton then
            TeleportButton.Text = "📍 ТЕЛЕПОРТ"
        end
    else
        TeleportButton.Text = "НЕТ СОХРАНЕННОЙ ПОЗИЦИИ!"
        
        task.wait(2)
        if TeleportButton then
            TeleportButton.Text = "📍 ТЕЛЕПОРТ"
        end
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinButton.Text = MainFrame.Visible and "➖" or "➕"
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
        SpeedDisplay.Text = "СКОРОСТЬ: " .. displaySpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        displaySpeed = displaySpeed - 1
        if displaySpeed < 1 then displaySpeed = 1 end
        flySpeed = displaySpeed * 10
        SpeedDisplay.Text = "СКОРОСТЬ: " .. displaySpeed
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

-- Обработка смерти персонажа
local function OnCharacterDeath()
    -- Отключаем полет
    if flyEnabled then
        ToggleFly()
    end
    
    -- Отключаем силовое поле
    if forceFieldEnabled then
        ToggleForceField()
    end
    
    -- Отключаем перенаправление урона
    if damageRedirectEnabled then
        ToggleDamageRedirect()
    end
    
    -- Отключаем ноклип
    if noclipEnabled then
        ToggleNoclip()
    end
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
    Title = "FLY GUI ULTIMATE",
    Text = "Полный функционал активирован!\nF - полет, E/Q - скорость\nR - силовое поле, T - перенаправление\nY - ноклип, Space/Ctrl - высота",
    Duration = 7,
    Icon = "rbxassetid://4483345998"
})

print("✅ Fly GUI Ultimate успешно загружен!")
print("📋 Функции:")
print("   🚀 Полет с правильным направлением")
print("   🛡️ Силовое поле (отталкивает игроков)")
print("   ⚡ Перенаправление урона (на ближайшего игрока)")
print("   🚫 Ноклип")
print("   💾 Сохранение/телепортация позиций")
