local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local KavoUI = Library.CreateLib("Eclipse Hub | Version 1.3", "BloodTheme")
local Window = KavoUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Get server and player info
local serverId = game.JobId
local placeId = game.PlaceId
local playerName = Players.LocalPlayer.Name

-- Your Discord webhook URL
local webhookUrl =
	"https://discord.com/api/webhooks/1393027837124018276/BjdquO7MPwJ8JWdWG1LTLYZRCNUoJuKLKM_i6muVpytLBathAgCbY0QWa_dk3Pj7bu-G"

-- Message content formatted for Discord
local data = {
	content = string.format(
		'**%s** is in a server!\n```lua\nlocal TeleportService = game:GetService("TeleportService")\nTeleportService:TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)\n```',
		playerName,
		placeId,
		serverId
	),
}

-- Encode the data as JSON
local jsonData = HttpService:JSONEncode(data)

-- Detect and use the supported HTTP request function from executor
local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)

-- Send the webhook
if requestFunc then
	local success, result = pcall(function()
		return requestFunc({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = jsonData,
		})
	end)

	if success then
		--nice
	else
		--nice
	end
else
	--nice
end

local function sendWebhook(action)
	local data = {
		content = action,
	}
	local httpRequest = httpRequest or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
	if httpRequest then
		httpRequest({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data),
		})
	else
		warn("No supported HTTP request found for webhook.")
	end
end

-- Send webhook on script execution
sendWebhook(
	"Eclipse Hub v1.3 executed by player: **"
		.. playerName
		.. " ("
		.. Players.LocalPlayer.UserId
		.. ")** at "
		.. os.date("%Y-%m-%d %H:%M:%S")
)

local player = Players.LocalPlayer

local CoreGui = game:GetService("CoreGui")
local userId = tostring(player.UserId)

-- Replace with your GitHub RAW blacklist URL
local blacklistUrl = "https://raw.githubusercontent.com/WinzeTim/timmyhack2/refs/heads/main/blacklistedids"

-- Webhook send function (if not already defined elsewhere)
local function sendWebhook(message)
	local data = {
		content = message,
	}
	local json = HttpService:JSONEncode(data)
	local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)

	if requestFunc then
		pcall(function()
			requestFunc({
				Url = webhookUrl,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = json,
			})
		end)
	end
end

