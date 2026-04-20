local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

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
title.Text = "PwukikScript"
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

-- Управление
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

local function checkInHiveHub()
    -- Ищем характерные объекты внутри Hive Hub (например, Hub Field)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("hub") or v.Name:lower():find("field")) then
            return true
        end
    end
    return false
end

local function pressKey(key)
    if typeof(key) == "EnumItem" then key = key.Name end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

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

local function findPortal()
    -- Ищем портал по точному имени
    local portal = Workspace:FindFirstChild("Hive Hub Portal", true)
    if portal and portal:IsA("BasePart") then
        return portal
    end
    -- Запасной вариант: ищем в папке World
    local world = Workspace:FindFirstChild("World")
    if world then
        portal = world:FindFirstChild("Hive Hub Portal", true)
        if portal and portal:IsA("BasePart") then
            return portal
        end
    end
    return nil
end

local function findNPC()
    -- Ищем NPC по точному имени
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Sticker-Seeker Quest Machine" then
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
                return v
            end
        end
    end
    return nil
end

local function doQuest()
    updateStatus("Searching NPC...")
    local npc = findNPC()
    if npc then
        local head = npc.Head
        updateStatus("Moving to " .. npc.Name)
        walkTo(head.Position + head.CFrame.LookVector * -3)
        task.wait(2)
        updateStatus("Interacting...")
        pressKey(Enum.KeyCode.E)
        task.wait(2)
        updateStatus("Quest done")
        return true
    else
        updateStatus("NPC not found")
        return false
    end
end

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
        updateStatus("Portal not found")
        return false
    end
end

local function mainLoop()
    while isRunning do
        updateStatus("Checking location...")
        local inHub = checkInHiveHub()
        updateStatus(inHub and "In Hive Hub" or "Going to Hive Hub")
        
        if inHub then
            doQuest()
        else
            local success = goToHiveHub()
            if success then
                task.wait(2)
                doQuest()
            end
        end
        
        updateStatus("Cycle done, waiting...")
        for i = 1, 8 do
            if not isRunning then break end
            task.wait(1)
        end
    end
    updateStatus("Stopped")
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
    updateStatus("Stopped")
end

btnStart.MouseButton1Click:Connect(startLoop)
btnStop.MouseButton1Click:Connect(stopLoop)

-- Автозапуск
startLoop()

player.CharacterAdded:Connect(function()
    if isRunning then
        updateStatus("Respawning...")
        task.wait(2)
    end
end)

updateStatus("Ready")