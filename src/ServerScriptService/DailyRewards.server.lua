-- DailyRewards.server.lua
-- Grants a daily login bonus of 50 coins once per calendar day.
-- Uses the lastDailyLogin Unix timestamp stored in the player's DataStore entry.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))
local Remotes     = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── Check and award daily reward ────────────────────────────────────────────
local function checkDailyReward(player)
	-- Wait for DataManager to finish loading
	task.wait(3)

	local data = DataManager.getData(player)
	if not data then return end

	local now      = os.time()
	local lastTime = data.lastDailyLogin or 0

	-- Compare calendar day (UTC)
	local lastDay  = math.floor(lastTime  / 86400)
	local today    = math.floor(now        / 86400)

	if today > lastDay then
		-- New day — award the bonus
		data.lastDailyLogin = now
		local earned = DataManager.addCoins(player, GameConfig.DailyLoginReward)
		Remotes.UpdateCoins:FireClient(player, DataManager.getData(player).coins)
		Remotes.PurchaseResult:FireClient(
			player,
			true,
			string.format("🎁 Daily reward: +%d coins!", earned or GameConfig.DailyLoginReward)
		)
		DataManager.saveData(player)
	end
end

-- ─── Connect to PlayerAdded ───────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.spawn(checkDailyReward, player)
end)

-- Handle players who were already in-game before this script ran
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkDailyReward, player)
end
