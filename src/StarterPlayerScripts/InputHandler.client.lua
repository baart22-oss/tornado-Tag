-- InputHandler.client.lua
-- Global keyboard shortcuts for the local player:
--   Tab  → toggle LeaderboardGui
--   B    → toggle ShopGui
--   E    → interact (reserved for future use)

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Helpers: invoke a BindableFunction by name in PlayerGui ─────────────────
local function invokeToggle(name)
	local bf = playerGui:FindFirstChild(name)
	if bf and bf:IsA("BindableFunction") then
		local ok, err = pcall(function() bf:Invoke() end)
		if not ok then
			warn("[InputHandler] Failed to invoke", name, ":", err)
		end
	end
end

-- ─── Key bindings ─────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end  -- ignore when typing in chat etc.

	if input.KeyCode == Enum.KeyCode.Tab then
		invokeToggle("ToggleLeaderboard")

	elseif input.KeyCode == Enum.KeyCode.B then
		invokeToggle("ToggleShop")
	end
end)
