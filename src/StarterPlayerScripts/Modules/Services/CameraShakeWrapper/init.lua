local CameraShaker = require(script.CameraShaker)
local CurrentCamera = workspace.CurrentCamera

local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
	CurrentCamera.CFrame = CurrentCamera.CFrame * shakeCf
end)
camShake:Start()

-- // Module // --
local Module = {}

function Module:ShakeOnce(...)
	--camShake:StartShake(...) -- this works
	camShake:ShakeOnce(...) -- this doesn't
end

function Module:Shake(...)
	camShake:Shake(...)
end

return Module
