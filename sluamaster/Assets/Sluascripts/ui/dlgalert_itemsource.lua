local require            = require
local unpack             = unpack
local print              = print
local UIManager          = require("uimanager")
local network            = require("network")
local ItemManager        = require("item.itemmanager")
local ItemEnum           = require("item.itemenum")
local ConfigManager      = require("cfg.configmanager")
local ModuleLockManager  = require("ui.modulelock.modulelockmanager")
local FamilyManager      = require("family.familymanager")
local PlayerRole         = require("character.playerrole")
local EventHelper        = UIEventListenerHelper


local name
local gameObject
local fields

local g_SourceList
local g_AllDialogs
local g_CurViewName

local function SetItemInfo(item)
	if not item then 
		logError("[DlgAlert_ItemSource]:Item data is nil")
		return 
	end
	local baseType = item:GetBaseType()
	--local temp = item:GetQuality()
	--printyellow(temp)
	colorutil.SetQualityColorText(fields.UILabel_Name,item:GetQuality(),item:GetName())
	fields.UISprite_Quality.color = colorutil.GetQualityColor(item:GetQuality())
	fields.UITexture_Icon:SetIconTexture(item:GetTextureName())
	fields.UISprite_Fragment.gameObject:SetActive((item:GetBaseType() == ItemEnum.ItemBaseType.Fragment)) 
end

local function InitSourceList()
	if fields.UIList_Source.Count == 0 then 
		for _,source in ipairs(g_SourceList) do
			local listItem = fields.UIList_Source:AddListItem()
			listItem:SetText("UILabel_SourceDesc",source.desc)
		end
	end
end

