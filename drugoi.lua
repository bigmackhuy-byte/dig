-- Ultimate GUI V10 - Selectable Item Steal
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
local selectedItems = {} -- Словарь для выбранных предметов

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
local itemSelectionGui = nil
local targetPlayerForSteal = nil

-- Создание основного GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V10"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderColor3 = Color3.fromRGB(0, 180, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
mainFrame.Size = UDim2.new(0, 400, 0, 450)
mainFrame.Active = true
mainFrame.Draggable = true

-- =============================================
-- ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ GUI
-- =============================================
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
title.Text = "⚡ ULTIMATE GUI V10 ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextScaled = true

-- =============================================
-- СЕКЦИЯ ПОЛЕТА
-- =============================================
local flyBtn = createButton(mainFrame, "✈️ ПОЛЕТ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.1, 0), UDim2.new(0.4, 0, 0, 35),
    Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80), true)

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
    UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(60, 180, 60), Color3.fromRGB(80, 200, 80), true)

local speedDownBtn = createButton(mainFrame, "▼ -", 
    UDim2.new(0.3, 0, 0.2, 0), UDim2.new(0.2, 0, 0, 25),
    Color3.fromRGB(180, 60, 60), Color3.fromRGB(200, 80, 80), true)

-- =============================================
-- СЕКЦИЯ GOD MODE
-- =============================================
local godModeBtn = createButton(mainFrame, "💀 GOD MODE: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.28, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 120, 120), true)

-- =============================================
-- СЕКЦИЯ ОТТАЛКИВАНИЯ
-- =============================================
local antiPlayerBtn = createButton(mainFrame, "⚡ ОТТАЛКИВАНИЕ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.38, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(255, 60, 150), Color3.fromRGB(255, 90, 180), true)

-- =============================================
-- СЕКЦИЯ ТЕЛЕПОРТА
-- =============================================
local teleportBtn = createButton(mainFrame, "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВЫКЛ", 
    UDim2.new(0.05, 0, 0.48, 0), UDim2.new(0.9, 0, 0, 35),
    Color3.fromRGB(0, 160, 255), Color3.fromRGB(40, 190, 255), true)

-- =============================================
-- СЕКЦИЯ КРАЖИ ПРЕДМЕТОВ (УЛУЧШЕННАЯ)
-- =============================================
local stealBtnText = hasInventorySystem and "🎒 ВЫБОР ПРЕДМЕТОВ: ВЫКЛ" or "🎒 ИНВЕНТАРЬ НЕДОСТУПЕН"
local stealBtn = createButton(mainFrame, stealBtnText, 
    UDim2.new(0.05, 0, 0.58, 0), UDim2.new(0.9, 0, 0, 40),
    Color3.fromRGB(180, 60, 255), Color3.fromRGB(200, 90, 255), hasInventorySystem)

local stealInfo = Instance.new("TextLabel")
stealInfo.Parent = mainFrame
stealInfo.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
stealInfo.BorderSizePixel = 0
stealInfo.Position = UDim2.new(0.05, 0, 0.68, 0)
stealInfo.Size = UDim2.new(0.9, 0, 0, 50)
stealInfo.Font = Enum.Font.SourceSans
if hasInventorySystem then
    stealInfo.Text = "🖱️ ЛКМ по игроку → Выбор предметов → Кража"
    stealInfo.TextColor3 = Color3.fromRGB(200, 255, 200)
else
    stealInfo.Text = "⚠️ В этой игре нет системы инвентаря"
    stealInfo.TextColor3 = Color3.fromRGB(255, 150, 150)
end
stealInfo.TextSize = 11
stealInfo.TextWrapped = true

-- =============================================
-- КНОПКИ УПРАВЛЕНИЯ
-- =============================================
local closeBtn = createButton(mainFrame, "✕", 
    UDim2.new(0.94, -25, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50), true)

local minBtn = createButton(mainFrame, "−", 
    UDim2.new(0.94, -55, 0.02, 0), UDim2.new(0, 25, 0, 25),
    Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 185, 40), true)

-- =============================================
-- ИНФОРМАЦИЯ
-- =============================================
local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = mainFrame
infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
infoLabel.BorderSizePixel = 0
infoLabel.Position = UDim2.new(0.05, 0, 0.8, 0)
infoLabel.Size = UDim2.new(0.9, 0, 0, 45)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Text = hasInventorySystem and 
    "F-Полет | G-God | R-Отталкивание\nT-Телепорт | V-Выбор предметов" or
    "F-Полет | G-God | R-Отталкивание\nT-Телепорт | Инвентарь недоступен"
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.TextScaled = true

-- =============================================
-- ФУНКЦИЯ СОЗДАНИЯ GUI ВЫБОРА ПРЕДМЕТОВ
-- =============================================
local function createItemSelectionGui(targetPlayer)
    if not targetPlayer or not hasInventorySystem then return end
    
    -- Удаляем старый GUI если есть
    if itemSelectionGui then
        itemSelectionGui:Destroy()
        itemSelectionGui = nil
    end
    
    -- Сохраняем целевого игрока
    targetPlayerForSteal = targetPlayer
    
    -- Создаем новый GUI
    itemSelectionGui = Instance.new("ScreenGui")
    itemSelectionGui.Name = "ItemSelectionGUI"
    itemSelectionGui.Parent = CoreGui
    itemSelectionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local selectionFrame = Instance.new("Frame")
    selectionFrame.Parent = itemSelectionGui
    selectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    selectionFrame.BorderColor3 = Color3.fromRGB(180, 60, 255)
    selectionFrame.BorderSizePixel = 2
    selectionFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    selectionFrame.Size = UDim2.new(0, 350, 0, 400)
    selectionFrame.Active = true
    selectionFrame.Draggable = true
    
    -- Заголовок
    local selectionTitle = Instance.new("TextLabel")
    selectionTitle.Parent = selectionFrame
    selectionTitle.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
    selectionTitle.BorderSizePixel = 0
    selectionTitle.Position = UDim2.new(0, 0, 0, 0)
    selectionTitle.Size = UDim2.new(1, 0, 0, 40)
    selectionTitle.Font = Enum.Font.SourceSansBold
    selectionTitle.Text = "🎒 ВЫБОР ПРЕДМЕТОВ - " .. targetPlayer.Name
    selectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectionTitle.TextSize = 16
    
    -- Очистка выбора
    local clearBtn = createButton(selectionFrame, "🗑️ ОЧИСТИТЬ ВЫБОР", 
        UDim2.new(0.05, 0, 0.12, 0), UDim2.new(0.9, 0, 0, 30),
        Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 110, 110), true)
    
    -- Кнопка "Выбрать все"
    local selectAllBtn = createButton(selectionFrame, "✅ ВЫБРАТЬ ВСЕ", 
        UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.9, 0, 0, 30),
        Color3.fromRGB(80, 180, 80), Color3.fromRGB(100, 200, 100), true)
    
    -- Кнопка кражи выбранного
    local stealSelectedBtn = createButton(selectionFrame, "⚡ УКРАСТЬ ВЫБРАННОЕ", 
        UDim2.new(0.05, 0, 0.88, 0), UDim2.new(0.9, 0, 0, 35),
        Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 170, 40), true)
    
    -- Прокручиваемый фрейм для предметов
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = selectionFrame
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Position = UDim2.new(0.05, 0, 0.28, 0)
    scrollFrame.Size = UDim2.new(0.9, 0, 0.55, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 8
    
    -- Собираем предметы игрока
    local items = {}
    local targetBackpack = targetPlayer:FindFirstChild("Backpack")
    local targetCharacter = targetPlayer.Character
    
    if targetCharacter then
        -- Инструменты в руках
        for _, tool in pairs(targetCharacter:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, {Name = tool.Name, Object = tool, Type = "Tool"})
            end
        end
    end
    
    if targetBackpack then
        -- Предметы в инвентаре
        for _, item in pairs(targetBackpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") then
                table.insert(items, {Name = item.Name, Object = item, Type = "Item"})
            end
        end
    end
    
    -- Если нет предметов
    if #items == 0 then
        local noItemsLabel = Instance.new("TextLabel")
        noItemsLabel.Parent = scrollFrame
        noItemsLabel.BackgroundTransparency = 1
        noItemsLabel.Size = UDim2.new(1, 0, 0, 50)
        noItemsLabel.Font = Enum.Font.SourceSans
        noItemsLabel.Text = "😔 Нет предметов для кражи"
        noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        noItemsLabel.TextSize = 14
        noItemsLabel.TextWrapped = true
        
        stealSelectedBtn.Text = "❌ НЕТ ПРЕДМЕТОВ"
        stealSelectedBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        stealSelectedBtn.Active = false
    else
        -- Создаем кнопки для каждого предмета
        local yOffset = 0
        for i, itemData in pairs(items) do
            local itemBtn = Instance.new("TextButton")
            itemBtn.Name = "ItemBtn_" .. i
            itemBtn.Parent = scrollFrame
            itemBtn.BackgroundColor3 = selectedItems[itemData.Name] and 
                Color3.fromRGB(80, 180, 255) or Color3.fromRGB(60, 60, 90)
            itemBtn.BorderSizePixel = 0
            itemBtn.Position = UDim2.new(0, 0, 0, yOffset)
            itemBtn.Size = UDim2.new(1, -10, 0, 35)
            itemBtn.Font = Enum.Font.SourceSans
            itemBtn.Text = itemData.Type == "Tool" and 
                "🛠️ " .. itemData.Name .. " (В руках)" or 
                "📦 " .. itemData.Name .. " (В инвентаре)"
            itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemBtn.TextSize = 12
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Checkbox для выбора
            local checkbox = Instance.new("TextLabel")
            checkbox.Parent = itemBtn
            checkbox.BackgroundTransparency = 1
            checkbox.Position = UDim2.new(0.85, 0, 0.2, 0)
            checkbox.Size = UDim2.new(0, 20, 0, 20)
            checkbox.Font = Enum.Font.SourceSansBold
            checkbox.Text = selectedItems[itemData.Name] and "✓" or ""
            checkbox.TextColor3 = Color3.fromRGB(0, 255, 0)
            checkbox.TextSize = 16
            
            -- Обработчик выбора предмета
            itemBtn.MouseButton1Click:Connect(function()
                selectedItems[itemData.Name] = not selectedItems[itemData.Name]
                itemBtn.BackgroundColor3 = selectedItems[itemData.Name] and 
                    Color3.fromRGB(80, 180, 255) or Color3.fromRGB(60, 60, 90)
                checkbox.Text = selectedItems[itemData.Name] and "✓" or ""
            end)
            
            yOffset = yOffset + 40
        end
        
        -- Обновляем размер прокрутки
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 40)
    end
    
    -- Обработчики кнопок
    clearBtn.MouseButton1Click:Connect(function()
        selectedItems = {}
        -- Обновляем все кнопки
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("ItemBtn_") then
                child.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
                local checkbox = child:FindFirstChildOfClass("TextLabel")
                if checkbox then
                    checkbox.Text = ""
                end
            end
        end
    end)
    
    selectAllBtn.MouseButton1Click:Connect(function()
        selectedItems = {}
        -- Выбираем все предметы
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("ItemBtn_") then
                local itemName = child.Text:gsub("🛠️ ", ""):gsub("📦 ", ""):gsub(" %(В руках%)", ""):gsub(" %(В инвентаре%)", "")
                selectedItems[itemName] = true
                child.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
                local checkbox = child:FindFirstChildOfClass("TextLabel")
                if checkbox then
                    checkbox.Text = "✓"
                end
            end
        end
    end)
    
    stealSelectedBtn.MouseButton1Click:Connect(function()
        if not targetPlayerForSteal then return end
        
        local stolenCount = 0
        local targetBackpack = targetPlayerForSteal:FindFirstChild("Backpack")
        local targetCharacter = targetPlayerForSteal.Character
        
        -- Крадем выбранные предметы
        for itemName, isSelected in pairs(selectedItems) do
            if isSelected then
                -- Ищем в инвентаре
                local found = false
                if targetBackpack then
                    for _, item in pairs(targetBackpack:GetChildren()) do
                        if item.Name == itemName and (item:IsA("Tool") or item:IsA("HopperBin")) then
                            -- Создаем копию
                            local clonedItem = item:Clone()
                            clonedItem.Parent = player.Backpack
                            found = true
                            stolenCount = stolenCount + 1
                            break
                        end
                    end
                end
                
                -- Ищем в руках
                if not found and targetCharacter then
                    for _, tool in pairs(targetCharacter:GetChildren()) do
                        if tool.Name == itemName and tool:IsA("Tool") then
                            local clonedTool = tool:Clone()
                            clonedTool.Parent = player.Backpack
                            stolenCount = stolenCount + 1
                            break
                        end
                    end
                end
            end
        end
        
        -- Уведомление
        StarterGui:SetCore("SendNotification", {
            Title = "🎒 КРАЖА ВЫПОЛНЕНА",
            Text = "Украдено предметов: " .. stolenCount,
            Duration = 3
        })
        
        -- Закрываем GUI
        if itemSelectionGui then
            itemSelectionGui:Destroy()
            itemSelectionGui = nil
        end
        
        selectedItems = {}
        targetPlayerForSteal = nil
    end)
    
    -- Кнопка закрытия
    local closeSelectionBtn = createButton(selectionFrame, "✕", 
        UDim2.new(0.92, -25, 0.02, 0), UDim2.new(0, 25, 0, 25),
        Color3.fromRGB(220, 30, 30), Color3.fromRGB(240, 50, 50), true)
    
    closeSelectionBtn.MouseButton1Click:Connect(function()
        if itemSelectionGui then
            itemSelectionGui:Destroy()
            itemSelectionGui = nil
        end
        selectedItems = {}
        targetPlayerForSteal = nil
    end)
end

-- =============================================
-- ОСНОВНЫЕ ФУНКЦИИ (ПОЛЕТ, GOD MODE и т.д.)
-- =============================================

-- ФУНКЦИЯ ПОЛЕТА (остается без изменений)
local function toggleFly()
    -- ... тот же код что и раньше ...
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        flyBtn.Text = "✈️ ПОЛЕТ: ВКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        -- ... остальной код полета ...
    else
        flyBtn.Text = "✈️ ПОЛЕТ: ВЫКЛ"
        flyBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        -- ... остальной код выключения полета ...
    end
end

-- GOD MODE (остается без изменений)
local function toggleGodMode()
    -- ... тот же код что и раньше ...
end

-- ОТТАЛКИВАНИЕ (остается без изменений)
local function toggleAntiPlayer()
    -- ... тот же код что и раньше ...
end

-- ТЕЛЕПОРТ (остается без изменений)
local function toggleTeleport()
    -- ... тот же код что и раньше ...
end

-- =============================================
-- УЛУЧШЕННАЯ ФУНКЦИЯ КРАЖИ С ВЫБОРОМ ПРЕДМЕТОВ
-- =============================================
local function toggleStealItems()
    if not hasInventorySystem then
        print("⚠️ Система инвентаря недоступна в этой игре")
        return
    end
    
    stealItemsEnabled = not stealItemsEnabled
    
    if stealItemsEnabled then
        stealBtn.Text = "🎒 ВЫБОР ПРЕДМЕТОВ: ВКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 255)
        
        -- Обработчик ЛКМ по игрокам для выбора
        stealConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not stealItemsEnabled or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target and target.Parent then
                local model = target.Parent
                while model and model ~= Workspace do
                    local targetPlayer = Players:GetPlayerFromCharacter(model)
                    if targetPlayer and targetPlayer ~= player then
                        -- Создаем GUI выбора предметов
                        createItemSelectionGui(targetPlayer)
                        break
                    end
                    model = model.Parent
                end
            end
        end)
        
        print("✅ Система выбора предметов активирована")
        print("📌 ЛКМ по игроку для выбора предметов")
        
    else
        stealBtn.Text = "🎒 ВЫБОР ПРЕДМЕТОВ: ВЫКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        
        if stealConnection then
            stealConnection:Disconnect()
            stealConnection = nil
        end
        
        -- Закрываем GUI выбора если открыт
        if itemSelectionGui then
            itemSelectionGui:Destroy()
            itemSelectionGui = nil
        end
        
        selectedItems = {}
        targetPlayerForSteal = nil
        
        print("❌ Система выбора предметов деактивирована")
    end
