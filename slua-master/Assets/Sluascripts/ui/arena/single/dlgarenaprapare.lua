local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local ArenaManager  = require("ui.arena.single.arenamanager")
local EventHelper 	= UIEventListenerHelper
local ArenaData     = ArenaManager.ArenaData
local CameraManager = require("cameramanager")
local PetManager    = require("character.pet.petmanager")
local ColorUtil     = require("common.colorutil")
local VipChargeManager = require("ui.vipcharge.vipchargemanager")
local CheckCmd      = require("common.checkcmd")

local name
local fields
local gameObject
local currentOpponent
local playerSelf
local playerOpponent

local function RefreshPartner(uiList,pets)
    local petNum = #pets
    --UIHelper.ResetItemNumberOfUIList(uiList, petNum)
    for i = 1, 3 do
        local uiItem = uiList:GetItemByIndex(i-1)
        --printyellow("uiItem",uiList,uiItem)
        local pet = pets[i]
        local UITexture_Icon = uiItem.Controls["UITexture_Icon"]
        local UISprite_Quality = uiItem.Controls["UISprite_Quality"]

        if pet then
            UITexture_Icon:SetIconTexture(pet:GetHeadIcon())
            local qualityColor = ColorUtil.GetQualitySpriteYuan(pet:GetQuality())
            UISprite_Quality.spriteName = qualityColor
        else
            UITexture_Icon:SetIconTexture("")
            local qualityColor = ColorUtil.GetQualityColor(cfg.item.EItemColor.WHITE)
            UISprite_Quality.spriteName = qualityColor
        end
    end
end

local function Button_StartFight(rank)
    local state = ArenaManager.GetPlayerInfo()
    local infoCfg = ConfigManager.getConfig("arenainfo")
    local arenaCfg = ConfigManager.getConfig("arenaconfig")

    --viplevel state.m_MaxChallengeNum
    if state.m_ChallengeCount >= state.m_MaxChallengeNum then
        UIManager.ShowSingleAlertDlg({content = LocalString.Arena.TimesMax}) 
    elseif state.m_ChallengeCount >= state.m_ChallengeNum and shouldHideVip() ~= true then
        UIManager.ShowAlertDlg({immediate = true,content = infoCfg["addnumber"].content, callBackFunc = function()
            VipChargeManager.ShowVipChargeDialog()
        end}) 
    else
        if state.m_ChallengeCurrency <= 0 then
            ArenaManager.Challenge(rank)
        else
            local currencyCount = PlayerRole:Instance():GetCurrency(arenaCfg.challengelimit.currencytype)
            if currencyCount >= state.m_ChallengeCurrency then
                UIManager.ShowAlertDlg({
                    immediate    = true,
                    content      = string.format(LocalString.Arena.CostMoney,tostring(state.m_ChallengeCurrency)),
                    callBackFunc = function()
                        ArenaManager.Challenge(rank)
                    end,
                    callBackFunc1 = function()
                    end,   
                })
            else
                UIManager.ShowSingleAlertDlg({content=LocalString.Arena.NotEnoughYuanBao})
            end
        end
    end    
end




