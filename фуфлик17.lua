-- PwukikScript v6.0 (Auto Sticker Seeker Quest)
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
main.Size = UDim2.new(0, 260, 0, 180)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(152, 255, 152)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "PwukikScript"
title.TextColor3 = Color3.fromRGB(0, 0, 0)
title.TextSize = 18
title.Font = Enum.Font.GothamBold

local btnStart = Instance.new("TextButton", main)
btnStart.Size = UDim2.new(1, -20, 0, 35)
btnStart.Position = UDim2.new(0, 10, 0, 40)
btnStart.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
btnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
btnStart.Text = "Start Questing"
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
status.Text = "Ready"
status.Font = Enum.Font.Gotham
status.TextSize = 12

local progress = Instance.new("TextLabel", main)
progress.Size = UDim2.new(1, -20, 0, 20)
progress.Position = UDim2.new(0, 10, 0, 145)
progress.BackgroundTransparency = 1
progress.TextColor3 = Color3.fromRGB(0, 0, 0)
progress.Text = ""
progress.Font = Enum.Font.Gotham
progress.TextSize = 12

-- 2. Управление циклом
local isRunning = false
local currentLoop
local collectedStickers = 0
local requiredStickers = 0

local function updateStatus(text)
    status.Text = text
    task.wait()
end

local function updateProgress(text)
    progress.Text = text
    task.wait()
end

local function getChar()
    return player.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function pressKey(key)
    if typeof(key) == "EnumItem" then key = key.Name end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

-- 3. Ходьба
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

-- 4. Проверка экипировки Sticker-Seeker
local function hasStickerSeeker()
    local character = getChar()
    if not character then return false end
    
    local tool = character:FindFirstChild("Sticker-Seeker")
    return tool ~= nil
end

-- 5. Поиск квестовой машины
local function findQuestMachine()
    local possibleNames = {
        "Sticker-Seeker Quest Machine",
        "Sticker Seeker Quest Machine",
        "Quest Machine"
    }
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            for _, name in ipairs(possibleNames) do
                if v.Name == name and v:FindFirstChild("Head") then
                    return v
                end
            end
        end
    end
    return nil
end

-- 6. Поиск портала в Hive Hub
local function findPortal()
    local possibleNames = {
        "Hive Hub Portal",
        "Portal_HiveHub",
        "HiveHubPortal",
        "Hive Hub"
    }
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            for _, name in ipairs(possibleNames) do
                if v.Name == name then
                    return v
                end
            end
        end
    end
    return nil
end

-- 7. Проверка, находимся ли мы в Hive Hub
local function isInHiveHub()
    return findQuestMachine() ~= nil
end

-- 8. Поиск ВСЕХ Seeker Stickers в мире
local function findAllSeekerStickers()
    local stickers = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and string.find(v.Name:lower(), "seeker sticker") then
            if v:FindFirstChild("ClickDetector") or v:FindFirstChild("ProximityPrompt") then
                table.insert(stickers, v)
            end
        end
    end
    return stickers
end

-- 9. Взаимодействие с квестовой машиной (взять/сдать квест)
local function interactWithQuestMachine()
    local machine = findQuestMachine()
    if not machine then return false end
    
    local head = machine:FindFirstChild("Head")
    if not head then return false end
    
    updateStatus("Moving to Quest Machine...")
    walkTo(head.Position + head.CFrame.LookVector * -3)
    task.wait(2)
    
    updateStatus("Interacting with Quest Machine...")
    pressKey(Enum.KeyCode.E)
    task.wait(3) -- Даём время на загрузку интерфейса квеста
    
    -- Нажимаем "Accept" если есть кнопка (через GUI или Remote)
    pcall(function()
        local guiService = game:GetService("GuiService")
        local screenGui = player.PlayerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local acceptButton = screenGui:FindFirstChild("AcceptButton", true)
            if acceptButton and acceptButton:IsA("TextButton") then
                firesignal(acceptButton.MouseButton1Click)
            end
        end
    end)
    
    return true
