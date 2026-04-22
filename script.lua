task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local highlights = {}
local billboards = {}
local highlightsEnabled = false

local aimAssistEnabled = false
local aimStrength = 10
local fovRadius = 150
local aimAtPart = "HumanoidRootPart"
local showFOVCircle = false
local verticalOffset = 2
local skipTeammates = false

local fovCircleGui = nil
local fovCircleFrame = nil

-- Movement variables
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil
local noclipEnabled = false
local noclipConnection = nil

-- Player variables
local godModeEnabled = false
local godModeConnection = nil
local invisEnabled = false

-- Server invisibility
local serverInvisEnabled = false
local serverInvisConnection = nil
local serverInvisCameraConnection = nil
local serverInvisOriginalCF = nil
local serverInvisCameraPitch = 0
local serverInvisCameraYaw = 0
local SKY_HEIGHT = 50000

-- Freecam variables
local freecamEnabled = false
local freecamConnection = nil
local freecamSpeed = 50
local originalCameraType = nil
local originalCameraSubject = nil
local freecamPart = nil

-- Chat log variables
local chatLogEnabled = false
local chatLogGui = nil
local chatLogFrame = nil
local chatLogScroll = nil
local chatMessages = {}
local playerChatConnections = {}

-- =====================
--   RAYFIELD UI
-- =====================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "ESP & Aim Script",
	LoadingTitle = "ESP & Aim Script",
	LoadingSubtitle = "by you",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = { Enabled = false },
	KeySystem = false,
})

-- =====================
--   ESP TAB
-- =====================

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
	Name = "Enable ESP",
	CurrentValue = false,
	Flag = "ESPToggle",
	Callback = function(value)
		highlightsEnabled = value
		for _, h in pairs(highlights) do
			if h then h.Enabled = highlightsEnabled end
		end
		for _, b in pairs(billboards) do
			if b then b.Enabled = highlightsEnabled end
		end
	end,
})

-- =====================
--   AIM ASSIST TAB
-- =====================

local AimTab = Window:CreateTab("Aim Assist", 4483362458)
AimTab:CreateSection("Aim Assist Settings")

AimTab:CreateToggle({
	Name = "Enable Aim Assist",
	CurrentValue = false,
	Flag = "AimAssistToggle",
	Callback = function(value)
		aimAssistEnabled = value
	end,
})

AimTab:CreateSlider({
	Name = "Aim Strength (1-30)",
	Range = {1, 30},
	Increment = 1,
	CurrentValue = 10,
	Flag = "AimStrengthSlider",
	Callback = function(value)
		aimStrength = value
	end,
})

AimTab:CreateSlider({
	Name = "FOV Radius (30-400px)",
	Range = {30, 400},
	Increment = 5,
	Suffix = "px",
	CurrentValue = 150,
	Flag = "AimFOVSlider",
	Callback = function(value)
		fovRadius = value
	end,
})

AimTab:CreateSlider({
	Name = "Vertical Offset (0-5 studs)",
	Range = {0, 5},
	Increment = 0.5,
	Suffix = " studs",
	CurrentValue = 2,
	Flag = "VerticalOffsetSlider",
	Callback = function(value)
		verticalOffset = value
	end,
})

AimTab:CreateSection("Target Settings")

AimTab:CreateDropdown({
	Name = "Aim At",
	Options = {"Head", "UpperTorso", "HumanoidRootPart"},
	CurrentOption = {"HumanoidRootPart"},
	Flag = "AimAtDropdown",
	Callback = function(selected)
		aimAtPart = selected[1]
	end,
})

AimTab:CreateToggle({
	Name = "Skip Teammates",
	CurrentValue = false,
	Flag = "SkipTeammatesToggle",
	Callback = function(value)
		skipTeammates = value
	end,
})

AimTab:CreateSection("Visualisation")

