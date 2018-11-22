local unpack = unpack
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local familymanager = require("family.familymanager")
local FamilyRoundRobinManager = require("family.familyroundrobinmanager")
local Monster = require("character.monster")
local Define = require("define")
local ConfigManager = require("cfg.configmanager")
local Format = string.format

local m_Name
local m_GameObject
local m_Fields

local m_battleinfo1
local m_battleinfo2
local m_battleinfo3
local m_battleinfo4
local m_AnimalInfo
local m_BossModel
local m_warInfo
local m_BossIndex

local function GetBossId(index, level)
    local bossesCfg = ConfigManager.getConfig("boss")
    local bossid = 0
    if index <= #bossesCfg then
        bossid = bossesCfg[index].bossinfo[level].monsterid
    end
    return bossid
end

local function GetBossName(index)
    local bossesCfg = ConfigManager.getConfig("boss")
    local bossname = ""
    if index <= #bossesCfg then
        bossname = bossesCfg[index].name
    end
    return bossname
end

local function OnBossModelLoaded(obj)
    local bossesCfg = ConfigManager.getConfig("boss")
    local offsety = -200
    local scale = 100
    local bosscfg = bossesCfg[m_BossIndex]
    if bossesCfg then       
        if bosscfg.offsety then
            offsety = bosscfg.offsety
        end
        if bosscfg.scale then
            scale = bosscfg.scale
        end
    end

    local bossTrans           = obj.transform
    bossTrans.parent          = m_Fields.UITexture_3DModel.gameObject.transform
	bossTrans.localScale      = Vector3.one*scale
    bossTrans.localPosition   = Vector3(0,offsety,-1000)
    bossTrans.localRotation   = Vector3.up*180
    ExtendedGameObject.SetLayerRecursively(obj,Define.Layer.LayerUICharacter)
    obj:SetActive(true)
    m_BossModel:PlayLoopAction(cfg.skill.AnimType.Stand)
end

local function ShowBossModel(bossIndex, bossLevel)
    if bossIndex == nil or bossIndex < 1 then
       return 
    end

    if m_BossModel then
        m_BossModel:release()
        m_BossModel=nil
    end

    m_BossIndex = bossIndex
    local bossid = GetBossId(m_BossIndex, bossLevel)
    m_BossModel = Monster:new()
    --m_BossModel.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_BossModel:RegisterOnLoaded(OnBossModelLoaded)
    m_BossModel:init(bossid, bossid, false)
end

local function destroy()
end

local function show(params)
    m_warInfo = FamilyRoundRobinManager.GetCurGame()
    m_AnimalInfo = FamilyRoundRobinManager.GetAnimalInfo()
    m_battleinfo1 = FamilyRoundRobinManager.GetRoundRobinStatus(1)  
    m_battleinfo2 = FamilyRoundRobinManager.GetRoundRobinStatus(2)
    m_battleinfo3 = FamilyRoundRobinManager.GetRoundRobinStatus(3)  
    m_battleinfo4 = FamilyRoundRobinManager.GetRoundRobinStatus(4)
    m_Fields.UILabel_Family_Green.text = Format(LocalString.Family.AboutWarName, familymanager.Info().flevel, familymanager.Info().familyname)
    m_Fields.UILabel_Mythical_Green.text = Format(LocalString.Family.AboutWarName, m_AnimalInfo.animal1level, GetBossName(m_AnimalInfo.animal1id))
    m_Fields.UILabel_MythicalName.text = Format(LocalString.Family.AboutWarName, m_AnimalInfo.animal1level, GetBossName(m_AnimalInfo.animal1id))   
    if m_warInfo.family2info.fid ~= familymanager.Info().familyid then
        m_Fields.UILabel_Family_Red.text = Format(LocalString.Family.AboutWarName,m_warInfo.family2info.familylvl, m_warInfo.family2info.familyname)
    else
        m_Fields.UILabel_Family_Red.text = Format(LocalString.Family.AboutWarName,m_warInfo.family1info.familylvl, m_warInfo.family1info.familyname)
    end
    m_Fields.UILabel_Mythical_Red.text = Format(LocalString.Family.AboutWarName,m_AnimalInfo.animal2level, GetBossName(m_AnimalInfo.animal2id)) 
    ShowBossModel(m_AnimalInfo.animal1id, m_AnimalInfo.animal1level)
end

local function hide()
    if m_BossModel then
        m_BossModel:release()
        m_BossModel=nil
    end
end

local function IsTowerOK(list, index)
    for id, towerindex in pairs(list) do
        if towerindex == index then
            return true
        end
    end
    return false
end

