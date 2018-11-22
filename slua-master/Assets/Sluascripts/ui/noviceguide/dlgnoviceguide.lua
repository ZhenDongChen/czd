local Unpack = unpack
local EventHelper = UIEventListenerHelper
local NoviceGuideManager = require"noviceguide.noviceguidemanager"
local NoviceGuideLockObj = require"noviceguide.noviceguide_lockobject"
local NoviceGuideTrigger
local m_GameObject
local m_Name
local m_Fields
local m_DelayTime=0
local m_State=nil
local m_HLDelayState=nil
local m_HLDelayTime=0
local m_DisplaySkill=nil
local m_OpenModule=nil
local m_OpenModuleTime=0

local function show(params)
    m_GameObject.transform.localPosition=Vector3(0,0,-600)
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        NoviceGuideManager.PlayAudio(guideData.audio)
    end
end

local function Clear()
    m_Fields.UIGroup_Figure.gameObject:SetActive(false)
    m_Fields.UIGroup_Pop.gameObject:SetActive(false)
    m_Fields.UIGroup_Arrow.gameObject:SetActive(false)
    m_Fields.UIGroup_Unlock.gameObject:SetActive(false)
    m_Fields.UILabel_Unlock.gameObject:SetActive(false)
    m_Fields.UIGroup_NewSkill.gameObject:SetActive(false)
    m_Fields.UIGroup_Hand.gameObject:SetActive(false)
    --m_Fields.UILabel_Tip.gameObject:SetActive(false) 
    m_Fields.UILabel_UnlockDes.gameObject:SetActive(false)
    m_Fields.UISprite_Block.gameObject:SetActive(true)
    m_Fields.UIButton_Skip.gameObject:SetActive(false)
    m_Fields.UIGroup_SkillDes.gameObject:SetActive(false)
    m_DisplaySkill=nil
    m_OpenModule=nil
end

local function hide()
    Clear()
end

local function GetPanel()
    return m_Fields.UIPanel_Copy
end

local function HideGroupPop()
    local npcData=NoviceGuideManager.GetEffectByType("cfg.guide.NPC")  
    if npcData then
        if npcData.type==0 then
            local UIGroup_PopLeft=m_Fields.UISprite_ArrowLeft.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopRight=m_Fields.UISprite_ArrowRight.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopDown=m_Fields.UISprite_ArrowDown.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopUp=m_Fields.UISprite_ArrowUp.gameObject.transform:Find("UIGroup_Pop")
            UIGroup_PopLeft.gameObject:SetActive(false)      
            UIGroup_PopRight.gameObject:SetActive(false)       
            UIGroup_PopDown.gameObject:SetActive(false)  
            UIGroup_PopUp.gameObject:SetActive(false)
        end
    end
end

local function DisplayNPC()
    local npcData=NoviceGuideManager.GetEffectByType("cfg.guide.NPC")  
    if npcData then     
        if npcData.type==1 then
            local UIGroup_PopLeft=m_Fields.UISprite_ArrowLeft.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopRight=m_Fields.UISprite_ArrowRight.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopDown=m_Fields.UISprite_ArrowDown.gameObject.transform:Find("UIGroup_Pop")
            local UIGroup_PopUp=m_Fields.UISprite_ArrowUp.gameObject.transform:Find("UIGroup_Pop")
            local lockObj=NoviceGuideManager.GetLockedObj()          
            UIGroup_PopLeft.gameObject:SetActive((lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.LEFT))      
            UIGroup_PopRight.gameObject:SetActive((lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.RIGHT))       
            UIGroup_PopDown.gameObject:SetActive((lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.DOWN))  
            UIGroup_PopUp.gameObject:SetActive((lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.UP))
            local UILabel_Pop=nil
            local tempObj=nil
            if (lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.LEFT) then
                tempObj=UIGroup_PopLeft.gameObject.transform:Find("UILabel_Pop")                           
            elseif (lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.RIGHT) then
                tempObj=UIGroup_PopRight.gameObject.transform:Find("UILabel_Pop")
            elseif (lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.DOWN) then
                tempObj=UIGroup_PopDown.gameObject.transform:Find("UILabel_Pop")
            elseif (lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.UP) then
                tempObj=UIGroup_PopUp.gameObject.transform:Find("UILabel_Pop")
            end   
            UILabel_Pop= tempObj.gameObject:GetComponent("UILabel")
            UILabel_Pop.text=npcData.text             
        elseif npcData.type==0 then
            m_Fields.UIGroup_Figure.transform.localPosition=Vector3(npcData.dialogpos[1],npcData.dialogpos[2],0) + Vector3(70,0,0)
            m_Fields.UILabel_Figure.text=npcData.text
            --local PlayerRole=require"character.playerrole"
            --if PlayerRole.Instance().m_Gender==cfg.role.GenderType.MALE then
                --m_Fields.UITexture_Figure:SetIconTexture("npc_biyao")
            --elseif PlayerRole.Instance().m_Gender==cfg.role.GenderType.FEMALE then
                --m_Fields.UITexture_Figure:SetIconTexture("npc_zhangxiaofan")
            --end
            m_Fields.UIGroup_Figure.gameObject:SetActive(true)   
        end
    end