local function GetSpecifiedEquip(equipType,quality)
	local equipsData = ConfigManager.getConfig("equip")
	local playerLevel = PlayerRole:Instance():GetLevel()
	local tempEquips = { }
	for csvId,data in pairs(equipsData) do
		if data.type == equipType and data.quality == quality then 
			local equip = ItemManager.CreateItemBaseById(csvId)
			if equip and (equip:GetProfessionLimit() == PlayerRole:Instance().m_Profession or equip:GetProfessionLimit() == cfg.Const.NULL) then 
				tempEquips[#tempEquips + 1] = equip
			end
		end
	end
	-- 按照level升序排列
	table.sort(tempEquips,function(equip1,equip2) return (equip1:GetLevel() < equip2:GetLevel()) end)
	if #tempEquips ~= 0 then 
		if tempEquips[1]:GetLevel() >= playerLevel then
			return tempEquips[1]
		else
			local maxIndex = -1
			for idx,equip in ipairs(tempEquips) do
				if playerLevel >= equip:GetLevel() then 
					maxIndex = idx
				end
			end
			return tempEquips[maxIndex]
		end
	end
	return nil
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	if params then
		if params.item then 
			local sourceCfg = ConfigManager.getConfigData("itemsource",(params.item):GetConfigId())
			if sourceCfg then
				g_SourceList = sourceCfg.sourcelist
				SetItemInfo(params.item)
				g_CurViewName = params.viewname
				InitSourceList()
			else
				logError("Can't find itemsource: " .. (params.item):GetConfigId())
				UIManager.hide(name)
			end
		elseif params.equiptype then  
			local sourceCfg = ConfigManager.getConfigData("equipsource",params.equiptype)
			if sourceCfg then
				local equip = GetSpecifiedEquip(params.equiptype,cfg.item.EItemColor.ORANGE)
				g_SourceList = sourceCfg.sourcelist
				SetItemInfo(equip)
				g_CurViewName = params.viewname
				InitSourceList()
			else
				logError("Can't find equipsource,the equiptype: "..params.equiptype)
				UIManager.hide(name)
			end
		else
			logError("Can't find any source,params is wrong")
			UIManager.hide(name)
		end
	else
		logError("params should not be empty!!!") 
		UIManager.hide(name)
	end
end

local function hide()
	-- print(name, "hide")
	fields.UIList_Source:Clear()
end

local function refresh(params)
	-- print(name, "refresh")
end

local function update()
	-- print(name, "update")
end

local function init(params)
	name, gameObject, fields = unpack(params)
	g_AllDialogs = ConfigManager.getConfig("dialog")

	gameObject.transform.localPosition = Vector3(0,0,-600)

	EventHelper.SetClick(fields.UIButton_Close, function()
		UIManager.hide(name)
	end )

	EventHelper.SetListClick(fields.UIList_Source, function(listItem)

		local dlgName = g_SourceList[listItem.Index + 1].dlgname
		if dlgName == "" then 
			UIManager.hide(name)
			return
		elseif dlgName == "family.dlgfamily" and not FamilyManager.InFamily() then 
			UIManager.ShowSystemFlyText(LocalString.Family.NoFamily)
			return 
		end
		local tabIndex1 = (g_SourceList[listItem.Index + 1].tabindex1 ~= cfg.Const.NULL) and g_SourceList[listItem.Index + 1].tabindex1 or nil
		local tabIndex2 = (g_SourceList[listItem.Index + 1].tabindex2 ~= cfg.Const.NULL) and g_SourceList[listItem.Index + 1].tabindex2 or nil
		local tabIndex3 = (g_SourceList[listItem.Index + 1].tabindex3 ~= cfg.Const.NULL) and g_SourceList[listItem.Index + 1].tabindex3 or nil
		local bShowRetunBtn = g_AllDialogs[dlgName].showreturn
		-- 检查传入界面是否是弹窗
		local bIsDialog = false
		if g_AllDialogs[g_CurViewName] then 
			bIsDialog = g_AllDialogs[g_CurViewName].showreturn
		end
		-- 检查传入界面是否是弹窗，是弹窗则隐藏
		if not bIsDialog then 
			UIManager.hide(g_CurViewName)
		end 
		UIManager.hide(name)

		local status = defineenum.ModuleStatus.LOCKED
		if tabIndex1 then 
			status = ModuleLockManager.GetModuleStatusByIndex(dlgName,tabIndex1)
		else
			status = ModuleLockManager.GetModuleStatusByType(g_AllDialogs[dlgName].parenttype)
		end

		if status == defineenum.ModuleStatus.UNLOCK then
			-- 已经开启
			-- 来源是同一个界面
			if bShowRetunBtn then 
				if g_CurViewName == dlgName then 
					UIManager.hidedialog(dlgName)
				end
				if dlgName == "vipcharge.dlgfirstofcharge" then
					local VipChargeManager=require"ui.vipcharge.vipchargemanager"
					local isRechargeUsed = VipChargeManager.GetFirstPayUsed()~=0
					if isRechargeUsed == true then
						UIManager.showdialog("vipcharge.dlgrecharge")
						return
					end
				end
				UIManager.showdialog(dlgName,{tabindex2 = tabIndex2,tabindex3 = tabIndex3},tabIndex1) 
			else
				if dlgName == "vipcharge.dlgfirstofcharge" then
					local VipChargeManager=require"ui.vipcharge.vipchargemanager"
					local isRechargeUsed = VipChargeManager.GetFirstPayUsed()~=0
					if isRechargeUsed == true then
						UIManager.showdialog("vipcharge.dlgrecharge")
						return
					end
				end
				UIManager.show(dlgName) 
			end
		elseif status == defineenum.ModuleStatus.LOCKED then

			-- 未开启，飘字
			local configData = nil 
			if tabIndex1 then 
				configData = UIManager.gettabgroup(dlgName,tabIndex1)
			else
				configData = ConfigManager.getConfigData("uimainreddot",g_AllDialogs[dlgName].parenttype)
			end
			if configData then
				local conditionData = ConfigManager.getConfigData("moduleunlockcond",configData.conid)

				if conditionData then 
					local text = ""
					if conditionData.openlevel ~= 0 then
						text = (conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
					elseif conditionData.opentaskid ~= 0 then
						local taskData = ConfigManager.getConfigData("task",conditionData.opentaskid)
						if taskData then
							text = string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
						end
					end
					UIManager.ShowSystemFlyText(text)
				else
					UIManager.ShowSystemFlyText(LocalString.ItemSource_Locked)
				end
			end
		end


	end )



end

return {
	init    = init,
	show    = show,
	hide    = hide,
	update  = update,
	destroy = destroy,
	refresh = refresh,
}

