local unpack = unpack
local print = print
local Format = string.format
local EventHelper = UIEventListenerHelper
local DefineEnum = require("defineenum")
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local RideManager=require "ui.ride.ridemanager"
local ExchangeMgr=require"ui.exchange.exchangemanager"
local MailManager = require("ui.mail.mailmanager")
local ConfigManager = require("cfg.configmanager")
local FashionManager = require"character.fashionmanager"
local EctypeManager = require("ectype.ectypemanager")
local MaimaiManager = require("ui.maimai.maimaimanager")
local FriendManager = require("ui.friend.friendmanager")
local PlayerRoleManager = require("ui.playerrole.playerrolemanager")
local DlgUIMain_HPTip = require("ui.dlguimain_hptip")
local TitleManager = require("ui.title.titlemanager")
local AchievementManager = require "ui.achievement.achievementmanager"
local RoleSkill       = require "character.skill.roleskill"
local CompressManager = require"ui.cornucopia.compressmanager"
local ShopManager = require("shopmanager")
local ExchangeManager = require("ui.exchange.exchangemanager")
local ModuleLockManager = require("ui.modulelock.modulelockmanager")
local SettingManager = require("character.settingmanager")
local CarryShopManager = require("ui.carryshop.carryshopmanager")
local depotmanager = require("character.depotmanager")
local PetManager    = require"character.pet.petmanager"
local Functionalswitch    = require("functionalswitch")
local ModuleStatus = DefineEnum.ModuleStatus

local m_GameObject
local m_Name
local m_Fields
local m_Modules={}
local m_RedDotList = {}

local function RegisterAllModules()
    m_Modules={
        [m_Fields.UIButton_Role]={redDotType=cfg.ui.FunctionList.ROLE,redDotFunc=(PlayerRoleManager.UnRead),callDlg={dlg="playerrole.dlgplayerrole",tabindex=1}},
        [m_Fields.UIButton_Mission]={callDlg={dlg="dlgtask"}},
        [m_Fields.UIButton_Skill]={redDotType=cfg.ui.FunctionList.SKILL,redDotFunc=(RoleSkill.UnRead),callDlg={dlg="skill.dlgskill"}},
        [m_Fields.UIButton_ResourseEx]={redDotType=cfg.ui.FunctionList.CORNUCOPIA,redDotFunc=(CompressManager.UnRead),callDlg={dlg="cornucopia.dlgcornucopia"}},
        [m_Fields.UIButton_Achievement]={redDotType=cfg.ui.FunctionList.ACHIEVEMENT,redDotFunc=(AchievementManager.UnRead),callDlg={dlg="achievement.dlgachievement"}},
        [m_Fields.UIButton_Shop]={redDotType=cfg.ui.FunctionList.PHARMACY},
        [m_Fields.UIButton_Ride]={redDotType=cfg.ui.FunctionList.MOUNT,redDotFunc=(RideManager.UnRead),callDlg={dlg="ride.dlgridedisplay"}},--,redDotFunc=(RideManager.UnRead)
        [m_Fields.UIButton_Auction]={redDotType=cfg.ui.FunctionList.EXCHANGE,redDotFunc=(ExchangeManager.UnRead),callDlg={dlg="exchange.dlgexchange"}},
        [m_Fields.UIButton_Warehouse]={redDotType=cfg.ui.FunctionList.WAREHOUSE},
        [m_Fields.UIButton_Fashion]={redDotType=cfg.ui.FunctionList.FASHION,redDotFunc=(FashionManager.UnRead),callDlg={dlg="dlgfashion",params={fashiontype="role"}}},---,redDotFunc=(FashionManager.UnRead)
        [m_Fields.UIButton_Title]={redDotType=cfg.ui.FunctionList.TITLE,redDotFunc=(TitleManager.UnRead),callDlg={dlg="title.dlgtitle"}},
        [m_Fields.UIButton_Zone]={redDotType=cfg.ui.FunctionList.SPACE,callDlg={dlg="testtab.dlgtesttab",tabindex=3 }},
        [m_Fields.UIButton_Community]={redDotType=cfg.ui.FunctionList.SETTING,redDotFunc=(SettingManager.UnRead),callDlg={dlg="dlgautofight"}},
        [m_Fields.UIButton_Mail]={redDotType=cfg.ui.FunctionList.MAIL,redDotFunc=(MailManager.UnRead),callDlg={dlg="mail.dlgmail"}},
        [m_Fields.UIButton_Friends]={redDotType=cfg.ui.FunctionList.FRIEND,redDotFunc=(FriendManager.UnRead),callDlg={dlg="friend.dlgfriend"}},
        [m_Fields.UIButton_Maimai]={redDotType=cfg.ui.FunctionList.MAIMAI,callDlg={dlg="maimai.dlgmaimai"}},
        [m_Fields.UIButton_Pokedex]={callDlg={dlg="illustrates.dlgillustrate",tabindex=1},redDotType=cfg.ui.FunctionList.ILLUSTRATION,redDotFunc=PetManager.HaveAwardPet},
    }
end

