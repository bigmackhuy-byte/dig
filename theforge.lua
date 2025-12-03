-- AFK Mining Bot for The Forge (Beta)
-- Автор: XNEO | Автоматический фарм ресурсов

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Переменные
local miningEnabled = false
local selectedOres = {}
local miningRange = 25
local miningSpeed = 2
local teleportToOres = true
local closestOre = nil
local lastOrePosition = nil
local blacklistedOres = {}
local oreBlacklistTime = 30 -- Секунд в черном списке

-- Обычные руды в The Forge
local defaultOres = {
    "Stone",
    "Coal",
    "Copper",
    "Iron",
    "Gold",
    "Diamond",
    "Emerald",
    "Ruby",
    "Sapphire",
    "Mithril",
    "Adamantite",
    "Titanium",
    "Obsidian",
    "Crystal"
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForgeMiningBot"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderColor3 = Color3.fromRGB(200, 100, 0)
MainFrame.BorderSizePixel = 3
MainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

-- Скругление углов
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
Title.BackgroundTransparency = 0
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚒️ FORGE MINING BOT ⚒️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
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
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.AutoButtonColor = false
    button.TextScaled = false
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = button
    
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.Parent = button
    textConstraint.MaxTextSize = 13
    
    -- Эффекты при наведении
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(color.R * 255 + 40, 255),
                math.min(color.G * 255 + 40, 255),
                math.min(color.B * 255 + 40, 255)
            ) / 255
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = color
        }):Play()
    end)
    
    return button
end

-- Панель статуса
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
StatusLabel.BorderSizePixel = 0
StatusLabel.Position = UDim2.new(0.05, 0, 0.11, 0)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Статус: Остановлен"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

-- Кнопка старт/стоп
local StartButton = CreateButton("StartButton", "▶️ НАЧАТЬ ФАРМ", UDim2.new(0.05, 0, 0.19, 0), UDim2.new(0.9, 0, 0, 40), Color3.fromRGB(0, 180, 0))

-- Панель выбора руд
local OresFrame = Instance.new("Frame")
OresFrame.Name = "OresFrame"
OresFrame.Parent = MainFrame
OresFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
OresFrame.BorderSizePixel = 0
OresFrame.Position = UDim2.new(0.05, 0, 0.32, 0)
OresFrame.Size = UDim2.new(0.9, 0, 0, 150)
OresFrame.ClipsDescendants = true

local OresCorner = Instance.new("UICorner")
OresCorner.CornerRadius = UDim.new(0, 6)
OresCorner.Parent = OresFrame

local OresScroll = Instance.new("ScrollingFrame")
OresScroll.Name = "OresScroll"
OresScroll.Parent = OresFrame
OresScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
OresScroll.BackgroundTransparency = 1
OresScroll.BorderSizePixel = 0
OresScroll.Position = UDim2.new(0, 5, 0, 5)
OresScroll.Size = UDim2.new(1, -10, 1, -10)
OresScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
OresScroll.ScrollBarThickness = 6

local OresLayout = Instance.new("UIListLayout")
OresLayout.Parent = OresScroll
OresLayout.SortOrder = Enum.SortOrder.LayoutOrder
OresLayout.Padding = UDim.new(0, 5)

