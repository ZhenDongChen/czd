local Unpack=unpack
local UIManager=require"uimanager"

local m_Name
local m_GameObject
local m_Fields 
local m_ShowEffect=nil
local m_EffectObject=nil
local m_EffectBeginTime=nil
local m_EffectDir=nil
local m_TargetPos=nil
local m_PlayParticle=nil
local m_Particle=nil

local function Clear()
    m_ShowEffect=nil 
    m_EffectBeginTime=nil
    m_EffectDir=nil
    m_TargetPos=nil
    m_EffectObject.gameObject:SetActive(false)
    m_EffectObject.gameObject.transform.position=Vector3.zero    
    m_PlayParticle=nil          
end

local function hide()
    Clear()
end

local function destroy()
end

local function update()
    if m_ShowEffect==true then
        if m_EffectObject and m_EffectBeginTime and m_EffectDir and m_TargetPos then
            m_EffectObject.transform:Translate(m_EffectDir*(Time.deltaTime), UnityEngine.Space.World)
            local distance = math.sqrt((m_TargetPos.x-m_EffectObject.transform.position.x)^2+(m_TargetPos.y-m_EffectObject.transform.position.y)^2)
            --printt(m_EffectObject.transform.position)
            --printyellow("distance:",distance)
            if (distance < 0.1) then
               m_ShowEffect=nil 
               m_EffectBeginTime=nil
               m_EffectDir=nil
               m_EffectObject.gameObject.transform.position=Vector3.zero   
               m_EffectObject.gameObject:SetActive(false)
               m_Fields.UIGroup_ShereLightEffect.gameObject.transform.position=m_TargetPos
               UIManager.PlayUIParticleSystem(m_Fields.UIGroup_ShereLightEffect.gameObject)
               m_PlayParticle=true
               m_TargetPos=nil
            end
        end
    end
    if m_PlayParticle then
        if not UIManager.IsPlaying(m_Fields.UIGroup_ShereLightEffect.gameObject) then
            m_PlayParticle=nil
            UIManager.StopUIParticleSystem(m_Fields.UIGroup_ShereLightEffect.gameObject)
            UIManager.hide(m_Name)
        end
    end
end

local function DisplayCurveEffect()        
--    local particle = m_EffectObject:GetComponent("ParticleSystem")
--    if particle then
--        particle:Stop(true)
--        particle:Play(true)
--    end
    m_EffectObject.gameObject.transform.position=Vector3.zero
    m_EffectObject.gameObject:SetActive(true)
    m_EffectDir = Vector3(m_TargetPos.x - m_EffectObject.gameObject.transform.position.x, m_TargetPos.y - m_EffectObject.gameObject.transform.position.y, 0)
    m_EffectBeginTime=Time.time
    m_ShowEffect=true     
end

local function show(params)
    local targetId=params.targetId
--    local DlgUIMain_Combat=require"ui.dlguimain_combat"
--    local target=DlgUIMain_Combat.GetSkillItemPos(targetId)
    local DlgUIMain_Novice=require"ui.dlguimain_novice"
    local target=DlgUIMain_Novice.GetItemPos(targetId)
    if target then
        m_TargetPos=Vector3(target.x,target.y,0)
        DisplayCurveEffect()
    else
        hide()
    end
end

local function refresh()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
    m_EffectObject=m_GameObject.transform:Find("ui_unlock")
    m_Particle=m_Fields.UIGroup_ShereLightEffect.gameObject:GetComponent("ParticleSystem")
end

return{
    init = init,
    update = update,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    Clear = Clear,
}