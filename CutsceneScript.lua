

local TweenService = game:GetService("TweenService") -- TweenService for smooth camera animations
local Camera = workspace.CurrentCamera -- Reference to the game's current camera
local events = game:GetService("ReplicatedStorage"):WaitForChild("Events") -- Folder holding all custom game events
local soundFolder = game:GetService("ReplicatedStorage"):WaitForChild("Sounds") -- Folder containing all sounds used in cutscenes
local Players = game:GetService("Players") -- Service to access player data

-- === CONFIGURATION === --
local partsFolder = workspace:WaitForChild("CutsceneParts"):WaitForChild("Test") -- Folder containing parts representing camera positions for the cutscene. "Test" is just a test, you can rename it to whatever folder you made.
local npcsFolder = workspace:WaitForChild("NPCs")

-- Duration in seconds for each tween (camera move) to complete
local tweenTimes = {
	[1] = 1,
	[2] = 1,
--	[3] = 1,
--	[4] = 6,
--	[5] = 0.0005,
}

-- Delay in seconds between each tween completing and the next one starting
local delaysBetweenTweens = {
	[1] = 0.3,
	[2] = 0.5,
--	[3] = 1,
--	[4] = 0.2,
--	[5] = 5,
}

local returnToCustomDelay = 1 -- Delay before returning control to the player after cutscene ends.

-- === Player Movement Control === --
local canPlayerMove = false -- Whether the player can move during the cutscene (false disables movement/jumping)
local ResetWalkSpeed = 16 -- Default walk speed to reset to after cutscene
local originalWalkSpeed = 16 -- Stores the player's original walk speed before cutscene starts

-- === Animation Data Tables === --
-- NPC animations to play during certain tween steps and specific timing (between 0 and 1)
local npcAnimations = {
	-- Example:
	-- { tweenPlay = 1, when = 1, npc = "b", animationId = "rbxassetid://84197626855631", doesLoop = false },
	-- tweenPlay: which tween step to trigger on
	-- when: normalized progress through tween (0=start, 1=end)
	-- npc: NPC model name in npc folder
	-- animationId: animation asset ID
	-- doesLoop: whether animation loops
}

-- Sounds to play at specific tween steps and timing
local soundsPlayed = {
	-- Example:
	-- { tweenPlay = 1, when = 0.7, ingameSound = "Sound" },
	-- tweenPlay: which tween step to trigger on
	-- when: normalized progress through tween
	-- ingameSound: sound name inside soundFolder
}

-- Player animations to play during certain tween steps and timing
local playerAnimations = {
	-- Example:
	-- { tweenPlay = 1, when = 0.5, animationId = "rbxassetid://94208597011396", doesLoop = false },
}

-- Table tracking all active animation tracks to allow stopping them easily
local activeTracks = {}

-- === Functions === --

-- Plays an animation on a specified NPC model
local function playNPCAnimation(npcName, animId, doesLoop)
	local npc = npcsFolder:FindFirstChild(npcName) -- Find the NPC in workspace
	if npc then
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local track = humanoid:LoadAnimation(anim)
			track.Looped = doesLoop
			track:Play()

			-- Add to active animation tracks list
			table.insert(activeTracks, track)

			-- Remove track from active list when animation stops
			track.Stopped:Connect(function()
				for i, t in ipairs(activeTracks) do
					if t == track then
						table.remove(activeTracks, i)
						break
					end
				end
			end)

			return track
		else
			warn("Humanoid not found in " .. npcName)
		end
	else
		warn("NPC " .. npcName .. " not found.")
	end
	return nil
end

-- Plays an animation on the local player character
local function playPlayerAnimation(animId, doesLoop)
	local player = Players.LocalPlayer -- Get local player
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		local track = humanoid:LoadAnimation(anim)
		track.Looped = doesLoop
		track:Play()

		-- Add to active animation tracks list
		table.insert(activeTracks, track)

		-- Remove track from active list when animation stops
		track.Stopped:Connect(function()
			for i, t in ipairs(activeTracks) do
				if t == track then
					table.remove(activeTracks, i)
					break
				end
			end
		end)

		return track
	else
		warn("Player character not found.")
	end
	return nil
