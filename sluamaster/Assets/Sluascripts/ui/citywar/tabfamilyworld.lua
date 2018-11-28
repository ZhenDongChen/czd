local EventHelper       = UIEventListenerHelper
local UIManager         = require("uimanager")
local CitywarManager    = require("ui.citywar.citywarmanager")
local CitywarInfo 	    = require("ui.citywar.citywarinfo")
local ConfigManager     = require("cfg.configmanager")
local DlgDeclareInvest  = require("ui.citywar.dlgdeclareinvest")
local BonusManager      = require("item.bonusmanager")
local DlgRewards        = require("ui.common.dlgdialogbox_reward")

local name, gameObject, fields
--============================================================================================
--辅助
--============================================================================================
local DEFAULT_COLOR
local function GetCityTypeName(type)
    if type == cfg.family.citywar.CityLevelType.SENIOR then
        return LocalString.Family.FamilyWorld.CityLevel_Senior
    elseif type == cfg.family.citywar.CityLevelType.MEDIUM then
        return LocalString.Family.FamilyWorld.CityLevel_Medium
    else
        return LocalString.Family.FamilyWorld.CityLevel_Primary
    end
end

local function GetDefaultColor()
    if DEFAULT_COLOR then
        return DEFAULT_COLOR
    end
    DEFAULT_COLOR = Color(  cfg.family.citywar.CityWar.DEFAULT_COLOR_R/255,
                            cfg.family.citywar.CityWar.DEFAULT_COLOR_G/255,
                            cfg.family.citywar.CityWar.DEFAULT_COLOR_B/255)
    local cfg = ConfigManager.getConfig("citywar")
    if cfg and cfg.colors and cfg.colors[1] then
        DEFAULT_COLOR = mathutils.IntToColorWithoutAlpha(tonumber("0x"..cfg.colors[1]))
    end
    return DEFAULT_COLOR
end

local function GetListItemByName(uiListTransform, name)
    if uiListTransform and name and name ~= "" then
        local trans = uiListTransform:Find(name)
        if trans then
            local uiItem = trans:GetComponent("UIListItem")
            return uiItem
        end
    end
    return nil
end

local function GetNameOrNone(name)
    if name == nil or name == "" then
        return LocalString.NoneText
    end
    return name
end

local function ShowRewardItems(items)
    UIManager.show("common.dlgdialogbox_reward", { type = 1, callBackFunc = function(params,fields)
        fields.UILabel_Title.text = LocalString.Family.FamilyWorld.BonusTitle
        local itemCount = #items
			
		
		
        local wrapList = fields.UIList_ItemShow.gameObject:GetComponent("UIWrapContentList")
        EventHelper.SetWrapListRefresh(wrapList, function(uiItem,index,realIndex)
            local item = items[realIndex]
            BonusManager.SetRewardItem(uiItem, item, {notSetClick = true})
            uiItem.Controls["UILabel_ItemName"].text = item:GetName()
            uiItem.Controls["UILabel_ItemIntroduce"].text = item:GetIntroduction()
        end)
		wrapList:SetDataCount(itemCount)
		wrapList:CenterOnIndex(-0.2)
    end})
end
--============================================================================================
--地图区域
--============================================================================================
-----------------------------------------------------------------------
--城市（通用）
local function ShowCityNormalDialog(cityData)
    if not cityData:ExistsLuckyBonus() then
        UIManager.ShowSingleAlertDlg({
            title   = cityData:GetCityName(),
            content = string.format( LocalString.Family.FamilyWorld.CityInfo_Simple,
                            GetCityTypeName(cityData:GetCityLevel()),
                            GetNameOrNone(cityData:GetDefenderFamilyName()),
                            string.format("%s%%", tostring((cityData:GetStability() or 0))))
        })
    else
        UIManager.ShowSingleAlertDlg({
            title   = cityData:GetCityName(),
            content = string.format( LocalString.Family.FamilyWorld.CityInfo_Simple,
                            GetCityTypeName(cityData:GetCityLevel()),
                            GetNameOrNone(cityData:GetDefenderFamilyName()),
                            string.format("%s%%", tostring((cityData:GetStability() or 0)))),
            buttonText = LocalString.Family.FamilyWorld.CheckLuckBonus,
            callBackFunc = function()
                local msgBonusDict = CitywarInfo.GetWorldLuckyBonus()
                local cityId = cityData:GetCityId()
                if msgBonusDict[cityId] then
                    local items = BonusManager.GetItemsOfServerBonus(msgBonusDict[cityId])
                    ShowRewardItems(items)
                end
            end,
        })
    end
