-- RoundManager.server.lua
-- Manages the Intermission → Active Round → Results cycle.
-- Coordinates with TornadoController, awards coins, and fires UI events.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataManager  = require(ReplicatedStorage:WaitForChild("DataManager"))
local Remotes      = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── State ────────────────────────────────────────────────────────────────────
local currentDifficulty = "Medium"
local difficultyVotes   = {}   -- { [player] = difficultyName }
local roundActive       = false
local roundKills        = {}   -- { [playerName] = count } for the current round
local roundCoins        = {}   -- { [playerName] = count } earned this round

-- ─── Leaderstats setup ────────────────────────────────────────────────────────
local function setupLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name  = "leaderstats"
	ls.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name   = "Kills"
	kills.Value  = 0
	kills.Parent = ls

	local coins = Instance.new("IntValue")
	coins.Name   = "Coins"
	coins.Value  = 0
	coins.Parent = ls

	local wins = Instance.new("IntValue")
	wins.Name   = "Wins"
	wins.Value   = 0
	wins.Parent  = ls
end

-- ─── Player management ────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
	local data = DataManager.loadData(player)

	-- Sync persistent values into leaderstats
	local ls = player:WaitForChild("leaderstats")
	ls.Kills.Value  = data.kills
	ls.Coins.Value  = data.coins
	ls.Wins.Value   = data.wins

	-- Notify client of starting coins
	Remotes.UpdateCoins:FireClient(player, data.coins)

	-- Give the LaserGun tool from ServerStorage if a round is active
	if roundActive then
		local gun = ServerStorage:FindFirstChild("LaserGun")
		if gun then gun:Clone().Parent = player.Backpack end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DataManager.onPlayerRemoving(player)
	difficultyVotes[player] = nil
end)

-- ─── Difficulty voting ────────────────────────────────────────────────────────
Remotes.SelectDifficulty.OnServerEvent:Connect(function(player, difficulty)
	if GameConfig.Difficulties[difficulty] then
		difficultyVotes[player] = difficulty
	end
end)

local function tallyDifficulty()
	local tally = {}
	for _, vote in pairs(difficultyVotes) do
		tally[vote] = (tally[vote] or 0) + 1
	end
	local best, bestCount = "Medium", 0
	for diff, count in pairs(tally) do
		if count > bestCount then
			best      = diff
			bestCount = count
		end
	end
	difficultyVotes = {}
	return best
end

-- ─── Helper: get alive players ────────────────────────────────────────────────
local function getAlivePlayers()
	local alive = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(alive, p)
			end
		end
	end
	return alive
end

-- ─── Spawn LaserGun to all current players ────────────────────────────────────
local function giveGunsToAll()
	local gun = ServerStorage:FindFirstChild("LaserGun")
	if not gun then return end
	for _, player in ipairs(Players:GetPlayers()) do
		-- Remove any existing gun first
		local existing = player.Backpack:FindFirstChild("LaserGun")
		if existing then existing:Destroy() end
		gun:Clone().Parent = player.Backpack
	end
end

-- ─── Respawn all players ──────────────────────────────────────────────────────
local function respawnAll()
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
end

-- ─── Round coin awards ────────────────────────────────────────────────────────
local function awardSurvivalCoins(difficulty)
	local cfg  = GameConfig.Difficulties[difficulty]
	local base = GameConfig.COINS_SURVIVE_INTERVAL
	for _, player in ipairs(getAlivePlayers()) do
		local earned = DataManager.addCoins(player, math.floor(base * cfg.coinMultiplier))
		roundCoins[player.Name] = (roundCoins[player.Name] or 0) + (earned or 0)
		Remotes.UpdateCoins:FireClient(player, DataManager.getData(player).coins)
	end
end

-- ─── Kill tracking (connected to Humanoid.Died) ───────────────────────────────
local killerConnections = {}

local function trackKills(victim)
	local char    = victim.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local conn
	conn = hum.Died:Connect(function()
		conn:Disconnect()
		-- Killer is stored as an attribute on the character by LaserGunServer
		local killerName = char:GetAttribute("LastAttacker")
		if killerName then
			local killer = Players:FindFirstChild(killerName)
			if killer and killer ~= victim then
				roundKills[killerName] = (roundKills[killerName] or 0) + 1

				-- Leaderstats
				local ls = killer:FindFirstChild("leaderstats")
				if ls then
					ls.Kills.Value = ls.Kills.Value + 1
				end

				-- Persistent kill count
				DataManager.increment(killer, "kills", 1)

				-- Coin reward
				local cfg = GameConfig.Difficulties[currentDifficulty]
				local earned = DataManager.addCoins(killer, math.floor(GameConfig.COINS_KILL * cfg.coinMultiplier))
				roundCoins[killerName] = (roundCoins[killerName] or 0) + (earned or 0)
				Remotes.UpdateCoins:FireClient(killer, DataManager.getData(killer).coins)

				-- Kill-feed broadcast
				Remotes.KillFeedUpdate:FireAllClients(killerName, victim.Name)
			end
		end
	end)
	table.insert(killerConnections, conn)
end

