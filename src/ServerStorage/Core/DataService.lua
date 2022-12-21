local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local ActiveDataStore = false

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:OnPlayerAdded(LocalPlayer)
	local leaderstats = Instance.new('Folder')
	leaderstats.Name = 'leaderstats'
	leaderstats.Parent = LocalPlayer

	local timePlayed = Instance.new('IntValue')
	timePlayed.Name = 'Time Played'
	timePlayed.Parent = leaderstats

	local success, result = pcall(function()
		return ActiveDataStore:GetAsync(LocalPlayer.UserId)
	end)

	if not success then
		warn(result)
	else
		print(result)
		timePlayed.Value = result.TimePlayed
	end

	task.spawn(function()
		while true do
			task.wait(1)
			timePlayed.Value += 1
		end
	end)
end

function Module:OnPlayerLeaving(LocalPlayer)
	local leaderstatsFolder = LocalPlayer:FindFirstChild('leaderstats')
	if not leaderstatsFolder then
		return
	end

	local success, result = pcall(function()
		return ActiveDataStore:SetAsync(LocalPlayer.UserId, { TimePlayed = leaderstatsFolder['Time Played'].Value })
	end)

	if success then
		print(result)
		-- load data
	else
		warn(result)
	end
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		task.defer(function()
			Module:OnPlayerAdded(LocalPlayer)
		end)
	end

	Players.PlayerAdded:Connect(function(LocalPlayer)
		Module:OnPlayerAdded(LocalPlayer)
	end)

	Players.PlayerRemoving:Connect(function(LocalPlayer)
		Module:OnPlayerLeaving(LocalPlayer)
	end)

	local success, err = pcall(function()
		ActiveDataStore = DataStoreService:GetDataStore('PlayerData1')
	end)

	if not success then
		warn(err)
	end
end

return Module

