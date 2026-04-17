-- Remotes.lua
-- Creates and returns all RemoteEvents and RemoteFunctions used for
-- client ↔ server communication.  Run once on the server at game start;
-- clients require this module to get references to the same objects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Helper: get-or-create a RemoteEvent inside a folder
local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local obj = Instance.new(className)
	obj.Name   = name
	obj.Parent = parent
	return obj
end

-- Ensure a "Remotes" folder exists in ReplicatedStorage
local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder        = Instance.new("Folder")
	folder.Name   = "Remotes"
	folder.Parent = ReplicatedStorage
end

-- ─── Round & State Events ─────────────────────────────────────────────────────
-- Fired server → all clients to update the round phase UI
Remotes.RoundStateChanged   = getOrCreate(folder, "RemoteEvent",    "RoundStateChanged")

-- Fired server → all clients with the current difficulty setting
Remotes.DifficultyChanged   = getOrCreate(folder, "RemoteEvent",    "DifficultyChanged")

-- Client → server: player has selected a difficulty (lobby vote)
Remotes.SelectDifficulty    = getOrCreate(folder, "RemoteEvent",    "SelectDifficulty")

-- ─── Combat Events ────────────────────────────────────────────────────────────
-- Client → server: player fired their laser gun
Remotes.LaserFired          = getOrCreate(folder, "RemoteEvent",    "LaserFired")

-- Server → all clients: render a laser beam effect
Remotes.ShowLaserBeam       = getOrCreate(folder, "RemoteEvent",    "ShowLaserBeam")

-- Server → shooter client: confirm a hit (for hit-marker UI)
Remotes.HitConfirmed        = getOrCreate(folder, "RemoteEvent",    "HitConfirmed")

-- ─── Shop Events ──────────────────────────────────────────────────────────────
-- Client → server: buy a coin-shop item
Remotes.BuyItem             = getOrCreate(folder, "RemoteEvent",    "BuyItem")

-- Server → client: purchase result (success / failure + reason)
Remotes.PurchaseResult      = getOrCreate(folder, "RemoteEvent",    "PurchaseResult")

-- ─── Coin / HUD Updates ───────────────────────────────────────────────────────
-- Server → specific client: update the coin display
Remotes.UpdateCoins         = getOrCreate(folder, "RemoteEvent",    "UpdateCoins")

-- Server → all clients: broadcast kill feed entry
Remotes.KillFeedUpdate      = getOrCreate(folder, "RemoteEvent",    "KillFeedUpdate")

-- ─── Results Screen ───────────────────────────────────────────────────────────
-- Server → all clients: show end-of-round results
Remotes.ShowResults         = getOrCreate(folder, "RemoteEvent",    "ShowResults")

-- ─── Leaderboard ──────────────────────────────────────────────────────────────
-- Client → server: request fresh global leaderboard data
Remotes.RequestLeaderboard  = getOrCreate(folder, "RemoteFunction", "RequestLeaderboard")

-- ─── Tornado Radar ────────────────────────────────────────────────────────────
-- Server → client (with TornadoRadar): send tornado positions for mini-map
Remotes.TornadoPositions    = getOrCreate(folder, "RemoteEvent",    "TornadoPositions")

return Remotes