AimTab:CreateToggle({
	Name = "Show FOV Circle",
	CurrentValue = false,
	Flag = "FOVCircleToggle",
	Callback = function(value)
		showFOVCircle = value
		if value then
			fovCircleGui = Instance.new("ScreenGui")
			fovCircleGui.Name = "FOVCircleGui"
			fovCircleGui.ResetOnSpawn = false
			fovCircleGui.IgnoreGuiInset = true
			fovCircleGui.DisplayOrder = 998
			fovCircleGui.Parent = localPlayer.PlayerGui

			local size = fovRadius * 2
			fovCircleFrame = Instance.new("Frame")
			fovCircleFrame.Size = UDim2.new(0, size, 0, size)
			fovCircleFrame.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
			fovCircleFrame.BackgroundTransparency = 1
			fovCircleFrame.BorderSizePixel = 0
			fovCircleFrame.Parent = fovCircleGui

			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = fovCircleFrame

			local uiStroke = Instance.new("UIStroke")
			uiStroke.Thickness = 1.5
			uiStroke.Color = Color3.fromRGB(255, 255, 255)
			uiStroke.Transparency = 0.3
			uiStroke.Parent = fovCircleFrame
		else
			if fovCircleGui then
				fovCircleGui:Destroy()
				fovCircleGui = nil
				fovCircleFrame = nil
			end
		end
	end,
})

-- =====================
--   MOVEMENT TAB
-- =====================

local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateSection("Walk & Jump")

MovementTab:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 300},
	Increment = 1,
	Suffix = " studs/s",
	CurrentValue = 16,
	Flag = "WalkSpeedSlider",
	Callback = function(value)
		local character = localPlayer.Character
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then humanoid.WalkSpeed = value end
	end,
})

MovementTab:CreateSlider({
	Name = "Jump Power",
	Range = {50, 500},
	Increment = 5,
	Suffix = " power",
	CurrentValue = 50,
	Flag = "JumpPowerSlider",
	Callback = function(value)
		local character = localPlayer.Character
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then humanoid.JumpPower = value end
	end,
})

MovementTab:CreateSection("Noclip")

MovementTab:CreateToggle({
	Name = "Enable Noclip",
	CurrentValue = false,
	Flag = "NoclipToggle",
	Callback = function(value)
		noclipEnabled = value
		if noclipEnabled then
			noclipConnection = RunService.Stepped:Connect(function()
				local character = localPlayer.Character
				if not character then return end
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end)
		else
			if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
			local character = localPlayer.Character
			if not character then return end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = true end
			end
		end
	end,
})

MovementTab:CreateSection("Flight")

MovementTab:CreateToggle({
	Name = "Enable Fly",
	CurrentValue = false,
	Flag = "FlyToggle",
	Callback = function(value)
		flyEnabled = value
		local character = localPlayer.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not root or not humanoid then return end

		if flyEnabled then
			humanoid.PlatformStand = true
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.zero
			bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			bodyVelocity.Parent = root
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			bodyGyro.P = 1e4
			bodyGyro.CFrame = root.CFrame
			bodyGyro.Parent = root

			flyConnection = RunService.Heartbeat:Connect(function()
				local character = localPlayer.Character
				if not character then return end
				local root = character:FindFirstChild("HumanoidRootPart")
				if not root then return end
				local moveVector = Vector3.zero
				local camCFrame = camera.CFrame
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += camCFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= camCFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= camCFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += camCFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.new(0,1,0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector -= Vector3.new(0,1,0) end
				bodyVelocity.Velocity = moveVector.Magnitude > 0 and moveVector.Unit * flySpeed or Vector3.zero
				bodyGyro.CFrame = camCFrame
			end)
		else
			humanoid.PlatformStand = false
			if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
			if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
			if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
		end
	end,
})

MovementTab:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 500},
	Increment = 5,
	Suffix = " studs/s",
	CurrentValue = 50,
	Flag = "FlySpeedSlider",
	Callback = function(value)
		flySpeed = value
	end,
})

MovementTab:CreateSection("Freecam")

MovementTab:CreateToggle({
	Name = "Enable Freecam",
	CurrentValue = false,
	Flag = "FreecamToggle",
	Callback = function(value)
		freecamEnabled = value
		if freecamEnabled then
			originalCameraType = camera.CameraType
			originalCameraSubject = camera.CameraSubject
			freecamPart = Instance.new("Part")
			freecamPart.Anchored = true
			freecamPart.CanCollide = false
			freecamPart.Transparency = 1
			freecamPart.Size = Vector3.new(1,1,1)
			freecamPart.CFrame = camera.CFrame
			freecamPart.Parent = workspace
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = freecamPart.CFrame

			freecamConnection = RunService.Heartbeat:Connect(function(dt)
				local moveVector = Vector3.zero
				local camCFrame = camera.CFrame
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += camCFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= camCFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= camCFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += camCFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0,1,0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0,1,0) end
				if moveVector.Magnitude > 0 then
					freecamPart.CFrame = freecamPart.CFrame + moveVector.Unit * freecamSpeed * dt
					camera.CFrame = CFrame.new(freecamPart.CFrame.Position) * (camCFrame - camCFrame.Position)
				end
			end)
		else
			if freecamConnection then freecamConnection:Disconnect(); freecamConnection = nil end
			if freecamPart then freecamPart:Destroy(); freecamPart = nil end
			camera.CameraType = originalCameraType or Enum.CameraType.Custom
			camera.CameraSubject = originalCameraSubject or (localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid"))
		end
	end,
})

