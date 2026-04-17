-- ShopGui.client.lua
-- Tabbed shop with a Coins tab and a Robux tab.
-- Opened via a button in the HUD or by pressing "B".

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Screen ────────────────────────────────────────────────────────────────────
local screenGui             = Instance.new("ScreenGui")
screenGui.Name              = "ShopGui"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Enabled           = false
screenGui.Parent            = playerGui

-- Backdrop
local backdrop                  = Instance.new("Frame")
backdrop.Size                   = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel        = 0
backdrop.Parent                 = screenGui

-- Panel
local panel                     = Instance.new("Frame")
panel.Size                      = UDim2.new(0, 600, 0, 480)
panel.Position                  = UDim2.new(0.5, -300, 0.5, -240)
panel.BackgroundColor3          = Color3.fromRGB(16, 16, 28)
panel.BackgroundTransparency    = 0.05
panel.BorderSizePixel           = 0
panel.Parent                    = screenGui

local panelCorner               = Instance.new("UICorner")
panelCorner.CornerRadius        = UDim.new(0, 16)
panelCorner.Parent              = panel

-- Title
local title                     = Instance.new("TextLabel")
title.Size                      = UDim2.new(1, -60, 0, 44)
title.Position                  = UDim2.new(0, 16, 0, 8)
title.Text                      = "🛒  Shop"
title.Font                      = Enum.Font.GothamBold
title.TextSize                  = 26
title.TextColor3                = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency    = 1
title.TextXAlignment            = Enum.TextXAlignment.Left
title.Parent                    = panel

-- Close button
local closeBtn                  = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 36, 0, 36)
closeBtn.Position               = UDim2.new(1, -44, 0, 8)
closeBtn.Text                   = "✕"
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.TextSize               = 20
closeBtn.TextColor3             = Color3.fromRGB(200, 200, 200)
closeBtn.BackgroundColor3       = Color3.fromRGB(60, 20, 20)
closeBtn.BorderSizePixel        = 0
closeBtn.Parent                 = panel
local closeCorner               = Instance.new("UICorner")
closeCorner.CornerRadius        = UDim.new(0, 8)
closeCorner.Parent              = closeBtn
closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- ─── Tab buttons ──────────────────────────────────────────────────────────────
local tabBar                    = Instance.new("Frame")
tabBar.Size                     = UDim2.new(1, -32, 0, 36)
tabBar.Position                 = UDim2.new(0, 16, 0, 56)
tabBar.BackgroundTransparency   = 1
tabBar.Parent                   = panel

local coinsTab                  = Instance.new("TextButton")
coinsTab.Size                   = UDim2.new(0.5, -4, 1, 0)
coinsTab.Position               = UDim2.new(0, 0, 0, 0)
coinsTab.Text                   = "🪙  Coins"
coinsTab.Font                   = Enum.Font.GothamBold
coinsTab.TextSize               = 16
coinsTab.TextColor3             = Color3.fromRGB(255, 215, 0)
coinsTab.BackgroundColor3       = Color3.fromRGB(40, 40, 60)
coinsTab.BorderSizePixel        = 0
coinsTab.Parent                 = tabBar
local coinsTabCorner            = Instance.new("UICorner")
coinsTabCorner.CornerRadius     = UDim.new(0, 8)
coinsTabCorner.Parent           = coinsTab

local robuxTab                  = Instance.new("TextButton")
robuxTab.Size                   = UDim2.new(0.5, -4, 1, 0)
robuxTab.Position               = UDim2.new(0.5, 4, 0, 0)
robuxTab.Text                   = "💎  Robux"
robuxTab.Font                   = Enum.Font.GothamBold
robuxTab.TextSize               = 16
robuxTab.TextColor3             = Color3.fromRGB(180, 180, 255)
robuxTab.BackgroundColor3       = Color3.fromRGB(28, 28, 44)
robuxTab.BorderSizePixel        = 0
robuxTab.Parent                 = tabBar
local robuxTabCorner            = Instance.new("UICorner")
robuxTabCorner.CornerRadius     = UDim.new(0, 8)
robuxTabCorner.Parent           = robuxTab

-- ─── Scroll frame for items ───────────────────────────────────────────────────
local scrollFrame               = Instance.new("ScrollingFrame")
scrollFrame.Size                = UDim2.new(1, -32, 1, -114)
scrollFrame.Position            = UDim2.new(0, 16, 0, 100)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness  = 6
scrollFrame.BorderSizePixel     = 0
scrollFrame.Parent              = panel

