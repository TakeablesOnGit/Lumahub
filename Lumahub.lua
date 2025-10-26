--// Settings \\--

--|| Hub Settings ||--
local HubName = "Lumahub"
local HubAuthor = "Takeables"

--|| Notification Settings ||--
local NotificationDuration = 5
local NotificationIcon = "geist:verified-check-fill"

--// Frameworks \\--

local UI_Framework =
	loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// UI's <<--

local Lumahub = UI_Framework:CreateWindow({
	Title = HubName,
	Author = ("Made by " .. HubAuthor),
	Icon = "geist:sparkles",
	Folder = HubName,
})

--// Functions <<--

function Notify(Title, Content, Duration, Icon)
	if Title == nil then
		Title = "Notification"
	end

	if Content == nil then
		Content = "This is a notification."
	end

	if Duration == nil or Duration <= 0 then
		Duration = NotificationDuration
	end

	if Icon == nil then
		Icon = NotificationIcon
	end

	UI_Framework:Notify({
		Title = Title,
		Content = Content,
		Duration = Duration,
		Icon = Icon,
	})
end

---------------------------[[ FARMING ]]---------------------------

local FarmingSection = Lumahub:Tab({
	Title = "Farming",
	Locked = false,
})

local FarmingToggle = FarmingSection:Toggle({
	Title = "Farm Candy",
	Desc = "collect candy currency automatically.",
	Type = "Checkbox",
	Value = false,

	Callback = function(state)
		print("Farming Candy Activated" .. tostring(state))
	end,
})

--// Main \\--

FarmingSection:Select()
FarmingToggle:Set(false)

---------------------------[[ NOTIFY ON LOAD ]]---------------------------

Notify(HubName, "Successfully Loaded!", NotificationDuration, NotificationIcon)
