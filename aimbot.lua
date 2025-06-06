-- Pro Rugball Curve Aimbot with Distance Display (Backline2 Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- GUI
local function createDistanceLabel()
	local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	gui.Name = "GoalDistanceGUI"
	local label = Instance.new("TextLabel", gui)
	label.Size = UDim2.new(0, 200, 0, 50)
	label.Position = UDim2.new(0.5, -100, 0, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Name = "GoalDistanceLabel"
	return label
end

local label = createDistanceLabel()

-- Find closest goal (Backline2 is actual scoring part)
local function getClosestGoal(fromPos)
	local closest, minDist = nil, math.huge
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "Backline2" then
			local dist = (v.Position - fromPos).Magnitude
			if dist < minDist then
				closest, minDist = v, dist
			end
		end
	end
	return closest, minDist
end

-- Apply curve force to ball
local function curveBall(ball, goal)
	if not (ball and goal) then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = (goal.Position - ball.Position).Unit * 120
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.P = 1250
	bv.Parent = ball
	Debris:AddItem(bv, 0.5)
end

-- Detect ball in workspace after it's thrown
local function waitForBallFromTool(handle)
	local timeout = 2
	local startTime = tick()
	while tick() - startTime < timeout do
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj ~= handle and (obj.Position - handle.Position).Magnitude < 5 and obj.Name == handle.Name then
				return obj
			end
		end
		task.wait(0.05)
	end
end

-- Tool activation
local hooked = {}
local function hookTool(tool)
	if hooked[tool] then return end
	hooked[tool] = true

	tool.Activated:Connect(function()
		local handle = tool:FindFirstChildWhichIsA("BasePart")
		if not handle then return end

		task.spawn(function()
			-- Wait until handle is detached from character
			local waitTime = 0
			repeat wait(0.05) waitTime += 0.05 until not handle:IsDescendantOf(player.Character) or waitTime > 1.5
			wait(0.1)

			local ball = waitForBallFromTool(handle)
			if ball then
				local goal, dist = getClosestGoal(ball.Position)
				if goal then
					label.Text = ("Distance: %.1f studs"):format(dist)
					if dist <= 35 and ball.Velocity.Magnitude > 10 then
						curveBall(ball, goal)
					end
				end
			else
				label.Text = "Ball not found in workspace"
			end
		end)
	end)
end

-- Hook all existing tools
for _, t in pairs(player.Backpack:GetChildren()) do
	if t:IsA("Tool") then hookTool(t) end
end
player.Backpack.ChildAdded:Connect(function(c)
	if c:IsA("Tool") then hookTool(c) end
end)
char.ChildAdded:Connect(function(c)
	if c:IsA("Tool") then hookTool(c) end
end)

-- Update GUI constantly
RunService.RenderStepped:Connect(function()
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local handle = tool:FindFirstChildWhichIsA("BasePart")
		if handle then
			local goal, dist = getClosestGoal(handle.Position)
			if goal then
				label.Text = ("Distance: %.1f studs"):format(dist)
			end
		end
	end
end)
