local NetWork=require("network")
local UIManager=require("uimanager")
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local itemmanager = require "item.itemmanager"
local ConfigManager 	  = require "cfg.configmanager"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local BonusManager = require("item.bonusmanager")
local gameevent         = require "gameevent"
local EctypeManager      = require("ectype.ectypemanager")
local timeutils = timeutils
local dlgdeclareinvest
local dlgchangelogoname
local ActivityTipMgr
local familymgr

local m_IsWarStartConfirmed = false

------------------------start util--------------------------------------
local function UnRead()
   -- printyellow("[citywarmanager:UnRead] citywarinfo.IsWarTime()= 红点的功能暂时注释做到城市战的时候请打开" )
     return citywarinfo.IsWarTime() or citywarinfo.HasNewBattle() or citywarinfo.HasFamilyLuckyBonus()
	--return false
end

local function ShowRule(text)
    UIManager.show( "common.dlgdialogbox_complex", { 
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        fields.UILabel_Title.text = LocalString.City_War_Rule_Title
                        fields.UILabel_Content_Single.text = text
                    end })
end

local function reset()
    m_IsWarStartConfirmed = false
end
------------------------end util--------------------------------------

------------------------start protocol--------------------------------------
local function on_SInfo(msg)
    printyellow("XXXXXXXXXXXXXX [citywarmanager:on_SInfo] receive:", msg)
    citywarinfo.SetFamilyCityInfo(msg)
    
    --declarewarcity/owncitys变动，更新dlgworldterritorial
    if UIManager.isshow("citywar.dlgworldterritorial") then
        UIManager.call("citywar.dlgworldterritorial","refresh")
    end
    
    --更新dlgdeclarewarterritorial宣战金
    if UIManager.isshow("citywar.dlgdeclarewarterritorial") then
        UIManager.call("citywar.dlgdeclarewarterritorial","refresh")
    end
    
    --declarewarcity/stage变动，更新dlgweekbattle
    if UIManager.isshow("citywar.dlgweekbattle") then
        UIManager.call("citywar.dlgweekbattle", "refresh")
    end
    
    --owncitys变动，更新dlgmyterritorial
    if UIManager.isshow("citywar.dlgmyterritorial") then
        UIManager.call("citywar.dlgmyterritorial","refresh")
    end

    --luckybonus/owncitys变动，更新 tabcitywaraward
    if UIManager.isshow("citywar.tabcitywaraward") then
        UIManager.call("citywar.tabcitywaraward","refresh")
    end

    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld")
    end
	
 
    --TODO:declarewarcity/owncitys/logoname/stage变动，更新tabfamilyworld
end

local function on_SStage(msg)

end

local function send_CGetAllCitys()
    --printyellow("[citywarmanager:send_CGetAllCitys] send CGetAllCitys.")
    local msg = lx.gs.family.msg.citywar.CGetAllCitys()
    NetWork.send(msg)
end

local function on_SGetAllCitys(msg)
    --printyellow("[citywarmanager:on_SGetAllCitys] receive:", msg)
    citywarinfo.SyncAllCityInfo(msg)
    
    --更新tabfamilyworld
    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["all"] = true }})
    end
    
    --更新dlgworldterritorial
    if UIManager.isshow("citywar.dlgworldterritorial") then
        UIManager.call("citywar.dlgworldterritorial","refresh")
    end
        
    --更新dlgdeclarewarterritorial
    if UIManager.isshow("citywar.dlgdeclarewarterritorial") then
        UIManager.call("citywar.dlgdeclarewarterritorial","refresh")
    end
end

local function send_CEnterBattle(cityid)
    local msg = lx.gs.family.msg.citywar.CEnterBattle({city=cityid})
    printyellow("[citywarmanager:send_CEnterBattle] send CEnterBattle:", msg)
    NetWork.send(msg)
end

local function send_CGetMyBattles()
    --printyellow("[citywarmanager:send_CGetMyBattles] send CGetMyBattles.")
    local msg = lx.gs.family.msg.citywar.CGetMyBattles()
    NetWork.send(msg)
end

local function OnCityWarTipClicked()
    printyellow("[citywarmanager:OnCityWarTipClicked] On CityWar activityTip Clicked!")
    local params = {}
    params.tabindex2 = 1
    UIManager.showdialog("arena.dlgarena", nil, 2)
end

local function NeedShowEnterConfirm()
   
    local rolemember = familymgr.RoleMember()
	--printyellow("[citywarmanager:NeedShowEnterConfirm] On CityWar activityTip Clicked!",rolemember.familyjob,cfg.family.FamilyJobEnum.MEMBER,m_IsWarStartConfirmed)
    return  false==m_IsWarStartConfirmed
end

