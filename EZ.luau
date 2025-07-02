local CoreGui = game:GetService("CoreGui")

for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "ScreenGui" then
        gui:Destroy()
    end
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "DOIT V.1 |",
    SubTitle = "Steal a Soccer Athlete",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

task.defer(function()
    local UserInputService = game:GetService("UserInputService")
    local MainGUI = CoreGui:WaitForChild("ScreenGui") -- Now exists

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "MobileToggleButton"
    ToggleButton.Size = UDim2.new(0, 60, 0, 40)
    ToggleButton.Position = UDim2.new(0.5, -30, 0, 10)
    ToggleButton.AnchorPoint = Vector2.new(0.5, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ToggleButton.Text = "≡"
    ToggleButton.TextSize = 24
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.BorderSizePixel = 0
    ToggleButton.BackgroundTransparency = 0.1
    ToggleButton.ZIndex = 9999
    ToggleButton.Parent = MainGUI

    local visible = true
    ToggleButton.MouseButton1Click:Connect(function()
        visible = not visible
        for _, obj in ipairs(MainGUI:GetChildren()) do
            if obj ~= ToggleButton then
                obj.Visible = visible
            end
        end
    end)

    local dragging, dragInput, dragStart, startPos
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ToggleButton.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end)

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local function findYourBaseIndex()
    local basesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Bases")
    if not basesFolder then return nil end
    local plrName = plr.Name:lower()
    for i = 1, 8 do
        local base = basesFolder:FindFirstChild(tostring(i))
        if base and base:FindFirstChild("Important") then
            local signPart = base.Important:FindFirstChild("Sign") and base.Important.Sign:FindFirstChild("SignPart")
            if signPart and signPart:FindFirstChild("SurfaceGui") then
                local textLabel = signPart.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
                if textLabel and string.find(textLabel.Text:lower(), plrName, 1, true) then
                    return i
                end
            end
        end
    end
    return nil
end
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

getgenv().Speed = 120
getgenv().Enabled = false
getgenv().executed = false
getgenv().DefaultSpeed = 16 

local function detectDefaultSpeed()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        getgenv().DefaultSpeed = hum.WalkSpeed
    end
end

detectDefaultSpeed() -- run once at start

local function bypassWalkSpeed()
    if getgenv().executed then
        if not getgenv().Enabled then return end
    else
        getgenv().executed = true
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldindex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "WalkSpeed" then
                return getgenv().DefaultSpeed
            end
            return oldindex(self, key)
        end)
    end

    task.spawn(function()
        while getgenv().Enabled do
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = getgenv().Speed
                end
            end
            task.wait()
        end
    end)
end

plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    detectDefaultSpeed()
    if getgenv().Enabled then
        bypassWalkSpeed()
        char.Humanoid.WalkSpeed = getgenv().Speed
    end
end)

Tabs.Main:AddToggle("BoostSpeed", {
    Title = "Boost Speed",
    Description = "Walk faster",
    Default = false,
}):OnChanged(function(state)
    getgenv().Enabled = state
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")

    if state then
        bypassWalkSpeed()
    elseif hum then
        hum.WalkSpeed = getgenv().DefaultSpeed
    end
end)

local instantPromptEnabled = false
local instantPromptLoop = nil
local promptOriginalDurations = {}

local function setPromptInstant(prompt)
    if prompt:IsA("ProximityPrompt") and not promptOriginalDurations[prompt] then
        promptOriginalDurations[prompt] = prompt.HoldDuration
        prompt.HoldDuration = 0
    end
end

local function resetAllPrompts()
    for prompt, original in pairs(promptOriginalDurations) do
        if prompt and prompt:IsDescendantOf(game) then
            prompt.HoldDuration = original
        end
    end
    promptOriginalDurations = {}
end

local function startInstantPromptLoop()
    if instantPromptLoop then return end
    instantPromptLoop = task.spawn(function()
        while instantPromptEnabled do
            for _, v in ipairs(workspace:GetDescendants()) do
                setPromptInstant(v)
            end
            task.wait(1)
        end
    end)
end

