--[[
  DEV TEST PANEL for YOUR OWN Roblox experience.
  Place this LocalScript in: StarterPlayer > StarterPlayerScripts
  Runs only in Roblox Studio (not in public servers).
  Features: free 360-degree flight, local noclip, WalkSpeed control,
  player ESP, rarity ESP (Mythic/Legendary/Secret/Divine), FPS and ping.

  Rarity detection checks:
    1) Attributes named Rarity, rarity, Tier, or tier
    2) StringValue descendants with those names
    3) Object name text as a fallback

  For item ESP, put collectible models/parts in Workspace and set their
  Rarity attribute (recommended), e.g. Model:SetAttribute("Rarity", "Mythic").
]]

if not game:GetService("RunService"):IsStudio() then
    warn("DEV TEST PANEL: Studio-only.")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("DevTestPanel")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DevTestPanel"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(330, 510)
main.Position = UDim2.new(0, 24, 0.5, -255)
main.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(78, 88, 115)
stroke.Thickness = 1
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 38)
title.Position = UDim2.fromOffset(14, 5)
title.BackgroundTransparency = 1
title.Text = "DEV TEST PANEL"
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -39, 0, 8)
close.Text = "×"
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(145, 55, 65)
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(12, 48)
content.Size = UDim2.new(1, -24, 1, -60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.fromOffset(0, 0)
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
end)

local function section(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(145, 177, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
    return label
end

local function button(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(42, 46, 59)
    b.TextColor3 = Color3.fromRGB(238, 241, 250)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function inputRow(labelText, defaultText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 36)
    row.BackgroundTransparency = 1
    row.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.56, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(225, 229, 240)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.42, 0, 1, 0)
    box.Position = UDim2.new(0.58, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(42, 46, 59)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.PlaceholderColor3 = Color3.fromRGB(160, 165, 180)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Text = defaultText
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then callback(n) else box.Text = defaultText end
    end)
    return box
end

-- Make the panel draggable.
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local character, humanoid, root
local function bindCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end
if player.Character then task.spawn(bindCharacter, player.Character) end
player.CharacterAdded:Connect(bindCharacter)

local flyOn, noclipOn = false, false
local flySpeed, walkSpeed = 80, 16
local flyAttachment, flyVelocity, flyOrientation
local savedWalkSpeed = 16
local keys = {W=false, A=false, S=false, D=false, Up=false, Down=false}

local function stopFly()
    flyOn = false
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyOrientation then flyOrientation:Destroy(); flyOrientation = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    if humanoid then humanoid.PlatformStand = false end
end

local function startFly()
    if not root or not humanoid then return end
    stopFly()
    flyOn = true
    humanoid.PlatformStand = true
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "DevFlyAttachment"
    flyAttachment.Parent = root

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "DevFlyVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.MaxForce = math.huge
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root

    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "DevFlyOrientation"
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.Responsiveness = 18
    flyOrientation.MaxTorque = math.huge
    flyOrientation.Parent = root
end

section("MOVEMENT")
local flyButton
flyButton = button("Fly 360°: OFF", function()
    if flyOn then
        stopFly()
        flyButton.Text = "Fly 360°: OFF"
    else
        startFly()
        flyButton.Text = "Fly 360°: ON"
    end
end)

local noclipButton
noclipButton = button("Noclip: OFF", function()
    noclipOn = not noclipOn
    noclipButton.Text = "Noclip: " .. (noclipOn and "ON" or "OFF")
end)

inputRow("Fly speed", "80", function(n) flySpeed = math.clamp(n, 1, 1000) end)
inputRow("WalkSpeed (max 10000)", "16", function(n)
    walkSpeed = math.clamp(n, 0, 10000)
    if humanoid then humanoid.WalkSpeed = walkSpeed end
end)

section("ESP")
local playerEspOn, itemEspOn = false, false
local rarityEnabled = {Mythic=true, Legendary=true, Secret=true, Divine=true}
local playerHighlights = {}
local itemHighlights = {}

local function clearHighlights(container)
    for obj, h in pairs(container) do
        if h and h.Parent then h:Destroy() end
        container[obj] = nil
    end
end

local function addHighlight(obj, container, fill, outline)
    if not obj or not obj.Parent or container[obj] then return end
    local h = Instance.new("Highlight")
    h.Adornee = obj
    h.FillColor = fill
    h.OutlineColor = outline
    h.FillTransparency = 0.72
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = gui
    container[obj] = h
end

local function updatePlayerESP()
    clearHighlights(playerHighlights)
    if not playerEspOn then return end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            addHighlight(other.Character, playerHighlights,
                Color3.fromRGB(255, 80, 100), Color3.fromRGB(255, 220, 225))
        end
    end
end

local rarityColors = {
    Mythic = Color3.fromRGB(255, 80, 190),
    Legendary = Color3.fromRGB(255, 190, 55),
    Secret = Color3.fromRGB(170, 95, 255),
    Divine = Color3.fromRGB(90, 220, 255),
}

local function getRarity(obj)
    local keysToCheck = {"Rarity", "rarity", "Tier", "tier"}
    for _, key in ipairs(keysToCheck) do
        local value = obj:GetAttribute(key)
        if typeof(value) == "string" then
            for rarity in pairs(rarityColors) do
                if string.lower(value) == string.lower(rarity) then return rarity end
            end
        end
    end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("StringValue") then
            for _, key in ipairs(keysToCheck) do
                if string.lower(child.Name) == string.lower(key) then
                    for rarity in pairs(rarityColors) do
                        if string.lower(child.Value) == string.lower(rarity) then return rarity end
                    end
                end
            end
        end
    end
    local lowerName = string.lower(obj.Name)
    for rarity in pairs(rarityColors) do
        if string.find(lowerName, string.lower(rarity), 1, true) then return rarity end
    end
    return nil
end

local function updateItemESP()
    clearHighlights(itemHighlights)
    if not itemEspOn then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)
            if rarity and rarityEnabled[rarity] then
                addHighlight(obj, itemHighlights, rarityColors[rarity], Color3.new(1,1,1))
            end
        end
    end
end

local playerEspButton
playerEspButton = button("Player ESP: OFF", function()
    playerEspOn = not playerEspOn
    playerEspButton.Text = "Player ESP: " .. (playerEspOn and "ON" or "OFF")
    updatePlayerESP()
end)

local itemEspButton
itemEspButton = button("Item ESP: OFF", function()
    itemEspOn = not itemEspOn
    itemEspButton.Text = "Item ESP: " .. (itemEspOn and "ON" or "OFF")
    updateItemESP()
end)

for rarity, color in pairs(rarityColors) do
    local b
    b = button(rarity .. ": ON", function()
        rarityEnabled[rarity] = not rarityEnabled[rarity]
        b.Text = rarity .. ": " .. (rarityEnabled[rarity] and "ON" or "OFF")
        b.TextColor3 = rarityEnabled[rarity] and color or Color3.fromRGB(150,150,150)
        updateItemESP()
    end)
    b.TextColor3 = color
end

section("STATUS")
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -4, 0, 28)
status.BackgroundColor3 = Color3.fromRGB(35, 39, 50)
status.TextColor3 = Color3.fromRGB(200, 220, 255)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Text = "FPS: --   |   Ping: --"
status.Parent = content
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

