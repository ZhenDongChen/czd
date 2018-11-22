local RoleSkill  = require "character.skill.roleskill"
local PlayerRole = require "character.playerrole"
local SettingManager = require "character.settingmanager"
local CharacterManager = require "character.charactermanager"
local autoai = require "character.ai.autoai"

local defineenum   = require "defineenum"
local autoaievents = defineenum.AutoAIEvent
------------------------------------------------------------------------------------------
-- class FSMState
------------------------------------------------------------------------------------------
local FSMState = Class.new() 
  
function FSMState:__new()  
end  
   
function FSMState:Enter()  
end  
   
function FSMState:Exit()  
end  

function FSMState:OnEvent(event)
end


------------------------------------------------------------------------------------------
-- class FSMStateAttack
------------------------------------------------------------------------------------------
local FSMStateAttack = Class:new(FSMState)

function  FSMStateAttack:__new()
    self.skillids = nil
    self.skillidx = 1  
    self.skillnum = 0
end

function FSMStateAttack:ResetSkillsInProlgue()
	local AllSkills =  RoleSkill.GetRoleSkillInfo():GetAllSkills()
	local allskillids = {}
	for _,skillinfo in pairs(AllSkills) do 
        if  not skillinfo:GetSkill():IsPassive() then 	
			local item ={}
			item.skillid = skillinfo:GetSkill().OriginalSkillId
			item.actived = true
			table.insert(allskillids,item)
        end 
    end
    self.skillids = {}
	for _, skill in pairs(allskillids) do
		table.insert(self.skillids,skill.skillid)
	end
    self.skillnum = #self.skillids
    self.skillidx = 1
    Util.LogWarning("FSMStateAttack:ResetSkillsInProlgue num:"..self.skillnum)
end

function FSMStateAttack:ResetSkills()
	local AllEquipedSkills =  RoleSkill.GetRoleSkillInfo():GetEquipedSkills()--GetAllSkills()
	local allskillids = {}

    for _,itSkillId in pairs(AllEquipedSkills) do 
        local skillinfo = RoleSkill.GetRoleSkillInfo():GetSkillInfoBySkillId(itSkillId);
        if  not skillinfo:GetSkill():IsPassive() then 			
			local item ={}
			if skillinfo.actived then
				item.skillid = skillinfo:GetSkill().OriginalSkillId
				item.actived = true
				table.insert(allskillids,item)
			else
				table.insert(allskillids,item)
			end 
        end 
    end

    local sids = {}
	local SettingAF = SettingManager.GetSettingAutoFight()
	for index, skill in pairs(allskillids) do
		if SettingAF["Skill" ..index] and skill.actived then
			table.insert(sids,skill.skillid)
		end
	end
    
    self.skillids = {}
    local num = 0
    local roleconfig = ConfigManager.getConfig("roleconfig")
    for _, sp in pairs(roleconfig.aotoskillpriority) do 
        if sp.career == PlayerRole:Instance().m_Profession then
            for _, id in pairs(sp.skillpriority) do 
                num = num + 1
                if  num == 4 then
                    if RoleSkill.GetRoleSkillByIndex(-1) ~=nil then   --��������
		                local skillid = RoleSkill.GetRoleSkillByIndex(-1).m_FirstSkillId
                        --printyellow("talisman skill id is " , skillid)
                        if SettingAF["Skill7"] then
		                    table.insert(self.skillids,skillid)
                        end
                    end                         
                end
                for _, dd in pairs(sids) do 
                    if id == dd then
                        table.insert(self.skillids, dd)
                    end
                end
            end
        end
    end

    self.skillnum = #self.skillids
    self.skillidx = self.skillnum
end

function FSMStateAttack:GetNextSkillIndex(index)
    local newidx = index + 1
    if newidx > self.skillnum then
        newidx = 1
    end
    return newidx
end

function FSMStateAttack:Attack()
    if CharacterManager.GetRoleNearestAttackableTarget4AI() then
 	    if PlayerRole:Instance():CanAttack() then
            --printyellow("try to attack ", self.skillidx,  self.skillnum)
            local oldidx = self.skillidx
            local newidx = self:GetNextSkillIndex(self.skillidx)
            --while(newidx ~= oldidx) do
            for i = 1, self.skillnum do
			    if PlayerRole:Instance().m_RoleSkillFsm:TryToAttackBySkillId(self.skillids[newidx]) then
                    --print("now sill id is ", newidx, self.skillids[newidx])
				    self.skillidx = newidx
				    break
			    end                  
                newidx = self:GetNextSkillIndex(newidx)
            end

            if (self.skillidx == oldidx) then
                PlayerRole:Instance().m_RoleSkillFsm:OnButtonCastSkill(0)
            end 
        else
            printyellow("attack now failure.......")               
        end  
    end                   
end


function FSMStateAttack:OnEvent(event)
    if event == autoaievents.skillover or event == autoaievents.monster then 
        self:Attack()                            
    end
end

function FSMStateAttack:ResetSkillIndex()
    self.skillidx = self.skillnum
end

------------------------------------------------------------------------------------------
-- class FSMStateIdle
------------------------------------------------------------------------------------------

local ifunc = function() 
    if CharacterManager.GetRoleNearestAttackableTarget4AI() then 
        autoai.OnEvent(autoaievents.monster) 
    end 
end


local FSMStateIdle = Class:new(FSMState)

function  FSMStateIdle:__new()
    self.timer = Timer.New(ifunc, 2, -1)
    
end

function FSMStateIdle:Enter()
    self.timer:Reset(ifunc, 2, -1)
    self.timer:Start()
    local frametimer = FrameTimer.New(ifunc,3,1)
    frametimer:Start()
end

function FSMStateIdle:Exit()
    self.timer:Stop()
end

------------------------------------------------------------------------------------------
-- class FSMStateJoyMove
------------------------------------------------------------------------------------------

local FSMStateJoyMove = Class:new(FSMState)

local jfunc = function()    
    autoai.OnEvent(autoaievents.joystop) 
end

function  FSMStateJoyMove:__new()
    self.timer = Timer.New(jfunc, 2, false)
end

function FSMStateJoyMove:OnEvent(event)
    if event == autoaievents.nojoy then    
        self.timer:Reset(jfunc, 2, false)
        self.timer:Start()
    end    
end


------------------------------------------------------------------------------------------
-- class FSMStateNone
------------------------------------------------------------------------------------------
local FSMStateNone = Class:new(FSMState)

function  FSMStateNone:__new()

end



------------------------------------------------------------------------------------------
-- class FSMStateAutoMove
------------------------------------------------------------------------------------------
local FSMStateAutoMove = Class:new(FSMState)

function  FSMStateAutoMove:__new()
    self.pos  = nil
end

function FSMStateAutoMove:OnEvent(event)
    if event == autoaievents.automove and self.pos then
          PlayerRole:Instance():navigateTo( {
                targetPos = self.pos,
                notStopAutoFight = true,
                callback = function()
                    --printyellow("autoai, nav to org pos..", self.pos)
                    autoai.OnEvent(autoaievents.backtopos)
                end
            } )    
    end
end

function FSMStateAutoMove:RecordStartPos(pos)
    self.pos = pos    
end
------------------------------------------------------------------------------------------
-- class end
------------------------------------------------------------------------------------------

return 
{
    FSMStateNone = FSMStateNone,
    FSMStateJoyMove = FSMStateJoyMove,
    FSMStateIdle = FSMStateIdle,
    FSMStateAttack = FSMStateAttack,
    FSMStateAutoMove = FSMStateAutoMove,

}