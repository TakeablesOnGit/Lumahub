--// Settings \\--

local HubName = "Lumahub"
local HubAuthor = "Takeables"

--// Frameworks \\--

local UI_Framework =
	loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// UI's <<--

local Lumahub = UI_Framework:CreateWindow({
	Title = HubName,
	Author = "Made by " .. HubAuthor,
	Folder = HubName,
})

---------------------------[[ FARMING ]]---------------------------

local LumaFarmingTab = Lumahub:Tab({
	Title = "Farming",
	Locked = false,
})

local LumaFarmingToggle = LumaFarmingTab:Toggle({
	Title = "Farm Candy",
	Desc = "collect candy currency automatically.",
	Type = "Checkbox",
	Value = false,

	Callback = function(state)
		print("Farming Candy Activated" .. tostring(state))
	end,
})

--// Main \\--

LumaFarmingTab:Select()
LumaFarmingToggle:Set(false)