-- Function to wipe UI, disconnect connections, and kick
local function nukeScript(reason)
	warn("[BLACKLISTED] UserId matched: " .. userId .. ". Reason: " .. reason)

	-- Destroy Timmy UI if present
	for _, gui in ipairs(CoreGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name:match("Timmy HUB") then
			gui:Destroy()
		end
	end

	player:Kick("You were blocked by Tim, please DM him for information.")
	sendWebhook("❌ Eclipse HUB user was kicked: **" .. player.Name .. "** at " .. os.date("%Y-%m-%d %H:%M:%S"))
end

-- Blacklist check
local function checkBlacklist()
	local success, result = pcall(function()
		return game:HttpGet(blacklistUrl)
	end)

	if success and typeof(result) == "string" then
		for line in string.gmatch(result, "[^\r\n]+") do
			if line == userId then
				nukeScript("User is blacklisted.")
				return
			end
		end
	else
		warn("[ERROR] Could not fetch blacklist:", result)
	end
end

-- Initial check
checkBlacklist()

-- Re-check every second
task.spawn(function()
	while true do
		checkBlacklist()
		task.wait(1)
	end
end)

local camera = workspace.CurrentCamera
local originalZoom = player.CameraMaxZoomDistance

local camlockEnabled = false
local silentAimEnabled = false
local hasShot = false
local jumpConnection = nil
local camlockCheckConnection = nil
local highlight = nil
local lastHighlightCheck = 0

-- Anti Lag for Camlock
local camlockAntiLag = false

-- Camlock Mode: "First Person" or "Third Person"
local camlockMode = "First Person"

-- Arc Mode: "High Arc" or "Low Arc"
local arcMode = "High Arc"

local deletedOOBs = {}
local oobDeleted = false

-- Create Tabs
local AimbotTab = Window:NewTab("Aimbot")
local AimbotSection = AimbotTab:NewSection("Main")

local MovementTab = Window:NewTab("Movement")
local MovementSection = MovementTab:NewSection("Speed Boost")

local ReachTab = Window:NewTab("Reach")
local ReachSection = ReachTab:NewSection("Magnet Reach")

local AutoTab = Window:NewTab("Automation")
local AutoSection = AutoTab:NewSection("Auto Guard")

local OOBTab = Window:NewTab("OOB")
local OOBSection = OOBTab:NewSection("OOB Folder Control")

local AntiTravelTab = Window:NewTab("Anti System")
local AntiTravelSection = AntiTravelTab:NewSection("Anti Travel")
local AntiFallSection = AntiTravelTab:NewSection("Anti Fall")

-- Create Auto Dime Tab
local AutoDimeTab = Window:NewTab("Auto Dime")
local AutoDimeSection = AutoDimeTab:NewSection("Main")

-- Create Self Pass Tab
local SelfPassTab = Window:NewTab("Self Pass")
local SelfPassSection = SelfPassTab:NewSection("Self Pass")
local PlatformSection = SelfPassTab:NewSection("Platform")

-- Create Social Tab
local SocialTab = Window:NewTab("Social")
local SocialSection = SocialTab:NewSection("Links")

local autoDimeKey = Enum.KeyCode.U -- Default keybind for diming

-- Self Pass Variables
local selfPassEnabled = false
local selfPassPlatform = "PC" -- "PC" or "Mobile"
local selfPassButton = nil
local selfPassKeybind = Enum.KeyCode.Two -- Default keybind for self pass
local originalCameraCFrame = nil
local originalCameraType = nil
local selfPassInputConnection = nil

-- Helper function to get basketball or z part (original logic)
local function getBallInstance(char)
    if not char then return nil end
    return char:FindFirstChild("Basketball") or char:FindFirstChild("z")
end

-- OOB Toggle: deletes/restores OOB folders in all courts on toggle
OOBSection:NewToggle(
	"Delete OOB",
	"Deletes all OOB folders in Courts when enabled; restores when disabled",
	function(state)
		if state then
			-- Delete OOB folders and store clones
			deletedOOBs = {}
			for _, court in pairs(workspace.Courts:GetChildren()) do
				local oob = court:FindFirstChild("OOB")
				if oob then
					deletedOOBs[court] = oob:Clone()
					oob:Destroy()
				end
			end
			oobDeleted = true
		else
			-- Restore OOB folders if deleted
			if oobDeleted then
				for court, oobClone in pairs(deletedOOBs) do
					if court and court.Parent then
						oobClone.Parent = court
					end
				end
				deletedOOBs = {}
				oobDeleted = false
			end
		end
	end
)

-- Camlock toggle and functions

AimbotSection:NewToggle("Camlock", "Lock camera to hoop while jumping", function(state)
	camlockEnabled = state
	if state then
		setupJumpListener()
		camlockChecker()
	else
		disableCamlock()
		stopCamlockChecker()
	end
end)

AimbotSection:NewDropdown("Aimlock Mode", "Switch between first and third person camlock modes", {"First Person", "Third Person"}, function(mode)
	camlockMode = mode
end, "First Person")

AimbotSection:NewDropdown("Arc Mode", "Choose between high arc (default) or low arc (faster)", {"High Arc", "Low Arc"}, function(mode)
    arcMode = mode
end, "High Arc")

AimbotSection:NewToggle("Anti Lag (Disables Highlight Indicator)", "Disables the highlight indicator for Camlock to reduce lag", function(state)
	camlockAntiLag = state
	if state then
		disableHighlight()
	end
end)

-- Magnet Reach toggles/sliders

local magnetEnabled = false
local magnetSize = 0
local originalHeadSize = nil

local function updateHeadSize()
	local char = player.Character or player.CharacterAdded:Wait()
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	if not magnetEnabled then
		if originalHeadSize then
			head.Size = originalHeadSize
			head.Transparency = 0
			head.Material = Enum.Material.Plastic
			head.CanCollide = true
			originalHeadSize = nil
		end
	else
		if not originalHeadSize then
			originalHeadSize = head.Size
		end
		local safeSize = math.clamp(magnetSize, 2, 50)
		head.Size = Vector3.new(safeSize, safeSize, safeSize)
		head.Transparency = 0.5
		head.Material = Enum.Material.ForceField
		head.CanCollide = false
		head.Massless = true
		head.CanTouch = true
	end
end

ReachSection:NewToggle("Enable Magnet (DELETE OOB)", "Toggle head reach expansion", function(state)
	magnetEnabled = state
	updateHeadSize()
end)

ReachSection:NewSlider("Magnet Size", "Adjust head size for reach", 50, 2, function(size)
	magnetSize = math.clamp(size, 2, 50)
	if magnetEnabled then
		updateHeadSize()
	end
end)

-- Add preset buttons for magnet sizes
ReachSection:NewButton("Legit Magnet (DELETE OOB)", "Set magnet size to 7 (legitimate reach)", function()
	magnetSize = 7
	-- Update the slider value if possible (this would require accessing the slider directly)
	-- For now, we'll just set the magnet size and update
	if magnetEnabled then
		updateHeadSize()
	end
	print("[Reach] Set to Legit Magnet (Size: 7)")
end)

ReachSection:NewButton("Blatant (DELETE OOB)", "Set magnet size to 50 (blatant reach)", function()
	magnetSize = 50
	-- Update the slider value if possible
	if magnetEnabled then
		updateHeadSize()
	end
	print("[Reach] Set to Blatant Magnet (Size: 50) - Remember to turn off OOB!")
end)

-- Auto Guard
local function findAutoGuardTarget()
	local courtsFolder = workspace:FindFirstChild("Courts")
	if not courtsFolder then
		return nil
	end

	local playerCourt = nil
	for _, court in pairs(courtsFolder:GetChildren()) do
		if court:IsA("Model") and court.Name:sub(1, 5) == "Court" then
			local identities = court:FindFirstChild("_CourtIdentities")
			if identities and identities:FindFirstChild(player.Name) then
				playerCourt = court
				break
			end
		end
	end

	if not playerCourt then
		return nil
	end

	local courtPlayers = playerCourt:FindFirstChild("_CourtPlayers")
	if not courtPlayers then
		return nil
	end

	for _, objValue in pairs(courtPlayers:GetChildren()) do
		if objValue:IsA("ObjectValue") and objValue.Value and objValue.Value ~= player then
			return objValue.Value
		end
	end

	return nil
end

-- Checks if the target has the ball (Basketball or z)
local function targetHasBasketball(targetPlayer)
	local char = targetPlayer and targetPlayer.Character
	return getBallInstance(char) ~= nil
end

local autoGuardEnabled = false
local autoGuardLoopRunning = false
local autoGuardConnection = nil -- Connection for character respawn

-- Function to start auto guard loop
local function startAutoGuardLoop()
	if autoGuardLoopRunning then return end
	
	autoGuardLoopRunning = true
	task.spawn(function()
		local currentEnemy = nil
		local humanoid = nil
		local rootPart = nil

		while autoGuardEnabled do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			humanoid = char and char:FindFirstChild("Humanoid")

			if not char or not hrp or not humanoid then
				task.wait(0.1) -- Faster check
				continue
			end

			rootPart = hrp

			-- Check if you have the ball - if so, stop auto guard temporarily
			if getBallInstance(char) then
				print("[Auto Guard] You have the basketball! Pausing auto guard...")
				-- Stop moving but keep the loop running
				-- No need to stop CFrame movement, it will naturally stop when not called
				currentEnemy = nil
				task.wait(0.5) -- Check every 0.5 seconds
				continue
			end

			-- Find enemy on your court
			local enemy = findAutoGuardTarget()

			-- Check if enemy has basketball or z
			if enemy and targetHasBasketball(enemy) then
				-- Enemy has ball: update currentEnemy
				if enemy ~= currentEnemy then
					currentEnemy = enemy
				end
			else
				-- Enemy doesn't have ball or no enemy found
				if currentEnemy ~= nil then
					currentEnemy = nil
				end
			end

			if currentEnemy then
				local enemyChar = currentEnemy.Character
				local enemyHRP = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
				local enemyHumanoid = enemyChar and enemyChar:FindFirstChild("Humanoid")
				
				if enemyHRP and enemyHumanoid then
					-- Calculate positions and distances
					local myPos = rootPart.Position
					local enemyPos = enemyHRP.Position
					local distance = (myPos - enemyPos).Magnitude
					
					-- Get enemy's movement direction and velocity
					local enemyMoveDirection = enemyHumanoid.MoveDirection
					local enemyVelocity = enemyHRP.Velocity
					local enemySpeed = enemyVelocity.Magnitude
					
					-- Get enemy's facing direction (where they're looking/moving)
					local enemyFacingDirection = Vector3.new(0, 0, 0)
					if enemyMoveDirection.Magnitude > 0.1 then
						enemyFacingDirection = enemyMoveDirection.Unit
					elseif enemySpeed > 2 then
						enemyFacingDirection = enemyVelocity.Unit
					else
						-- If enemy not moving, use direction from enemy to me
						enemyFacingDirection = (myPos - enemyPos).Unit
					end
					
					-- Calculate target position 3 studs in front of enemy (from enemy's perspective)
					local targetPosition = enemyPos + enemyFacingDirection * 3
					local distanceToTarget = (myPos - targetPosition).Magnitude
					
					-- Check if we're too close to enemy and need to wrap around
					local distanceToEnemy = (myPos - enemyPos).Magnitude
					if distanceToEnemy < 3 then
						-- We're too close, need to wrap around to the front
						-- Calculate a point to the side of the enemy to wrap around
						local enemyRight = Vector3.new(-enemyFacingDirection.Z, 0, enemyFacingDirection.X) -- Perpendicular to facing direction
						local wrapAroundPoint = enemyPos + enemyRight * 2 -- 2 studs to the side
						
						-- Check if we need to go left or right to get to front faster
						local leftPoint = enemyPos + (enemyRight * -1) * 2
						local rightPoint = enemyPos + enemyRight * 2
						
						local distanceToLeft = (myPos - leftPoint).Magnitude
						local distanceToRight = (myPos - rightPoint).Magnitude
						
						-- Choose the closer side to wrap around
						if distanceToLeft < distanceToRight then
							targetPosition = leftPoint
						else
							targetPosition = rightPoint
						end
						
						distanceToTarget = (myPos - targetPosition).Magnitude
					end
					
					-- Only print debug info occasionally to reduce lag
					if tick() % 1 < 0.016 then -- Print roughly every second
						print("[Auto Guard] Distance to target:", math.floor(distanceToTarget))
					end
					
					-- Face the enemy
					rootPart.CFrame = CFrame.new(rootPart.Position, Vector3.new(enemyPos.X, rootPart.Position.Y, enemyPos.Z))
					
					-- Use CFrame movement to move towards target position with consistent speed
					local moveDirection = (targetPosition - myPos).Unit
					local speedMultiplier = 0.35 -- Consistent speed for any distance
					rootPart.CFrame = rootPart.CFrame + moveDirection * speedMultiplier
					
					-- Only print every 30 frames to reduce lag
					if tick() % 0.5 < 0.016 then -- Print roughly every 0.5 seconds
						print("[Auto Guard] Moving to front of enemy, distance:", math.floor(distanceToTarget))
					end
					
				else
					print("[Auto Guard] Enemy missing HumanoidRootPart or Humanoid.")
				end
			else
				-- No enemy to follow, stop moving
				-- No need to stop CFrame movement, it will naturally stop when not called
				task.wait(0.1)
			end

			task.wait(0.016) -- ~60 FPS for smooth movement
		end

		-- Stop moving when loop ends
		-- No need to stop CFrame movement, it will naturally stop when not called
		print("[Auto Guard] Loop ended.")
		autoGuardLoopRunning = false
	end)
end

-- Function to stop auto guard
local function stopAutoGuard()
	autoGuardEnabled = false
	autoGuardLoopRunning = false
	-- Stop moving when disabled
	-- No need to stop CFrame movement, it will naturally stop when not called
end

-- Set up character respawn listener
local function setupAutoGuardRespawn()
	if autoGuardConnection then
		autoGuardConnection:Disconnect()
	end
	
	autoGuardConnection = player.CharacterAdded:Connect(function()
		print("[Auto Guard] Character respawned, restarting auto guard...")
		task.wait(1) -- Wait for character to fully load
		if autoGuardEnabled then
			startAutoGuardLoop()
		end
	end)
end

-- Initialize the respawn listener
setupAutoGuardRespawn()

AutoSection:NewToggle("Auto Guard", "Automatically follows target player", function(state)
	autoGuardEnabled = state
	print("[Auto Guard] Toggled:", state)

	if autoGuardEnabled then
		startAutoGuardLoop()
	else
		stopAutoGuard()
	end
end)

-- Movement speed toggle

local speedEnabled = false

MovementSection:NewToggle("Speed Boost", "Mini forward boost while walking", function(state)
	speedEnabled = state
end)

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	if speedEnabled and hum.MoveDirection.Magnitude > 0 then
		hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 0.015
	end
end)

