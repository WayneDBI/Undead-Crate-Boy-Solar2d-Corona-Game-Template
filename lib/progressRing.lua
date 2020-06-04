-- progressRing Module for Corona SDK
-- Copyright (c) 2014 Jason Schroeder
-- http://www.jasonschroeder.com
-- http://www.twitter.com/schroederapps

--[[ Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. ]]--

------------------------------------------------------------------------------------
-- HOW TO USE THIS MODULE
------------------------------------------------------------------------------------
-- Step One: put this lua file in your project's root directory
-- Step Two: require the module in your project as such:
	-- local progressRing = require("progressRing")
-- Step Three: create a progress ring object as such:
	-- local ringObject = progressRing.new([params])
	-- You can customize the look of your progress ring by including a single table as an argument when calling progressRing.new(). The table can include any of the following key/value pairs (but none are required):
		-- radius: a number representing the radius of your ring in pixels. Defaults to 100.
		-- ringColor: a table containing 4 numbers between 0 and 1, representing the RGBA values of your ring's bar color. Defaults to {1, 1, 1} (white).
		-- bgColor: a table containing 4 numbers between 0 and 1, representing the RBGA values of your ring's background color. Defaults to {0, 0, 0} (black).
		-- ringDepth: a number between 0 and 1 representing the depth of your ring. A ringDepth of 1 will result in a fully-round ring ("all donut, no hole"), while a ringDepth of 0 would result in an invisible ring ("all hole, no donut"). Defaults to .33.
		-- strokeColor: a table containing 4 numbers between 0 and 1, representing the RBGA values of your ring's stroke (border) color. Defaults to whatever your bgColor is.
		-- strokeWidth: a number representing the width of your ring's stroke (border) in pixels. Defaults to 0 (no stroke).
		-- counterclockwise: a boolean (true/false) value indicating whether or not the ring should advance in a counter-clockwise manner. Defaults to false.
		-- hideBG: a boolean (true/false) value indicating whether or not the background should be visible. Defaults to false.
		-- time: a number representing the amount of time (in milliseconds) your ring will take to make a full rotation, from 0 to 360 degrees. Defaults to 10000 (10 seconds).
		-- position: a number between 0 and 1 representing the starting position of your progress bar. 0 would result in no visible progress bar (i.e. 0 degrees). 1 would result in a full progress bar (i.e. 360 degrees). .5 would result in a halfway-full progress bar (i.e. 180 degrees). Defaults to 0.
		-- bottomImage: a string representing the path to an image file (i.e. "images/bottom.png") that will appear "underneath" or "behind" your progress ring. Automatically supports dynamic image scaling (@2x, @3x, etc.). Defaults to nil.
		-- topImage: a string representing the path to an image file (i.e. "images/top.png") that will appear "on top of" or "in front of" your progress ring. Automatically supports dynamic image scaling (@2x, @3x, etc.). Defaults to nil.
		
-- Step Four: you can change the position of your progress ring using the following methods:
	-- ringObject:goTo(position, [time]) is used to advance/retreat the position of the progress ring. Note:
		-- position (required) is a number between 0 and 1 representing the position the bar should advance or retreat to.
		-- time (optional) is a number representing the amount of time (in milliseconds) it will take for your ring to reach the position you defined. By default, this is determined by the time you set for a full rotation. (i.e. if you set a time of 10 seconds for a full 360-degree rotation, and your ring is advancing 180 degrees, it will take 5 seconds). Setting a time of 0 will result in an immediate repositioning of your progress ring.
	-- ringObject:pause() will pause your progress ring while advancing or retreating.
	-- ringObject:resume() will resume a paused progress ring.
	-- ringObject:reset() will return your progress ring to the starting position you defined when creating the object.

