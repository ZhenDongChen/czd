
local defineenum 	= require "defineenum"
local WorkType 		= defineenum.WorkType
local CharState 	= defineenum.CharState
local Work 			= require "character.work.work"
local mathutils 	= require "common.mathutils"
local SceneMgr 		= require "scenemanager"


local FreeActionWork = Class:new(Work)


function FreeActionWork:__new()
    Work.__new(self)
    self:reset()
    self.currentPlayState = false
    self.lastPlayState = false
    self.type = WorkType.FreeAction
end

function FreeActionWork:reset()
    Work.reset(self)
    self.AnimName = nil
end

function FreeActionWork:CanDo()
    if not Work.CanDo(self) then
        return false
    end
    return true
end

function FreeActionWork:OnStart()
    Work.OnStart(self)
    self.currentPlayState = false
    self.lastPlayState = false
    if self.AnimName ~= nil then
        self.Character:PlayAction(self.AnimName)
    else
        self:End()
    end
end

function FreeActionWork:OnEnd()
    Work.OnEnd(self)
  --  self.currentPlayState = false
  --  self.lastPlayState = false
end

function FreeActionWork:OnUpdate()
    Work.OnUpdate(self)
    self.currentPlayState = self.Character:IsPlayingAction(self.AnimName)
    if self.currentPlayState == true and self.lastPlayState == false then
        self.lastPlayState = true
    end
    if self.currentPlayState == false and self.lastPlayState == true then
        self:End()
    end 

end

return FreeActionWork