-- Camlock Support Functions

local function arcOffset(d)
	return d <= 12 and 134
		or d <= 16 and 130
		or d <= 30 and 116
		or d <= 31 and 115
		or d <= 32 and 114
		or d <= 33 and 113
		or d <= 34 and 112
		or d <= 35 and 111
		or d <= 36 and 110
		or d <= 37 and 109
		or d <= 38 and 108
		or d <= 39 and 107
		or d <= 40 and 106
		or d <= 41 and 105
		or d <= 42 and 104
		or d <= 43 and 103
		or d <= 44 and 102
		or d <= 45 and 101
		or d <= 46 and 100
		or d <= 47 and 99
		or d <= 48 and 98
		or d <= 49 and 97
		or d <= 50 and 96
		or d <= 51 and 95
		or d <= 52 and 94
		or d <= 53 and 93
		or d <= 54 and 92
		or d <= 55 and 91
		or d <= 56 and 90
		or d <= 57 and 89
		or d <= 58 and 88
		or d <= 59 and 87
		or d <= 60 and 86
		or d <= 61 and 85
		or d <= 62 and 84
		or d <= 63 and 83
		or d <= 64 and 82
		or d <= 65 and 78
		or d <= 66 and 74
		or d <= 67 and 70
		or d <= 68 and 66
		or d <= 69 and 62
		or d <= 70 and 58
		or d <= 71 and 52
		or d <= 72 and 48
		or d <= 73 and 46
		or d <= 74 and 34
		or 15
