------------------------------------------------------------------------------------------------------------------------------------
-- Undead Crate Boy [Corona Template]
------------------------------------------------------------------------------------------------------------------------------------
-- Developed by Deep Blue Apps.com [http:www.deepblueideas.com]
------------------------------------------------------------------------------------------------------------------------------------
-- Abstract: Collect the crates to increase your score. Achieve the TARGET amount of crates to
-- proceed to the next level. Avoid the Enemies and Ghosts, or shoot them with the various
-- weapons. Run and Jump around the scene to avoid the enemies and collect the crates.
-- Enemies will change direction when they hit an opposing wall.
------------------------------------------------------------------------------------------------------------------------------------
--
-- main.lua
--
------------------------------------------------------------------------------------------------------------------------------------
-- 27th August 2016
-- Version 5.0
-- Requires Corona 2016.2906 - minimum
------------------------------------------------------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

local composer 		= require "composer"
local physics 		= require( "physics" )
local myGlobalData 	= require( "lib.globalData" )
local loadsave 		= require( "lib.loadsave" )
local device 		= require( "lib.device" )


system.activate( "multitouch" )


--_G.sprite = require "sprite"							-- Add SPRITE API for Graphics 1.0

-- Define our Game Global variables
_G._w 					= display.contentWidth  		-- Get the devices Width
_G._h 					= display.contentHeight 		-- Get the devices Height
_G.gameScore			= 0								-- The Users score
_G.highScore			= 0								-- Saved HighScore value
_G.numberOfLevels		= 3								-- How many levels does the game have?
_G.levelsUnlocked		= 1								-- How many levels has the user unlocked?
_G.sfxVolume			= 1								-- Default SFX Volume
_G.musicVolume			= 0.8							-- Default Music Volume
_G.imagePath			= "assets/images/"				-- GLOBAL path to the image folder 
_G.audioPath			= "assets/audio/"				-- GLOBAL path to the audio folder 
_G.audioExtensions		= "caf"							-- GLOBAL path to the audio FORMAT folder [caf, aiff, ogg]
_G.level				= 1								-- Global Level Select, Clean, Load, etc...
_G.maxLevels			= 2								-- Global Maximum number of levels to fully complete the game
_G.allLevelsWon			= false							-- Global Has the user completed every single level?
_G.targetCrates			= 0								-- Global How many crates need to be collected for the loaded level
_G.doDebugPhysics		= true
_G.templateName			= "Undead Crate Boy Template"
_G.soundPlaying			= true

_G.saveDataTable		= {}							-- Define the Save/Load base Table to hold our data

-- Load in the saved data to our game table
-- check the files exists before !
if loadsave.fileExists("dbi_CrateBoy_001.json", system.DocumentsDirectory) then
	saveDataTable = loadsave.loadTable("dbi_CrateBoy_001.json")
else
	saveDataTable.levelReached = 1
	loadsave.saveTable(saveDataTable, "dbi_CrateBoy_001.json")
end

--Now load in the Data
saveDataTable = loadsave.loadTable("dbi_CrateBoy_001.json")

--Now assign the LOADED level to the Game Variable to control the levels the user can select.
_G.nextLevel			= saveDataTable.levelReached	-- Global The next available Level Select, Clean, Load, etc...

---------------------------------------------------------------------------------
-- Enable debug by setting to [true] to see FPS and Memory usage.
---------------------------------------------------------------------------------
myGlobalData.doDebug 					= false	-- show the Memory and FPS box?

if (myGlobalData.doDebug) then
	composer.isDebug = true
	local fps = require("lib.fps")
	local performance = fps.PerformanceOutput.new();
	performance.group.x, performance.group.y = (display.contentWidth/2)-50,  display.contentWidth/2-70;
	performance.alpha = 0.3; -- So it doesn't get in the way of the rest of the scene
end
------------------------------------------------------------------------------------------------------------------------------------


audio.setVolume( musicVolume )

function startGame()
	composer.gotoScene( "startScreen")	--This is our main menu
end



--Define some globally loaded assets
sfxCollect 		= audio.loadSound( audioPath.._G.audioExtensions.."/Collect.".._G.audioExtensions )
sfxFail			= audio.loadSound( audioPath.._G.audioExtensions.."/Fail.".._G.audioExtensions)
sfxKill			= audio.loadSound( audioPath.._G.audioExtensions.."/GhostKill.".._G.audioExtensions)
sfxGun			= audio.loadSound( audioPath.._G.audioExtensions.."/Gun.".._G.audioExtensions)
sfxGun2			= audio.loadSound( audioPath.._G.audioExtensions.."/Gun8.".._G.audioExtensions)
sfxHit			= audio.loadSound( audioPath.._G.audioExtensions.."/Unithit.".._G.audioExtensions)
sfxJump			= audio.loadSound( audioPath.._G.audioExtensions.."/Jump.".._G.audioExtensions)
sfxLevelWon		= audio.loadSound( audioPath.._G.audioExtensions.."/Victory2.".._G.audioExtensions)
sfxVictory		= audio.loadSound( audioPath.._G.audioExtensions.."/Victory.".._G.audioExtensions)

bgMusic1		= audio.loadStream( audioPath.."music/".."BigParty.mp3" )

--Start Game after a short delay.
timer.performWithDelay(1, startGame )