------------------------------------------------------------------------------------
-- FINALIZE BUG FIX:
-- Prior to Corona build # 2015.2544, there was a bug in Corona SDK that prevented
-- finalize events from being called for children objects when group is removed. This
-- code fixes that bug, in case you are using an older build for your app.
-- This bug fix was written by the incomparable @SergeyLerg - thanks, Sergey!
------------------------------------------------------------------------------------
local function fixFinalize()
	print("Fixing finalize() bug...")
	local function finalize(event)
		local g = event.target
		for i = 1, g.numChildren do
			if g[i]._tableListeners and g[i]._tableListeners.finalize then
				for j = 1, #g[i]._tableListeners.finalize do
					g[i]._tableListeners.finalize[j]:dispatchEvent{name = 'finalize', target = g[i]}
				end
			end
			if g[i]._functionListeners and g[i]._functionListeners.finalize then
				for j = 1, #g[i]._functionListeners.finalize do
					g[i]._functionListeners.finalize[j]({name = 'finalize', target = g[i]})
				end
			end
			if g[i].numChildren then
				finalize{target = g[i]}
			end
		end
	end

	local newGroup = display.newGroup

	function display.newGroup()
		local g = newGroup()
		g:addEventListener('finalize', finalize)
		return g
	end
end

local finalizeFixed = false
local testGroup = display.newGroup()
testGroup.isVisible = false
local testObject = display.newRect(testGroup, 0, 0, 1, 1)
function testObject.finalize(self, event)
	finalizeFixed = true
	print("no longer any need to fix finalize() - thanks Corona Labs!")
end
testObject:addEventListener("finalize")
display.remove(testGroup)
timer.performWithDelay(1, function()
	if not finalizeFixed then fixFinalize() end
	finalizeFixed, testGroup, testObject = nil, nil, nil
end)

------------------------------------------------------------------------------------
-- CREATE TABLE TO HOLD MODULE
------------------------------------------------------------------------------------
local progressRing = {}

------------------------------------------------------------------------------------
-- SCREEN POSITIONING VARIABLES
------------------------------------------------------------------------------------
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenTop = display.screenOriginY
local screenLeft = display.screenOriginX
local screenBottom = display.screenOriginY+display.actualContentHeight
local screenRight = display.screenOriginX+display.actualContentWidth
local screenWidth = screenRight - screenLeft
local screenHeight = screenBottom - screenTop

local tempW = display.pixelWidth
local tempH = display.pixelHeight

if tempW==750 and tempH==1334 then --iPhone 6 fix
	screenWidth = 374
elseif tempW==2048 and tempH==2732 then --iPad PRO fix
	screenWidth = 1024
end

