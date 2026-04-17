-- MainHUD.client.lua
-- Builds the main heads-up display:
--   • Health bar
--   • Coin counter
--   • Round timer
--   • Kill count
--   • Difficulty badge
--   • Kill feed
--   • Hit marker (used by LaserGunClient)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes    = require(ReplicatedStorage:WaitForChild("Remotes"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Create ScreenGui ─────────────────────────────────────────────────────────
local screenGui             = Instance.new("ScreenGui")
screenGui.Name              = "MainHUD"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Parent            = playerGui

-- ─── Helper: make a rounded frame ─────────────────────────────────────────────
local function makeFrame(parent, size, pos, bgColor, alpha)
	local f                 = Instance.new("Frame")
	f.Size                  = size
	f.Position              = pos
	f.BackgroundColor3      = bgColor or Color3.fromRGB(20, 20, 30)
	f.BackgroundTransparency = alpha or 0.35
	f.BorderSizePixel       = 0
	f.Parent                = parent
	local corner            = Instance.new("UICorner")
	corner.CornerRadius     = UDim.new(0, 8)
	corner.Parent           = f
	return f
end

local function makeLabel(parent, text, size, pos, font, textSize, color)
	local l             = Instance.new("TextLabel")
	l.Size              = size
	l.Position          = pos
	l.Text              = text
	l.Font              = font              or Enum.Font.GothamBold
	l.TextSize          = textSize          or 18
	l.TextColor3        = color             or Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 1
	l.TextXAlignment    = Enum.TextXAlignment.Left
	l.Parent            = parent
	return l
end

-- ─── Health Bar ───────────────────────────────────────────────────────────────
local healthFrame = makeFrame(screenGui,
	UDim2.new(0, 260, 0, 28),
	UDim2.new(0, 16, 1, -50)
)
local healthBg = makeFrame(healthFrame,
	UDim2.new(1, 0, 1, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(60, 20, 20), 0.1
)
local healthFill           = Instance.new("Frame")
healthFill.Name            = "HealthFill"
healthFill.Size            = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(70, 210, 70)
healthFill.BorderSizePixel = 0
healthFill.Parent          = healthBg
local healthCorner         = Instance.new("UICorner")
healthCorner.CornerRadius  = UDim.new(0, 8)
healthCorner.Parent        = healthFill

local healthLabel = makeLabel(healthFrame, "❤  100", UDim2.new(1, -10, 1, 0), UDim2.new(0, 8, 0, 0),
	Enum.Font.GothamBold, 14)
healthLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ─── Coin Counter ─────────────────────────────────────────────────────────────
local coinFrame  = makeFrame(screenGui,
	UDim2.new(0, 160, 0, 36),
	UDim2.new(0, 16, 0, 16)
)
local coinLabel  = makeLabel(coinFrame, "🪙  0", UDim2.new(1, -10, 1, 0), UDim2.new(0, 8, 0, 0),
	Enum.Font.GothamBold, 20, Color3.fromRGB(255, 215, 0))
coinLabel.Name   = "CoinLabel"
coinLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ─── Round Timer ──────────────────────────────────────────────────────────────
local timerFrame = makeFrame(screenGui,
	UDim2.new(0, 160, 0, 36),
	UDim2.new(0.5, -80, 0, 16)
)
local timerLabel = makeLabel(timerFrame, "⏱  --:--", UDim2.new(1, -10, 1, 0), UDim2.new(0, 8, 0, 0),
	Enum.Font.GothamBold, 20)
timerLabel.Name  = "TimerLabel"
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.Size  = UDim2.new(1, 0, 1, 0)

-- ─── Kill Count ───────────────────────────────────────────────────────────────
local killFrame  = makeFrame(screenGui,
	UDim2.new(0, 130, 0, 36),
	UDim2.new(1, -146, 0, 16)
)
local killLabel  = makeLabel(killFrame, "💀  0 Kills", UDim2.new(1, -10, 1, 0), UDim2.new(0, 8, 0, 0),
	Enum.Font.GothamBold, 18, Color3.fromRGB(255, 100, 100))
killLabel.Name   = "KillLabel"
killLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ─── Difficulty Badge ─────────────────────────────────────────────────────────
local diffFrame  = makeFrame(screenGui,
	UDim2.new(0, 110, 0, 30),
	UDim2.new(1, -126, 0, 60)
)
diffFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
local diffLabel  = makeLabel(diffFrame, "🌪  Medium", UDim2.new(1, -10, 1, 0), UDim2.new(0, 8, 0, 0),
	Enum.Font.Gotham, 14, Color3.fromRGB(255, 200, 50))
diffLabel.Name   = "DiffLabel"
diffLabel.TextXAlignment = Enum.TextXAlignment.Center
diffLabel.Size   = UDim2.new(1, 0, 1, 0)

-- ─── Kill Feed ────────────────────────────────────────────────────────────────
local killFeedFrame = makeFrame(screenGui,
	UDim2.new(0, 280, 0, 120),
	UDim2.new(1, -296, 0.5, -60),
	Color3.fromRGB(0, 0, 0), 0.7
)
killFeedFrame.Name = "KillFeed"

local killFeedLayout       = Instance.new("UIListLayout")
killFeedLayout.SortOrder   = Enum.SortOrder.LayoutOrder
killFeedLayout.Padding     = UDim.new(0, 4)
killFeedLayout.Parent      = killFeedFrame

local killFeedEntries = {}

local function addKillFeedEntry(killer, victim)
	local entry             = Instance.new("TextLabel")
	entry.Size              = UDim2.new(1, 0, 0, 22)
	entry.BackgroundTransparency = 1
	entry.Text              = string.format("💀 %s → %s", killer, victim)
	entry.Font              = Enum.Font.Gotham
	entry.TextSize          = 14
	entry.TextColor3        = Color3.fromRGB(240, 240, 240)
	entry.TextXAlignment    = Enum.TextXAlignment.Right
	entry.LayoutOrder       = #killFeedEntries + 1
	entry.Parent            = killFeedFrame

	table.insert(killFeedEntries, entry)

	-- Remove after 5 seconds
	task.delay(5, function()
		if entry and entry.Parent then
			entry:Destroy()
		end
	end)

	-- Keep only last 5 entries
	if #killFeedEntries > 5 then
		local old = table.remove(killFeedEntries, 1)
		if old and old.Parent then old:Destroy() end
	end
end

Remotes.KillFeedUpdate.OnClientEvent:Connect(addKillFeedEntry)

-- ─── Hit Marker ───────────────────────────────────────────────────────────────
local hitMarker         = Instance.new("ImageLabel")
hitMarker.Name          = "HitMarker"
hitMarker.Size          = UDim2.new(0, 48, 0, 48)
hitMarker.Position      = UDim2.new(0.5, -24, 0.5, -24)
hitMarker.BackgroundTransparency = 1
hitMarker.Image         = "rbxassetid://6031068420"  -- crosshair icon
hitMarker.ImageColor3   = Color3.fromRGB(255, 255, 255)
hitMarker.Visible       = false
hitMarker.Parent        = screenGui

-- ─── Health bar sync ──────────────────────────────────────────────────────────
local function connectHealthBar(character)
	local hum = character:WaitForChild("Humanoid", 5)
	if not hum then return end

	local function updateHealth()
		local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		healthFill.Size = UDim2.new(pct, 0, 1, 0)
		healthLabel.Text = string.format("❤  %d", math.ceil(hum.Health))
		-- Colour shift: green → yellow → red
		if pct > 0.5 then
			healthFill.BackgroundColor3 = Color3.fromRGB(70, 210, 70)
		elseif pct > 0.25 then
			healthFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
		else
			healthFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		end
	end

	hum.HealthChanged:Connect(updateHealth)
	updateHealth()
end

if localPlayer.Character then
	connectHealthBar(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(connectHealthBar)

-- ─── Kill count sync ──────────────────────────────────────────────────────────
local function syncKills()
	local ls = localPlayer:FindFirstChild("leaderstats")
	if not ls then return end
	local kills = ls:FindFirstChild("Kills")
	if kills then
		killLabel.Text = string.format("💀  %d Kill%s", kills.Value, kills.Value == 1 and "" or "s")
		kills.Changed:Connect(function(v)
			killLabel.Text = string.format("💀  %d Kill%s", v, v == 1 and "" or "s")
		end)
	end
end

task.spawn(function()
	task.wait(2)
	syncKills()
end)

-- ─── Coin display ─────────────────────────────────────────────────────────────
Remotes.UpdateCoins.OnClientEvent:Connect(function(amount)
	coinLabel.Text = string.format("🪙  %s", tostring(amount))
end)

-- ─── Round timer ──────────────────────────────────────────────────────────────
local timerRemaining = 0
local timerRunning   = false

Remotes.RoundStateChanged.OnClientEvent:Connect(function(state, duration, difficulty)
	if state == "Intermission" then
		timerLabel.Text        = string.format("⏳  Intermission: %ds", duration)
		timerLabel.TextColor3  = Color3.fromRGB(150, 200, 255)
		timerRunning           = false
		timerRemaining         = duration
	elseif state == "Active" then
		timerRemaining         = duration
		timerRunning           = true
		-- Update difficulty badge
		local cfg = GameConfig.Difficulties[difficulty]
		if cfg then
			diffFrame.BackgroundColor3 = cfg.color
			diffLabel.Text  = "🌪  " .. cfg.label
		end
	elseif state == "Results" then
		timerRunning           = false
		timerLabel.Text        = "🏆  Round Over!"
		timerLabel.TextColor3  = Color3.fromRGB(255, 215, 0)
	end
end)

-- Countdown tick
task.spawn(function()
	while true do
		task.wait(1)
		if timerRunning and timerRemaining > 0 then
			timerRemaining = timerRemaining - 1
			local mins = math.floor(timerRemaining / 60)
			local secs = timerRemaining % 60
			timerLabel.Text       = string.format("⏱  %02d:%02d", mins, secs)
			timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			if timerRemaining <= 30 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
		end
	end
end)