-- Кнопки выбора всех/очистки
local SelectAllButton = CreateButton("SelectAllButton", "✓ ВЫБРАТЬ ВСЕ", UDim2.new(0.05, 0, 0.72, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(50, 120, 200))

local ClearSelectionButton = CreateButton("ClearSelectionButton", "✗ ОЧИСТИТЬ ВЫБОР", UDim2.new(0.51, 0, 0.72, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(200, 50, 50))

-- Настройки
local TeleportToggle = CreateButton("TeleportToggle", "⚡ ТЕЛЕПОРТ: ВКЛ", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(100, 50, 200))

local RangeDisplay = Instance.new("TextLabel")
RangeDisplay.Name = "RangeDisplay"
RangeDisplay.Parent = MainFrame
RangeDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
RangeDisplay.BorderSizePixel = 0
RangeDisplay.Position = UDim2.new(0.51, 0, 0.8, 0)
RangeDisplay.Size = UDim2.new(0.44, 0, 0, 30)
RangeDisplay.Font = Enum.Font.Gotham
RangeDisplay.Text = "ДИСТАНЦИЯ: 25"
RangeDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeDisplay.TextSize = 13

local RangeCorner = Instance.new("UICorner")
RangeCorner.CornerRadius = UDim.new(0, 6)
RangeCorner.Parent = RangeDisplay

local IncreaseRangeButton = CreateButton("IncreaseRangeBtn", "+", UDim2.new(0.05, 0, 0.87, 0), UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(50, 150, 50))

local DecreaseRangeButton = CreateButton("DecreaseRangeBtn", "-", UDim2.new(0.3, 0, 0.87, 0), UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(200, 50, 50))

local BlacklistButton = CreateButton("BlacklistButton", "🚫 ЧЕРНЫЙ СПИСОК", UDim2.new(0.55, 0, 0.87, 0), UDim2.new(0.4, 0, 0, 30), Color3.fromRGB(255, 100, 0))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "✖", UDim2.new(0.92, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(200, 50, 50))

local MinButton = CreateButton("MinBtn", "–", UDim2.new(0.84, 0, 0.02, 0), UDim2.new(0.06, 0, 0.1, 0), Color3.fromRGB(255, 165, 0))

-- Создаем чекбоксы для каждой руды
local oreCheckboxes = {}
local function CreateOreCheckbox(oreName)
    local checkboxFrame = Instance.new("Frame")
    checkboxFrame.Name = oreName .. "Checkbox"
    checkboxFrame.BackgroundTransparency = 1
    checkboxFrame.Size = UDim2.new(1, 0, 0, 25)
    
    local checkboxButton = Instance.new("TextButton")
    checkboxButton.Name = "CheckboxButton"
    checkboxButton.Parent = checkboxFrame
    checkboxButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    checkboxButton.BorderSizePixel = 0
    checkboxButton.Position = UDim2.new(0, 0, 0, 0)
    checkboxButton.Size = UDim2.new(1, 0, 1, 0)
    checkboxButton.Font = Enum.Font.Gotham
    checkboxButton.Text = "□ " .. oreName
    checkboxButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    checkboxButton.TextSize = 12
    checkboxButton.TextXAlignment = Enum.TextXAlignment.Left
    checkboxButton.TextPadding = Instance.new("UIPadding")
    checkboxButton.TextPadding.PaddingLeft = UDim.new(0, 10)
    
    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0, 4)
    checkboxCorner.Parent = checkboxButton
    
    checkboxButton.MouseButton1Click:Connect(function()
        if selectedOres[oreName] then
            selectedOres[oreName] = nil
            checkboxButton.Text = "□ " .. oreName
            checkboxButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        else
            selectedOres[oreName] = true
            checkboxButton.Text = "✓ " .. oreName
            checkboxButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
        end
    end)
    
    oreCheckboxes[oreName] = checkboxButton
    checkboxFrame.Parent = OresScroll
    
    -- Обновляем размер скролла
    OresScroll.CanvasSize = UDim2.new(0, 0, 0, OresLayout.AbsoluteContentSize.Y)
end

-- Создаем чекбоксы для всех руд по умолчанию
for _, oreName in ipairs(defaultOres) do
    CreateOreCheckbox(oreName)
end

-- Функция поиска ближайшей руды
local function FindClosestOre()
    if not character or not humanoidRootPart then return nil end
    
    local closestDistance = math.huge
    local closestOre = nil
    local myPosition = humanoidRootPart.Position
    
    -- Проверяем черный список
    local currentTime = tick()
    for ore, blacklistTime in pairs(blacklistedOres) do
        if currentTime - blacklistTime > oreBlacklistTime then
            blacklistedOres[ore] = nil
        end
    end
    
    -- Ищем все части в рабочем пространстве
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name then
            -- Проверяем, выбрана ли эта руда
            if selectedOres[part.Name] and not blacklistedOres[part] then
                -- Проверяем дистанцию
                local distance = (myPosition - part.Position).Magnitude
                if distance < miningRange and distance < closestDistance then
                    closestDistance = distance
                    closestOre = part
                end
            end
        end
    end
    
    return closestOre
end

-- Функция добычи руды
local function MineOre(ore)
    if not character or not ore then return end
    
    -- Сохраняем позицию руды
    lastOrePosition = ore.Position
    
    -- Если включен телепорт - телепортируемся к руде
    if teleportToOres then
        humanoidRootPart.CFrame = CFrame.new(ore.Position + Vector3.new(0, 3, 0))
        wait(0.1)
    else
        -- Иначе идем к руде
        humanoid:MoveTo(ore.Position)
        local startTime = tick()
        while (humanoidRootPart.Position - ore.Position).Magnitude > 5 and tick() - startTime < 5 do
            wait(0.1)
        end
    end
    
    -- Пытаемся добыть руду
    -- Вариант 1: Клик по руде (если есть ClickDetector)
    local clickDetector = ore:FindFirstChild("ClickDetector")
    if clickDetector then
        for i = 1, 3 do
            fireclickdetector(clickDetector)
            wait(miningSpeed)
        end
    end
    
    -- Вариант 2: Использование инструмента
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        -- Активируем инструмент
        tool:Activate()
        wait(0.5)
        tool:Deactivate()
    end
    
    -- Вариант 3: Просто стоим рядом (для автоматической добычи)
    wait(miningSpeed * 2)
    
    -- Проверяем, исчезла ли руда
    if not ore.Parent then
        -- Руда добыта, добавляем в черный список на время
        blacklistedOres[ore] = tick()
    end
end

-- Основной цикл фарма
local miningConnection = nil
local function StartMining()
    if miningConnection then return end
    
    miningEnabled = true
    StartButton.Text = "⏹️ ОСТАНОВИТЬ ФАРМ"
    StartButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    StatusLabel.Text = "Статус: Фармим..."
    
    miningConnection = RunService.Heartbeat:Connect(function()
        if not miningEnabled or not character then return end
        
        -- Ищем ближайшую руду
        closestOre = FindClosestOre()
        
        if closestOre then
            StatusLabel.Text = string.format("Статус: Добываем %s...", closestOre.Name)
            MineOre(closestOre)
        else
            StatusLabel.Text = "Статус: Ищем руды..."
            
            -- Если есть последняя позиция руды, двигаемся к ней
            if lastOrePosition then
                if teleportToOres then
                    humanoidRootPart.CFrame = CFrame.new(lastOrePosition)
                else
                    humanoid:MoveTo(lastOrePosition)
                end
                wait(1)
            else
                -- Ищем любую руду в большем радиусе
                miningRange = 100
                closestOre = FindClosestOre()
                miningRange = 25
                
                if closestOre then
                    StatusLabel.Text = string.format("Статус: Нашли %s, идем...", closestOre.Name)
                    MineOre(closestOre)
                end
            end
        end
        
        -- Небольшая задержка между проверками
        wait(0.5)
    end)
end

local function StopMining()
    miningEnabled = false
    if miningConnection then
        miningConnection:Disconnect()
        miningConnection = nil
    end
    
    StartButton.Text = "▶️ НАЧАТЬ ФАРМ"
    StartButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    StatusLabel.Text = "Статус: Остановлен"
end

-- Обработчики кнопок
StartButton.MouseButton1Click:Connect(function()
    if miningEnabled then
        StopMining()
    else
        -- Проверяем, выбраны ли руды
        local hasSelectedOres = false
        for _ in pairs(selectedOres) do
            hasSelectedOres = true
            break
        end
        
        if not hasSelectedOres then
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Выберите хотя бы одну руду для фарма!",
                Duration = 3,
                Icon = "rbxassetid://4483345998"
            })
            return
        end
        
        StartMining()
    end
