------------------------------------------------------------------------------------------------------------------------------------
-- Undead Crate Boy [Corona Template]
------------------------------------------------------------------------------------------------------------------------------------
-- Developed by Deep Blue Apps.com [http:www.deepblueapps.com]
------------------------------------------------------------------------------------------------------------------------------------
-- Abstract: Collect the crates to increase your score. Achieve the TARGET amount of crates to
-- proceed to the next level. Avoid the enemies and Ghosts, or shoot them with the various
-- weapons. Run and Jump around the scene to avoid the enemies and collect the crates.
-- Enemies will change direction when they hit an opposing wall.
------------------------------------------------------------------------------------------------------------------------------------
--
-- mainGameInterface.lua
-- 
------------------------------------------------------------------------------------------------------------------------------------
-- 20th Feb 2014
-- Version 4.0
-- Requires Corona 2013.2076 - minimum
------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------
-- Build more scenes using the GUMBO tool, then use the co-ordinates of the obsticles
------------------------------------------------------------------------------------------------------------------------------------

-- Collect relevant external libraries
local composer 	= require( "composer" )
local scene 		= composer.newScene()

-- Activate MULTI-TOUCH - we want to be able to Move, run, Jump and Shoot at the same time!
system.activate( "multitouch" )

local myGlobalData 	= require( "lib.globalData" )
local loadsave 		= require( "lib.loadsave" )

------------------------------------------------------------------------------------------------------------------------------------
-- vars local
------------------------------------------------------------------------------------------------------------------------------------
local gameOverBool				= false
local levelCompleted			= false
local levelFailed				= false
local myLevel					= "needs loading"

local ourHeroDirection			= "Right"
local ourHeroLeft				= false
local ourHeroRight				= false
local ourHeroFireBullet			= false
local ourHeroJump				= false
local ourHeroOnFloor			= true
local ourHeroJumpForce			= -1.5
local ourHeroSpeed				= 3				-- Higher number = FASTER Movement.
ourHeroCanJump					= false
ourHeroOnPlatform 				= false

local timeLastBullet			= 0
local timeLastEnemy 			= 0
local bulletInterval 			= 200			-- Lower number = FASTER SHOOTING!
local rocketInterval 			= 700			-- Lower number = FASTER SHOOTING!
local bulletType	 			= 1				-- [1] Single Shot   [2] Double Shot   [3] Triple Shot   [4] Rocket!

local crateOnScreen				= false
local enemiesSpawnedTable 		= {} 			-- Create blank table to hold our enemies in
local enemiesToRemoveTable 		= {}
local maxEnemiesOnScreen		= 8
local totalEnemiesSpawned		= 0
local enemiesOnScreen			= 0
local enemyInPit				= false
local enemySpeed				= 1

local myScore					= 0
local myHighScore				= 0
local myCollectedCrates			= 0
local myScoreText				= 0
local myHighScoreText			= 0
local myCollectedCratesText		= 0

local cheatModeOn				= false		-- If set to true the enemies WILL NOT KILL YOU :-)

local shakeRightFunction1, shakeLeftFunction1, endShake1
local shakeRightFunction2, shakeLeftFunction2, endShake2
local shakeRightFunction3, shakeLeftFunction3, endShake3
local rightTrans, leftTrans, originalTrans
local shakeTime = 55
local shakeRange = {min = 1, max = 10}
local endShake          
local originalX = _w
local originalY = _h

-- Define our scene objects Collision bits
local heroCollisionFilter 		= { categoryBits = 2, maskBits = 119 } 
local bulletCollisionFilter 	= { categoryBits = 8, maskBits = 38 } 
local enemyCollisionFilter 		= { categoryBits = 4, maskBits = 59 } 
local crateCollisionFilter 		= { categoryBits = 64, maskBits = 51 } 

------------------------------------------------------------------------------------------------------------------------------------
-- Setup the Physics World
------------------------------------------------------------------------------------------------------------------------------------
physics.start()
physics.setScale( 90 )
physics.setGravity( 0, 12 )
physics.setPositionIterations(32)

------------------------------------------------------------------------------------------------------------------------------------
-- un-comment to see the Physics world over the top of the Sprites
------------------------------------------------------------------------------------------------------------------------------------
--physics.setDrawMode( "hybrid" )

----------------------------------------------------------------------------------------------------
-- Extra cleanup routines
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