end

local function DisplayHightLight()
    local lockObj=NoviceGuideManager.GetLockedObj()
    if lockObj and lockObj.lockedObjectData then
        local npcData=NoviceGuideManager.GetEffectByType("cfg.guide.NPC")
        m_Fields.UISprite_Circle.gameObject:SetActive(true)
        m_Fields.UISprite_Rectangle.gameObject:SetActive(false)
        m_Fields.UISprite_ArrowLeft.gameObject:SetActive(lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.LEFT)     
        m_Fields.UISprite_ArrowRight.gameObject:SetActive(lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.RIGHT)      
        m_Fields.UISprite_ArrowDown.gameObject:SetActive(lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.DOWN)         
        m_Fields.UISprite_ArrowUp.gameObject:SetActive(lockObj.lockedObjectData.arrowtype==cfg.guide.Direction.UP)             
        if lockObj.lockedObjectData.bordertype==cfg.guide.BorderType.CIRCLE then
            m_Fields.UISprite_Circle.transform.localScale=Vector3(lockObj.lockedObjectData.scale[1],lockObj.lockedObjectData.scale[1],1)
        elseif lockObj.lockedObjectData.bordertype==cfg.guide.BorderType.RECTANGLE then
            m_Fields.UISprite_Rectangle.transform.localScale=Vector3(lockObj.lockedObjectData.scale[1],lockObj.lockedObjectData.scale[1],1)
        end
        if (lockObj.lockedObjectData.fixorbind==true) then
            m_Fields.UIGroup_Arrow.transform.position=lockObj.targetUIObject.gameObject.transform.position
            --local objWidget = lockObj.targetUIObject.gameObject:GetComponent("UIWidget")
            --if objWidget then
            --    m_Fields.UISprite_Circle.width = objWidget.width + 20
            --    m_Fields.UISprite_Circle.width = objWidget.height + 20
            --else
            --    m_Fields.UISprite_Circle.width = objWidget.width + 130
            --    m_Fields.UISprite_Circle.width = objWidget.height + 130
            --end

            local pos=m_Fields.UIGroup_Arrow.transform.localPosition
            m_Fields.UIGroup_Arrow.transform.localPosition=Vector3(pos.x+lockObj.lockedObjectData.offset[1],pos.y+lockObj.lockedObjectData.offset[2],0)
        else    
            m_Fields.UIGroup_Arrow.transform.localPosition=Vector3(lockObj.lockedObjectData.offset[1],lockObj.lockedObjectData.offset[2],0)
        end
        m_Fields.UIGroup_Arrow.gameObject:SetActive(true)
        HideGroupPop()
    end
end

local function DisplayLockUI()
    NoviceGuideLockObj.LockUIObj()   
    if NoviceGuideManager.IsMandatory()==true then
        local delayTime=NoviceGuideManager.GetDelayTime()
        if delayTime==0 then  
            m_State=nil      
            NoviceGuideLockObj.DealLockedObject() 
        elseif delayTime>0 then
            m_DelayTime=delayTime
            m_State=true
        end
    end
end

