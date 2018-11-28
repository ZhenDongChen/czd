local unpack, print = unpack, print
local EventHelper   = UIEventListenerHelper
local uimanager     = require("uimanager")
local EctypeManager = require("ectype.ectypemanager")
local ColorUtil     = require("common.colorutil")
local PetManager    = require("character.pet.petmanager")
local gameObject, name, fields

local BattleMsgInfo = Class:new()

function BattleMsgInfo:__new(msg, playerCamp)
    self.m_AttackerName = msg.attackername or ""
    self.m_DefencerName = msg.defencer or ""
    self.m_AttackerCamp = msg.attackercamp
    self.m_DefencerCamp = msg.defencercamp
    self.m_PetKey       = msg.petkey
    self.m_PlayerCamp   = playerCamp
end

function BattleMsgInfo:GetAttackerName()
    local colorType = (((self.m_AttackerCamp == self.m_PlayerCamp) and ColorUtil.ColorType.Green) or ColorUtil.ColorType.Red)
    return ColorUtil.GetColorStr(colorType, self.m_AttackerName)
end

function BattleMsgInfo:GetDefencerName()
    local colorType = (((self.m_DefencerCamp == self.m_PlayerCamp) and ColorUtil.ColorType.Green) or ColorUtil.ColorType.Red)
    local str = self.m_DefencerName
    if self.m_PetKey and self.m_PetKey > 0 then
        local petName = PetManager.GetPetName(self.m_PetKey)
        if petName then
            str = string.format( "%s(%s)", self.m_DefencerName, petName)
        end
    end
    return ColorUtil.GetColorStr(colorType, str)
end
--========================================================================================================

local BattleMsg = {}
local currentMsg = nil
local coutDown = 0



local function destroy()
end

local function show(params)

end

local function hide()
end

local function ReShowMsg(msgInfo)
    local str = string.format( LocalString.TeamFight.BattleMsgInfo, msgInfo:GetAttackerName(), msgInfo:GetDefencerName() )
    fields.UILabel_BattleMsg.text = str
    fields.UIPlayTweens_BattleMsg.gameObject:SetActive(true)
    fields.UIPlayTweens_BattleMsg:Play(true)
    coutDown = 0.5
end

local function update()
    if coutDown <= 0 then
        if #BattleMsg <= 0 then 
            return
        end
        ReShowMsg(BattleMsg[1])
        table.remove( BattleMsg, 1 )
    else
        coutDown = coutDown - Time.deltaTime
    end
end

local function NewBattleMsg(data)
    local newMsg = BattleMsgInfo:new(data.serverMsg, data.playerCamp)
    table.insert( BattleMsg, newMsg )
end


local function refresh(params)

end

local function LeaveEctype()
    if EctypeManager.IsFinished() then
        EctypeManager.FuncEnd()
    else
        EctypeManager.RequestLeaveEctype()
    end
end

local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end
local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
    
    fields.UIPlayTweens_BattleMsg.gameObject:SetActive(false)

    EventHelper.SetClick(fields.UIButton_RequestLeave,function()
        local tb = {}
        tb.title = LocalString.EctypeText.LeaveWarningTitle
        tb.content = LocalString.EctypeText.LeaveWarningContent
        tb.immediate = true
        tb.callBackFunc = LeaveEctype
        uimanager.ShowAlertDlg(tb)
    end)

end

local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function UpdateRemainTime(h,m,s)
    if fields then
        if h == 0 then
            fields.UILabel_RemainTime.text = GetFormatedTime(m) ..':'.. GetFormatedTime(s)
        else
            fields.UILabel_RemainTime.text = GetFormatedTime(h) ..':'.. GetFormatedTime(m) ..':'.. GetFormatedTime(s)
        end
    end
end

local function EnterEctype(name,ectypetype)
    --uimanager.show(name)
end




local function ChangeScore( params )
    if params.maxScore then
        fields.UILabel_MyScore.text = tostring(params.friendlyScore) .. "/" .. tostring(params.maxScore)
        fields.UILabel_EnemyScore.text = tostring(params.enemyScore) .. "/" .. tostring(params.maxScore)
    else 
        fields.UILabel_MyScore.text = tostring(params.friendlyScore)
        fields.UILabel_EnemyScore.text = tostring(params.enemyScore)
    end
end

local function ChangeTitle(text)
    fields.UILabel_Title.text = text
end

local function ChangeTeam(teamText,enemyText)
    fields.UILabel_Team.text = teamText
    fields.UILabel_Enemy.text = enemyText
end

local function ChangeGoal(goal)
    fields.UILabel_Goal.text = goal
end

local function ShowScorePanel(params)
    if params ~= nil  and params.isShowPanel ~= nil then
        if params.isShowPanel == true then
            fields.UIWidget_Left.gameObject:SetActive(true)
        else
            fields.UIWidget_Left.gameObject:SetActive(false)
        end
    end

end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  late_update = late_update,
  destroy = destroy,
  refresh = refresh,
  UpdateRemainTime = UpdateRemainTime,
  EnterEctype = EnterEctype,
  ChangeScore = ChangeScore,
  ChangeTitle = ChangeTitle,
  ChangeTeam = ChangeTeam,
  ChangeGoal = ChangeGoal,
  ShowScorePanel = ShowScorePanel,
  NewBattleMsg = NewBattleMsg,
}
