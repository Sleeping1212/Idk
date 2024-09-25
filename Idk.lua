local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CamlockState = false
local Prediction = 0.24664 -- Improved Prediction for air and ground shots
local HorizontalPrediction = 0.24664
local VerticalPrediction = 0.14
local Smoothness = 0.75 -- Increased smoothing value for better camera movement

local Locked = true
getgenv().Key = "q"

-- Create Dot on Target (No custom assets to avoid MeshContentProvider error)
local function CreateDot(target)
    local dot = Instance.new("Part")
    dot.Name = "TargetDot"
    dot.Shape = Enum.PartType.Ball -- Use basic shapes without external mesh
    dot.Size = Vector3.new(0.8, 0.8, 0.8) -- Simple 3D sphere
    dot.Color = Color3.fromRGB(255, 0, 0)
    dot.Transparency = 0.4
    dot.Anchored = true
    dot.CanCollide = false
    dot.Position = target.Position -- Start at target's position
    dot.Parent = workspace
    return dot
end

-- Find the nearest enemy function
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = math.huge, nil
    local CenterPosition = workspace.CurrentCamera.ViewportSize / 2

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character.Humanoid.Health > 0 then
                local Position, IsVisibleOnViewport =
                    workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)

                if IsVisibleOnViewport then
                    local Distance = (CenterPosition - Vector2.new(Position.X, Position.Y)).Magnitude
                    if Distance < ClosestDistance then
                        ClosestPlayer = Character.HumanoidRootPart
                        ClosestDistance = Distance
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

local enemy = nil
local dot = nil

-- Helper function for smooth camera movement
local function SmoothMove(targetPosition, smoothness)
    local camera = workspace.CurrentCamera
    camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPosition), smoothness)
end

-- TriggerBot function, now faster and more responsive
local function TriggerBot()
    if not enemy then return end
    local camera = workspace.CurrentCamera
    local targetPosition = enemy.Position + enemy.Velocity * Prediction
    local cameraDirection = (camera.CFrame.LookVector).unit
    local targetDirection = (targetPosition - camera.CFrame.Position).unit
    
    local angle = math.acos(cameraDirection:Dot(targetDirection))
    
    -- Trigger faster by adjusting the angle threshold
    if angle > math.rad(2) then -- If the camera is off by more than 2 degrees, adjust faster
        SmoothMove(targetPosition, Smoothness)
    end
end

-- Aim Assist, Silent Aim, and Camlock function
RunService.Heartbeat:Connect(function()
    if CamlockState and enemy then
        local camera = workspace.CurrentCamera
        -- TriggerBot logic to adjust camera if not locked perfectly
        TriggerBot()

        -- Adjust prediction if Locked
        if Locked then
            local offsetX = math.random(-1, 1) * HorizontalPrediction
            local offsetY = math.random(-1, 1) * VerticalPrediction
            camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(offsetX), 0)
            camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(offsetY), 0, 0)
        end

        -- Move the dot to enemy position
        if dot then
            dot.Position = enemy.Position
        end
    end
end)

Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            enemy = FindNearestEnemy()
            CamlockState = true
            if enemy then
                dot = CreateDot(enemy)
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Locked On",
                    Text = "Locked onto: " .. enemy.Parent.Name,
                    Duration = 2
                })
            end
        else
            enemy = nil
            CamlockState = false
            if dot then
                dot:Destroy()
                dot = nil
            end
        end
    end
end)

-- Button UI
local Camlock = Instance.new("ScreenGui")
Camlock.Name = "Camlock"
Camlock.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 202, 0, 70)
Frame.Position = UDim2.new(0.5, -101, 0.5, -35) -- Centered on screen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = Camlock

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame

local TextButton = Instance.new("TextButton")
TextButton.Size = UDim2.new(0, 170, 0, 44)
TextButton.Position = UDim2.new(0.079, 0, 0.185, 0)
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextScaled = true
TextButton.Text = "Toggle CamLock"
TextButton.Parent = Frame

local state = true
TextButton.MouseButton1Click:Connect(function()
    state = not state
    if state then
        TextButton.Text = "Camlock ON"
        CamlockState = true
        enemy = FindNearestEnemy()
        if enemy then
            dot = CreateDot(enemy)
            game.StarterGui:SetCore("SendNotification", {
                Title = "Locked On",
                Text = "Locked onto: " .. enemy.Parent.Name,
                Duration = 2
            })
        end
    else
        TextButton.Text = "Camlock OFF"
        CamlockState = false
        enemy = nil
        if dot then
            dot:Destroy()
            dot = nil
        end
    end
end)

-- Load and error logging
local function main()
    local success, err = pcall(function()
        print("Camlock has loaded successfully")
    end)

    if not success then
        warn("Error loading Camlock: " .. err)
    end
end

main()