local function DisplaySlider()
    local sliderData=NoviceGuideManager.GetEffectByType("cfg.guide.Slider")  
    if sliderData then       
        m_Fields.UIGroup_Hand.gameObject.transform.localPosition=Vector3(sliderData.pos[1],sliderData.pos[2],0)
        m_Fields.UISprite_Hand.gameObject.transform.localEulerAngles=(Vector3.forward)*(sliderData.fromRotation)
        local tweenPos=m_Fields.UISprite_Hand.gameObject:GetComponent("TweenRotation")
        if tweenPos then
            tweenPos.from=(Vector3.forward)*(sliderData.fromRotation)
            tweenPos.to=(Vector3.forward)*(sliderData.toRotation)
        end
        m_Fields.UISprite_Hand.gameObject:SetActive(true)
        m_Fields.UIGroup_Hand.gameObject:SetActive(true)
    end
end

local function SetBlock()
    m_Fields.UIGroup_Unlock.gameObject:SetActive(true)
    m_Fields.UISprite_Block.gameObject:SetActive(true)
    m_Fields.UILabel_Unlock.gameObject:SetActive(false)
    m_Fields.UIGroup_NewSkill.gameObject:SetActive(false)
    --m_Fields.UILabel_Tip.gameObject:SetActive(false) 
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        if guideData.isdisskipbutton==true then
            m_Fields.UIButton_Skip.gameObject:SetActive(true)
            EventHelper.SetClick(m_Fields.UIButton_Skip,function()
                local NoviceGuideFsm=require"noviceguide.noviceguide_fsm"
                NoviceGuideFsm.SkipGuide() 
            end)
        end
    end
end

local function DisplayClickOver()
    SetBlock()
    EventHelper.SetClick(m_Fields.UISprite_Block,function()
        NoviceGuideTrigger.ClickAnyWhere()
    end)
end

local function DisplayNewItem()
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        local displayEffect=NoviceGuideManager.GetEffectByType("cfg.guide.Display")
        if displayEffect then
            if displayEffect.icon and displayEffect.icon~="" then
                if displayEffect.istexture==true then
                    m_Fields.UITexture_Skill:SetIconTexture(displayEffect)
                    m_Fields.UISprite_Function.gameObject:SetActive(false)
                    m_Fields.UITexture_Skill.gameObject:SetActive(true)
                else
                    m_Fields.UITexture_Skill.gameObject:SetActive(false)
                    m_Fields.UISprite_Function.spriteName=displayEffect.icon
					          m_Fields.UISprite_Function.gameObject:SetActive(true)
                end   
                if displayEffect.desc and displayEffect.desc~="" then             
                    m_Fields.UILabel_Unlock.text=displayEffect.desc   
                    m_Fields.UILabel_Unlock.gameObject:SetActive(true)
                end
                if displayEffect.desc1 and displayEffect.desc1~="" then
                    m_Fields.UILabel_UnlockDes.text=displayEffect.desc1    
                    m_Fields.UILabel_UnlockDes.gameObject:SetActive(true)
                end  
                if displayEffect.target then
                    NoviceGuideManager.SetDisplayEffect(true)
                    NoviceGuideManager.SetTargetId(displayEffect.target)
                    m_OpenModule=true
                    m_OpenModuleTime=cfg.guide.NoviceGuide.OPENFORCETIME
                end      
            else
                for _,condition in pairs(guideData.triggerconditions) do
                    if condition.class=="cfg.cmd.condition.OwnSkill" then                     
                        local PlayerRole=require"character.playerrole"
                        local skillid=condition.skillids[PlayerRole:Instance().m_Profession]
                        if skillid then
                            local playerSkillData=PlayerRole:Instance().PlayerSkill:GetPlayerSkill(skillid)
                            if playerSkillData then
                                m_Fields.UILabel_Unlock.text=string.format(LocalString.OwnNewSkill,playerSkillData:GetCurrentSkill():GetSkillName())
                                m_Fields.UITexture_Skill:SetIconTexture(playerSkillData:GetCurrentSkill():GetSkillIcon())
                                m_Fields.UISprite_Function.gameObject:SetActive(false)
                                m_Fields.UITexture_Skill.gameObject:SetActive(true)
                                NoviceGuideManager.SetDisplayEffect(true)
                                NoviceGuideManager.SetTargetId(skillid)
                            end
                        end  
                    end              
                end
            end         
            --m_Fields.UILabel_Tip.gameObject:SetActive(true)
            m_Fields.UIGroup_NewSkill.gameObject:SetActive(true)
        end
    end   
    m_Fields.UIGroup_Unlock.gameObject:SetActive(true)
    m_Fields.UISprite_Block.gameObject:SetActive(true)
    EventHelper.SetClick(m_Fields.UISprite_Block,function()
        if m_OpenModule~=true then
            NoviceGuideTrigger.ClickAnyWhere()
        end
    end) 
