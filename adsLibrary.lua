local adsConfig             = {}
local ads                   = require( "ads" )
local adProvider_AdMob      = "admob"
local adProvider_Vungle     = "vungle"
local adListener
local interstitialFetchFlag = 1 -- Call Load Interstitial if this Flag is set to 1
local myGlobalData          = require( "lib.globalData" )
local device                = require( "lib.device" )

local paramsVungle          =   {
                                    isAnimated      = true,
                                    isAutoRotation  = true,
                                }

local targetStore
targetStore = system.getInfo( "targetAppStore" )
print( "Device running on: "..targetStore)



local bannerAppID                  = ""  --leave as is - configure variables below
local interstitialAppID            = ""  --leave as is - configure variables below
local vungleAd                     = ""  --leave as is - configure variables below
local rewardVideoAppID             = ""  --leave as is - configure variables below
---------------------------------------------------------------------------------
local adMob_Banner_iOS             = myGlobalData.adMob_Banner_iOS
local adMob_Interstitial_iOS       = myGlobalData.adMob_Interstitial_iOS
local adMob_RewardVideo_iOS        = myGlobalData.adMob_RewardVideo_iOS
---------------------------------------------------------------------------------
local adMob_Banner_Android         = myGlobalData.adMob_Banner_Android
local adMob_Interstitial_Android   = myGlobalData.adMob_Interstitial_Android
local adMob_RewardVideo_Android    = myGlobalData.adMob_RewardVideo_Android
---------------------------------------------------------------------------------
local vungleAd_iOS                 = myGlobalData.vungleAd_iOS
local vungleAd_Android             = myGlobalData.vungleAd_Android
---------------------------------------------------------------------------------


if ( device.isApple or device.isSimulator) then
    bannerAppID         = adMob_Banner_iOS
    interstitialAppID   = adMob_Interstitial_iOS
    vungleAd            = vungleAd_iOS
else
    bannerAppID         = adMob_Banner_Android
    interstitialAppID   = adMob_Interstitial_Android
    vungleAd            = vungleAd_Android
end


----------------------------------------------------------------------------

----------------------------------------------------------------------------
function adListener( event )
      -- The 'event' table includes:
    -- event.name: string value of "adsRequest"
    -- event.response: message from the ad provider about the status of this request
    -- event.phase: string value of "loaded", "shown", or "refresh"
    -- event.type: string value of "banner" or "interstitial"
    -- event.isError: boolean true or false

    if (device.isNook) then
        return false 
    end
        
    local msg = event.response
    -- Quick debug message regarding the response from the library
    print( "Message from the ads library: ", msg )

    if (event.type == "banner") then
        if ( event.isError ) then
            print( "Error, no ad received", msg )
            bannerAdHeight = bannerAdHeightDefault
        else
            print( "Got a Banner Ad.." )
            bannerAdHeight = ads.height() 
            if (bannerAdHeight == nil or bannerAdHeight == 0) then
                bannerAdHeight = bannerAdHeightDefault
            end
            --getBannerHeight()
        end
    elseif (event.type == "interstitial") then
        if ( event.isError ) then
            print( "Error while calling interstitialAdListener ... Try another Ad from another provider" )
        -- attempt to fetch another ad
        elseif ( event.phase == "loaded" ) then
        -- an ad was preloaded
            interstitialFetchFlag = 0
            print("interstitial loaded and show can be called to show ad")
        elseif ( event.phase == "shown" ) then
        -- the ad was viewed and closed
            print("interstitial-closed shown")
        -- composer.gotoScene( "loopScene1", options)
        end
    end

end

--adsConfig.bannerAdListener = bannerAdListener
----------------------------------------------------------------------------

function interstitialAdListener( event )

    if (device.isNook) then 
        return false 
    end

    if ( event.isError ) then
        print( "Error while calling interstitialAdListener ... Try another Ad from another provider" )
        -- attempt to fetch another ad
    elseif ( event.phase == "loaded" ) then
        -- an ad was preloaded
        interstitialFetchFlag = 0
        print("interstitial loaded and show can be called to show ad")
    elseif ( event.phase == "shown" ) then
        -- the ad was viewed and closed
        print("interstitial-closed shown")
      -- composer.gotoScene( "loopScene1", options)
    end
end

