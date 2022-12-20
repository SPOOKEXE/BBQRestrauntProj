local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local DataRemoteEvent = ReplicatedModules.Services.RemoteService:GetRemote('DataRemote', 'RemoteEvent', false)

-- // Module // --
local Module = {}

if RunService:IsServer() then

	Module.Replications = { Private = {}, Public = {}, }

	-- localplayer is optional, if no local player then replicate to all.
	function Module:SetData( Category, Data, PlayerTable )
		if PlayerTable then
			-- private data for a select group of players
			table.insert(Module.Replications.Private, { Category, Data, PlayerTable })
		else
			-- public data
			Module.Replications.Public [ Category ] = Data
		end
	end

	function Module:RemoveData( Category )
		if Module.Replications.Public [ Category ] then
			Module.Replications.Public [ Category ] = nil
		end
		for index, replicationInfo in ipairs( Module.Replications.Private ) do
			if replicationInfo[1] == Category then
				table.remove(Module.Replications.Private, index)
			end
		end
	end
	
	function Module:UpdateData( category, data, playerTable )
		if playerTable then
			for _, LocalPlayer in ipairs( playerTable ) do
				DataRemoteEvent:FireClient(LocalPlayer, category, data)
			end
		else
			DataRemoteEvent:FireAllClients(category, data)
		end
	end
	
	function Module:TableToString(Tbl)
		local Str = ""
		for i, v in ipairs(Tbl) do
			Str = Str..tostring(i)..tostring(v)
		end
		return Str
	end
	
	DataRemoteEvent.OnServerEvent:Connect(function( LocalPlayer )
		for publicCategory, publicData in pairs( Module.Replications.Public ) do
			DataRemoteEvent:FireClient( LocalPlayer, publicCategory, publicData )
		end
		for _, replicationInfo in ipairs( Module.Replications.Private ) do
			local Category, Data, PlayerTable = unpack( replicationInfo )
			if table.find( PlayerTable, LocalPlayer ) then
				DataRemoteEvent:FireClient( LocalPlayer, Category, Data )
			end
		end
	end)
	
	task.spawn(function()
		local comparisonCache = { } -- [category] = cache_string
		while task.wait(0.2) do
			-- public data, replicates to all
			for publicCategory, publicData in pairs( Module.Replications.Public ) do
				local newEncodedString = HttpService:JSONEncode( publicData )
				if ( not comparisonCache[publicCategory] ) or comparisonCache[publicCategory] ~= newEncodedString then 
					-- update the data
					comparisonCache[publicCategory] = newEncodedString
					Module:UpdateData( publicCategory, publicData, nil )
				end
			end
			-- private data, replicates to specific
			for _, replicationInfo in ipairs( Module.Replications.Private ) do
				local Category, Data, PlayerTable = unpack( replicationInfo )
				local newEncodedString = HttpService:JSONEncode( Data )
				local idIndex = Category..(typeof(PlayerTable) == 'table' and Module:TableToString(PlayerTable) or PlayerTable)
				if ( not comparisonCache[idIndex] ) or comparisonCache[idIndex] ~= newEncodedString then 
					comparisonCache[idIndex] = newEncodedString
					Module:UpdateData( Category, Data, PlayerTable )
				end
			end
		end
	end)
	
else
	
	local LocalPlayer = game:GetService('Players').LocalPlayer
	
	Module.OnUpdate = Instance.new('BindableEvent')
	
	-- client
	local DataContainer = { }
	
	function Module:GetData( Category, Yield )
		if DataContainer[Category] then
			return DataContainer[Category]
		end
		if Yield then
			local yieldStart = time()
			repeat task.wait(0.1) until DataContainer[Category] or (time() - yieldStart) > 5
		end
		return DataContainer[Category]
	end
	
	DataRemoteEvent.OnClientEvent:Connect(function( Category, Data )
		print(Category)
		DataContainer[ Category ] = Data
		Module.OnUpdate:Fire( Category, Data )
	end)
	
	DataRemoteEvent:FireServer()
	
end

return Module
