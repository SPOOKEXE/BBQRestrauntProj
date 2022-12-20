
local TweenService = game:GetService('TweenService')

local baseTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

-- // Module // --
local Module = {}

-- // VIEWPORT // --
function Module:SetupInstanceForViewport( Target : Instance )
	local Humanoid = Target:FindFirstChildWhichIsA("Humanoid")
	if Humanoid then
		Humanoid.HealthDisplayDistance = Enum.HumanoidHealthDisplayType.AlwaysOff
		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if Target:IsA("Model") and Target.PrimaryPart then
		Target.PrimaryPart.Anchored = true
	end
end

function Module:SetupViewportCamera( ViewportFrame, CameraCFrame )
	local Camera = ViewportFrame:FindFirstChildOfClass('Camera')
	if not Camera then
		Camera = Instance.new('Camera')
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = CameraCFrame or CFrame.new()
		Camera.Parent = ViewportFrame
		ViewportFrame.CurrentCamera = Camera
	end
	return Camera
end

function Module:ClearViewport(ViewportFrame)
	for _, item in ipairs(ViewportFrame:GetChildren()) do
		if not item:IsA('Camera') then
			item:Destroy()
		end
	end
end

function Module:WrapperViewportSetup(Viewport, Model, CameraCFrame, ModelCFrame)
	Model = Model:Clone()
	Module:SetupInstanceForViewport( Model )
	Model:SetPrimaryPartCFrame( ModelCFrame )
	Model.Parent = Viewport
	local Camera = Module:SetupViewportCamera( Viewport, CameraCFrame )
	return Model, Camera
end

-- // USER INTERFACE // --
local baseButton = Instance.new('ImageButton')
baseButton.Name = 'Button'
baseButton.AnchorPoint = Vector2.new(0.5, 0.5)
baseButton.Position = UDim2.fromScale(0.5, 0.5)
baseButton.Size = UDim2.fromScale(1, 1)
baseButton.BackgroundTransparency = 1
baseButton.Selectable = true
baseButton.ImageTransparency = 1
baseButton.ZIndex = 50
function Module:CreateActionButton(properties)
	local button = baseButton:Clone()
	if typeof(properties) == 'table' then
		for k, v in pairs(properties) do
			button[k] = v
		end
	end
	return button
end

function Module:FadeGuiObjects( Parent, endTransparency, customTweenInfo )
	local Objs = Parent:GetDescendants()
	if Parent:IsA('GuiObject') then
		table.insert(Objs, Parent)
	end
	for _, GuiObject in ipairs( Objs ) do
		local objectGoal = nil
		if GuiObject:IsA('Frame') then
			objectGoal = {BackgroundTransparency = endTransparency}
		elseif GuiObject:IsA('TextLabel') then
			objectGoal = {BackgroundTransparency = endTransparency, TextTransparency = endTransparency}
		elseif GuiObject:IsA('UIStroke') then
			objectGoal = {Transparency = endTransparency}
		elseif GuiObject:IsA('ImageLabel') or GuiObject:IsA('ImageButton') then
			objectGoal = {BackgroundTransparency = endTransparency, ImageTransparency = endTransparency}
		end
		TweenService:Create(GuiObject, customTweenInfo or baseTweenInfo, objectGoal):Play()
	end
end

return Module
