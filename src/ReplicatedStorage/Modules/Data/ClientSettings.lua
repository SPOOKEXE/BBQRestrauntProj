-- TODO: IMPLEMENT THESE

local Module = {}

Module.DefaultSettings = {
	Interface = {
		Click_Sounds = true,
		VFX_Sounds = true,

		Notification_Sounds = true,
		Essential_Notifications_Only = true,

		Allow_Trading = true,
		Allow_Guild_Invites = true,
	},

	Gameplay = {
		VFX_Quality = { 1, 3, 1, 1 }, -- min, max, step, default (or highest if nil)
		VFX_Sound = true,

		Level_Up_Sound = true,
		Background_Music = true,

		Weather_Enabled = true,
		Weather_Sound = true,
	},

	Keybinds = { -- Enum.KeyCode.
		Settings_Widget = false,
		Cinematic_Mode = false, -- disables UI visibility for cinematography
		Attributes_Widget = false,
		Quest_Widget = false,
		Inventory_Widget = false,
		Dialogue_ContinueAccept = false,
		Dialogue_DenyCancel = false,

		-- Ability_1 = Enum.KeyCode.Z,
		-- Ability_2 = Enum.KeyCode.X,
		-- Ability_3 = Enum.KeyCode.C,
		-- Ability_4 = Enum.KeyCode.V,
	},
}

function Module:ValidateConfigOption( category, configName, newConfigValue )
	local categoryConfigData = category and Module.DefaultSettings[category]
	if (not categoryConfigData) then
		return false, 'Config category is invalid.'
	end

	local defaultConfigValue = categoryConfigData[configName]
	if not defaultConfigValue then
		return false, 'ConfigName is not a valid config under the category.'
	end

	if typeof(defaultConfigValue) == 'table' then
		-- custom checks
		if typeof(defaultConfigValue[1]) == 'number' and typeof(newConfigValue) == 'number' then
			local min, max, step, default = unpack(defaultConfigValue)
			default = (default or max)
			if newConfigValue < min or newConfigValue > max then
				return false, 'ConfigValue reaches out of set numerical bounds.'
			end
			if math.fmod( newConfigValue, step ) ~= 0 then
				return false, 'ConfigValue does not match the step amount.'
			end
			return true
		end
		return false, 'No bound check setup for values - report to developers.'
	elseif (typeof(defaultConfigValue) == typeof(newConfigValue)) or (typeof(newConfigValue) == 'nil') then
		return true
	end

	return false ,'Invalid ConfigValue Type.'
end

return Module

