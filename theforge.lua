-- AFK Mining Bot for The Forge (Beta) - FIXED VERSION
-- Автор: XNEO | Автоматический фарм ресурсов

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

-- Локальный игрок
local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChild("Humanoid")
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

-- Ожидаем персонажа если его нет
if not character then
    character = player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Переменные
local miningEnabled = false
local selectedOres = {}
local miningRange = 25
local teleportToOres = true
local closestOre = nil
local lastOrePosition = nil
local blacklistedOres = {}
local oreBlacklistTime = 30
local autoClick = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForgeMiningBot_FIXED"
ScreenGui.Parent = CoreGui -- Используем CoreGui для надежности
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderColor3 = Color3.fromRGB(200, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Selectable = true

-- Тень
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Parent = MainFrame
Shadow.BackgroundTransparency = 1
Shadow.Size = UDim2.new(1, 10, 1, 10)
Shadow.Position = UDim2.new(0, -5, 0, -5)
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.8
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)

-- Функция создания кнопок
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
    button.AutoButtonColor = false
    button.TextScaled = false
    button.ClipsDescendants = true
    
    -- Закругление
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Тень кнопки
    local buttonShadow = Instance.new("Frame")
    buttonShadow.Name = "Shadow"
    buttonShadow.Parent = button
    buttonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    buttonShadow.BackgroundTransparency = 0.7
    buttonShadow.Size = UDim2.new(1, 4, 1, 4)
    buttonShadow.Position = UDim2.new(0, -2, 0, -2)
    buttonShadow.ZIndex = -1
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 8)
    shadowCorner.Parent = buttonShadow
    
    -- Эффекты кнопки
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(color.R * 255 + 30, 255),
                math.min(color.G * 255 + 30, 255),
                math.min(color.B * 255 + 30, 255)
            ) / 255,
            Size = size + UDim2.new(0, 2, 0, 2)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = color,
            Size = size
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(
                math.max(color.R * 255 - 40, 0),
                math.max(color.G * 255 - 40, 0),
                math.max(color.B * 255 - 40, 0)
            ) / 255,
            Size = size - UDim2.new(0, 2, 0, 2)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = color,
            Size = size
        }):Play()
    end)
    
    return button
end

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
Title.BackgroundTransparency = 0
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "⚒️ FORGE MINING BOT ⚒️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

-- Закругление заголовка
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = Title

-- Статус бар
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Parent = MainFrame
StatusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
StatusBar.BorderSizePixel = 0
StatusBar.Position = UDim2.new(0.05, 0, 0.12, 0)
StatusBar.Size = UDim2.new(0.9, 0, 0, 30)

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = StatusBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = StatusBar
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Статус: Ожидание"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14

-- Кнопки управления
local StartButton = CreateButton("StartButton", "▶️ НАЧАТЬ ФАРМ", UDim2.new(0.05, 0, 0.22, 0), UDim2.new(0.9, 0, 0, 40), Color3.fromRGB(0, 180, 0))

-- Панель выбора руд
local OresFrame = Instance.new("ScrollingFrame")
OresFrame.Name = "OresFrame"
OresFrame.Parent = MainFrame
OresFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
OresFrame.BorderSizePixel = 0
OresFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
OresFrame.Size = UDim2.new(0.9, 0, 0, 120)
OresFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
OresFrame.ScrollBarThickness = 6

local oresCorner = Instance.new("UICorner")
oresCorner.CornerRadius = UDim.new(0, 6)
oresCorner.Parent = OresFrame

-- Список руд
local oreNames = {
    "Stone", "Coal", "Copper", "Iron", "Gold", 
    "Diamond", "Emerald", "Ruby", "Sapphire", "Mithril",
    "Adamantite", "Titanium", "Obsidian", "Crystal",
    "Rock", "Ore", "Mineral", "Gem"
}

-- Создаем чекбоксы для руд
local oreCheckboxes = {}
local function CreateOreCheckbox(oreName, index)
    local yPos = ((index-1) * 25) / OresFrame.CanvasSize.Y.Scale
    
    local checkboxFrame = Instance.new("Frame")
    checkboxFrame.Name = oreName .. "Frame"
    checkboxFrame.BackgroundTransparency = 1
    checkboxFrame.Size = UDim2.new(1, -10, 0, 20)
    checkboxFrame.Position = UDim2.new(0, 5, 0, 5 + ((index-1) * 25))
    checkboxFrame.Parent = OresFrame
    
    local checkbox = Instance.new("TextButton")
    checkbox.Name = oreName .. "Checkbox"
    checkbox.Parent = checkboxFrame
    checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    checkbox.BorderSizePixel = 0
    checkbox.Size = UDim2.new(1, 0, 1, 0)
    checkbox.Font = Enum.Font.SourceSans
    checkbox.Text = "□ " .. oreName
    checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
    checkbox.TextSize = 12
    checkbox.TextXAlignment = Enum.TextXAlignment.Left
    checkbox.TextPadding = Instance.new("UIPadding")
    checkbox.TextPadding.PaddingLeft = UDim.new(0, 10)
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkbox
    
    -- Обработчик клика
    checkbox.MouseButton1Click:Connect(function()
        if selectedOres[oreName] then
            selectedOres[oreName] = nil
            checkbox.Text = "□ " .. oreName
            checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        else
            selectedOres[oreName] = true
            checkbox.Text = "✓ " .. oreName
            checkbox.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
        end
    end)
    
    oreCheckboxes[oreName] = checkbox