end

function lowArcPowerOffset(d)
    -- You can tune these values for each distance
    return d <= 12 and 30
        or d <= 16 and 35
        or d <= 21 and 40
        or d <= 26 and 45
        or d <= 31 and 50
        or d <= 36 and 55
        or d <= 41 and 60
        or d <= 46 and 65
        or d <= 50 and 70
        or d <= 56 and 75
        or d <= 58 and 75
        or d <= 59 and 75
        or d <= 60 and 75
        or d <= 61 and 80
        or d <= 62 and 80
        or d <= 63 and 80
        or d <= 64 and 80
        or d <= 65 and 80
        or d <= 66 and 80
        or d <= 67 and 80
        or d <= 68 and 85
        or d <= 69 and 85
        or d <= 70 and 85
        or d <= 71 and 85
        or d <= 72 and 85
        or d <= 73 and 85
        or d <= 74 and 85
        or 75
end

function lowArcAimOffset(d)
    -- You can tune these values for each distance (smaller than high arc)
    return d <= 12 and 20
        or d <= 16 and 22
        or d <= 21 and 24
        or d <= 26 and 26
        or d <= 31 and 28
        or d <= 36 and 30
        or d <= 41 and 32
        or d <= 46 and 34
        or d <= 50 and 36

		-- 75 Power
        or d <= 56 and 46
        or d <= 58 and 42
        or d <= 59 and 38
        or d <= 60 and 34

		-- 80 Power
        or d <= 61 and 64
        or d <= 62 and 60
        or d <= 63 and 56
        or d <= 64 and 52
        or d <= 65 and 48
		or d <= 66 and 44
		or d <= 67 and 40

		-- 85 Power
		or d <= 68 and 66
		or d <= 69 and 62
		or d <= 70 and 58
		or d <= 71 and 54
		or d <= 72 and 50
		or d <= 73 and 46
		or d <= 74 and 42
        or 40
end

function getNearestRim()
    local torso = player.Character and player.Character:FindFirstChild("Torso")
    if not torso then
        return nil, nil
    end
    local rims = {}

    -- Search in workspace.Courts and workspace.PracticeArea (original logic)
    for _, parent in pairs({ workspace.Courts, workspace.PracticeArea }) do
        if parent then
            for _, d in pairs(parent:GetDescendants()) do
                if d:IsA("MeshPart") and (d.Name == "Rim" or d.Name == "hoop") then
                    table.insert(rims, d)
                end
            end
        end
    end

    -- Search in workspace.Court.HitboxesAway and HitboxesHome for HoopModel > hoop
    local function addHoopsFromHitboxes(hitboxFolder)
        if hitboxFolder then
            for _, desc in ipairs(hitboxFolder:GetDescendants()) do
                if desc.Name == "HoopModel" and desc:IsA("Model") then
                    local hoop = desc:FindFirstChild("hoop")
                    if hoop and hoop:IsA("MeshPart") then
                        table.insert(rims, hoop)
                    end
                end
            end
        end
    end

    if workspace:FindFirstChild("Court") then
        addHoopsFromHitboxes(workspace.Court:FindFirstChild("HitboxesAway"))
        addHoopsFromHitboxes(workspace.Court:FindFirstChild("HitboxesHome"))
    end

    -- Find the closest rim
    local closest, minDist = nil, math.huge
    for _, rim in pairs(rims) do
        local dist = (torso.Position - rim.Position).Magnitude
        if dist < minDist then
            minDist, closest = dist, rim
        end
    end
    return math.floor(minDist), closest
end

function aimAtRim(dist, rim, mode)
    local char = player.Character
    if not char then
        return
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head or not rim then
        return
    end
    local arcY
    local targetPos
    if arcMode == "High Arc" then
        arcY = arcOffset(dist)
        targetPos = rim.Position + Vector3.new(0, arcY, 0)
    else -- Low Arc
        local power = lowArcPowerOffset(dist)
        player:SetAttribute("Power", power)
        local arcY = lowArcAimOffset(dist)
        targetPos = rim.Position + Vector3.new(0, arcY, 0)
    end
    -- Mobile-specific aiming: use vector logic from mobile script if on mobile
    if UserInputService.TouchEnabled then
        -- Use a vector above the rim/goal based on distance, similar to the mobile script
        local vector = Vector3.new(0, 8, 0)
        if dist >= 58 and dist <= 61 then
            vector = Vector3.new(0, 9, 0)
        elseif dist == 62 then
            vector = Vector3.new(0, 8, 0)
        elseif dist == 63 then
            vector = Vector3.new(0, 14, 0)
        elseif dist >= 67 and dist <= 72.4 then
            vector = Vector3.new(0, 19, 0)
        end
        targetPos = rim.Position + vector
    end
    local flatDir = Vector3.new((rim.Position - root.Position).X, 0, (rim.Position - root.Position).Z).Unit
    if mode == "First Person" then
        root.CFrame = CFrame.new(root.Position, root.Position + flatDir)
    end
    return CFrame.new(head.Position, targetPos), targetPos
end

function shootAtWorldPos(pos)
    local char = player.Character
    if char then
        local zPart = char:FindFirstChild("z")
        if zPart then
            zPart.Name = "Basketball"
        end
    end

    -- Mobile compatibility: use TouchEvent if on mobile
    local screen, onScreen = camera:WorldToViewportPoint(pos)
    if not onScreen then
        return
    end
    if UserInputService.TouchEnabled then
        -- Simulate a tap at the target position for mobile
        VirtualInputManager:SendTouchEvent(true, screen.X, screen.Y, 0)
        task.wait(0.05)
        VirtualInputManager:SendTouchEvent(false, screen.X, screen.Y, 0)
    else
        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, false, game, 0)
    end
end