MovementTab:CreateSlider({
	Name = "Freecam Speed",
	Range = {5, 200},
	Increment = 5,
	Suffix = " studs/s",
	CurrentValue = 50,
	Flag = "FreecamSpeedSlider",
	Callback = function(value)
		freecamSpeed = value
	end,
})

localPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	local humanoid = character:WaitForChild("Humanoid")
	local wsValue = Rayfield.Flags["WalkSpeedSlider"]
	local jpValue = Rayfield.Flags["JumpPowerSlider"]
	if wsValue then humanoid.WalkSpeed = wsValue.Value end
	if jpValue then humanoid.JumpPower = jpValue.Value end

	if noclipEnabled then
		if noclipConnection then noclipConnection:Disconnect() end
		noclipConnection = RunService.Stepped:Connect(function()
			local c = localPlayer.Character
			if not c then return end
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end

	if godModeEnabled then
		if godModeConnection then godModeConnection:Disconnect() end
		local newHumanoid = character:WaitForChild("Humanoid")
		godModeConnection = newHumanoid.HealthChanged:Connect(function()
			if godModeEnabled then newHumanoid.Health = newHumanoid.MaxHealth end
		end)
	end

	if serverInvisEnabled then
		serverInvisEnabled = false
		if serverInvisConnection then serverInvisConnection:Disconnect(); serverInvisConnection = nil end
		if serverInvisCameraConnection then serverInvisCameraConnection:Disconnect(); serverInvisCameraConnection = nil end
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = character:WaitForChild("Humanoid")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if flyEnabled then
		flyEnabled = false
		if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
		if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
		if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
	end
end)

-- =====================
--   PLAYER TAB
-- =====================

local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("God Mode")

PlayerTab:CreateToggle({
	Name = "Enable God Mode",
	CurrentValue = false,
	Flag = "GodModeToggle",
	Callback = function(value)
		godModeEnabled = value
		local character = localPlayer.Character
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end
		if godModeEnabled then
			humanoid.Health = humanoid.MaxHealth
			godModeConnection = humanoid.HealthChanged:Connect(function()
				if godModeEnabled then humanoid.Health = humanoid.MaxHealth end
			end)
		else
			if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
		end
	end,
})

PlayerTab:CreateSection("Invisibility (Client Only)")

PlayerTab:CreateToggle({
	Name = "Enable Client Invisibility",
	CurrentValue = false,
	Flag = "InvisToggle",
	Callback = function(value)
		invisEnabled = value
		local character = localPlayer.Character
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.LocalTransparencyModifier = invisEnabled and 1 or 0
			end
		end
	end,
})

PlayerTab:CreateSection("Invisibility (Server Side)")