end

-- 10. Сбор одного стикера
local function collectSticker(sticker)
    local root = getRoot()
    if not root then return false end
    
    updateStatus("Collecting: " .. sticker.Name)
    local success = walkTo(sticker:GetPivot().Position)
    if not success then
        updateStatus("Failed to reach " .. sticker.Name)
        return false
    end
    
    task.wait(1)
    
    -- Активируем ClickDetector
    local clickDetector = sticker:FindFirstChild("ClickDetector")
    if clickDetector then
        pcall(function()
            clickDetector:Click()
        end)
    end
    
    -- Активируем ProximityPrompt (нажатие E)
    local prompt = sticker:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        pcall(function()
            pressKey(Enum.KeyCode.E)
        end)
    end
    
    task.wait(1)
    collectedStickers = collectedStickers + 1
    updateProgress("Collected: " .. collectedStickers .. "/" .. requiredStickers)
    return true
end

-- 11. Переход в Hive Hub
local function goToHiveHub()
    updateStatus("Looking for portal...")
    local portal = findPortal()
    if portal then
        updateStatus("Walking to portal...")
        walkTo(portal.Position)
        task.wait(2)
        updateStatus("Entering portal...")
        local root = getRoot()
        if root then
            root.CFrame = portal.CFrame * CFrame.new(0, 2, 0)
        end
        task.wait(5)
        updateStatus("Arrived in Hive Hub")
        return true
    else
        updateStatus("Portal not found!")
        return false
    end
end

-- 12. Главный цикл квеста
local function mainLoop()
    while isRunning do
        local success, err = pcall(function()
            if not getChar() then
                updateStatus("Waiting for character...")
                task.wait(3)
                return
            end
            
            -- Проверяем наличие Sticker-Seeker
            if not hasStickerSeeker() then
                updateStatus("Equip Sticker-Seeker first!")
                task.wait(5)
                return
            end
            
            -- Шаг 1: Перемещаемся в Hive Hub, если не там
            if not isInHiveHub() then
                updateStatus("Going to Hive Hub...")
                if not goToHiveHub() then
                    updateStatus("Failed to enter Hive Hub")
                    task.wait(5)
                    return
                end
            end
            
            -- Шаг 2: Взаимодействуем с квестовой машиной
            updateStatus("Interacting with Quest Machine...")
            interactWithQuestMachine()
            
            -- Шаг 3: Ищем и собираем Seeker Stickers
            updateStatus("Scanning for Seeker Stickers...")
            local stickers = findAllSeekerStickers()
            
            if #stickers > 0 then
                requiredStickers = #stickers
                collectedStickers = 0
                updateStatus("Found " .. #stickers .. " Seeker Stickers")
                updateProgress("Collected: 0/" .. requiredStickers)
                
                for _, sticker in ipairs(stickers) do
                    if not isRunning then break end
                    collectSticker(sticker)
                end
                
                updateStatus("All Seeker Stickers collected!")
                
                -- Шаг 4: Возвращаемся в Hive Hub (если вышли) и сдаём квест
                if not isInHiveHub() then
                    goToHiveHub()
                end
                
                updateStatus("Returning to Quest Machine...")
                interactWithQuestMachine()
                updateStatus("Quest completed!")
            else
                updateStatus("No Seeker Stickers found")
            end
            
            updateStatus("Cycle done. Waiting...")
            updateProgress("")
        end)
        
        if not success then
            updateStatus("Error: " .. tostring(err))
        end
        
        -- Пауза перед следующим циклом
        for i = 1, 10 do
            if not isRunning then break end
            task.wait(1)
        end
    end
    updateStatus("Stopped")
    updateProgress("")
end

-- 13. Управление кнопками
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
    updateStatus("Stopped")
    updateProgress("")
end

btnStart.MouseButton1Click:Connect(startLoop)
btnStop.MouseButton1Click:Connect(stopLoop)

updateStatus("Ready. Press Start Questing")