function setupJumpListener()
	if jumpConnection then
		jumpConnection:Disconnect()
	end
	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	jumpConnection = humanoid.Jumping:Connect(function()
		if hasShot or not getBallInstance(player.Character) then
			return
		end
		hasShot = true
		task.delay(0.2, function()
			local dist, rim = getNearestRim()
			if not rim or dist > 74 then
				hasShot = false
				return
			end
			if arcMode == "High Arc" then
				player:SetAttribute("Power", 85)
			end
			local camCFrame, target = aimAtRim(dist, rim, camlockMode)
			if camlockMode == "First Person" then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = camCFrame
				player.CameraMaxZoomDistance = 0
				task.wait(0.1)
				shootAtWorldPos(target)
				camera.CameraType = Enum.CameraType.Custom
				player.CameraMaxZoomDistance = originalZoom
			else -- Third Person
				local prevCFrame = camera.CFrame
				camera.CFrame = camCFrame
				task.wait(0.1)
				shootAtWorldPos(target)
				camera.CFrame = prevCFrame
			end
			task.delay(0.2, function()
				hasShot = false
			end)
		end)
	end)
end

function disableCamlock()
	if jumpConnection then
		jumpConnection:Disconnect()
		jumpConnection = nil
	end
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMaxZoomDistance = originalZoom
end

function enableHighlight()
	if camlockAntiLag then return end
	local char = player.Character
	if not char then
		return
	end
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "CamlockHighlight"
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
		highlight.OutlineTransparency = 0.3
		highlight.Adornee = char
		highlight.Parent = char
	else
		highlight.Enabled = true
	end
end

function disableHighlight()
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
end

function camlockChecker()
	if camlockCheckConnection then
		camlockCheckConnection:Disconnect()
	end
	camlockCheckConnection = RunService.Heartbeat:Connect(function(dt)
		if tick() - lastHighlightCheck < 0.2 then
			return
		end
		lastHighlightCheck = tick()
		if not camlockEnabled then
			return
		end
		local char = player.Character
		if not char or not getBallInstance(char) then
			return disableHighlight()
		end
		local dist, rim = getNearestRim()
		if not rim or dist > 74 then
			return disableHighlight()
		end
		enableHighlight()
	end)
end

function stopCamlockChecker()
	if camlockCheckConnection then
		camlockCheckConnection:Disconnect()
		camlockCheckConnection = nil
	end
	disableHighlight()
end

-- ANTI TRAVEL TOGGLE VARIABLES
local antiTravelEnabled = false
local inAir = false
local landedSince = 0
local renameBackTask = nil
local antiTravelConnection = nil

-- ANTI FALL VARIABLES
local antiFallEnabled = false
local antiFallConnection = nil
local currentAntiFallBoxes = {} -- {player = box}
local lastClosestPlayers = {} -- Track the 3 closest players

local function renameToZ()
	local char = player.Character
	if char then
		local b = char:FindFirstChild("Basketball")
		if b then
			b.Name = "z"
		end
	end
end

local function renameToBasketball()
	local char = player.Character
	if char then
		local z = char:FindFirstChild("z")
		if z then
			z.Name = "Basketball"
		end
	end
end

local function cancelRenameBackTask()
	if renameBackTask then
		task.cancel(renameBackTask)
		renameBackTask = nil
	end
end

local function delayedRenameBack()
	cancelRenameBackTask()
	renameBackTask = task.spawn(function()
		task.wait(0.3)
		if not inAir and antiTravelEnabled and tick() - landedSince >= 0.3 then
			renameToBasketball()
		end
		renameBackTask = nil
	end)
end

local function monitorAntiTravelStates()
	-- Disconnect any existing connection first
	if antiTravelConnection then
		antiTravelConnection:Disconnect()
		antiTravelConnection = nil
	end
	
	local char = player.Character
	if not char then return end
	
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	antiTravelConnection = humanoid.StateChanged:Connect(function(_, new)
		if not antiTravelEnabled then
			return
		end

		if new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
			inAir = true
			renameToZ()
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			inAir = false
			landedSince = tick()
			delayedRenameBack()
		end
	end)
end

-- Anti Fall Functions
local function createAntiFallBox(player)
	if not player or not player.Character then return nil end
	local head = player.Character:FindFirstChild("Head")
	if not head then return nil end
	
	-- Create invisible box part
	local box = Instance.new("Part")
	box.Name = "AntiFallBox"
	box.Size = Vector3.new(3, 3, 3) -- Slightly larger than head
	box.Transparency = 1 -- Invisible
	box.CanCollide = true
	box.Anchored = true
	box.Material = Enum.Material.SmoothPlastic
	box.Parent = workspace
	
	-- Position box at head
	box.CFrame = head.CFrame
	
	return box
end

local function removeAntiFallBox(player)
	if currentAntiFallBoxes[player] then
		currentAntiFallBoxes[player]:Destroy()
		currentAntiFallBoxes[player] = nil
	end
end

