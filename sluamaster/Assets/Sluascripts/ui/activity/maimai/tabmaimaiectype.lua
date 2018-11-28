local unpack, print         = unpack, print
local UIManager             = require("uimanager")
local MaimaiManager         = require("ui.activity.maimai.maimaiactmanager")
local BonusManager          = require("item.bonusmanager")
local ItemManager           = require("item.itemmanager")
local PlayerRole            = require "character.playerrole"
local ColorUtil = require("common.colorutil")
local EventHelper           = UIEventListenerHelper

local LimitManager = require"limittimemanager"
local TeamManager       = require"ui.team.teammanager"
local fields
local name
local gameObject
--local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
--local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local function destroy()
end


local function init(params)
    name, gameObject, fields    = unpack(params)
    EventHelper.SetClick(fields.UIButton_Invitation,function ()
        UIManager.show("common.dlgdialogbox_listfriend")
        local localData = MaimaiManager.getConfigData()
        if UIManager.gettabindex("activity.dlgactivity")== 4 then
            MaimaiManager.getMMLeftTimes(cfg.ectype.MMEctype.SPRING_ID)
        else
            MaimaiManager.getMMLeftTimes(cfg.ectype.MMEctype.MM_ID)
        end
    end)

    EventHelper.SetClick(fields.UIButton_Extract,function ()
        local localData = MaimaiManager.getConfigData()
        if UIManager.gettabindex("activity.dlgactivity")== 4 then
            MaimaiManager.begainFight(cfg.ectype.MMEctype.SPRING_ID)
        else
            MaimaiManager.begainFight(cfg.ectype.MMEctype.MM_ID)
        end
    end)

end

local function refresh()
    local teamData = TeamManager.GetTeamInfo()
    if teamData then
        local level = 0
        local num = 0
        for _,roleData in pairs(teamData.members) do
            printt(roleData)
            level = level + roleData.roleinfo.level
            num = num + 1
        end
        level = math.floor(level/num)

        fields.UILabel_PhysicalStrength.text = level
    else
        fields.UILabel_PhysicalStrength.text = PlayerRole:Instance():GetLevel()
    end
end

local function update()

end

local function show()
    local localData = MaimaiManager.getConfigData()
    local maimaiData = {}
    if UIManager.gettabindex("activity.dlgactivity")== 4 then
        maimaiData = localData[cfg.ectype.MMEctype.SPRING_ID]
        fields.UITexture_Pvp:SetIconTexture("Texture_Activity_30");
    else
        fields.UITexture_Pvp:SetIconTexture("Texture_Activity_29");
        maimaiData = localData[cfg.ectype.MMEctype.MM_ID]
    end
    fields.UILabel_Describe.text = maimaiData.decs
    fields.UILabel_Level.text =  maimaiData.openlevel .. LocalString.WorldMap_OpenLevel

    if maimaiData.openlevel > PlayerRole:Instance():GetLevel() then
        ColorUtil.SetTextureColorGray(fields.UITexture_Pvp, true)
        fields.UIGroup_Lock.gameObject:SetActive(true)
    else
        ColorUtil.SetTextureColorGray(fields.UITexture_Pvp, false)
        fields.UIGroup_Lock.gameObject:SetActive(false)
    end

    local rewardList = maimaiData.showrewards.items  
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Icon, #rewardList)
    for i = 1,#rewardList do
        local rewardsItem = ItemManager.CreateItemBaseById(rewardList[i])
        local item = fields.UIList_Icon:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(item,rewardsItem,{notShowAmount = true})
    end
    local times 
    if UIManager.gettabindex("activity.dlgactivity")== 4 then
        times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE_CHRISMAS,0)
    else
        times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE,0)
    end

    local num = maimaiData.dailyrewardtime.num - times
    if num < 0 then
        num = 0
    end
    fields.UILabel_Times.text = LocalString.MAIMAI_FREE_TIMES .. num
end

local function hide()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function UnRead()
end

return{
    show=show,
    hide=hide,
    init=init,
    refresh=refresh,
    uishowtype=uishowtype,
    update=update,
    destroy = destroy,
    UnRead = UnRead,
}
