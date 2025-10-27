--------------------------------------------------------------------------------------------
--[[
 $$$$$$\  $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$\ $$\   $$\  $$$$$$\   $$$$$$\  
$$  __$$\ $$  _____|\__$$  __|\__$$  __|\_$$  _|$$$\  $$ |$$  __$$\ $$  __$$\ 
$$ /  \__|$$ |         $$ |      $$ |     $$ |  $$$$\ $$ |$$ /  \__|$$ /  \__|
\$$$$$$\  $$$$$\       $$ |      $$ |     $$ |  $$ $$\$$ |$$ |$$$$\ \$$$$$$\  
 \____$$\ $$  __|      $$ |      $$ |     $$ |  $$ \$$$$ |$$ |\_$$ | \____$$\ 
$$\   $$ |$$ |         $$ |      $$ |     $$ |  $$ |\$$$ |$$ |  $$ |$$\   $$ |
\$$$$$$  |$$$$$$$$\    $$ |      $$ |   $$$$$$\ $$ | \$$ |\$$$$$$  |\$$$$$$  |
 \______/ \________|   \__|      \__|   \______|\__|  \__| \______/  \______/                                                                                                                                                                                                                                    
]]
--------------------------------------------------------------------------------------------

-- Hub Settings
local HubName = "Lumahub"
local HubAuthor = "Takeables"

-- Notification Settings
local NotificationDuration = 5
local NotificationIcon = "bell-ring"

-- Farming Settings
local NearbyRadius = 50

--------------------------------------------------------------------------------------------
--[[
$$\    $$\  $$$$$$\  $$$$$$$\  $$$$$$\  $$$$$$\  $$$$$$$\  $$\       $$$$$$$$\  $$$$$$\  
$$ |   $$ |$$  __$$\ $$  __$$\ \_$$  _|$$  __$$\ $$  __$$\ $$ |      $$  _____|$$  __$$\ 
$$ |   $$ |$$ /  $$ |$$ |  $$ |  $$ |  $$ /  $$ |$$ |  $$ |$$ |      $$ |      $$ /  \__|
\$$\  $$  |$$$$$$$$ |$$$$$$$  |  $$ |  $$$$$$$$ |$$$$$$$\ |$$ |      $$$$$\    \$$$$$$\  
 \$$\$$  / $$  __$$ |$$  __$$<   $$ |  $$  __$$ |$$  __$$\ $$ |      $$  __|    \____$$\ 
  \$$$  /  $$ |  $$ |$$ |  $$ |  $$ |  $$ |  $$ |$$ |  $$ |$$ |      $$ |      $$\   $$ |
   \$  /   $$ |  $$ |$$ |  $$ |$$$$$$\ $$ |  $$ |$$$$$$$  |$$$$$$$$\ $$$$$$$$\ \$$$$$$  |
    \_/    \__|  \__|\__|  \__|\______|\__|  \__|\_______/ \________|\________| \______/                                                                                                                                                                                                                                                                           
]]
--------------------------------------------------------------------------------------------

-- Frameworks
local UI_Framework =
	loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Config_Framework

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Private Values
local AutoFarmEnabled
local IsAutoFarming = false

-- Instance References
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

--------------------------------------------------------------------------------------------
--[[
$$$$$$$$\ $$\   $$\ $$\   $$\  $$$$$$\ $$$$$$$$\ $$$$$$\  $$$$$$\  $$\   $$\  $$$$$$\  
$$  _____|$$ |  $$ |$$$\  $$ |$$  __$$\\__$$  __|\_$$  _|$$  __$$\ $$$\  $$ |$$  __$$\ 
$$ |      $$ |  $$ |$$$$\ $$ |$$ /  \__|  $$ |     $$ |  $$ /  $$ |$$$$\ $$ |$$ /  \__|
$$$$$\    $$ |  $$ |$$ $$\$$ |$$ |        $$ |     $$ |  $$ |  $$ |$$ $$\$$ |\$$$$$$\  
$$  __|   $$ |  $$ |$$ \$$$$ |$$ |        $$ |     $$ |  $$ |  $$ |$$ \$$$$ | \____$$\ 
$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$\   $$ |     $$ |  $$ |  $$ |$$ |\$$$ |$$\   $$ |
$$ |      \$$$$$$  |$$ | \$$ |\$$$$$$  |  $$ |   $$$$$$\  $$$$$$  |$$ | \$$ |\$$$$$$  |
\__|       \______/ \__|  \__| \______/   \__|   \______| \______/ \__|  \__| \______/                                                                                                                                                                                                                                                                                                                                             
]]
--------------------------------------------------------------------------------------------

