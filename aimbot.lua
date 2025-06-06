-- Pro Rugball Curve Aimbot with Distance Display
-- For executor use (client-side)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- Create GUI for distance label
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

-- Find closest InnerRing
local function getClosestGoal(fromPos)
	local closest, minDist = nil, math.huge
	for _, v in pairs(workspace:GetDescendants()) do
		if v.Name == "InnerRing" and v:IsA("BasePart") then
			local dist = (v.Position - fromPos).Magnitude
			if dist < minDist then
				closest, minDist = v, dist
			end
		end
	end
	return closest, minDist
end

-- Curve the ball to the goal
local function curveBall(ball, goal)
	if not (ball and goal) then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = (goal.Position - ball.Position).Unit * 120
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = ball
	Debris:AddItem(bv, 0.5)
end

-- Track thrown tools
local toolHooked = {}

local function hookTool(tool)
	if toolHooked[tool] then return end
	toolHooked[tool] = true
	tool.Activated:Connect(function()
		local handle = tool:FindFirstChildWhichIsA("BasePart")
		if not handle then return end

		task.spawn(function()
			while handle:IsDescendantOf(player.Character) do task.wait() end
			task.wait(0.1)

			local goal, dist = getClosestGoal(handle.Position)
			if goal then
				label.Text = ("Distance: %.1f studs"):format(dist)
				if dist <= 35 and handle.Velocity.Magnitude > 10 then
					curveBall(handle, goal)
				end
			else
				label.Text = "No Goal Found"
			end
		end)
	end)
end

-- Hook existing & future tools
for _, t in pairs(player.Backpack:GetChildren()) do
	if t:IsA("Tool") then hookTool(t) end
end
player.Backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then hookTool(child) end
end)
char.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then hookTool(child) end
end)

-- Update distance label in real-time
RunService.RenderStepped:Connect(function()
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local handle = tool:FindFirstChildWhichIsA("BasePart")
		if handle then
			local goal, dist = getClosestGoal(handle.Position)
			if goal then
				label.Text = ("Distance: %.1f studs"):format(dist)
			else
				label.Text = "No Goal Found"
			end
		end
	end
end)
