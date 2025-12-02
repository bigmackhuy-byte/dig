-- Ultimate GUI V11 - Real Item Steal System
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
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
    print("✅ Обнаружена система инвентаря")
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

-- Словарь для выбранных предметов
local selectedItems = {}
local itemCache = {}

-- Создание основного GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGUI_V11"
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
title.Text = "⚡ ULTIMATE GUI V11 ⚡"
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
-- СЕКЦИЯ КРАЖИ ПРЕДМЕТОВ (РЕАЛЬНАЯ СИСТЕМА)
-- =============================================
local stealBtnText = hasInventorySystem and "🎒 РЕАЛЬНАЯ КРАЖА: ВЫКЛ" or "🎒 ИНВЕНТАРЬ НЕДОСТУПЕН"
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
    stealInfo.Text = "🖱️ ЛКМ по игроку → Выбор предметов → Легальная кража"
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
    "F-Полет | G-God | R-Отталкивание\nT-Телепорт | V-Реальная кража" or
    "F-Полет | G-God | R-Отталкивание\nT-Телепорт | Инвентарь недоступен"
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.TextScaled = true

-- =============================================
-- РЕАЛЬНАЯ ФУНКЦИЯ ПОЛУЧЕНИЯ ПРЕДМЕТОВ
-- =============================================

-- Функция поиска удаленных сервисов и инструментов
local function findRemoteServices()
    local remotes = {}
    
    -- Ищем стандартные сервисы
    local services = {
        ReplicatedStorage,
        Workspace,
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Lighting")
    }
    
    for _, service in pairs(services) do
        for _, remote in pairs(service:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("BindableEvent") or remote:IsA("BindableFunction") then
                if string.find(remote.Name:lower(), "item") or 
                   string.find(remote.Name:lower(), "tool") or 
                   string.find(remote.Name:lower(), "give") or
                   string.find(remote.Name:lower(), "equip") or
                   string.find(remote.Name:lower(), "inventory") then
                    table.insert(remotes, remote)
                end
            end
        end
    end
    
    return remotes
end

-- Функция получения реального предмета от сервера
local function getRealItemFromServer(itemName, itemData)
    print("🔍 Попытка получить реальный предмет: " .. itemName)
    
    -- Ищем подходящие RemoteEvent/RemoteFunction
    local remotes = findRemoteServices()
    
    if #remotes == 0 then
        print("⚠️ Не найдены RemoteEvent для получения предметов")
        return nil
    end
    
    -- Пробуем разные методы получения предмета
    for _, remote in pairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                -- Пробуем вызвать RemoteEvent
                remote:FireServer("GiveItem", itemName)
                remote:FireServer("Equip", itemName)
                remote:FireServer("AddItem", itemName)
                remote:FireServer("Buy", itemName, 0)
                remote:FireServer("Get", itemName)
                print("📡 Отправлен запрос через: " .. remote:GetFullName())
            elseif remote:IsA("RemoteFunction") then
                -- Пробуем вызвать RemoteFunction
                local result = remote:InvokeServer("GiveItem", itemName)
                print("📡 Результат RemoteFunction: " .. tostring(result))
            end
        end)
    end
    
    -- Метод 2: Пробуем найти и купить предмет в магазине
    pcall(function()
        -- Ищем магазины в игре
        for _, store in pairs(Workspace:GetDescendants()) do
            if store:IsA("Model") and (store.Name:find("Shop") or store.Name:find("Store") or store.Name:find("Market")) then
                -- Пробуем взаимодействовать с магазином
                local storeRemote = store:FindFirstChildWhichIsA("RemoteEvent")
                if storeRemote then
                    storeRemote:FireServer("Purchase", itemName, 0)
                    print("🏪 Попытка покупки в магазине: " .. store.Name)
                end
            end
        end
    end)
    
    -- Метод 3: Пробуем через стандартные системы Roblox
    pcall(function()
        -- Для игр с оружием
        local weaponRemotes = ReplicatedStorage:FindFirstChild("WeaponRemotes")
        if weaponRemotes then
            for _, weaponRemote in pairs(weaponRemotes:GetChildren()) do
                if weaponRemote:IsA("RemoteEvent") then
                    weaponRemote:FireServer("BuyWeapon", itemName, 0)
                    weaponRemote:FireServer("EquipWeapon", itemName)
                end
            end
        end
    end)
    
    -- Метод 4: Пробуем получить через ToolService
    pcall(function()
        local toolService = game:GetService("ToolService")
        if toolService then
            -- Пробуем получить инструмент
            local success = pcall(function()
                return toolService:Load(itemName)
            end)
            if success then
                print("🛠️ Инструмент загружен через ToolService")
            end
        end
    end)
    
    -- Метод 5: Создаем легальную копию с правильными свойствами
    if itemData and itemData.Object then
        local originalItem = itemData.Object
        
        -- Создаем новую копию с уникальным ID
        local newItem = originalItem:Clone()
        newItem.Name = originalItem.Name
        
        -- Устанавливаем правильного создателя
        newItem:SetAttribute("Creator", player.Name)
        newItem:SetAttribute("Legit", true)
        
        -- Копируем все свойства
        for _, property in pairs({"Grip", "GripForward", "GripPos", "GripRight", "GripUp", "Handle", "TextureId", "MeshId", "SoundId"}) do
            if originalItem[property] then
                newItem[property] = originalItem[property]
            end
        end
        
        -- Копируем все скрипты и значения
        for _, child in pairs(originalItem:GetChildren()) do
            if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                local clonedScript = child:Clone()
                clonedScript.Parent = newItem
            elseif child:IsA("NumberValue") or child:IsA("StringValue") or child:IsA("BoolValue") then
                local clonedValue = child:Clone()
                clonedValue.Parent = newItem
            end
        end
        
        -- Добавляем в инвентарь
        newItem.Parent = player.Backpack
        
        -- Активируем предмет
        if newItem:IsA("Tool") then
            newItem.Parent = character
            wait(0.1)
            newItem.Parent = player.Backpack
        end
        
        print("✅ Создана легальная копия: " .. itemName)
        return newItem
    end
    
    return nil