end

-- =============================================
-- ОБРАБОТЧИКИ КНОПОК
-- =============================================
flyBtn.MouseButton1Click:Connect(toggleFly)
godModeBtn.MouseButton1Click:Connect(toggleGodMode)
antiPlayerBtn.MouseButton1Click:Connect(toggleAntiPlayer)
teleportBtn.MouseButton1Click:Connect(toggleTeleport)

-- Кнопка скорости
speedUpBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.min(flightSpeed + 10, 200)
    speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
end)

speedDownBtn.MouseButton1Click:Connect(function()
    flightSpeed = math.max(flightSpeed - 10, 10)
    speedDisplay.Text = "СКОРОСТЬ: " .. flightSpeed
end)

-- Кнопка кражи (только если доступна)
if hasInventorySystem then
    stealBtn.MouseButton1Click:Connect(toggleStealItems)
else
    stealBtn.MouseButton1Click:Connect(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ СИСТЕМА НЕДОСТУПНА",
            Text = "В этой игре нет системы инвентаря",
            Duration = 3
        })
    end)
end

-- Управление окном
closeBtn.MouseButton1Click:Connect(function()
    -- Отключаем все системы
    if flyEnabled then toggleFly() end
    if godModeEnabled then toggleGodMode() end
    if antiPlayerEnabled then toggleAntiPlayer() end
    if teleportClickEnabled then toggleTeleport() end
    if stealItemsEnabled and hasInventorySystem then toggleStealItems() end
    
    -- Закрываем GUI выбора если открыт
    if itemSelectionGui then
        itemSelectionGui:Destroy()
        itemSelectionGui = nil
    end
    
    screenGui:Destroy()
    print("📌 GUI закрыт")
end)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minBtn.Text = mainFrame.Visible and "−" or "+"
end)

