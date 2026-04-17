-- ResultsScreen.client.lua
-- End-of-round overlay showing placement, kills, coins earned, and the MVP.
-- Automatically hides after the results period.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes     = require(ReplicatedStorage:WaitForChild("Remotes"))

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Build ScreenGui ──────────────────────────────────────────────────────────
local screenGui             = Instance.new("ScreenGui")
screenGui.Name              = "ResultsScreen"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Enabled           = false
screenGui.Parent            = playerGui

-- Backdrop
local backdrop                  = Instance.new("Frame")
backdrop.Size                   = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.4
backdrop.BorderSizePixel        = 0
backdrop.Parent                 = screenGui

-- Panel
local panel                     = Instance.new("Frame")
panel.Size                      = UDim2.new(0, 560, 0, 460)
panel.Position                  = UDim2.new(0.5, -280, 0.5, -230)
panel.BackgroundColor3          = Color3.fromRGB(14, 14, 26)
panel.BackgroundTransparency    = 0.05
panel.BorderSizePixel           = 0
panel.Parent                    = screenGui

local panelCorner               = Instance.new("UICorner")
panelCorner.CornerRadius        = UDim.new(0, 16)
panelCorner.Parent              = panel

-- Title
local title                     = Instance.new("TextLabel")
title.Name                      = "Title"
title.Size                      = UDim2.new(1, 0, 0, 54)
title.Position                  = UDim2.new(0, 0, 0, 8)
title.Text                      = "🏆  Round Results"
title.Font                      = Enum.Font.GothamBold
title.TextSize                  = 30
title.TextColor3                = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency    = 1
title.Parent                    = panel

-- MVP banner
local mvpBanner                 = Instance.new("Frame")
mvpBanner.Name                  = "MVPBanner"
mvpBanner.Size                  = UDim2.new(1, -32, 0, 60)
mvpBanner.Position              = UDim2.new(0, 16, 0, 66)
mvpBanner.BackgroundColor3      = Color3.fromRGB(60, 50, 10)
mvpBanner.BorderSizePixel       = 0
mvpBanner.Parent                = panel
local mvpCorner                 = Instance.new("UICorner")
mvpCorner.CornerRadius          = UDim.new(0, 10)
mvpCorner.Parent                = mvpBanner

local mvpLabel                  = Instance.new("TextLabel")
mvpLabel.Name                   = "MVPLabel"
mvpLabel.Size                   = UDim2.new(1, -20, 1, 0)
mvpLabel.Position               = UDim2.new(0, 10, 0, 0)
mvpLabel.Text                   = "👑  MVP: —"
mvpLabel.Font                   = Enum.Font.GothamBold
mvpLabel.TextSize               = 22
mvpLabel.TextColor3             = Color3.fromRGB(255, 215, 0)
mvpLabel.BackgroundTransparency = 1
mvpLabel.Parent                 = mvpBanner

-- Personal stats
local statsFrame                = Instance.new("Frame")
statsFrame.Name                 = "PersonalStats"
statsFrame.Size                 = UDim2.new(1, -32, 0, 70)
statsFrame.Position             = UDim2.new(0, 16, 0, 136)
statsFrame.BackgroundColor3     = Color3.fromRGB(22, 22, 40)
statsFrame.BorderSizePixel      = 0
statsFrame.Parent               = panel
local statsCorner               = Instance.new("UICorner")
statsCorner.CornerRadius        = UDim.new(0, 10)
statsCorner.Parent              = statsFrame

local placementLabel            = Instance.new("TextLabel")
placementLabel.Name             = "Placement"
placementLabel.Size             = UDim2.new(0.33, 0, 1, 0)
placementLabel.Text             = "#—"
placementLabel.Font             = Enum.Font.GothamBold
placementLabel.TextSize         = 28
placementLabel.TextColor3       = Color3.fromRGB(255, 215, 0)
placementLabel.BackgroundTransparency = 1
placementLabel.Parent           = statsFrame

local killsLabel                = Instance.new("TextLabel")
killsLabel.Name                 = "Kills"
killsLabel.Size                 = UDim2.new(0.33, 0, 1, 0)
killsLabel.Position             = UDim2.new(0.33, 0, 0, 0)
killsLabel.Text                 = "💀 0 kills"
killsLabel.Font                 = Enum.Font.GothamBold
killsLabel.TextSize             = 20
killsLabel.TextColor3           = Color3.fromRGB(255, 120, 120)
killsLabel.BackgroundTransparency = 1
killsLabel.Parent               = statsFrame