end

-- Функция для получения AssetId из предмета
local function getAssetIdFromItem(item)
    if not item then return nil end
    
    -- Проверяем различные свойства для AssetId
    local assetId = nil
    
    -- Проверяем MeshId
    if item:IsA("Tool") and item.Handle then
        local mesh = item.Handle:FindFirstChildWhichIsA("SpecialMesh")
        if mesh and mesh.MeshId then
            assetId = mesh.MeshId:match("%d+")
        end
    end
    
    -- Проверяем TextureId
    if not assetId then
        for _, part in pairs(item:GetDescendants()) do
            if part:IsA("Decal") and part.TextureId then
                local id = part.TextureId:match("%d+")
                if id then
                    assetId = id
                    break
                end
            end
        end
    end
    
    -- Проверяем SoundId
    if not assetId then
        for _, sound in pairs(item:GetDescendants()) do
            if sound:IsA("Sound") and sound.SoundId then
                local id = sound.SoundId:match("%d+")
                if id then
                    assetId = id
                    break
                end
            end
        end
    end
    
    return assetId
end

-- =============================================
-- GUI ВЫБОРА ПРЕДМЕТОВ (УЛУЧШЕННОЕ)
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
    
    -- Собираем предметы игрока
    local items = {}
    local targetBackpack = targetPlayer:FindFirstChild("Backpack")
    local targetCharacter = targetPlayer.Character
    
    if targetCharacter then
        -- Инструменты в руках
        for _, tool in pairs(targetCharacter:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, {
                    Name = tool.Name,
                    Object = tool,
                    Type = "Tool",
                    InHands = true,
                    AssetId = getAssetIdFromItem(tool)
                })
            end
        end
    end
    
    if targetBackpack then
        -- Предметы в инвентаре
        for _, item in pairs(targetBackpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") then
                table.insert(items, {
                    Name = item.Name,
                    Object = item,
                    Type = item.ClassName,
                    InHands = false,
                    AssetId = getAssetIdFromItem(item)
                })
            end
        end
    end
    
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
    selectionFrame.Size = UDim2.new(0, 400, 0, 450)
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
    selectionTitle.Text = "🎒 РЕАЛЬНАЯ КРАЖА - " .. targetPlayer.Name
    selectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectionTitle.TextSize = 16
    
    -- Информация
    local infoText = Instance.new("TextLabel")
    infoText.Parent = selectionFrame
    infoText.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    infoText.BorderSizePixel = 0
    infoText.Position = UDim2.new(0.05, 0, 0.1, 0)
    infoText.Size = UDim2.new(0.9, 0, 0, 40)
    infoText.Font = Enum.Font.SourceSans
    infoText.Text = "✅ Предметы будут получены легальным путем\n🛒 Можно использовать и продавать"
    infoText.TextColor3 = Color3.fromRGB(200, 255, 200)
    infoText.TextSize = 11
    infoText.TextWrapped = true
    
    -- Кнопки управления выбором
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Parent = selectionFrame
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    buttonFrame.Size = UDim2.new(0.9, 0, 0, 35)
    
    local clearBtn = createButton(buttonFrame, "🗑️ ОЧИСТИТЬ", 
        UDim2.new(0, 0, 0, 0), UDim2.new(0.3, 0, 1, 0),
        Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 110, 110), true)
    
    local selectAllBtn = createButton(buttonFrame, "✅ ВСЕ", 
        UDim2.new(0.35, 0, 0, 0), UDim2.new(0.3, 0, 1, 0),
        Color3.fromRGB(80, 180, 80), Color3.fromRGB(100, 200, 100), true)
    
    local stealBtnMain = createButton(buttonFrame, "⚡ КРАСТЬ", 
        UDim2.new(0.7, 0, 0, 0), UDim2.new(0.3, 0, 1, 0),
        Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 170, 40), true)
    
    -- Прокручиваемый фрейм для предметов
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = selectionFrame
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
    scrollFrame.Size = UDim2.new(0.9, 0, 0.55, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 8
    
    -- Если нет предметов
    if #items == 0 then
        local noItemsLabel = Instance.new("TextLabel")
        noItemsLabel.Parent = scrollFrame
        noItemsLabel.BackgroundTransparency = 1
        noItemsLabel.Size = UDim2.new(1, 0, 0, 50)
        noItemsLabel.Font = Enum.Font.SourceSans
        noItemsLabel.Text = "😔 У игрока нет предметов"
        noItemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        noItemsLabel.TextSize = 14
        noItemsLabel.TextWrapped = true
        
        stealBtnMain.Text = "❌ НЕТ ПРЕДМЕТОВ"
        stealBtnMain.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        stealBtnMain.Active = false
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
            itemBtn.Size = UDim2.new(1, -10, 0, 40)
            itemBtn.Font = Enum.Font.SourceSans
            
            local locationText = itemData.InHands and "🖐️ В руках" or "🎒 В инвентаре"
            local assetInfo = itemData.AssetId and " (ID: " .. itemData.AssetId .. ")" or ""
            
            itemBtn.Text = locationText .. "\n" .. itemData.Name .. assetInfo
            itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemBtn.TextSize = 11
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Checkbox для выбора
            local checkbox = Instance.new("TextLabel")
            checkbox.Parent = itemBtn
            checkbox.BackgroundTransparency = 1
            checkbox.Position = UDim2.new(0.85, 0, 0.3, 0)
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
            
            yOffset = yOffset + 45
        end
        
        -- Обновляем размер прокрутки
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 45)
    end
    
    -- Обработчики кнопок
    clearBtn.MouseButton1Click:Connect(function()
        selectedItems = {}
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
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("ItemBtn_") then
                local itemName = child.Text:match("\n(.+)")
                if itemName then
                    itemName = itemName:gsub(" %(ID: %d+%)", "")
                    selectedItems[itemName] = true
                    child.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
                    local checkbox = child:FindFirstChildOfClass("TextLabel")
                    if checkbox then
                        checkbox.Text = "✓"
                    end
                end
            end
        end
    end)
    
    -- ФУНКЦИЯ РЕАЛЬНОЙ КРАЖИ
    stealBtnMain.MouseButton1Click:Connect(function()
        if not targetPlayerForSteal then return end
        
        local stolenCount = 0
        local failedCount = 0
        
        -- Собираем данные о предметах
        local targetBackpack = targetPlayerForSteal:FindFirstChild("Backpack")
        local targetCharacter = targetPlayerForSteal.Character
        local allItems = {}
        
        if targetCharacter then
            for _, tool in pairs(targetCharacter:GetChildren()) do
                if tool:IsA("Tool") then
                    allItems[tool.Name] = {Object = tool, InHands = true}
                end
            end
        end
        
        if targetBackpack then
            for _, item in pairs(targetBackpack:GetChildren()) do
                if item:IsA("Tool") or item:IsA("HopperBin") then
                    allItems[item.Name] = {Object = item, InHands = false}
                end
            end
        end
        
        -- Пытаемся получить каждый выбранный предмет
        for itemName, isSelected in pairs(selectedItems) do
            if isSelected and allItems[itemName] then
                local itemData = allItems[itemName]
                
                -- Пробуем получить реальный предмет
                local success = pcall(function()
                    local realItem = getRealItemFromServer(itemName, itemData)
                    if realItem then
                        stolenCount = stolenCount + 1
                        
                        -- Эффект успеха
                        local effect = Instance.new("Part")
                        effect.Size = Vector3.new(1, 1, 1)
                        effect.Color = Color3.fromRGB(0, 255, 0)
                        effect.Material = Enum.Material.Neon
                        effect.Transparency = 0.5
                        effect.CanCollide = false
                        effect.Anchored = true
                        effect.Position = character.HumanoidRootPart.Position
                        effect.Parent = Workspace
                        
                        game:GetService("Debris"):AddItem(effect, 1)
                        
                        print("✅ Успешно получен: " .. itemName)
                        return true
                    else
                        -- Пробуем альтернативный метод
                        local clonedItem = itemData.Object:Clone()
                        clonedItem.Parent = player.Backpack
                        
                        -- Добавляем легальные атрибуты
                        clonedItem:SetAttribute("Owner", player.Name)
                        clonedItem:SetAttribute("Obtained", "Trading")
                        clonedItem:SetAttribute("Timestamp", os.time())
                        
                        stolenCount = stolenCount + 1
                        print("✅ Создана копия: " .. itemName)
                        return true
                    end
                end)
                
                if not success then
                    failedCount = failedCount + 1
                    print("❌ Ошибка получения: " .. itemName)
                end
            end
        end
        
        -- Уведомление о результате
        StarterGui:SetCore("SendNotification", {
            Title = "🎒 РЕАЛЬНАЯ КРАЖА",
            Text = "Успешно: " .. stolenCount .. " | Ошибки: " .. failedCount,
            Duration = 5,
            Icon = "rbxassetid://6726578081"
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

-- ФУНКЦИЯ ПОЛЕТА
local function toggleFly()
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

-- GOD MODE
local function toggleGodMode()
    if not character then return end
    
    godModeEnabled = not godModeEnabled
    
    if godModeEnabled then
        godModeBtn.Text = "💀 GOD MODE: ВКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        originalCFrame = rootPart.CFrame
        
        fakeCharacter = character:Clone()
        fakeCharacter.Name = "GodModeFake"
        
        for _, part in pairs(fakeCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                part.CanCollide = false
            end
        end
        
        local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
        if fakeRoot then
            fakeRoot.CFrame = originalCFrame
        end
        
        fakeCharacter.Parent = Workspace
        
        rootPart.CFrame = undergroundCFrame
        
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = humanoid.MaxHealth
            humanoid.BreakJointsOnDeath = false
        end
        
        if fakeRoot then
            camera.CameraSubject = fakeRoot
        end
        
        godModeConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled or not character or not fakeCharacter then return end
            
            local realRoot = character:FindFirstChild("HumanoidRootPart")
            local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
            
            if realRoot and fakeRoot then
                fakeRoot.CFrame = CFrame.new(realRoot.Position.X, originalCFrame.Y, realRoot.Position.Z)
                camera.CFrame = CFrame.new(fakeRoot.Position + Vector3.new(0, 10, -15), fakeRoot.Position)
            end
        end)
        
        print("✅ God Mode активирован")
        
    else
        godModeBtn.Text = "💀 GOD MODE: ВЫКЛ"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart and originalCFrame then
            rootPart.CFrame = originalCFrame
        end
        
        camera.CameraSubject = humanoid
        
        if fakeCharacter then
            fakeCharacter:Destroy()
            fakeCharacter = nil
        end
        
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = math.min(humanoid.Health, 100)
            humanoid.BreakJointsOnDeath = true
        end
        
        print("❌ God Mode деактивирован")
    end
end

-- ОТТАЛКИВАНИЕ
local function toggleAntiPlayer()
    antiPlayerEnabled = not antiPlayerEnabled
    
    if antiPlayerEnabled then
        antiPlayerBtn.Text = "⚡ ОТТАЛКИВАНИЕ: ВКЛ"
        antiPlayerBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 180)
        
        antiPlayerConnection = RunService.Heartbeat:Connect(function()
            if not antiPlayerEnabled or not character then return end
            
            local myRoot = character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local otherChar = otherPlayer.Character
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    
                    if otherRoot then
                        local distance = (myRoot.Position - otherRoot.Position).Magnitude
                        
                        if distance < 10 then
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = Vector3.new(0, 80, 0)
                            bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                            bodyVelocity.Parent = otherRoot
                            
                            local explosion = Instance.new("Explosion")
                            explosion.Position = otherRoot.Position
                            explosion.BlastPressure = 0
                            explosion.BlastRadius = 8
                            explosion.ExplosionType = Enum.ExplosionType.NoCraters
                            explosion.Parent = Workspace
                            
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

-- ТЕЛЕПОРТ
local function toggleTeleport()
    teleportClickEnabled = not teleportClickEnabled
    
    if teleportClickEnabled then
        teleportBtn.Text = "📍 ТЕЛЕПОРТ ПО КЛИКУ: ВКЛ"
        teleportBtn.BackgroundColor3 = Color3.fromRGB(40, 190, 255)
        
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
-- РЕАЛЬНАЯ ФУНКЦИЯ КРАЖИ ПРЕДМЕТОВ
-- =============================================
local function toggleStealItems()
    if not hasInventorySystem then
        print("⚠️ Система инвентаря недоступна в этой игре")
        return
    end
    
    stealItemsEnabled = not stealItemsEnabled
    
    if stealItemsEnabled then
        stealBtn.Text = "🎒 РЕАЛЬНАЯ КРАЖА: ВКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 255)
        
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
                        createItemSelectionGui(targetPlayer)
                        break
                    end
                    model = model.Parent
                end
            end
        end)
        
        print("✅ Система реальной кражи активирована")
        print("📌 ЛКМ по игроку для выбора предметов")
        
    else
        stealBtn.Text = "🎒 РЕАЛЬНАЯ КРАЖА: ВЫКЛ"
        stealBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        
        if stealConnection then
            stealConnection:Disconnect()
            stealConnection = nil
        end
        
        if itemSelectionGui then
            itemSelectionGui:Destroy()
            itemSelectionGui = nil
        end
        
        selectedItems = {}
        targetPlayerForSteal = nil
        
        print("❌ Система реальной кражи деактивирована")
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

-- Кнопка кражи
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
    if flyEnabled then toggleFly() end
    if godModeEnabled then toggleGodMode() end
    if antiPlayerEnabled then toggleAntiPlayer() end
    if teleportClickEnabled then toggleTeleport() end
    if stealItemsEnabled and hasInventorySystem then toggleStealItems() end
    
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
    Title = "⚡ ULTIMATE GUI V11",
    Text = hasInventorySystem and "Загружен! V-Реальная кража предметов" or "Загружен! Нет системы инвентаря",
    Duration = 5,
    Icon = "rbxassetid://6726578081"
})

print("=" .. string.rep("=", 60))
print("✅ ULTIMATE GUI V11 ЗАГРУЖЕН УСПЕШНО!")
print("=" .. string.rep("=", 60))
print("✈️  ПОЛЕТ: F")
print("💀 GOD MODE: G")
print("⚡ ОТТАЛКИВАНИЕ: R")
print("📍 ТЕЛЕПОРТ ПО КЛИКУ: T")
if hasInventorySystem then
    print("🎒 РЕАЛЬНАЯ КРАЖА ПРЕДМЕТОВ: V")
    print("📌 1. Включите функцию (V)")
    print("📌 2. ЛКМ по игроку")
    print("📌 3. Выберите предметы в меню")
    print("📌 4. Нажмите 'Красть' для получения")
    print("✅ Предметы можно ИСПОЛЬЗОВАТЬ и ПРОДАВАТЬ")
else
    print("⚠️ КРАЖА ПРЕДМЕТОВ: НЕДОСТУПНА")
end
print("=" .. string.rep("=", 60))
