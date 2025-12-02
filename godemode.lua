-- Ultimate GUI V4 - Fly, Noclip, Invisibility, God Mode
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
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

-- Переменные
local flyEnabled = false
local flightSpeed = 50
local noclipEnabled = false
local invisibilityEnabled = false
local godModeEnabled = false
local savedPosition = nil

-- Переменные для восстановления
local originalTransparency = {}
local originalHealth = 100
local godModeConnection = nil

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V4"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Active = true
mainFrame.Draggable = true

-- Функция для создания элементов
local function createLabel(parent, text, position, size)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
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
    button.TextSize = 14
    
    -- Эффекты при наведении
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor or Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 40, 255),
            math.min(color.B * 255 + 40, 255)
        ) / 255
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = color
    end)
    
    return button
end

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
title.BorderSizePixel = 0
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 40)
title.Font = Enum.Font.SourceSansBold
title.Text = "🔥 ULTIMATE GUI V4 🔥"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.TextScaled = true

-- Разделитель
local divider = Instance.new("Frame")
divider.Parent = mainFrame
divider.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0.05, 0, 0.12, 0)
divider.Size = UDim2.new(0.9, 0, 0, 2)

-- Секция полета
createLabel(mainFrame, "✈️ FLIGHT CONTROLS", UDim2.new(0.05, 0, 0.15, 0), UDim2.new(0.9, 0, 0, 25))

