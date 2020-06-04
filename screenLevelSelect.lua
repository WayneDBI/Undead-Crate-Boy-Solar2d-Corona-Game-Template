------------------------------------------------------------------------------------------------------------------------------------
-- Undead Crate Boy [Corona Template]
------------------------------------------------------------------------------------------------------------------------------------
-- Developed by Deep Blue Apps.com [http:www.deepblueapps.com]
------------------------------------------------------------------------------------------------------------------------------------
-- Abstract: Collect the crates to increase your score. Achieve the TARGET amount of crates to
-- proceed to the next level. Avoid the Enemies and Ghosts, or shoot them with the various
-- weapons. Run and Jump around the scene to avoid the enemies and collect the crates.
-- Enemies will change direction when they hit an opposing wall.
------------------------------------------------------------------------------------------------------------------------------------
--
-- screenLevelSelect.lua
--
------------------------------------------------------------------------------------------------------------------------------------
-- 20th Feb 2014
-- Version 4.0
-- Requires Corona 2013.2076 - minimum
------------------------------------------------------------------------------------------------------------------------------------

local composer		= require( "composer" )
local myGlobalData 	= require( "lib.globalData" )
local loadsave 		= require( "lib.loadsave" )
--local ui 				= require( "ui" )
local gameUI 		= require( "lib.gameUI" )
local widget 		= require "widget"


local scene = composer.newScene()


---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Goto Level functions
----------------------------------------------------------------------------------------------------
local function nextLevelPlay()
	composer.gotoScene( "mainGameInterface", "fade", 400  )
	return true
end


local function playLevel1()
	level = 1
	timer.performWithDelay( 300, nextLevelPlay )
end

local function playLevel2()
	if (nextLevel > 1) then
		level = 2
		timer.performWithDelay( 300, nextLevelPlay )
	end
end

local function resetLevelsFunction()
	--Reset the level data back to LEVEL 1
	--SAVE the level data to the users device!
	saveDataTable.levelReached = 1
	loadsave.saveTable(saveDataTable, "crateboydba.json")
	level 		= 1 -- reset the Global variables too
	nextLevel	= 1 -- reset
	composer.gotoScene( "startScreen", "fade", 400  ) --take user back to start screen after reset
	return true
end


-- Called when the scene's view does not exist:
function scene:create( event )
	local screenGroup = self.view
	
	----------------------------------------------------------------------------------------------------
	-- Setup the Background Image
	----------------------------------------------------------------------------------------------------
	local image = display.newImage( imagePath.."levelSelectScreen.png",480,320 )
	image.x = _w/2
	image.y = _h/2
	screenGroup:insert( image )

	
	--NOTE the Level buttons are invisible, they just show a darkened overlay when the user presses them
	----------------------------------------------------------------------------------------------------
	-- Level 1 Button
	----------------------------------------------------------------------------------------------------
	local levelButton = widget.newButton{
		left 	= 17,
		top 	= 166,
		defaultFile = imagePath.."button_LevelOff.png",
		overFile 	= imagePath.."button_LevelOn.png",
		onRelease = playLevel1,
		}			
	screenGroup:insert( levelButton )
	
	----------------------------------------------------------------------------------------------------
	-- Level 2 Button
	----------------------------------------------------------------------------------------------------
	local levelButton = widget.newButton{
		left 	= 252,
		top 	= 166,
		defaultFile = imagePath.."button_LevelOff.png",
		overFile 	= imagePath.."button_LevelOn.png",
		onRelease = playLevel2,
		}			
	screenGroup:insert( levelButton )
	
	----------------------------------------------------------------------------------------------------
	-- Show a lock on the level 2 button (if its not been unlocked yet).
	----------------------------------------------------------------------------------------------------

	lockImage = display.newImage( imagePath.."levelLocked.png",204,136 )
	lockImage.x = 354
	lockImage.y = 234
	screenGroup:insert( lockImage )

	if (nextLevel > 1 ) then
		lockImage.alpha = 0.0
	else
		lockImage.alpha = 1.0
	end
	
	
	----------------------------------------------------------------------------------------------------
	-- Setup the RESET LEVELS button
	----------------------------------------------------------------------------------------------------
	local resetButton = widget.newButton{
		left = _w-150,
		top = (_h/2)-32,
		defaultFile = imagePath.."buttonResetOff.png",
		overFile = imagePath.."buttonResetOn.png",
		onRelease = resetLevelsFunction,
		}			
	screenGroup:insert( resetButton )

	
	
end






-- Called immediately after scene has moved onscreen:
function scene:show( event )
	
	composer.removeScene( "startScreen" )
	composer.removeScene( "mainGameInterface" )
	composer.removeScene( "level"..level )
	
end


-- Called when scene is about to move offscreen:
function scene:hide( event )
		
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroy( event )
	print( "((destroying Level Selection view))" )
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "create", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "show", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "hide", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------------

return scene