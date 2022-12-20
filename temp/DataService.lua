local Players = game:GetService('Players')

local ServerStorage = game:GetService('ServerStorage')
local ServerModules = require(ServerStorage:WaitForChild("Modules"))

-- local DebugServiceModule = ServerModules.Services.DebugService

-- local ReplicatedStorage = game:GetService('ReplicatedStorage')
-- local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local ProfileService = ServerModules.Services.ProfileService

local CurrentDataVersion = 1 -- change this and create a reconcile function if format of data is changed
local DataStoreName = 'PlayerData1' -- change this to wipe data

local SystemsContainer = {}

local GameProfileStore = ProfileService.GetProfileStore(DataStoreName, {
	Version = CurrentDataVersion, -- data version
	Banned = false, -- banned

	Saves = {}, -- saves the player saves
	DeletedSaves = {},

	Tags = {}, -- Tags under the profile
	PurchaseHistory = {}, -- DevProducts under all saves
}).Mock

local ProfileCache = {}
local Loading = {}

-- // Module // --
local Module = {}

-- Get player key from userid
function Module:GetPlayerKey(UserId)
	return tostring(UserId)
end

-- Wipes a player's progress
function Module:WipeUserIdProgress(UserId)
	GameProfileStore:WipeProfileAsync(Module:GetPlayerKey(UserId))
end

--[[
	Write additional custom data to the player's data when they join the game.
	Can be used for a variety of hard-coded purposes.
]]
function Module:CustomPlayerDataWrite(LocalPlayer, Profile)
	local reconcileSucceeded, err = SystemsContainer.DataReconcile:CheckReconcileStatus(Profile, CurrentDataVersion)
	if not reconcileSucceeded then
		-- DebugServiceModule:ErrorAtLevel(1, false, LocalPlayer.Name..' Data Reconcile Failed! ' .. tostring(err))
		LocalPlayer:Kick('Data Reconcile Failed! ' .. tostring(err))
	end
end

--[[
	Get the player's data profile gien the player Instance.
	Optionally the function can be yielded until the data exists.
]]
function Module:GetProfileFromPlayer(LocalPlayer, Yield)
	if Yield then
		local startTick = time()
		while (time() - startTick < 10) and LocalPlayer:IsDescendantOf(Players) do
			if ProfileCache[LocalPlayer.UserId] then
				return ProfileCache[LocalPlayer.UserId]
			end
			task.wait(0.1)
		end
		-- DebugServiceModule:WarnAtLevel(2, true, 'GetProfileFromPlayer yielded for more than 10 seconds: ', LocalPlayer.Name, debug.traceback())
	end
	return ProfileCache[LocalPlayer.UserId]
end

--[[
	Load the player's data profile given the player UserId.
	Has extra features like load-locking (only allowing one thread to load it at a time)
]]
function Module:LoadProfileDataFromUserId(UserId)
	if Loading[UserId] then
		repeat task.wait(0.1)
		until not Loading[UserId]
	end
	if ProfileCache[UserId] then
		return ProfileCache[UserId]
	end
	Loading[UserId] = true
	local profile = GameProfileStore:LoadProfileAsync(tonumber(UserId) and Module:GetPlayerKey(UserId) or UserId, "ForceLoad")
	ProfileCache[UserId] = profile
	Loading[UserId] = nil
	return profile
end

--[[
	Given the user id, load their profile, reconcile it, and do nothing else with it.
]]
function Module:LoadUserIdProfile(UserId)
	local profile = Module:LoadProfileDataFromUserId(UserId)
	if profile then
		profile:Reconcile()
		profile:AddUserId(UserId)
		profile:ListenToRelease(function()
			ProfileCache[UserId] = nil
		end)
		local couldReconcile = SystemsContainer.DataReconcile:CheckReconcileStatus(UserId, profile, CurrentDataVersion)
		if not couldReconcile then
			profile:Release()
			return false
		end
		ProfileCache[UserId] = profile
		return profile
	end
	return nil
end

--[[
	Given a player instance, load their data for the purpose of writing/editing it.
]]
function Module:LoadPlayerProfile(LocalPlayer)
	local profile = Module:LoadProfileDataFromUserId(LocalPlayer.UserId)
	if profile then
		profile:ListenToRelease(function()
			ProfileCache[LocalPlayer.UserId] = nil
			if not profile.Data.Banned then
				LocalPlayer:Kick('Profile loaded on a different server.')
			end
		end)
		if LocalPlayer:IsDescendantOf(Players) then
			Module:CustomPlayerDataWrite(LocalPlayer, profile)
			local IsBanned = SystemsContainer.BanService:CheckProfileBanExpired(LocalPlayer, profile)
			if IsBanned then
				profile:Release()
				local BanMessage = SystemsContainer.BanService:CompileBanMessage(profile.Data.Banned)
				if LocalPlayer:IsDescendantOf(Players) then
					LocalPlayer:Kick(BanMessage)
				end
				return false
			end
			ProfileCache[LocalPlayer.UserId] = profile
		else
			profile:Release()
			ProfileCache[LocalPlayer.UserId] = nil
		end
	end
	return profile
end

function Module:OnPlayerAdded(LocalPlayer)
	if ProfileCache[LocalPlayer] then
		return
	end
	local playerProfile = Module:LoadPlayerProfile(LocalPlayer)
	if not playerProfile then
		warn('PlayerData did not load: ', LocalPlayer.Name)
		return
	end
	-- ReplicatedData:SetData('PlayerProfileData', playerProfile.Data, {LocalPlayer})
	return playerProfile
end

function Module:Init( otherSystems )
	SystemsContainer = otherSystems

	-- if SystemsContainer.SoftShutdown:IsShutdownServer() then
	-- 	return false
	-- end

	Players.PlayerRemoving:Connect(function(LocalPlayer)
		local Profile = ProfileCache[LocalPlayer.UserId]
		if Profile then
			Profile:Release()
			ProfileCache[LocalPlayer.UserId] = nil
		end
	end)

	for _, LocalPlayer in ipairs(Players:GetPlayers()) do
		task.defer(function()
			Module:OnPlayerAdded(LocalPlayer)
		end)
	end

	Players.PlayerAdded:Connect(function(LocalPlayer)
		Module:OnPlayerAdded(LocalPlayer)
	end)
end

return Module