local flyBtn = createButton(mainFrame, "FLY: OFF", UDim2.new(0.05, 0, 0.22, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(200, 50, 50), Color3.fromRGB(230, 70, 70))

local speedDisplay = createLabel(mainFrame, "SPEED: 50", UDim2.new(0.52, 0, 0.22, 0), UDim2.new(0.43, 0, 0, 40))
speedDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
speedDisplay.TextScaled = true

local speedUpBtn = createButton(mainFrame, "▲ SPEED +", UDim2.new(0.05, 0, 0.32, 0), 
    UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(50, 180, 50), Color3.fromRGB(70, 200, 70))

local speedDownBtn = createButton(mainFrame, "▼ SPEED -", UDim2.new(0.52, 0, 0.32, 0), 
    UDim2.new(0.43, 0, 0, 35), Color3.fromRGB(180, 50, 50), Color3.fromRGB(200, 70, 70))

-- Секция способностей
createLabel(mainFrame, "🛡️ ABILITIES", UDim2.new(0.05, 0, 0.43, 0), UDim2.new(0.9, 0, 0, 25))

local noclipBtn = createButton(mainFrame, "🚫 NOCLIP: OFF", UDim2.new(0.05, 0, 0.5, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(150, 50, 200), Color3.fromRGB(180, 70, 220))

local invisibilityBtn = createButton(mainFrame, "👻 INVISIBLE: OFF", UDim2.new(0.52, 0, 0.5, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(100, 100, 100), Color3.fromRGB(150, 150, 150))

local godModeBtn = createButton(mainFrame, "💪 GOD MODE: OFF", UDim2.new(0.05, 0, 0.6, 0), 
    UDim2.new(0.9, 0, 0, 40), Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 140, 40))

-- Секция позиции
createLabel(mainFrame, "📍 POSITION", UDim2.new(0.05, 0, 0.73, 0), UDim2.new(0.9, 0, 0, 25))

local savePosBtn = createButton(mainFrame, "💾 SAVE POSITION", UDim2.new(0.05, 0, 0.8, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 185, 40))

local loadPosBtn = createButton(mainFrame, "🚀 LOAD POSITION", UDim2.new(0.52, 0, 0.8, 0), 
    UDim2.new(0.43, 0, 0, 40), Color3.fromRGB(0, 140, 255), Color3.fromRGB(40, 170, 255))

-- Кнопки управления окном
local closeBtn = createButton(mainFrame, "✕", UDim2.new(0.9, -30, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(200, 0, 0), Color3.fromRGB(230, 30, 30))

local minBtn = createButton(mainFrame, "−", UDim2.new(0.9, -65, 0.02, 0), 
    UDim2.new(0, 30, 0, 30), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 185, 40))

-- Секция информации
local infoLabel = createLabel(mainFrame, "ℹ️ PRESS F: Fly | T: Noclip | G: God Mode | I: Invisible", 
    UDim2.new(0.05, 0, 0.92, 0), UDim2.new(0.9, 0, 0, 25))
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
infoLabel.TextScaled = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ФУНКЦИИ -----------------------------------------------------------------

-- 1. ФУНКЦИЯ ПОЛЕТА
local flyBodyGyro, flyBodyVelocity, flyConnection

local function startFlying()
    if not character then return end
    
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
        if not character or not flyEnabled then return end
        
        local cam = workspace.CurrentCamera
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local direction = Vector3.new(0, 0, 0)
        
        -- Обработка клавиш WASD
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
    flyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
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
    flyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end

local function toggleFly()
    if flyEnabled then
        stopFlying()
    else
        startFlying()
    end
end

-- 2. ФУНКЦИЯ НОКЛИПА
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        noclipBtn.Text = "🚫 NOCLIP: ON"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 220)
        
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
    else
        noclipBtn.Text = "🚫 NOCLIP: OFF"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
        
        -- Возвращаем коллизию
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- 3. ФУНКЦИЯ НЕВИДИМОСТИ
local function toggleInvisibility()
    invisibilityEnabled = not invisibilityEnabled
    
    if invisibilityEnabled then
        invisibilityBtn.Text = "👻 INVISIBLE: ON"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        
        -- Сохраняем оригинальную прозрачность
        originalTransparency = {}
        
        -- Делаем все части невидимыми
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalTransparency[part] = part.Transparency
                    part.Transparency = 1 -- Полностью прозрачный
                elseif part:IsA("Decal") then
                    originalTransparency[part] = part.Transparency
                    part.Transparency = 1
                end
            end
            
            -- Также скрываем одежду и аксессуары
            for _, accessory in pairs(character:GetChildren()) do
                if accessory:IsA("Accessory") then
                    local handle = accessory:FindFirstChild("Handle")
                    if handle then
                        originalTransparency[handle] = handle.Transparency
                        handle.Transparency = 1
                    end
                end
            end
        end
    else
        invisibilityBtn.Text = "👻 INVISIBLE: OFF"
        invisibilityBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        
        -- Восстанавливаем видимость
        if character then
            for part, transparency in pairs(originalTransparency) do
                if part and part.Parent then
                    part.Transparency = transparency
                end
            end
            originalTransparency = {}
        end
    end
end

-- 4. ФУНКЦИЯ GOD MODE (восстановление здоровья каждую секунду)
local function toggleGodMode()
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💪 GOD MODE: ON"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
        
        -- Сохраняем оригинальное здоровье
        originalHealth = humanoid.Health
        
        -- Включаем бессмертие
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = humanoid.MaxHealth
        end
        
        -- Запускаем восстановление здоровья каждую секунду
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not character or not humanoid then
                return
            end
            
            -- Восстанавливаем здоровье до максимума
            humanoid.Health = humanoid.MaxHealth
            
            -- Также защищаем от смерти (на всякий случай)
            if humanoid.Health <= 0 then
                humanoid.Health = humanoid.MaxHealth
            end
            
            -- Защита от урона (если возможно)
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        
        -- Дополнительная защита: предотвращаем смерть
        humanoid.BreakJointsOnDeath = false
        humanoid.Died:Connect(function()
            if godModeEnabled then
                wait(0.1)
                if humanoid then
                    humanoid.Health = humanoid.MaxHealth
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
        
        print("✅ God Mode активирован! Вы бессмертны.")
        
    else
        godModeBtn.Text = "💪 GOD MODE: OFF"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        
        -- Отключаем соединение
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        -- Возвращаем нормальное здоровье
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = originalHealth
            humanoid.BreakJointsOnDeath = true
        end
        
        print("❌ God Mode деактивирован.")
    end
end

-- 5. ФУНКЦИИ СОХРАНЕНИЯ ПОЗИЦИИ
savePosBtn.MouseButton1Click:Connect(function()
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            savedPosition = rootPart.CFrame
            savePosBtn.Text = "✓ POSITION SAVED"
            
            -- Возвращаем текст через 2 секунды
            delay(2, function()
                savePosBtn.Text = "💾 SAVE POSITION"
            end)
            
            print("📍 Позиция сохранена!")
        end
    end
end)

loadPosBtn.MouseButton1Click:Connect(function()
    if savedPosition and character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = savedPosition
            loadPosBtn.Text = "✓ TELEPORTED!"
            
            delay(2, function()
                loadPosBtn.Text = "🚀 LOAD POSITION"
            end)
            
            print("🚀 Телепортирован на сохраненную позицию!")
        end
    else
        loadPosBtn.Text = "❌ NO POSITION"
        
        delay(2, function()
            loadPosBtn.Text = "🚀 LOAD POSITION"
        end)
    end
end)

-- 6. УПРАВЛЕНИЕ ОКНОМ
closeBtn.MouseButton1Click:Connect(function()
    -- Отключаем все функции перед закрытием
    if flyEnabled then stopFlying() end
    if godModeEnabled then 
        godModeEnabled = false
        if godModeConnection then
            godModeConnection:Disconnect()
        end
    end
    
    screenGui:Destroy()
    print("📌 GUI закрыт.")
end)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minBtn.Text = mainFrame.Visible and "−" or "+"
end)

-- 7. ГОРЯЧИЕ КЛАВИШИ
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
    elseif input.KeyCode == Enum.KeyCode.E then
        flightSpeed = math.min(flightSpeed + 10, 200)
        speedDisplay.Text = "SPEED: " .. flightSpeed
    elseif input.KeyCode == Enum.KeyCode.Q then
        flightSpeed = math.max(flightSpeed - 10, 10)
        speedDisplay.Text = "SPEED: " .. flightSpeed
    end
end)

