--local dlgflytext = require "ui.dlgflytext"
local unpack = unpack
local print = print
local uimanager = require("uimanager")
local fields,gameObject,name
local dlgname = "dlgtweenset"
local EventHelper    = UIEventListenerHelper

local function hide()

end

local function destroy()

end


local function initfiled(tweenfield,fieldparams) 
    if tweenfield == "UIPlayTweens_EvolveSkill" then 
        fields.UITexture_EvolveSkill:SetIconTexture(fieldparams.texture)
    elseif tweenfield == "UIPlayTweens_Achievement" then 
        fields.UITexture_Title:SetIconTexture(fieldparams.texture)
	elseif tweenfield == "UIPlayTweens_EquipUpgrade" then
		fields.UITexture_EquipUpgrade:SetIconTexture(fieldparams.texture)
    end 
end 



local function refresh(params)
    if params and params.tweenfield and fields[params.tweenfield] then 
        initfiled(params.tweenfield,params.fieldparams)
        EventHelper.SetPlayTweensFinish(fields[params.tweenfield],function()
            uimanager.hide(dlgname)
            if params.callback then 
                params.callback()
            end 
	    end)
        fields[params.tweenfield]:Play(true)
    else
        uimanager.hide(dlgname)
    end 
end

local function show(params)
   
end

local function init(params)
    name, gameObject, fields = unpack(params)
	EventHelper.SetClick(fields.UISprite_BG,function() 
	fields.UISprite_BG.gameObject:GetComponent("BoxCollider").enabled = false
	end)


end




return {
    init = init,
    show = show,
    destroy = destroy,
    refresh = refresh,
    hide = hide,
}
