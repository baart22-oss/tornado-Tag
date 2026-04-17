-- LaserGunServer.server.lua
-- Server-side laser gun logic.
-- Validates shots fired by clients, applies damage, and broadcasts beam effects.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))
local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── Cooldown tracking per player ─────────────────────────────────────────────
local lastShot = {}  -- { [userId] = tick() }

-- ─── Process a laser shot request from a client ───────────────────────────────
Remotes.LaserFired.OnServerEvent:Connect(function(player, origin, direction)
	-- Validate types
	if typeof(origin)    ~= "Vector3" then return end
	if typeof(direction) ~= "Vector3" then return end

	-- Cooldown check
	local userId = player.UserId
	local now    = tick()
	if lastShot[userId] and (now - lastShot[userId]) < GameConfig.LaserCooldown then
		return  -- still on cooldown
	end
	lastShot[userId] = now

	-- Ensure the player has the tool equipped
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChild("LaserGun")
	if not tool then return end

	-- ── Raycast ──────────────────────────────────────────────────────────────
	local rayParams       = RaycastParams.new()
	rayParams.FilterType  = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }

	local safeDir = direction.Unit  -- normalise, just in case
	local result  = workspace:Raycast(origin, safeDir * GameConfig.LaserRange, rayParams)

	local hitPos  = result and result.Position or (origin + safeDir * GameConfig.LaserRange)
	local hitPart = result and result.Instance  or nil

	-- ── Determine if we hit a player ──────────────────────────────────────────
	local hitPlayer = nil
	local isHeadshot = false

	if hitPart then
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			local victim = Players:GetPlayerFromCharacter(model)
			if victim and victim ~= player then
				hitPlayer  = victim
				isHeadshot = (hitPart.Name == "Head")
			end
		end
	end

	-- ── Apply damage ──────────────────────────────────────────────────────────
	if hitPlayer then
		local victimChar = hitPlayer.Character
		local hum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			-- Calculate final damage
			local data   = DataManager.getData(player)
			local bonus  = data and (data.laserDamageBonus or 0) or 0
			local damage = GameConfig.LaserDamage * (1 + bonus / 100)
			if isHeadshot then
				damage = damage * GameConfig.HeadshotMultiplier
			end
			damage = math.floor(damage)

			-- Mark attacker on the character so RoundManager can credit the kill
			victimChar:SetAttribute("LastAttacker", player.Name)

			hum:TakeDamage(damage)

			-- Confirm hit to shooter
			Remotes.HitConfirmed:FireClient(player, isHeadshot)
		end
	end

	-- ── Broadcast beam visual to all clients ──────────────────────────────────
	Remotes.ShowLaserBeam:FireAllClients(player, origin, hitPos)
end)