-- Кнопки управления скоростью
speedUpBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.min(flightSpeed + 10, 200)
    speedDisplay.Text = "SPEED: " .. flightSpeed
end)

speedDownBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.max(flightSpeed - 10, 10)
    speedDisplay.Text = "SPEED: " .. flightSpeed
end)

-- 8. ОБРАБОТЧИКИ ОСНОВНЫХ КНОПОК
flyBtn.MouseButton1Click:Connect(toggleFly)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)
invisibilityBtn.MouseButton1Click:Connect(toggleInvisibility)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)

-- 9. АВТООБНОВЛЕНИЕ ПЕРСОНАЖА
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    
    -- Переподключаем God Mode если он был включен
    if godModeEnabled then
        wait(0.5)
        toggleGodMode() -- Выключаем и включаем заново
        toggleGodMode()
    end
end)

-- 10. УВЕДОМЛЕНИЕ ПРИ ЗАГРУЗКЕ
StarterGui:SetCore("SendNotification", {
    Title = "🔥 ULTIMATE GUI V4",
    Text = "Успешно загружен!\nF - Полет | T - Ноклип\nG - God Mode | I - Невидимость",
    Icon = "rbxassetid://6726578081",
    Duration = 8
})

-- 11. ИНФОРМАЦИЯ В КОНСОЛЬ
print("=" .. string.rep("=", 50))
print("🔥 ULTIMATE GUI V4 ЗАГРУЖЕН!")
print("=" .. string.rep("=", 50))
print("✈️  ПОЛЕТ: F")
print("🚫 НОКЛИП: T")
print("💪 GOD MODE: G (восстановление здоровья каждую секунду)")
print("👻 НЕВИДИМОСТЬ: I")
print("➕ СКОРОСТЬ +: E")
print("➖ СКОРОСТЬ -: Q")
print("=" .. string.rep("=", 50))
print("🎮 Управление полетом: WASD + Space/Shift")
print("💾 Сохранение позиции: Кнопка SAVE")
print("🚀 Телепорт: Кнопка LOAD")
print("=" .. string.rep("=", 50))

-- 12. ДОПОЛНИТЕЛЬНАЯ ЗАЩИТА ДЛЯ GOD MODE
-- Проверяем здоровье каждые 0.5 секунд
spawn(function()
    while wait(0.5) do
        if godModeEnabled and humanoid then
            -- Если здоровье упало ниже максимума, восстанавливаем
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            
            -- Если персонаж "умер", воскрешаем
            if humanoid.Health <= 0 then
                humanoid.Health = humanoid.MaxHealth
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)