------------------------------------------------------------------------------------
-- CREATE NEW PROGRESS RING
------------------------------------------------------------------------------------
function progressRing.new(params)
	-- available params are: radius, ringColor, bgColor, strokeColor, ringDepth, strokeWidth, hideBG, time, position, topImage, bottomImage
	if params == nil then params = {} end
	
	--------------------------------------------------------------------------------
	-- LOCALIZE PARAMS & SET DEFAULTS
	--------------------------------------------------------------------------------
	local radius = params.radius or 100
	local counterclockwise = params.counterclockwise
	local ringColor = params.ringColor or {1, 1, 1}
	local bgColor = params.bgColor or {0, 0, 0}
	local strokeColor = params.strokeColor or bgColor
	local ringDepth = params.ringDepth or .33
	local strokeWidth = params.strokeWidth or 0
	local hideBG = params.hideBG
	local time = params.time or 10000
	local startPosition = params.position or 0
	local topImage = params.topImage
	local bottomImage = params.bottomImage
	
	if ringDepth > 1 then ringDepth = 1 elseif ringDepth <0 then ringDepth = 0 end
	
	--------------------------------------------------------------------------------
	-- CREATE PROGRESS RING VISUALS
	--------------------------------------------------------------------------------
	local group = display.newGroup()
	group.position = startPosition
	local objectName = tostring(group)
	if counterclockwise == true then group.xScale = -1 end
	local sliceGroup = display.newGroup()
	sliceGroup.group = sliceGroup
	function sliceGroup.invalidate() end
	if ringColor[4] ~= nil and ringColor[4] < 1 and ringColor[4] > 0 then
		sliceGroup = nil
		sliceGroup = display.newSnapshot(radius*2, radius*2)
		sliceGroup.alpha = ringColor[4]
	end
	local sliceContainer = display.newContainer(group, radius*2, radius*2)
	sliceContainer.anchorChildren = false
	sliceContainer.anchorX = 0
	group.isVisible = false
	
	local slices = {}
	
	local bg = display.newCircle(group, 0, 0, radius)
	bg:setFillColor(unpack(bgColor))
	group:insert(sliceGroup)
	if hideBG then bg.isVisible = false end
	local stroke1 = display.newCircle(group, 0, 0, radius + strokeWidth*.5)
	stroke1:setFillColor(0, 0, 0, 0)
	stroke1:setStrokeColor(unpack(strokeColor))
	stroke1.strokeWidth = strokeWidth
	local stroke2 = display.newCircle(group, 0, 0, radius - radius*ringDepth - strokeWidth/2)
	stroke2:setFillColor(0, 0, 0, 0)
	stroke2:setStrokeColor(unpack(strokeColor))
	stroke2.strokeWidth = strokeWidth
	
	if bottomImage ~= nil then
		local getDims = display.newImage(bottomImage)
		getDims.isVisible = false
		local w, h = getDims.width, getDims.height
		group.bottomImage = display.newImageRect(bottomImage, w, h)
		group.bottomImage.x, group.bottomImage.y = 0, 0
		group:insert(1, group.bottomImage)
		display.remove(getDims)
		getDims = nil
	end
	
	if topImage ~= nil then
		local getDims = display.newImage(topImage)
		getDims.isVisible = false
		local w, h = getDims.width, getDims.height
		group.topImage = display.newImageRect(group, topImage, w, h)
		group.topImage.x, group.topImage.y = 0, 0
		display.remove(getDims)
		getDims = nil
	end
	
	--------------------------------------------------------------------------------
	-- ADD PROGRESS RING "SLICES"
	--------------------------------------------------------------------------------
	local sliceHeight = radius * 1.5
	for i = 0, 350, 10 do
		local slice = display.newPolygon(0, 0, {0, 0, 0, -sliceHeight, sliceHeight*.182, -sliceHeight})
		local ringColor = {ringColor[1], ringColor[2], ringColor[3]}
		slice:setFillColor(unpack(ringColor))
		slice.anchorX, slice.anchorY = 0, 1
		slice.target = i
		if i >=180 then
			sliceGroup.group:insert(slice)
		else
			sliceContainer:insert(slice)
		end
		slice.rotation = -10
		slices[#slices+1] = slice
	end
	
	--------------------------------------------------------------------------------
	-- CREATE CIRCULAR MASK FOR SLICES
	--------------------------------------------------------------------------------
	local stageColor = display.getDefault("background")
	local coverUp = display.newRect(centerX, centerY, screenWidth, screenHeight)
	coverUp:setFillColor(stageColor)
	display.getCurrentStage():insert(1, coverUp)
	
	local squareSize = screenWidth - 16

	if screenWidth > screenHeight then squareSize = screenHeight - 16 end
	squareSize = math.floor(squareSize*.25)*4 + 16

	local maskRadius = squareSize * .5 - 16

	local maskScaleX = radius / (maskRadius / display.contentScaleX)
	local maskScaleY = radius / (maskRadius / display.contentScaleY)

	local maskGroup = display.newGroup()
	maskGroup.x, maskGroup.y = centerX, centerY
	display.getCurrentStage():insert(1, maskGroup)
	local square = display.newRect(maskGroup, 0, 0, squareSize, squareSize)
	square:setFillColor(0)
	local circle = display.newCircle(maskGroup, 0, 0, maskRadius)
	circle:setFillColor(1)
	local circle2 = display.newCircle(maskGroup, 0, 0, maskRadius*(1-ringDepth))
	circle2:setFillColor(0)

	timer.performWithDelay(10, function()
		local maskImage = display.capture(maskGroup, { saveToPhotoLibrary=false, captureOffscreenArea=true } )
		display.getCurrentStage():insert(1, maskImage)
	
		timer.performWithDelay(1, function()
			display.save( maskImage, {filename=objectName..".jpg", baseDir=system.TemporaryDirectory, captureOffscreenArea=true} )

			local mask = graphics.newMask( objectName..".jpg", system.TemporaryDirectory )

			timer.performWithDelay(1, function()
				bg:setMask(mask)
				bg.maskScaleX, bg.maskScaleY = maskScaleX, maskScaleY

				sliceGroup.group:setMask(mask)
				sliceGroup.maskScaleX, sliceGroup.maskScaleY = maskScaleX, maskScaleY
				display.remove(maskGroup)
				display.remove(maskImage)
				display.remove(coverUp)
				sliceGroup.group:insert(sliceContainer)
				group.isCreated = true
				group:goTo(startPosition, 0, true)
				group.isVisible = true
			end)
		end)
	end)
	
	--------------------------------------------------------------------------------
	-- SET RING POSITION (i.e. start rotation)
	--------------------------------------------------------------------------------
	function group.goTo(self, position, customTime, doNotDispatch)
		if group.isCreated then
			transition.cancel(objectName)
			local function onComplete()
				if not doNotDispatch then
					group:dispatchEvent({name = "completed"})
				end
			end
			customTime = customTime or math.abs(group.position - position)*time
			if position > 1 then position = 1 elseif position < 0 then position = 0 end
			transition.to(slices[#slices], {rotation = position*360 - 10, time = customTime, tag = objectName, onComplete = onComplete})
		else
			timer.performWithDelay(50, function()
				group:goTo(position, customTime)
			end)
		end
	end
	
	--------------------------------------------------------------------------------
	-- RESET RING ROTATION
	--------------------------------------------------------------------------------
	function group.reset(self)
		transition.cancel(objectName)
		group:dispatchEvent({name = "reset"})
		group:goTo(startPosition, 0)
	end
	
	--------------------------------------------------------------------------------
	-- PAUSE RING ROTATION
	--------------------------------------------------------------------------------
	function group.pause(self)
		transition.pause(objectName)
		group:dispatchEvent({name = "paused"})
	end
	
	--------------------------------------------------------------------------------
	-- RESUME PAUSED ROTATION
	--------------------------------------------------------------------------------
	function group.resume(self)
		transition.resume(objectName)
		group:dispatchEvent({name = "resumed"})
	end
	
	--------------------------------------------------------------------------------
	-- RUNTIME LISTENER TO SET SLICE ROTATIONS & MAKE VISIBLE/INVISIBLE
	--------------------------------------------------------------------------------
	function group.runtimeListener(event)
		local targetSlice = slices[#slices]
		targetSlice.isVisible = targetSlice.rotation >=0
		group.position = (targetSlice.rotation + 10)/360
		for i = 1,#slices-1 do
			local slice = slices[i]
			slice.isVisible = slice.rotation > -10
			if targetSlice.rotation <= slice.target then
				slice.rotation = targetSlice.rotation
			else
				slice.rotation = slice.target
			end
			if i >= #slices*.5 then
				slice.isVisible = slice.rotation >=0
			end
		end
		sliceGroup:invalidate()
	end
	
	Runtime:addEventListener("enterFrame", group.runtimeListener)
	
	--------------------------------------------------------------------------------
	-- FINALIZE CLEANUP WHEN PROGRESS RING IS REMOVED
	--------------------------------------------------------------------------------
	function group.finalize(self, event)
		transition.cancel(objectName)
		Runtime:removeEventListener("enterFrame", group.runtimeListener)
	end
	group:addEventListener("finalize")
	
	--------------------------------------------------------------------------------
	-- RETURN PROGRESS RING OBJECT
	--------------------------------------------------------------------------------
	return group
end


------------------------------------------------------------------------------------
-- RETURN MODULE
------------------------------------------------------------------------------------
return progressRing