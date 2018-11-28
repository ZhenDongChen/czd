local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")

local gameObject
local name

local fields
local DlgInfo
local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    DlgInfo = params and params or { title = LocalString.TipText, content = "" }

    if DlgInfo.fontSize then
        fields.UILabel_Content.fontSize = DlgInfo.fontSize
    else
        fields.UILabel_Content.fontSize = 24
    end   

    if DlgInfo.content then
        fields.UILabel_Content.text = DlgInfo.content
    end
    if DlgInfo.title then
        fields.UILabel_Title.text = DlgInfo.title
    end   
    EventHelper.SetClick(fields.UIButton_Func, function()
        uimanager.hide(name)

        if DlgInfo.callBackFunc then
            DlgInfo.callBackFunc()
        end
    end )
    if DlgInfo.buttonText then
        fields.UILabel_Func.text = DlgInfo.buttonText
    end
end

local function hide()
    -- print(name, "hide")
end

local function update()
    -- print(name, "update")
end

local function refresh(params)
    gameObject.transform.localPosition = Vector3.forward * -3000
end


local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Close, function()
	Util.Log("single closed!")
	
        uimanager.hide(name)
		
        if DlgInfo.callBackHideFunc then
            DlgInfo.callBackHideFunc()
        end
    end )
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