PlayerTab:CreateToggle({
	Name = "Enable Server Invisibility",
	CurrentValue = false,
	Flag = "ServerInvisToggle",
	Callback = function(value)
		serverInvisEnabled = value
		local character = localPlayer.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not root or not humanoid then return end

		if serverInvisEnabled then
			-- Save current ground position
			serverInvisOriginalCF = root.CFrame

			-- Get current camera yaw to start from
			local _, yaw, _ = camera.CFrame:ToEulerAnglesYXZ()
			serverInvisCameraYaw = math.deg(yaw)
			serverInvisCameraPitch = 0

			-- Take over camera
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = serverInvisOriginalCF

			-- Lock mouse for looking around
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

			-- Mouse look delta
			serverInvisCameraConnection = UserInputService.InputChanged:Connect(function(input)
				if not serverInvisEnabled then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					serverInvisCameraYaw   = serverInvisCameraYaw - input.Delta.X * 0.3
					serverInvisCameraPitch = math.clamp(serverInvisCameraPitch - input.Delta.Y * 0.3, -80, 80)
				end
			end)

			serverInvisConnection = RunService.Heartbeat:Connect(function(dt)
				local character = localPlayer.Character
				if not character then return end
				local root = character:FindFirstChild("HumanoidRootPart")
				if not root then return end

				-- Build camera CFrame from yaw/pitch so we know look direction
				local camCFrame = CFrame.new(serverInvisOriginalCF.Position)
					* CFrame.Angles(0, math.rad(serverInvisCameraYaw), 0)
					* CFrame.Angles(math.rad(serverInvisCameraPitch), 0, 0)

				-- WASD moves the ground anchor position
				local moveSpeed = 16
				local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
				local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)
				local moveVector = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += flatLook.Magnitude > 0 and flatLook.Unit or Vector3.zero end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= flatLook.Magnitude > 0 and flatLook.Unit or Vector3.zero end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= flatRight.Magnitude > 0 and flatRight.Unit or Vector3.zero end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += flatRight.Magnitude > 0 and flatRight.Unit or Vector3.zero end

				if moveVector.Magnitude > 0 then
					local newPos = serverInvisOriginalCF.Position + moveVector.Unit * moveSpeed * dt
					serverInvisOriginalCF = CFrame.new(newPos)
				end

				-- Update camera to new position
				camCFrame = CFrame.new(serverInvisOriginalCF.Position)
					* CFrame.Angles(0, math.rad(serverInvisCameraYaw), 0)
					* CFrame.Angles(math.rad(serverInvisCameraPitch), 0, 0)
				camera.CFrame = camCFrame

				-- Shove character into sky every frame so others can't see it
				root.CFrame = CFrame.new(
					serverInvisOriginalCF.Position.X,
					SKY_HEIGHT,
					serverInvisOriginalCF.Position.Z
				)

				-- Reposition held tool near camera
				local tool = character:FindFirstChildOfClass("Tool")
				if tool then
					local handle = tool:FindFirstChild("Handle")
					if handle then
						handle.CFrame = camCFrame * CFrame.new(0, -1, -2)
					end
				end
			end)

		else
			if serverInvisConnection then serverInvisConnection:Disconnect(); serverInvisConnection = nil end
			if serverInvisCameraConnection then serverInvisCameraConnection:Disconnect(); serverInvisCameraConnection = nil end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
			if serverInvisOriginalCF then
				root.CFrame = serverInvisOriginalCF
			end
		end
	end,
})

-- =====================
--   CHAT LOG TAB
-- =====================

local ChatTab = Window:CreateTab("Chat Log", 4483362458)
ChatTab:CreateSection("Chat Logger")

local function createChatLogGui()
	chatLogGui = Instance.new("ScreenGui")
	chatLogGui.Name = "ChatLogGui"
	chatLogGui.ResetOnSpawn = false
	chatLogGui.IgnoreGuiInset = true
	chatLogGui.DisplayOrder = 997
	chatLogGui.Parent = localPlayer.PlayerGui

	chatLogFrame = Instance.new("Frame")
	chatLogFrame.Size = UDim2.new(0, 400, 0, 250)
	chatLogFrame.Position = UDim2.new(1, -420, 0.5, -125)
	chatLogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	chatLogFrame.BackgroundTransparency = 0.2
	chatLogFrame.BorderSizePixel = 0
	chatLogFrame.Parent = chatLogGui
	Instance.new("UICorner", chatLogFrame).CornerRadius = UDim.new(0, 8)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = chatLogFrame
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Chat Log"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.Parent = titleBar

	chatLogScroll = Instance.new("ScrollingFrame")
	chatLogScroll.Size = UDim2.new(1, -10, 1, -40)
	chatLogScroll.Position = UDim2.new(0, 5, 0, 35)
	chatLogScroll.BackgroundTransparency = 1
	chatLogScroll.BorderSizePixel = 0
	chatLogScroll.ScrollBarThickness = 4
	chatLogScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	chatLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	chatLogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	chatLogScroll.Parent = chatLogFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = chatLogScroll

	local dragging = false
	local dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = input.Position; startPos = chatLogFrame.Position
		end
	end)
	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			chatLogFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	for _, msg in ipairs(chatMessages) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -5, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.BackgroundTransparency = 1
		label.Text = msg
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = chatLogScroll
	end
end

