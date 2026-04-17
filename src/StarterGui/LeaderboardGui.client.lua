-- LeaderboardGui.client.lua
-- Custom leaderboard overlay toggled with the Tab key.
-- Shows top players by Kills, Coins Earned This Round, and Total Coins.
-- Also fetches global top players from the server.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Build ScreenGui ──────────────────────────────────────────────────────────
local screenGui             = Instance.new("ScreenGui")
screenGui.Name              = "LeaderboardGui"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Enabled           = false
screenGui.Parent            = playerGui

-- Panel
local panel                     = Instance.new("Frame")
panel.Size                      = UDim2.new(0, 560, 0, 460)
panel.Position                  = UDim2.new(0.5, -280, 0.5, -230)
panel.BackgroundColor3          = Color3.fromRGB(14, 14, 24)
panel.BackgroundTransparency    = 0.05
panel.BorderSizePixel           = 0
panel.Parent                    = screenGui

local panelCorner               = Instance.new("UICorner")
panelCorner.CornerRadius        = UDim.new(0, 14)
panelCorner.Parent              = panel

-- Title
local title                     = Instance.new("TextLabel")
title.Size                      = UDim2.new(1, -20, 0, 44)
title.Position                  = UDim2.new(0, 10, 0, 6)
title.Text                      = "📊  Leaderboard  (Tab to close)"
title.Font                      = Enum.Font.GothamBold
title.TextSize                  = 22
title.TextColor3                = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency    = 1
title.TextXAlignment            = Enum.TextXAlignment.Center
title.Parent                    = panel

-- Tabs
local tabBar                    = Instance.new("Frame")
tabBar.Size                     = UDim2.new(1, -20, 0, 32)
tabBar.Position                 = UDim2.new(0, 10, 0, 50)
tabBar.BackgroundTransparency   = 1
tabBar.Parent                   = panel

local tabNames = { "In-Round", "Global Wins", "Global Coins" }
local tabBtns  = {}

for i, name in ipairs(tabNames) do
	local btn                   = Instance.new("TextButton")
	btn.Size                    = UDim2.new(1 / #tabNames, -4, 1, 0)
	btn.Position                = UDim2.new((i - 1) / #tabNames, 2, 0, 0)
	btn.Text                    = name
	btn.Font                    = Enum.Font.Gotham
	btn.TextSize                = 14
	btn.TextColor3              = Color3.fromRGB(200, 200, 255)
	btn.BackgroundColor3        = Color3.fromRGB(28, 28, 44)
	btn.BorderSizePixel         = 0
	btn.Name                    = name
	btn.Parent                  = tabBar
	local c                     = Instance.new("UICorner")
	c.CornerRadius              = UDim.new(0, 6)
	c.Parent                    = btn
	tabBtns[name]               = btn
end

-- Scroll area
local scroll                    = Instance.new("ScrollingFrame")
scroll.Size                     = UDim2.new(1, -20, 1, -100)
scroll.Position                 = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency   = 1
scroll.ScrollBarThickness       = 6
scroll.BorderSizePixel          = 0
scroll.Parent                   = panel

local layout                    = Instance.new("UIListLayout")
layout.Padding                  = UDim.new(0, 4)
layout.SortOrder                = Enum.SortOrder.LayoutOrder
layout.Parent                   = scroll

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function clearScroll()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function addRow(rank, name, value, highlight)
	local row                   = Instance.new("Frame")
	row.Size                    = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3        = highlight
		and Color3.fromRGB(50, 80, 50)
		or  (rank % 2 == 0 and Color3.fromRGB(22, 22, 38) or Color3.fromRGB(18, 18, 30))
	row.BorderSizePixel         = 0
	row.LayoutOrder             = rank
	row.Parent                  = scroll
	local c                     = Instance.new("UICorner")
	c.CornerRadius              = UDim.new(0, 6)
	c.Parent                    = row

	local rankL                 = Instance.new("TextLabel")
	rankL.Size                  = UDim2.new(0, 40, 1, 0)
	rankL.Text                  = "#" .. rank
	rankL.Font                  = Enum.Font.GothamBold
	rankL.TextSize              = 16
	rankL.TextColor3            = Color3.fromRGB(255, 215, 0)
	rankL.BackgroundTransparency = 1
	rankL.Parent                = row

	local nameL                 = Instance.new("TextLabel")
	nameL.Size                  = UDim2.new(0.6, -50, 1, 0)
	nameL.Position              = UDim2.new(0, 50, 0, 0)
	nameL.Text                  = name
	nameL.Font                  = Enum.Font.Gotham
	nameL.TextSize              = 15
	nameL.TextColor3            = Color3.fromRGB(220, 220, 255)
	nameL.BackgroundTransparency = 1
	nameL.TextXAlignment        = Enum.TextXAlignment.Left
	nameL.Parent                = row

	local valL                  = Instance.new("TextLabel")
	valL.Size                   = UDim2.new(0.35, 0, 1, 0)
	valL.Position               = UDim2.new(0.65, 0, 0, 0)
	valL.Text                   = tostring(value)
	valL.Font                   = Enum.Font.GothamBold
	valL.TextSize               = 15
	valL.TextColor3             = Color3.fromRGB(180, 255, 180)
	valL.BackgroundTransparency = 1
	valL.TextXAlignment         = Enum.TextXAlignment.Right
	valL.Parent                 = row
end

-- ─── Tab content builders ─────────────────────────────────────────────────────
local function showInRound()
	clearScroll()
	-- Gather current players and their leaderstats kills
	local stats = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local kills = ls and ls:FindFirstChild("Kills")
		table.insert(stats, { name = p.Name, value = kills and kills.Value or 0 })
	end
	table.sort(stats, function(a, b) return a.value > b.value end)
	for i, s in ipairs(stats) do
		addRow(i, s.name, s.value .. " kills", s.name == localPlayer.Name)
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, #stats * 40)
end

local function showGlobal(boardType)
	clearScroll()
	local ok, data = pcall(function()
		return Remotes.RequestLeaderboard:InvokeServer(boardType)
	end)
	if ok and data then
		for i, entry in ipairs(data) do
			addRow(i, entry.name, entry.value, entry.name == localPlayer.Name)
		end
		scroll.CanvasSize = UDim2.new(0, 0, 0, #data * 40)
	else
		addRow(1, "Failed to load", "", false)
	end
end

-- ─── Tab clicks ───────────────────────────────────────────────────────────────
tabBtns["In-Round"].MouseButton1Click:Connect(function()
	for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(28, 28, 44) end
	tabBtns["In-Round"].BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	showInRound()
end)

tabBtns["Global Wins"].MouseButton1Click:Connect(function()
	for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(28, 28, 44) end
	tabBtns["Global Wins"].BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	showGlobal("Wins")
end)

tabBtns["Global Coins"].MouseButton1Click:Connect(function()
	for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(28, 28, 44) end
	tabBtns["Global Coins"].BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	showGlobal("Coins")
end)

-- ─── Toggle visibility (called by InputHandler) ───────────────────────────────
local function toggleLeaderboard()
	screenGui.Enabled = not screenGui.Enabled
	if screenGui.Enabled then
		-- Reset to In-Round tab
		for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(28, 28, 44) end
		tabBtns["In-Round"].BackgroundColor3 = Color3.fromRGB(40, 40, 70)
		showInRound()
	end
end

-- Expose via BindableFunction for InputHandler
local bf        = Instance.new("BindableFunction")
bf.Name         = "ToggleLeaderboard"
bf.Parent       = playerGui
bf.OnInvoke     = function()
	toggleLeaderboard()
end
