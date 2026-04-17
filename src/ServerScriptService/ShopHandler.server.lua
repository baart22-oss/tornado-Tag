-- ShopHandler.server.lua
-- Processes coin-shop purchases and Robux developer product receipts.
-- Responds to BuyItem RemoteEvent and handles MarketplaceService callbacks.

local Players             = game:GetService("Players")
local MarketplaceService  = game:GetService("MarketplaceService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))
local Remotes     = require(ReplicatedStorage:WaitForChild("Remotes"))

-- ─── Helper: apply a purchased item to a player ───────────────────────────────
local function applyItem(player, itemId)
	local data = DataManager.getData(player)
	if not data then return false, "Data not loaded" end

	if itemId == "SpeedBoost" then
		player:SetAttribute("SpeedBoost", true)
		-- Actual WalkSpeed change is applied on character spawn / round start
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = hum.WalkSpeed * 1.2 end
		end

	elseif itemId == "Shield" then
		player:SetAttribute("Shield", true)

	elseif itemId == "DoubleCoins" then
		player:SetAttribute("DoubleCoins", true)

	elseif itemId == "LaserUpgrade" then
		data.laserDamageBonus = (data.laserDamageBonus or 0) + 25

	elseif itemId == "TornadoRadar" then
		player:SetAttribute("TornadoRadar", true)

	else
		return false, "Unknown item: " .. tostring(itemId)
	end

	return true
end

-- ─── Coin-shop purchase handler ───────────────────────────────────────────────
Remotes.BuyItem.OnServerEvent:Connect(function(player, itemId)
	-- Find item config
	local itemCfg = nil
	for _, item in ipairs(GameConfig.ShopItems) do
		if item.id == itemId then
			itemCfg = item
			break
		end
	end

	if not itemCfg then
		Remotes.PurchaseResult:FireClient(player, false, "Item not found.")
		return
	end

	local data = DataManager.getData(player)
	if not data then
		Remotes.PurchaseResult:FireClient(player, false, "Data not ready.")
		return
	end

	if data.coins < itemCfg.cost then
		Remotes.PurchaseResult:FireClient(player, false, "Not enough coins.")
		return
	end

	-- Deduct coins
	data.coins = data.coins - itemCfg.cost
	local ls   = player:FindFirstChild("leaderstats")
	if ls then
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then coinsVal.Value = data.coins end
	end
	Remotes.UpdateCoins:FireClient(player, data.coins)

	-- Apply effect
	local ok, err = applyItem(player, itemId)
	if ok then
		Remotes.PurchaseResult:FireClient(player, true, itemCfg.name .. " purchased!")
	else
		-- Refund on failure
		data.coins = data.coins + itemCfg.cost
		if ls then
			local coinsVal = ls:FindFirstChild("Coins")
			if coinsVal then coinsVal.Value = data.coins end
		end
		Remotes.UpdateCoins:FireClient(player, data.coins)
		Remotes.PurchaseResult:FireClient(player, false, err or "Purchase failed.")
	end
end)

-- ─── Developer Product receipt handler ────────────────────────────────────────
-- Build a lookup table: productId → handler function
local productHandlers = {}

local function registerProduct(productId, handler)
	if productId and productId ~= 0 then
		productHandlers[productId] = handler
	end
end

for _, product in ipairs(GameConfig.RobuxProducts) do
	if product.productId then
		local pid = product.productId
		local id  = product.id

		registerProduct(pid, function(player)
			local data = DataManager.getData(player)
			if not data then return false end

			if id == "StarterPack" then
				DataManager.addCoins(player, 500)
				player:SetAttribute("SpeedBoost", true)
				player:SetAttribute("Shield", true)

			elseif id == "MegaLaser" then
				data.megaLaser = true
				data.laserDamageBonus = (data.laserDamageBonus or 0) + 50

			elseif id == "CoinBundle1K" then
				DataManager.addCoins(player, 1000)

			elseif id == "CoinBundle5K" then
				DataManager.addCoins(player, 5000)
			end

			Remotes.UpdateCoins:FireClient(player, DataManager.getData(player).coins)
			DataManager.saveData(player)
			return true
		end)
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left; grant next time they join (not implemented here for brevity)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = productHandlers[receiptInfo.ProductId]
	if handler then
		local ok, err = pcall(handler, player)
		if ok then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("[ShopHandler] ProcessReceipt error:", err)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ─── Game Pass purchase handler ───────────────────────────────────────────────
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end

	for _, product in ipairs(GameConfig.RobuxProducts) do
		if product.gamePassId == gamePassId then
			if product.id == "VIPPass" then
				local data = DataManager.getData(player)
				if data then
					data.vipMultiplier = true
					DataManager.saveData(player)
				end
			end
			break
		end
	end
end)

-- ─── Check game pass ownership on join ───────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to be loaded by RoundManager
	task.wait(3)
	for _, product in ipairs(GameConfig.RobuxProducts) do
		if product.gamePassId and product.gamePassId ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, product.gamePassId)
			end)
			if ok and owns then
				local data = DataManager.getData(player)
				if data and product.id == "VIPPass" then
					data.vipMultiplier = true
				end
			end
		end
	end
end)