Tabs.Main:AddToggle("InstantPrompt", {
    Title = "Fast Steal",
    Description = "Fast steal",
    Default = false,
}):OnChanged(function(state)
    instantPromptEnabled = state
    if state then
        promptOriginalDurations = {}
        startInstantPromptLoop()
    else
        instantPromptEnabled = false
        instantPromptLoop = nil
        resetAllPrompts()
    end
end)



Tabs.Main:AddButton({
    Title = "Teleport to Your Base",
    Description = "TP to your base",
    Callback = function()
        local character = plr.Character or plr.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        local basesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Bases")
        if not basesFolder then
            return
        end

        local foundBaseIndex = findYourBaseIndex()

        if foundBaseIndex then
            local base = basesFolder:FindFirstChild(tostring(foundBaseIndex))
            local lockButton = base and base.Important and base.Important:FindFirstChild("LockButton")
            if lockButton and hrp then
                hrp.CFrame = lockButton.CFrame * CFrame.new(0, 3, 0)
            end
        end
    end
})

Tabs.Main:AddButton({
    Title = "Remove Laser",
    Description = "Remove all laser",
    Callback = function()
        local basesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Bases")
        if not basesFolder then
            return
        end

        local deletedCount = 0
        for i = 1, 8 do
            local base = basesFolder:FindFirstChild(tostring(i))
            if base then
                local barrier = base:FindFirstChild("Barrier")
                if barrier then
                    barrier:Destroy()
                    deletedCount = deletedCount + 1
                end
            end
        end
    end
})

local function parsePrice(priceText)
    local raw = priceText:lower():gsub("[$,]", "")
    local number = tonumber(raw:match("%d+%.?%d*"))
    local suffix = raw:match("[km]")
    if not number then return nil end
    if suffix == "k" then number = number * 1000
    elseif suffix == "m" then number = number * 1000000 end
    return number
end

Tabs.Main:AddSection("Extra")

Tabs.Main:AddButton({
    Title = "Steal Highest Price Player",
    Description = "Steal the highest price player",
    Callback = function()
        local character = plr.Character or plr.CharacterAdded:Wait()
        local playerHRP = character:WaitForChild("HumanoidRootPart")

        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.HoldDuration = 0
            end
        end

        local basesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Bases")
        if not basesFolder then return end

        local yourBaseIndex = findYourBaseIndex()
        if not yourBaseIndex then return end

        local maxPrice = 0
        local targetHRP, targetPrompt = nil, nil

        for baseIndex = 1, 8 do
            if baseIndex ~= yourBaseIndex then
                local base = basesFolder:FindFirstChild(tostring(baseIndex))
                if base and base:FindFirstChild("Important") then
                    local pads = base.Important:FindFirstChild("NPCPads")
                    if pads then
                        for padIndex = 1, 10 do
                            local pad = pads:FindFirstChild(tostring(padIndex))
                            if pad and pad:FindFirstChild("Character") then
                                local char = pad.Character
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    local head = char:FindFirstChild("Head")
                                    if head then
                                        local overhead = head:FindFirstChild("OverHeadAttachment")
                                        if overhead then
                                            local info = overhead:FindFirstChild("CharacterInfo")
                                            if info and info:FindFirstChild("Frame") then
                                                local priceLabel = info.Frame:FindFirstChild("Price")
                                                if priceLabel and priceLabel:IsA("TextLabel") then
                                                    local price = parsePrice(priceLabel.Text)
                                                    if price and price > maxPrice then
                                                        maxPrice = price
                                                        targetHRP = hrp
                                                        targetPrompt = hrp:FindFirstChild("SlotPrompt")
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local yourBase = basesFolder:FindFirstChild(tostring(yourBaseIndex))
        local baseLockButton = yourBase and yourBase.Important and yourBase.Important:FindFirstChild("LockButton")

        if targetHRP and baseLockButton then
            playerHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 0)

            task.wait(0.1)

            if targetPrompt then
                for _ = 1, 6 do
                    fireproximityprompt(targetPrompt, 0.5)
                    task.wait(0.1) 
                end
            end

            playerHRP.CFrame = baseLockButton.CFrame * CFrame.new(0, 3, 0)
        end
    end
})



