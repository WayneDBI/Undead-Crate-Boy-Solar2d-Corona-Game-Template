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
-- startScreen.lua
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


local highlightSpeed		= 10
local maxCrates				= 20
local crateCounter 			= 0
-----------------------------------------------------------------
-- Setup the Physics World
-----------------------------------------------------------------
physics.start()
physics.setScale( 90 )
physics.setGravity( 0, 7 )
physics.setPositionIterations(128)

-- un-comment to see the Physics world over the top of the Sprites
--physics.setDrawMode( "hybrid" )

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

local image
local logoAreaPhysics

----------------------------------------------------------------------------------------------------
-- Extra cleanup routine
----------------------------------------------------------------------------------------------------
local coronaMetaTable = getmetatable(display.getCurrentStage())
	isDisplayObject = function(aDisplayObject)
	return (type(aDisplayObject) == "table" and getmetatable(aDisplayObject) == coronaMetaTable)
end

local function cleanGroups ( objectOrGroup )
    if(not isDisplayObject(objectOrGroup)) then return end
		if objectOrGroup.numChildren then
			-- we have a group, so first clean that out
			while objectOrGroup.numChildren > 0 do
				-- clean out the last member of the group (work from the top down!)
				cleanGroups ( objectOrGroup[objectOrGroup.numChildren])
			end
		end
			objectOrGroup:removeSelf()
    return
end

----------------------------------------------------------------------------------------------------
-- Goto Game function
----------------------------------------------------------------------------------------------------
local function levelSelect()
	--nextLevel 		= 1		-- Reset the NEXT LEVEL variable to 1 (Starting Level)
	--level				= 1 	-- Reset the CURRENT LEVEL back to level 1
	--allLevelsWon 		= false	-- Reset the All Levels won flag
	
	-- NOTE: If you want to SAVE the users current level location you would need to
	-- manipulate these variables accordingly.
	
	--storyboard.gotoScene( "mainGameInterface", "fade", 400  )
	composer.gotoScene( "screenLevelSelect", "fade", 400  )
	return true
end

local function levelSelectPrepare()
	timer.cancel(dropSomeCrates)
	cleanGroups ( crateGroup )
	cleanGroups ( logoAreaPhysics )
	timer.performWithDelay( 300, levelSelect )
end



-- Called when the scene's view does not exist:
function scene:create( event )
	local screenGroup = self.view
	
	local buttonGroup 			= display.newGroup()
	local logoGroup 			= display.newGroup()
	local dbaGroup 				= display.newGroup()
	local highlightGroup 		= display.newGroup()
	local crateGroup 			= display.newGroup()

	----------------------------------------------------------------------------------------------------
	-- Setup the Background Image
	----------------------------------------------------------------------------------------------------
	image = display.newImage( imagePath.."background_001.png",480,320 )
	image.x = _w/2
	image.y = _h/2
	screenGroup:insert( image )
	
	local image2 = display.newImage( imagePath.."background_overlay.png",480,320 )
	image2.x = _w/2
	image2.y = _h/2
	screenGroup:insert( image2 )

	local border1 = display.newImage( imagePath.."blockLong_001.png",480,20 )
	border1.x = _w/2
	border1.y = _h-10
	border1.xScale = 2.5
	screenGroup:insert( border1 )

	----------------------------------------------------------------------------------------------------
	-- Create a Physics base for the splash screen crates to bounce on!
	----------------------------------------------------------------------------------------------------
	local platformMaterial = { density=1000.0, friction=0.0, bounce=0.1 }
	local platform = display.newRect( 0, 0, _w, 20 )
	platform.x = _w/2
	platform.y = _h-10
	platform.alpha = 0
	platform.myName = "platform"
	physics.addBody( platform, "static", platformMaterial )
	screenGroup:insert( platform )
	
	local wall = display.newRect( 0,0, 33,347 )
	wall.x = 6
	wall.y = 159
	wall.alpha = 0
	wall.myName = "platform"
	physics.addBody( wall, "static", platformMaterial )
	screenGroup:insert( wall )
	
	local wall = display.newRect( 0,0, 33,347 )
	wall.x = 478
	wall.y = 159
	wall.alpha = 0
	wall.myName = "platform"
	physics.addBody( wall, "static", platformMaterial )
	screenGroup:insert( wall )

	local wall = display.newRect( 0,0, 480,20 )
	wall.x = _w/2
	wall.y = 0
	wall.alpha = 0
	wall.myName = "platform"
	physics.addBody( wall, "static", platformMaterial )
	screenGroup:insert( wall )

	-- Create a Physics base on part of our logo for added effect!
	-- This is not needed in your final game though.
	local platformMaterial = { density=20.0, friction=0.01, bounce=0.6 }
	logoAreaPhysics = display.newRect( 0, 0, 70, 75 )
	logoAreaPhysics.x = _w/2+10
	logoAreaPhysics.y = _h-115
	logoAreaPhysics.alpha = 0
	logoAreaPhysics.rotation = 5
	logoAreaPhysics.myName = "platform"
	physics.addBody( logoAreaPhysics, "static", platformMaterial )
	logoGroup:insert( logoAreaPhysics )
	----------------------------------------------------------------------------------------------------
	

	----------------------------------------------------------------------------------------------------
	-- Setup the Highlight bar
	----------------------------------------------------------------------------------------------------
	highlight = display.newImage( imagePath.."highlight.png" )
	highlight.x = _w+200
	highlight.y = _h/2
	highlight.alpha = 1.0
	highlight.rotation = -55
	highlightGroup:insert( highlight )
	screenGroup:insert( highlightGroup )
	
	----------------------------------------------------------------------------------------------------
	-- Setup the start game button
	----------------------------------------------------------------------------------------------------
	local infoButton = widget.newButton{
		left 	= (_w-160)/2,
		top 	= _h-50,
		defaultFile = imagePath.."button_Start.png",
		overFile 	= imagePath.."button_StartOn.png",
		onRelease = levelSelectPrepare,
		}			
	buttonGroup:insert( infoButton )
	--Insert the Info Group Layer into the Main Layer