------------------------------------------------------------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
------------------------------------------------------------------------------------------------------------------------------------
function scene:create( event )
	local screenGroup = self.view
		
		audio.setVolume( musicVolume )

		-----------------------------------------------------------------
		-- Setup our World/Scene Groups
		-----------------------------------------------------------------
		bgObjects_Group 		= display.newGroup()
		fgObjects_Group 		= display.newGroup()
		ourHeroObjects_Group 	= display.newGroup()
		bulletsObjects_Group 	= display.newGroup()
		enemiesObjects_Group 	= display.newGroup()
		cratesObjects_Group 	= display.newGroup()
		hud_Group 				= display.newGroup()
		game			 		= display.newGroup()
		game.x = 0

		-----------------------------------------------------------------
		-- Load the Level and return how many CRATES there are to collect.
		-----------------------------------------------------------------
		-- We dynamically load the correct level data AND return how many
		-- crates should be collected in that level to win!
		-----------------------------------------------------------------
		myLevel = "level"..level
		targetCrates = require(myLevel)
		print(myLevel.." : Collect "..targetCrates.." Crates.")  -- Debug terminal info only.
		
		-----------------------------------------------------------------
		-- Insert the LEVEL Scene Data into the Game Group
		-----------------------------------------------------------------
		game:insert( bgObjects_Group )
		
		
		-----------------------------------------------------------------
		-- Setup the Sound ON/OFF buttons
		-- Note we also set the GLOBAL volumes on/off or reset back to the default.
		-- We do this so the OFF or ON sound is carried over to the next scenes.
		-----------------------------------------------------------------
		soundButton = display.newImage( imagePath.."soundOn.png" )
		soundButton.x = _w-18
		soundButton.y = _h-_h+18
		if (soundPlaying == true) then			-- We check to see if the GLOBAL sound Playing value is True or False
			soundButton.alpha = 0.5				-- if it's TRUE set the sound on button to visible
			audio.setVolume( musicVolume )		-- and set the volume to the globally stored volume level
		else
			soundButton.alpha = 0.0
			audio.setVolume( 0.0 )
		end
		fgObjects_Group:insert( soundButton )
	
		soundButtonOff = display.newImage( imagePath.."soundOff.png" )
		soundButtonOff.x = _w-18
		soundButtonOff.y = _h-_h+18
		if (soundPlaying == false) then
			soundButtonOff.alpha = 0.5
			audio.setVolume( 0.0 )
		else
			soundButtonOff.alpha = 0.0
			audio.setVolume( musicVolume )
		end
		fgObjects_Group:insert( soundButtonOff )
		
		-----------------------------------------------------------------
		--Turn Music on or Off Button function
		-----------------------------------------------------------------
		function musicOnOff(event)
			if (event.phase == "ended") then
				if (soundPlaying==true) then
					audio.pause(bgMusic1)
					soundPlaying=false
					soundButton.alpha 		= 0.0
					soundButtonOff.alpha	= 0.5
					audio.setVolume( 0.0 )
				else
					audio.resume(bgMusic1)
					soundPlaying=true
					soundButton.alpha 		= 0.5
					soundButtonOff.alpha	= 0.0
					audio.setVolume( musicVolume )
				end
			end
		end
		-----------------------------------------------------------------
		
		-----------------------------------------------------------------
		-- Insert the Left Button
		-----------------------------------------------------------------
		leftButton = display.newImageRect( imagePath.."buttonLeft.png", 48, 48 )
		leftButton.x = 26
		leftButton.y = _h-26
		leftButton.alpha = 0.5
		fgObjects_Group:insert( leftButton )
		
		-----------------------------------------------------------------
		-- Insert the Right Button
		-----------------------------------------------------------------
		rightButton = display.newImageRect( imagePath.."buttonRight.png", 48, 48 )
		rightButton.x = 88
		rightButton.y = _h-26
		rightButton.alpha = 0.5
		fgObjects_Group:insert( rightButton )

		-----------------------------------------------------------------
		-- Insert the Fire Button
		-----------------------------------------------------------------
		fireButton = display.newImageRect( imagePath.."buttonFire.png", 48, 48 )
		fireButton.x = 396
		fireButton.y = _h-26
		fireButton.alpha = 0.5
		fgObjects_Group:insert( fireButton )
		
		-----------------------------------------------------------------
		-- Insert the Jump Button
		-----------------------------------------------------------------
		jumpButton = display.newImageRect( imagePath.."buttonJump.png", 48, 48 )
		jumpButton.x = 454
		jumpButton.y = _h-26
		jumpButton.alpha = 0.5
		fgObjects_Group:insert( jumpButton )


		-----------------------------------------------------------------
		-- Add our Hero to the main Scene (we'll put him in the Centre)
		-----------------------------------------------------------------
		local heroArea = { -8,-8, 8,-8, 8,8, -8,8 }
		local heroMaterial = { density=8.0, friction=1.0, bounce=0.0, filter=heroCollisionFilter, shape=heroArea }
		ourHero = display.newImageRect( imagePath.."hero_001.png", 20, 20 )
		ourHero.x = _w/2
		ourHero.y = _h/2
		ourHero.alpha = 1.0
		ourHero.myName = "hero"
		physics.addBody( ourHero, "dynamic", heroMaterial )
		ourHero.isFixedRotation = true 	-- we don't want our hero to be abe to ROTATE or change angle
		ourHeroObjects_Group:insert( ourHero )


		-------------------------------------------------------------------------
		-- Add Our Score, Highscore, Collected Crates Count and TARGET count
		-------------------------------------------------------------------------
		--Score - You get a POINT for every enemy you hit
		myScoreText = display.newText("Score: "..myScore, 0, 0, "HelveticaNeue-CondensedBlack", 16)
		--myScoreText:setReferencePoint(display.CenterLeftReferencePoint)
		myScoreText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		myScoreText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		myScoreText:setTextColor(255, 255, 255)
		myScoreText.x = 5
		myScoreText.y = 6
		myScoreText.alpha = 0.5
		hud_Group:insert(myScoreText)
		
		-------------------------------------------------------------------------
		--HighScore
		-------------------------------------------------------------------------
		myHighScoreText = display.newText("Highscore: "..highScore, 0, 0, "HelveticaNeue", 13)   -- (Note we first use the GLOBALLY defined HighScore value)
		--myHighScoreText:setReferencePoint(display.CenterLeftReferencePoint)
		myHighScoreText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		myHighScoreText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		myHighScoreText:setTextColor(255, 255, 255)
		myHighScoreText.x = 5
		myHighScoreText.y = 26
		myHighScoreText.alpha = 0.5
		hud_Group:insert(myHighScoreText)

		-------------------------------------------------------------------------
		--Crates Collected and Crates to Collect!
		-------------------------------------------------------------------------
		local targetCratesToCollectText = display.newText("Collect: "..targetCrates.." crates!", 0, 0, "HelveticaNeue-CondensedBlack", 16)
		--targetCratesToCollectText:setReferencePoint(display.CenterLeftReferencePoint)
		targetCratesToCollectText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		targetCratesToCollectText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		targetCratesToCollectText:setTextColor(255, 255, 255)
		targetCratesToCollectText.x = _w-160
		targetCratesToCollectText.y = 6
		targetCratesToCollectText.alpha = 0.5
		hud_Group:insert(targetCratesToCollectText)

		-------------------------------------------------------------------------
		--How many Crates collected so far?
		-------------------------------------------------------------------------
		myCollectedCratesText = display.newText("Crates Collected: "..myCollectedCrates, 0, 0, "HelveticaNeue", 13)
		--myCollectedCratesText:setReferencePoint(display.CenterLeftReferencePoint)
		myCollectedCratesText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		myCollectedCratesText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		myCollectedCratesText:setTextColor(255, 255, 255)
		myCollectedCratesText.x = _w-160
		myCollectedCratesText.y = 26
		myCollectedCratesText.alpha = 0.5
		hud_Group:insert(myCollectedCratesText)


		-----------------------------------------------------------------
		-- Insert All the Groups into the Scenes main Grouping Layer
		-- We do this so the SCENE TRANSITION can clean up properly at the end
		-----------------------------------------------------------------
		screenGroup:insert( game )
		screenGroup:insert( ourHeroObjects_Group )
		screenGroup:insert( fgObjects_Group )
		screenGroup:insert( enemiesObjects_Group )
		screenGroup:insert( hud_Group )

		
		-----------------------------------------------------------------
		-- Add event listeners to our audio button
		-----------------------------------------------------------------
		soundButton:addEventListener( "touch", musicOnOff )
		soundButtonOff:addEventListener( "touch", musicOnOff )
		

end	--END OF createScene
		
		
---------------------------------------------------------------------------------------------
-- Called immediately after scene has moved onscreen:
---------------------------------------------------------------------------------------------
function scene:show( event )
	
	-- remove previous scene's view
	composer.removeScene( "screenLevelSelect" )
	composer.removeScene( "startScreen" )
	composer.removeScene( "screenLevelComplete" )
	composer.removeScene( "screenGameOver" )

	---------------------------------------------------------------------------------------------
	-- Add Listeners to our SCENE
	---------------------------------------------------------------------------------------------
	rightButton:addEventListener( "touch", rightTouch)
	leftButton:addEventListener( "touch", leftTouch)
	fireButton:addEventListener( "touch", fireTouch)
	jumpButton:addEventListener( "touch", jumpTouch)

	---------------------------------------------------------------------------------------------
	-- Create a series of functions and transitions to create a quick SHAKE EFFECT
	-- We'll call this code when our hero DIES or fires a ROCKET
	---------------------------------------------------------------------------------------------
	--Store BG Groups x and Y's position
	originalX = bgObjects_Group.x
	originalY = bgObjects_Group.y

	shakeRightFunction1 = function(event) rightTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max), y = math.random(shakeRange.min, shakeRange.max), time = shakeTime, onComplete=shakeLeftFunction1}); end 
	shakeLeftFunction1 = function(event) leftTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max) * -1, y = math.random(shakeRange.min,shakeRange.max) * -1, time = shakeTime, onComplete=endShake1});  end 
	endShake1 = function(event) originalTrans = transition.to(game, {x = originalX, y = originalY, time = 0, onComplete=shakeRightFunction2}); end

	shakeRightFunction2 = function(event) rightTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max), y = math.random(shakeRange.min, shakeRange.max), time = shakeTime, onComplete=shakeLeftFunction2}); end 
	shakeLeftFunction2 = function(event) leftTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max) * -1, y = math.random(shakeRange.min,shakeRange.max) * -1, time = shakeTime, onComplete=endShake2});  end 
	endShake2 = function(event) originalTrans = transition.to(game, {x = originalX, y = originalY, time = 0, onComplete=shakeRightFunction3}); end

	shakeRightFunction3 = function(event) rightTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max), y = math.random(shakeRange.min, shakeRange.max), time = shakeTime, onComplete=shakeLeftFunction3}); end 
	shakeLeftFunction3 = function(event) leftTrans = transition.to(game, {x = math.random(shakeRange.min,shakeRange.max) * -1, y = math.random(shakeRange.min,shakeRange.max) * -1, time = shakeTime, onComplete=endShake});  end 
	endShake3 = function(event) originalTrans = transition.to(game, {x = originalX, y = originalY, time = 0}); end

	---------------------------------------------------------------------------------------------
	-- Run a timer every 1/4 seconds to see if there are any stray bullets to clean up
	---------------------------------------------------------------------------------------------
	 removerBulletsTimer = timer.performWithDelay(250,removeBullets,0)

	---------------------------------------------------------------------------------------------
	-- Run a timer every 1 second to see if we need to Spawn some more enemies
	-- Note the timer slowly gets faster, as more enemies have been spawned over time.
	---------------------------------------------------------------------------------------------
	spawnNewEnemyTimer = timer.performWithDelay(1000-(totalEnemiesSpawned*4),spawnEnemy,0)

	---------------------------------------------------------------------------------------------
	-- Run a timer every 1 seconds to see if we need to Spawn a new crate for our user.
	---------------------------------------------------------------------------------------------
	if (crateOnScreen == false and myCollectedCrates < targetCrates and gameOverBool == false) then
		spawnNewCrateTimer = timer.performWithDelay(1000,spawnCrate,0)
	end

