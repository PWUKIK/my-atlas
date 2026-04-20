-- PwukikScript v4.0 (Stable & Optimized)
local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

-- 1. Мятный GUI
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
title.Text = "PwukikScript v4"
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

-- 2. Управление циклом
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

-- 3. Надёжное взаимодействие с объектами (имитация нажатия E)
local function pressKey(key)
    if typeof(key) == "EnumItem" then key = key.Name end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

-- 4. Функция для ходьбы
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

-- 5. Поиск портала (точное имя, найденное в игре)
local function findPortal()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "Hive Hub Portal" then
            return v
        end
    end
    return nil
end

-- 6. Поиск NPC Sticker-Seeker (точное имя)
local function findNPC()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Sticker-Seeker Quest Machine" then
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
                return v
            end
        end
    end
    return nil
end

-- 7. Выполнение квеста
local function doQuest()
    updateStatus("Ищем NPC...")
    local npc = findNPC()
    if npc then
        local head = npc.Head
        updateStatus("Идём к " .. npc.Name)
        walkTo(head.Position + head.CFrame.LookVector * -3)
        task.wait(2)
        updateStatus("Взаимодействие...")
        pressKey(Enum.KeyCode.E)
        task.wait(2)
        updateStatus("Квест выполнен")
        return true
    else
        updateStatus("NPC не найден")
        return false
    end
end

-- 8. Переход в Hive Hub
local function goToHiveHub()
    updateStatus("Ищем портал...")
    local portal = findPortal()
    if portal then
        updateStatus("Идём к порталу...")
        walkTo(portal.Position)
        task.wait(2)
        updateStatus("Входим в портал...")
        local root = getRoot()
        if root then
            root.CFrame = portal.CFrame * CFrame.new(0, 2, 0)
        end
        task.wait(5)
        updateStatus("Прибыли в Hive Hub")
        return true
    else
        updateStatus("Портал не найден")
        return false
    end
end

-- 9. Проверка, находимся ли мы в Hive Hub
local function isInHiveHub()
    return findNPC() ~= nil
end

-- 10. Главный цикл
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
                doQuest()
            else
                updateStatus("Ищем путь в Hive Hub...")
                local success = goToHiveHub()
                if success then
                    task.wait(2)
                    doQuest()
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

-- 11. Управление кнопками
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

-- 12. Автозапуск
startLoop()

player.CharacterAdded:Connect(function()
    if isRunning then
        updateStatus("Возрождение...")
        task.wait(2)
    end
end)

updateStatus("Готов к работе (v4)")