local function updateAntiFallBoxes()
	if not antiFallEnabled then return end
	
	local myChar = player.Character
	if not myChar then return end
	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end
	
	-- Get all players except self
	local allPlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				table.insert(allPlayers, {player = plr, distance = (myHRP.Position - hrp.Position).Magnitude})
			end
		end
	end
	
	-- Sort by distance and get 3 closest
	table.sort(allPlayers, function(a, b) return a.distance < b.distance end)
	local closestPlayers = {}
	for i = 1, math.min(3, #allPlayers) do
		table.insert(closestPlayers, allPlayers[i].player)
	end
	
	-- Remove boxes for players no longer in top 3
	for player, box in pairs(currentAntiFallBoxes) do
		local stillClosest = false
		for _, closestPlayer in ipairs(closestPlayers) do
			if player == closestPlayer then
				stillClosest = true
				break
			end
		end
		if not stillClosest then
			removeAntiFallBox(player)
		end
	end
	
	-- Add boxes for new closest players
	for _, closestPlayer in ipairs(closestPlayers) do
		if not currentAntiFallBoxes[closestPlayer] then
			currentAntiFallBoxes[closestPlayer] = createAntiFallBox(closestPlayer)
		end
	end
	
	-- Update positions of existing boxes
	for player, box in pairs(currentAntiFallBoxes) do
		if player.Character then
			local head = player.Character:FindFirstChild("Head")
			if head then
				box.CFrame = head.CFrame
			end
		end
	end
end

local function startAntiFall()
	if antiFallConnection then antiFallConnection:Disconnect() end
	antiFallConnection = RunService.Heartbeat:Connect(function()
		if antiFallEnabled then
			updateAntiFallBoxes()
		end
	end)
end

local function stopAntiFall()
	if antiFallConnection then
		antiFallConnection:Disconnect()
		antiFallConnection = nil
	end
	
	-- Remove all boxes
	for player, box in pairs(currentAntiFallBoxes) do
		removeAntiFallBox(player)
	end
	currentAntiFallBoxes = {}
end

AntiTravelSection:NewToggle("Anti Travel", "The name says it all, jump all you want no travel call", function(state)
	antiTravelEnabled = state
	if state then
		monitorAntiTravelStates() -- Call on each toggle ON to reset connection
	else
		-- Disconnect the connection when disabled
		if antiTravelConnection then
			antiTravelConnection:Disconnect()
			antiTravelConnection = nil
		end
		renameToBasketball()
	end
end)

AntiFallSection:NewToggle("Anti Fall", "No more ankles broken its in the name im getting tired of this", function(state)
	antiFallEnabled = state
	if state then
		startAntiFall()
		print("[Anti Fall] Enabled - Creating invisible boxes on 3 closest enemies")
	else
		stopAntiFall()
		print("[Anti Fall] Disabled - Removed all anti-fall boxes")
	end
end)

-- Self Pass Toggles
local function updateSelfPassUI()
    -- Remove old
    removeSelfPassButton()
    if selfPassInputConnection then
        selfPassInputConnection:Disconnect()
        selfPassInputConnection = nil
    end

    if selfPassEnabled then
        createSelfPassButton()
        if selfPassPlatform == "PC" then
            setupSelfPassInput()
        end
    end
end

SelfPassSection:NewToggle("Self Pass", "Enable self pass functionality", function(state)
    selfPassEnabled = state
    updateSelfPassUI()
end)

PlatformSection:NewToggle("PC Mode", "Use keybind (2) for self pass", function(state)
    if state then
        selfPassPlatform = "PC"
        if mobileModeToggle then mobileModeToggle:UpdateToggle(false) end
    end
    updateSelfPassUI()
end)

PlatformSection:NewToggle("Mobile Mode", "Use on-screen button for self pass", function(state)
    if state then
        selfPassPlatform = "Mobile"
        if pcModeToggle then pcModeToggle:UpdateToggle(false) end
    end
    updateSelfPassUI()
end)

-- Prevent renaming during actual shot input
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and hasShot then
		return -- Do not rename ball while shooting to avoid conflicts
	end
end)

-- Create Toggle GUI
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "ToggleKavoUI"
toggleGui.ResetOnSpawn = false
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleGui.Parent = CoreGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "KavoToggleButton"
toggleButton.Size = UDim2.new(0, 90, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0.5, -17)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "☰ Menu"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextScaled = true
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.AutoButtonColor = true
toggleButton.Active = true
toggleButton.Draggable = true
toggleButton.Parent = toggleGui

toggleButton.MouseButton1Click:Connect(function()
    Library:ToggleUI()
end)

local autoDribbleEnabled = false
local autoDribbleConnection = nil
local lastEnemySide = nil
local lastSwitchTime = 0
local switchCooldown = 1.0 -- 1 second cooldown between switches
local lastBallSide = nil
local consecutiveSwitches = 0

AutoSection:NewToggle("Auto Dribble (ONLY FOR 1v1's)", "Automatically switches dribble hand away from enemy in 1v1s", function(state)
    autoDribbleEnabled = state
    if autoDribbleEnabled then
        if autoDribbleConnection then autoDribbleConnection:Disconnect() end
        autoDribbleConnection = RunService.Heartbeat:Connect(function()
            if not autoDribbleEnabled then return end
            if antiTravelEnabled and inAir then return end
            local char = player.Character
            if not char then return end
            local ball = getBallInstance(char)
            -- If ball is a folder, look for a part named 'Ball' inside
            if ball and not ball:IsA("BasePart") and ball:IsA("Folder") then
                local innerBall = ball:FindFirstChild("Ball")
                if innerBall and innerBall:IsA("BasePart") then
                    ball = innerBall
                else
                    return
                end
            end
            if not ball or not ball:IsA("BasePart") then return end
            local enemy = findAutoGuardTarget()
            if not enemy or not enemy.Character then return end
            local enemyHRP = enemy.Character:FindFirstChild("HumanoidRootPart")
            local lArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand")
            local rArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
            if not enemyHRP or not lArm or not rArm then return end
            -- Determine which hand is holding the ball (simplified detection)
            local ballSide = nil
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            -- Simple detection: which side of the character is the ball on
            local ballRelativePos = ball.Position - hrp.Position
            local rightVector = hrp.CFrame.RightVector
            local dotProduct = ballRelativePos:Dot(rightVector)
            
            if dotProduct > 0 then
                ballSide = "Right"
            else
                ballSide = "Left"
            end
            
            -- Determine which side the enemy is on
            local enemyRelativePos = enemyHRP.Position - hrp.Position
            local enemyDotProduct = enemyRelativePos:Dot(rightVector)
            local enemySide = enemyDotProduct > 0 and "Right" or "Left"
            
            -- Only proceed if we have a valid ball side and enemy is close enough
            local distanceToEnemy = (enemyHRP.Position - hrp.Position).Magnitude
            if distanceToEnemy > 12 then return end -- Don't switch if enemy is too far
            
            -- Check if we need to switch (only if ball and enemy are on same side)
            local currentTime = tick()
            local shouldSwitch = false
            
            if ballSide == enemySide then
                shouldSwitch = true
            end
            
            -- Only switch if:
            -- 1. We need to switch
            -- 2. Cooldown has passed
            -- 3. Ball side has been stable for a bit
            -- 4. We haven't switched too many times recently
            if shouldSwitch and currentTime - lastSwitchTime > switchCooldown then
                -- Additional check: make sure we're not switching too rapidly
                if consecutiveSwitches < 3 then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.H, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.H, false, game)
                    lastSwitchTime = currentTime
                    consecutiveSwitches = consecutiveSwitches + 1
                    print("[Auto Dribble] Switched - Enemy:", enemySide, "Ball:", ballSide)
                end
            else
                -- Reset consecutive switches if we haven't switched recently
                if currentTime - lastSwitchTime > 2.0 then
                    consecutiveSwitches = 0
                end
            end
        end)
    else
        if autoDribbleConnection then autoDribbleConnection:Disconnect() end
        autoDribbleConnection = nil
    end
