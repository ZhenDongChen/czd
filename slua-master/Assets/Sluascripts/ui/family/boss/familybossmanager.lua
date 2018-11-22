local NetWork=require("network")
local UIManager=require("uimanager")
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local FamilyBossInfo = require("ui.family.boss.familybossinfo")
local DlgDialogBox_Commodity = require"ui.common.dlgdialogbox_commodity"
local itemmanager = require "item.itemmanager"
local LimitTimeManager       = require("limittimemanager")
local ConfigManager 	  = require "cfg.configmanager"

local m_BossesCfg
local m_TrainGoldCfg
local m_TrainYuanbaoCfg

--��ʼ������ս,ÿ������
local function send_CLaunchGodAnimalActivity()
    local msg = lx.gs.family.msg.CLaunchGodAnimalActivity()
    --printyellow("[familybossmanager:send_CLaunchGodAnimalActivity] send:", msg)
    NetWork.send(msg)
end

--��ʼ������ս,ÿ������
local function on_SLaunchGodAnimalActivity(msg)
    --printyellow("[familybossmanager:on_SLaunchGodAnimalActivity] receive:", msg)
end

--��ʼ������ս,ÿ�����Σ�֪ͨȫ����Ա
local function on_SLaunchGodAnimalActivityNotify(msg)
    --printyellow("[familybossmanager:on_SLaunchGodAnimalActivityNotify] receive:", msg)
    FamilyBossInfo.SetBossOpenTime(msg.starttime)
end

--������ս����10���ӿ�ʼ֪ͨ
local function on_SGodAnimalActivityStartNotify(msg)
    --printyellow("[familybossmanager:on_SGodAnimalActivityStartNotify] receive:", msg)
    FamilyBossInfo.SetBossOpenTime(msg.countdowntime)
    UIManager.ShowSystemFlyText(string.format(LocalString.Family_Boss_Launch_Notice, math.ceil(msg.countdowntime/60000)) )
end

--��������
local function send_CEvolveGodAnimal(animalid)
    local msg = lx.gs.family.msg.CEvolveGodAnimal({animalid = animalid})
    --printyellow("[familybossmanager:send_CEvolveGodAnimal] send:", msg)
    NetWork.send(msg)
end

--��������
local function on_SEvolveGodAnimal(msg)
    --printyellow("[familybossmanager:on_SEvolveGodAnimal] receive:", msg)
    FamilyBossInfo.SetBossInfo(msg)
    if UIManager.needrefresh("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "UpdateBoss")
    end
end

--��������
local function send_CRaiseGodAnimal(raisetype, animalid)
    local msg = lx.gs.family.msg.CRaiseGodAnimal({raisetype=raisetype, animalid=animalid})
    --printyellow("[familybossmanager:send_CRaiseGodAnimal] send:", msg)
    NetWork.send(msg)
end

local function AwardFlyText(prefix, value)
    if prefix and value and value>0 then        
        --printyellow("[familybossmanager:AwardFlyText] AwardFlyText:", string.format(prefix, value))
        UIManager.ShowItemFlyText(string.format(prefix, value))
    end    
end

--��������
local function on_SRaiseGodAnimal(msg)
    --printyellow("[familybossmanager:on_SRaiseGodAnimal] receive:", msg)
    --print("[familybossmanager:on_SRaiseGodAnimal] receive:", msg)
    FamilyBossInfo.SetBossInfo(msg)

    --update ui
    if UIManager.needrefresh("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "UpdateBoss")
        UIManager.call("family.boss.dlgfamilyboss", "UpdateTrain")
    end
  
    --fly text
    local familyfund
    local familybuild
    local familycontribution
    if msg.raisetype==lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_XUNIBI then
        familyfund = m_TrainGoldCfg.buildrate.money
        familybuild = m_TrainGoldCfg.buildrate.buildv
        familycontribution = m_TrainGoldCfg.familycontribution.amount
    elseif msg.raisetype==lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_YUANBAO then
        familyfund = m_TrainYuanbaoCfg.buildrate.money
        familybuild = m_TrainYuanbaoCfg.buildrate.buildv
        familycontribution = m_TrainYuanbaoCfg.familycontribution.amount
    end
    AwardFlyText(LocalString.Family_Boss_Train_Add_Fund, familyfund)
    AwardFlyText(LocalString.Family_Boss_Train_Add_Build, familybuild)
    --AwardFlyText(LocalString.Family_Boss_Train_Get_Banggong, familycontribution)个人帮贡变化服务器已处理

    --evolve tip
    local bossinfo = msg.animal
    local bosscfg = m_BossesCfg[bossinfo.animalid]
    local bosslevelcfg = bosscfg.bossinfo[bossinfo.animallevel]
    if bosslevelcfg then
        local levelexp = bosslevelcfg.requireexp
        local curexp = bossinfo.exp
        if curexp and levelexp and curexp>=levelexp then
            UIManager.ShowSystemFlyText(LocalString.Family_Boss_Train_Exp_Overflow)
        end
    end
end

--����������Ϣ
local function on_SGetFamilyActivityInfo(msg)
    -- printyellow("[familybossmanager:on_SGetFamilyActivityInfo] receive:", msg)
    FamilyBossInfo.SetFamilyBossInfo(msg)
end

--����������Ϣ
local function on_SGetFamilyInfo(msg)
    --printyellow("[familybossmanager:on_SGetFamilyInfo] receive:", msg)
    FamilyBossInfo.SetFamilyBossTime(msg)
end

--�˳�����
local function on_SQuitFamilyNotify(msg)
    --printyellow("[familybossmanager:on_SQuitFamilyNotify] receive:", msg)
    if msg.memberid == PlayerRole.m_Id and UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.hide("family.boss.dlgfamilyboss")
    end
end

--�߳�����
local function on_SKickoutFamilyMemberNotify(msg)
    --printyellow("[familybossmanager:on_SKickoutFamilyMemberNotify] receive:", msg)
    if msg.memberid == PlayerRole.m_Id and UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.hide("family.boss.dlgfamilyboss")
    end
end

--ת��ְλ
local function on_STransferChiefNotify(msg)
    --printyellow("[familybossmanager:on_STransferChiefNotify] receive:", msg)
    if (msg.operator.roleid == PlayerRole.m_Id or msg.member.roleid == PlayerRole.m_Id) and UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "UpdateOpen")
    end
end

--����ְλ
local function on_SAppointJobNotify(msg)
    --printyellow("[familybossmanager:on_SAppointJobNotify] receive:", msg)
    if msg.member.roleid == PlayerRole.m_Id and UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "UpdateOpen")
    end
