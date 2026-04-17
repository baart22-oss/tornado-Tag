-- LaserGun/init.lua
-- Tool model descriptor for the LaserGun.
-- Rojo maps this folder to a Tool instance in ServerStorage.
-- The actual logic lives in LaserGunServer.server.lua (server) and
-- LaserGunClient.client.lua (client, cloned to StarterPack).

-- This script runs inside the Tool and exposes a "module-like" interface
-- so both the server and client scripts can share constants.

local LaserGun = {}

LaserGun.ToolName    = "LaserGun"
LaserGun.Grip        = CFrame.new(0, -1.5, 0) * CFrame.Angles(0, math.pi / 2, 0)

return LaserGun
