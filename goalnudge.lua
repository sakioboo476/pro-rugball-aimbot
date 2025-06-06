local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TELEPORT_DISTANCE = 25 -- max distance to trigger assist
local NUDGE_FORCE = 80       -- how strong to nudge the ball

-- Get Backline2 from each goal
local function getBacklines()
	local backlines = {}
	for _, goalName in {"Blue Goal", "Red Goal"} do
		local goal = workspace:FindFirstChild(goalName)
		if goal and goal:FindFirstChild("Backline2") then
			table.insert(backlines, goal.Backline2)
		end
	end
	return backlines
end

-- Find the loose ball (free in workspace)
local function getFreeBall()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Part") and obj.Name == "Handle" and obj:FindFirstChild("TouchInterest") then
			if not Players:GetPlayerFromCharacter(obj.Parent) then
				return obj
			end
		end
	end
	return nil
end

-- Nudge the ball toward the closest Backline2
local function nudgeTowardBackline(ball, backlines)
	local closestBackline = nil
	local closestDistance = math.huge

	for _, line in ipairs(backlines) do
		local dist = (line.Position - ball.Position).Magnitude
		if dist < closestDistance then
			closestBackline = line
			closestDistance = dist
		end
	end

	if closestBackline and closestDistance <= TELEPORT_DISTANCE then
		local direction = (closestBackline.Position - ball.Position).Unit
		ball.AssemblyLinearVelocity = direction * NUDGE_FORCE
	end
end

-- Loop
RunService.RenderStepped:Connect(function()
	local ball = getFreeBall()
	if not ball then return end

	local backlines = getBacklines()
	if #backlines == 0 then return end

	nudgeTowardBackline(ball, backlines)
end)