local function on_SGetMyBattles(msg)
    --printyellow("[citywarmanager:on_SGetMyBattles] receive:", msg)
    citywarinfo.SetFamilyWeekBattles(msg.battlestatus)
    
    --更新 dlgweekbattle
    if UIManager.isshow("citywar.dlgweekbattle") then
        UIManager.call("citywar.dlgweekbattle", "refresh")
    end
    
    --更新 tabembattle 布阵
    if UIManager.isshow("citywar.tabembattle") then
        UIManager.call("citywar.tabembattle","refresh", msg)
    end

    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["all"] = true } } )
    end

    --update activity tip
    local iswartime, citydata = citywarinfo.IsWarTime()    
    if true==iswartime then
        ActivityTipMgr.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR, nil, OnCityWarTipClicked)
        local citywarinfo = require"ui.citywar.citywarinfo"
		local isWarOver = citywarinfo.GetCityWarIsOver()
		local needshow = NeedShowEnterConfirm()
		local isinectypr = EctypeManager.IsInEctype()
		printyellow("NeedShowEnterConfirm",NeedShowEnterConfirm(),citydata:CanEnterCityWar(),citydata:IsCityWarOver(),EctypeManager.IsInEctype())
        --弹出进入城战确认框
        if citydata and true==NeedShowEnterConfirm() and citydata:CanEnterCityWar() and not citydata:IsCityWarOver() and not EctypeManager.IsInEctype()  then
            m_IsWarStartConfirmed = true
                
            local params = {}
            params.title = LocalString.TipText
	        params.content = LocalString.City_War_Enter_Confirm
            --params.sureText = LocalString.Family.FamilyWorld.CityInfo_EnterWar
            params.callBackFunc = function()
                --send_CEnterBattle(citydata:GetCityId())                
                local params = {}
                params.tabindex2 = 1
                UIManager.showdialog("arena.dlgarena", nil, 2)
                UIManager.show("citywar.dlgweekbattle")
            end
	        UIManager.ShowAlertDlg(params)        
        end
    elseif true==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.CITYWAR) then
        ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR)
    end        

    local ispreparing, preparetime = citywarinfo.IsPrepareWarTime()
    if true == ispreparing then    
        if false==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE) then
            ActivityTipMgr.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE, preparetime, OnCityWarTipClicked)
        end
    elseif true==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE) then
        ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE)
    end
end

local function send_CDeclare(city, totalmoney)
    local msg = lx.gs.family.msg.citywar.CDeclare({city=city, totalmoney=totalmoney})
    --printyellow("[citywarmanager:send_CDeclare] send CDeclare:", msg)
    NetWork.send(msg)
end

local function on_SDeclare(msg)

    printyellow("[citywarmanager:on_SDeclare] city:", msg.city)
	printyellow("[citywarmanager:on_SDeclare] totalmoney:", msg.totalmoney)
    citywarinfo.SetFamilyDeclareWarInfo(msg.city, msg.totalmoney)

    --更新城市和战役信息
    if msg.city and msg.totalmoney then    
        send_CGetAllCitys()
        send_CGetMyBattles()
    end
    
    --更新dlgdeclarewarterritorial宣战金
    if UIManager.isshow("citywar.dlgdeclarewarterritorial") then
        UIManager.call("citywar.dlgdeclarewarterritorial","refresh")
    end

    --宣战成功，关闭资金投入界面
    if dlgdeclareinvest then
        dlgdeclareinvest.hide()
    end


    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld")
    end
end

local function send_CGetAllLuckyBonusInfo()
    --printyellow("[citywarmanager:send_CGetAllLuckyBonusInfo] send CGetAllLuckyBonusInfo.")
    local msg = lx.gs.family.msg.citywar.CGetAllLuckyBonusInfo()
    NetWork.send(msg)
end

local function on_SGetAllLuckyBonusInfo(msg)
    printyellow("[citywarmanager:on_SGetAllLuckyBonusInfo] receive:", msg)
    citywarinfo.SetWorldLuckyBonus(msg.citybonus)
    
    --更新 tabcitywaraward
    if UIManager.isshow("citywar.tabcitywaraward") then
        UIManager.call("citywar.tabcitywaraward","RefreshLuckyBonus")
    end    
    
    --更新 dlgsendawards
    if UIManager.isshow("citywar.dlgsendawards") then
        UIManager.call("citywar.dlgsendawards","refresh")
    end

    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld")
    end
end

local function send_CAllocBonus(memberid, bonus)
    local msg = lx.gs.family.msg.citywar.CAllocBonus({memberid=memberid, bonus=bonus})
    --printyellow("[citywarmanager:send_CAllocBonus] send CAllocBonus:", msg)
    NetWork.send(msg)
end

local function on_SAllocBonus(msg)
    --printyellow("[citywarmanager:on_SAllocBonus] receive:", msg)    
    citywarinfo.SetFamilyLuckyBonus(msg.remainbonus)
    
    --更新 dlgsendawards
    if UIManager.isshow("citywar.dlgsendawards") then
        UIManager.call("citywar.dlgsendawards","refresh")
    end

    --TODO:广播给家族所有人
end

local function send_CGetAllocLog()
    --printyellow("[citywarmanager:send_CGetAllocLog] send CGetAllocLog.")
    local msg = lx.gs.family.msg.citywar.CGetAllocLog()
    NetWork.send(msg)
end

