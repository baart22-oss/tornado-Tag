-- GameConfig.lua
-- Shared configuration for Tornado Tag.
-- Accessible from both server and client via ReplicatedStorage.

local GameConfig = {}

-- ─── Round Timing ─────────────────────────────────────────────────────────────
GameConfig.INTERMISSION_DURATION  = 30   -- seconds between rounds
GameConfig.ROUND_DURATION         = 180  -- 3 minutes per round
GameConfig.SURVIVAL_INTERVAL      = 30   -- coins awarded every N seconds survived

-- ─── Coin Rewards ─────────────────────────────────────────────────────────────
GameConfig.COINS_SURVIVE_INTERVAL = 10   -- coins per survival interval
GameConfig.COINS_KILL             = 25   -- coins per elimination
GameConfig.COINS_WIN              = 100  -- coins for winning the round

-- ─── Difficulty Presets ───────────────────────────────────────────────────────
-- Each entry defines how tornados behave at that difficulty.
GameConfig.Difficulties = {
	Easy = {
		tornadoCountMin  = 1,
		tornadoCountMax  = 2,
		tornadoSpeed     = 12,   -- studs/s
		tornadoDamage    = 10,   -- HP per tick
		pullStrength     = 30,   -- force magnitude
		coinMultiplier   = 1,
		label            = "Easy",
		description      = "Fewer, slower tornados — great for beginners.",
		color            = Color3.fromRGB(100, 200, 100),
	},
	Medium = {
		tornadoCountMin  = 3,
		tornadoCountMax  = 4,
		tornadoSpeed     = 22,
		tornadoDamage    = 20,
		pullStrength     = 55,
		coinMultiplier   = 1.5,
		label            = "Medium",
		description      = "Balanced challenge with a better coin payout.",
		color            = Color3.fromRGB(255, 200, 50),
	},
	Hard = {
		tornadoCountMin  = 5,
		tornadoCountMax  = 7,
		tornadoSpeed     = 38,
		tornadoDamage    = 35,
		pullStrength     = 90,
		coinMultiplier   = 2,
		label            = "Hard",
		description      = "Chaos mode — high risk, double coin rewards.",
		color            = Color3.fromRGB(220, 60, 60),
	},
}

-- ─── Laser Gun ────────────────────────────────────────────────────────────────
GameConfig.LaserDamage         = 20    -- base damage per hit
GameConfig.HeadshotMultiplier  = 1.5   -- multiplier when hitting the head
GameConfig.LaserCooldown       = 0.35  -- seconds between shots
GameConfig.LaserRange          = 500   -- maximum raycast distance (studs)

-- ─── Shop – Coin Items ────────────────────────────────────────────────────────
GameConfig.ShopItems = {
	{
		id          = "SpeedBoost",
		name        = "Speed Boost",
		description = "+20% WalkSpeed for 1 round",
		cost        = 200,
		icon        = "🏃",
	},
	{
		id          = "Shield",
		name        = "Shield",
		description = "Absorb 1 tornado hit",
		cost        = 500,
		icon        = "🛡️",
	},
	{
		id          = "DoubleCoins",
		name        = "Double Coins",
		description = "2× coin earn for 1 round",
		cost        = 750,
		icon        = "💰",
	},
	{
		id          = "LaserUpgrade",
		name        = "Laser Upgrade",
		description = "+25% laser damage permanently",
		cost        = 1000,
		icon        = "🔫",
	},
	{
		id          = "TornadoRadar",
		name        = "Tornado Radar",
		description = "Mini-map blips showing tornados",
		cost        = 1500,
		icon        = "📡",
	},
}

-- ─── Shop – Robux Products ────────────────────────────────────────────────────
-- Replace the placeholder IDs with your actual Developer Product / GamePass IDs
-- from the Roblox Creator Dashboard before publishing.
GameConfig.RobuxProducts = {
	{
		id          = "StarterPack",
		name        = "Starter Pack",
		description = "500 coins + Speed Boost + Shield",
		robux       = 99,
		productId   = 0,   -- ← replace with real Developer Product ID
		icon        = "🎁",
	},
	{
		id          = "VIPPass",
		name        = "VIP Pass",
		description = "Permanent 1.5× coin multiplier",
		robux       = 399,
		gamePassId  = 0,   -- ← replace with real GamePass ID
		icon        = "⭐",
	},
	{
		id          = "MegaLaser",
		name        = "Mega Laser",
		description = "Permanent +50% laser damage",
		robux       = 199,
		productId   = 0,   -- ← replace with real Developer Product ID
		icon        = "⚡",
	},
	{
		id          = "CoinBundle1K",
		name        = "Coin Bundle (1K)",
		description = "1,000 coins",
		robux       = 49,
		productId   = 0,   -- ← replace with real Developer Product ID
		icon        = "🪙",
	},
	{
		id          = "CoinBundle5K",
		name        = "Coin Bundle (5K)",
		description = "5,000 coins",
		robux       = 199,
		productId   = 0,   -- ← replace with real Developer Product ID
		icon        = "💎",
	},
}

-- ─── Milestone Rewards ────────────────────────────────────────────────────────
GameConfig.MilestoneRewards = {
	[10]  = 500,
	[50]  = 2500,
	[100] = 10000,
}

-- ─── Daily Login Reward ───────────────────────────────────────────────────────
GameConfig.DailyLoginReward = 50  -- coins granted once per calendar day

-- ─── Persistent DataStore keys ────────────────────────────────────────────────
GameConfig.DataStoreKey     = "TornadoTag_v1"
GameConfig.GlobalWinsStore  = "TornadoTag_GlobalWins_v1"
GameConfig.GlobalCoinsStore = "TornadoTag_GlobalCoins_v1"

return GameConfig
