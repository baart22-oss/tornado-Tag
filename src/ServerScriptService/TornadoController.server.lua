-- TornadoController.server.lua
-- Spawns and drives tornados on the server.
-- Listens for RoundStateChanged to know when to start/stop.
-- Each tornado:
--   • moves along a semi-random path inside the arena
--   • pulls nearby players toward its centre (LinearVelocity / BodyVelocity)
--   • deals damage on contact every 0.5 s
--   • scales with the active difficulty preset

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── Arena bounds (adjust to match your map) ─────────────────────────────────
local ARENA_SIZE   = 400  -- half-extent; tornados stay within ±ARENA_SIZE
local ARENA_HEIGHT = 5    -- Y position tornados travel at

-- ─── Active tornado tracking ─────────────────────────────────────────────────
local activeTornados = {}  -- list of { part, thread }
local roundRunning   = false
local currentDiff    = "Medium"

-- ─── Radar broadcast ─────────────────────────────────────────────────────────
-- Every 2 seconds, tell clients with TornadoRadar about tornado positions.
task.spawn(function()
	while true do
		task.wait(2)
		if #activeTornados > 0 then
			local positions = {}
			for _, t in ipairs(activeTornados) do
				if t.part and t.part.Parent then
					table.insert(positions, t.part.Position)
				end
			end
			-- Only fire to players who own the TornadoRadar perk
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("TornadoRadar") then
					Remotes.TornadoPositions:FireClient(player, positions)
				end
			end
		end
	end
end)

-- ─── Build tornado visual ─────────────────────────────────────────────────────
local function createTornadoPart(cfg)
	local part          = Instance.new("Part")
	part.Name           = "Tornado"
	part.Anchored       = true
	part.CanCollide     = false
	part.CastShadow     = false
	part.Size           = Vector3.new(14, 40, 14)
	part.Shape          = Enum.PartType.Cylinder
	part.Material       = Enum.Material.SmoothPlastic
	part.Color          = Color3.fromRGB(130, 130, 140)
	part.Transparency   = 0.45
	part.CFrame         = CFrame.new(
		math.random(-ARENA_SIZE, ARENA_SIZE),
		ARENA_HEIGHT,
		math.random(-ARENA_SIZE, ARENA_SIZE)
	) * CFrame.Angles(0, 0, math.pi / 2)  -- lay on its side so it's vertical
	part.Parent         = workspace

	-- Spinning billboard to make it look like a funnel
	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local particles = Instance.new("ParticleEmitter")
	particles.Parent      = attachment
	particles.Texture     = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color       = ColorSequence.new(Color3.fromRGB(100, 100, 110))
	particles.Size        = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime    = NumberRange.new(1.5, 3)
	particles.Rate        = 80
	particles.Speed       = NumberRange.new(8, 18)
	particles.SpreadAngle = Vector2.new(360, 0)
	particles.RotSpeed    = NumberRange.new(-360, 360)

	return part
end

-- ─── Damage players inside the tornado ───────────────────────────────────────
local function damagePlayers(tornadoPart, cfg)
	local pos    = tornadoPart.Position
	local radius = tornadoPart.Size.X / 2 + 4   -- contact zone

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local dist = (hrp.Position - pos).Magnitude
		if dist <= radius then
			-- Check for Shield perk
			if player:GetAttribute("Shield") then
				player:SetAttribute("Shield", nil)
			else
				hum:TakeDamage(cfg.tornadoDamage)
			end
		end
	end
end

-- ─── Pull players toward the tornado centre ───────────────────────────────────
local function pullPlayers(tornadoPart, cfg)
	local pos    = tornadoPart.Position
	local pullRadius = tornadoPart.Size.X / 2 + 30

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local offset = pos - hrp.Position
		local dist   = offset.Magnitude
		if dist > 2 and dist <= pullRadius then
			local direction  = offset.Unit
			local forceMag   = cfg.pullStrength * (1 - dist / pullRadius)
			-- Apply an impulse via a temporary BodyVelocity
			local bv = hrp:FindFirstChild("TornadoPull")
			if not bv then
				bv          = Instance.new("BodyVelocity")
				bv.Name     = "TornadoPull"
				bv.MaxForce = Vector3.new(1e5, 1e4, 1e5)
				bv.Parent   = hrp
			end
			-- Blend with existing velocity
			bv.Velocity = direction * forceMag + Vector3.new(0, forceMag * 0.3, 0)
		else
			-- Remove pull when out of range
			local bv = hrp:FindFirstChild("TornadoPull")
			if bv then bv:Destroy() end
		end
	end
