local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local CharacterManager = require "character.charactermanager"
local EctypeManager = require "ectype.ectypemanager"
local gameObject
local ConfigManager = require "cfg.configmanager"
local name
local BonusManager = require"item.bonusmanager"
local PlayerRole = require "character.playerrole"
local playerRole
local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
local dlgname = "ectype.guardtower.dlgguardtower"
local fields
local waveid = 0 
local baseid = nil 
local base = nil 
local buffs = {} --buffid:count


local function ShowTasks(b)
   -- printt(fields)
    if fields then 
        fields.UIGroup_MainUI.gameObject:SetActive(b)
    end
end

local function ShowResult(msg)
    fields.UIGroup_MainUI.gameObject:SetActive(false)
    if #msg.statics>0 then
        local totaldamage = msg.statics[1].totaldamage
        for index,data in pairs(msg.statics) do
            local item = fields.UIList_Ranklist:GetItemByIndex(index-1)
            if item then
                local UISprite_Name = item.Controls["UISprite_Name"]
                local UISlider_Hurt = item.Controls["UISlider_Hurt"]
                item:SetText("UILabel_Hurt",data.totaldamage)
                item:SetText("UILabel_Amound",data.totalspell)

            end
        end
    end

end

local function LeaveEctype()
    if EctypeManager.IsFinished() then
        EctypeManager.FuncEnd()
    else
        EctypeManager.RequestLeaveEctype()
    end
end



local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function UpdateRemainTime(active,h,m,s)
    if fields then
        fields.UILabel_CountDown.gameObject:SetActive(active)
        if active then
            fields.UILabel_RemainTime.text = GetFormatedTime(h)..':'..GetFormatedTime(m)..':'..GetFormatedTime(s)
        end
    end
end


local function UpdateBaseState()
    if base and base.m_Object then
        local pct = base.m_Attributes[cfg.fight.AttrId.HP_VALUE]/base.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
        fields.UIProgressBar_Blood.value = pct
        fields.UILabel_BaseHP.text = tostring(math.floor(pct*100))..'%'
    else
        --printyellow("baseid",baseid)
        local char = CharacterManager.GetNearestCharacterByCsvId(baseid)
        --printyellow("base",char.m_Name)
        if char and char.m_Object then
            base = char
            fields.UIProgressBar_Blood.gameObject:SetActive(true)
        else
            fields.UIProgressBar_Blood.gameObject:SetActive(false)
        end
    end
end



local function RefreshLayer(layerid)
    waveid = layerid
    if uimanager.needrefresh(dlgname) then
        fields.UILabel_LayerNumber.text = tostring(waveid)
    end
end


local function RefreshBuff(ibuffs)
    if Local.GuardTower then 
        printyellow("RefreshBuff")
        printt(ibuffs)
    end 
    buffs = ibuffs
    if uimanager.needrefresh(dlgname) then
        for i = 1,fields.UIList_Attribute.Count do
            local item = fields.UIList_Attribute:GetItemByIndex(i-1)
            local data = buffs[item.Id] 
            if data then
                viewutil.SetTextureGray(item.Controls["UITexture_Arrows"],data.Num<=0)
                item.Controls["UITexture_Arrows"]:SetIconTexture(data.Rune.icon)
                item.Controls["UILabel_AddValue"].text =data.Effect.name.. "+"..tostring(data.Effect.value*100*data.Num).."%"
            end
        end
    end

end

local function EnterDuardTower(level,bid,ibuffs)
    printyellow("EnterDuardTower",level,bid,ibuffs)
    --fields.UILabel_IntegralNumber.text = tostring(score)
    waveid = level
    baseid = bid
    buffs = ibuffs
    fields.UIList_Attribute:Clear()
    for buffid,count in pairs(buffs) do
        local item = fields.UIList_Attribute:AddListItem()
        item.Id = buffid
    end
    if uimanager.needrefresh(dlgname) then
        RefreshLayer(waveid)
        RefreshBuff(buffs)
    end
end

local function EnterEctype(towername)
    
end




local function destroy()
    fields = nil
end

local function show(params)
    fields.UIGroup_MainUI.gameObject:SetActive(true)
end

local function hide()

end


local function update()
    if baseid then
        UpdateBaseState()
    end
end

local function refresh(params)
    RefreshLayer(waveid)
    RefreshBuff(buffs)
end
local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
    playerRole = PlayerRole.Instance()

    EventHelper.SetClick(fields.UIButton_RequestLeave,function()
        local tb = {}
        tb.immediate = true
        tb.title = LocalString.EctypeText.LeaveWarningTitle
        tb.content = timeutils.getDateTimeString(guardtowermanager.GetLastMatchTime(),LocalString.EctypeText.GuardTowerLeaveWarningContent)
        tb.callBackFunc = LeaveEctype
        uimanager.ShowAlertDlg(tb)
    end)

end




return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  UpdateRemainTime = UpdateRemainTime,
  EnterEctype = EnterEctype,
  EnterDuardTower = EnterDuardTower,
  RefreshLayer = RefreshLayer,
  RefreshBuff = RefreshBuff,
  ShowTasks = ShowTasks,
}
