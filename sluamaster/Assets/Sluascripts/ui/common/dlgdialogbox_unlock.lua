local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local PlayerRole            = require "character.playerrole"
local ModuleLockManager     = require("ui.modulelock.modulelockmanager")
local name
local gameObject
local fields
local ShowData = nil

local function unlockfunctiondata()
    local PlayerLevel = PlayerRole:Instance():GetLevel()
    local functionData = ConfigManager.getConfig("nextfunctiontips")
    for _,data in ipairs(functionData) do
        if data.conid >= 1000 then
            if not ModuleLockManager.GetTaskStatus(data.conid) then
                ShowData = data
                break
            end
        else
            if PlayerLevel < data.conid then
                ShowData = data
                break
            end
        end
    end
    return ShowData
end

local function refresh()
	
end

local function update()

end

local function hide()

end

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end


local function show()
    fields.UISprite_Icon.spriteName = ShowData.icon
    fields.UILabel_Title.text = ShowData.name
    fields.UILabel_Name.text = ShowData.name
    fields.UILabel_Discription.text = ShowData.coniddesc 
    fields.UILabel_DiscriptionCheck.text = ShowData.functiondesc 
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    unlockfunctiondata()
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.showmaincitydlgs()
        UIManager.hide(name)
    end)
    -- EventHelper.SetClick(fields.UISprite_Black,function()
    --     UIManager.showmaincitydlgs()
    --     UIManager.hide(name)
    -- end)

end

return{
    show = show,
    init = init,
	hide = hide,
    update = update,
    refresh = refresh,
	uishowtype = uishowtype,
    unlockfunctiondata = unlockfunctiondata,
}