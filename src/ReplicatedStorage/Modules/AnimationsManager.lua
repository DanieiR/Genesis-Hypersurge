-- AnimationManager ModuleScript
-- Author: Dan_iDev
-- Date: 2024-12-31

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = {}
AnimationManager.LoadedAnimations = {}

-- Function to preload animations for a specific character
function AnimationManager:LoadAnimations(character, animations)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	if not self.LoadedAnimations[character] then
		self.LoadedAnimations[character] = {}
	end

	for animName, animId in pairs(animations) do
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. animId
		local track = animator:LoadAnimation(animation)
		if animName:sub(-4) == "Idle" then
			track.Priority = Enum.AnimationPriority.Action
		end
		self.LoadedAnimations[character][animName] = track
		animation:Destroy()
	end
end

-- Function to play an animation
function AnimationManager:PlayAnimation(character, animationName, loop, fadeTime)
	local animationTrack = self:GetAnimationTrack(character, animationName)

	if animationTrack then
		for name, track in pairs(self.LoadedAnimations[character]) do
			if track.IsPlaying then
				track:Stop(fadeTime or 0)
			end
		end

		animationTrack:Play(fadeTime or 0)
		if loop ~= nil then
			animationTrack.Looped = loop
		end
		return animationTrack
	else
		warn("Animation not found for character:", character, animationName)
	end
end

-- Function to stop animations
function AnimationManager:StopAnimation(character, animationName, fadeTime)
	local animationTrack = self:GetAnimationTrack(character, animationName)

	if animationTrack then
		animationTrack:Stop(fadeTime or 0)
		return animationTrack
	else
		warn("Animation not found for character:", character, animationName)
	end
end

function AnimationManager:StopAnimations(character, fadeTime)
	if self.LoadedAnimations[character] then
		for name, track in pairs(self.LoadedAnimations[character]) do
			track:Stop(fadeTime or 0)
		end
	end
end

-- Function to get an animation track
function AnimationManager:GetAnimationTrack(character, animationName)
	if self.LoadedAnimations[character] then
		return self.LoadedAnimations[character][animationName]
	end
	return nil
end

return AnimationManager
