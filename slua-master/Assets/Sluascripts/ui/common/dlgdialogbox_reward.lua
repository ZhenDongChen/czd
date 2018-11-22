local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name
local gameObject
local fields

Dlg_Reward_Type={
    UIGROUP_REWARDLIST=0,
    UIGROUP_ITEMSHOW=1,
}
----------------------------
--显示功能所需的Group，关闭无关的Group
-----------------------------
local function DisplayGroupByType(type)
    fields.UIGroup_RewardList.gameObject:SetActive(type==Dlg_Reward_Type.UIGROUP_REWARDLIST)
    fields.UIGroup_ItemShow.gameObject:SetActive(type==Dlg_Reward_Type.UIGROUP_ITEMSHOW)
end

local function refresh(params)

end

local hasReposition = false
local function update()
    --解决奖励列表因子项大小计算错误导致重叠问题
    if not hasReposition then
        local uitable = fields.UIList_RewardGroups.gameObject:GetComponent(UITable)
        --printyellow("[dlgtournamentreward:update] set uitable:Reposition()!")
        uitable:Reposition() 
        hasReposition = true   
    end
end

local function hide()
    if UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "SetModelActive", true)   
    end 
end

local function destroy()
end

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end
---------------------------------------
--调用接口 
--参数释义({type:功能类型，见Dlg_Reward_Type;callBackFunc:回调函数，实现个人所需功能})
---------------------------------------
local function show(params)
    if params then
        if params.type then
            DisplayGroupByType(params.type)
        end
        if params.callBackFunc then
            params.callBackFunc(params,fields)
        end
    end   
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hide(name)
    end)
end


return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
	destroy = destroy,
    hide = hide,
	uishowtype = uishowtype,
}