local function on_SGetAllocLog(msg)
    --printyellow("[citywarmanager:on_SGetAllocLog] receive:", msg)   
    --[[
    for _,log in ipairs(msg.logs) do
        printyellow(string.format("[citywarmanager:on_SGetAllocLog] role [%s] receiveaward.", log.name))
    end
    --]]
    
    --更新分配历史界面
    if UIManager.isshow("citywar.tabworldterritoryrewarddistribution") then
        UIManager.call("citywar.tabworldterritoryrewarddistribution","refresh", msg)
    end
end

local function send_CChangeLogoName(name)
    local msg = lx.gs.family.msg.citywar.CChangeLogoName({name=name})
    --printyellow("[citywarmanager:send_CChangeLogoName] send CChangeLogoName:", msg)
    NetWork.send(msg)
end

local function on_SChangeLogoName(msg)
    
    citywarinfo.SetFamilyLogoname(msg.name)

    --更新 家族徽章
    if UIManager.isshow("citywar.dlgmyterritorial") then
        UIManager.call("citywar.dlgmyterritorial","ShowLogoName")
    end

    --修改徽记成功，关闭修改界面
    if dlgchangelogoname then
        dlgchangelogoname.hide()
    end
end

local function send_CGetBattleLog()
    --printyellow("[citywarmanager:send_CGetBattleLog] send CGetBattleLog.")
    local msg = lx.gs.family.msg.citywar.CGetBattleLog()
    NetWork.send(msg)
end

local function on_SGetBattleLog(msg)
    --printyellow("[citywarmanager:on_SGetBattleLog] receive:", msg)  
    citywarinfo.SetFamilyLogs(msg.logs)

    --更新 tabfamilyworld
    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["log"] = true }})
    end
end
------------------------end protocol--------------------------------------

local m_PreCheckTime
local CheckInterval = 30
local function second_update()    
    if m_PreCheckTime and Time.time-m_PreCheckTime<CheckInterval then
        return
    end

    --printyellow("[citywarmanager:second_update] Check war state!")
    m_PreCheckTime = Time.time
    if cfg.family.citywar.CityWarStage.BATTLE==citywarinfo.GetFamilyCityWarStage() or cfg.family.citywar.CityWarStage.BEFORE_BATTLE==citywarinfo.GetFamilyCityWarStage() then
        if false == UIManager.isshow("citywar.tabfamilyworld") then
            send_CGetMyBattles()
        end
    else
        if true==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.CITYWAR) then
            ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR)
        end

        if true==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE) then
            ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE)
        end
    end
end

--test
local function onmsg_SRoleLogin(msg)
    --printyellow("[citywarmanager:onmsg_SRoleLogin] request citywar SInfo on SRoleLogin.")  
    --send_CGetAllCitys()
	ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE)
end

local function OnLogout() 
    reset()
end

local function init()
    --printyellow("[citywarmanager:init] init!")   
    citywarinfo.init()
    dlgdeclareinvest = require "ui.citywar.dlgdeclareinvest"
    dlgchangelogoname = require "ui.citywar.dlgchangelogoname"
    ActivityTipMgr           = require("ui.activity.activitytipmanager")
    familymgr = require("family.familymanager")

	gameevent.evt_second_update:add(second_update)
	gameevent.evt_system_message:add("logout", OnLogout)

    --test
    --ActivityTipMgr.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.CITYWAR, nil, OnCityWarTipClicked)

    NetWork.add_listeners({
        {"lx.gs.family.msg.citywar.SInfo", on_SInfo},
        {"lx.gs.family.msg.citywar.SStage", on_SStage},
        {"lx.gs.family.msg.citywar.SGetAllCitys", on_SGetAllCitys},
        {"lx.gs.family.msg.citywar.SGetMyBattles", on_SGetMyBattles},
        {"lx.gs.family.msg.citywar.SDeclare", on_SDeclare},
        {"lx.gs.family.msg.citywar.SGetAllLuckyBonusInfo", on_SGetAllLuckyBonusInfo},   
        {"lx.gs.family.msg.citywar.SAllocBonus", on_SAllocBonus},            
        {"lx.gs.family.msg.citywar.SGetAllocLog", on_SGetAllocLog},     
        {"lx.gs.family.msg.citywar.SChangeLogoName", on_SChangeLogoName},   
        {"lx.gs.family.msg.citywar.SGetBattleLog", on_SGetBattleLog},         
        { "lx.gs.login.SRoleLogin", onmsg_SRoleLogin }, 
    })
end

return
{
    init     = init,
    UnRead   = UnRead,
    ShowRule = ShowRule,

    send_CGetAllCitys = send_CGetAllCitys,
    send_CGetMyBattles = send_CGetMyBattles,
    send_CDeclare = send_CDeclare,
    send_CEnterBattle = send_CEnterBattle,
    send_CGetAllLuckyBonusInfo = send_CGetAllLuckyBonusInfo,
    send_CAllocBonus = send_CAllocBonus,
    send_CGetAllocLog = send_CGetAllocLog,
    send_CChangeLogoName = send_CChangeLogoName,
    send_CGetBattleLog = send_CGetBattleLog,
}
