local PhysicsService = game:GetService('PhysicsService')

local function IterateBaseParts(Parent, callback)
	local Array = Parent:GetDescendants()
	table.insert(Array, Parent)
	for _, BasePart in ipairs( Array ) do
		if BasePart:IsA('BasePart') then
			callback(BasePart)
		end
	end
end

-- // Module // --
local Module = {}

function Module:NewGroup(GroupName)
	local success, err = pcall(function()
		return PhysicsService:GetCollisionGroupId(GroupName)
	end)
	if not success then
		PhysicsService:CreateCollisionGroup(GroupName)
	end
end

function Module:SetCollisionOfGroups(GroupA, GroupB, Enabled)
	Module:NewGroup(GroupA)
	Module:NewGroup(GroupB)
	PhysicsService:CollisionGroupSetCollidable(GroupA, GroupB, Enabled)
end

function Module:AddDescendantsToGroup(Parent, GroupName)
	Module:NewGroup(GroupName)
	IterateBaseParts(Parent, function(BasePart)
		PhysicsService:SetPartCollisionGroup(BasePart, GroupName)
	end)
end

function Module:RemoveDescendantsFromGroup(Parent, GroupName)
	Module:NewGroup(GroupName)
	IterateBaseParts(Parent, function(BasePart)
		PhysicsService:RemoveCollisionGroup(BasePart, GroupName)
	end)
end

return Module
