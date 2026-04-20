local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

-- GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PwukikScript"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 160)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "PwukikScript"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold

local btnStart = Instance.new("TextButton", main)
btnStart.Size = UDim2.new(1, -20, 0, 35)
btnStart.Position = UDim2.new(0, 10, 0, 40)
btnStart.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
btnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
btnStart.Text = "Start"
btnStart.Font = Enum.Font.GothamSemibold
btnStart.TextSize = 14

local btnStop = Instance.new("TextButton", main)
btnStop.Size = UDim2.new(1, -20, 0, 35)
btnStop.Position = UDim2.new(0, 10, 0, 80)
btnStop.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
btnStop.TextColor3 = Color3.fromRGB(255, 255, 255)
btnStop.Text = "Stop"
btnStop.Font = Enum.Font.GothamSemibold
btnStop.TextSize = 14

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 125)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Text = "Auto Starting..."
status.Font = Enum.Font.Gotham
status.TextSize = 12

local isRunning = false
local currentLoop
local isInHiveHub = false

local function updateStatus(text)
    status.Text = text
    task.wait()
end

local function getCharacter()
    return player.Character
end

local function getHumanoidRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function checkIfInHiveHub()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local name = v.Name:lower()
            if name:find("hive") or name:find("hub") then
                return true
            end
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
    local root = getHumanoidRootPart()
    if not root then return false end
    local humanoid = getCharacter():FindFirstChild("Humanoid")
    if not humanoid then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
        WaypointSpacing = 3,
        Costs = { Water = 20, Lava = 1000 }
    })

    local success, err = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in ipairs(waypoints) do
            if not isRunning then break end
            humanoid:MoveTo(wp.Position)
            humanoid.MoveToFinished:Wait()
        end
        return true
    end
    return false
end

local function findPortal()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local name = v.Name:lower()
            if (name:find("hive") or name:find("hub")) and name:find("portal") then
                return v
            end
        end
    end
    return nil
end

local function findNPC()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            local name = v.Name:lower()
            if name:find("sticker") and name:find("seeker") then
                local humanoid = v:FindFirstChild("Humanoid")
                local head = v:FindFirstChild("Head")
                if humanoid and head then
                    return v
                end
            end
        end
    end
    return nil
end

local function doQuest()
    updateStatus("Searching NPC...")
    local npc = findNPC()
    if npc then
        local head = npc:FindFirstChild("Head")
        if head then
            updateStatus("Moving to " .. npc.Name)
            walkTo(head.Position + head.CFrame.LookVector * -3)
            task.wait(2)
            updateStatus("Interacting...")
            pressKey(Enum.KeyCode.E)
            task.wait(2)
            updateStatus("Quest done")
        end
    else
        updateStatus("NPC not found")
    end
end

local function goToHiveHub()
    updateStatus("Looking for portal...")
    local portal = findPortal()
    if portal then
        updateStatus("Portal found! Walking...")
        walkTo(portal.Position)
        task.wait(2)
        updateStatus("Entering portal...")
        local root = getHumanoidRootPart()
        if root then
            root.CFrame = portal.CFrame * CFrame.new(0, 2, 0)
        end
        task.wait(5)
        isInHiveHub = true
        updateStatus("Arrived at Hive Hub")
    else
        updateStatus("Portal not found")
    end
end

local function gameLoop()
    while isRunning do
        local success, err = pcall(function()
            if not getCharacter() then
                updateStatus("Waiting character...")
                task.wait(3)
                return
            end

            isInHiveHub = checkIfInHiveHub()
            updateStatus(isInHiveHub and "In Hive Hub" or "Going to Hive Hub")

            if isInHiveHub then
                doQuest()
            else
                goToHiveHub()
                if isInHiveHub then
                    doQuest()
                else
                    updateStatus("Failed to enter Hive Hub")
                end
            end
            updateStatus("Cycle done, waiting...")
        end)

        if not success then
            updateStatus("Error: " .. tostring(err))
        end

        for i = 1, 8 do
            if not isRunning then break end
            task.wait(1)
        end
    end
    updateStatus("Stopped")
end

local function fullStop()
    isRunning = false
    if currentLoop then
        task.cancel(currentLoop)
        currentLoop = nil
    end
    updateStatus("Stopped")
end

local function startLoop()
    if not isRunning then
        isRunning = true
        updateStatus("Starting...")
        currentLoop = task.spawn(gameLoop)
    end
end

btnStart.MouseButton1Click:Connect(startLoop)
btnStop.MouseButton1Click:Connect(fullStop)

-- Автозапуск
startLoop()

player.CharacterAdded:Connect(function(char)
    if isRunning then
        updateStatus("Respawning...")
        task.wait(2)
        isInHiveHub = checkIfInHiveHub()
        updateStatus("Respawned")
    end
end)

updateStatus("Ready")