end

-- ─── Move tornado along a random path ────────────────────────────────────────
local function runTornado(part, cfg)
	local speed      = cfg.tornadoSpeed
	local target     = Vector3.new(
		math.random(-ARENA_SIZE, ARENA_SIZE),
		ARENA_HEIGHT,
		math.random(-ARENA_SIZE, ARENA_SIZE)
	)
	local damageTimer = 0
	local wanderTimer = 0

	while roundRunning and part.Parent do
		local dt = task.wait(0.05)  -- ~20 Hz physics step
		damageTimer = damageTimer + dt
		wanderTimer = wanderTimer + dt

		-- Pick a new waypoint every 4–8 seconds
		if wanderTimer >= math.random(4, 8) then
			wanderTimer = 0
			target = Vector3.new(
				math.random(-ARENA_SIZE, ARENA_SIZE),
				ARENA_HEIGHT,
				math.random(-ARENA_SIZE, ARENA_SIZE)
			)
		end

		-- Move toward target
		local pos       = part.Position
		local direction = (target - pos)
		if direction.Magnitude > 2 then
			direction = direction.Unit
			local newPos = pos + direction * speed * dt
			part.CFrame  = CFrame.new(newPos, newPos + direction)
				* CFrame.Angles(0, 0, math.pi / 2)
		end

		-- Pull nearby players
		pullPlayers(part, cfg)

		-- Deal damage every 0.5 s
		if damageTimer >= 0.5 then
			damageTimer = 0
			damagePlayers(part, cfg)
		end
	end

	-- Clean up pull forces on all players
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local bv = hrp:FindFirstChild("TornadoPull")
				if bv then bv:Destroy() end
			end
		end
	end

	if part.Parent then part:Destroy() end
end

-- ─── Spawn tornados for the current difficulty ────────────────────────────────
local function spawnTornados(difficulty)
	local cfg   = GameConfig.Difficulties[difficulty]
	local count = math.random(cfg.tornadoCountMin, cfg.tornadoCountMax)

	for i = 1, count do
		task.wait(math.random(2, 6))  -- stagger spawns
		if not roundRunning then break end

		local part   = createTornadoPart(cfg)
		local thread = task.spawn(runTornado, part, cfg)
		table.insert(activeTornados, { part = part, thread = thread })
	end
end

-- ─── Stop all active tornados ─────────────────────────────────────────────────
local function stopAllTornados()
	roundRunning = false
	for _, t in ipairs(activeTornados) do
		if t.part and t.part.Parent then
			t.part:Destroy()
		end
	end
	activeTornados = {}
end

-- ─── Listen for round state changes ──────────────────────────────────────────
-- RoundManager sets the shared StringValue "RoundState" in ReplicatedStorage
-- whenever the round phase changes.  We watch that value here to start and
-- stop tornados without tight coupling between the two server scripts.
local stateValue = ReplicatedStorage:FindFirstChild("RoundState")
if not stateValue then
	stateValue        = Instance.new("StringValue")
	stateValue.Name   = "RoundState"
	stateValue.Value  = "Intermission"
	stateValue.Parent = ReplicatedStorage
end

local diffValue = ReplicatedStorage:FindFirstChild("CurrentDifficulty")
if not diffValue then
	diffValue        = Instance.new("StringValue")
	diffValue.Name   = "CurrentDifficulty"
	diffValue.Value  = "Medium"
	diffValue.Parent = ReplicatedStorage
end

stateValue.Changed:Connect(function(newState)
	if newState == "Active" then
		roundRunning   = true
		currentDiff    = diffValue.Value
		activeTornados = {}
		task.spawn(spawnTornados, currentDiff)
	elseif newState == "Results" or newState == "Intermission" then
		stopAllTornados()
	end
end)
