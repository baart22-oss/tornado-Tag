-- DifficultySelectGui.client.lua
-- Displays during Intermission so players can vote on the next round's difficulty.
-- Hides once the Active round begins.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Build ScreenGui ──────────────────────────────────────────────────────────
local screenGui          = Instance.new("ScreenGui")
screenGui.Name           = "DifficultySelectGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled        = false
screenGui.Parent         = playerGui

-- Semi-transparent backdrop
local backdrop                  = Instance.new("Frame")
backdrop.Size                   = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.55
backdrop.BorderSizePixel        = 0
backdrop.Parent                 = screenGui

-- Central panel
local panel                     = Instance.new("Frame")
panel.Size                      = UDim2.new(0, 520, 0, 360)
panel.Position                  = UDim2.new(0.5, -260, 0.5, -180)
panel.BackgroundColor3          = Color3.fromRGB(18, 18, 30)
panel.BackgroundTransparency    = 0.05
panel.BorderSizePixel           = 0
panel.Parent                    = screenGui

local panelCorner               = Instance.new("UICorner")
panelCorner.CornerRadius        = UDim.new(0, 16)
panelCorner.Parent              = panel

-- Title
local title                     = Instance.new("TextLabel")
title.Size                      = UDim2.new(1, 0, 0, 50)
title.Position                  = UDim2.new(0, 0, 0, 0)
title.Text                      = "🌪  Choose Difficulty"
title.Font                      = Enum.Font.GothamBold
title.TextSize                  = 26
title.TextColor3                = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency    = 1
title.Parent                    = panel

local subtitle                  = Instance.new("TextLabel")
subtitle.Size                   = UDim2.new(1, 0, 0, 24)
subtitle.Position               = UDim2.new(0, 0, 0, 46)
subtitle.Text                   = "Most votes wins. Round starts when timer reaches 0."
subtitle.Font                   = Enum.Font.Gotham
subtitle.TextSize               = 14
subtitle.TextColor3             = Color3.fromRGB(180, 180, 200)
subtitle.BackgroundTransparency = 1
subtitle.Parent                 = panel

-- ─── Difficulty buttons ───────────────────────────────────────────────────────
local difficulties = { "Easy", "Medium", "Hard" }
local buttons      = {}
local selectedDiff = nil

for i, diff in ipairs(difficulties) do
	local cfg    = GameConfig.Difficulties[diff]
	local xOff   = (i - 1) * 168 + 16

	local card                      = Instance.new("Frame")
	card.Name                       = diff
	card.Size                       = UDim2.new(0, 152, 0, 200)
	card.Position                   = UDim2.new(0, xOff, 0, 80)
	card.BackgroundColor3           = Color3.fromRGB(28, 28, 44)
	card.BorderSizePixel            = 0
	card.Parent                     = panel

	local cardCorner                = Instance.new("UICorner")
	cardCorner.CornerRadius         = UDim.new(0, 12)
	cardCorner.Parent               = card

	-- Coloured top stripe
	local stripe                    = Instance.new("Frame")
	stripe.Size                     = UDim2.new(1, 0, 0, 8)
	stripe.BackgroundColor3         = cfg.color
	stripe.BorderSizePixel          = 0
	stripe.Parent                   = card
	local stripeCorner              = Instance.new("UICorner")
	stripeCorner.CornerRadius       = UDim.new(0, 12)
	stripeCorner.Parent             = stripe

	local nameLabel                 = Instance.new("TextLabel")
	nameLabel.Size                  = UDim2.new(1, 0, 0, 36)
	nameLabel.Position              = UDim2.new(0, 0, 0, 14)
	nameLabel.Text                  = cfg.label
	nameLabel.Font                  = Enum.Font.GothamBold
	nameLabel.TextSize              = 22
	nameLabel.TextColor3            = cfg.color
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent                = card

	local descLabel                 = Instance.new("TextLabel")
	descLabel.Size                  = UDim2.new(1, -16, 0, 60)
	descLabel.Position              = UDim2.new(0, 8, 0, 52)
	descLabel.Text                  = cfg.description
	descLabel.Font                  = Enum.Font.Gotham
	descLabel.TextSize              = 13
	descLabel.TextColor3            = Color3.fromRGB(200, 200, 220)
	descLabel.BackgroundTransparency = 1
	descLabel.TextWrapped           = true
	descLabel.Parent                = card

	-- Stats
	local statsText = string.format(
		"Tornados: %d–%d\nDamage: %d/tick\nCoins: %g×",
		cfg.tornadoCountMin, cfg.tornadoCountMax,
		cfg.tornadoDamage,
		cfg.coinMultiplier
	)
	local statsLabel                = Instance.new("TextLabel")
	statsLabel.Size                 = UDim2.new(1, -16, 0, 60)
	statsLabel.Position             = UDim2.new(0, 8, 0, 116)
	statsLabel.Text                 = statsText
	statsLabel.Font                 = Enum.Font.Gotham
	statsLabel.TextSize             = 12
	statsLabel.TextColor3           = Color3.fromRGB(160, 160, 180)
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextWrapped          = true
	statsLabel.Parent               = card

	-- Vote button
	local btn                       = Instance.new("TextButton")
	btn.Name                        = "VoteBtn"
	btn.Size                        = UDim2.new(1, -16, 0, 32)
	btn.Position                    = UDim2.new(0, 8, 1, -40)
	btn.BackgroundColor3            = cfg.color
	btn.Text                        = "Vote"
	btn.Font                        = Enum.Font.GothamBold
	btn.TextSize                    = 16
	btn.TextColor3                  = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel             = 0
	btn.Parent                      = card

	local btnCorner                 = Instance.new("UICorner")
	btnCorner.CornerRadius          = UDim.new(0, 8)
	btnCorner.Parent                = btn

	buttons[diff] = { card = card, btn = btn }

	btn.MouseButton1Click:Connect(function()
		-- Deselect all
		for _, d in ipairs(difficulties) do
			if buttons[d] then
				buttons[d].card.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
				buttons[d].btn.Text = "Vote"
			end
		end
		-- Select this one
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
		btn.Text = "✔ Voted"
		selectedDiff = diff
		Remotes.SelectDifficulty:FireServer(diff)
	end)
end

-- ─── Timer countdown label ────────────────────────────────────────────────────
local timerLabel                    = Instance.new("TextLabel")
timerLabel.Size                     = UDim2.new(1, 0, 0, 36)
timerLabel.Position                 = UDim2.new(0, 0, 1, -44)
timerLabel.Text                     = "Round starts in: --"
timerLabel.Font                     = Enum.Font.GothamBold
timerLabel.TextSize                 = 18
timerLabel.TextColor3               = Color3.fromRGB(200, 200, 255)
timerLabel.BackgroundTransparency   = 1
timerLabel.Parent                   = panel

-- ─── Show/hide based on round state ──────────────────────────────────────────
local countdown   = 0
local ticking     = false

Remotes.RoundStateChanged.OnClientEvent:Connect(function(state, duration)
	if state == "Intermission" then
		screenGui.Enabled = true
		countdown         = duration
		ticking           = true
		-- Reset vote UI
		for _, d in ipairs(difficulties) do
			if buttons[d] then
				buttons[d].card.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
				buttons[d].btn.Text = "Vote"
			end
		end
		selectedDiff = nil
	elseif state == "Active" or state == "Results" then
		screenGui.Enabled = false
		ticking           = false
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if ticking and countdown > 0 then
			countdown = countdown - 1
			timerLabel.Text = string.format("Round starts in: %ds", countdown)
		end
	end
end)
