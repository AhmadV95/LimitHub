--// Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--// Create ScreenGui
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "ExecutorDetectorUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--// Create main frame
local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 420, 0, 220)
frame.Position = UDim2.new(0.5, -210, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 6

--// Create label
local label = Instance.new("TextLabel")
label.Parent = frame
label.Size = UDim2.new(1, 0, 0.6, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.SourceSansBold
label.TextScaled = true
label.Text = "Detecting Executor..."

--// Create button
local button = Instance.new("TextButton")
button.Parent = frame
button.Size = UDim2.new(0.65, 0, 0.25, 0)
button.Position = UDim2.new(0.175, 0, 0.7, 0)
button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
button.BorderColor3 = Color3.fromRGB(40, 40, 40)
button.BorderSizePixel = 2
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true
button.Text = "Copy KRNL.vip"
button.Visible = false

-- Clipboard function
local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    elseif syn and syn.setclipboard then
        syn.setclipboard(text)
    else
        warn("Clipboard not supported.")
    end
end

-- Detection
task.wait(2)
local isDelta = false

if identifyexecutor then
    local exec = identifyexecutor()
    if typeof(exec) == "string" and string.lower(exec):find("delta") then
        isDelta = true
    end
elseif _G.DeltaExecute or (getexecutorname and getexecutorname() == "Delta") then
    isDelta = true
end

-- Action
if isDelta then
    label.Text = "You're using Delta.\nThis script doesn't work on Delta.\nUse KRNL or another executor."
    button.Visible = true
    button.MouseButton1Click:Connect(function()
        copyToClipboard("https://krnl.vip")
        button.Text = "Copied!"
        task.wait(2)
        button.Text = "Copy KRNL.vip"
    end)
else
    label.Text = "Executor OK. Running Script..."
    task.wait(1)
    screenGui:Destroy()

    -- ✅ Safe to run script now
    loadstring(game:HttpGet("https://pastefy.app/fJnI69gN/raw"))()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/FakeModz/LimitHub/refs/heads/main/LimitHub_Loader.lua')))()
end
