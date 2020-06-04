-- Color transition wrapper
-- Author: atoko
-- Release date: 5/9/2012
-- Version: 1.0.0
-- 
--
--
--Description:
--      This is a wrapper for changing fill color within a transition
--  Time, delay and easing values are optional
--
--Usage:
-- cTrans = require( "colortransition" ) ;
-- 
-- cTrans:colorTransition(displayObject, colorFrom, colorTo, [time], [delay], [easing]) ;
-- ex:
--  
--  local rect = display.newRect(0,0,250,250) ;
--      local white = {255,255,255}     
--  local red = {255,0,0} ;
--      
--  cTrans:colorTransition(rect, white, red, 1200) ;
 

local _M = {}
 
--Local reference to transition function
_M.callback = transition.to ;
 
function returnRGB(value)
	return value/255
end


-- function _M:colorTransition( obj, colorFrom, colorTo, time, onComplete, delay, ease )
function _M:colorTransition( obj, colorFrom, colorTo, time, params  )
        
        local _obj =  obj ; 
        local ease = params and params.ease or easing.linear
        local callbackOnComplete = params and params.onComplete or nil --callback functionality added
        
        
        local fcolor = colorFrom or {1,1,1} ; -- defaults to white
        local tcolor = colorTo or {0,0,0} ; -- defaults to black
        local t = nil ;
        local p = {} --hold parameters here
        
        local rDiff = returnRGB(tcolor[1]) - returnRGB(fcolor[1]) ; --Calculate difference between values
        local gDiff = returnRGB(tcolor[2]) - returnRGB(fcolor[2]) ;
        local bDiff = returnRGB(tcolor[3]) - returnRGB(fcolor[3]) ;
        
        --print("Ext function - FROM COLOUR: R:"..fcolor[1].." | G:"..fcolor[2].." | B:"..fcolor[3])
        --print("Ext function - TO COLOUR: R:"..tcolor[1].." | G:"..tcolor[2].." | B:"..tcolor[3])
        
                --Set up proxy
        local proxy = {step = 0} ;
        
        local mt = {
                __index = function(t,k)
                        --print("get") ;
                        return t["step"] 
                end,
                
                __newindex = function (t,k,v)
                        --print("set") 
                        --print(t,k,v)                        
                        
                        --if(_obj.setFillColor) then
                        if(_obj.fill) then
                        		--print(returnRGB(fcolor[1]) + (v*rDiff))
                                _obj.fill = {returnRGB(fcolor[1]) + (v*rDiff) ,returnRGB(fcolor[2]) + (v*gDiff) ,returnRGB(fcolor[3]) + (v*bDiff) }
                                --_obj:setFillColor(returnRGB(fcolor[1]) + (v*rDiff) ,returnRGB(fcolor[2]) + (v*gDiff) ,returnRGB(fcolor[3]) + (v*bDiff) )
                                --_obj.rCol = fcolor[1] + (v*rDiff)
                                --_obj.gCol = fcolor[2] + (v*gDiff)
                                --_obj.bCol = fcolor[3] + (v*bDiff)
                        end
                        t["step"] = v ;      
                end    
        }
        
        p.time = time or 1000 ; --defaults to 1 second
        p.delay = params and params.delay or 0 ;
        p.transition = ease ;
        p.onComplete = callbackOnComplete; --callback functionality added
        
 
        setmetatable(proxy,mt) ;
        
        p.colorScale = 1 ;
        
        t = self.callback( proxy, p, 1 )  ;
 
        return t
 
end
 

return _M ;