local function refresh(params)   
    m_battleinfo1 = FamilyRoundRobinManager.GetRoundRobinStatus(1)  
    m_battleinfo2 = FamilyRoundRobinManager.GetRoundRobinStatus(2)
    m_battleinfo3 = FamilyRoundRobinManager.GetRoundRobinStatus(3)  
    m_battleinfo4 = FamilyRoundRobinManager.GetRoundRobinStatus(4)

    if (m_battleinfo1) ~= nil then
        local myFamilyStatus = {}
        local enemyFamilyStatus = {}
        if m_battleinfo1.status1.familyid == familymanager.Info().familyid then
            myFamilyStatus = m_battleinfo1.status1
            enemyFamilyStatus = m_battleinfo1.status2
        else
            enemyFamilyStatus = m_battleinfo1.status1
            myFamilyStatus = m_battleinfo1.status2
        end

        m_Fields.UILabel_Player_Green_1.text = Format(LocalString.Family.AboutWarMemberNum, myFamilyStatus.membernum)
        m_Fields.UILabel_Score_Green_1.text = tostring(myFamilyStatus.score)
        m_Fields.UILabel_Player_Red_1.text = Format(LocalString.Family.AboutWarMemberNum, enemyFamilyStatus.membernum)
        m_Fields.UILabel_Score_Red_1.text = tostring(enemyFamilyStatus.score)

        local leftTimeSeces = m_battleinfo1.remaintime/1000
        if leftTimeSeces < 0 then
            leftTimeSeces = 0
        end 
        local leftTime = timeutils.getDateTime(leftTimeSeces)
        m_Fields.UILabel_Timer_1.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)

        if m_battleinfo1.result == -2 then
            local familywarConfig = ConfigManager.getConfig("familywar")
            if myFamilyStatus.membernum >= familywarConfig.maxfamilymembernum then
                m_Fields.UIButton_Area_1.isEnabled = false
                m_Fields.UILabel_Area_1.text = LocalString.Family.AboutWarAreaButttonMemFull
            else
                m_Fields.UIButton_Area_1.isEnabled = true
                m_Fields.UILabel_Area_1.text = LocalString.Family.AboutWarAreaButttonEnter
            end 
        else            
            m_Fields.UIButton_Area_1.isEnabled = false
            if m_battleinfo1.result == cfg.ectype.FamilyWarBattleResult.WIN then
                m_Fields.UILabel_Area_1.text = LocalString.Family.AboutWarAreaButttonWin
            else
                m_Fields.UILabel_Area_1.text = LocalString.Family.AboutWarAreaButttonFailed
            end        
        end

        m_Fields.UISprite_Green_Base_1.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_1.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_1.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_1.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_1.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_1.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 1))
        
        m_Fields.UISprite_Green_Base_Gray_1.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_Gray_1.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_Gray_1.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 1))        
        m_Fields.UISprite_Red_Base_Gray_1.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_Gray_1.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_Gray_1.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 1))
    end
    
    if (m_battleinfo2) ~= nil then
        local myFamilyStatus = {}
        local enemyFamilyStatus = {}
        if m_battleinfo2.status1.familyid == familymanager.Info().familyid then
            myFamilyStatus = m_battleinfo2.status1
            enemyFamilyStatus = m_battleinfo2.status2
        else
            enemyFamilyStatus = m_battleinfo2.status1
            myFamilyStatus = m_battleinfo2.status2
        end

        m_Fields.UILabel_Player_Green_2.text = Format(LocalString.Family.AboutWarMemberNum, myFamilyStatus.membernum)
        m_Fields.UILabel_Score_Green_2.text = tostring(myFamilyStatus.score)
        m_Fields.UILabel_Player_Red_2.text = Format(LocalString.Family.AboutWarMemberNum, enemyFamilyStatus.membernum)
        m_Fields.UILabel_Score_Red_2.text = tostring(enemyFamilyStatus.score)
        
        local leftTimeSeces = m_battleinfo2.remaintime/1000
        if leftTimeSeces < 0 then
            leftTimeSeces = 0
        end 
        local leftTime = timeutils.getDateTime(leftTimeSeces)
        m_Fields.UILabel_Timer_2.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)

        if m_battleinfo2.result == -2 then
            local familywarConfig = ConfigManager.getConfig("familywar")
            if myFamilyStatus.membernum >= familywarConfig.maxfamilymembernum then
                m_Fields.UIButton_Area_2.isEnabled = false
                m_Fields.UILabel_Area_2.text = LocalString.Family.AboutWarAreaButttonMemFull
            else
                m_Fields.UIButton_Area_2.isEnabled = true
                m_Fields.UILabel_Area_2.text = LocalString.Family.AboutWarAreaButttonEnter
            end                    
        else
            m_Fields.UIButton_Area_2.isEnabled = false
            if m_battleinfo2.result == cfg.ectype.FamilyWarBattleResult.WIN then
                m_Fields.UILabel_Area_2.text = LocalString.Family.AboutWarAreaButttonWin
            else
                m_Fields.UILabel_Area_2.text = LocalString.Family.AboutWarAreaButttonFailed
            end  
        end

        m_Fields.UISprite_Green_Base_2.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_2.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_2.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_2.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_2.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_2.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 1))
        
        m_Fields.UISprite_Green_Base_Gray_2.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_Gray_2.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_Gray_2.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_Gray_2.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_Gray_2.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_Gray_2.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 1))
    end 

    if (m_battleinfo3) ~= nil then
        local myFamilyStatus = {}
        local enemyFamilyStatus = {}
        if m_battleinfo3.status1.familyid == familymanager.Info().familyid then
            myFamilyStatus = m_battleinfo3.status1
            enemyFamilyStatus = m_battleinfo3.status2
        else
            enemyFamilyStatus = m_battleinfo3.status1
            myFamilyStatus = m_battleinfo3.status2
        end

        m_Fields.UILabel_Player_Green_3.text = Format(LocalString.Family.AboutWarMemberNum, myFamilyStatus.membernum)
        m_Fields.UILabel_Score_Green_3.text = tostring(myFamilyStatus.score)
        m_Fields.UILabel_Player_Red_3.text = Format(LocalString.Family.AboutWarMemberNum, enemyFamilyStatus.membernum)
        m_Fields.UILabel_Score_Red_3.text = tostring(enemyFamilyStatus.score)
        
        local leftTimeSeces = m_battleinfo3.remaintime/1000
        if leftTimeSeces < 0 then
            leftTimeSeces = 0
        end 
        local leftTime = timeutils.getDateTime(leftTimeSeces)
        m_Fields.UILabel_Timer_3.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)

        if m_battleinfo3.result == -2 then
            local familywarConfig = ConfigManager.getConfig("familywar")
            if myFamilyStatus.membernum >= familywarConfig.maxfamilymembernum then
                m_Fields.UIButton_Area_3.isEnabled = false
                m_Fields.UILabel_Area_3.text = LocalString.Family.AboutWarAreaButttonMemFull
            else
                m_Fields.UIButton_Area_3.isEnabled = true
                m_Fields.UILabel_Area_3.text = LocalString.Family.AboutWarAreaButttonEnter
            end                    
        else
            m_Fields.UIButton_Area_3.isEnabled = false
            if m_battleinfo3.result == cfg.ectype.FamilyWarBattleResult.WIN then
                m_Fields.UILabel_Area_3.text = LocalString.Family.AboutWarAreaButttonWin
            else
                m_Fields.UILabel_Area_3.text = LocalString.Family.AboutWarAreaButttonFailed
            end  
        end

        m_Fields.UISprite_Green_Base_3.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_3.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_3.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_3.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_3.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_3.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 1))
        
        m_Fields.UISprite_Green_Base_Gray_3.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_Gray_3.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_Gray_3.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_Gray_3.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_Gray_3.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_Gray_3.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 1))
    end 

    if (m_battleinfo4) ~= nil then
        local myFamilyStatus = {}
        local enemyFamilyStatus = {}
        if m_battleinfo4.status1.familyid == familymanager.Info().familyid then
            myFamilyStatus = m_battleinfo4.status1
            enemyFamilyStatus = m_battleinfo4.status2
        else
            enemyFamilyStatus = m_battleinfo4.status1
            myFamilyStatus = m_battleinfo4.status2
        end

        m_Fields.UILabel_Player_Green_4.text = Format(LocalString.Family.AboutWarMemberNum, myFamilyStatus.membernum)
        m_Fields.UILabel_Score_Green_4.text = tostring(myFamilyStatus.score)
        m_Fields.UILabel_Player_Red_4.text = Format(LocalString.Family.AboutWarMemberNum, enemyFamilyStatus.membernum)
        m_Fields.UILabel_Score_Red_4.text = tostring(enemyFamilyStatus.score)
        
        local leftTimeSeces = m_battleinfo4.remaintime/1000
        if leftTimeSeces < 0 then
            leftTimeSeces = 0
        end 
        local leftTime = timeutils.getDateTime(leftTimeSeces)
        m_Fields.UILabel_Timer_4.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)

        if m_battleinfo4.result == -2 then
            local familywarConfig = ConfigManager.getConfig("familywar")
            if myFamilyStatus.membernum >= familywarConfig.maxfamilymembernum then
                m_Fields.UIButton_Area_4.isEnabled = false
                m_Fields.UILabel_Area_4.text = LocalString.Family.AboutWarAreaButttonMemFull
            else
                m_Fields.UIButton_Area_4.isEnabled = true
                m_Fields.UILabel_Area_4.text = LocalString.Family.AboutWarAreaButttonEnter
            end                    
        else
            m_Fields.UIButton_Area_4.isEnabled = false
            if m_battleinfo4.result == cfg.ectype.FamilyWarBattleResult.WIN then
                m_Fields.UILabel_Area_4.text = LocalString.Family.AboutWarAreaButttonWin
            else
                m_Fields.UILabel_Area_4.text = LocalString.Family.AboutWarAreaButttonFailed
            end  
        end

        m_Fields.UISprite_Green_Base_4.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_4.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_4.gameObject:SetActive(IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_4.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_4.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_4.gameObject:SetActive(IsTowerOK(enemyFamilyStatus.remaintowers, 1))
        
        m_Fields.UISprite_Green_Base_Gray_4.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Green_Mid_Gray_4.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Green_Top_Gray_4.gameObject:SetActive(not IsTowerOK(myFamilyStatus.remaintowers, 1))
        m_Fields.UISprite_Red_Base_Gray_4.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 3))
        m_Fields.UISprite_Red_Mid_Gray_4.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 2))
        m_Fields.UISprite_Red_Top_Gray_4.gameObject:SetActive(not IsTowerOK(enemyFamilyStatus.remaintowers, 1))
    end 
