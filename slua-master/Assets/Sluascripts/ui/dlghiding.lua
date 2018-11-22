local unpack          = unpack
local print           = print
local uimanager       = require("uimanager")
local fields,gameObject,name
local dlgname = "dlghiding"
local fadeoutcount = 0
local hidetime = 0
local maxhidetime = 1

local function showdlghiding() 
    if not uimanager.isshow(dlgname) then 
        uimanager.show(dlgname)
    end
    hidetime = Time.time
end 

local function hidedlghiding() 
    if uimanager.isshow(dlgname) then 
        uimanager.hide(dlgname)
    end
    fadeoutcount = 0
end 

local function OnFadeOutBegin() 
    fadeoutcount = fadeoutcount +1
    showdlghiding()
end 

local function OnFadeOutEnd() 
    fadeoutcount = fadeoutcount -1
    if fadeoutcount <= 0 then 
        hidedlghiding()
    end 
end 


local function destroy()
end

local function show(params)
end

local function update()
   if Time.time-hidetime > maxhidetime then 
        hidedlghiding()
   end
end

local function refresh(params)
    hidetime = Time.time
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

local function hide()

end




return {
    init = init,
    show = show,
    update = update,
    destroy = destroy,
    refresh = refresh,
    hide = hide,
    OnFadeOutBegin = OnFadeOutBegin,
    OnFadeOutEnd = OnFadeOutEnd,

}