local function RefreshModuleByType(icon,type)
    local moduleData=m_Modules[icon]
    if moduleData then
        local configData=ConfigManager.getConfigData("uimainreddot",type)
        local conditionData=ConfigManager.getConfigData("moduleunlockcond",configData.conid)
        local status=ModuleLockManager.GetModuleStatusByType(type)
        if status == ModuleStatus.LOCKED then  --未解锁
            if configData.opentype==cfg.ui.FunctionOpenType.APPEAR then
                icon.gameObject:SetActive(false)
            elseif configData.opentype==cfg.ui.FunctionOpenType.UNLOCK then
                local lockObj=icon.gameObject.transform:Find("UISprite_LeftLock")
                lockObj.gameObject:SetActive(true)
                EventHelper.SetClick(icon,function()
                    if conditionData then
                        local text=""
                        if conditionData.openlevel~=0 then
                            text=(conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
                        elseif conditionData.opentaskid~=0 then
                            local taskData=ConfigManager.getConfigData("task",conditionData.opentaskid)
                            if taskData then
                                text = Format(LocalString.CompleteTaskOpen,taskData.basic.name)
                            end
                        end
                        uimanager.ShowSystemFlyText(text)
                    end
                end)
            end
        elseif status == ModuleStatus.UNLOCK then  --已解锁
            if configData.opentype==cfg.ui.FunctionOpenType.APPEAR then
                icon.gameObject:SetActive(true)
            elseif configData.opentype==cfg.ui.FunctionOpenType.UNLOCK then
                local lockObj=icon.gameObject.transform:Find("UISprite_LeftLock")
                if lockObj then
                    lockObj.gameObject:SetActive(false)
                end
                local redDotSprite=icon.gameObject.transform:Find("UISprite_Warning")
                if redDotSprite then
                    if configData and (((configData.dottype==cfg.ui.DotType.ONCE) and (moduleData.click)) or (configData.dottype==cfg.ui.DotType.NONE)) then
                        redDotSprite.gameObject:SetActive(false)
                    else
                        if moduleData.redDotFunc~=nil then
                            redDotSprite.gameObject:SetActive(moduleData.redDotFunc())
                        end
                    end
                end
            end
            if moduleData.callDlg then
                    EventHelper.SetClick(icon,function()
                        if moduleData.redDotType then
                            moduleData.click=true
                        end                       
                        uimanager.showdialog(moduleData.callDlg.dlg,moduleData.callDlg.params,moduleData.callDlg.tabindex)
                    end)
            end
        end
    end
end

local function RefreshAllModules()
    for id,buttonItem in pairs(m_Modules) do
        if buttonItem.redDotType then
            RefreshModuleByType(id,buttonItem.redDotType)
        else
            if buttonItem.callDlg then
                if (id==m_Fields.UIButton_Mission) and (EctypeManager.IsInEctype()==true) then
                    id.isEnabled=false
                else
                    id.isEnabled=true
                    EventHelper.SetClick(id,function()
                        local TeamManager = require("ui.team.teammanager")
                        if (id == m_Fields.UIButton_Shop) or (id == m_Fields.UIButton_Warehouse) then
                                if TeamManager.IsForcedFollow() ~= true then
                                    uimanager.showdialog(buttonItem.callDlg.dlg,buttonItem.callDlg.params,buttonItem.callDlg.tabindex)
                                end
                            else
                                uimanager.showdialog(buttonItem.callDlg.dlg,buttonItem.callDlg.params,buttonItem.callDlg.tabindex)
                            end
                    end)
                end
            end
        end
    end
end

local function RefreshRedDot(type)
    local redDot=nil
    local icon=nil
    for id,buttonData in pairs(m_Modules) do
        if buttonData.redDotType==type then
            icon=id
            redDot=buttonData
            break
        end
    end
    if (redDot and icon) then
        local configData=ConfigManager.getConfigData("uimainreddot",type)
        if configData and (configData.dottype ~= cfg.ui.DotType.NONE) then
            redDot.click=false
            if (uimanager.isshow(m_Name)) then
                icon.gameObject:SetActive(redDot.redDotFunc())
            end
        else
            icon.gameObject:SetActive(false)
        end
    end
end

local function destroy()
end

local function show(params)
    PlayerRole:Instance():RefreshRidingAction()
end

local function hide()
end

local function refresh(params)
    RefreshAllModules()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = unpack(params)
    if Local.HideZone == true then
        m_Fields.UIButton_Zone.gameObject:SetActive(false)
    else
        m_Fields.UIButton_Zone.gameObject:SetActive(false)  ---暂时隐藏
    end
    
    EventHelper.SetClick(m_Fields.UIButton_Shop,function()
		    CarryShopManager.NavigateToCarryShopNPC()
	  end)

	  EventHelper.SetClick(m_Fields.UIButton_Warehouse,function()
		    depotmanager.NavigateToDepotNPC()
      end)
      local state = Functionalswitch:GetSwitchState()
      m_Fields.UIButton_Pokedex.gameObject:SetActive(state)
    RegisterAllModules()
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    RefreshRedDot = RefreshRedDot,
    RefreshAllModules = RefreshAllModules,
}