end

local function update()
    if m_BossModel and m_BossModel.m_Object then
        m_BossModel.m_Avatar:Update()
    end
end

local function second_update()
    if (m_battleinfo1) ~= nil then
        local leftTimeSeces1 = m_battleinfo1.remaintime/1000
        if leftTimeSeces1 < 0 then
            leftTimeSeces1 = 0
        end 
        local leftTime1 = timeutils.getDateTime(leftTimeSeces1)
        m_Fields.UILabel_Timer_1.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime1.minutes,leftTime1.seconds)
        FamilyRoundRobinManager.SetCurBattleInfoRemaintime(1, FamilyRoundRobinManager.GetRoundRobinStatus(1).remaintime - 1000)
    end   

    if (m_battleinfo2) ~= nil then
        local leftTimeSeces2 = m_battleinfo2.remaintime/1000
        if leftTimeSeces2 < 0 then
            leftTimeSeces2 = 0
        end 
        local leftTime2 = timeutils.getDateTime(leftTimeSeces2)
        m_Fields.UILabel_Timer_2.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime2.minutes,leftTime2.seconds)
        FamilyRoundRobinManager.SetCurBattleInfoRemaintime(2, FamilyRoundRobinManager.GetRoundRobinStatus(2).remaintime - 1000)
    end
   
   if (m_battleinfo3) ~= nil then
        local leftTimeSeces3 = m_battleinfo3.remaintime/1000
        if leftTimeSeces3 < 0 then
            leftTimeSeces3 = 0
        end 
        local leftTime3 = timeutils.getDateTime(leftTimeSeces3)
        m_Fields.UILabel_Timer_3.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime3.minutes,leftTime3.seconds)
        FamilyRoundRobinManager.SetCurBattleInfoRemaintime(3, FamilyRoundRobinManager.GetRoundRobinStatus(3).remaintime - 1000)
    end

    if (m_battleinfo4) ~= nil then
        local leftTimeSeces4 = m_battleinfo4.remaintime/1000
        if leftTimeSeces4 < 0 then
            leftTimeSeces4 = 0
        end 
        local leftTime4 = timeutils.getDateTime(leftTimeSeces4)
        m_Fields.UILabel_Timer_4.text = Format(LocalString.Family.AboutWarAreaTimeLeft, leftTime4.minutes,leftTime4.seconds)
        FamilyRoundRobinManager.SetCurBattleInfoRemaintime(4, FamilyRoundRobinManager.GetRoundRobinStatus(4).remaintime - 1000)
    end
end

local function init(name,gameObject,fields)
    m_Name, m_GameObject, m_Fields = name,gameObject,fields
    EventHelper.SetClick(m_Fields.UIButton_Area_1, function()
        FamilyRoundRobinManager.SendCEnterFamilyRoundMatch(1)
    end)
    EventHelper.SetClick(m_Fields.UIButton_Area_2, function()
        FamilyRoundRobinManager.SendCEnterFamilyRoundMatch(2)
    end)
    EventHelper.SetClick(m_Fields.UIButton_Area_3, function()
        FamilyRoundRobinManager.SendCEnterFamilyRoundMatch(3)
    end)
    EventHelper.SetClick(m_Fields.UIButton_Area_4, function()
        FamilyRoundRobinManager.SendCEnterFamilyRoundMatch(4)
    end)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    second_update = second_update,
}