local listLayout                = Instance.new("UIListLayout")
listLayout.Padding              = UDim.new(0, 8)
listLayout.SortOrder            = Enum.SortOrder.LayoutOrder
listLayout.Parent               = scrollFrame

-- ─── Status message ───────────────────────────────────────────────────────────
local statusLabel               = Instance.new("TextLabel")
statusLabel.Name                = "StatusLabel"
statusLabel.Size                = UDim2.new(1, -32, 0, 28)
statusLabel.Position            = UDim2.new(0, 16, 1, -36)
statusLabel.Text                = ""
statusLabel.Font                = Enum.Font.Gotham
statusLabel.TextSize            = 15
statusLabel.TextColor3          = Color3.fromRGB(100, 220, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment      = Enum.TextXAlignment.Center
statusLabel.Parent              = panel

Remotes.PurchaseResult.OnClientEvent:Connect(function(success, message)
	statusLabel.Text       = message or ""
	statusLabel.TextColor3 = success
		and Color3.fromRGB(100, 220, 100)
		or  Color3.fromRGB(255, 80, 80)
	task.delay(3, function()
		if statusLabel.Text == message then
			statusLabel.Text = ""
		end
	end)
end)

-- ─── Build item card ──────────────────────────────────────────────────────────
local function buildCoinCard(item, order)
	local card                      = Instance.new("Frame")
	card.Name                       = item.id
	card.Size                       = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3           = Color3.fromRGB(28, 28, 44)
	card.BorderSizePixel            = 0
	card.LayoutOrder                = order
	card.Parent                     = scrollFrame

	local corner                    = Instance.new("UICorner")
	corner.CornerRadius             = UDim.new(0, 10)
	corner.Parent                   = card

	-- Icon
	local icon                      = Instance.new("TextLabel")
	icon.Size                       = UDim2.new(0, 60, 1, 0)
	icon.Position                   = UDim2.new(0, 8, 0, 0)
	icon.Text                       = item.icon or "?"
	icon.Font                       = Enum.Font.GothamBold
	icon.TextSize                   = 30
	icon.BackgroundTransparency     = 1
	icon.Parent                     = card

	-- Name
	local nameL                     = Instance.new("TextLabel")
	nameL.Size                      = UDim2.new(0.5, 0, 0, 28)
	nameL.Position                  = UDim2.new(0, 72, 0, 8)
	nameL.Text                      = item.name
	nameL.Font                      = Enum.Font.GothamBold
	nameL.TextSize                  = 16
	nameL.TextColor3                = Color3.fromRGB(255, 255, 255)
	nameL.BackgroundTransparency    = 1
	nameL.TextXAlignment            = Enum.TextXAlignment.Left
	nameL.Parent                    = card

	-- Description
	local descL                     = Instance.new("TextLabel")
	descL.Size                      = UDim2.new(0.55, 0, 0, 24)
	descL.Position                  = UDim2.new(0, 72, 0, 36)
	descL.Text                      = item.description
	descL.Font                      = Enum.Font.Gotham
	descL.TextSize                  = 12
	descL.TextColor3                = Color3.fromRGB(160, 160, 180)
	descL.BackgroundTransparency    = 1
	descL.TextXAlignment            = Enum.TextXAlignment.Left
	descL.TextWrapped               = true
	descL.Parent                    = card

	-- Buy button
	local buyBtn                    = Instance.new("TextButton")
	buyBtn.Size                     = UDim2.new(0, 120, 0, 38)
	buyBtn.Position                 = UDim2.new(1, -132, 0.5, -19)
	buyBtn.Text                     = string.format("🪙 %d", item.cost)
	buyBtn.Font                     = Enum.Font.GothamBold
	buyBtn.TextSize                 = 15
	buyBtn.TextColor3               = Color3.fromRGB(255, 255, 255)
	buyBtn.BackgroundColor3         = Color3.fromRGB(50, 140, 50)
	buyBtn.BorderSizePixel          = 0
	buyBtn.Parent                   = card
	local buyCorner                 = Instance.new("UICorner")
	buyCorner.CornerRadius          = UDim.new(0, 8)
	buyCorner.Parent                = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		Remotes.BuyItem:FireServer(item.id)
	end)
end

