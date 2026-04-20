local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Создание GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PwukikScript"

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
status.Text = "Idle"
status.Font = Enum.Font.Gotham
status.TextSize = 12

-- Управление циклом
local isRunning = false
local currentLoop

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

-- Функция для эмуляции нажатия клавиш
local function pressKey(key)
    if typeof(key) == "EnumItem" then key = key.Name end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end)
end

-- Функция для перемещения персонажа
local function moveTo(targetPos)
    local root = getHumanoidRootPart()
    if not root then return false end
    local humanoid = getCharacter():FindFirstChild("Humanoid")
    if humanoid then
        humanoid:MoveTo(targetPos)
        local startTime = os.clock()
        repeat
            task.wait(0.5)
            if os.clock() - startTime > 5 then break end
        until (root.Position - targetPos).Magnitude < 5
    end
    return true
end

-- Функция для мгновенной телепортации (более быстрый способ)
local function teleportTo(targetPos)
    local root = getHumanoidRootPart()
    if root then
        root.CFrame = CFrame.new(targetPos)
        return true
    end
    return false
end

-- Поиск портала по ключевым словам
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

-- Поиск NPC по ключевым словам
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
            moveTo(head.Position + head.CFrame.LookVector * -3)
            task.wait(2)
            updateStatus("Interacting with " .. npc.Name)
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
        updateStatus("Portal found! Moving...")
        teleportTo(portal.Position + Vector3.new(0, 5, 0))
        task.wait(2)
        updateStatus("Entering portal")
        pressKey(Enum.KeyCode.E)
        task.wait(5)
        updateStatus("Arrived at Hive Hub")
    else
        updateStatus("Portal not found, check console")
        warn("PwukikScript: Portal not found. Available parts with 'portal' in name:")
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("portal") then
                warn(" - " .. v.Name .. " (Parent: " .. v.Parent.Name .. ")")
            end
        end
        updateStatus("Portal not found")
    end
end

local function gameLoop()
    while isRunning do
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
            updateStatus("Waiting next cycle...")
        end)
        if not success then
            updateStatus("Error: " .. tostring(err))
            warn("PwukikScript Error: " .. tostring(err))
        end
        task.wait(8)
    end
    updateStatus("Stopped")
end

btnStart.MouseButton1Click:Connect(function()
    if not isRunning then
        isRunning = true
        updateStatus("Starting...")
        currentLoop = task.spawn(gameLoop)
    end
end)

btnStop.MouseButton1Click:Connect(function()
    isRunning = false
    if currentLoop then
        task.cancel(currentLoop)
        currentLoop = nil
    end
    updateStatus("Stopped")
end)

updateStatus("Ready")