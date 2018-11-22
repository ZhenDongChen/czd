local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local CharacterManager = require "character.charactermanager"
local EctypeManager = require "ectype.ectypemanager"

local ConfigManager = require "cfg.configmanager"
local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
local BonusManager = require"item.bonusmanager"
local PlayerRole = require "character.playerrole"
local playerRole
local dlgname = "ectype.guardtower.dlgguardtower"

local gameObject
local name
local fields


local function destroy()
end

local function show(params)
end

local function hide()

end


local function update()

end

local function refresh(params)
    local matchinfo = guardtowermanager.GetMatchInfo()
    if matchinfo then
        if matchinfo.teaminfo then
            fields.UIList_Player:Clear()
            for _,playerinfo in pairs(matchinfo.teaminfo.members) do
                local item = fields.UIList_Player:AddListItem()
                local UITexture_Head = item.Controls["UITexture_Head"]
                UITexture_Head:SetIconTexture(ConfigManager.GetHeadIcon(playerinfo.profession,playerinfo.gender))
                item:SetText("UILabel_Name",playerinfo.name)
                item:SetText("UILabel_Level",tostring(playerinfo.level))
                item:SetText("UILabel_Power",playerinfo.combatpower)
            end

        end
    end
    fields.UILabel_LastTime.gameObject:SetActive(false)
    fields.UIButton_Cancel.gameObject:SetActive(guardtowermanager.IsMatching())
end

local function second_update(now)
    fields.UILabel_LastTime.gameObject:SetActive(not guardtowermanager.IsReady())
    if guardtowermanager.IsReady() then
        fields.UILabel_Matching.text = LocalString.GuardTower.UILabel_Matching
        fields.UILabel_LastTime.text = ""

    elseif guardtowermanager.IsUnReady() then
        fields.UILabel_Matching.text = LocalString.GuardTower.UILabel_Matching
        fields.UILabel_LastTime.text = ""

    elseif guardtowermanager.IsMatching() then
        fields.UILabel_Matching.text = LocalString.GuardTower.UILabel_Matching
        fields.UILabel_LastTime.text = string.format(LocalString.GuardTower.UILabel_LastTime,guardtowermanager.GetLastTime())

    elseif guardtowermanager.IsMatched() then
        fields.UILabel_Matching.text = LocalString.GuardTower.UILabel_Matching_Done
        fields.UILabel_LastTime.text = string.format(LocalString.GuardTower.UILabel_LastTime2,guardtowermanager.GetLastTime())
    end

end


local function init(params)
    name, gameObject, fields = unpack(params)

    playerRole = PlayerRole.Instance()

    EventHelper.SetClick(fields.UIButton_Return,function()
        uimanager.hide("ectype.guardtower.dlgguardtower_matching")
    end)

    EventHelper.SetClick(fields.UIButton_Cancel, function()
        guardtowermanager.MatchCancel()
    end )

    EventHelper.SetClick(fields.UIButton_Confirm, function()
        guardtowermanager.Invitation()
    end )



end






return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  second_update = second_update,
  RefreshState = RefreshState,
}