local function buildRobuxCard(product, order)
	local card                      = Instance.new("Frame")
	card.Name                       = product.id
	card.Size                       = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3           = Color3.fromRGB(28, 28, 55)
	card.BorderSizePixel            = 0
	card.LayoutOrder                = order
	card.Parent                     = scrollFrame

	local corner                    = Instance.new("UICorner")
	corner.CornerRadius             = UDim.new(0, 10)
	corner.Parent                   = card

	local icon                      = Instance.new("TextLabel")
	icon.Size                       = UDim2.new(0, 60, 1, 0)
	icon.Position                   = UDim2.new(0, 8, 0, 0)
	icon.Text                       = product.icon or "?"
	icon.Font                       = Enum.Font.GothamBold
	icon.TextSize                   = 30
	icon.BackgroundTransparency     = 1
	icon.Parent                     = card

	local nameL                     = Instance.new("TextLabel")
	nameL.Size                      = UDim2.new(0.5, 0, 0, 28)
	nameL.Position                  = UDim2.new(0, 72, 0, 8)
	nameL.Text                      = product.name
	nameL.Font                      = Enum.Font.GothamBold
	nameL.TextSize                  = 16
	nameL.TextColor3                = Color3.fromRGB(180, 180, 255)
	nameL.BackgroundTransparency    = 1
	nameL.TextXAlignment            = Enum.TextXAlignment.Left
	nameL.Parent                    = card

	local descL                     = Instance.new("TextLabel")
	descL.Size                      = UDim2.new(0.55, 0, 0, 24)
	descL.Position                  = UDim2.new(0, 72, 0, 36)
	descL.Text                      = product.description
	descL.Font                      = Enum.Font.Gotham
	descL.TextSize                  = 12
	descL.TextColor3                = Color3.fromRGB(160, 160, 200)
	descL.BackgroundTransparency    = 1
	descL.TextXAlignment            = Enum.TextXAlignment.Left
	descL.TextWrapped               = true
	descL.Parent                    = card

	local buyBtn                    = Instance.new("TextButton")
	buyBtn.Size                     = UDim2.new(0, 120, 0, 38)
	buyBtn.Position                 = UDim2.new(1, -132, 0.5, -19)
	buyBtn.Text                     = string.format("R$ %d", product.robux)
	buyBtn.Font                     = Enum.Font.GothamBold
	buyBtn.TextSize                 = 15
	buyBtn.TextColor3               = Color3.fromRGB(255, 255, 255)
	buyBtn.BackgroundColor3         = Color3.fromRGB(0, 100, 200)
	buyBtn.BorderSizePixel          = 0
	buyBtn.Parent                   = card
	local buyCorner                 = Instance.new("UICorner")
	buyCorner.CornerRadius          = UDim.new(0, 8)
	buyCorner.Parent                = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		if product.gamePassId and product.gamePassId ~= 0 then
			MarketplaceService:PromptGamePassPurchase(localPlayer, product.gamePassId)
		elseif product.productId and product.productId ~= 0 then
			MarketplaceService:PromptProductPurchase(localPlayer, product.productId)
		end
	end)
end

-- ─── Tab switching ────────────────────────────────────────────────────────────
local currentTab = "Coins"

local function showCoinsTab()
	currentTab = "Coins"
	coinsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	robuxTab.BackgroundColor3 = Color3.fromRGB(28, 28, 44)

	-- Clear and rebuild
	for _, c in ipairs(scrollFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i, item in ipairs(GameConfig.ShopItems) do
		buildCoinCard(item, i)
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.ShopItems * 80)
end

local function showRobuxTab()
	currentTab = "Robux"
	robuxTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	coinsTab.BackgroundColor3 = Color3.fromRGB(28, 28, 44)

	for _, c in ipairs(scrollFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i, product in ipairs(GameConfig.RobuxProducts) do
		buildRobuxCard(product, i)
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.RobuxProducts * 80)
end

coinsTab.MouseButton1Click:Connect(showCoinsTab)
robuxTab.MouseButton1Click:Connect(showRobuxTab)

-- ─── Show/hide via InputHandler (B key) ──────────────────────────────────────
-- The InputHandler.client.lua fires a BindableEvent; we just expose a toggle.
-- For now, keep it simple — "B" is handled in InputHandler.

-- Initial tab
showCoinsTab()

-- Expose toggle function for InputHandler
localPlayer:SetAttribute("ShopOpen", false)
local function toggleShop()
	screenGui.Enabled = not screenGui.Enabled
	localPlayer:SetAttribute("ShopOpen", screenGui.Enabled)
	if screenGui.Enabled then
		showCoinsTab()
	end
end

-- Store toggle in a BindableFunction so InputHandler can call it
local toggleBF = Instance.new("BindableFunction")
toggleBF.Name   = "ToggleShop"
toggleBF.Parent = playerGui
toggleBF.OnInvoke = function()
	toggleShop()
end