end
		
---------------------------------------------------------------------------------------------
-- Called when scene is about to move offscreen:
---------------------------------------------------------------------------------------------
function scene:hide( event )
	
	---------------------------------------------------------------------------------------------
	-- Remove our Listeners from the scene when we exit. Would be nice if Corona did this for you.
	---------------------------------------------------------------------------------------------
	soundButton:removeEventListener( "touch", musicOnOff )
	soundButtonOff:removeEventListener( "touch", musicOnOff )

	rightButton:removeEventListener( "touch", rightTouch)
	leftButton:removeEventListener( "touch", leftTouch)
	fireButton:removeEventListener( "touch", fireTouch)
	jumpButton:removeEventListener( "touch", jumpTouch)
	
	Runtime:removeEventListener ( "collision", onGlobalCollision )
	Runtime:removeEventListener( "enterFrame", enemiesManager )
	Runtime:removeEventListener( "enterFrame", ourHeroManager )
		
end


---------------------------------------------------------------------------------------------
-- Called prior to the removal of scene's "view" (display group)
---------------------------------------------------------------------------------------------
function scene:destroy( event )

	---------------------------------------------------------------------------------------------
	-- Remove our Listeners from the scene when we exit. Would be nice if Corona did this for you.
	-- Note we do this here to ensure the Listeners are 100% removed.
	---------------------------------------------------------------------------------------------
	soundButton:removeEventListener( "touch", musicOnOff )
	soundButtonOff:removeEventListener( "touch", musicOnOff )

	rightButton:removeEventListener( "touch", rightTouch)
	leftButton:removeEventListener( "touch", leftTouch)
	fireButton:removeEventListener( "touch", fireTouch)
	jumpButton:removeEventListener( "touch", jumpTouch)
	
	Runtime:removeEventListener ( "collision", onGlobalCollision )
	Runtime:removeEventListener( "enterFrame", enemiesManager )
	Runtime:removeEventListener( "enterFrame", ourHeroManager )
	
end



---------------------------------------------------------------------------------------------
-- Update the score function
---------------------------------------------------------------------------------------------
local function updateTheScore()
		--Add a Point to our Score!
		myScore = myScore + 1
		if (myScore > myHighScore) then
			myHighScore = myScore
			highScore = myScore		-- Set the Global High Score variable to the new value
		end
		
		-----------------------------------------------------------------
		-- Update Score on the screen
		-----------------------------------------------------------------
		myScoreText.text = "Score: "..myScore
		--myScoreText:setReferencePoint(display.CenterLeftReferencePoint);
		myScoreText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		myScoreText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		myScoreText.x = 5

		-----------------------------------------------------------------
		-- Update the HighScore text on the screen
		-----------------------------------------------------------------
		myHighScoreText.text = "Highscore: "..myHighScore
		--myHighScoreText:setReferencePoint(display.CenterLeftReferencePoint);
		myHighScoreText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
		myHighScoreText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		myHighScoreText.x = 5
end



---------------------------------------------------------------------------------------------
--Level completed/Win code/functions
---------------------------------------------------------------------------------------------
local function levelCompletedFunctionEnd()
	gameOverBool = true
	levelCompleted = true
end 