local function addChatMessage(playerName, message)
	local formatted = "[" .. playerName .. "]: " .. message
	table.insert(chatMessages, formatted)
	if #chatMessages > 100 then table.remove(chatMessages, 1) end
	if chatLogScroll then
		if #chatLogScroll:GetChildren() > 101 then
			local first = chatLogScroll:FindFirstChildWhichIsA("TextLabel")
			if first then first:Destroy() end
		end
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -5, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.BackgroundTransparency = 1
		label.Text = formatted
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = chatLogScroll
		task.defer(function()
			chatLogScroll.CanvasPosition = Vector2.new(0, chatLogScroll.AbsoluteCanvasSize.Y)
		end)
	end
end

local function hookPlayerChat(player)
	if playerChatConnections[player] then return end
	playerChatConnections[player] = player.Chatted:Connect(function(message)
		addChatMessage(player.Name, message)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do hookPlayerChat(player) end
Players.PlayerAdded:Connect(function(player) hookPlayerChat(player) end)
Players.PlayerRemoving:Connect(function(player)
	if playerChatConnections[player] then
		playerChatConnections[player]:Disconnect()
		playerChatConnections[player] = nil
	end
end)

ChatTab:CreateToggle({
	Name = "Show Chat Log",
	CurrentValue = false,
	Flag = "ChatLogToggle",
	Callback = function(value)
		chatLogEnabled = value
		if value then
			createChatLogGui()
		else
			if chatLogGui then chatLogGui:Destroy(); chatLogGui = nil; chatLogFrame = nil; chatLogScroll = nil end
		end
	end,
})

ChatTab:CreateButton({
	Name = "Clear Chat Log",
	Callback = function()
		chatMessages = {}
		if chatLogScroll then
			for _, child in ipairs(chatLogScroll:GetChildren()) do
				if child:IsA("TextLabel") then child:Destroy() end
			end
		end
		Rayfield:Notify({ Title = "Chat Log", Content = "Chat log cleared.", Duration = 2 })
	end,
})

-- =====================
--   TELEPORT TAB
-- =====================

local TeleportTab = Window:CreateTab("Teleport", 4483362458)
TeleportTab:CreateSection("Teleport to Player")

local function getPlayerNames()
	local names = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then table.insert(names, player.Name) end
	end
	if #names == 0 then table.insert(names, "No players found") end
	return names
end

local selectedTeleportPlayer = nil

local teleportDropdown = TeleportTab:CreateDropdown({
	Name = "Select Player",
	Options = getPlayerNames(),
	CurrentOption = {getPlayerNames()[1]},
	Flag = "TeleportPlayerDropdown",
	Callback = function(selected)
		selectedTeleportPlayer = selected[1]
	end,
})

selectedTeleportPlayer = getPlayerNames()[1]

local function getTeleportTarget()
	if not selectedTeleportPlayer or selectedTeleportPlayer == "No players found" then
		Rayfield:Notify({ Title = "Teleport Failed", Content = "No player selected.", Duration = 3 })
		return nil, nil
	end
	local target = Players:FindFirstChild(selectedTeleportPlayer)
	if not target then
		Rayfield:Notify({ Title = "Teleport Failed", Content = selectedTeleportPlayer .. " not found.", Duration = 3 })
		return nil, nil
	end
	local targetChar = target.Character
	local localChar = localPlayer.Character
	if not targetChar or not localChar then
		Rayfield:Notify({ Title = "Teleport Failed", Content = "Character not loaded.", Duration = 3 })
		return nil, nil
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not localRoot then
		Rayfield:Notify({ Title = "Teleport Failed", Content = "Could not find root parts.", Duration = 3 })
		return nil, nil
	end
	return targetRoot, localRoot
end

TeleportTab:CreateButton({
	Name = "Teleport To Player",
	Callback = function()
		local targetRoot, localRoot = getTeleportTarget()
		if not targetRoot then return end
		local dest = targetRoot.CFrame * CFrame.new(3, 0, 0)
		if serverInvisEnabled then
			serverInvisOriginalCF = dest
		else
			localRoot.CFrame = dest
		end
		Rayfield:Notify({ Title = "Teleported", Content = "Teleported to " .. selectedTeleportPlayer, Duration = 2 })
	end,
})

TeleportTab:CreateButton({
	Name = "Teleport Behind Player",
	Callback = function()
		local targetRoot, localRoot = getTeleportTarget()
		if not targetRoot then return end
		-- Go 4 studs directly behind them based on their look direction
		local dest = targetRoot.CFrame * CFrame.new(0, 0, 4)
		if serverInvisEnabled then
			serverInvisOriginalCF = dest
		else
			localRoot.CFrame = dest
		end
		Rayfield:Notify({ Title = "Teleported", Content = "Teleported behind " .. selectedTeleportPlayer, Duration = 2 })
	end,
})

TeleportTab:CreateButton({
	Name = "Refresh Player List",
	Callback = function()
		local names = getPlayerNames()
		teleportDropdown:Refresh(names, true)
		selectedTeleportPlayer = names[1]
		Rayfield:Notify({ Title = "Refreshed", Content = "Player list updated.", Duration = 2 })
	end,
})

Players.PlayerAdded:Connect(function()
	local names = getPlayerNames()
	teleportDropdown:Refresh(names, true)
	selectedTeleportPlayer = names[1]
end)

Players.PlayerRemoving:Connect(function()
	local names = getPlayerNames()
	teleportDropdown:Refresh(names, true)
	selectedTeleportPlayer = names[1]
end)

-- =====================
--   NAME TAG
-- =====================

local function createBillboard(character, name)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_NameTag"
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard
	return billboard
end

-- =====================
--   APPLY ESP
-- =====================

local function applyESP(player, character)
	if player == localPlayer then return end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	if highlights[player] then highlights[player]:Destroy() end
	if billboards[player] then billboards[player]:Destroy() end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.6
	highlight.Adornee = character
	highlight.Enabled = highlightsEnabled
	highlight.Parent = character
	highlights[player] = highlight
	character:WaitForChild("Head", 5)
	local billboard = createBillboard(character, player.Name)
	if billboard then
		billboard.Enabled = highlightsEnabled
		billboards[player] = billboard
	end
end

-- =====================
--   PLAYER SETUP
-- =====================

local function setupPlayer(player)
	if player == localPlayer then return end
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		applyESP(player, character)
	end)
	if player.Character then applyESP(player, player.Character) end
