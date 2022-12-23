
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local ServerAssets = ServerStorage:WaitForChild('Assets')
local ServerModules = require(ServerStorage:WaitForChild('Modules'))

local NPCClassModule = ServerModules.Classes.NPC

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local RemoteService = ReplicatedModules.Services.RemoteService
local OrderRemoteEvent = RemoteService:GetRemote('OrderEvent', 'RemoteEvent', false)

local OrderingOptionsModule = ReplicatedModules.Data.OrderingOptions

local SystemsContainer = {}

local ActiveNPCCache = {} -- players that have called employees
local ActiveTableCache = {} -- tables that have called employees

local ActiveSeatOccupants = {} -- [TableModel] = { ...PlayersInTheSeats... }
local PlayerOrderCache = {} -- [PlayerInstance] = { ...OrderData...}

-- // Module // --
local Module = {}

function Module:ValidateOrderRequest(orderData)
	if typeof(orderData) ~= 'table' then
		return false, 'Order data is not a table.'
	end
	local validatedOrder = {}
	local totalItems = 0
	for itemID, numberOfItems in pairs(orderData) do
		if typeof(itemID) ~= 'string' or typeof(numberOfItems) ~= 'number' then
			continue
		end
		if numberOfItems < 1 or numberOfItems > OrderingOptionsModule.MaxOrderForItem then
			continue
		end
		if not OrderingOptionsModule.OrderingOptions[ itemID ] then
			continue
		end
		validatedOrder[itemID] = numberOfItems
		totalItems += 1
	end
	return totalItems ~= 0 and validatedOrder
end

function Module:SpawnEmployeeNPC()
	local BaseDummy = ServerAssets.EmployeeDummy:Clone()
	BaseDummy:PivotTo( EmployeeSpawnCFrame )
	BaseDummy.Parent = workspace
	return NPCClassModule.New(BaseDummy)
end

function Module:DistributeOrderItems(OrderDict, TableModel)
	for _, LocalPlayer in ipairs( ActiveSeatOccupants[TableModel] ) do
		if OrderDict[LocalPlayer] then
			-- give items
			print('Give player these items; ', OrderDict[LocalPlayer])
		end
	end
end

function Module:RequestTableOrders(TableModel)
	if not ActiveSeatOccupants[TableModel] then
		return -- no one is at the table, ignore
	end

	-- give all people at the table the order gui
	for _, LocalPlayer in ipairs( ActiveSeatOccupants[TableModel] ) do
		PlayerOrderCache[LocalPlayer] = nil
		OrderRemoteEvent:FireClient(LocalPlayer)
	end

	-- wait for all orders to come in (or timeout)
	local startTime = time()
	while time() - startTime < OrderingOptionsModule.MaxOrderTime do
		local allOrdersReceived = true
		for _, LocalPlayer in ipairs( ActiveSeatOccupants[TableModel] ) do
			if not PlayerOrderCache[LocalPlayer] then
				allOrdersReceived = false
				break
			end
		end
		if allOrdersReceived then
			break
		end
		task.wait(0.5)
	end

	-- return orders
	local Orders = {}
	for _, LocalPlayer in ipairs( ActiveSeatOccupants[TableModel] ) do
		Orders[LocalPlayer] = PlayerOrderCache[LocalPlayer]
	end
	return Orders
end

function Module:OnTableEmployeeCall(LocalPlayer, TableModel)
	if ActiveNPCCache[LocalPlayer] or ActiveTableCache[TableModel] then
		return
	end
	ActiveNPCCache[LocalPlayer] = true
	ActiveTableCache[TableModel] = true

	-- summon npc
	local EmployeeNPC = Module:SpawnEmployeeNPC()

	-- walk to player table
	EmployeeNPC:CalculatePathTo(TableModel.EmployeePart.Position):FollowPath()

	-- ask player for order
	EmployeeNPC:ChatMessage('Hello guests, what would you like to order today?')
	local TableOrders = Module:RequestTableOrders(TableModel)
	for PlayerInstance, OrderData in pairs(TableOrders) do
		TableOrders[PlayerInstance] = OrderData and Module:ValidateOrderRequest(OrderData) or nil
	end
	-- { [PlayerInstance] = { ItemID = NumberOfItems } }

	-- order dialogue
	EmployeeNPC:ChatMessage('I have receieved your orders, please wait for the food to come out.')

	-- walk to kitchen
	EmployeeNPC:CalculatePathTo(KitchenNodePosition):FollowPath()

	-- wait a duration
	task.wait(8)

	-- bring order to table (the player)
	EmployeeNPC:CalculatePathTo(TableModel.EmployeePart.Position):FollowPath()

	-- give stuff, dialogue
	EmployeeNPC:ChatMessage('Here is the food you have ordered.')

	-- walk to kitchen
	EmployeeNPC:CalculatePathTo(KitchenNodePosition):FollowPath()

	-- despawn
	EmployeeNPC:Destroy()

	ActiveNPCCache[LocalPlayer] = nil
	ActiveTableCache[TableModel] = nil
end

local LastOccupantCache = {}
function Module:OnOccupantChanged(SeatPart, TableModel)
	if not ActiveSeatOccupants[TableModel] then
		ActiveSeatOccupants[TableModel] = {}
	end
	local Occupant = SeatPart.Occupant
	local PlayerInstance = Occupant and Players:GetPlayerFromCharacter(Occupant.Parent)
	if PlayerInstance then
		table.insert(ActiveSeatOccupants[TableModel], PlayerInstance )
	elseif LastOccupantCache[SeatPart] then
		local index = table.find(ActiveSeatOccupants[TableModel], LastOccupantCache[SeatPart])
		if index then
			table.remove(ActiveSeatOccupants[TableModel], index )
		end
	end
	LastOccupantCache[SeatPart] = PlayerInstance
end

function Module:OnPlayerRemoving(LocalPlayer)
	for SeatPart, LastOccupant in pairs( LastOccupantCache ) do
		if LastOccupant == LocalPlayer then
			LastOccupantCache[SeatPart] = nil
		end
	end

	for _, SeatedPlayers in pairs( ActiveSeatOccupants ) do
		local index = table.find(SeatedPlayers, LocalPlayer)
		if index then
			table.remove(SeatedPlayers, index)
		end
	end

	ActiveNPCCache[LocalPlayer] = nil
	PlayerOrderCache[LocalPlayer] = nil
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	OrderRemoteEvent.OnServerEvent:Connect(function(LocalPlayer, Order)
		if PlayerOrderCache[LocalPlayer] then
			return
		end
		PlayerOrderCache[LocalPlayer] = Module:ValidateOrderRequest(Order)
	end)

	for _, TableModel in ipairs( workspace.ActiveTables ) do
		for _, SeatPart in ipairs(TableModel.Seats:GetChildren()) do
			SeatPart:GetPropertyChangedSignal('Occupant'):Connect(function()
				Module:OnOccupantChanged(SeatPart, TableModel)
			end)
			Module:OnOccupantChanged(SeatPart, TableModel)
		end

		workspace.ActiveTables.EmployeeCall.MouseClick:Connect(function(LocalPlayer)
			Module:OnTableEmployeeCall(LocalPlayer, TableModel)
		end)
	end

	Players.PlayerRemoving:Connect(function(LocalPlayer)
		Module:OnPlayerRemoving(LocalPlayer)
	end)
end

return Module
