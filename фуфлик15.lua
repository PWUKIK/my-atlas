-- PwukikScript v3.0 (Atlas-Inspired & Completely Revamped)
local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local QuestService = game:GetService("QuestService")

-- Мятный GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PwukikScript"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 160)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(152, 255, 152)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "PwukikScript v3"
title.TextColor3 = Color3.fromRGB(0, 0, 0)
title.TextSize = 18
title.Font = Enum.Font.GothamBold

local btnStart = Instance.new("TextButton", main)
btnStart.Size = UDim2.new(1, -20, 0, 35)
btnStart.Position = UDim2.new(0, 10, 0, 40)
btnStart.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
btnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
btnStart.Text = "Start"
btnStart.Font = Enum.Font.GothamSemibold
btnStart.TextSize = 14

local btnStop = Instance.new("TextButton", main)
btnStop.Size = UDim2.new(1, -20, 0, 35)
btnStop.Position = UDim2.new(0, 10, 0, 80)
btnStop.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
btnStop.TextColor3 = Color3.fromRGB(255, 255, 255)
btnStop.Text = "Stop"
btnStop.Font = Enum.Font.GothamSemibold
btnStop.TextSize = 14

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 125)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(0, 0, 0)
status.Text = "Auto Starting..."
status.Font = Enum.Font.Gotham
status.TextSize = 12

local isRunning = false
local currentLoop

local function updateStatus(text)
    status.Text = text
    task.wait()
end

local function getChar()
    return player.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Функция для проверки, находимся ли мы в Hive Hub (взята из структуры Atlas)
local function isInHiveHub()
    -- В Hive Hub есть уникальные объекты, например, Sticker-Seeker Quest Machine
    local npc = Workspace:FindFirstChild("Sticker-Seeker Quest Machine", true)
    return npc ~= nil
end

-- Функция для поиска портала в Hive Hub (используем точный путь, как в Atlas)
local function findHiveHubPortal()
    local portalsFolder = Workspace:FindFirstChild("Portals")
    if portalsFolder then
        local portal = portalsFolder:FindFirstChild("Hive Hub Portal")
        if portal and portal:IsA("BasePart") then
            return portal
        end
    end
    return nil
end

-- Функция для поиска NPC Sticker-Seeker (используем точный путь)
local function findStickerSeekerNPC()
    local npcsFolder = Workspace:FindFirstChild("NPCS")
    if npcsFolder then
        local modelsFolder = npcsFolder:FindFirstChild("Models")
        if modelsFolder then
            local npc = modelsFolder:FindFirstChild("Sticker-Seeker Quest Machine")
            if npc and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("Head") then
                return npc
            end
        end
    end
    return nil
end

local function pressKey(key)
    if typeof(key) == "EnumItem" then key = key.Name end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

-- Продвинутая функция ходьбы с использованием PathfindingService
local function walkTo(targetPos)
    local root = getRoot()
    local humanoid = getChar() and getChar():FindFirstChild("Humanoid")
    if not root or not humanoid then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
        WaypointSpacing = 3,
    })

    local success = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not isRunning then break end
            humanoid:MoveTo(wp.Position)
            humanoid.MoveToFinished:Wait()
        end
        return true
    end
    return false
end

-- Функция для взаимодействия с NPC (использует ProximityPromptService, как в Atlas)
local function interactWithNpc(npc)
    local head = npc:FindFirstChild("Head")
    if not head then return false end

    local prompts = head:GetDescendants()
    for _, prompt in ipairs(prompts) do
        if prompt:IsA("ProximityPrompt") then
            ProximityPromptService:Prompt(prompt)
            return true
        end
    end
    return false
end

-- Функция для проверки, есть ли активный квест Sticker-Seeker
local function hasActiveStickerSeekerQuest()
    for _, quest in ipairs(QuestService:GetActiveQuests()) do
        if quest.Name == "Sticker Seeker Quest" or quest.Title == "Sticker Seeker Quest" then
            return true
        end
    end
    return false
end

-- Функция для входа в портал
local function enterPortal(portal)
    local root = getRoot()
    if not root then return false end
    root.CFrame = portal.CFrame * CFrame.new(0, 2, 0)
    task.wait(5) -- Ожидаем загрузки локации
    return true
end

-- Основная логика квеста
local function doQuestCycle()
    updateStatus("Поиск NPC...")
    local npc = findStickerSeekerNPC()
    if not npc then
        updateStatus("NPC не найден!")
        return false
    end

    -- Проверяем, есть ли активный квест
    local hasQuest = hasActiveStickerSeekerQuest()

    updateStatus("Идём к NPC...")
    walkTo(npc.Head.Position + npc.Head.CFrame.LookVector * -3)

    if hasQuest then
        updateStatus("Сдаём квест...")
    else
        updateStatus("Берём новый квест...")
    end

    task.wait(2)
    interactWithNpc(npc)
    task.wait(2)
    updateStatus("Взаимодействие завершено.")
    return true
end

-- Главный цикл
local function mainLoop()
    while isRunning do
        local success, err = pcall(function()
            if not getChar() then
                updateStatus("Ожидание персонажа...")
                task.wait(3)
                return
            end

            if isInHiveHub() then
                updateStatus("В Hive Hub. Выполняем квест...")
                doQuestCycle()
            else
                updateStatus("Ищем портал в Hive Hub...")
                local portal = findHiveHubPortal()
                if portal then
                    updateStatus("Идём к порталу...")
                    walkTo(portal.Position)
                    task.wait(2)
                    enterPortal(portal)
                    updateStatus("Вошли в Hive Hub.")
                    task.wait(2)
                    doQuestCycle()
                else
                    updateStatus("Портал не найден!")
                end
            end
            
            updateStatus("Цикл завершен. Ожидание...")
        end)
        
        if not success then
            updateStatus("Ошибка: " .. tostring(err))
        end
        
        for i = 1, 8 do
            if not isRunning then break end
            task.wait(1)
        end
    end
    updateStatus("Остановлен")
end

local function startLoop()
    if not isRunning then
        isRunning = true
        currentLoop = task.spawn(mainLoop)
    end
end

local function stopLoop()
    isRunning = false
    if currentLoop then
        task.cancel(currentLoop)
    end
    updateStatus("Остановлен")
end

btnStart.MouseButton1Click:Connect(startLoop)
btnStop.MouseButton1Click:Connect(stopLoop)

-- Автозапуск при инжекте
startLoop()

player.CharacterAdded:Connect(function()
    if isRunning then
        updateStatus("Возрождение...")
        task.wait(2)
    end
end)

updateStatus("Готов к работе (v3)")