end

--��ʼ��ս����
--[[local function send_CChallengeGodAnimal(animalid)
    local msg = lx.gs.family.msg.CEnterFamilyStation({isopenparty=0})
    printyellow("[familybossmanager:send_CChallengeGodAnimal] send:", msg)
    NetWork.send(msg)
end]]

--ɱ������
local function on_SKillGodAnimal(msg)
    --printyellow("[familybossmanager:on_SKillGodAnimal] receive:", msg)
    local bouns = msg.bonus
    if bouns then
        for id, count in pairs(bouns.items) do
            --printyellow("[familybossmanager:on_SKillGodAnimal] itemid= [%s], count=[%s]", id, count)
            local itemdata = itemmanager.GetItemData(id)
            if itemdata and itemdata.name and count > 0 and itemmanager.IsCurrency(id) == false then
                --printyellow("[familybossmanager:on_SKillGodAnimal] award [%s] count [%s].", itemdata.name, count)
                UIManager.ShowSystemFlyText(itemdata.name.."x"..count)
            else
                if itemdata then
                    --printyellow(string.format("[familybossmanager:on_SKillGodAnimal] itemdata.name = [%s], count =[%s], itemmanager.IsCurrency(id)=[%s]",itemdata.name, count, itemmanager.IsCurrency(id)))
                else
                    --printyellow(string.format("[familybossmanager:on_SKillGodAnimal] itemdata null for id[%s]",id))
                end
            end
        end
    else
        -- printyellow("[familybossmanager:on_SKillGodAnimal] bouns nil!")
    end

    if msg.isover > 0 then
        --chanllenge end
        FamilyBossInfo.SetBossChallengeTime(0)
        if UIManager.isshow("family.boss.dlgfamilyboss") then
            UIManager.call("family.boss.dlgfamilyboss", "UpdateOpen")
            UIManager.call("family.boss.dlgfamilyboss", "UpdateCountdown")
        end
    end
end

local function UnRead()
    local trainlimit = LimitTimeManager.GetLimitTime(cfg.cmd.ConfigId.FAMILY_FEED, 1)   
    local traincount =  trainlimit and trainlimit[1] or 0
    local totalcount = m_TrainGoldCfg and m_TrainGoldCfg.feedlimit.entertimes[1] or 0
    --printyellow(string.format("[familybossmanager:UnRead] left train count = [%s].", (totalcount-traincount)))
    return (totalcount-traincount)>0
end

local function init()
    --printyellow("[familybossmanager:init] init!")
    m_BossesCfg = ConfigManager.getConfig("boss")
    m_TrainGoldCfg = ConfigManager.getConfigData("bossfeed", 1)
    m_TrainYuanbaoCfg = ConfigManager.getConfigData("bossfeed", 2)

    FamilyBossInfo.init()
   
    NetWork.add_listeners({
        {"lx.gs.family.msg.SLaunchGodAnimalActivity",on_SLaunchGodAnimalActivity},
        {"lx.gs.family.msg.SLaunchGodAnimalActivityNotify",on_SLaunchGodAnimalActivityNotify},
        {"lx.gs.family.msg.SGodAnimalActivityStartNotify",on_SGodAnimalActivityStartNotify},
        {"lx.gs.family.msg.SEvolveGodAnimal",on_SEvolveGodAnimal},
        {"lx.gs.family.msg.SRaiseGodAnimal",on_SRaiseGodAnimal},
        {"lx.gs.family.msg.SGetFamilyActivityInfo", on_SGetFamilyActivityInfo},
        {"lx.gs.family.msg.SGetFamilyInfo", on_SGetFamilyInfo},
        {"map.msg.SKillGodAnimal", on_SKillGodAnimal},

        {"lx.gs.family.msg.SQuitFamilyNotify", on_SQuitFamilyNotify},
        {"lx.gs.family.msg.SKickoutFamilyMemberNotify", on_SKickoutFamilyMemberNotify},
        {"lx.gs.family.msg.STransferChiefNotify", on_STransferChiefNotify},
        {"lx.gs.family.msg.SAppointJobNotify", on_SAppointJobNotify},
    })
end

return
{
    init     = init,
    UnRead   = UnRead,
    send_CLaunchGodAnimalActivity = send_CLaunchGodAnimalActivity,
    send_CEvolveGodAnimal = send_CEvolveGodAnimal,
    send_CRaiseGodAnimal = send_CRaiseGodAnimal,
    --send_CChallengeGodAnimal = send_CChallengeGodAnimal,
}
