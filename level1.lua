module(..., package.seeall)

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
-- level1.lua
--
------------------------------------------------------------------------------------------------------------------------------------
-- 20th Feb 2014
-- Version 4.0
-- Requires Corona 2013.2076 - minimum
------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------
-- Level 1
---------------------------------------------------------------------------
-- Assign how many crates the user must collect in this level to complete the stage
local level1_TargetCrates	 = 3

---------------------------------------------------------------------------
-- Build more scenes using the GUMBO tool, then use the co-ordinates of the obstacles
-- www.nerderer.com
---------------------------------------------------------------------------
	
	--Define our collision filters
	local platformsCollisionFilter 	= { categoryBits = 1, maskBits = 71 } 
	local firePitCollisionFilter 	= { categoryBits = 32, maskBits = 110 } 
	local rightWallCollisionFilter 	= { categoryBits = 16, maskBits = 86 } 
	local leftWallCollisionFilter 	= { categoryBits = 16, maskBits = 86 } 
	
	-----------------------------------------------------------------
	-- Setup the Background for this level
	-- Note: the [bgObjects_Group] is defined in the manGameInterface lua file.
	-----------------------------------------------------------------
	local bgImageSprite = display.newImageRect( imagePath.."background_001.png", 480, 320 )
	bgImageSprite.x = _w/2
	bgImageSprite.y = _h/2
	--bgImageSprite.alpha = 0.7
	bgObjects_Group:insert( bgImageSprite )
	
	--Add a grungy overlay to the background image
	local bgImageClouds = display.newImageRect( imagePath.."background_overlay.png", 480, 320 )
	bgImageClouds.x = _w/2
	bgImageClouds.y = _h/2
	bgObjects_Group:insert( bgImageClouds )

	-----------------------------------------------------------------
	-- Add the background scenery
	-----------------------------------------------------------------
	local function addScenery(x ,y, sizeX, sizeY, angle, pngImageName)
		--We don't want any PHYSICS on the background scenery.
		--local sceneryCollisionFilter = { categoryBits = 2, maskBits = 3 } 
		--local sceneryMaterial = { density=100.0, friction=0.1, bounce=0.2, filter=riggingCollisionFilter }
		local newScenery = display.newImageRect( imagePath..pngImageName..".png", sizeX, sizeY )
		newScenery.x = x
		newScenery.y = y
		newScenery.rotation = angle
		newScenery.myName = "myScenery"
		--physics.addBody( newScenery, "static", sceneryCollisionFilter )		--No Physics for Scenery
		bgObjects_Group:insert( newScenery )
		
	end
	-- addScenery(X, Y, W, H, A, "NAME")
	addScenery(183, 72, 86, 44, 0, "scenery_001")
	addScenery(319, 73, 56, 48, 0, "scenery_002")
	addScenery(71, 133, 56, 58, 0, "scenery_003")
	addScenery(110, 144, 12, 40, 0, "scenery_004")
	addScenery(252, 203, 12, 40, 0, "scenery_004")
	addScenery(196, 210, 42, 34, 0, "scenery_005")
	addScenery(39, 270, 42, 34, 0, "scenery_005")
	addScenery(391, 274, 30, 34, 0, "scenery_006")
	addScenery(311, 291, 30, 34, 0, "scenery_006")
	addScenery(191, 289, 30, 34, 0, "scenery_006")
	addScenery(401, 149, 30, 34, 0, "scenery_006")
	addScenery(233, 210, 14, 34, 0, "scenery_007")
	addScenery(151, 289, 14, 34, 0, "scenery_007")
	addScenery(456, 145, 32, 34, 0, "scenery_008")
	addScenery(296, 206, 32, 34, 0, "scenery_008")
	addScenery(443, 267, 50, 34, 0, "scenery_009")
	-----------------------------------------------------------------

	-----------------------------------------------------------------
	-- Add the Platforms
	-----------------------------------------------------------------
	local function addPlatforms(x ,y, sizeX, sizeY, angle, pngImageName, info)
		local platformsMaterial = { density=100.0, friction=0.1, bounce=0.0, filter=platformsCollisionFilter }
		local newPlatform = display.newImageRect( imagePath..pngImageName..".png", sizeX, sizeY )
		newPlatform.x = x
		newPlatform.y = y
		newPlatform.rotation = angle
		newPlatform.myName = info
		physics.addBody( newPlatform, "static", platformsMaterial )
		bgObjects_Group:insert( newPlatform )
		
	end
	addPlatforms(250, 99, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(250, 227, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(104, 310, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(396, 310, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(486, 290, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(14, 290, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(14, 168, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(486, 168, 228, 20, 0, 		"blockLong_001", "platform")
	addPlatforms(103, 10, 228, 20, 180, 	"blockLong_001", "platform")
	addPlatforms(401, 10, 228, 20, 180, 	"blockLong_001", "platform")
	addPlatforms(245, -10, 228, 20, 180, 	"blockLong_001", "platform")
	
	--These last three platforms are UNDER the fire pit to catch our baddies!
	addPlatforms(256, 373, 228, 20, 180, 	"blockLong_001", "killEnemy")
	addPlatforms(186, 434, 228, 20, 90, 	"blockLong_001", "killEnemy")
	addPlatforms(320, 434, 228, 20, 90, 	"blockLong_001", "killEnemy")
	-----------------------------------------------------------------

	-----------------------------------------------------------------
	-- Add the Fire Pit
	-----------------------------------------------------------------
	local function addFirePit(x ,y, sizeX, sizeY, angle, pngImageName)
		local firePitMaterial = { density=2.0, friction=0.1, bounce=0.2, filter=firePitCollisionFilter }
		local firePit = display.newImageRect( imagePath..pngImageName..".png", sizeX, sizeY )
		firePit.x = x
		firePit.y = y
		firePit.rotation = angle
		firePit.myName = "firepit"
		physics.addBody( firePit, "static", firePitMaterial )
		firePit.isSensor = true
		bgObjects_Group:insert( firePit )
		
	end
	addFirePit(250, 318, 64, 28, 0, "firePit_001")

	-----------------------------------------------------------------
	-- Add the Left Wall
	-----------------------------------------------------------------
	local function addLeftWall(x ,y, sizeX, sizeY, angle, pngImageName)
		local leftWallMaterial = { density=100.0, friction=0.1, bounce=1.5, filter=leftWallCollisionFilter }
		local leftWall = display.newRect( 0,0, sizeX, sizeY )
		leftWall.x = x
		leftWall.y = y
		--leftWall:setReferencePoint(display.CenterRightReferencePoint);
		leftWall.anchorX = 0.5		-- Graphics 2.0 Anchoring method
		leftWall.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		leftWall:setFillColor(0, 0, 0)
		--leftWall:setFillColor(140, 40, 40)
		leftWall.rotation = angle
		--leftWall.alpha = 0.7
		leftWall.rotation = angle
		leftWall.myName = "wallLeft"
		physics.addBody( leftWall, "static", leftWallMaterial )
		bgObjects_Group:insert( leftWall )
		
	end
	addLeftWall(-40, 159, 100, 347, 0, "NA")

	-----------------------------------------------------------------
	-- Add the Right Wall
	-----------------------------------------------------------------
	local function addRightWall(x ,y, sizeX, sizeY, angle, pngImageName)
		local rightWallMaterial = { density=2.0, friction=0.1, bounce=1.5, filter=rightWallCollisionFilter }
		local rightWall = display.newRect( 0,0, sizeX, sizeY )
		rightWall.x = x
		rightWall.y = y
		--rightWall:setReferencePoint(display.CenterLeftReferencePoint);
		rightWall.anchorX = 0.5		-- Graphics 2.0 Anchoring method
		rightWall.anchorY = 0.5		-- Graphics 2.0 Anchoring method
		rightWall:setFillColor(0, 0, 0)
		--rightWall:setFillColor(140, 40, 40)
		rightWall.rotation = angle
		--rightWall.alpha = 0.7
		rightWall.myName = "wallRight"
		physics.addBody( rightWall, "static", rightWallMaterial )
		bgObjects_Group:insert( rightWall )
		
	end
	addRightWall(_w+40, 159, 100, 347, 0, "NA")
	addRightWall(240, -30, 500, 30, 0, "NA")  -- This is a wall for the TOP of the screen - we'll use it to clean up any stray bullets!

return level1_TargetCrates