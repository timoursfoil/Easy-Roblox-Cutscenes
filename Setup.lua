-- HOW TO SETUP
--[[
Make sure this in a place that LocalScripts can run (StarterPlayerScripts, StarterCharacterScripts, anything visible on the Client end. You can find documentation here: https://create.roblox.com/docs/reference/engine/classes/LocalScript)
First, create a folder in Workspace and name it "CutsceneParts". Inside that folder, put another folder, name it whatever. Then, inside of it, create 2 or more parts. Name them "Part1", "Part2", "Part3", etc. Make sure they are:
- Anchored
- CanCollide is false
- Anything else is fine (Trasnparent, Massless, etc.)
Second, create another folder in Workspace and name it "NPCs". This will store all your npcs, where you can put them in this folder.
Make sure all the NPCs inside this folder are actual NPCs.
You can check this by making sure they have:
- A Humanoid
- A Head
- A Torso
- A Left Arm
- A Right Arm
- A Left Leg
- A Right Leg
- Motor6Ds in the Torso/HumanoidRootPart connected to all the other limbs.
You can create joints easily using the "RidEdit" plugin (https://create.roblox.com/store/asset/1274343708/RigEdit-Lite)

With all this, it should work good! Just make sure to uncomment out the lines of the examples to add your npcs, sounds, etc.
If it doesnt work, even if you did everything right, please send me a DM on discord. (@timoursfoil)
]]
