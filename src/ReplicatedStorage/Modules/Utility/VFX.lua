
local WHITELIST_CLASSES = {'ParticleEmitter', 'Beam', 'Trail'}

-- // Module // --
local Module = {}

function Module:EmitAllEmitterDescendants(Ins, customNumber)
	for _, ins in ipairs(Ins:GetDescendants()) do
		if ins:IsA("ParticleEmitter") then
			ins:Emit(customNumber or ins:GetAttribute("EmitCount") or 1)
		end
	end
end

function Module:ToggleEmitterDescendants(Particle, bool)
	for _, v in ipairs(Particle:GetDescendants()) do
		if table.find(WHITELIST_CLASSES, v.ClassName) then
			v.Enabled = bool
		end
	end
end

function Module:ToggleEmitterChildren(Particle, bool)
	for _, v in ipairs(Particle:GetChildren()) do
		if table.find(WHITELIST_CLASSES, v.ClassName) then
			v.Enabled = bool
		end
	end
end

return Module
