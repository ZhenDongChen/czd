local PlotDefine    = require("plot.base.plotdefine");
local CharacterManager = require("character.charactermanager");

local CharacterAction = {};
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.LoadFunction = nil
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.StartFunction = function(self)
    self.Characters = {}
    if self.CharactorGetMode == "Id" then
        local character = CharacterManager.GetCharacter(self.CharactorId);
        table.insert(self.Characters, character)
    elseif self.CharactorGetMode == "Type" then
        for i,char in pairs(CharacterManager.GetCharacters()) do
            if char.m_Type == self.CharactorType then
                table.insert(self.Characters, char)
            end
        end
    else
        for i,char in pairs(CharacterManager.GetCharacters()) do
            table.insert(self.Characters, char)
        end
    end

    for i,char in pairs(self.Characters) do
        if self.CharactorAction == "Move" then
            local defineenum = require("defineenum")
            local targetPos = (((RelativeCoordinates == true) and char.m_Pos + self.TargetPosition) or self.TargetPosition)
            if self.Navigate == true and char.m_Type == defineenum.CharacterType.PlayerRole then
                char:navigateTo(targetPos)
            else
                if char.m_Type == defineenum.CharacterType.PlayerRole then
                    char:moveTo(targetPos)
                else
                    char:MoveTo(targetPos)
                end
            end
        elseif self.CharactorAction == "Jump" then
            char:Jump()
        elseif self.CharactorAction == "Skill" then
            char:PlaySkill(self.SkillId)
        elseif self.CharactorAction == "FreeAction" then
            char:PlayFreeAction(self.ActionName)
        elseif self.CharactorAction == "Revive" then
            char:Revive()
        elseif self.CharactorAction == "Dead" then
            char:Death()
        end
    end

    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.LoopFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.EndFunction = function(self)

    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterAction.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return CharacterAction;
