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
-- screenGameOver.lua
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
local gameUI 	= require( "lib.gameUI" )
local widget 			= require "widget"

local scene = composer.newScene()


---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Goto Menu/Game functions
----------------------------------------------------------------------------------------------------
local function tryAgain()
	composer.gotoScene( "mainGameInterface", "fade", 400  )
	return true
end

local function backToMenu()
	composer.gotoScene( "startScreen", "fade", 400  )
	return true
end


local function tryAgainPrepare()
	timer.performWithDelay( 300, tryAgain )
end

local function backToMenuPrepare()
	timer.performWithDelay( 300, backToMenu )
end



-- Called when the scene's view does not exist:
function scene:create( event )
	local screenGroup = self.view
	
	----------------------------------------------------------------------------------------------------
	-- Setup the Background Image
	----------------------------------------------------------------------------------------------------
	local image = display.newImage( imagePath.."gameOverScreen.png",480,320 )
	image.x = _w/2
	image.y = _h/2
	screenGroup:insert( image )

	----------------------------------------------------------------------------------------------------
	-- Back to Menu Button
	----------------------------------------------------------------------------------------------------
	local menuButton = widget.newButton{
		left 	= 198-45,
		top 	= 258-45,
		defaultFile = imagePath.."button_Menu.png",
		overFile 	= imagePath.."button_MenuOn.png",
		onRelease = backToMenuPrepare,
		}			
	--menuButton:setReferencePoint(display.CenterReferencePoint)
	menuButton.anchorX = 0.5		-- Graphics 2.0 Anchoring method
	menuButton.anchorY = 0.5		-- Graphics 2.0 Anchoring method
	screenGroup:insert( menuButton )
	
	----------------------------------------------------------------------------------------------------
	-- TryAgain Button
	----------------------------------------------------------------------------------------------------
	local tryAgainButton = widget.newButton{
		left 	= 288-45,
		top 	= 258-41,
		defaultFile = imagePath.."button_TryAgain.png",
		overFile 	= imagePath.."button_TryAgainOn.png",
		onRelease = tryAgainPrepare,
		}			
	--tryAgainButton:setReferencePoint(display.CenterReferencePoint)
	tryAgainButton.anchorX = 0.5		-- Graphics 2.0 Anchoring method
	tryAgainButton.anchorY = 0.5		-- Graphics 2.0 Anchoring method
	screenGroup:insert( tryAgainButton )
end




-- Called immediately after scene has moved onscreen:
function scene:show( event )
	
	composer.removeScene( "mainGameInterface" )
	composer.removeScene( "level"..level )
	
end


-- Called when scene is about to move offscreen:
function scene:hide( event )
		
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroy( event )
	print( "((destroying scene 1's view))" )
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