local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Signal = require(script.Signal)

local ActiveZoneClasses = {}

warn([[SPOOK_EXE's ZoneModule v1 has loaded.]])

-- // Class // --
local Class = {}
Class.__index = Class

function Class.New()
	local self = setmetatable({
		AllowUpdate = true,

		Active = true,
		Parts = {},
		PlayersWithinZone = {},
		CharactersWithinZone = {},
		Events = {
			PlayerEnter = Signal.new(),
			PlayerLeave = Signal.new(),
			CharacterEnter = Signal.new(),
			CharacterLeave = Signal.new(),
		},
	}, Class)

	table.insert(ActiveZoneClasses, self)

	return self
end

function Class:RemoveAllFromZones()
	-- fire zone leave signals
	for PlrInst, ZonePart in pairs(self.PlayersWithinZone) do
		self.Events.PlayerLeave:Fire(PlrInst, ZonePart)
	end
	for CharInst, ZonePart in pairs(self.CharactersWithinZone) do
		self.Events.CharacterLeave:Fire(CharInst, ZonePart)
	end
	-- clear the dictionary tables
	self.PlayersWithinZone = {}
	self.CharactersWithinZone = {}
	return self -- allows chaining
end

function Class:OnPlayerEnter(...)
	return self.Events.PlayerEnter:Connect(...)
end

function Class:OnPlayerLeave(...)
	return self.Events.PlayerLeave:Connect(...)
end

function Class:OnCharacterEnter(...)
	return self.Events.CharacterEnter:Connect(...)
end

function Class:OnCharacterLeave(...)
	return self.Events.CharacterLeave:Connect(...)
end

function Class:AddZoneParts(...)
	local usedIncorrectArguments = false
	for _, Object in ipairs( {...} ) do
		-- if its not an Instance, skip over it and prepare the warn message
		if typeof(Object) ~= 'Instance' then
			usedIncorrectArguments = true
			continue
		end
		-- if its a basepart, add it to the Parts table.
		if Object:IsA('BasePart') then
			if not table.find(self.Parts, Object) then
				table.insert(self.Parts, Object)
			end
		elseif Object:IsA('Folder') or Object:IsA('Model') then
			self:AddZoneParts(unpack(Object:GetChildren()))
		else
			usedIncorrectArguments = true
		end
	end

	if usedIncorrectArguments then -- do it here so it only warns once per call
		warn("You attempted to use an Instance other than a BasePart or Folder/Model in the AddZoneParts function.")
	end

	return self -- allows chaining
end

function Class:RemoveZoneParts(...)
	for _, Object in ipairs( {...} ) do
		if typeof(Object) == 'Instance' then
			local index = table.find(self.Parts, Object)
			if index then
				table.remove(self.Parts, index)
			end
		end
	end
	return self -- allows chaining
end

function Class:Destroy()
	if self.Destroyed then
		return
	end
	self.Active = false
	self.Destroyed = true
	self:RemoveAllFromZones()
	for _, signal in pairs(self.Events) do
		signal:Disconnect()
	end
end

local raycastPrms = RaycastParams.new()
raycastPrms.FilterType = Enum.RaycastFilterType.Whitelist
function Class:_IsInstanceWithinZone(Inst, overlapParams : OverlapParams?)

	debug.profilebegin('ZoneModule_ObjectArrayConversion')
	local ObjectsArray = {}
	if Inst:IsA('BasePart') then
		table.insert(ObjectsArray, Inst)
	elseif Inst:IsA('Model') or (Inst:IsA('Player') and Inst.Character) then
		if Inst:IsA('Player') then
			Inst = Inst.Character
		end
		for _, BasePart in ipairs( Inst:GetDescendants() ) do
			if BasePart:IsA('BasePart') then
				table.insert(ObjectsArray, BasePart)
			end
		end
	end
	debug.profileend()

	debug.profilebegin('O^2_InstanceFind')
	for _, ZonePart in ipairs( self.Parts ) do
		for _, CharacterPart in ipairs( ObjectsArray ) do
			if table.find( workspace:GetPartsInPart(ZonePart, overlapParams), CharacterPart ) then
				return ZonePart
			end
		end
	end
	debug.profileend()

	return false
end

function Class:_InternalZoneCheck(InstanceDictionary, RefTable, enterSignal, leaveSignal, overlapParams)
	debug.profilebegin('ZonesModule_InternalCheck')
	for _, RefInstance in ipairs( RefTable ) do
		local WithinZonePart = self:_IsInstanceWithinZone(RefInstance, overlapParams)
		if InstanceDictionary[RefInstance] and (not WithinZonePart) then
			local PreviousPart = InstanceDictionary[RefInstance]
			InstanceDictionary[RefInstance] = nil
			leaveSignal:Fire(RefInstance, PreviousPart)
		elseif (not InstanceDictionary[RefInstance]) and WithinZonePart then
			InstanceDictionary[RefInstance] = WithinZonePart
			enterSignal:Fire(RefInstance, WithinZonePart)
		end
	end
	debug.profileend()

	return self -- allows chaining
end

function Class:_Update(PlayerArray, CharacterArray)
	-- if there is no active parts
	if #self.Parts == 0 then
		-- if it was previously active
		if self.Active then
			-- deactive it
			self.Active = false
			self:RemoveAllFromZones()
		end
		return self -- allows chaining
	end

	-- there are parts in the zone
	self.Active = true

	if self.AllowUpdate then
		self:_InternalZoneCheck(self.CharactersWithinZone, CharacterArray, self.Events.CharacterEnter, self.Events.CharacterLeave, nil)
		self:_InternalZoneCheck(self.PlayersWithinZone, PlayerArray, self.Events.PlayerEnter, self.Events.PlayerLeave, nil)
	end

	return self -- allows chaining
end

function Class:StartLocal()
	self.AllowUpdate = true
end

function Class:StopLocal()
	self.AllowUpdate = false
end

function Class:StartGlobal()
	if Class.Heartbeat then
		return self -- allows chaining
	end

	Class.Heartbeat = RunService.Heartbeat:Connect(function()
		debug.profilebegin('ZoneModule_GetInstances')
		local PlayerArray = Players:GetPlayers()

		local CharacterArray = {}
		for _, Model in ipairs( workspace:GetChildren() ) do
			if Model:FindFirstChildWhichIsA('Humanoid') and (not Players:FindFirstChild(Model.Name)) then
				table.insert(CharacterArray, Model)
			end
		end
		debug.profileend()

		debug.profilebegin('ZoneModule_UpdateClasses')
		for _, activeClass in ipairs( ActiveZoneClasses ) do
			activeClass:_Update(PlayerArray, CharacterArray)
		end
		debug.profileend()
	end)

	return self -- allows chaining
end

function Class:StopGlobal()
	if Class.Heartbeat then
		Class.Heartbeat:Disconnect()
		Class.Heartbeat = nil
	end
end

Class:StartGlobal() -- globally enable by default

return Class