local function refresh(params)
    if ArenaData.CurrentOpponent == nil then
        return
    end
    currentOpponent = ArenaData.CurrentOpponent

    if playerSelf == nil then
        local rolePublicInfo = {    roleid      = PlayerRole:Instance():GetId(),
                                    profession  = PlayerRole:Instance().m_Profession,
                                    gender      = PlayerRole:Instance().m_Gender,
                                    dressid     = PlayerRole:Instance().m_Dress,
                                    equips      = PlayerRole:Instance().m_Equips or {},
                                }
        playerSelf = CharacterManager.GetPlayerForUI(rolePublicInfo, function(player,object)
            object.transform.parent = fields.UIGroup_Player02.gameObject.transform
            object.transform.localPosition = Vector3(0,-250,200)
            object.transform.localRotation = Quaternion.Euler(-90,0,0)
            player:SetUIScale(220)
            --object.transform.localScale = Vector3(-250,250,250)
            --ExtendedGameObject.SetLayerRecursively(object, define.Layer.LayerUI)
            object:SetActive(true)
      --      UIManager.refresh("arena.dlgarenaprapare")
        end)
    end
     if playerOpponent ~= nil then
         playerOpponent:release()
         playerOpponent = nil
     end
    if playerOpponent == nil then

        local rolePublicInfo = {    roleid      = ArenaData.CurrentOpponent.m_Id ,
                                    profession  = ArenaData.CurrentOpponent.m_Profession,
                                    gender      = ArenaData.CurrentOpponent.m_Gender,
                                    dressid     = ArenaData.CurrentOpponent.m_DressId,
                                    equips      = ArenaData.CurrentOpponent.m_Equips,
                                }
        playerOpponent = CharacterManager.GetPlayerForUI(rolePublicInfo, function(player,object)
            object.transform.parent         = fields.UIGroup_Player01.gameObject.transform
            object.transform.localPosition  = Vector3(0,-250,200)
            object.transform.localRotation  = Quaternion.Euler(-90,0,0)
            player:SetUIScale(220)
            --object.transform.localScale     = Vector3(250,250,250)
            --ExtendedGameObject.SetLayerRecursively(object, define.Layer.LayerUI)
            object:SetActive(true)
      --      UIManager.refresh("arena.dlgarenaprapare")
        end)
    end

    fields.UILabel_LV01.text               = ArenaData.CurrentOpponent.m_Level
    fields.UILabel_Name01.text             = ArenaData.CurrentOpponent.m_Name
    fields.UILabel_Fighting01.text         = ArenaData.CurrentOpponent.m_Power

    fields.UILabel_LV02.text               = PlayerRole:Instance():GetLevel()
    fields.UILabel_Name02.text             = PlayerRole:Instance():GetName()
    fields.UILabel_Fighting02.text         = PlayerRole:Instance():GetPower()

    EventHelper.SetClick(fields.UIButton_Player01,function()
--        UIManager.showdialog("otherplayer.dlgotherroledetails",{roleId = ArenaData.CurrentOpponent.m_Id})
    end)

    EventHelper.SetClick(fields.UIButton_Player02,function()
        UIManager.showdialog("playerrole.dlgplayerrole",nil,1)
    end)

    EventHelper.SetClick(fields.UIButton_Adjust, function ()
        UIManager.show("partner.dlgpartner_assist", { onHide = function()
            UIManager.refresh(name)
        end})
	end)
    
    EventHelper.SetClick(fields.UIButton_Fighting, function ()
        Button_StartFight(ArenaData.CurrentOpponent.m_Rank)
	end)

    RefreshPartner(fields.UIList_PartnerBG02,ArenaData.CurrentOpponent.m_Pets)
    RefreshPartner(fields.UIList_PartnerBG01,PetManager:GetBattlePets())
end

local function destroy()

end

local function show(params)

   -- CameraManager.AddUICameraLight(true)
    playerSelf = nil
    playerOpponent = nil
    fields.UIPlayTweens_Challenge.gameObject:SetActive(true)
    fields.UIPlayTweens_Challenge:Play(true)
    UIManager.SetUITextureFit(fields.UITexture_BG)
end

local function hide()
--    CameraManager.AddUICameraLight(false)
    if playerSelf then
        playerSelf:release()
    end
    if playerOpponent then
        playerOpponent:release()
    end
    playerSelf = nil
    playerOpponent = nil
end

local function update()
    if playerSelf and playerSelf.m_Avatar then
        playerSelf.m_Avatar:Update()
    end
    if playerOpponent and playerOpponent.m_Avatar then
        playerOpponent.m_Avatar:Update()
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    fields.UIPlayTweens_Challenge.gameObject:SetActive(false)
end
local function uishowtype()
    return UIShowType.Refresh
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype=uishowtype,
}