end

local function removePlayer(player)
	if highlights[player] then highlights[player]:Destroy() end
	if billboards[player] then billboards[player]:Destroy() end
	highlights[player] = nil
	billboards[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)

-- =====================
--   TEAMMATE CHECK
-- =====================

local function isTeammate(player)
	if not skipTeammates then return false end
	if localPlayer.Team == nil or player.Team == nil then return false end
	return localPlayer.Team == player.Team
end

-- =====================
--   AIM ASSIST LOGIC
-- =====================

local function getClosestTarget()
	local closestPlayer = nil
	local closestDistance = fovRadius
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	for _, player in ipairs(Players:GetPlayers()) do
		if player == localPlayer then continue end
		if isTeammate(player) then continue end
		local character = player.Character
		if not character then continue end
		local targetPart = character:FindFirstChild(aimAtPart)
		local humanoid = character:FindFirstChild("Humanoid")
		if not targetPart or not humanoid or humanoid.Health <= 0 then continue end
		local offsetPosition = targetPart.Position + Vector3.new(0, verticalOffset, 0)
		local screenPos, onScreen = camera:WorldToViewportPoint(offsetPosition)
		if not onScreen then continue end
		local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
		if dist < closestDistance then
			closestDistance = dist
			closestPlayer = player
		end
	end
	return closestPlayer
end

RunService:BindToRenderStep("AimAssist", Enum.RenderPriority.Camera.Value + 1, function()
	if showFOVCircle and fovCircleFrame then
		local size = fovRadius * 2
		fovCircleFrame.Size = UDim2.new(0, size, 0, size)
		fovCircleFrame.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
	end
	if not aimAssistEnabled then return end
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
	local target = getClosestTarget()
	if not target then return end
	local character = target.Character
	if not character then return end
	local targetPart = character:FindFirstChild(aimAtPart)
	if not targetPart then return end
	local alpha = math.clamp(aimStrength / 30, 0.001, 1)
	local aimPosition = targetPart.Position + Vector3.new(0, verticalOffset, 0)
	local currentCFrame = camera.CFrame
	local targetCFrame = CFrame.new(currentCFrame.Position, aimPosition)
	camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
end)

-- =====================
--   FORCE RESYNC
-- =====================

localPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	for _, h in pairs(highlights) do
		if h then h.Enabled = false; h.Enabled = highlightsEnabled end
	end
end)
