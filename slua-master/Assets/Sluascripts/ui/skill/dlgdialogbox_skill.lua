local EventHelper = UIEventListenerHelper
local uimanager 	= require "uimanager"
local SkillManager  = require "character.skill.skillmanager"
local RoleSkill     = require "character.skill.roleskill"
local PlayerRole    = require "character.playerrole"
--------------------------------------------------------------------------------------------

local gameObject
local name
local fields


--=====================================================================================================================================
local function refresh(params)
   --print(name, "refresh")
  
end


local function destroy()
  --print(name, "destroy")
end

local function show(params)
    local skillinfo = params.skillinfo
    local skill =  skillinfo:GetSkill()
    if skill ==nil then
        logError("skill config error: skillid: ",skillinfo.skillid)
        return
    end

    printyellow("text:"..string.format("Lv:%s%s",skillinfo.level,RoleSkill.GetAmuletLabel(skill) ))
    fields.UILabel_LV01.text = string.format("Lv:%s%s",skillinfo.level,RoleSkill.GetAmuletLabel(skill) )
    fields.UILabel_SkillName01.text = skill:GetSkillName()
    fields.UITexture_Skill01:SetIconTexture(skill:GetSkillIcon())
    fields.UILabel_Discription.text =skill:GetSkillDescription()
    fields.UILabel_DiscriptionCheck.text =skill:GetSkillDetailDesc(skillinfo.level+RoleSkill.GetAmuletLevel(skill))
    
    
end

local function hide()
  --print(name, "hide")
end

local function update()
    
end

local function init(params)
--	FriendManager.init()
   	name, gameObject, fields = unpack(params)
    
    EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hide("skill.dlgdialogbox_skill")
    end )

end

--不写此函数 默认为 UIShowType.Default
local function uishowtype()
    --return UIShowType.Default
    --return UIShowType.ShowImmediate--强制在showtab页时 不回调showtab
    return UIShowType.Refresh  --强制在切换tab页时回调show
    --return bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)
end


return {
  init                      = init,
  show                      = show,
  hide                      = hide,
  update                    = update,
  destroy                   = destroy,
  refresh                   = refresh,
}