local lockToggle = Tabs.Main:AddToggle("AutoLockBase", {
    Title = "Auto Lock Your Base",
    Description = "Auto Lock your base",
    Default = false,
})

local autoLockConnection

local function findYourBaseLockButton()
    local basesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Bases")
    if not basesFolder then return nil end
    local yourBaseIndex = findYourBaseIndex()
    if yourBaseIndex then
        local yourBase = basesFolder:FindFirstChild(tostring(yourBaseIndex))
        if yourBase and yourBase:FindFirstChild("Important") then
            return yourBase.Important:FindFirstChild("LockButton")
        end
    end
    return nil
end

local function fireLockTouch()
    local lockButton = findYourBaseLockButton()
    if lockButton then
        for _, ti in pairs(lockButton:GetChildren()) do
            if ti:IsA("TouchTransmitter") or ti.ClassName == "TouchInterest" then
                firetouchinterest(plr.Character.HumanoidRootPart, lockButton, 0)
                firetouchinterest(plr.Character.HumanoidRootPart, lockButton, 1)
            end
        end
    end
end

lockToggle:OnChanged(function(state)
    if state then
        autoLockConnection = game:GetService("RunService").Heartbeat:Connect(function()
            fireLockTouch()
        end)
    else
        if autoLockConnection then
            autoLockConnection:Disconnect()
            autoLockConnection = nil
        end
    end
end)

local currentHighlightChar = nil
local highlightRunning = false
local highlightColor = Color3.new(1,1,1)

local function clearHighlight(character)
    if character then
        local hl = character:FindFirstChild("GetReal")
        if hl then hl:Destroy() end
    end
end

local function highlightHighestPriceNPC()
    local yourBaseIndex = findYourBaseIndex()
    while highlightRunning do
        local maxPrice = 0
        local highestChar = nil

        for baseIndex = 1, 8 do
            if baseIndex ~= yourBaseIndex then 
                local base = Workspace.Map.Bases:FindFirstChild(tostring(baseIndex))
                if base and base:FindFirstChild("Important") then
                    local pads = base.Important:FindFirstChild("NPCPads")
                    if pads then
                        for padIndex = 1, 10 do
                            local pad = pads:FindFirstChild(tostring(padIndex))
                            if pad and pad:FindFirstChild("Character") then
                                local char = pad.Character
                                local head = char:FindFirstChild("Head")
                                if head then
                                    local overhead = head:FindFirstChild("OverHeadAttachment")
                                    if overhead then
                                        local info = overhead:FindFirstChild("CharacterInfo")
                                        if info and info:FindFirstChild("Frame") then
                                            local priceLabel = info.Frame:FindFirstChild("Price")
                                            if priceLabel and priceLabel:IsA("TextLabel") then
                                                local price = parsePrice(priceLabel.Text)
                                                if price and price > maxPrice then
                                                    maxPrice = price
                                                    highestChar = char
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if currentHighlightChar and currentHighlightChar ~= highestChar then
            clearHighlight(currentHighlightChar)
            currentHighlightChar = nil
        end

        if highestChar then
            local hl = highestChar:FindFirstChild("GetReal")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "GetReal"
                hl.RobloxLocked = true
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = highestChar
            end
            hl.FillColor = highlightColor
            hl.OutlineColor = highlightColor
            currentHighlightChar = highestChar
        else
            if currentHighlightChar then
                clearHighlight(currentHighlightChar)
                currentHighlightChar = nil
            end
        end

        task.wait(0.5)
    end
end

local Toggle = Tabs.Main:AddToggle("HighlightHighestNPC", {
    Title = "ESP Highest Price",
    Default = false,
    Description = "ESP for highest price NPC"
})

Toggle:OnChanged(function(value)
    highlightRunning = value
    if value then
        task.spawn(highlightHighestPriceNPC)
    else
        highlightRunning = false
        if currentHighlightChar then
            clearHighlight(currentHighlightChar)
            currentHighlightChar = nil
        end
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "DOIT",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
