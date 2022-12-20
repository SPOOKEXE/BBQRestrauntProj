
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local ClientSettingsModule = ReplicatedModules.Data.ClientSettings

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:EditClientConfig(LocalPlayer, category, configName, newConfigValue)
	local activeSaveData = SystemsContainer.SaveSelectionService:GetActiveSaveData(LocalPlayer)
	if not activeSaveData then
		return false, 'No Active Save Data'
	end

	local success, errMsg = ClientSettingsModule:ValidateConfigOption( category, configName, newConfigValue )
	if not success then
		return false, errMsg
	end

	activeSaveData.ClientSettings[category..'+'..configName] = newConfigValue

	return true, 'Successfully changed the config option.'
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