local coinsLabel                = Instance.new("TextLabel")
coinsLabel.Name                 = "Coins"
coinsLabel.Size                 = UDim2.new(0.33, 0, 1, 0)
coinsLabel.Position             = UDim2.new(0.66, 0, 0, 0)
coinsLabel.Text                 = "🪙 0 coins"
coinsLabel.Font                 = Enum.Font.GothamBold
coinsLabel.TextSize             = 20
coinsLabel.TextColor3           = Color3.fromRGB(255, 215, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Parent               = statsFrame

-- All-players leaderboard in results
local scroll                    = Instance.new("ScrollingFrame")
scroll.Size                     = UDim2.new(1, -32, 1, -240)
scroll.Position                 = UDim2.new(0, 16, 0, 218)
scroll.BackgroundTransparency   = 1
scroll.ScrollBarThickness       = 6
scroll.BorderSizePixel          = 0
scroll.Parent                   = panel

local layout                    = Instance.new("UIListLayout")
layout.Padding                  = UDim.new(0, 4)
layout.SortOrder                = Enum.SortOrder.LayoutOrder
layout.Parent                   = scroll

-- ─── Show results ─────────────────────────────────────────────────────────────
Remotes.ShowResults.OnClientEvent:Connect(function(results)
	screenGui.Enabled = true

	-- Clear old rows
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	-- MVP
	mvpLabel.Text = string.format("👑  MVP: %s", results.winner or "—")

	-- My stats
	local myStats = nil
	for _, s in ipairs(results.stats) do
		if s.name == localPlayer.Name then
			myStats = s
			break
		end
	end

	if myStats then
		placementLabel.Text = string.format("#%d", myStats.placement)
		killsLabel.Text     = string.format("💀 %d kills", myStats.kills)
		coinsLabel.Text     = string.format("🪙 +%d", myStats.coins)
		if myStats.placement == 1 then
			placementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		else
			placementLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	-- All-player rows
	for i, s in ipairs(results.stats) do
		local row                   = Instance.new("Frame")
		row.Size                    = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3        = s.name == localPlayer.Name
			and Color3.fromRGB(40, 60, 40)
			or  (i % 2 == 0 and Color3.fromRGB(22, 22, 38) or Color3.fromRGB(18, 18, 30))
		row.BorderSizePixel         = 0
		row.LayoutOrder             = i
		row.Parent                  = scroll
		local rowCorner             = Instance.new("UICorner")
		rowCorner.CornerRadius      = UDim.new(0, 6)
		rowCorner.Parent            = row

		local rankL                 = Instance.new("TextLabel")
		rankL.Size                  = UDim2.new(0, 36, 1, 0)
		rankL.Text                  = "#" .. i
		rankL.Font                  = Enum.Font.GothamBold
		rankL.TextSize              = 15
		rankL.TextColor3            = Color3.fromRGB(255, 215, 0)
		rankL.BackgroundTransparency = 1
		rankL.Parent                = row

		local nameL                 = Instance.new("TextLabel")
		nameL.Size                  = UDim2.new(0.45, -40, 1, 0)
		nameL.Position              = UDim2.new(0, 40, 0, 0)
		nameL.Text                  = s.name
		nameL.Font                  = Enum.Font.Gotham
		nameL.TextSize              = 14
		nameL.TextColor3            = Color3.fromRGB(220, 220, 255)
		nameL.BackgroundTransparency = 1
		nameL.TextXAlignment        = Enum.TextXAlignment.Left
		nameL.Parent                = row

		local killsL                = Instance.new("TextLabel")
		killsL.Size                 = UDim2.new(0.27, 0, 1, 0)
		killsL.Position             = UDim2.new(0.48, 0, 0, 0)
		killsL.Text                 = string.format("💀 %d", s.kills)
		killsL.Font                 = Enum.Font.Gotham
		killsL.TextSize             = 14
		killsL.TextColor3           = Color3.fromRGB(255, 120, 120)
		killsL.BackgroundTransparency = 1
		killsL.Parent               = row

		local coinsL                = Instance.new("TextLabel")
		coinsL.Size                 = UDim2.new(0.25, 0, 1, 0)
		coinsL.Position             = UDim2.new(0.75, 0, 0, 0)
		coinsL.Text                 = string.format("🪙 +%d", s.coins)
		coinsL.Font                 = Enum.Font.Gotham
		coinsL.TextSize             = 14
		coinsL.TextColor3           = Color3.fromRGB(255, 215, 0)
		coinsL.BackgroundTransparency = 1
		coinsL.Parent               = row
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, #results.stats * 40)

	-- Auto-hide after 10 seconds
	task.delay(10, function()
		screenGui.Enabled = false
	end)
end)

-- Also hide when a new round starts
Remotes.RoundStateChanged.OnClientEvent:Connect(function(state)
	if state == "Active" then
		screenGui.Enabled = false
	end
end)
