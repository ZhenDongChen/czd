local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name
local gameObject
local fields

local secondUpdateDelegate = nil
local updateDelegate = nil
local refreshDelegate = nil




----------------------------
--显示功能所需的Group，关闭无关的Group
-----------------------------


local function refresh()
    
end

local function update()
  
end


local function hide()

end
---------------------------------------
--调用接口
--参数释义({type:功能类型，见Dlg_Common_Type;callBackFunc:回调函数，实现个人所需功能})
---------------------------------------
local function show()
  
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    EventHelper.SetClick(fields.UIButton_1,function ()
        local login = require"login"
        login.Game_logout(login.LogoutType.to_login)
        UIManager.hdie(name)
	end)
end


return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
    hide = hide,
}
