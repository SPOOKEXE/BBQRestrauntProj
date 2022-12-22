
local PathfindingService = game:GetService('PathfindingService')
local RunService = game:GetService('RunService')
local ChatService = game:GetService('Chat')

local ActiveMoveToConnections = {}

local function HasReachedMoveToPosition(MoveToData)
	local Bindable = MoveToData.Bindable
	if time() - MoveToData.Start > MoveToData.Timeout then
		MoveToData.Success = false
		Bindable:Fire()
		return true
	end
	if (MoveToData.AI.Model:GetPivot().Position - MoveToData.Target) < MoveToData.MaxDistance then
		MoveToData.Success = true
		Bindable:Fire()
		return true
	end
	return false
end

RunService.Heartbeat:Connect(function()
	local index = 1
	while index <= #ActiveMoveToConnections do
		local MoveToData = ActiveMoveToConnections[index]
		if HasReachedMoveToPosition(MoveToData) then
			table.remove(ActiveMoveToConnections, index)
		else
			index += 1
		end
	end
end)

-- // Class // --
local Class = {}
Class.__index = Class

function Class.New( Model )
	return setmetatable({
		Model = Model,
		Humanoid = Model and Model:FindFirstChildWhichIsA('Humanoid'),
		Path = false,

		ActiveWaypoints = false,
		--WaypointIndex = 1,
	}, Class):SetAgentParams({AgentCanJump = false})
end

function Class:SetAgentParams(AgentParams)
	self.Path = PathfindingService:CreatePath(AgentParams)
	return self
end

function Class:SetModel(Model)
	self.Model = Model
	self.Humanoid = Model and Model:FindFirstChildWhichIsA('Humanoid')
	--self.WaypointIndex = 1
	return self
end

function Class:CalculatePathTo(Position)
	self.Path:ComputeAsync(self.Model.PrimaryPart.Position, Position)
	--self.WaypointIndex = 1
	if self.Path.Status == Enum.PathStatus.Success then
		self.ActiveWaypoints = self.Path:GetWaypoints()
	else
		self.ActiveWaypoints = false
	end
	return self
end

function Class:_MoveToFinished(Position)
	local Bindable = Instance.new('BindableEvent')
	local Data = {
		Success = nil,
		AI = self,
		Bindable = Bindable,
		TargetPosition = Position,

		Timeout = 2,
		MaxDistance = 8,
		Start = time(),
	}
	table.insert(ActiveMoveToConnections, Data)
	if typeof(Data.Success) ~= 'nil' then
		Bindable.Event:Wait()
	end
	Bindable:Destroy()
	return self
end

function Class:FollowPath(startIndex)
	startIndex = startIndex or 1
	if self.ActiveWaypoints then
		for _, waypoint : PathWaypoint in ipairs( self.ActiveWaypoints ) do
			self:_MoveToFinished(waypoint.Position)
		end
	end
	return self
end

function Class:ChatMessage(message)
	ChatService:Chat(self.Model.Head, message, Enum.ChatColor.White)
end

function Class:Destroy()
	for k, _ in pairs(self) do
		self[k] = nil
	end
	setmetatable(self, nil)
end

return Class