end)

-- Helper to find nearest teammate (excluding self)
local function getNearestTeammate()
    local myChar = player.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == player.Team and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- Helper to find current court and teammate for local player
local function getCourtAndTeammate()
    local courtsFolder = workspace:FindFirstChild("Courts")
    if not courtsFolder then return nil, nil end
    for _, court in ipairs(courtsFolder:GetChildren()) do
        if court:IsA("Model") then
            local courtPlayers = court:FindFirstChild("_CourtPlayers")
            if courtPlayers then
                for _, obj in ipairs(courtPlayers:GetChildren()) do
                    if obj:IsA("ObjectValue") and obj.Value == player then
                        -- Found my slot (Away1, Away2, Home1, Home2)
                        local mySlot = obj.Name
                        local teammateSlot = nil
                        if mySlot == "Away1" then teammateSlot = "Away2"
                        elseif mySlot == "Away2" then teammateSlot = "Away1"
                        elseif mySlot == "Home1" then teammateSlot = "Home2"
                        elseif mySlot == "Home2" then teammateSlot = "Home1" end
                        if teammateSlot and courtPlayers:FindFirstChild(teammateSlot) then
                            local teammateObj = courtPlayers:FindFirstChild(teammateSlot)
                            return court, teammateObj.Value
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

-- Predict teammate's position based on velocity
local function getPredictedTeammatePosition(teammate)
    if not teammate or not teammate.Character then return nil end
    local hrp = teammate.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local velocity = hrp.Velocity or Vector3.new()
    -- Predict 0.4 seconds ahead (tweak as needed)
    local predictionTime = 0.4
    return hrp.Position + velocity * predictionTime
end

-- Simulate pass (dime) to teammate's predicted position
local function dimeToTeammate(teammate)
    if not teammate or not teammate.Character then return end
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local predictedPos = getPredictedTeammatePosition(teammate)
    if not predictedPos then return end
    player:SetAttribute("Power", 85)
    myHRP.CFrame = CFrame.new(myHRP.Position, Vector3.new(predictedPos.X, myHRP.Position.Y, predictedPos.Z))
    local screen, onScreen = camera:WorldToViewportPoint(predictedPos)
    if onScreen then
        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, false, game, 0)
    end
end

-- Auto Dime Toggle
AutoDimeSection:NewToggle("Auto Dime", "Automatically pass to teammate with prediction", function(state)
    autoDimeEnabled = state
    if autoDimeEnabled then
        if autoDimeConnection then autoDimeConnection:Disconnect() end
        autoDimeConnection = nil -- Do not use RenderStepped for auto dime
    else
        if autoDimeConnection then autoDimeConnection:Disconnect() end
        autoDimeConnection = nil
    end
end)

-- Add keybind picker to Auto Dime tab
AutoDimeSection:NewKeybind("Dime Key (Key is U)", "KEY IS U", autoDimeKey, function(newKey)
    autoDimeKey = newKey
end)

-- Helper to temporarily disable/restore highlight
local function withHighlightDisabled(callback)
    local wasEnabled = highlight and highlight.Enabled
    if highlight then highlight.Enabled = false end
    callback()
    if highlight and wasEnabled then highlight.Enabled = true end
end

-- Only set up the auto dime InputBegan listener ONCE at script load
if autoDimeInputConn then autoDimeInputConn:Disconnect() end
local autoDimeInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not autoDimeEnabled then return end
    if gameProcessed then return end
    if input.KeyCode == autoDimeKey then
        local char = player.Character
        if not char then return end
        local ball = getBallInstance(char)
        if not ball then return end
        local court, teammate = getCourtAndTeammate()
        if not teammate then return end
        withHighlightDisabled(function()
            dimeToTeammate(teammate)
        end)
    end
end)

-- Reconnect on character respawn
player.CharacterAdded:Connect(function()
    setupAutoDimeInputListener()
end)

-- Teammate Distance Counter GUI and updater
local function setupTeammateDistanceCounter()
    local teammateDistanceGui = CoreGui:FindFirstChild("TeammateDistanceGui")
    if not teammateDistanceGui then
        teammateDistanceGui = Instance.new("ScreenGui")
        teammateDistanceGui.Name = "TeammateDistanceGui"
        teammateDistanceGui.ResetOnSpawn = false
        teammateDistanceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        teammateDistanceGui.Parent = CoreGui
    end
    local teammateDistanceLabel = teammateDistanceGui:FindFirstChild("TeammateDistanceLabel")
    if not teammateDistanceLabel then
        teammateDistanceLabel = Instance.new("TextLabel")
        teammateDistanceLabel.Name = "TeammateDistanceLabel"
        teammateDistanceLabel.Size = UDim2.new(0.3, 0, 0, 40)
        teammateDistanceLabel.Position = UDim2.new(0.35, 0, 0, 0)
        teammateDistanceLabel.BackgroundTransparency = 1
        teammateDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        teammateDistanceLabel.TextStrokeTransparency = 0.5
        teammateDistanceLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        teammateDistanceLabel.Text = ""
        teammateDistanceLabel.Font = Enum.Font.GothamBold
        teammateDistanceLabel.TextScaled = true
        teammateDistanceLabel.Visible = false
        teammateDistanceLabel.Parent = teammateDistanceGui
    end
    -- Toggle for teammate distance in Auto Dime tab
    if not _G._teammateDistanceToggleSetup then
        _G._teammateDistanceToggleSetup = true
        local showTeammateDistance = false
        AutoDimeSection:NewToggle("Show Teammate Distance", "Show the distance to your teammate at the top of the screen", function(state)
            showTeammateDistance = state
            teammateDistanceLabel.Visible = state
        end)
        _G._showTeammateDistance = function() return showTeammateDistance end
    end
    -- Disconnect previous connection if exists
    if _G._teammateDistanceRenderConn then _G._teammateDistanceRenderConn:Disconnect() end
    _G._teammateDistanceRenderConn = RunService.RenderStepped:Connect(function()
        if _G._showTeammateDistance and _G._showTeammateDistance() and teammateDistanceLabel.Visible then
            local _, teammate = getCourtAndTeammate()
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local teammateHRP = teammate and teammate.Character and teammate.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and teammateHRP then
                local dist = (myHRP.Position - teammateHRP.Position).Magnitude
                teammateDistanceLabel.Text = string.format("Teammate Distance: %.1f", dist)
            else
                teammateDistanceLabel.Text = "Teammate Distance: N/A"
            end
        end
    end)