end

local function SetCityNormal(cityData, uiItem, warItem)
    --local existLuckBonus = SetCityLuckBonus(cityData, uiItem, warItem)
    --printyellow("========================================>",cityData:ExistsLuckyBonus())

    warItem.Controls["UIGroup_LuckBonus"].gameObject:SetActive(cityData:ExistsLuckyBonus() or false)
    warItem.Controls["UIGroup_CanAttack"].gameObject:SetActive(false)
    warItem.Controls["UIGroup_InWar"].gameObject:SetActive(false)
	--printyellow(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",CitywarInfo.HasFamilyDeclareCity(),cityData:GetCityId(),CitywarInfo.HasFamilyDeclareCity() ==cityData:GetCityId())
	
    EventHelper.SetClick(uiItem, function()
        ShowCityNormalDialog(cityData)
    end)
	

end
-----------------------------------------------------------------------
--城市（可宣战）
local function ShowCityCanAttackDialog(cityData)
    UIManager.ShowSingleAlertDlg({
        title   = cityData:GetCityName(),
        content = string.format( LocalString.Family.FamilyWorld.CityInfo_Simple,
                        GetCityTypeName(cityData:GetCityLevel()),
                        GetNameOrNone(cityData:GetDefenderFamilyName()),
                        string.format("%s%%", tostring((cityData:GetStability() or 0)))),
        buttonText = LocalString.Family.FamilyWorld.DeclareWar,
        callBackFunc = function()
            DlgDeclareInvest.show(cityData)
        end
    })
end

local function SetCityCanAttack(cityData, uiItem, warItem)
    --local existLuckBonus = SetCityLuckBonus(cityData, uiItem, warItem)
    warItem.Controls["UIGroup_LuckBonus"].gameObject:SetActive(cityData:ExistsLuckyBonus() or false)
    warItem.Controls["UIGroup_CanAttack"].gameObject:SetActive(true)
    warItem.Controls["UIGroup_InWar"].gameObject:SetActive(false)
    warItem.Controls["UISprite_SelectColor"].color = cityData:GetDefenderColor() or GetDefaultColor()
    EventHelper.SetClick(uiItem, function()
        ShowCityCanAttackDialog(cityData)
    end)
end
-----------------------------------------------------------------------
--城市（战争中）
local function ShowCityInWarDialog(cityData)
    UIManager.ShowAlertDlg({
        title   = string.format(
                    LocalString.Family.FamilyWorld.CityInfo_TitleWar,
                    GetCityTypeName(cityData:GetCityLevel()),
                    cityData:GetCityName() ),
        content = string.format(
                    LocalString.Family.FamilyWorld.CityInfo_InWar,
                    GetNameOrNone(cityData:GetDefenderFamilyName()),
                    string.format("%s%%", tostring((cityData:GetStability() or 0))),
                    GetNameOrNone(cityData:GetAttackerFamilyName()),
                    GetNameOrNone(cityData:GetDefenderFamilyName())),
        sureText = LocalString.Family.FamilyWorld.CityInfo_EnterWar,
        callBackFunc = function()
            CitywarManager.send_CEnterBattle(cityData:GetCityId())
        end})
end

local function SetCityInWar(cityData, uiItem, warItem)
    local stage = CitywarInfo.GetFamilyCityWarStage()
    local EnumStage = cfg.family.citywar.CityWarStage
    --local existLuckBonus = SetCityLuckBonus(cityData, uiItem, warItem)
    --printyellow("cityData:IsFamilyAttacking()",cityData:IsFamilyAttacking())
    --printyellow("cityData:IsFamilyDefending()",cityData:IsFamilyDefending())
    local dcolor = cityData:GetDefenderColor() or GetDefaultColor()
    warItem.Controls["UIGroup_LuckBonus"].gameObject:SetActive(cityData:ExistsLuckyBonus() or false)
    warItem.Controls["UIGroup_CanAttack"].gameObject:SetActive(false)
    warItem.Controls["UIGroup_InWar"].gameObject:SetActive(true)
    local declareCityId = CitywarInfo.GetFamilyDeclareCity()
    warItem.Controls["UISprite_Attack"].gameObject:SetActive((declareCityId~=nil and declareCityId == cityData:GetCityId()) or cityData:IsFamilyAttacking() or false)
    warItem.Controls["UISprite_Attack"].color = dcolor
    warItem.Controls["UISprite_Defence"].gameObject:SetActive(cityData:IsFamilyDefending() or false)
    warItem.Controls["UISprite_Defence"].color = dcolor
    --printyellow("cityData:IsPeace()",cityData:IsPeace())
    local isInWar = ((stage == EnumStage.BATTLE) and cityData:CanEnterCityWar() and (not cityData:IsPeace()))

    warItem.Controls["UIGroup_WarState"].gameObject:SetActive(isInWar)
    if isInWar then
        local battlesInfo = CitywarInfo.GetFamilyWeekBattles()
		if battlesInfo ~= nil then
			local friendPlayerCount = 0
			local enemyPlayerCount = 0
			local cityId = cityData:GetCityId() or 0
			if cityData:GetDefenderFamilyId() and cityData:GetDefenderFamilyId() == PlayerRole:Instance().m_FamilyID then
				friendPlayerCount = (battlesInfo[cityId] ~= nil) and battlesInfo[cityId].defencemembernum or 0
				enemyPlayerCount = (battlesInfo[cityId] ~= nil) and battlesInfo[cityId].attackmembernum or 0
			else
				enemyPlayerCount = (battlesInfo[cityId] ~= nil) and battlesInfo[cityId].defencemembernum or 0
				friendPlayerCount = (battlesInfo[cityId] ~= nil) and battlesInfo[cityId].attackmembernum or 0
			end
			local tempfriendPlayerCount = 0
			local tempenemyPlayerCount = 0
			if (friendPlayerCount + enemyPlayerCount) == 0 then 
				tempfriendPlayerCount = 0
				tempenemyPlayerCount = 0
			else
				tempfriendPlayerCount =	friendPlayerCount/(friendPlayerCount + enemyPlayerCount)
				tempenemyPlayerCount = enemyPlayerCount/(friendPlayerCount + enemyPlayerCount)
			end
			
			warItem.Controls["UISlider_Green"].value = tempfriendPlayerCount
			warItem.Controls["UISlider_Red"].value = tempenemyPlayerCount
			warItem.Controls["UILabel_Green"].text = tostring(friendPlayerCount)
			warItem.Controls["UILabel_Red"].text = tostring(enemyPlayerCount)
			warItem.Controls["UILabel_Status2"].gameObject:SetActive(false)
		end
    else
        warItem.Controls["UILabel_Status2"].gameObject:SetActive(true)
    end
    EventHelper.SetClick(uiItem, function()
        if isInWar == true then
				ShowCityInWarDialog(cityData)
			else
					--printyellow("HasFamilyDeclareCity")
			if CitywarInfo.GetFamilyDeclareCity() ==cityData:GetCityId()  and stage == EnumStage.ENTROLL then 
				--printyellow("HasFamilyDeclareCity")
				ShowCityCanAttackDialog(cityData)
			else
				ShowCityNormalDialog(cityData)
			
			end
        end
    end)
end

local function SetCities(citiesDict, cities)
    local stage = CitywarInfo.GetFamilyCityWarStage()
    local EnumStage = cfg.family.citywar.CityWarStage
    --printyellow("currentStage :=> ", stage)

    UIHelper.ResetItemNumberOfUIList(fields.UIList_CityWar, utils.table_count(citiesDict) )
    for i, cityData in pairs(citiesDict) do
        if cities == nil or (cities ~= nil and cities[cityData:GetCityId()] ~= nil) then
            --local uiItem = fields.UIList_Cities:GetItemByIndex(cityData:GetCityId())
            local uiItem = GetListItemByName(fields.UIList_Cities.transform, cityData:GetListItemName())
            local warItem = uiItem and fields.UIList_CityWar:GetItemByIndex(uiItem.Index) or nil

            if uiItem and warItem then
                --printyellow("City: ", cityData:GetCityId(), cityData:GetCityName(),cityData:GetDefenderColor(),cityData:IsFamilyAttacking(),cityData:IsFamilyDefending())

                uiItem.Controls["UISprite_Color"].color = cityData:GetDefenderColor() or GetDefaultColor()
                uiItem.Controls["UILabel_LogoName"].text = cityData:GetLogoName() or ""
				--printyellow(uiItem.Controls["UIGroup_War"].transform.position)
                warItem.transform.position = uiItem.Controls["UIGroup_War"].transform.position
             --   printyellow(cityData:GetCityName(), tostring(cityData:CanDeclareWar()), stage,cityData:GetLogoName())
				
               -- printyellow(stage == EnumStage.BEFORE_ENROLL, stage == EnumStage.ENTROLL, stage == EnumStage.BATTLE)
				--printyellow("CitywarInfo.HasFamilyDeclareCity()",cityData:GetCityId(),CitywarInfo.GetFamilyDeclareCity(),CitywarInfo.HasFamilyDeclareCity(),cityData:IsFamilyAttacking(),cityData:IsFamilyDefending())

               -- SetCityCanAttack(cityData, uiItem, warItem)
				
				
                if stage == EnumStage.ENTROLL and cityData:CanDeclareWar() and (not CitywarInfo.HasFamilyDeclareCity()) then
                  --  printyellow("ENTROLL")
                    SetCityCanAttack(cityData, uiItem, warItem)
                elseif ((stage == EnumStage.BEFORE_BATTLE or stage == EnumStage.BATTLE) and (cityData:IsFamilyAttacking() or cityData:IsFamilyDefending()) and  not  cityData:IsPeace())
                        or (stage == EnumStage.ENTROLL and CitywarInfo.HasFamilyDeclareCity() == true and CitywarInfo.GetFamilyDeclareCity() == cityData:GetCityId() ) then
                  --  printyellow("BEFORE_BATTLE & BATTLE : ",cityData:GetCityName())
                    SetCityInWar(cityData, uiItem, warItem)
                else
                   -- printyellow("OTHER")

					SetCityNormal(cityData, uiItem, warItem)

                    
                end
	    end
        end
    end
end

local function SetCityWarMap(citiesDict)
	
	local UIPanel_Clip=fields.UIPanel_Clip
	local realViewSize = LuaHelper.GetScreenSize()
	--UIPanel_Clip:SetRect(0,0,realViewSize.x,realViewSize.y)
	
	
	local multipleX = realViewSize.x/1280
	local multipleY = realViewSize.y/720
	
	local tempmultiple = 1280/720
	
	local targetmultiple = realViewSize.x/realViewSize.y

    local clipRange     = fields.UIPanel_Clip:GetViewSize()
    local marginWidth   = (fields.UITexture_Area.width-clipRange.x)/2
    local marginHeight  = (fields.UITexture_Area.height-clipRange.y)/2


	--TODONGUI做了齐刘海的自适应旁边多了几个像素的空白区域
	if realViewSize.x == 1624 and realViewSize.y == 750 then
		if targetmultiple > tempmultiple then
		 marginWidth = marginWidth/multipleX - 100
		end
		
		if targetmultiple < tempmultiple then
			marginHeight = marginHeight/multipleY 
		end
	
	else
		if targetmultiple > tempmultiple then
		 marginWidth = marginWidth/multipleX - 100
		end
		
		if targetmultiple < tempmultiple then
			marginHeight = marginHeight/multipleY -100
		end
	
	end
	

    EventHelper.SetDrag(fields.UITexture_Area, function(go, delta)
        local targetPos = fields.UITexture_Area.transform.localPosition
        local targetX = Mathf.Clamp(targetPos.x + delta.x, -marginWidth, marginWidth)
        local targetY = Mathf.Clamp(targetPos.y + delta.y, -marginHeight, marginHeight)
        fields.UITexture_Area.transform.localPosition = Vector3(targetX, targetY, targetPos.z)
    end)
end
--============================================================================================
--底部信息
--============================================================================================
local function GetMyCityColorAndCount(citiesDict)
    local roleFamilyId = PlayerRole:Instance().m_FamilyID
    local cityCountInfo = {
        [cfg.family.citywar.CityLevelType.SENIOR] = 0,
        [cfg.family.citywar.CityLevelType.MEDIUM] = 0,
        [cfg.family.citywar.CityLevelType.PRIMARY] = 0,
    }
    --local myCityColor = mathutils.IntToColor(cfg.family.citywar.CityWar.DEFAULT_COLOR)

    local myCityColor = GetDefaultColor()

    for id, cityData in pairs(citiesDict) do
        if cityData:GetDefenderFamilyId() == roleFamilyId then
            for type, count in pairs(cityCountInfo) do
                if cityData:GetCityLevel() == type then
                    cityCountInfo[type] = cityCountInfo[type] + 1
                end
            end
            myCityColor = cityData:GetDefenderColor()
        end
    end
    return myCityColor, cityCountInfo
end

local function SetBottomInfo(citiesDict)
    local myColor, countInfo1 = GetMyCityColorAndCount(citiesDict)
    local countInfo2 = CitywarInfo.GetFamilyCityLevelCounts()
    fields.UISprite_CitySign_1.color = myColor
    fields.UISprite_CitySign_2.color = myColor
    fields.UISprite_CitySign_3.color = myColor
    fields.UISprite_AttackSign.color = myColor
    fields.UISprite_DefenceSign.color = myColor
    local countInfo = countInfo2 or countInfo1
    fields.UILabel_CitySign_1.text = tostring(countInfo[cfg.family.citywar.CityLevelType.SENIOR] or 0)
    fields.UILabel_CitySign_2.text = tostring(countInfo[cfg.family.citywar.CityLevelType.MEDIUM] or 0)
    fields.UILabel_CitySign_3.text = tostring(countInfo[cfg.family.citywar.CityLevelType.PRIMARY] or 0)
end

local function GetLuckBonusCitiesName(citiesDict)
    local str = ""
    for id, cityData in pairs(citiesDict) do
        --printyellow("cities:",cityData:GetCityName(),tostring(cityData:ExistsLuckyBonus()))
        if cityData:ExistsLuckyBonus() then

            if str ~= "" then
                str = str .. LocalString.StopSeparator
            end
            str = str .. cityData:GetCityName()
        end
    end
    return str
end

local function SetBottomWarTips(citiesDict)
    --[[待定]]
    local stage = CitywarInfo.GetFamilyCityWarStage()
    --printyellow("stage",stage)
   -- printyellow("=======================================")
    local tips = CitywarInfo.GetCurrentTip()
    tips = utils.table_sub_count(tips, 5)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Tips, #tips)
   -- printyellow("________________________________",#tips)
    for i, tip in ipairs(tips) do
        local uiItem = fields.UIList_Tips:GetItemByIndex(i-1)
        --printyellow(i,tip)
        if uiItem then
            if stage == cfg.family.citywar.CityWarStage.LUCKY_BONUS then
                --printyellow("aaaa")
                local finalText = string.gsub( tip:GetContent(),"{name}", GetLuckBonusCitiesName(citiesDict))
                uiItem.Controls["UILabel_Log"].text = finalText
            else
                uiItem.Controls["UILabel_Log"].text = tip:GetContent()
            end
            --printyellow(tip:GetContent())
            local oldColor = uiItem.Controls["UILabel_Log"].color
            local alpha = (25 - i * i)/24
            alpha = alpha > 0 and alpha or 0
            uiItem.Controls["UILabel_Log"].color = Color(oldColor.r, oldColor.g, oldColor.b, alpha)
        end
    end
end

local isShowLogs = false

local function SetBottomWarLog(citiesDict)
    fields.UIGroup_Log.gameObject:SetActive(isShowLogs)
    fields.UIButton_Log.gameObject:SetActive(not isShowLogs)
    if isShowLogs then
        EventHelper.SetClick(fields.UIButton_Hide, function()
            isShowLogs = false
            SetBottomWarLog(citiesDict)
        end)
    else
        EventHelper.SetClick(fields.UIButton_Log, function()
            isShowLogs = true
            SetBottomWarLog(citiesDict)
        end)
        return
    end
    --[[待定]]
    local logs = CitywarInfo.GetFamilyLogs()
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Logs, #logs)
    for i, log in ipairs(logs) do
        local uiItem = fields.UIList_Logs:GetItemByIndex(i-1)
        if uiItem then
            uiItem.Controls["UILabel_Log"].text = log:GetContent()
        end
    end
end

local function RefreshBattleReddot()
    local redDotSprite= fields.UIButton_Week.gameObject.transform:Find("UISprite_Warning")
    if redDotSprite then
        --printyellow("[tabfamilyworld:RefreshBattleReddot] Set UIButton_Week reddot active=", CitywarInfo.HasNewBattle())
        redDotSprite.gameObject:SetActive(CitywarInfo.HasNewBattle())
    end
end

local function RefreshBonusReddot()
    local redDotSprite= fields.UIButton_Info.gameObject.transform:Find("UISprite_Warning")
    if redDotSprite then
      --  printyellow("[tabfamilyworld:RefreshBonusReddot] Set UIButton_Info reddot active=", CitywarInfo.HasFamilyLuckyBonus())
        --printt(CitywarInfo.GetFamilyLuckyBonus())
        redDotSprite.gameObject:SetActive(CitywarInfo.HasFamilyLuckyBonus())
    end
end

local function SetBottomButtons(citiesDict)
    EventHelper.SetClick(fields.UIButton_World, function()
        UIManager.show("citywar.dlgworldterritorial")
    end)
    EventHelper.SetClick(fields.UIButton_Declare, function()
        UIManager.show("citywar.dlgdeclarewarterritorial")
    end)
    EventHelper.SetClick(fields.UIButton_Week, function()
        CitywarInfo.SetNewBattleState(false)
        UIManager.show("citywar.dlgweekbattle")
    end)
    EventHelper.SetClick(fields.UIButton_My, function()
        UIManager.show("citywar.dlgmyterritorial")
    end)
    EventHelper.SetClick(fields.UIButton_Solid, function()
        --UIManager.showdialog("citywar.dlgworldterritorial")
        local citywarcfg = ConfigManager.getConfig("citywar")
        if citywarcfg then
            CitywarManager.ShowRule(citywarcfg.maintips)
        else
            print("[ERROR][tabfamilyworld:fields.UIButton_Solid] citywarcfg nil!")
        end
    end)
    EventHelper.SetClick(fields.UIButton_Info, function()
        UIManager.show("citywar.tabcitywaraward")
    end)
    --fields.UIButton_Solid.isEnabled = false
end
--============================================================================================
--UI
--============================================================================================
local function hide()

end

local function destroy()

end

local function refresh(params)
    params = params or {}
    params.refresh = params.refresh or { ["all"] = true }
    local citiesDict = CitywarInfo.GetAllCities()
    --地图
    if params.refresh["all"] or params.refresh["map"] then
        SetCityWarMap(citiesDict)
    end
    --城市信息
    if params.refresh["all"] or params.refresh["city"] then
        SetCities(citiesDict, params.cities)
    end
    --城市占领信息
    if params.refresh["all"] or params.refresh["info"] then
        SetBottomInfo(citiesDict)
    end
    --按钮
    if params.refresh["all"] or params.refresh["button"] then
        SetBottomButtons(citiesDict)
    end
    --战斗日志
    if params.refresh["all"] or params.refresh["log"] then
        SetBottomWarLog(citiesDict)
    end
    --本周战役按钮红点
    if params.refresh["all"] or params.refresh["weekbattles"] then
        RefreshBattleReddot()
    end
    --奖励按钮红点
    if params.refresh["all"] or params.refresh["luckybonus"] then
        RefreshBonusReddot()
    end
    --提示信息
    if params.refresh["all"] or params.refresh["tip"] then
        SetBottomWarTips(citiesDict)
    end
end

local function show(params)
    CitywarManager.send_CGetAllCitys()
    CitywarManager.send_CGetBattleLog()
    CitywarManager.send_CGetMyBattles()
    CitywarManager.send_CGetAllLuckyBonusInfo()
end


local function init(params)
    name, gameObject, fields = unpack(params)

end

local function uishowtype()
    return UIShowType.Refresh
end
local elapsed = 0
local UPDATE_FRAME = 10
local function second_update()
    elapsed = elapsed + 1
    if elapsed < UPDATE_FRAME then
        return
    end
    elapsed = 0
    local stage = CitywarInfo.GetFamilyCityWarStage()
    local EnumStage = cfg.family.citywar.CityWarStage
    if stage == EnumStage.BATTLE or stage == EnumStage.BEFORE_LUCKY_BONUS or stage == EnumStage.LUCKY_BONUS then
        CitywarManager.send_CGetMyBattles()
    end
end

local citynumber = {}
local function loadCityNumber(params)

	
	if #params <2 then
		return
	else if tonumber(params[2])  ==  1 and #citynumber >0  then
			for i , citydata  in ipairs(citynumber) do 
				citydata.gameObject:SetActive(true)
			end
	else if tonumber(params[2]) == 1 and #citynumber <= 0 then
			local targetposition = Vector3(-39,-13,0)
			local targetname = "UILabel_CityNumber"
			local citywarcfg = ConfigManager.getConfig("citywar")
			local citylistcfg = citywarcfg.citys
			for i , citydata in ipairs(citylistcfg) do
				local tempUIButtonTransform = GetListItemByName(fields.UIList_Cities.transform,citydata.listitemname)
				local target = GameObject.Instantiate(fields.UILabel_CityNumber.gameObject).gameObject
				target.transform.parent = tempUIButtonTransform.transform
				local targetlabel = target.gameObject:GetComponent("UILabel")
				target.gameObject.transform.localScale = Vector3.one
				target.gameObject.transform.localPosition = targetposition
				target.gameObject.transform.name = citydata.listitemname
				targetlabel.text = tostring(citydata.cityid) 
				table.insert(citynumber,targetlabel)
			end
	else if tonumber(params[2]) == 2 and #citynumber >0 then
			for i , citydata  in ipairs(citynumber) do 
				citydata.gameObject:SetActive(false)
			end
		end
	end
end

end
	
	
end

RegisterClientCmd("/LCN",loadCityNumber)

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    second_update = second_update,
}
