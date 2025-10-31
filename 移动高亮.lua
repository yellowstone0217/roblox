-- 放在 StarterPlayer > StarterPlayerScripts 中
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 等待玩家加载
player:WaitForChild("PlayerGui")

-- 创建移动物体高亮GUI
local highlightGui = Instance.new("ScreenGui")
highlightGui.Name = "MovementHighlighter"
highlightGui.ResetOnSpawn = false
highlightGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 主框架
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.1, 0, 0.8, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- 圆角
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- 边框
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 150)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- 标题文字
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "移动物体高亮"
titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.Parent = titleBar

-- 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

-- 内容区域
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -40)
contentFrame.Position = UDim2.new(0, 10, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- 状态显示
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "移动物体高亮已启用\n红色轮廓显示移动的物体"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.TextWrapped = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = contentFrame

-- 设置按钮
local settingsButton = Instance.new("TextButton")
settingsButton.Size = UDim2.new(1, 0, 0, 30)
settingsButton.Position = UDim2.new(0, 0, 0, 50)
settingsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
settingsButton.Text = "高亮设置"
settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.TextScaled = true
settingsButton.Font = Enum.Font.Gotham
settingsButton.Parent = contentFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 6)
settingsCorner.Parent = settingsButton

-- 开关按钮
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.Position = UDim2.new(0, 0, 0, 90)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
toggleButton.Text = "关闭高亮"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = contentFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- 高亮系统变量
local highlightEnabled = true
local trackedObjects = {}
local objectHighlights = {}
local lastPositions = {}

-- 高亮设置
local highlightSettings = {
    maxDistance = 100,  -- 最大检测距离
    minMovement = 0.1,  -- 最小移动距离阈值
    updateInterval = 0.1, -- 更新间隔
    outlineColor = Color3.new(1, 0, 0), -- 红色轮廓
    outlineTransparency = 0.3, -- 轮廓透明度
    alwaysOnTop = true -- 是否始终在前（透墙）
}

-- 关闭按钮事件
closeButton.MouseButton1Click:Connect(function()
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    
    tween.Completed:Connect(function()
        highlightGui:Destroy()
        -- 同时关闭高亮功能
        highlightEnabled = false
        clearAllHighlights()
    end)
end)

-- 开关按钮事件
toggleButton.MouseButton1Click:Connect(function()
    highlightEnabled = not highlightEnabled
    
    if highlightEnabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        toggleButton.Text = "关闭高亮"
        statusLabel.Text = "移动物体高亮已启用\n红色轮廓显示移动的物体"
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
        toggleButton.Text = "开启高亮"
        statusLabel.Text = "移动物体高亮已禁用"
        clearAllHighlights()
    end
end)

-- 设置按钮事件
settingsButton.MouseButton1Click:Connect(function()
    openSettingsMenu()
end)

-- 清除所有高亮
function clearAllHighlights()
    for _, highlight in pairs(objectHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    objectHighlights = {}
    lastPositions = {}
end

-- 检查物体是否应该被高亮
function shouldHighlightObject(obj)
    -- 排除玩家自身
    if obj:IsDescendantOf(player.Character) then
        return false
    end
    
    -- 排除基础地形
    if obj.Name == "Baseplate" or obj.Name == "Terrain" then
        return false
    end
    
    -- 只处理部分和模型
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then
        return false
    end
    
    -- 检查距离
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local objPosition
    if obj:IsA("BasePart") then
        objPosition = obj.Position
    elseif obj:IsA("Model") then
        local primaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
        if primaryPart then
            objPosition = primaryPart.Position
        else
            return false
        end
    end
    
    local distance = (rootPart.Position - objPosition).Magnitude
    if distance > highlightSettings.maxDistance then
        return false
    end
    
    return true
end

-- 检查物体是否在移动
function isObjectMoving(obj)
    local currentPosition
    
    if obj:IsA("BasePart") then
        currentPosition = obj.Position
    elseif obj:IsA("Model") then
        local primaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
        if primaryPart then
            currentPosition = primaryPart.Position
        else
            return false
        end
    end
    
    -- 获取上次位置
    local lastPosition = lastPositions[obj]
    
    -- 更新当前位置
    lastPositions[obj] = currentPosition
    
    -- 如果是第一次检测，不视为移动
    if not lastPosition then
        return false
    end
    
    -- 计算移动距离
    local movement = (currentPosition - lastPosition).Magnitude
    
    -- 检查是否超过移动阈值
    return movement > highlightSettings.minMovement
end

-- 为物体添加高亮
function addHighlightToObject(obj)
    if objectHighlights[obj] then
        return -- 已经存在高亮
    end
    
    -- 创建高亮效果
    local highlight = Instance.new("Highlight")
    highlight.Adornee = obj
    highlight.FillColor = highlightSettings.outlineColor
    highlight.FillTransparency = 1  -- 完全透明填充，只显示轮廓
    highlight.OutlineColor = highlightSettings.outlineColor
    highlight.OutlineTransparency = highlightSettings.outlineTransparency
    
    if highlightSettings.alwaysOnTop then
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    
    highlight.Parent = obj
    objectHighlights[obj] = highlight
    
    -- 当物体被销毁时移除高亮
    obj.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if objectHighlights[obj] then
                objectHighlights[obj]:Destroy()
                objectHighlights[obj] = nil
            end
            lastPositions[obj] = nil
        end
    end)
end