end

-- Создаем все чекбоксы
for i, oreName in ipairs(oreNames) do
    CreateOreCheckbox(oreName, i)
end

-- Кнопки выбора
local SelectAllButton = CreateButton("SelectAllButton", "✓ ВЫБРАТЬ ВСЕ", UDim2.new(0.05, 0, 0.72, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(50, 120, 200))

local ClearButton = CreateButton("ClearButton", "✗ ОЧИСТИТЬ", UDim2.new(0.51, 0, 0.72, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(200, 50, 50))

-- Настройки
local TeleportButton = CreateButton("TeleportButton", "⚡ ТЕЛЕПОРТ: ВКЛ", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(100, 50, 200))

local RangeButton = CreateButton("RangeButton", "📏 ДИСТ: 25", UDim2.new(0.51, 0, 0.8, 0), UDim2.new(0.44, 0, 0, 30), Color3.fromRGB(50, 150, 200))

-- Кнопки управления окном
local CloseButton = CreateButton("CloseBtn", "✖", UDim2.new(0.85, 0, 0.02, 0), UDim2.new(0.12, 0, 0.08, 0), Color3.fromRGB(200, 50, 50))

local MinButton = CreateButton("MinBtn", "–", UDim2.new(0.72, 0, 0.02, 0), UDim2.new(0.12, 0, 0.08, 0), Color3.fromRGB(255, 165, 0))

-- Функция поиска руды
local function FindClosestOre()
    if not character or not humanoidRootPart then return nil end
    
    local closest = nil
    local closestDist = miningRange
    local myPos = humanoidRootPart.Position
    
    -- Очищаем старые записи в черном списке
    local currentTime = tick()
    for ore, time in pairs(blacklistedOres) do
        if currentTime - time > oreBlacklistTime then
            blacklistedOres[ore] = nil
        end
    end
    
    -- Ищем руды
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            if obj.Name then
                local isSelectedOre = false
                
                -- Проверяем все выбранные руды
                for oreName in pairs(selectedOres) do
                    if string.find(obj.Name:lower(), oreName:lower()) then
                        isSelectedOre = true
                        break
                    end
                end
                
                if isSelectedOre and not blacklistedOres[obj] then
                    local dist = (myPos - obj.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    
    return closest
end

-- Функция добычи
local function MineOre(ore)
    if not character or not ore then return false end
    
    StatusLabel.Text = "Статус: Добываем " .. ore.Name
    
    -- Телепортируемся или идем к руде
    if teleportToOres then
        humanoidRootPart.CFrame = CFrame.new(ore.Position + Vector3.new(0, 3, 2))
    else
        humanoid:MoveTo(ore.Position)
        
        -- Ждем пока подойдем
        local startTime = tick()
        while (humanoidRootPart.Position - ore.Position).Magnitude > 5 do
            if tick() - startTime > 5 then break end
            wait(0.1)
        end
    end
    
    wait(0.5)
    
    -- Пытаемся кликнуть по руде
    local clickDetector = ore:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        for i = 1, 3 do
            fireclickdetector(clickDetector)
            wait(0.5)
        end
    else
        -- Имитируем удар по руде
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        wait(0.2)
    end
    
    -- Проверяем, добыта ли руда
    if not ore.Parent then
        -- Руда добыта, добавляем в черный список
        blacklistedOres[ore] = tick()
        return true
    end
    
    return false
end

-- Основной цикл
local miningConnection = nil
local function StartMining()
    if miningEnabled then return end
    
    miningEnabled = true
    StartButton.Text = "⏹️ ОСТАНОВИТЬ"
    StartButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    StatusLabel.Text = "Статус: Поиск руд..."
    
    miningConnection = RunService.Heartbeat:Connect(function()
        if not miningEnabled or not character then return end
        
        -- Ищем ближайшую руду
        local ore = FindClosestOre()
        
        if ore then
            closestOre = ore
            MineOre(ore)
        else
            StatusLabel.Text = "Статус: Руд не найдено"
            
            -- Если есть последняя позиция, идем туда
            if lastOrePosition then
                if teleportToOres then
                    humanoidRootPart.CFrame = CFrame.new(lastOrePosition)
                else
                    humanoid:MoveTo(lastOrePosition)
                end
            end
            
            wait(1)
        end
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
    print("Кнопка Старт нажата")
    
    -- Проверяем выбраны ли руды
    local hasOres = false
    for _ in pairs(selectedOres) do
        hasOres = true
        break
    end
    
    if not hasOres then
        StatusLabel.Text = "Ошибка: Выберите руды!"
        wait(2)
        StatusLabel.Text = "Статус: Ожидание"
        return
    end
    
    if miningEnabled then
        StopMining()
    else
        StartMining()
    end
end)

SelectAllButton.MouseButton1Click:Connect(function()
    print("Выбрать все нажато")
    
    for oreName, checkbox in pairs(oreCheckboxes) do
        selectedOres[oreName] = true
        checkbox.Text = "✓ " .. oreName
        checkbox.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    end
    
    StatusLabel.Text = "Все руды выбраны"
    wait(1)
    StatusLabel.Text = "Статус: Готов"
end)

ClearButton.MouseButton1Click:Connect(function()
    print("Очистить нажато")
    
    selectedOres = {}
    for oreName, checkbox in pairs(oreCheckboxes) do
        checkbox.Text = "□ " .. oreName
        checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
    
    StatusLabel.Text = "Выбор очищен"
    wait(1)
    StatusLabel.Text = "Статус: Готов"
end)

TeleportButton.MouseButton1Click:Connect(function()
    teleportToOres = not teleportToOres
    
    if teleportToOres then
        TeleportButton.Text = "⚡ ТЕЛЕПОРТ: ВКЛ"
        TeleportButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    else
        TeleportButton.Text = "🚶 ПЕШКОМ: ВКЛ"
        TeleportButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    end
end)

RangeButton.MouseButton1Click:Connect(function()
    miningRange = miningRange + 10
    if miningRange > 100 then
        miningRange = 10
    end
    
    RangeButton.Text = "📏 ДИСТ: " .. miningRange
end)

CloseButton.MouseButton1Click:Connect(function()
    StopMining()
    ScreenGui:Destroy()
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinButton.Text = MainFrame.Visible and "–" or "+"
end)

-- Функция для ручного добавления руды
local function AddCurrentOre()
    if not character then return end
    
    local camera = Workspace.CurrentCamera
    local mouse = player:GetMouse()
    
    -- Луч из камеры
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 100
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        local oreName = hitPart.Name
        
        -- Добавляем в список если еще нет
        if not oreCheckboxes[oreName] then
            local newIndex = #oreNames + 1
            oreNames[newIndex] = oreName
            CreateOreCheckbox(oreName, newIndex)
        end
        
        -- Выбираем руду
        selectedOres[oreName] = true
        if oreCheckboxes[oreName] then
            oreCheckboxes[oreName].Text = "✓ " .. oreName
            oreCheckboxes[oreName].BackgroundColor3 = Color3.fromRGB(80, 120, 80)
        end
        
        StatusLabel.Text = "Добавлена руда: " .. oreName
        wait(2)
        StatusLabel.Text = "Статус: Готов"
    end
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
    elseif input.KeyCode == Enum.KeyCode.G then
        -- Добавить текущую руду
        AddCurrentOre()
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Черный список текущей руды
        if closestOre then
            blacklistedOres[closestOre] = tick()
            StatusLabel.Text = "Руда в черном списке"
            closestOre = nil
            wait(2)
            StatusLabel.Text = "Статус: Поиск..."
        end
    end
end)

-- Обновляем позицию персонажа при респавне
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    
    if miningEnabled then
        wait(2)
        StartMining()
    end
end)

-- Обработка смерти
if humanoid then
    humanoid.Died:Connect(function()
        StopMining()
    end)
end

-- Информационное сообщение
wait(2)
StarterGui:SetCore("SendNotification", {
    Title = "⚒️ Forge Mining Bot",
    Text = "Бот успешно загружен!\nF - Старт/Стоп\nG - Добавить руду\nH - Черный список",
    Duration = 5,
    Icon = "rbxassetid://4483345998"
})

-- Выводим инструкцию в консоль
print("====================================")
print("⚒️ FORGE MINING BOT v2.0")
print("====================================")
print("Инструкция:")
print("1. Выберите руды для фарма (галочки)")
print("2. Нажмите 'Начать фарм' или F")
print("3. Для добавления руды: смотрите на нее и нажмите G")
print("4. Для черного списка: нажмите H когда руда выбрана")
print("====================================")
print("Статус: Готов к работе")
print("Выбранные руды: 0")
print("Дистанция поиска: " .. miningRange)
print("Режим: " .. (teleportToOres and "Телепорт" or "Пешком"))
print("====================================")

-- Функция для проверки работы
local function TestBot()
    print("🧪 Тестирование...")
    print("Персонаж:", character and "✓" or "✗")
    print("Гуи:", ScreenGui and "✓" or "✗")
    print("Кнопки:", StartButton and "✓" or "✗")
    
    -- Тестовый поиск руды
    local testOre = FindClosestOre()
    print("Найдено руд:", testOre and "✓" or "✗")
    
    if testOre then
        print("Пример руды:", testOre.Name)
        print("Позиция:", testOre.Position)
    end
end

-- Запускаем тест через 3 секунды
wait(3)
TestBot()
