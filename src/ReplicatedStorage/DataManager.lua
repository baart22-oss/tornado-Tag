-- DataManager.lua
-- Handles persistent player data via DataStoreService.
-- Auto-saves every 60 seconds and on PlayerRemoving.
-- Accessible from ServerScriptService scripts via require().

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local GameConfig       = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

local DataManager = {}

-- ─── DataStore handle ─────────────────────────────────────────────────────────
local playerStore = DataStoreService:GetDataStore(GameConfig.DataStoreKey)

-- In-memory cache: { [userId] = dataTable }
local dataCache = {}

-- ─── Default player data template ────────────────────────────────────────────
local function defaultData()
	return {
		coins          = 0,
		kills          = 0,
		wins           = 0,
		totalCoins     = 0,       -- all-time coins earned
		laserDamageBonus = 0,     -- permanent % bonus from shop/robux
		vipMultiplier  = false,   -- permanent 1.5× multiplier from VIP pass
		megaLaser      = false,   -- permanent +50% laser damage
		milestonesClaimed = {},   -- set of win milestones already rewarded
		lastDailyLogin = 0,       -- Unix timestamp of last daily reward claim
	}
end

-- ─── Load data for a player ───────────────────────────────────────────────────
function DataManager.loadData(player)
	local userId = tostring(player.UserId)
	local success, result = pcall(function()
		return playerStore:GetAsync(userId)
	end)

	local data
	if success and result then
		-- Merge saved data with defaults to handle new fields gracefully
		data = defaultData()
		for k, v in pairs(result) do
			data[k] = v
		end
	else
		if not success then
			warn("[DataManager] Failed to load data for", player.Name, ":", result)
		end
		data = defaultData()
	end

	dataCache[userId] = data
	return data
end

-- ─── Save data for a player ───────────────────────────────────────────────────
function DataManager.saveData(player)
	local userId = tostring(player.UserId)
	local data   = dataCache[userId]
	if not data then return end

	local success, err = pcall(function()
		playerStore:SetAsync(userId, data)
	end)

	if not success then
		warn("[DataManager] Failed to save data for", player.Name, ":", err)
	end
end

-- ─── Get cached data (must have called loadData first) ────────────────────────
function DataManager.getData(player)
	return dataCache[tostring(player.UserId)]
end

-- ─── Modify a specific field and return new value ─────────────────────────────
function DataManager.increment(player, field, amount)
	local data = dataCache[tostring(player.UserId)]
	if not data then return end
	data[field] = (data[field] or 0) + amount
	return data[field]
end

function DataManager.set(player, field, value)
	local data = dataCache[tostring(player.UserId)]
	if not data then return end
	data[field] = value
end

-- ─── Add coins (respects active per-round multipliers stored in leaderstats) ──
function DataManager.addCoins(player, amount)
	local data = dataCache[tostring(player.UserId)]
	if not data then return end

	-- Apply VIP multiplier if active
	local multiplier = 1
	if data.vipMultiplier then
		multiplier = multiplier * 1.5
	end

	-- Per-round DoubleCoins boost is tracked on the player object directly
	local boost = player:GetAttribute("DoubleCoins")
	if boost then
		multiplier = multiplier * 2
	end

	local earned = math.floor(amount * multiplier)
	data.coins      = data.coins      + earned
	data.totalCoins = data.totalCoins + earned

	-- Update the visible leaderstats coin value
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then coinsVal.Value = data.coins end
	end

	return earned
end

-- ─── Auto-save loop ───────────────────────────────────────────────────────────
function DataManager.startAutoSave()
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				DataManager.saveData(player)
			end
		end
	end)
end

-- ─── Cleanup on player leave ──────────────────────────────────────────────────
function DataManager.onPlayerRemoving(player)
	DataManager.saveData(player)
	dataCache[tostring(player.UserId)] = nil
end

return DataManager