end

local function DisplaySkill()
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        local displayEffect=NoviceGuideManager.GetEffectByType("cfg.guide.DisplaySkill")
        if displayEffect then
            for _,condition in pairs(guideData.triggerconditions) do
                if condition.class=="cfg.cmd.condition.OwnSkill" then
                    local PlayerRole=require"character.playerrole"
                    local skillid=condition.skillids[PlayerRole:Instance().m_Profession]
                    if skillid then
                        local playerSkillData=PlayerRole:Instance().PlayerSkill:GetPlayerSkill(skillid)
                        if playerSkillData then
                            m_Fields.UITexture_SkillIcon:SetIconTexture(playerSkillData:GetCurrentSkill():GetSkillIcon())
                            local DlgUIMain_Combat=require"ui.dlguimain_combat"
                            local target=DlgUIMain_Combat.GetSkillItemPos(skillid)
                            if target~=nil then
                                m_DisplaySkill=nil
                                local targetPos=Vector3(target.x,target.y,0)
                                m_Fields.UIGroup_SkillDes.gameObject.transform.position=targetPos
                                local textId=displayEffect.desc[PlayerRole:Instance().m_Profession]
                                if (textId) then
                                    local ConfigManager=require"cfg.configmanager"
                                    local textData=ConfigManager.getConfigData("noviceguidetext",textId)
                                    if textData and textData.desc then
                                        m_Fields.UILabel_SkillDes.text=textData.desc
                                    end
                                end  
                                m_Fields.UIGroup_SkillDes.gameObject:SetActive(true)
                            else
                                m_DisplaySkill=true
                            end
                        end
                    end  
                end
            end
            EventHelper.SetClick(m_Fields.UISprite_Block,function()
                NoviceGuideTrigger.ClickAnyWhere()
            end)
        end
    end
end

local function refresh(params) 
    Clear()
    if NoviceGuideManager.IsGuiding() then
        if NoviceGuideManager.IsMandatory()==true then
            SetBlock()
        end
        if (NoviceGuideManager.GetEffectByType("cfg.guide.LockUI")~=nil) then
            m_HLDelayState=true
            m_HLDelayTime=0.5
           -- DisplayHightLight()
            DisplayLockUI()
        end  
        if (NoviceGuideManager.GetEffectByType("cfg.guide.NPC")~=nil) then
            DisplayNPC()
        end   
        if (NoviceGuideManager.GetEffectByType("cfg.guide.Slider")~=nil) then
            DisplaySlider()
        end
        if (NoviceGuideManager.GetEffectByType("cfg.guide.ClickOver")~=nil) then
            DisplayClickOver()
        end
        if (NoviceGuideManager.GetEffectByType("cfg.guide.Display")~=nil) then
            DisplayNewItem()
        end
        if (NoviceGuideManager.GetEffectByType("cfg.guide.DisplaySkill")~=nil) then
            DisplaySkill()
        end
        
    end
end

local function destroy()
end

local function update()
    if m_State==true then
        m_DelayTime=m_DelayTime-Time.deltaTime
        if m_DelayTime<=0 then
            m_State=nil
            NoviceGuideLockObj.DealLockedObject()
        end
    end
    if m_HLDelayState==true then
        m_HLDelayTime=m_HLDelayTime-Time.deltaTime
        if m_HLDelayTime<=0 then
            m_HLDelayState=nil
            DisplayHightLight()
        end
    end
    if m_DisplaySkill==true then
        DisplaySkill()
    end
    if m_OpenModule then
        m_OpenModuleTime=m_OpenModuleTime-Time.deltaTime
        if m_OpenModuleTime<=0 then
            m_OpenModule=nil
        end
    end
end

local function init(params)
     m_Name, m_GameObject, m_Fields = Unpack(params)   
     NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
     m_DisplaySkill=nil
     m_OpenModule=nil
    m_Fields.UITexture_Biyao:SetIconTexture("npc_biyao")
end

return{
    init = init,
    update = update,
    show = show,
    hide = hide,
    refresh = refresh,
    destroy = destroy,
    GetPanel = GetPanel,
}