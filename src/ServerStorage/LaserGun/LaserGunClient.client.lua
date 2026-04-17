-- LaserGunClient.client.lua
-- Client-side laser gun: handles input, fires to server, renders beam/hit-marker.
-- This LocalScript runs inside the Tool when it's in the player's character.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))

local tool        = script.Parent
local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

-- ─── Cooldown state ───────────────────────────────────────────────────────────
local canFire     = true
local cooldown    = GameConfig.LaserCooldown

-- ─── Build a muzzle attachment on the handle ──────────────────────────────────
local handle = tool:WaitForChild("Handle", 5)
if not handle then
	-- Create a minimal handle if the tool doesn't have one yet
	handle             = Instance.new("Part")
	handle.Name        = "Handle"
	handle.Size        = Vector3.new(0.3, 0.3, 2.5)
	handle.BrickColor  = BrickColor.new("Dark stone grey")
	handle.Material    = Enum.Material.Metal
	handle.Parent      = tool
end

-- ─── Fire the laser ───────────────────────────────────────────────────────────
local function fire()
	if not canFire then return end
	local char = localPlayer.Character
	if not char then return end

	-- Origin: muzzle of the handle
	local origin    = handle.CFrame.Position
	local direction = (camera.CFrame.LookVector)

	-- Fire to server
	Remotes.LaserFired:FireServer(origin, direction)

	-- Client-side cooldown
	canFire = false
	task.delay(cooldown, function()
		canFire = true
	end)
end

-- ─── Input ────────────────────────────────────────────────────────────────────
tool.Activated:Connect(fire)

-- ─── Render laser beam (triggered by server broadcast) ────────────────────────
-- Create a temporary beam part
local function renderBeam(shooter, fromPos, toPos)
	-- Only render if it's near our camera (optimisation: skip far shots)
	local dist = (camera.CFrame.Position - fromPos).Magnitude
	if dist > 600 then return end

	local length    = (toPos - fromPos).Magnitude
	local midpoint  = (fromPos + toPos) / 2

	local beam             = Instance.new("Part")
	beam.Name              = "LaserBeam"
	beam.Anchored          = true
	beam.CanCollide        = false
	beam.CastShadow        = false
	beam.Size              = Vector3.new(0.08, 0.08, length)
	beam.CFrame            = CFrame.lookAt(midpoint, toPos)
	beam.Material          = Enum.Material.Neon
	beam.Color             = Color3.fromRGB(255, 50, 50)
	beam.Transparency      = 0.2
	beam.Parent            = workspace

	-- Fade and destroy
	task.spawn(function()
		for i = 1, 5 do
			task.wait(0.04)
			beam.Transparency = 0.2 + i * 0.15
		end
		beam:Destroy()
	end)
end

Remotes.ShowLaserBeam.OnClientEvent:Connect(renderBeam)

-- ─── Hit marker ───────────────────────────────────────────────────────────────
local hitMarkerGui
task.spawn(function()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screen    = playerGui:FindFirstChild("MainHUD")
	if not screen then return end

	hitMarkerGui = screen:FindFirstChild("HitMarker")
end)

Remotes.HitConfirmed.OnClientEvent:Connect(function(isHeadshot)
	-- Try to show the hit marker; fall back gracefully if the GUI isn't ready
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local screen = playerGui:FindFirstChild("MainHUD")
	if not screen then return end

	local marker = screen:FindFirstChild("HitMarker")
	if not marker then return end

	marker.Visible    = true
	marker.ImageColor3 = isHeadshot
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 255, 255)

	task.delay(0.15, function()
		if marker then marker.Visible = false end
	end)
end)
