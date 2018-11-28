-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成



-- endregion

local unpack = unpack
local print = print
local math = math
local uimanager = require("uimanager")
local gameObject
local name
local fields
local DlgInfo
local EventHelper = UIEventListenerHelper

local function destroy()
end

local function show(params)
    DlgInfo = params and params or { title = LocalString.TipText, content = "" }
	if DlgInfo.content then
        fields.UILabel_NoticeContent.text = DlgInfo.content
    end
    if DlgInfo.title then
        fields.UILabel_Title.text = DlgInfo.title
    end
end

local function hide()
end

local function update()

end

local function refresh(params)

end


local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Return,function()
        uimanager.hide(name)
    end)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