-- Input handling for keyboard flight. On mobile, use the camera direction
-- and jump buttons; the GUI itself remains touch-draggable.
local keyMap = {
    [Enum.KeyCode.W] = "W", [Enum.KeyCode.A] = "A",
    [Enum.KeyCode.S] = "S", [Enum.KeyCode.D] = "D",
    [Enum.KeyCode.Space] = "Up", [Enum.KeyCode.LeftControl] = "Down",
}
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local key = keyMap[input.KeyCode]
    if key then keys[key] = true end
end)
UserInputService.InputEnded:Connect(function(input)
    local key = keyMap[input.KeyCode]
    if key then keys[key] = false end
end)

local fpsFrames, fpsElapsed, currentFps = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
    fpsFrames += 1
    fpsElapsed += dt
    if fpsElapsed >= 1 then
        currentFps = math.floor(fpsFrames / fpsElapsed)
        fpsFrames, fpsElapsed = 0, 0
        local ping = "--"
        pcall(function()
            ping = tostring(math.floor(player:GetNetworkPing() * 1000 + 0.5)) .. " ms"
        end)
        status.Text = "FPS: " .. currentFps .. "   |   Ping: " .. ping
    end

    if flyOn and root and flyVelocity and flyOrientation then
        local camera = Workspace.CurrentCamera
        if camera then
            local cf = camera.CFrame
            local move = Vector3.zero
            if keys.W then move += cf.LookVector end
            if keys.S then move -= cf.LookVector end
            if keys.D then move += cf.RightVector end
            if keys.A then move -= cf.RightVector end
            if keys.Up then move += Vector3.yAxis end
            if keys.Down then move -= Vector3.yAxis end
            if move.Magnitude > 0 then move = move.Unit end
            flyVelocity.VectorVelocity = move * flySpeed
            flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, cf.LookVector, Vector3.yAxis)
        end
    end

    if noclipOn and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait(1)
    updatePlayerESP()
end)
Players.PlayerRemoving:Connect(updatePlayerESP)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if flyOn then startFly() end
    if playerEspOn then updatePlayerESP() end
end)

-- Press RightShift to reopen the panel after closing it.
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

print("DEV TEST PANEL loaded. Press RightShift to show/hide.")