end)

SelectAllButton.MouseButton1Click:Connect(function()
    -- Выбираем все руды
    for oreName, checkbox in pairs(oreCheckboxes) do
        selectedOres[oreName] = true
        checkbox.Text = "✓ " .. oreName
        checkbox.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    end
end)

ClearSelectionButton.MouseButton1Click:Connect(function()
    -- Очищаем выбор
    selectedOres = {}
    for oreName, checkbox in pairs(oreCheckboxes) do
        checkbox.Text = "□ " .. oreName
        checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
end)

TeleportToggle.MouseButton1Click:Connect(function()
    teleportToOres = not teleportToOres
    if teleportToOres then
        TeleportToggle.Text = "⚡ ТЕЛЕПОРТ: ВКЛ"
        TeleportToggle.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    else
        TeleportToggle.Text = "🚶 ПЕШКОМ: ВКЛ"
        TeleportToggle.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    end
end)

IncreaseRangeButton.MouseButton1Click:Connect(function()
    miningRange = math.min(100, miningRange + 5)
    RangeDisplay.Text = "ДИСТАНЦИЯ: " .. miningRange
end)

DecreaseRangeButton.MouseButton1Click:Connect(function()
    miningRange = math.max(10, miningRange - 5)
    RangeDisplay.Text = "ДИСТАНЦИЯ: " .. miningRange
end)