-- 移除物体的高亮
function removeHighlightFromObject(obj)
    if objectHighlights[obj] then
        objectHighlights[obj]:Destroy()
        objectHighlights[obj] = nil
    end
end

-- 高亮系统主循环
local lastUpdate = 0
local highlightConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if not highlightEnabled then return end
    
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < highlightSettings.updateInterval then
        return
    end
    lastUpdate = 0
    
    local character = player.Character
    if not character then return end
    
    -- 获取玩家周围的物体
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local playerPosition = rootPart.Position
    local region = Region3.new(
        playerPosition - Vector3.new(highlightSettings.maxDistance, highlightSettings.maxDistance, highlightSettings.maxDistance),
        playerPosition + Vector3.new(highlightSettings.maxDistance, highlightSettings.maxDistance, highlightSettings.maxDistance)
    )
    
    local objects = workspace:FindPartsInRegion3(region, nil, math.huge)
    
    -- 跟踪当前帧的物体
    local currentFrameObjects = {}
    
    for _, obj in pairs(objects) do
        if shouldHighlightObject(obj) then
            currentFrameObjects[obj] = true
            
            if isObjectMoving(obj) then
                addHighlightToObject(obj)
            else
                removeHighlightFromObject(obj)
            end
        end
    end
    
    -- 移除不再范围内的物体的高亮
    for obj in pairs(objectHighlights) do
        if not currentFrameObjects[obj] and obj.Parent then
            removeHighlightFromObject(obj)
        end
    end
end)

-- 设置菜单
function openSettingsMenu()
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(0, 280, 0, 200)
    settingsFrame.Position = UDim2.new(0.5, -140, 0.5, -100)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = highlightGui
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsFrame
    
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, 0, 0, 30)
    settingsTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    settingsTitle.Text = "高亮设置"
    settingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsTitle.TextScaled = true
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.Parent = settingsFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = settingsTitle
    
    -- 距离设置
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, -20, 0, 20)
    distanceLabel.Position = UDim2.new(0, 10, 0, 40)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "检测距离: " .. highlightSettings.maxDistance
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = settingsFrame
    
    local distanceSlider = Instance.new("TextButton")
    distanceSlider.Size = UDim2.new(1, -20, 0, 20)
    distanceSlider.Position = UDim2.new(0, 10, 0, 65)
    distanceSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    distanceSlider.Text = ""
    distanceSlider.Parent = settingsFrame
    
    local distanceSliderCorner = Instance.new("UICorner")
    distanceSliderCorner.CornerRadius = UDim.new(0, 4)
    distanceSliderCorner.Parent = distanceSlider
    
    -- 透墙设置
    local wallhackToggle = Instance.new("TextButton")
    wallhackToggle.Size = UDim2.new(1, -20, 0, 30)
    wallhackToggle.Position = UDim2.new(0, 10, 0, 95)
    wallhackToggle.BackgroundColor3 = highlightSettings.alwaysOnTop and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(120, 80, 80)
    wallhackToggle.Text = "透墙显示: " .. (highlightSettings.alwaysOnTop and "开" or "关")
    wallhackToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    wallhackToggle.TextScaled = true
    wallhackToggle.Font = Enum.Font.Gotham
    wallhackToggle.Parent = settingsFrame
    
    local wallhackCorner = Instance.new("UICorner")
    wallhackCorner.CornerRadius = UDim.new(0, 6)
    wallhackCorner.Parent = wallhackToggle
    
    -- 关闭设置按钮
    local closeSettings = Instance.new("TextButton")
    closeSettings.Size = UDim2.new(0, 100, 0, 30)
    closeSettings.Position = UDim2.new(0.5, -50, 1, -40)
    closeSettings.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeSettings.Text = "关闭设置"
    closeSettings.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeSettings.TextScaled = true
    closeSettings.Font = Enum.Font.Gotham
    closeSettings.Parent = settingsFrame
    
    local closeSettingsCorner = Instance.new("UICorner")
    closeSettingsCorner.CornerRadius = UDim.new(0, 6)
    closeSettingsCorner.Parent = closeSettings
    
    -- 按钮事件
    wallhackToggle.MouseButton1Click:Connect(function()
        highlightSettings.alwaysOnTop = not highlightSettings.alwaysOnTop
        wallhackToggle.BackgroundColor3 = highlightSettings.alwaysOnTop and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(120, 80, 80)
        wallhackToggle.Text = "透墙显示: " .. (highlightSettings.alwaysOnTop and "开" or "关")
        
        -- 更新所有高亮的DepthMode
        for _, highlight in pairs(objectHighlights) do
            if highlightSettings.alwaysOnTop then
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            end
        end
    end)
    
    closeSettings.MouseButton1Click:Connect(function()
        settingsFrame:Destroy()
    end)
end

-- 组装GUI
mainFrame.Parent = highlightGui
highlightGui.Parent = player.PlayerGui

-- 添加打开动画
mainFrame.Size = UDim2.new(0, 0, 0, 0)
local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 180)})
openTween:Play()

print("移动物体高亮系统已加载！")
print("使用说明：")
print("- 长按标题栏拖动窗口")
print("- 点击X按钮完全关闭系统")
print("- 使用开关按钮临时启用/禁用高亮")
print("- 点击设置按钮调整参数")

-- 当GUI被销毁时断开连接
highlightGui.Destroying:Connect(function()
    if highlightConnection then
        highlightConnection:Disconnect()
    end
    clearAllHighlights()
end)