local function doLevelCompleted()
	gameOverBool 	= true				-- set the GAME OVER FLAG to TRUE
	levelCompleted 	= true				-- set the LEVEL COMPLETE FLAG to TRUE - this means you have won the level.
	ourHeroSpeed 	= 0					-- Set our heros speed to 0 (Zero) before cleaning up.
	cleanGroups(ourHero)				-- Clear the Hero from the screen
	cleanGroups(enemiesObjects_Group)	-- Clear any Enemies from the screen
	cleanGroups(bulletsObjects_Group)	-- Clear any stray bullets from the screen
end 
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--Game over Function
---------------------------------------------------------------------------------------------
local function gameOverFunction()
	composer.gotoScene( "screenGameOver", "crossFade", 200  )
end 

---------------------------------------------------------------------------------------------
--Level Completed Function
---------------------------------------------------------------------------------------------
local function levelCompletedFunction()
	composer.gotoScene( "screenLevelComplete", "crossFade", 200  )
end 

---------------------------------------------------------------------------------------------
--Whole Game Completed Function
---------------------------------------------------------------------------------------------
local function wholeGameCompletedFunction()
	composer.gotoScene( "screenGameComplete", "crossFade", 200  )
end 

---------------------------------------------------------------------------------------------
-- Start the Game over functions
---------------------------------------------------------------------------------------------
local function gameOverFunctionStart()

	ourHeroSpeed  	= 0													-- Reset the Heros speed to 0 to stop him moving
	gameOverBool 	= true												-- Ensure the Game Over Boolean is TRUE - to stop all other scene actions.

	-- Clean up and delete some data from the screen - keep it clean.
	cleanGroups(ourHero)												-- Deletes our hero from the Group
	cleanGroups(enemiesObjects_Group)									-- Deletes all of the enemies from the Group
	cleanGroups(bulletsObjects_Group)									-- Deletes all of the bullets and any stray bullets from the Group
	cleanGroups(cratesObjects_Group)									-- Deletes any crates on the screen
	
	if (levelFailed == true) then
		-- The Hero was hit by and ENEMY or fell into the FIRE PIT
		print("GAME OVER ! ++ YOU LOST ++")								-- Report a Game Over in the terminal.
		audio.play(sfxFail) 											-- Play a failed level sound.
		timer.performWithDelay( 100, gameOverFunction )					-- Call the gameOver Function. This takes the user to a Restart/Menu Screen (after a tiny delay)
	
	elseif (levelFailed == false and levelCompleted	== true) then 		-- Its Game Over - BUT has the user completed the level or won the entire game?
	
		if (allLevelsWon == true) then									-- Has the user completed EVERY LEVEL in the game?
			-- The hero has collected every crate from ALL the levels	-- WHOLE GAME IS COMPLETED.
			print("GAME OVER ! ++ YOU WIN - EVERY LEVEL COMPLETED :-)")	-- Report a Game Over [WON ALL LEVELS] in the terminal.
			audio.play(sfxVictory) 										-- Play a Game Victory Sound
			timer.performWithDelay( 100, wholeGameCompletedFunction )	-- Call the gameOver Function. This takes the user to a Restart/Menu Screen (after a tiny delay)
		else
			-- The Hero was completed the current level - start NEXT level
			print("GAME OVER ! ++ LEVEL ["..level.."] completed!")		-- Report a Game Over [LEVEL COMPLETED] in the terminal.
			print("Prepare to play Level ["..nextLevel.."].")			-- Report preparing next level in the terminal.
			audio.play(sfxLevelWon) 									-- Play a Level Won sound.
			timer.performWithDelay( 100, levelCompletedFunction )		-- Call the gameOver Function. This takes the user to a Restart/Menu Screen (after a tiny delay)
		end
		
	end
	
end 


