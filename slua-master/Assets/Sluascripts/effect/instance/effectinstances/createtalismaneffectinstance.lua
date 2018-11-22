local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"
local EffectInstanceAlignType       = defineenum.EffectInstanceAlignType
local ESpecialType                  = defineenum.ESpecialType
local uimanager                     = require("uimanager")
--local dlgcreatplayer                 = require"ui.dlgcreatplayer"
local Instance                = require "effect.instance.instance"


local CreatTalismanffectInstance = Class:new(EffectInstance)



function CreatTalismanffectInstance:CheckCanShow()
    if uimanager.hasloaded "dlgcreatplayer" == false then
        return false
    end
    local dlgcreatplayer  = require"ui.dlgcreatplayer"
    local  playerObj =  dlgcreatplayer.getTalismanObj()
    if playerObj ==nil or
            IsNull(playerObj.m_Object) or
            IsNullOrEmpty(self.EffectInstanceData.Path) then
        return false
    end
    return true
end

function CreatTalismanffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect.UseTargetPos then
        vecPos = self.ParentEffect.TargetPos
    else

        local dlgcreatplayer  = require"ui.dlgcreatplayer"
        local  playerObj =  dlgcreatplayer.getTalismanObj()
        vecPos =self:GetBindPos(playerObj,self.EffectInstanceData.CasterBindType)
    end

    if self.EffectInstanceData.AlignType ~= EffectInstanceAlignType.None then
        vecPos = self:ModifyBornPosByAlignType()
    end
    return vecPos;
end


function CreatTalismanffectInstance:UpdateTransform()
    local dlgcreatplayer  = require"ui.dlgcreatplayer"
    local  playerObj =  dlgcreatplayer.getTalismanObj()
    self:UpdateRotation()
    self:SetPosition(self:GetBindPos(playerObj,self.EffectInstanceData.CasterBindType))


end



function CreatTalismanffectInstance:UpdateRotation()
    if Local.LogModuals.EffectManager then
        printyellow("EffectInstance:UpdateRotation()",Time.time,self.EffectInstanceData.FollowBoneDirection,self.EffectInstanceData.FollowDirection,self.ParentEffect:Caster())
    end

    local dlgcreatplayer  = require"ui.dlgcreatplayer"
    local  playerObj =  dlgcreatplayer.getTalismanObj()

    local bonetrans = self:GetBindTransform(playerObj,self.EffectInstanceData.CasterBindType)
    if self.EffectInstanceData.FollowBoneDirection and self.EffectInstanceData.CasterBindType == 0 then
        self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
    elseif self.EffectInstanceData.FollowBoneDirection and bonetrans~=nil then
        self.Object.transform.rotation = bonetrans.rotation * self.EffectInstanceData.Rot
        if Local.LogModuals.EffectManager then
            printyellow("FollowBoneDirection")
            printt(bonetrans.rotation.eulerAngles)
            printt(self.EffectInstanceData.Rot.eulerAngles)
            printt(self.Object.transform.rotation.eulerAngles)
        end
    elseif self.EffectInstanceData.FollowDirection then
        if playerObj and playerObj.m_Object then
            self.Object.transform.rotation = playerObj.m_Object.transform.rotation * self.EffectInstanceData.Rot
            if Local.LogModuals.EffectManager then
                printyellow("FollowDirection")
                printt(playerObj.m_Object.transform.rotation.eulerAngles)
                printt(self.EffectInstanceData.Rot.eulerAngles)
                printt(self.Object.transform.rotation.eulerAngles)
            end
        end
    else
        if Local.LogModuals.EffectManager then
            printyellow("DefaultDirection")
        end
        self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
    end
end



function CreatTalismanffectInstance:Update()
    Instance.Update(self)
    if not self.Loaded then
        self:UpdateLoad()
    end

    if self.Object == nil or
            self.ParentEffect ==nil or
            not self.Visible or
            self.Dead then
        return
    end

    local dlgcreatplayer  = require"ui.dlgcreatplayer"
    local  playerObj =  dlgcreatplayer.getTalismanObj()
    if playerObj == nil or playerObj.m_Object == nil then
        self:Destroy()
    end


    if self.EffectInstanceData.Life > 0 and Time.time - self.BornTime >= self.EffectInstanceData.Life + self.ParentEffect.PauseTime or
            self.ParentEffect.FadeOut and Time.time - self.ParentEffect.FadeOutTime >= self.EffectInstanceDate.FadeOutTime then
        self:Destroy()
        return
    end

    if self.Object then
        self:UpdateTransform()

    end

end





return CreatTalismanffectInstance