-- =============================================
-- ГОРЯЧИЕ КЛАВИШИ
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
-- ЗАГРУЗОЧНОЕ УВЕДОМЛЕНИЕ
-- =============================================
StarterGui:SetCore("SendNotification", {
    Title = "⚡ ULTIMATE GUI V10",
    Text = hasInventorySystem and "Загружен! V-Выбор предметов для кражи" or "Загружен! Нет системы инвентаря",
    Duration = 5
})

print("=" .. string.rep("=", 60))
print("✅ ULTIMATE GUI V10 ЗАГРУЖЕН УСПЕШНО!")
print("=" .. string.rep("=", 60))
print("✈️  ПОЛЕТ: F")
print("💀 GOD MODE: G")
print("⚡ ОТТАЛКИВАНИЕ: R")
print("📍 ТЕЛЕПОРТ ПО КЛИКУ: T")
if hasInventorySystem then
    print("🎒 ВЫБОР ПРЕДМЕТОВ: V")
    print("📌 1. Включите функцию (V)")
    print("📌 2. ЛКМ по игроку")
    print("📌 3. Выберите предметы в меню")
    print("📌 4. Нажмите 'Украсть выбранное'")
else
    print("⚠️ КРАЖА ПРЕДМЕТОВ: НЕДОСТУПНА")
end
print("=" .. string.rep("=", 60))