---------------------------------------------------------------------------------------------
--Game Collision logic system
---------------------------------------------------------------------------------------------
local function onGlobalCollision( event )

	if ( event.phase == "began" and gameOverBool==false ) then
	
		--print( "Global report: " .. event.object1.myName .. " & " .. event.object2.myName .. " collision began" )

		-----------------------------------------------------------------
		--Check if our Hero is on a platform - If he is then ALLOW him to jump .... or her :-)
		-----------------------------------------------------------------
		linearVelocityX, linearVelocityY = ourHero:getLinearVelocity()
		if (event.object1.myName == "platform" and event.object2.myName == "hero" and linearVelocityY > 0 ) then
			ourHeroCanJump = true
		end
		if (event.object1.myName == "hero" and event.object2.myName == "platform" and linearVelocityY > 0 ) then
			ourHeroCanJump = true
		end
		-----------------------------------------------------------------
		--Check if our Hero hits a wall - we'll apply a SmaLL force in the opposite direction to help avoid Sticking!
		-----------------------------------------------------------------
		if (event.object1.myName == "wallRight" and event.object2.myName == "hero") then
			ourHero:applyLinearImpulse(-0.3, 0, ourHero.x, ourHero.y)
			ourHero.x=ourHero.x-3
		end
		if (event.object1.myName == "wallLeft" and event.object2.myName == "hero") then
			ourHero:applyLinearImpulse(0.3, 0, ourHero.x, ourHero.y)
			ourHero.x=ourHero.x-3
		end
		
		-----------------------------------------------------------------
		--Check if our Hero has fallen into the Pit - Game Over!
		-----------------------------------------------------------------
		if (event.object1.myName == "firepit" and event.object2.myName == "hero") then
			gameOverBool 		= true
			levelFailed 		= true
			levelCompleted		= false
			timer.performWithDelay( 100, gameOverFunctionStart )
		end
		if (event.object1.myName == "hero" and event.object2.myName == "firepit") then
			gameOverBool 		= true
			levelFailed 		= true
			levelCompleted		= false
			timer.performWithDelay( 100, gameOverFunctionStart )
		end
		-----------------------------------------------------------------
		--Check if our Hero has been hit by an Enemy.
		-----------------------------------------------------------------
		if (event.object1.myName == "enemy" and event.object2.myName == "hero" and cheatModeOn == false) then
			gameOverBool 		= true
			levelFailed 		= true
			levelCompleted		= false
			shakeRightFunction1()	--Shake the Screen
			timer.performWithDelay( 100, gameOverFunctionStart )
		end
		if (event.object1.myName == "hero" and event.object2.myName == "enemy" and cheatModeOn == false) then
			gameOverBool 		= true
			levelFailed 		= true
			levelCompleted		= false
			shakeRightFunction1()	--Shake the Screen
			timer.performWithDelay( 100, gameOverFunctionStart )
		end
		-----------------------------------------------------------------
		--Check if our Hero has collected a crate.
		-----------------------------------------------------------------
		local function destroyCollectedCrate(myCrateKill)
			myCrateKill:removeSelf()
			myCrateKill.object1=nil
			myCollectedCrates = myCollectedCrates + 1
			
			-- Update the Score and HighScore texts on the screen
			myCollectedCratesText.text = "Crates Collected: "..myCollectedCrates
			--myCollectedCratesText:setReferencePoint(display.CenterLeftReferencePoint);
			myCollectedCratesText.anchorX = 0.0		-- Graphics 2.0 Anchoring method
			myCollectedCratesText.anchorY = 0.5		-- Graphics 2.0 Anchoring method
			myCollectedCratesText.x = _w-160
		end
		
		if (event.object1.myName == "crate" and event.object2.myName == "hero" ) then
			crateOnScreen 		= false
			bulletType 			= event.object1.myType
			audio.play(sfxCollect)
			timer.performWithDelay( 20, destroyCollectedCrate(event.object1) )
		end
		
		if (event.object1.myName == "hero" and event.object2.myName == "crate" ) then
			crateOnScreen 		= false
			bulletType 			= event.object2.myType
			audio.play(sfxCollect)
			timer.performWithDelay( 20, destroyCollectedCrate(event.object2) )
		end

		-- See if our NEW crate has fallen into the FirePit - if so just create another one :-)
		if (event.object1.myName == "crate" and event.object2.myName == "firepit" ) then
			crateOnScreen 		= false
			myCollectedCrates = myCollectedCrates - 1
			timer.performWithDelay( 20, destroyCollectedCrate(event.object1) )
		end
		if (event.object1.myName == "firepit" and event.object2.myName == "crate" ) then
			crateOnScreen 		= false
			myCollectedCrates = myCollectedCrates - 1
			timer.performWithDelay( 20, destroyCollectedCrate(event.object2) )
		end



		-----------------------------------------------------------------
		--Cleanup our Bullets if they hit a WALL, PLATFORM or PIT
		-----------------------------------------------------------------
		if (event.object1.myName == "wallLeft" and event.object2.myName == "bullet" ) then
			display.remove( event.object2 )
			event.object2=nil
		end
		if (event.object1.myName == "wallRight" and event.object2.myName == "bullet" ) then
			display.remove( event.object2 )
			event.object2=nil
		end
		
		-----------------------------------------------------------------
		--Check if the enemies touch a WALL - if they do - switch their direction
		-----------------------------------------------------------------
		if (event.object1.myName == "enemy"  and event.object2.myName == "wallLeft") then
			event.object1.enemyDirection = 1
			event.object1.xScale = 1
			event.object1:applyLinearImpulse(0.3, 0, event.object1.x, event.object1.y)
		elseif (event.object1.myName == "enemy"  and event.object2.myName == "wallRight") then
			event.object1.enemyDirection = -1
			event.object1.xScale = -1
			event.object1:applyLinearImpulse(-0.3, 0, event.object1.x, event.object1.y)
		end
		if (event.object1.myName == "wallLeft"  and event.object2.myName == "enemy") then
			event.object2.enemyDirection = 1
			event.object2.xScale = 1
			event.object2:applyLinearImpulse(0.3, 0, event.object2.x, event.object2.y)
		elseif (event.object1.myName == "wallRight"  and event.object2.myName == "enemy") then
			event.object2.enemyDirection = -1
			event.object2.xScale = -1
			event.object2:applyLinearImpulse(-0.3, 0, event.object2.x, event.object2.y)
		end
		
		
		-----------------------------------------------------------------
		--ENEMY hit by a BULLET - reduce the enemies hit count
		-----------------------------------------------------------------
		if (event.object1.myName == "enemy"  and event.object2.myName == "bullet") then
			-- Deduct a POINT from the enemies HIT COUNTER
			event.object1.hitCount = event.object1.hitCount-1
			
			display.remove( event.object2 )
			event.object2=nil

			--Mark the Enemy as being HIT - we need to check to see if we have met the enemies HIT MAX counter
			if (event.object1.hitCount == 0) then
				event.object1.destroy 			= true
				event.object1.enemyDirection 	= 0
				audio.play(sfxKill)
				updateEnemeyHit(event.object1)	-- We send a call to a function to do the actual Enemy Removal from Screen & Memory.
				updateTheScore()
			end
		end

		-----------------------------------------------------------------
		--ENEMY hit by a ROCKET - reduce the enemies hit count to 0
		-----------------------------------------------------------------

		if event.object1 ~= nil and event.object2 ~= nil then

			if (event.object1.myName == "enemy"  and event.object2.myName == "rocket") then
				-- Deduct a POINT from the enemiesSpawnedTable HIT COUNTER
				event.object1.hitCount 			= 0
				event.object1.destroy 			= true
				event.object1.enemyDirection 	= 0
				audio.play(sfxKill)
				updateEnemeyHit(event.object1)	-- We send a call to a function to do the actual Enemy Removal from Screen & Memory.
				updateTheScore()
			end


			if (event.object1.myName == "rocket"  and event.object2.myName == "enemy") then
				-- Deduct a POINT from the enemies HIT COUNTER
				event.object2.hitCount 			= 0
				event.object2.destroy 			= true
				event.object2.enemyDirection 	= 0
				audio.play(sfxKill)
				updateEnemeyHit(event.object2)	-- We send a call to a function to do the actual Enemy Removal from Screen & Memory.
				updateTheScore()
			end

			-----------------------------------------------------------------
			--ENEMY in the PIT - kill
			-----------------------------------------------------------------
			if (event.object1.myName == "enemy"  and event.object2.myName == "killEnemy") then
				event.object1.hitCount 			= 0
				event.object1.destroy 			= true
				event.object1.enemyDirection 	= 0
				audio.play(sfxKill)
				updateEnemeyHit(event.object1)	-- We send a call to a function to do the actual Enemy Removal from Screen & Memory.
			end
			
			if (event.object1.myName == "killEnemy"  and event.object2.myName == "enemy") then
				-- Prepare the enemy to be killed
				event.object2.hitCount 			= 0
				event.object2.destroy 			= true
				event.object2.enemyDirection 	= 0
				audio.play(sfxKill)
				updateEnemeyHit(event.object2)	-- We send a call to a function to do the actual Enemy Removal from Screen & Memory.
			end

	end

		
	elseif ( event.phase == "ended" and gameOverBool==false) then
	
		if (event.object1.myName == "platform" and event.object2.myName == "hero") then
			ourHeroCanJump = false
		end 

	end
	
	
end