end

-- Stops all currently active animations immediately
local function stopAllAnimations()
	for _, track in ipairs(activeTracks) do
		if track then
			track:Stop()
		end
	end
	activeTracks = {} -- Clear the list of active tracks
end

-- Plays a sound from the sound folder by name
local function playSound(soundName)
	local sound = soundFolder:FindFirstChild(soundName)

	if sound then
		sound:Play()
	else
		warn("Sound " .. soundName .. " is not inside the soundFolder!")
	end
end

-- === Main cutscene function === --
local function ObjectAnimPlay()
	-- Switch camera to scriptable mode for manual control
	Camera.CameraType = Enum.CameraType.Scriptable

	-- Disable player movement if configured
	local player = Players.LocalPlayer
	local playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	local controls = playerModule:GetControls()

	-- Save the player's original walk speed or use default if unavailable
	originalWalkSpeed = player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.WalkSpeed or ResetWalkSpeed

	if not canPlayerMove then
		controls:Disable() -- Disable player controls to prevent movement/jumping during cutscene
	end

	-- Gather cutscene parts into a table indexed by their part number (e.g., Part1, Part2)
	local parts = {}
	for _, part in ipairs(partsFolder:GetChildren()) do
		local index = tonumber(part.Name:match("Part(%d+)"))
		if index then
			parts[index] = part
		end
	end

	local index = 1

	-- Function to play each tween in sequence, animating the camera and triggering animations/sounds
	local function playNextTween()
		local currentPart = parts[index]
		if not currentPart then
			-- No more parts, wait then restore camera and controls
			task.wait(returnToCustomDelay)
			stopAllAnimations() -- Stop any playing animations
			Camera.CameraType = Enum.CameraType.Custom -- Return camera control to player
			controls:Enable() -- Re-enable player controls
			if player.Character then
				player.Character.Humanoid.WalkSpeed = originalWalkSpeed -- Restore walk speed
			end
			return
		end

		local duration = tweenTimes[index] or 0.5 -- Duration of current tween
		local delayAfter = delaysBetweenTweens[index] or 0.1 -- Delay after tween finishes before next tween starts

		-- Create and play tween moving camera to current part's CFrame
		local tween = TweenService:Create(Camera, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			CFrame = currentPart.CFrame
		})
		tween:Play()

		-- Schedule NPC animations that should play during this tween at the specified normalized times
		for _, anim in ipairs(npcAnimations) do
			if anim.tweenPlay == index and anim.when >= 0 and anim.when <= 1 then
				task.delay(duration * anim.when, function()
					playNPCAnimation(anim.npc, anim.animationId, anim.doesLoop)
				end)
			end
		end

		-- Schedule player animations similarly
		for _, anim in ipairs(playerAnimations) do
			if anim.tweenPlay == index and anim.when >= 0 and anim.when <= 1 then
				task.delay(duration * anim.when, function()
					playPlayerAnimation(anim.animationId, anim.doesLoop)
				end)
			end
		end

		-- Schedule sounds to play at the right moments
		for _, soundData in ipairs(soundsPlayed) do
			if soundData.tweenPlay == index and soundData.when >= 0 and soundData.when <= 1 then
				task.delay(duration * soundData.when, function()
					playSound(soundData.ingameSound)
				end)
			end
		end

		-- When tween completes, wait the configured delay then move to the next part
		tween.Completed:Connect(function()
			task.wait(delayAfter)
			index += 1
			playNextTween()
		end)
	end

	-- Start the cutscene tween sequence
	playNextTween()
end

-- Connect cutscene functions to remote events so the cutscene can be triggered
events.CutsceneEventBind.Event:Connect(ObjectAnimPlay) -- Fires when the bindable event is triggered
events.CutsceneEventRemote.Event:Connect(ObjectAnimPlay) -- Fires when the remote event is triggered
