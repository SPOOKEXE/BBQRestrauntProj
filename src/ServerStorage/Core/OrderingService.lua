
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local OrderingOptionsModule = ReplicatedModules.Data.OrderingOptions

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:ValidateOrderRequest(orderData)
	if typeof(orderData) ~= 'table' then
		return false, 'Order data is not a table.'
	end
	local validatedOrder = {}
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
	end
	return validatedOrder
end

function Module:OnPlayerOrderRequest(LocalPlayer)
	-- summon npc > walk to player > open menu > wait for order > take order to kitchen > wait for order to be ready > deliver order to player + dialogue > walk to kitchen > despawn
	-- employee dialogue
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