----------------------------------------------------------------------------------------------
-- Spawn Bullets: These functions also control the Powerups and the Speed of the shots.
----------------------------------------------------------------------------------------------z
function spawnBulletsFunction(event)
        -- Spawn a new bullet
        
        -- [1] Single Shot
        if (bulletType == 1) then
			if event.time - timeLastBullet >= bulletInterval then
				
				local bullet = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet.contentWidth/2)+2
				bullet.x = ourHero.x
				bullet.y = getYPos
	
				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet.width/2 }
				physics.addBody(bullet, "dynamic", bulletMaterial)
				bullet.myName = "bullet"
				bullet.isBullet = true
				bulletsObjects_Group:insert(bullet)
				
				audio.play(sfxGun)
				
				-- Move the Bullet in the correct Direction
				if (ourHeroDirection == "Left") then
					transition.to(bullet, {time = 800, x = -bullet.contentWidth-60, y=getYPos})	--Fire the Single shot bullet LEFT
				elseif (ourHeroDirection == "Right") then
					transition.to(bullet, {time = 800, x = _w+60, y=getYPos}) 					--Fire the Single shot bullet RIGHT
				end
	
				timeLastBullet = event.time
			end	
		end

        -- [2] Double Shot
		if (bulletType == 2) then
			if event.time - timeLastBullet >= bulletInterval then
				
				local bullet = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet.contentWidth/2)+2
				bullet.x = ourHero.x
				bullet.y = getYPos
	
				local bullet2 = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet2.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet2.contentWidth/2)+2
				bullet2.x = ourHero.x
				bullet2.y = getYPos

				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet.width/2 }
				physics.addBody(bullet, "dynamic", bulletMaterial)
				bullet.myName = "bullet"
				bullet.isBullet = true
				bullet.isSensor = true
				bulletsObjects_Group:insert(bullet)
				
				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet2.width/2 }
				physics.addBody(bullet2, "dynamic", bulletMaterial)
				bullet2.myName = "bullet"
				bullet2.isBullet = true
				bullet2.isSensor = true
				bulletsObjects_Group:insert(bullet2)

				audio.play(sfxGun)
				
				transition.to(bullet,  {time = 800, x = -bullet.contentWidth-60, y=getYPos})
				transition.to(bullet2, {time = 800, x = _w+60, y=getYPos})
	
				timeLastBullet = event.time
			end	
		end

        -- [3] Triple Shot
		if (bulletType == 3) then
			if event.time - timeLastBullet >= bulletInterval then
				
				local bullet = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet.contentWidth/2)+2
				bullet.x = ourHero.x
				bullet.y = getYPos
	
				local bullet2 = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet2.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet2.contentWidth/2)+2
				bullet2.x = ourHero.x
				bullet2.y = getYPos

				local bullet3 = display.newImageRect(imagePath.."bullet_001.png",10,10)
				local getYPos = ourHero.y - (bullet3.contentHeight/2)+2
				local getXPos = ourHero.x - (bullet3.contentWidth/2)+2
				bullet3.x = ourHero.x
				bullet3.y = getYPos

				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet.width/2 }
				physics.addBody(bullet, "dynamic", bulletMaterial)
				bullet.myName = "bullet"
				bullet.isBullet = true
				bullet.isSensor = true
				bulletsObjects_Group:insert(bullet)
				
				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet2.width/2 }
				physics.addBody(bullet2, "dynamic", bulletMaterial)
				bullet2.myName = "bullet"
				bullet2.isBullet = true
				bullet2.isSensor = true
				bulletsObjects_Group:insert(bullet2)

				local bulletMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter, radius=bullet3.width/2 }
				physics.addBody(bullet3, "dynamic", bulletMaterial)
				bullet3.myName = "bullet"
				bullet3.isBullet = true
				bullet3.isSensor = true
				bulletsObjects_Group:insert(bullet3)

				audio.play(sfxGun)
				
				transition.to(bullet,  {time = 800, x = -bullet.contentWidth-60, y=getYPos})
				transition.to(bullet2, {time = 800, x = _w+60, y=getYPos})
				transition.to(bullet3, {time = 800, x = getXPos, y=-100})

				timeLastBullet = event.time
			end	
		end

        -- [4] Rocket !!
        if (bulletType == 4) then
			if event.time - timeLastBullet >= rocketInterval then
				
				local rocket = display.newImageRect(imagePath.."rocket_001.png",30,20)
				local getYPos = ourHero.y - (rocket.contentHeight/2)+2
				local getXPos = ourHero.x - (rocket.contentWidth/2)+2
				rocket.x = ourHero.x
				rocket.y = getYPos
	
				local rocketMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=bulletCollisionFilter }
				physics.addBody(rocket, "dynamic", rocketMaterial)
				rocket.myName = "rocket"
				rocket.isBullet = true
				rocket.isFixedRotation = true 	-- we don't want our Rocket to be abe to ROTATE or change angle
				bulletsObjects_Group:insert(rocket)
				
				audio.play(sfxGun2)
				shakeRightFunction1()	--Shake the Screen when a Rocket is Fired!
				
				-- Move the Rocket in the correct Direction
				if (ourHeroDirection == "Left") then
					rocket.xScale = -1
					transition.to(rocket, {time = 800, x = -rocket.contentWidth-60, y=getYPos})
				elseif (ourHeroDirection == "Right") then
					rocket.xScale = 1
					transition.to(rocket, {time = 800, x = _w+60, y=getYPos})
				end
	
				timeLastBullet = event.time
			end	
		end
		
end

----------------------------------------------------------------------------------------------
-- Loop through the bullets, removing those off screen
----------------------------------------------------------------------------------------------
function removeBullets()
	if (bulletsObjects_Group.numChildren ~= nil ) then
		for i = bulletsObjects_Group.numChildren, 1, -1 do 	-- check the display objects in the group
			local bullet = bulletsObjects_Group[i] 			-- performance: getting a local ref to an obj in a table is quicker than referencing table
			if ( bullet.x < 0 or bullet.x > _w or bullet.y < 0 or bullet.y > _h )  then
				display.remove( bullet )
				bullet=nil
				--print("Bullet/Rocket Removed from memory")
			end
		end
	end
end

