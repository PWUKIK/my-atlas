local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "PwukikScript"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 200, 0, 120)
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

local plr = game.Players.LocalPlayer
local function teleport(cf)
    local char = plr.Character or plr.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = cf
end

local function findNpc(name)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == name and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            return v
        end
    end
    return nil
end

local function doQuest()
    local npc = findNpc("Sticker Seeker")
    if npc then
        local head = npc.Head
        teleport(head.CFrame * CFrame.new(0, 0, -5))
        wait(0.5)
        fireproximityprompt(head, 0)
        wait(1)
    end
end

local function goToHiveHub()
    local portal = workspace:FindFirstChild("Portal_HiveHub", true)
    if portal and portal:IsA("BasePart") then
        teleport(portal.CFrame * CFrame.new(0, 5, 0))
        wait(2)
        local touchPart = portal:FindFirstChildWhichIsA("TouchTransmitter")
        if touchPart then
            firetouchinterest(plr.Character.HumanoidRootPart, portal, 0)
            firetouchinterest(plr.Character.HumanoidRootPart, portal, 1)
        end
    else
        teleport(CFrame.new(-1500, 50, 1000))
    end
    wait(3)
end

btn.MouseButton1Click:Connect(function()
    status.Text = "Running..."
    spawn(function()
        while true do
            status.Text = "Checking quest..."
            goToHiveHub()
            wait(1)
            doQuest()
            wait(5)
        end
    end)
end)