--adsConfig.interstitialAdListener = interstitialAdListener
----------------------------------------------------------------------------

function vungleAdListener( event )
  if ( event.type == "adStart" and event.isError ) then
        print( "Ad has not finished caching and will not play")
  end
  if ( event.type == "adStart" and not event.isError ) then
        print( "Ad will play")
  end
  if ( event.type == "cachedAdAvailable" ) then
        interstitialFetchFlag = 0
        print( "Ad has finished caching and is ready to play")
  end
  if ( event.type == "adView" ) then
        print( "An ad has completed")
  end
  if ( event.type == "adEnd" ) then
        print( "The ad experience has been closed - resume your app")
  end
end





function initAdmobBannerAd()
    if (device.isNook) then 
        return false 
    end
    ads.init( adProvider_AdMob, bannerAppID, adListener)
end

adsConfig.initAdmobBannerAd = initAdmobBannerAd
----------------------------------------------------------------------------
function showAdmobBannerAd(position)
    if (device.isNook) then 
        return false 
    end

    if (position == nil) then
        position = "top"
    elseif (position ~= "top" and position ~= "bottom") then
        position = "top"
    end

    ads:setCurrentProvider( adProvider_AdMob )

    if (position == "top") then
        print( "Top Ad Called" )
        ads.show( "banner", { x=0, y=0, appId=bannerAppID, testMode=true })
    elseif (position == "bottom") then
      print( "Bottom Ad Called" )
      ads.show( "banner", { x=0, y=100000, appId=bannerAppID, testMode=true })
    else
      print( "Something wrong with Banner Ad Position Logic ... Shouldn't come to this statement" )
    end
    
end
adsConfig.showAdmobBannerAd = showAdmobBannerAd
----------------------------------------------------------------------------
function hideAdmobBannerAd()
    if (device.isNook) then 
        return false 
    end
    ads.hide()
end
adsConfig.hideAdmobBannerAd = hideAdmobBannerAd
----------------------------------------------------------------------------
function initAdmobInterstitialAd()
    if (device.isNook) then 
        return false 
    end
    ads.init( adProvider_AdMob, interstitialAppID, adListener)
end

adsConfig.initAdmobInterstitialAd = initAdmobInterstitialAd

----------------------------------------------------------------------------
function initVungleInterstitialAd()
    if (device.isNook) then 
        return false 
    end
    ads.init( adProvider_Vungle, vungleAd, vungleAdListener)
end

adsConfig.initVungleInterstitialAd = initVungleInterstitialAd
----------------------------------------------------------------------------

function loadAdmobInterstitialAd()
    if (device.isNook) then 
        return false 
    end
    if (interstitialFetchFlag == 1) then
        ads.load( "interstitial", { appId=interstitialAppID } )
    else
        print( "Fetch Flag is 0 ... Ad must be ready to show" )
    end
    
end
adsConfig.loadAdmobInterstitialAd = loadAdmobInterstitialAd
----------------------------------------------------------------------------
function showAdmobInterstitialAd()
    if (device.isNook) then 
        return false 
    end
    --if (ads.isLoaded( "interstitial", { appId=interstitialAppID } )) then
    if (interstitialFetchFlag == 0) then
        interstitialFetchFlag = 1
        ads:setCurrentProvider( adProvider_AdMob )
        ads.show( "interstitial", { appId=interstitialAppID } )
    else
        loadAdmobInterstitialAd() -- Load Admob Interstitial Ad and get ready for next call
        print( "ads.isLoaded" .. " returned FALSE and so can't display Interstitial Ad" )
    end
end
adsConfig.showAdmobInterstitialAd = showAdmobInterstitialAd

----------------------------------------------------------------------------
function showVungleInterstitialAd()
    if (device.isNook) then 
        return false 
    end
    if (interstitialFetchFlag == 0) then
        interstitialFetchFlag = 1
        print( "VUNGLE: ads.isLoaded" .. " returned TRUE displayin Interstitial Ad" )
        ads:setCurrentProvider( adProvider_Vungle )
        ads.show( "interstitial", paramsVungle )
    else
        print( "VUNGLE: ads.isLoaded" .. " returned FALSE and so can't display Interstitial Ad" )        
    end
end
adsConfig.showVungleInterstitialAd = showVungleInterstitialAd
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
return adsConfig