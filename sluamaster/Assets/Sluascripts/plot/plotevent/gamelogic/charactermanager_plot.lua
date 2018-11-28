local PlotDefine = require("plot.base.plotdefine");
local CharacterMgr = require("character.charactermanager");

local CharacterManager = {};
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.StartFunction = function(self,container,cutscene)
    if self.Mode == "Add" then
        CharacterMgr.AddLocalCharacter(self.CharacterId, self.CharacterType, self.CharacterName ,self.Position, self.Rotation, self.Profession, nil, nil );
    elseif self.Mode == "Remove" then
        if FindByName == true then
            self.Object = PlotDirector.Instance:FindGameObject(self.CharacterName);
            if self.Object ~= nil then
                for i,character in pairs(CharacterMgr.GetLocalCharacters()) do
                    if character.m_Object == self.Object then
                        self.character=character;
                    end
                end
            end
        else
            self.character = CharacterMgr.GetLocalCharacter(self.CharacterId);
        end
        if self.character ~= nil then
            CharacterMgr.RemoveLocalCharacter(self.character.id);
        end
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.LoopFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.EndFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterManager.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return CharacterManager;
