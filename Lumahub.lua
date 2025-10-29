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
local MaxSafeSpeed = 15

-- Server Hop Settings
local GamesAPI = "https://games.roblox.com/v1/games/"
local GamePlace, GameID = game.PlaceId, game.JobId
local ServerList = GamesAPI .. GamePlace .. "/servers/Public?"
local DefaultServerHopWaitTime = 120

-- Auto Farm Settings
local MinInterval = 0.2

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

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Private Values
local AutoFarmEnabled = false
local ServerHopEnabled = false
local IsAutoFarming = false
local LastTweenTime = 0

-- Instance References
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Connections
local HeartbeatConnection
local ServerHopConnection

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

local function Destroy()
	AutoFarmEnabled = false
	IsAutoFarming = false

	if HeartbeatConnection then
		HeartbeatConnection:Disconnect()
		HeartbeatConnection = nil
	end
end

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

local function ListServers(cursor)
	local Raw = game:HttpGet(ServerList .. ((cursor and "&cursor=" .. Cursor) or ""))
	return Http:JSONDecode(Raw)
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

local function FindNearestCoin(Radius, OptionalSpeed)
	local CoinContainer = FindCoinContainer()

	if not CoinContainer then
		return nil
	end

	local Speed = OptionalSpeed or MaxSafeSpeed
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local NearestCoin = nil
	local TweenTime

	for _, Coin in pairs(CoinContainer:GetChildren()) do
		if NearestCoin ~= nil then
			return NearestCoin, TweenTime
		end

		if Coin:GetAttribute("Collected") == true then
			Coin:Destroy()
		else
			local Distance = (Coin.Position - HumanoidRootPart.Position).Magnitude

			TweenTime = math.clamp(Distance / Speed, 0.1, 3)

			if Distance < Radius then
				NearestCoin = Coin
			end
		end
	end

	return NearestCoin, TweenTime
end

local function TeleportToCoin(Coin, Speed)
	print("Tweening To Coin In Exactly " .. tostring(Speed) .. " Seconds")

	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local TweenConfig = TweenInfo.new(Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local Tween = TweenService:Create(HumanoidRootPart, TweenConfig, { CFrame = Coin.CFrame })

	Tween:Play()
	return Tween
end

local function TeleportToNearbyOrRandomCoin()
	if not AutoFarmEnabled or IsAutoFarming then
		return
	end

	local NearbyCoin, TweenTime = FindNearestCoin(NearbyRadius)

	if NearbyCoin then
		IsAutoFarming = true
		local Tween = TeleportToCoin(NearbyCoin, TweenTime)
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

		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		local RandomCoin = Coins[math.random(1, #Coins)]

		if RandomCoin:GetAttribute("Collected") == true then
			return
		end

		local Distance = (RandomCoin.Position - HumanoidRootPart.Position).Magnitude

		IsAutoFarming = true

		TweenTime = Distance / MaxSafeSpeed
		TweenTime = math.clamp(TweenTime, 0.1, 3)

		local Tween = TeleportToCoin(RandomCoin, TweenTime)
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

---------------------------[[ AUTO FARMING ]]---------------------------
-- Farming Section
local FarmingSection = Lumahub:Tab({
	Title = "Farming",
	Locked = false,
})

-- Farming Toggle
local FarmingToggle = FarmingSection:Toggle({
	Type = "Checkbox",
	Value = false,

	Callback = function(state)
		print("Farming Candy Activated: " .. tostring(state))
		AutoFarmEnabled = state

		if state == false then
			IsAutoFarming = false
		end
	end,
})

FarmingToggle:SetTitle("Candy Auto-Farm")
FarmingToggle:SetDesc("collect candy currency automatically.")

FarmingSection:Select()

HeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
	if
		AutoFarmEnabled
		and Character
		and Character:FindFirstChild("HumanoidRootPart")
		and tick() - LastTweenTime > MinInterval
	then
		LastTweenTime = tick()

		coroutine.wrap(function()
			TeleportToNearbyOrRandomCoin()
		end)()
	end
end)

---------------------------[[ SERVERS ]]---------------------------
-- Servers Section
local ServersSection = Lumahub:Tab({
	Title = "Servers",
	Locked = false,
})

-- Farming Toggle
local ServerHopToggle = ServersSection:Toggle({
	Type = "Checkbox",
	Value = false,

	Callback = function(state)
		ServerHopEnabled = state
	end,
})

ServerHopConnection = task.spawn(function()
	while true do
		if ServerHopEnabled then
			Player.Character.HumanoidRootPart.Anchored = true

			local Servers = ListServers()
			local Server = Servers.data[math.random(1, #Servers.data)]

			TeleportService:TeleportToPlaceInstance(GamePlace, Server.id, Player)
		end

		task.wait()
	end
end)
---------------------------[[ NOTIFY ON LOAD ]]---------------------------

Notify(HubName, "Successfully Loaded!", NotificationDuration, "badge-check")

---------------------------[[ CLEAN UP ]]---------------------------

Lumahub:OnDestroy(Destroy)