--	screenGroup:insert( buttonGroup )

	----------------------------------------------------------------------------------------------------
	-- Setup the Sound ON/OFF button
	----------------------------------------------------------------------------------------------------
	soundButton = display.newImage( imagePath.."soundOn.png" )
	soundButton.x = _w-18
	soundButton.y = _h-_h+18
	soundButton.alpha = 0.5
	buttonGroup:insert( soundButton )

	soundButtonOff = display.newImage( imagePath.."soundOff.png" )
	soundButtonOff.x = _w-18
	soundButtonOff.y = _h-_h+18
	soundButtonOff.alpha = 0.0
	buttonGroup:insert( soundButtonOff )

	function musicOnOff(event)
		--Turn Music on or Off
		if (event.phase == "ended") then
			if (soundPlaying==true) then
				audio.pause(bgMusic1)
				soundPlaying=false
				audio.setVolume( 0.0 )
				print("STOP Music")
				soundButton.alpha 		= 0.0
				soundButtonOff.alpha	= 0.5
			else
				audio.resume(bgMusic1)
				soundPlaying=true
				audio.setVolume( musicVolume )
				print("START Music")
				soundButton.alpha 		= 0.5
				soundButtonOff.alpha	= 0.0
			end
		end
    	
	end

	----------------------------------------------------------------------------------------------------
	-- Setup the Logo - with Bounce in effect
	----------------------------------------------------------------------------------------------------
	local dbaLogo = display.newImage( imagePath.."dbaLogo.png" )
	dbaLogo.x = (_w/2)-120
	dbaLogo.y = 550
	dbaGroup:insert( dbaLogo )
	dbaGroup.alpha=0.0

	local imageLogo = display.newImage( imagePath.."gameLogo.png" )
	imageLogo.x = (_w/2)
	imageLogo.y = -80
	logoGroup:insert( imageLogo )
	logoGroup.xScale = 2.0
	logoGroup.yScale = 2.0
	logoGroup.x = -240

	function bounceUp()
		transition.to(logoGroup, {y=230, time=150, xScale=1, yScale=1, x=0}) 			-- Bounce the logo back up a little
		transition.to(dbaGroup, {y=-430, time=950, alpha=1.0}) 							-- Bounce the DBA logo back up a little
		transition.to(highlight, {alpha=0.0,xScale=4.0, yScale=4.0, x=0, time=1800})	-- Swipe the Highlight across the screen	
		audio.play(sfxCollect)
	end
	
	transition.to(logoGroup, {y=270, time=350, onComplete=bounceUp})					-- Animate the intro Logo..
	screenGroup:insert( dbaGroup )
	screenGroup:insert( logoGroup )

	----------------------------------------------------------------------------------------------------
	-- Drop in some crates for fun...
	-- This is all just for effect and not required in your final game if not required.
	----------------------------------------------------------------------------------------------------
	local function doShake(target)--, onCompleteDo)
		local firstTran, secondTran, thirdTran
		
		--Third Transition
		thirdTran = function()
			if target.shakeType == "Loop" then
				transition.to(target, {transition = inOutExpo, time = 100, rotation = 0, onComplete = firstTran})
			else
				transition.to(target, {transition = inOutExpo, time = 100, rotation = 0, onComplete = onCompleteDo})
			end
		end
		
		--Second Transition
		secondTran = function()
			transition.to(target, {transition = inOutExpo, time = 100, alpha = 1, rotation = -5, onComplete = thirdTran})
		end
		
		--First Transtion
		firstTran = function()
			transition.to(target, {transition = inOutExpo, time = 100, rotation = 5, onComplete = secondTran})
		end
		
		--Do the first transition
		firstTran()
	end
        
    -- Enable the user to be able to DRAG and throw our little Crates around.    
    local dragBody = gameUI.dragBody -- for use in touch event listener below
	
	function newCrate()	
		crateCounter = crateCounter + 1
		rand = math.random( 100 )
	
			local myNewCrateDrop = display.newImageRect(imagePath.."crate_42x42.png",36,36);
			myNewCrateDrop.x = 100+math.random( 300 )
			myNewCrateDrop.y = 20
			myNewCrateDrop.myName = "crate"
			myNewCrateDrop.soundPlaying = false
			myNewCrateDrop.id = crateCounter
			-- Our crate is 42 x 42 - it's got some CLEAR PIXELS around it to help prevent
			-- distortion during rotation. To account for this we'll create a new PHYSICS AREA
			-- around our crate to ensure they collide correctly.
			local crateArea = { -16,-16, 16,-16, 16,16, -16,16 }
			physics.addBody( myNewCrateDrop, { density=200, friction=0.1, bounce=0.1, shape=crateArea} )
			
			crateGroup:insert( myNewCrateDrop )
			
			-- Add event listener to the crate so we can throw it a round!    
			myNewCrateDrop:addEventListener( "touch", dragBody )
			
			-- Shake the main logo when all of the Crates are on the screen.
			if (crateCounter == maxCrates) then
				doShake(logoGroup)
			end
	
	end
	
	-- Start adding some crates to the scene
	dropSomeCrates = timer.performWithDelay( 500, newCrate, maxCrates )
	
	
	-- Add the Crates Group
	screenGroup:insert( crateGroup )
	
	-- Add the BUTTON group last - we want this to be on top of every other scene element.
	screenGroup:insert( buttonGroup )


	------------------------------------------------------------------------------------------------------------------------------------
	-- Start the BG Music - Looping
	------------------------------------------------------------------------------------------------------------------------------------
	audio.play(bgMusic1, {channel=1, loops =-1})

	soundButton:addEventListener( "touch", musicOnOff )
	soundButtonOff:addEventListener( "touch", musicOnOff )

end



local function onGlobalCollision( event )
	--print( "Global report: " .. event.object1.myName .. " & " .. event.object2.myName .. " collision began" )
	if (event.object1.myName == "platform" and event.object2.myName == "crate" and event.phase == "ended" and event.object2.soundPlaying == false ) then
		event.object2.soundPlaying = true
	end 

end


-- Called immediately after scene has moved onscreen:
function scene:show( event )
	-- remove previous scene's view
	composer.removeScene( "mainGameInterface" )
	composer.removeScene( "screenLevelSelect" )
	composer.removeScene( "level"..level )
	composer.removeScene( "screenGameOver" )
	composer.removeScene( "screenGameComplete" )
	composer.removeScene( "screenLevelComplete" )
end


-- Called when scene is about to move offscreen:
function scene:hide( event )
	Runtime:removeEventListener ( "collision", onGlobalCollision )
	soundButton:removeEventListener( "touch", musicOnOff )
	soundButtonOff:removeEventListener( "touch", musicOnOff )
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroy( event )
	print( "((destroying startScreen.lua view))" )
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
Runtime:addEventListener ( "collision", onGlobalCollision )

return scene