----------------------------------------------------------------------------------------------
-- Spawn new enemies - assigning them their attributes, also we'll randomly choose each enemy
----------------------------------------------------------------------------------------------
function spawnEnemy()

	if (gameOverBool == false and enemiesOnScreen < maxEnemiesOnScreen) then
        
        -- Select and define our enemy using a random range - also set the enemies speed based on its type.
        local enemyRandomizer = math.random(1, 30)
        if (enemyRandomizer > 10) then
        	enemyType = 1
        	enemySpeeder = 0.5
        elseif (enemyRandomizer > 5 and enemyRandomizer < 10) then
        	enemyType = 2
        	enemySpeeder = 0.1
        elseif (enemyRandomizer < 5) then
        	enemyType = 3
        	enemySpeeder = 0
		end

		-- Set up a RANDOM Start direction for each newly spawned enemy (Left or Right).
        local enemyDirectinGetter = math.random(1, 2)
        
        local enemy = display.newImage(imagePath.."enemy_00"..enemyType..".png")
        enemy.x 					= _w/2				-- Define the start X Position for our enemy (Centre of Horizontal)
        enemy.y 					= 20				-- Define the start Y Position for our enemy (20 Pixels from the top)
        enemy.myName 				= "enemy"			-- Give our enemy a name - we'll use this in the collision event to detect a hit
        enemy.hitCount 				= enemyType + 1		-- How many hits this enemy needs to be killed.
        enemy.enemySpeed 			= (ourHeroSpeed-2) + enemySpeeder --Speed will increment over time to make it harder!
        enemy.inPit 				= false				-- Set a variable to declare our enemy IS NOT in the Fire Pit
        enemy.destroy 				= false				-- Set a variable to declare our enemy has NOT YET been destroyed
        
        if (enemyDirectinGetter == 2) then
			enemy.enemyDirection 	= -1			-- [LEFT] Set a variable within the enemy, we'll use this later to detect if he's hit a wall
			enemy.xScale 			= -1			-- If he's facing left - Flip our Sprite over.
			enemy.x 				= enemy.x - (enemy.enemySpeed + (totalEnemiesSpawned/100))
		else
			enemy.enemyDirection 	= 1				-- [RIGHT] Set a variable within the enemy, we'll use this later to detect if he's hit a wall
			enemy.xScale 			= 1				-- If he's facing Right - maintain the sprites original x orientation
			enemy.x 				= enemy.x + (enemy.enemySpeed + (totalEnemiesSpawned/100))
		end
		
		local squareEnemySize = (enemy.contentWidth/2)-2	--We're going to define a hit zone slightly smaller than our square enemies (which are all square)
		local enemyArea = { -squareEnemySize,-squareEnemySize, squareEnemySize,-squareEnemySize, squareEnemySize,squareEnemySize, -squareEnemySize,squareEnemySize }
		local enemyMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=enemyCollisionFilter, shape=enemyArea }

        physics.addBody( enemy, "dynamic", enemyMaterial  )
		enemy.isFixedRotation 		= true 						-- we don't the enemy to be abe to ROTATE or change angle
        enemy.isSleepingAllowed 	= false 					-- we don't the Physics engine to let our enemy sleep
		enemy:applyLinearImpulse(0, 2, enemy.x, enemy.y)  		--Push our new Enemy DOWN as he is spawned..

		-- Put the newly created Enemy and all its attributes into our Table.
        enemiesSpawnedTable[#enemiesSpawnedTable + 1] = enemy	--Increment the Table pointer by one, then add all of the enemy details into it.					
        enemiesOnScreen 			= enemiesOnScreen + 1		-- Keep a count of how many enemies their are on the screen (restrict the Max enemies)
		totalEnemiesSpawned 		= totalEnemiesSpawned + 1	-- Keep a FULL COUNT of all enemies, we'll use the value to determine the SPEED of each NEW enemy.

		--Insert the NEW enemy into the enemies Group.
		enemiesObjects_Group:insert(enemy)
	
	end

end


----------------------------------------------------------------------------------------------
-- Spawn new Crate - assigning them their attributes, also we'll randomly choose each crate type
----------------------------------------------------------------------------------------------
function spawnCrate()

	if (crateOnScreen == false and myCollectedCrates < targetCrates and gameOverBool == false) then

        local crateType = math.random(1, 4)		-- Select a Random number between 1 and 4 (Each crate has a different power up)
        local crate = display.newImage(imagePath.."crate_00"..crateType..".png",48,48)
        crate.x = math.random(40, _w-40)
        crate.y = math.random(34, 245)
        crate.myName = "crate"
		crate.myType = crateType -- The crate Type is which power up the user gets when they collect it.

		--We just define a small area around the crate graphic to receive collisions.
		local crateArea = { -8,7, 8,7, 8, 21, -8, 21 } 
		local crateMaterial = { density=10.0, friction=1.0, bounce=0.0, filter=crateCollisionFilter, shape=crateArea }

        physics.addBody( crate, "dynamic", crateMaterial  )
		crate.isFixedRotation 	= true 	-- we don't the crate to be abe to ROTATE or change angle
        crate.isSleepingAllowed = false
        
        crateOnScreen 			= true	-- Declare to the GAME that their is a Crate on the screen - this stops MORE crates being spawned.

		--Insert the NEW CRATE into the crate Group.
		cratesObjects_Group:insert(crate)
	
	end

end

----------------------------------------------------------------------------------------------
-- A function to remove Hit enemies - this is called from the collision events functions
----------------------------------------------------------------------------------------------
function updateEnemeyHit(tagEnemy)
	table.insert(enemiesToRemoveTable, tagEnemy)
	enemiesOnScreen = enemiesOnScreen - 1
end

----------------------------------------------------------------------------------------------
-- The control manager for the enemies
----------------------------------------------------------------------------------------------
function enemiesManager(event)
	
	if (gameOverBool == false) then
	
		-- Loop through all the enemies to delete!
		for i = 1, #enemiesToRemoveTable do
			enemiesToRemoveTable[i].parent:remove(enemiesToRemoveTable[i])
			enemiesToRemoveTable[i] = nil
		end

		-- Loop through all of our enemiesSpawnedTable and control there MOVEMENT
		for i2 = 1, #enemiesSpawnedTable,1 do
			-- We are going to ensure they are all moving in the correct direction and speed, based on there 'enemyDirection' variable
			if (enemiesSpawnedTable[i2].enemyDirection == -1) then					-- Enemy Left
				enemiesSpawnedTable[i2].x = enemiesSpawnedTable[i2].x - enemiesSpawnedTable[i2].enemySpeed
			elseif (enemiesSpawnedTable[i2].enemyDirection == 1) then				-- Enemy Right
				enemiesSpawnedTable[i2].x = enemiesSpawnedTable[i2].x + enemiesSpawnedTable[i2].enemySpeed
			end
		end	
		
	end
	
end


----------------------------------------------------------------------------------------------
-- The control manager for our ourHero/Hero
----------------------------------------------------------------------------------------------
function ourHeroManager(event)
	
	if (gameOverBool == false) then
	
	--Check our Heros Velocity
		linearVelocityX, linearVelocityY = ourHero:getLinearVelocity()
	
		--Detect firing for continuos shooting
		if ourHeroFireBullet == true then
		  spawnBulletsFunction(event)
		end
	
		--Make our Hero Jump
		if (ourHeroJump == true and ourHeroCanJump == true and linearVelocityY==0) then
			ourHero:applyLinearImpulse(0, ourHeroJumpForce, ourHero.x, ourHero.y)
			audio.play(sfxJump) --Play a Jump Sound
			ourHeroJump = false
			ourHeroCanJump = false
		end
		
		--Turn and move LEFT
		if (ourHeroLeft == true) then
			ourHero.xScale = -1		--Note: -1 Flips our Hero Horizontally
			ourHero.x = ourHero.x - ourHeroSpeed
			ourHeroRight = false
		end
		
		--Turn and move RIGHT
		if (ourHeroRight == true) then
			ourHero.xScale = 1		--Note: 1 Flips our Hero back Horizontally
			ourHero.x = ourHero.x + ourHeroSpeed
			ourHeroLeft = false
		end
		
		-----------------------------------------------------------------
		--Check if our Hero has collected all of the crates.
		-----------------------------------------------------------------
		if (myCollectedCrates == targetCrates ) then
			gameOverBool 		= true
			levelFailed 		= false
			levelCompleted		= true
			
			-- Here we increment the 'next' level counter to the CURRENT LEVEL + 1.
			-- if it's not greater than the MAX LEVELS, we load the value to the next level variable.
			nextLevel = level + 1
			
			--SAVE the level data to the users device!
			saveDataTable.levelReached = nextLevel
			loadsave.saveTable(saveDataTable, "crateboydba.json")

			
			-- Has the user completed every single level?
			if (nextLevel > maxLevels) then
				allLevelsWon = true
				level 		= maxLevels
				nextLevel 	= maxLevels
				
				--SAVE the level data to the users device!
				saveDataTable.levelReached = nextLevel
				loadsave.saveTable(saveDataTable, "crateboydba.json")

			end	
			timer.performWithDelay( 100, gameOverFunctionStart )
		end

	end


end


----------------------------------------------------------------------------------------------------
-- Manage our UI Buttons in the Game
-- We've set these functions up to just to TOGGLE BOOLEAN variables which we'll listen
-- for within the games main tick cycle.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--FIRE Button
----------------------------------------------------------------------------------------------------
function fireTouch(event)
	if(event.phase == "began" and gameOverBool == false) then
		ourHeroFireBullet = true
		fireButton.alpha = 1.0	-- Change Alpha of button to show a Touch
	elseif(event.phase == "ended") then
		ourHeroFireBullet = false
		fireButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	end
end

----------------------------------------------------------------------------------------------------
--JUMP Button
----------------------------------------------------------------------------------------------------
function jumpTouch(event)
	if(event.phase == "began" and gameOverBool == false) then
		ourHeroJump = true
		jumpButton.alpha = 1.0	-- Change Alpha of button to show a Touch
	elseif(event.phase == "ended") then
		ourHeroJump = false
		jumpButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	end
end

----------------------------------------------------------------------------------------------------
--GO LEFT Button
----------------------------------------------------------------------------------------------------
function leftTouch(event)
	if(event.phase == "began" and gameOverBool == false) then
		ourHeroLeft = true
		ourHeroRight = false
		ourHeroDirection = "Left"
		leftButton.alpha = 1.0	-- Change Alpha of button to show a Touch
	elseif(event.phase == "ended") then
		ourHeroLeft = false
		leftButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	end
end

----------------------------------------------------------------------------------------------------
--GO RIGHT Button
----------------------------------------------------------------------------------------------------
function rightTouch(event)
	if(event.phase == "began" and gameOverBool == false) then
		ourHeroRight = true
		ourHeroLeft = false
		ourHeroDirection = "Right"
		rightButton.alpha = 1.0	-- Change Alpha of button to show a Touch
	elseif(event.phase == "ended") then
		ourHeroRight = false
		rightButton.alpha = 0.5	-- Change Alpha of button to show a Touch
  end
end
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-- Use keyboard input: CURSOR Left, Right, Up (Jump), Space to fire.
----------------------------------------------------------------------------------------------------
local function onKeyEvent( event )
    -- Print which key was pressed down/up
    local message = "Key '" .. event.keyName .. "' was pressed " .. event.phase
    --print( message )


    if ( event.keyName == "right" ) then
		if(event.phase == "down" and gameOverBool == false) then
			ourHeroRight = true
			ourHeroLeft = false
			ourHeroDirection = "Right"
			rightButton.alpha = 1.0	-- Change Alpha of button to show a Touch
		elseif(event.phase == "up") then
			ourHeroRight = false
			rightButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	  	end
	end

    if ( event.keyName == "left" ) then
		if(event.phase == "down" and gameOverBool == false) then
			ourHeroLeft = true
			ourHeroRight = false
			ourHeroDirection = "Left"
			leftButton.alpha = 1.0	-- Change Alpha of button to show a Touch
		elseif(event.phase == "up") then
			ourHeroLeft = false
			leftButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	  	end
	end

    if ( event.keyName == "up" ) then
		if(event.phase == "down" and gameOverBool == false) then
			ourHeroJump = true
			jumpButton.alpha = 1.0	-- Change Alpha of button to show a Touch
		elseif(event.phase == "up") then
			ourHeroJump = false
			jumpButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	  	end
	end

    if ( event.keyName == "space" ) then
		if(event.phase == "down" and gameOverBool == false) then
			ourHeroFireBullet = true
			fireButton.alpha = 1.0	-- Change Alpha of button to show a Touch
		elseif(event.phase == "up") then
			ourHeroFireBullet = false
			fireButton.alpha = 0.5	-- Change Alpha of button to show a Touch
	  	end
	end



    -- If the "back" key was pressed on Android or Windows Phone, prevent it from backing out of the app
    --[[
    if ( event.keyName == "back" ) then
        local platformName = system.getInfo( "platformName" )
        if ( platformName == "Android" ) or ( platformName == "WinPhone" ) then
            return true
        end
    end
	--]]

    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end




---------------------------------------------------------------------------------
-- END OF SCENE IMPLEMENTATION
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


---------------------------------------------------------------------------------
-- Start the MAIN GAMES Runtime events. Remember to end all events on the exit scene.
---------------------------------------------------------------------------------
Runtime:addEventListener ( "collision", onGlobalCollision )
Runtime:addEventListener( "enterFrame", ourHeroManager )
Runtime:addEventListener( "enterFrame", enemiesManager )

-- Add the key event listener
Runtime:addEventListener( "key", onKeyEvent )

return scene