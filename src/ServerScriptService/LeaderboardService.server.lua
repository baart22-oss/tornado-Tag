-- LeaderboardService.server.lua
-- Maintains persistent global leaderboards using OrderedDataStore.
-- Updates at the end of each round and serves data to clients on request.

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── OrderedDataStore handles ─────────────────────────────────────────────────
local winsStore  = DataStoreService:GetOrderedDataStore(GameConfig.GlobalWinsStore)
local coinsStore = DataStoreService:GetOrderedDataStore(GameConfig.GlobalCoinsStore)

-- ─── Update a player's entry in a store ───────────────────────────────────────
local function updateStore(store, userId, value)
	local ok, err = pcall(function()
		store:SetAsync(tostring(userId), value)
	end)
	if not ok then
		warn("[LeaderboardService] UpdateStore error:", err)
	end
end

-- ─── Fetch top N entries from an OrderedDataStore ─────────────────────────────
local function getTopEntries(store, count)
	local pages
	local ok, err = pcall(function()
		pages = store:GetSortedAsync(false, count)
	end)
	if not ok then
		warn("[LeaderboardService] GetSortedAsync error:", err)
		return {}
	end

	local entries = {}
	local success, data = pcall(function()
		return pages:GetCurrentPage()
	end)
	if success and data then
		for _, entry in ipairs(data) do
			-- Attempt to get a display name from UserId
			local displayName = tostring(entry.key)
			local ok2, name = pcall(function()
				return Players:GetNameFromUserIdAsync(tonumber(entry.key))
			end)
			if ok2 then displayName = name end

			table.insert(entries, {
				name  = displayName,
				value = entry.value,
			})
		end
	end
	return entries
end

-- ─── Update global leaderboard at round end ───────────────────────────────────
local stateValue = ReplicatedStorage:FindFirstChild("RoundState")

-- Wait until the value exists (created by RoundManager)
if not stateValue then
	stateValue = ReplicatedStorage:WaitForChild("RoundState", 30)
end

if stateValue then
	stateValue.Changed:Connect(function(newState)
		if newState ~= "Results" then return end

		for _, player in ipairs(Players:GetPlayers()) do
			local ls = player:FindFirstChild("leaderstats")
			if not ls then continue end

			local wins  = ls:FindFirstChild("Wins")
			local coins = ls:FindFirstChild("Coins")

			if wins then
				updateStore(winsStore, player.UserId, wins.Value)
			end
			if coins then
				updateStore(coinsStore, player.UserId, coins.Value)
			end
		end
	end)
end

-- ─── Serve leaderboard data to clients on request ────────────────────────────
Remotes.RequestLeaderboard.OnServerInvoke = function(_player, boardType)
	if boardType == "Wins" then
		return getTopEntries(winsStore, 20)
	elseif boardType == "Coins" then
		return getTopEntries(coinsStore, 20)
	end
	return {}
end

-- ─── Surface GUI leaderboard board (optional in-world part) ──────────────────
-- If a Part named "LeaderboardBoard" exists in Workspace, we populate it.
task.spawn(function()
	local board = workspace:WaitForChild("LeaderboardBoard", 10)
	if not board then return end  -- no board in the map, skip

	local surfaceGui = board:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then
		surfaceGui        = Instance.new("SurfaceGui")
		surfaceGui.Face   = Enum.NormalId.Front
		surfaceGui.Parent = board
	end

	local function refreshBoard()
		-- Clear existing children
		for _, child in ipairs(surfaceGui:GetChildren()) do
			child:Destroy()
		end

		local topWins = getTopEntries(winsStore, 10)

		local title       = Instance.new("TextLabel")
		title.Size        = UDim2.new(1, 0, 0.1, 0)
		title.Position    = UDim2.new(0, 0, 0, 0)
		title.Text        = "🏆 TOP PLAYERS – WINS"
		title.TextScaled  = true
		title.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
		title.TextColor3  = Color3.fromRGB(255, 215, 0)
		title.Font        = Enum.Font.GothamBold
		title.Parent      = surfaceGui

		for i, entry in ipairs(topWins) do
			local row        = Instance.new("TextLabel")
			row.Size         = UDim2.new(1, 0, 0.08, 0)
			row.Position     = UDim2.new(0, 0, 0.1 + (i - 1) * 0.08, 0)
			row.Text         = string.format("#%d  %s  —  %d wins", i, entry.name, entry.value)
			row.TextScaled   = true
			row.BackgroundColor3 = (i % 2 == 0)
				and Color3.fromRGB(30, 30, 55)
				or  Color3.fromRGB(20, 20, 40)
			row.TextColor3   = Color3.fromRGB(220, 220, 255)
			row.Font         = Enum.Font.Gotham
			row.Parent       = surfaceGui
		end
	end

	-- Refresh every 5 minutes
	while true do
		pcall(refreshBoard)
		task.wait(300)
	end
end)