BlacklistButton.MouseButton1Click:Connect(function()
    if closestOre then
        blacklistedOres[closestOre] = tick()
        StatusLabel.Text = "Статус: Руда в черном списке"
        closestOre = nil
        
        StarterGui:SetCore("SendNotification", {
            Title = "Черный список",
            Text = "Текущая руда добавлена в черный список",
            Duration = 3
        })
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    StopMining()
    ScreenGui:Destroy()
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinButton.Text = MainFrame.Visible and "–" or "+"
end)

-- Функция для ручного добавления руд
local function AddCustomOre()
    -- Можно добавить через текстовое поле, но для простоты добавим кнопку
    -- которая будет выбирать руду, на которую смотрит игрок
    StarterGui:SetCore("SendNotification", {
        Title = "Добавление руды",
        Text = "Посмотрите на руду и нажмите B для добавления",
        Duration = 5
    })
end

-- Горячие клавиши
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if miningEnabled then
            StopMining()
        else
            StartMining()
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        -- Ручное добавление руды
        local ray = Workspace.CurrentCamera:ScreenPointToRay(Vector2.new(0.5, 0.5))
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 100)
        
        if result and result.Instance then
            local ore = result.Instance
            if not oreCheckboxes[ore.Name] then
                CreateOreCheckbox(ore.Name)
            end
            selectedOres[ore.Name] = true
            oreCheckboxes[ore.Name].Text = "✓ " .. ore.Name
            oreCheckboxes[ore.Name].BackgroundColor3 = Color3.fromRGB(80, 120, 80)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Руда добавлена",
                Text = "Добавлена руда: " .. ore.Name,
                Duration = 3
            })
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        -- Добавить текущую руду в черный список
        if closestOre then
            blacklistedOres[closestOre] = tick()
        end
    end
end)

-- Автоматическое обнаружение новых руд
local oreDetectionConnection = nil
local function StartOreDetection()
    if oreDetectionConnection then return end
    
    oreDetectionConnection = RunService.Heartbeat:Connect(function()
        -- Сканируем все части в радиусе 50 studs
        if not character or not humanoidRootPart then return end
        
        local myPosition = humanoidRootPart.Position
        
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name then
                local distance = (myPosition - part.Position).Magnitude
                
                -- Если часть близко и ее нет в списке, предлагаем добавить
                if distance < 50 and not oreCheckboxes[part.Name] and not string.find(part.Name:lower(), "base") then
                    -- Проверяем, похоже ли имя на руду
                    local lowerName = part.Name:lower()
                    if string.find(lowerName, "ore") or string.find(lowerName, "stone") or 
                       string.find(lowerName, "crystal") or string.find(lowerName, "gem") or
                       string.find(lowerName, "mineral") then
                        
                        -- Предлагаем добавить
                        if not oreCheckboxes[part.Name] then
                            CreateOreCheckbox(part.Name)
                            
                            StarterGui:SetCore("SendNotification", {
                                Title = "Обнаружена новая руда",
                                Text = "Добавлена: " .. part.Name,
                                Duration = 4
                            })
                        end
                    end
                end
            end
        end
    end)
end

-- Запускаем обнаружение руд
StartOreDetection()

-- Обработка смерти
humanoid.Died:Connect(function()
    StopMining()
end)

-- Обработка респавна
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    
    wait(2)
    if miningEnabled then
        StartMining()
    end
end)

-- Уведомление о загрузке
wait(2)
StarterGui:SetCore("SendNotification", {
    Title = "Forge Mining Bot",
    Text = "AFK фарм активирован!\nF - Старт/Стоп, B - Добавить руду\nN - Черный список текущей руды",
    Duration = 7
})

print("✅ Forge Mining Bot успешно загружен!")
print("📋 Инструкция:")
print("   1. Выберите руды для фарма в списке")
print("   2. Нажмите 'Начать фарм' или клавишу F")
print("   3. Бот автоматически найдет и начнет добывать выбранные руды")
print("   4. Нажмите B, глядя на руду, чтобы добавить ее в список")
print("   5. Нажмите N, чтобы добавить текущую руду в черный список")

-- Функция для тестирования
local function TestMining()
    print("🔍 Тестирование поиска руд...")
    local testOre = FindClosestOre()
    if testOre then
        print("✅ Найдена руда: " .. testOre.Name)
        print("📍 Позиция: " .. tostring(testOre.Position))
    else
        print("❌ Руды не найдены")
    end
end

-- Тестирование при запуске
wait(3)
TestMining()