local function Notify(Title, Content, Duration, Icon)
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

local function FindCoinContainer()
	for _, Object in pairs(game.Workspace:GetChildren()) do
		local CoinContainer = Object:FindFirstChild("CoinContainer")

		if CoinContainer then
			return CoinContainer
		end
	end

	return nil
end

local function FindNearestCoin(Radius)
	local CoinContainer = FindCoinContainer()

	if not CoinContainer then
		return nil
	end

	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local NearestCoin = nil
	local NearestDistance = Radius

	for _, Coin in pairs(CoinContainer:GetChildren()) do
		local Distance = (Coin.Position - HumanoidRootPart.Position).Magnitude

		if Distance < NearestDistance then
			NearestCoin = Coin
			NearestDistance = Distance
		end
	end

	return NearestCoin
end

local function TeleportToCoin(Coin)
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local TweenConfig = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local Tween = TweenService:Create(HumanoidRootPart, TweenConfig, { CFrame = Coin.CFrame })

	Tween:Play()
	return Tween
end

local function TeleportToNearbyOrRandomCoin()
	if not AutoFarmEnabled or IsAutoFarming then
		return
	end

	local NearbyCoin = FindNearestCoin(NearbyRadius)

	if NearbyCoin then
		IsAutoFarming = true
		local Tween = TeleportToCoin(NearbyCoin)
		Tween.Completed:Wait()
		IsAutoFarming = false
	else
		local CoinContainer = FindCoinContainer()

		if not CoinContainer then
			print("📝 CoinContainer Not Found")
			return
		end

		local Coins = CoinContainer:GetChildren()

		if #Coins == 0 then
			print("📝 No Coins Found")
			return
		end

		local RandomCoin = Coins[math.random(1, #Coins)]
		IsAutoFarming = true

		local Tween = TeleportToCoin(RandomCoin)
		Tween.Completed:Wait()
		IsAutoFarming = false
	end
end

--------------------------------------------------------------------------------------------
--[[
$$\      $$\  $$$$$$\  $$$$$$\ $$\   $$\ 
$$$\    $$$ |$$  __$$\ \_$$  _|$$$\  $$ |
$$$$\  $$$$ |$$ /  $$ |  $$ |  $$$$\ $$ |
$$\$$\$$ $$ |$$$$$$$$ |  $$ |  $$ $$\$$ |
$$ \$$$  $$ |$$  __$$ |  $$ |  $$ \$$$$ |
$$ |\$  /$$ |$$ |  $$ |  $$ |  $$ |\$$$ |
$$ | \_/ $$ |$$ |  $$ |$$$$$$\ $$ | \$$ |
\__|     \__|\__|  \__|\______|\__|  \__|                                                                                                                          
]]
--------------------------------------------------------------------------------------------

-- Lumahub UI
local Lumahub = UI_Framework:CreateWindow({
	Title = HubName,
	Author = ("Made by " .. HubAuthor),
	Icon = "geist:sparkles",
	Folder = HubName,
})

Config_Framework = Lumahub.ConfigManager
local Config = Config_Framework:CreateConfig(HubName)

---------------------------[[ FARMING ]]---------------------------
-- Farming Section
local FarmingSection = Lumahub:Tab({
	Title = "Farming",
	Locked = false,
})

-- Farming Toggle
local FarmingToggle = FarmingSection:Toggle({
	Title = "Candy Auto-Farm",
	Desc = "collect candy currency automatically.",
	Type = "Checkbox",
	Value = false,

	Callback = function(state)
		print("Farming Candy Activated" .. tostring(state))
		AutoFarmEnabled = state
		Config:Save()
	end,
})

Config:Register("CandyFarm", FarmingToggle)
FarmingSection:Select()

RunService.Heartbeat:Connect(function()
	if AutoFarmEnabled and Character and Character:FindFirstChild("HumanoidRootPart") then
		TeleportToNearbyOrRandomCoin()
	end
end)

---------------------------[[ NOTIFY ON LOAD ]]---------------------------

Config:Load()
Notify(HubName, "Successfully Loaded!", NotificationDuration, "badge-check")