-- ─── Results calculation ──────────────────────────────────────────────────────
local function buildResults(winnerName)
	local results = { winner = winnerName, stats = {} }
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(results.stats, {
			name   = player.Name,
			kills  = roundKills[player.Name]  or 0,
			coins  = roundCoins[player.Name]  or 0,
			placement = (player.Name == winnerName) and 1 or 2,
		})
	end
	-- Sort by kills descending
	table.sort(results.stats, function(a, b) return a.kills > b.kills end)
	for i, s in ipairs(results.stats) do
		if i > 1 then s.placement = i end
	end
	return results
end

-- ─── Shared state values (read by TornadoController) ─────────────────────────
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

local function setRoundState(state, difficulty)
	if difficulty then diffValue.Value = difficulty end
	stateValue.Value = state
end

-- ─── Main round loop ──────────────────────────────────────────────────────────
DataManager.startAutoSave()

local function runGame()
	while true do
		-- ── Intermission ──────────────────────────────────────────────────────
		roundActive     = false
		roundKills      = {}
		roundCoins      = {}
		killerConnections = {}
		difficultyVotes = {}

		Remotes.RoundStateChanged:FireAllClients("Intermission", GameConfig.INTERMISSION_DURATION)
		setRoundState("Intermission")

		task.wait(GameConfig.INTERMISSION_DURATION)

		-- Tally difficulty votes
		currentDifficulty = tallyDifficulty()
		Remotes.DifficultyChanged:FireAllClients(currentDifficulty)

		-- ── Active Round ──────────────────────────────────────────────────────
		roundActive = true
		respawnAll()
		task.wait(1) -- brief pause for characters to load

		giveGunsToAll()

		-- Hook kill tracking for everyone alive
		for _, player in ipairs(Players:GetPlayers()) do
			trackKills(player)
		end
		-- Also hook for players who join mid-round
		local joinConn = Players.PlayerAdded:Connect(function(player)
			task.wait(2)
			local gun = ServerStorage:FindFirstChild("LaserGun")
			if gun then gun:Clone().Parent = player.Backpack end
			trackKills(player)
		end)

		-- Signal TornadoController to start spawning
		Remotes.RoundStateChanged:FireAllClients("Active", GameConfig.ROUND_DURATION, currentDifficulty)
		setRoundState("Active", currentDifficulty)

		-- Round timer with per-interval survival coins
		local elapsed  = 0
		local nextCoin = GameConfig.SURVIVAL_INTERVAL
		local winner   = nil

		while elapsed < GameConfig.ROUND_DURATION do
			task.wait(1)
			elapsed = elapsed + 1

			-- Survival coin tick
			if elapsed >= nextCoin then
				awardSurvivalCoins(currentDifficulty)
				nextCoin = nextCoin + GameConfig.SURVIVAL_INTERVAL
			end

			-- Check for last-player-standing
			local alive = getAlivePlayers()
			if #alive == 1 then
				winner = alive[1]
				break
			elseif #alive == 0 then
				break
			end
		end

		joinConn:Disconnect()
		for _, c in ipairs(killerConnections) do pcall(function() c:Disconnect() end) end

		-- ── Determine winner & award win coins ────────────────────────────────
		if not winner then
			-- Most kills wins; tie → first in list
			local best, bestKills = nil, -1
			for _, player in ipairs(Players:GetPlayers()) do
				local k = roundKills[player.Name] or 0
				if k > bestKills then
					best      = player
					bestKills = k
				end
			end
			winner = best
		end

		if winner then
			local cfg    = GameConfig.Difficulties[currentDifficulty]
			local earned = DataManager.addCoins(winner, math.floor(GameConfig.COINS_WIN * cfg.coinMultiplier))
			roundCoins[winner.Name] = (roundCoins[winner.Name] or 0) + (earned or 0)

			local ls = winner:FindFirstChild("leaderstats")
			if ls then ls.Wins.Value = ls.Wins.Value + 1 end
			DataManager.increment(winner, "wins", 1)
			Remotes.UpdateCoins:FireClient(winner, DataManager.getData(winner).coins)

			-- Milestone rewards
			local winData = DataManager.getData(winner)
			if winData then
				local totalWins = winData.wins
				for milestone, bonus in pairs(GameConfig.MilestoneRewards) do
					if totalWins >= milestone and not winData.milestonesClaimed[tostring(milestone)] then
						winData.milestonesClaimed[tostring(milestone)] = true
						DataManager.addCoins(winner, bonus)
						Remotes.UpdateCoins:FireClient(winner, DataManager.getData(winner).coins)
					end
				end
			end
		end

		-- ── Signal to stop tornados ────────────────────────────────────────────
		Remotes.RoundStateChanged:FireAllClients("Results", 10, currentDifficulty)
		setRoundState("Results")

		-- Build & fire results screen
		local results = buildResults(winner and winner.Name or "")
		Remotes.ShowResults:FireAllClients(results)

		-- Save all data at round end
		for _, player in ipairs(Players:GetPlayers()) do
			DataManager.saveData(player)
		end

		task.wait(10) -- show results for 10 seconds
	end
end

-- Kick off the game loop
task.spawn(runGame)
