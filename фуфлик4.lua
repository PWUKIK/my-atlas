local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

-- GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PwukikScript"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 140)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "PwukikScript v2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold

local btn = Instance.new("TextButton", main)
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 40)
btn.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Text = "Start Quest Loop"
btn.Font = Enum.Font.GothamSemibold
btn.TextSize = 14

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 90)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Text = "Idle"
status.Font = Enum.Font.Gotham
status.TextSize = 12

-- Вспомогательные функции
local function updateStatus(text)
    status.Text = text
    task.wait()
end

local function getCharacter()
    return player.Character
end

local function getHumanoidRootPart()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Функция для эмуляции нажатия клавиш (более безопасный способ взаимодействия)
local function pressKey(key)
    if typeof(key) == "EnumItem" then
        key = key.Name
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

-- Функция для плавного перемещения персонажа
local function moveTo(targetPosition)
    local root = getHumanoidRootPart()
    if not root then return false end
    
    local humanoid = getCharacter():FindFirstChild("Humanoid")
    if humanoid then
        humanoid:MoveTo(targetPosition)
        local startTime = os.clock()
        repeat
            task.wait(0.5)
            if os.clock() - startTime > 5 then break end
        until (root.Position - targetPosition).Magnitude < 5
    end
    return true
end

-- Функция поиска NPC
local function findNPC(namePatterns)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            local humanoid = v:FindFirstChild("Humanoid")
            local head = v:FindFirstChild("Head")
            if humanoid and head then
                for _, pattern in ipairs(namePatterns) do
                    if string.find(v.Name:lower(), pattern:lower()) then
                        return v
                    end
                end
            end
        end
    end
    return nil
end

-- Функция выполнения квеста
local function doQuest()
    updateStatus("Searching for NPC...")
    
    -- Поиск NPC по ключевым словам
    local npc = findNPC({"Sticker", "Seeker", "Canvas", "Quest"})
    if npc then
        local head = npc:FindFirstChild("Head")
        if head then
            updateStatus("Moving to " .. npc.Name)
            local targetPos = head.Position + (head.CFrame.LookVector * -3)
            moveTo(targetPos)
            task.wait(2)
            
            -- Эмуляция нажатия 'E' для взаимодействия (стандартная клавиша)
            updateStatus("Interacting with " .. npc.Name)
            pressKey(Enum.KeyCode.E)
            task.wait(2)
            updateStatus("Quest interaction done")
        end
    else
        updateStatus("NPC not found")
    end
end

-- Функция для перехода в Hive Hub
local function goToHiveHub()
    updateStatus("Looking for Hive Hub...")
    
    -- Поиск портала по ключевым словам
    local portal = nil
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.find(v.Name:lower(), "hive") and string.find(v.Name:lower(), "portal") then
            portal = v
            break
        end
    end
    
    if portal then
        updateStatus("Moving to Hive Hub Portal")
        moveTo(portal.Position)
        task.wait(2)
        
        -- Входим в портал с помощью клавиши 'E'
        updateStatus("Entering Hive Hub Portal")
        pressKey(Enum.KeyCode.E)
        task.wait(5) -- Ожидание загрузки локации
        updateStatus("Arrived at Hive Hub")
    else
        updateStatus("Portal not found, walking to spawn")
        -- Перемещаемся в зону спавна (Hive Hub — это начальная зона)
        moveTo(Vector3.new(0, 10, 0))
        task.wait(3)
        updateStatus("At spawn area (Hive Hub)")
    end
end

-- Основной цикл с обработкой ошибок
local function gameLoop()
    while true do
        local success, err = pcall(function()
            if not getCharacter() then
                updateStatus("Waiting for character...")
                task.wait(3)
                return
            end
            
            updateStatus("Checking quest...")
            goToHiveHub()
            task.wait(2)
            doQuest()
            updateStatus("Waiting for next cycle...")
        end)
        
        if not success then
            updateStatus("Error: " .. tostring(err))
            print("PwukikScript Error:", err)
        end
        
        task.wait(8) -- Длинная пауза между циклами для стабильности
    end
end

-- Запуск по кнопке
btn.MouseButton1Click:Connect(function()
    updateStatus("Starting loop...")
    task.spawn(gameLoop)
end)

updateStatus("Ready. Press 'Start Quest Loop'")