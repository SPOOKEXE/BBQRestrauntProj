
local ServerStorage = game:GetService('ServerStorage')
local ServerAssets = ServerStorage:WaitForChild('Assets')
local ServerModules = require(ServerStorage:WaitForChild('Modules'))

local NPCClassModule = ServerModules.Classes.NPC

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local OrderingOptionsModule = ReplicatedModules.Data.OrderingOptions

local SystemsContainer = {}

local ActiveNPCCache = {}

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
	return totalItems ~= 0 and validatedOrder or false
end

function Module:SpawnEmployeeNPC()
	local BaseDummy = ServerAssets.EmployeeDummy:Clone()
	BaseDummy:PivotTo( EmployeeSpawnCFrame )
	BaseDummy.Parent = workspace
	return NPCClassModule.New(BaseDummy)
end

function Module:RequestTableOrders(TableModel)
	-- give all people at the table the order gui

	-- wait for all orders to come in (or timeout)

	-- return orders

	return { }
end

function Module:OnTableEmployeeCall(LocalPlayer, TableModel)
	if ActiveNPCCache[LocalPlayer] or TableModel[TableModel] then
		return
	end
	ActiveNPCCache[LocalPlayer] = true
	TableModel[TableModel] = true

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
	TableModel[TableModel] = nil
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	--[[
		for _, TableModel in ipairs( workspace.ActiveTables ) do
			workspace.ActiveTables.EmployeeCall.MouseClick:Connect(function(LocalPlayer)
				Module:OnTableEmployeeCall(LocalPlayer, TableModel)
			end)
		end
	]]
end

return Module