end

setupTeammateDistanceCounter()

-- Re-setup the counter on character respawn
player.CharacterAdded:Connect(function()
	setupTeammateDistanceCounter()
end)

-- Self Pass Functions
local function createSelfPassButton()
    if selfPassButton then
        selfPassButton:Destroy()
    end

    selfPassButton = Instance.new("ScreenGui")
    selfPassButton.Name = "SelfPassButton"
    selfPassButton.ResetOnSpawn = false
    selfPassButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    selfPassButton.Parent = CoreGui

    local button = Instance.new("TextButton")
    button.Name = "SelfPassButton"
    button.Size = UDim2.new(0, 80, 0, 80) -- Circle, 80x80 px
    -- Default to center of screen, or use saved position
    local defaultPos = UDim2.new(0.5, -40, 0.5, -40)
    if _G.SelfPassButtonPos then
        button.Position = _G.SelfPassButtonPos
    else
        button.Position = defaultPos
    end
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Self Pass"
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.AnchorPoint = Vector2.new(0, 0)
    button.AutoButtonColor = true
    button.Active = true
    button.Draggable = true
    button.Parent = selfPassButton
    -- Make it a circle
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(1, 0)
    uicorner.Parent = button

    -- Save position on drag end
    local dragging = false
    local dragInput, mousePos, btnStartPos
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            btnStartPos = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    _G.SelfPassButtonPos = button.Position
                end
            end)
        end
    end)
    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - mousePos
            button.Position = btnStartPos + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)

    button.MouseButton1Click:Connect(function()
        print("[Self Pass] Button clicked!")
        performSelfPass()
    end)

    print("[Self Pass] Button created (universal)")
    return selfPassButton
end

local function removeSelfPassButton()
	if selfPassButton then
		selfPassButton:Destroy()
		selfPassButton = nil
	end
end

local function updateSelfPassButtonText()
	if selfPassButton then
		local button = selfPassButton:FindFirstChild("SelfPassButton")
		if button then
			button.Text = "Self Pass (" .. selfPassPlatform .. ")"
		end
	end
end

local function performSelfPass()
    if not selfPassEnabled then return end

    local char = player.Character
    if not char then return end

    local ball = getBallInstance(char)
    if not ball then return end

    -- Store original camera state
    originalCameraCFrame = camera.CFrame
    originalCameraType = camera.CameraType

    -- Store original power
    local originalPower = player:GetAttribute("Power") or 85

    -- Store anti travel state and temporarily disable
    local wasAntiTravelEnabled = antiTravelEnabled
    if wasAntiTravelEnabled then
        antiTravelEnabled = false
    end

    -- Ensure the ball is named "Basketball"
    if ball.Name ~= "Basketball" then
        ball.Name = "Basketball"
    end

    -- Set power to 85 for self pass
    player:SetAttribute("Power", 85)

    -- Switch to third person and look up or angle forward if moving fast
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local moveDir = Vector3.new(0,0,0)
    if humanoid then
        moveDir = humanoid.MoveDirection
        if moveDir.Magnitude < 0.1 and hrp then
            -- Fallback to velocity if not actively pressing a key
            local vel = hrp.Velocity
            vel = Vector3.new(vel.X, 0, vel.Z)
            if vel.Magnitude > 0.1 then
                moveDir = vel.Unit
            end
        end
    end
    local speed = moveDir.Magnitude

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if hrp and head then
        local basePos = head.Position
        local targetPos
        if speed > 0.1 then -- Now this will be true if you're moving by key or velocity
            targetPos = basePos + moveDir * 6.8 + Vector3.new(0, 30, 0)
        else
            targetPos = basePos + Vector3.new(0, 8, 0)
        end
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(basePos, targetPos)
    end

    -- Wait a moment for camera to adjust
    task.wait(0.1)

    -- Get the center of the screen in pixels
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    -- Simulate click at the center of the screen
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)

    -- Wait a moment then restore camera
    task.wait(0.1)

    -- Restore original camera
    if originalCameraType then
        camera.CameraType = originalCameraType
    end
    if originalCameraCFrame then
        camera.CFrame = originalCameraCFrame
    end

    -- Restore original power
    player:SetAttribute("Power", originalPower)

    -- Restore anti travel state
    if wasAntiTravelEnabled then
        antiTravelEnabled = true
    end
end

local function setupSelfPassInput()
	-- Set up keybind for PC
	if selfPassPlatform == "PC" then
		-- Disconnect any existing connection
		if selfPassInputConnection then
			selfPassInputConnection:Disconnect()
		end
		
		selfPassInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			print("[Self Pass] Key pressed:", input.KeyCode, "Expected:", selfPassKeybind, "Enabled:", selfPassEnabled)
			if input.KeyCode == selfPassKeybind and selfPassEnabled then
				print("[Self Pass] Triggering self pass!")
				performSelfPass()
			end
		end)
		print("[Self Pass] PC input handler set up")
	end
end

-- Self Pass Keybind Listener (PC Mode)
if selfPassInputConn then selfPassInputConn:Disconnect() end
selfPassInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not selfPassEnabled then return end
    if selfPassPlatform ~= "PC" then return end
    if gameProcessed then return end
    if input.KeyCode == selfPassKeybind then
        performSelfPass()
    end
end)

-- Social Section
SocialSection:NewButton("DISCORD LINK (PASTE IN BROWSER)", "Click to open the Discord link in your browser", function()
    setclipboard("https://discord.gg/4AWJM36S88")
    print("[Social] Discord link copied to clipboard!")
    sendWebhook("Discord link button clicked by " .. playerName)
end)

print("[✅] Script loaded successfully.")
