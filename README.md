# Tornado Tag 🌪️🔫

A fully functional Roblox game combining **tornado survival** mechanics with **laser tag** combat. Built with [Rojo](https://rojo.space/) — sync the source tree directly into Roblox Studio.

---

## Table of Contents
1. [Game Overview](#game-overview)
2. [Project Structure](#project-structure)
3. [Setup & Installation](#setup--installation)
4. [Configuring Developer Product IDs](#configuring-developer-product-ids)
5. [Gameplay Guide](#gameplay-guide)
6. [Difficulty Levels](#difficulty-levels)
7. [Coin Shop](#coin-shop)
8. [Robux Shop](#robux-shop)
9. [Leaderboard & Rewards](#leaderboard--rewards)
10. [Keyboard Shortcuts](#keyboard-shortcuts)
11. [Technical Notes](#technical-notes)

---

## Game Overview

**Tornado Tag** drops players into an arena where:

- Tornados spawn and roam the map, pulling players in and dealing damage.
- Players carry a **Laser Gun** and must eliminate opponents.
- Coins are earned for surviving, getting kills, and winning rounds.
- Coins can be spent in the shop for temporary and permanent upgrades.
- Robux purchases provide strong boosts for committed players.

A round lasts **3 minutes**. The last player standing (or the player with the most kills when time expires) wins. Between rounds there is a **30-second intermission** where players vote on the next difficulty.

---

## Project Structure

```
tornado-Tag/
├── default.project.json              # Rojo project configuration
├── .gitignore
├── README.md
└── src/
    ├── ServerScriptService/
    │   ├── RoundManager.server.lua       # Round cycle, coin awards, winner detection
    │   ├── TornadoController.server.lua  # Tornado spawning, movement, damage, pull
    │   ├── ShopHandler.server.lua        # Coin shop + Robux product processing
    │   ├── LeaderboardService.server.lua # OrderedDataStore global leaderboards
    │   └── DailyRewards.server.lua       # Daily login coin bonus
    ├── ServerStorage/
    │   └── LaserGun/
    │       ├── init.lua                  # Tool descriptor
    │       ├── LaserGunServer.server.lua # Raycast validation & damage (server)
    │       └── LaserGunClient.client.lua # Input, beam rendering, hit marker (client)
    ├── ReplicatedStorage/
    │   ├── GameConfig.lua                # All tunable constants & item definitions
    │   ├── DataManager.lua               # DataStoreService save/load/auto-save
    │   └── Remotes.lua                   # RemoteEvent / RemoteFunction creation
    ├── StarterGui/
    │   ├── MainHUD.client.lua            # Health bar, coins, timer, kills, kill feed
    │   ├── ShopGui.client.lua            # Tabbed shop (Coins / Robux)
    │   ├── DifficultySelectGui.client.lua# Intermission difficulty vote screen
    │   ├── LeaderboardGui.client.lua     # Custom leaderboard overlay (Tab key)
    │   └── ResultsScreen.client.lua      # End-of-round results overlay
    └── StarterPlayerScripts/
        └── InputHandler.client.lua       # Tab / B key bindings
```

---

## Setup & Installation

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Rojo](https://rojo.space/) | ≥ 7.x | Sync Luau source into Roblox Studio |
| [Roblox Studio](https://www.roblox.com/create) | Latest | Game editor |
| Rojo Studio Plugin | Latest | Receives the Rojo sync |

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/baart22-oss/tornado-Tag.git
   cd tornado-Tag
   ```

2. **Install Rojo** (if not already installed)
   ```bash
   # Using Aftman (recommended)
   aftman install
   # Or via Foreman / direct binary from https://github.com/rojo-rbx/rojo/releases
   ```

3. **Start the Rojo dev server**
   ```bash
   rojo serve default.project.json
   ```

4. **Connect in Roblox Studio**
   - Open Roblox Studio and create a new place (or open your existing place).
   - Click the **Rojo** plugin button and press **Connect**.
   - Studio will sync all scripts into the correct services.

5. **Add a map / baseplate**
   - Tornado Tag needs a flat arena of roughly **800×800 studs**.
   - Set the arena bounds in `TornadoController.server.lua`:
     ```lua
     local ARENA_SIZE   = 400  -- half-extent (studs from centre)
     local ARENA_HEIGHT = 5    -- Y level tornados travel at
     ```
   - Optionally, add a `Part` named **LeaderboardBoard** with a `SurfaceGui` face set to **Front** — the server will auto-populate it with top players.

6. **Publish & play-test**
   - File → Publish to Roblox (or use `rojo build` for a `.rbxl` file).
   - Play-test in Studio or in a live server.

---

## Configuring Developer Product IDs

Before publishing, replace the placeholder `0` IDs in `src/ReplicatedStorage/GameConfig.lua`:

```lua
GameConfig.RobuxProducts = {
    {
        id        = "StarterPack",
        productId = 0,   -- ← Replace with your Developer Product ID
        ...
    },
    {
        id         = "VIPPass",
        gamePassId = 0,  -- ← Replace with your GamePass ID
        ...
    },
    ...
}
```

### How to get IDs

1. Go to [create.roblox.com](https://create.roblox.com/) → your experience → **Monetization**.
2. Create each **Developer Product** (one-time purchase) and note its numeric ID.
3. Create the **VIP Pass** as a **Game Pass** and note its numeric ID.
4. Paste the IDs into `GameConfig.lua` and re-sync.

---

## Gameplay Guide

### Round Flow

```
Intermission (30s)  →  Active Round (3 min)  →  Results (10s)  →  repeat
```

- **Intermission**: Vote on difficulty. The winning vote sets the tornado parameters for the next round.
- **Active Round**: Tornados spawn incrementally. Use the Laser Gun to eliminate opponents. Survive to earn passive coin ticks.
- **Results**: See your placement, kills, coins earned, and the round MVP.

### Laser Gun

- **Left-click / tap** to fire.
- Fires a raycast beam up to **500 studs**.
- **Base damage**: 20 HP. **Headshot multiplier**: 1.5×.
- **Cooldown**: 0.35 seconds between shots.
- A red beam is rendered briefly on all clients.
- A hit marker flashes on the shooter's screen for confirmed hits (orange for headshots).

### Tornados

- Roam along semi-random paths within the arena.
- **Pull**: Players within ~30 studs of a tornado are pulled toward it.
- **Damage**: Contact deals damage every 0.5 s (amount depends on difficulty).
- **Shield** perk absorbs one tornado hit completely.

---

## Difficulty Levels

| Difficulty | Tornado Count | Speed | Damage/tick | Coin Multiplier |
|------------|:------------:|:-----:|:-----------:|:---------------:|
| Easy       | 1–2          | Slow  | 10 HP       | 1×              |
| Medium     | 3–4          | Medium| 20 HP       | 1.5×            |
| Hard       | 5–7          | Fast  | 35 HP       | 2×              |

Players vote during intermission; the most-voted option wins.

---

## Coin Shop

Open with the **B** key or the in-game button.

| Item | Cost | Effect |
|------|-----:|--------|
| Speed Boost | 200 🪙 | +20% WalkSpeed for 1 round |
| Shield | 500 🪙 | Absorb 1 tornado hit |
| Double Coins | 750 🪙 | 2× coin earn for 1 round |
| Laser Upgrade | 1,000 🪙 | +25% laser damage (permanent) |
| Tornado Radar | 1,500 🪙 | Mini-map blips showing tornado positions |

---

## Robux Shop

| Product | Price | Effect |
|---------|------:|--------|
| Starter Pack | R$99 | 500 coins + Speed Boost + Shield |
| VIP Pass | R$399 | Permanent 1.5× coin multiplier (Game Pass) |
| Mega Laser | R$199 | Permanent +50% laser damage |
| Coin Bundle (1K) | R$49 | 1,000 coins |
| Coin Bundle (5K) | R$199 | 5,000 coins |

> **Note**: Prices shown are placeholders. Set actual prices in the Roblox Creator Dashboard after configuring product IDs.

---

## Leaderboard & Rewards

### In-Game Leaderstats
Visible on the default Roblox leaderboard (top-right):
- **Kills** – total kills this session
- **Coins** – current coin balance
- **Wins** – total round wins

### Global Leaderboard
Powered by `OrderedDataStore`. Updated at the end of every round.
- Top 20 by **Wins**
- Top 20 by **Total Coins**

Access via the **Tab** overlay → "Global Wins" / "Global Coins" tabs.
Also displayed on the in-world `LeaderboardBoard` part (if placed in the map).

### Coin Rewards Per Round

| Action | Coins |
|--------|------:|
| Survive 30-second interval | +10 (× difficulty multiplier) |
| Eliminate a player | +25 (× difficulty multiplier) |
| Win the round | +100 (× difficulty multiplier) |

### Milestone Rewards (all-time wins)
| Wins | Bonus |
|-----:|------:|
| 10   | 500 🪙 |
| 50   | 2,500 🪙 |
| 100  | 10,000 🪙 |

### Daily Login Reward
**+50 coins** once every calendar day (UTC). Claimed automatically on join.

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Tab** | Toggle custom Leaderboard overlay |
| **B** | Toggle Shop |
| **Left-click** | Fire laser gun (when equipped) |

---

## Technical Notes

- All scripts are written in **Luau** (Roblox Lua).
- DataStore calls are wrapped in `pcall` for error handling.
- Modern task library (`task.spawn`, `task.wait`, `task.delay`) used throughout — no deprecated `wait()` or `spawn()`.
- Coin/DataStore data is auto-saved every **60 seconds** and on `PlayerRemoving`.
- The `ProcessReceipt` callback grants purchases reliably; if a player leaves mid-purchase the receipt is retried on next join by Roblox.
- All client↔server communication flows through `RemoteEvent` / `RemoteFunction` objects created by `Remotes.lua` in `ReplicatedStorage`.

---

## License

MIT — feel free to fork and adapt for your own Roblox experiences.