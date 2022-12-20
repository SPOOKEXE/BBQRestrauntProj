local Debris = game:GetService('Debris')

local Terrain = workspace.Terrain

local SoundFolderDescendantsCache = {} do
	local ReplicatedStorage = game:GetService('ReplicatedStorage')
	local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')
	for _, soundObject in ipairs( ReplicatedAssets:GetDescendants() ) do
		if soundObject:IsA('Sound') then
			SoundFolderDescendantsCache[soundObject.Name] = soundObject
		end
	end
end

-- // Module // --
local Module = {}

function Module:CreateSoundAtPosition(SoundInstance, WorldPosition)
	local Attach = Instance.new('Attachment')
	Attach.WorldPosition = WorldPosition
	Attach.Visible = true
	Attach.Parent = Terrain
	SoundInstance = SoundInstance:Clone()
	SoundInstance.Parent = Attach
	return SoundInstance, Attach
end

function Module:GetSoundFromValue(soundValue)
	if typeof(soundValue) == 'number' then
		soundValue = 'rbxassetid://'..soundValue
	end
	if typeof(soundValue) == 'string' then
		if string.find(soundValue, 'rbxassetid://') and (not SoundFolderDescendantsCache[soundValue]) then
			local newSoundInstance = Instance.new('Sound')
			newSoundInstance.SoundId = soundValue
			newSoundInstance.Parent = script
			SoundFolderDescendantsCache[soundValue] = newSoundInstance
			soundValue = newSoundInstance
		else
			soundValue = SoundFolderDescendantsCache[soundValue]
		end
	end
	if typeof(soundValue) == 'Instance' and soundValue:IsA('Sound') then
		return soundValue
	end
	return false
end

function Module:PlaySoundInParent(soundValue, Parent, Duration)
	soundValue = Module:GetSoundFromValue(soundValue)
	if not soundValue then
		return
	end
	soundValue = soundValue:Clone()
	soundValue.Parent = Parent
	if Duration then
		Debris:AddItem(soundValue, Duration)
	end
	soundValue:Play()
	return soundValue
end

function Module:PlaySoundAtPosition(soundValue, Position, Duration)
	soundValue = Module:GetSoundFromValue(soundValue)
	if not soundValue then
		return
	end
	local SoundObj, Att = Module:CreateSoundAtPosition(soundValue, Position)
	if Duration then
		Debris:AddItem(Att, Duration)
	end
	SoundObj:Play()
	return SoundObj, Att
end

return Module
