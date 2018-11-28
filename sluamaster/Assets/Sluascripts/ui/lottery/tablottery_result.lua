--local tablottery_result  = require "ui.lottery.tablottery_result"
local unpack         = unpack
local print          = print
local EventHelper    = UIEventListenerHelper
local uimanager      = require("uimanager")
local network        = require("network")
local lotterymanager = require "ui.lottery.lotterymanager"

local LimitManager   = require("limittimemanager")
local ItemEnum 		 = require("item.itemenum")
local ItemManager    = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local Pet            = require"character.pet.pet"
local Talisman       = require("character.talisman.talisman")
local PlayerRole     = require "character.playerrole"
local Define         = require("define")
local ConfigManager = require"cfg.configmanager"


local gameObject
local name
local fields
local dialogname = "lottery.dlglottery"
local tabname = "lottery.tablottery_result"

local lotterydatas
local showresults = {}
local showindex = 0
local showtime = 0
local ShowInterval = 0.2
local showcharacter
local quality_showeffects --根据品质显示不同特效组
local quality_ranks --根据品质显示不同Sprite
local plattransform
local frameEffectTransform
local modelEffectTransform
local pickloadingEffectTransform
local CureanimationObject
local g_partnerCharacter
local frameResultPosition = Vector3(0,152.8,0) --碎片展示的位置
local wholecardPosition = Vector3(0,60,0)    --整张卡展示的位置
local wholecardcardPostion = Vector3(0,15,0)
local iswTenCompany
local sortorder

g_bDebugEnable=2

local ShowState = enum{
    "None",
    "Before",
    "Show",
    "Stop",
    "Interrupt", --被其它页面中断
    "Finish",
}

local CurrentState = ShowState.None
local InterruptState = ShowState.None



--模型加载
local function OnModelLoaded(go)
	print("OnModelLoaded")
	if not g_Player and not g_Player.m_Object then return end

	local playerTrans = g_Player.m_Object.transform
	playerTrans.parent = fields.Texture_PlayerModel.transform
	playerTrans.localScale = Vector3.one * 150
	playerTrans.localPosition = Vector3(-5, -200, -170)
	playerTrans.rotation = Quaternion.Euler(-90,0,0)
	
	if modelEffectTransform ~= nil then
		modelEffectTransform.gameObject:SetActive(true)
	end
	ExtendedGameObject.SetLayerRecursively(g_Player.m_Object, Define.Layer.LayerUICharacter)
end


--整合整个招募界面的流程
local function  ConformityLottery(PetID)

--首先加载太子台
 Util.Load(string.format("character/c_%s.bundle", "zhaomu"), Define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
				if not IsNull(asset_obj) then
					 plattransform = GameObject.Instantiate(asset_obj)  				
					 SetDontDestroyOnLoad(plattransform.gameObject)				
					if fields.UIGroup_Start == nil then
						printyellow("设置父节点的对象是空的")
					else
						plattransform.gameObject.transform.parent = fields.UIGroup_Start.gameObject.transform
						plattransform.gameObject.transform.localScale = Vector3.one 
						plattransform.gameObject.transform.localPosition = Vector3(0,0,-605)
						ExtendedGameObject.SetLayerRecursively(plattransform.gameObject, define.Layer.LayerUICharacter)
						frameEffectTransform  = plattransform.gameObject.transform:Find("zhaomu2")
						modelEffectTransform  = plattransform.gameObject.transform:Find("zhaomu3")
						pickloadingEffectTransform  = plattransform.gameObject.transform:Find("zhaomu")
						local sortorder =  pickloadingEffectTransform.gameObject:AddComponent("SetSortingOrder")
						sortorder.setOrder = 1500
						CureanimationObject = frameEffectTransform.transform:Find("GameObject/M_yuantong_03")
					end
					
					--playerTrans.transform.rotation = Quaternion.Euler(-90,0,0)
				end
	end)
	
	 local pet = ConfigManager.getConfigData("petbasicstatus",PetID)
        if pet then
            local modeldata = ConfigManager.getConfigData("model",pet.modelname)
				g_partnerCharacter =  Pet:new(0,showinfo.itemid,0,true)
				g_partnerCharacter.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
				g_partnerCharacter:RegisterOnLoaded(function(go)
				if IsNull(g_partnerCharacter.m_Object)  then printyellow("no object??") return end
				plattransform.gameObject:SetActive(true)
				local trans         = g_partnerCharacter.m_Object.transform
				trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
				trans.rotation = Quaternion.Euler(-90,0,0)
				SetModelOffset(trans,showinfo.itemid)
				ExtendedGameObject.SetLayerRecursively(g_partnerCharacter.m_Object, define.Layer.LayerUICharacter)
				end)
				g_partnerCharacter:init(pet.PetSkin)
        end
	
	if pickloadingEffectTransform ~= nil then
		pickloadingEffectTransform.gameObject:SetActive(false)
        pickloadingEffectTransform.gameObject:SetActive(true)
        fields.UILabel_Skip.gameObject:SetActive(true)
	end
end


-----------------------------------------------------------------------------


--加载太子台
local function loadPlat(platname)

	if plattransform == nil then 
		 Util.Load(string.format("character/c_%s.bundle", platname), Define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
				if not IsNull(asset_obj) then
					 plattransform = GameObject.Instantiate(asset_obj)  				
					 SetDontDestroyOnLoad(plattransform.gameObject)				
					if fields.UIGroup_Start == nil then
						printyellow("设置父节点的对象是空的")
					else
						plattransform.gameObject.transform.parent = fields.UIGroup_Start.gameObject.transform
						plattransform.gameObject.transform.localScale = Vector3.one 
						plattransform.gameObject.transform.localPosition = Vector3(0,0,-605)
						ExtendedGameObject.SetLayerRecursively(plattransform.gameObject, define.Layer.LayerUICharacter)
						frameEffectTransform  = plattransform.gameObject.transform:Find("zhaomu2")
						modelEffectTransform  = plattransform.gameObject.transform:Find("zhaomu3")
						pickloadingEffectTransform  = plattransform.gameObject.transform:Find("zhaomu")
						sortorder =  pickloadingEffectTransform.gameObject:AddComponent("SetSortingOrder")
						sortorder.setOrder = 1500
						CureanimationObject = frameEffectTransform.transform:Find("GameObject/M_yuantong_03")
					end
					
					--playerTrans.transform.rotation = Quaternion.Euler(-90,0,0)
				end
			end)
	else
		plattransform.gameObject:SetActive(true)
	end
end


--模型加载
local function OnModelLoaded(go)
	print("OnModelLoaded")
	if not g_Player and not g_Player.m_Object then return end

	local playerTrans = g_Player.m_Object.transform
	playerTrans.parent = fields.Texture_PlayerModel.transform
	playerTrans.localScale = Vector3.one * 150
	playerTrans.localPosition = Vector3(-5, -200, -170)
	playerTrans.rotation = Quaternion.Euler(-90,0,0)

	ExtendedGameObject.SetLayerRecursively(g_Player.m_Object, Define.Layer.LayerUICharacter)
end

local function SetState(state)
    -- printyellow("tablottery SetState " ,utils.getenumname(ShowState,state))
    if state == ShowState.Interrupt then 
        InterruptState = CurrentState
    end 

    CurrentState = state
end

local function SetOptionActive(active)
    for index = 0,fields.UIList_Option.Count-1 do
        local item = fields.UIList_Option:GetItemByIndex(index)
        local button = item.Controls["UIButton_Pray"]
        button.isEnabled = active
    end
    uimanager.call("dlgdialog","SetListCurrencyActive",active)
    uimanager.call("dlgdialog","SetReturnButtonActive",active)
    if fields.UIGroup_Options.gameObject.activeSelf ~=active then
	    fields.UIGroup_Options.gameObject:SetActive(active)
    end
end 

local function release()

    if showcharacter ~= nil then
        showcharacter:release()
        showcharacter = nil
    end
	
	if g_partnerCharacter ~= nil then
		g_partnerCharacter:release()
		g_partnerCharacter = nil
	end
end

local function SetModelOffset(go,itemid)
    local modeloffset = ConfigManager.getConfigData("lotteryitemoffset",itemid)
    if modeloffset and go then
        go.transform.localPosition = Vector3(modeloffset.x,modeloffset.y,modeloffset.z)
        go.transform.localScale = Vector3(modeloffset.scale,modeloffset.scale,modeloffset.scale)
    else
        go.transform.localPosition = Vector3.zero
        go.transform.localScale = Vector3.one
    end
	sortorder.enabled = false
	sortorder.enabled = true
end

local function RefreshQualityEffect(quality)
     for q,groups in pairs(quality_showeffects) do
        for _,group in ipairs(groups) do
            group.gameObject:SetActive(quality == q)
        end
    end
end


local function RefreshModel(showinfo)
    release()
    fields.UITexture_Character.gameObject:SetActive(showinfo.itemtype == ItemEnum.ItemBaseType.Pet)
    fields.UITexture_Talisman.gameObject:SetActive(showinfo.itemtype == ItemEnum.ItemBaseType.Talisman)

    if showinfo.itemtype == ItemEnum.ItemBaseType.Pet then
        local pet = ConfigManager.getConfigData("petbasicstatus",showinfo.itemid)
        if pet then
            local modeldata = ConfigManager.getConfigData("model",pet.modelname)
				g_partnerCharacter =  Pet:new(0,showinfo.itemid,0,true)
				g_partnerCharacter.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
				g_partnerCharacter:RegisterOnLoaded(function(go)
				if IsNull(g_partnerCharacter.m_Object)  then printyellow("no object??") return end
				plattransform.gameObject:SetActive(true)
				local trans         = g_partnerCharacter.m_Object.transform
				trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
				trans.rotation = Quaternion.Euler(-90,0,0)
				SetModelOffset(trans,showinfo.itemid)
				ExtendedGameObject.SetLayerRecursively(g_partnerCharacter.m_Object, define.Layer.LayerUICharacter)
				end)
				g_partnerCharacter:init(pet.PetSkin)
        end
    elseif showinfo.itemtype == ItemEnum.ItemBaseType.Talisman then
        showcharacter = Talisman:new()
        showcharacter.m_AnimSelectType= cfg.skill.AnimTypeSelectType.UI
        showcharacter:RegisterOnLoaded(function(go)
            if IsNull(showcharacter.m_Object)  then printyellow("no object??") return end
			plattransform.gameObject:SetActive(true)
            local trans         = showcharacter.m_Object.transform
            trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
			
            trans.rotation = Quaternion.Euler(-90,0,0)
            ExtendedGameObject.SetLayerRecursively(showcharacter.m_Object, define.Layer.LayerUICharacter)
            --showcharacter:UIScaleModify()
            SetModelOffset(showcharacter.m_Object,showinfo.itemid)
        end)
        showcharacter:init(showinfo.item,PlayerRole:Instance(),-1)

    end


    local quality = showinfo.showitem:GetQuality()

   fields.UITexture_Rank:SetIconTexture(quality_ranks[quality])

    EventHelper.SetPlayTweensFinish(fields.UIPlayTweens_Show,function()
        fields.UITexture_Background.gameObject:SetActive(true)
	end)
    fields.UITexture_Background.gameObject:SetActive(false)
	fields.UIPlayTweens_Show:Play(true)
end

--播放抽卡特效
local function PlayPickloadingEffect()
	if pickloadingEffectTransform ~= nil then
		pickloadingEffectTransform.gameObject:SetActive(false)
        pickloadingEffectTransform.gameObject:SetActive(true)
        fields.UILabel_Skip.gameObject:SetActive(true)
	end
	
	if frameEffectTransform ~= nil and modelEffectTransform ~= nil and CureanimationObject ~= nil then
		frameEffectTransform.gameObject:SetActive(false)
		modelEffectTransform.gameObject:SetActive(false)
		CureanimationObject.gameObject:SetActive(true)
	end
end


local function startshow()

	loadPlat("zhaomu")
	PlayPickloadingEffect()
    uimanager.refresh(tabname)
    showindex = 1
    showtime = 0
    SetOptionActive(false)
    fields.UIGroup_Result.gameObject:SetActive(false)
    fields.UIGroup_WholeCard.gameObject:SetActive(false)
    fields.UIGroup_Start.gameObject:SetActive(true)
    fields.UIList_Rewards:Clear()
    SetState(ShowState.Before)
    EventHelper.SetPlayTweensFinish(fields.UIPlayTweens_Timer,function()
        if CurrentState == ShowState.Before then
            SetState(ShowState.Show)
            fields.UIGroup_Result.gameObject:SetActive(true)
        end
	end)
    fields.UIPlayTweens_Timer:Play(true)
    fields.UIPlayTweens_Timeline:Play(true)
end



--显示抽卡结果
local function showresult(results,datas)
    lotterydatas = datas
    showresults = results

    SetState(ShowState.None)
    if uimanager.isshow(tabname) then
        startshow()
    else
        uimanager.showdialog(tabname)
    end
end


local function destroy()
    -- print(name, "destroy")
    release()
    SetState(ShowState.None)
    fields.UIGroup_Result.gameObject:SetActive(false)
    lotterydatas = nil
    showresults = nil
end


local function show(params)

	local Background = gameObject.transform:Find("Tween_Lottry/Frame/Panel/Background")
	if Background~=nil then
        local uiTex = Background.gameObject:GetComponent("UITexture")
        if uiTex~=nil then
            uimanager.SetUITextureFit(uiTex)
        end
    end
    if CurrentState == ShowState.Interrupt then 
        if InterruptState == ShowState.Before then
            startshow()
        else
            SetOptionActive(false)
            SetState(InterruptState)
        end
        InterruptState = ShowState.None
    elseif CurrentState == ShowState.None then 
        startshow() 
    end 
    
end

local function hide()
    -- print(name, "hide")
    if CurrentState == ShowState.Before or CurrentState == ShowState.Show or CurrentState == ShowState.Stop then
        SetState(ShowState.Interrupt)
    end
--[[	if plattransform ~= nil then
		GameObject.Destroy(plattransform.gameObject)
	end
	plattransform = nil
	frameEffectTransform = nil
	modelEffectTransform = nil
    pickloadingEffectTransform = nil--]]
    local lotterymanager = require "ui.lottery.lotterymanager"
    lotterymanager.setRecruit(true)
end
local function refresh(params)
    for index = 0,fields.UIList_Option.Count-1 do
        local item = fields.UIList_Option:GetItemByIndex(index)
        item.Data = lotterydatas[index+1]
		if item.Data:IsFree() then 
			item:SetText("UILabel_Msg",colorutil.GetColorStr(colorutil.ColorType.Green,item.Data:GetMsg()))
		else
			item:SetText("UILabel_Msg",colorutil.GetColorStr(colorutil.ColorType.Red,item.Data:GetMsg()))
		end
        item.Controls["UISprite_Icon"].spriteName = item.Data:GetIcon()
        item:SetText("UILabel_Amount",item.Data:GetAmount())
        item:SetText("UILabel_Discription",item.Data:Desc())
        local button = item.Controls["UIButton_Pray"]
        EventHelper.SetClick(button, function()
            local leftoverNum = 0
            lotterymanager.CPickCard(item.Data)
            local num = item.Data.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY and 1 or 10
            local validate = checkcmd.CheckData( { data = item.Data.m_Data.requirecurrency, num = num, showsysteminfo = false })
            if item.Data.m_TextureData.type == 8 or item.Data.m_TextureData.type == 7  or item.Data.m_TextureData.type == 10 or item.Data.m_TextureData.type ==11 then 
                local BagManager   = require "character.bagmanager"
                if BagManager.GetUnLockedSize(cfg.bag.BagType.TALISMAN) - BagManager.GetItemSlotsNum(cfg.bag.BagType.TALISMAN) < num then 
                    leftoverNum = BagManager.GetUnLockedSize(cfg.bag.BagType.TALISMAN) - BagManager.GetItemSlotsNum(cfg.bag.BagType.TALISMAN) - num
                end
            end
            if validate then 
                for index = 0,fields.UIList_Option.Count-1 do -- 请求按钮不可点击处理
                    local btnPray = fields.UIList_Option:GetItemByIndex(index).Controls["UIButton_Pray"]
                    if leftoverNum >= 0 then   
                        btnPray.isEnabled = false
                    -- else
                    --     if leftoverNum > -10 then --- 可以单抽
                    --         if index == 1 then 
                    --             btnPray.isEnabled = false
                    --         end
                    --     else                     --- 都不可以
                    --         btnPray.isEnabled = false
                    --     end
                    end
                end
            end
        end )
    end
	if #showresults >1 then
		iswTenCompany = true
		 fields.UIScrollView_MoneyTen.gameObject.transform.localPosition = wholecardPosition
	else
		fields.UIScrollView_MoneyTen.gameObject.transform.localPosition = frameResultPosition
		iswTenCompany = false
	end
end



local function updatestate_before()

end


local function updatestate_show()
    if showtime < ShowInterval then
        showtime = showtime + Time.deltaTime
    else
        fields.UILabel_Skip.gameObject:SetActive(false)
        if showindex <= #showresults then
			
            showtime = 0
            local showresult = showresults[showindex]
            showindex = showindex+1
			if iswTenCompany == true and showresult.wholecard == false then
				plattransform.gameObject:SetActive(false)
			end
			
            local item = fields.UIList_Rewards:AddListItem()
            item.Id = showresult.showitemid
            item.Data = showresult.showitem
            item:SetIconTexture(showresult.showitem:GetIconPath())
            item:SetText("UILabel_Count",string.format("X%s",showresult.showitem:GetNumber()))
            colorutil.SetQualityColorText(item.Controls["UILabel_Name"],showresult.showitem:GetQuality(),showresult.showitem:GetName())
            item.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(showresult.showitem:GetQuality())
            --printyellow("isfragment",showresult.showitem:GetBaseType(),ItemEnum.ItemBaseType.Item)

		    item.Controls["UISprite_Fragment"].gameObject:SetActive(showresult.showitem:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
			if frameEffectTransform ~= nil then frameEffectTransform.gameObject:SetActive(true) end
            if showresult.wholecard then
                fields.UILabel_Reward.text = showresult.title
                fields.UIGroup_WholeCard.gameObject:SetActive(true)
				if modelEffectTransform ~= nil then
					modelEffectTransform.gameObject:SetActive(true)
				end
                fields.UILabel_Splite.gameObject:SetActive(showresult.issplit)
                RefreshModel(showresult)
                SetState(ShowState.Stop)
				fields.UIGroup_Result.gameObject:SetActive(false)
            end
        else
            SetState(ShowState.Finish)
            SetOptionActive(true)
        end
    end
end

local function updatestate_stop()

end

local function update()
    -- print(name, "update")

    if CurrentState == ShowState.Before then
        updatestate_before()
    elseif CurrentState == ShowState.Show then
        updatestate_show()
    elseif CurrentState == ShowState.Stop then
        updatestate_stop()
    end
    if showcharacter then
        showcharacter.m_Avatar:Update()
    end
	
	if g_partnerCharacter then
		g_partnerCharacter.m_Avatar:Update()
	end

end


local function second_update(now)
    for index = 0,fields.UIList_Option.Count-1 do
        local item = fields.UIList_Option:GetItemByIndex(index)
        --printt(item.Data)
        if item.Data.m_TextureData.iscooldown then
            local UILabel_Msg           = item.Controls["UILabel_Msg"]
            if not item.Data:IsCoolDown() then
                UILabel_Msg.gameObject:SetActive(true)
                uimanager.refresh(tabname)
            else
                if UILabel_Msg.gameObject.activeInHierarchy then
                    UILabel_Msg.gameObject:SetActive(false)
                    uimanager.refresh(tabname)
                end
            end
        end
    end
end


local function init(params)
    name, gameObject, fields = unpack(params)
      --print(name, "init")
    quality_showeffects = {
        [cfg.item.EItemColor.BLUE] = {fields.UIGroup_Blue},
        [cfg.item.EItemColor.PURPLE] = {fields.UIGroup_Purple},
        [cfg.item.EItemColor.ORANGE] = {fields.UIGroup_Orange},
        [cfg.item.EItemColor.RED] = {fields.UIGroup_Red},
    }


    quality_ranks = {
        [cfg.item.EItemColor.PURPLE] = "Texture_Excellent",
        [cfg.item.EItemColor.ORANGE] = "Texture_Perfect",
        [cfg.item.EItemColor.RED] = "Texture_Peerless",
    }

         --返回
    EventHelper.SetClick(fields.UITexture_Background, function()
        fields.UIGroup_WholeCard.gameObject:SetActive(false)
		fields.UIGroup_Result.gameObject:SetActive(true)
        SetState(ShowState.Show)
		if g_partnerCharacter ~= nil then
			g_partnerCharacter:release()
		end
		
		if showcharacter ~= nil then
			showcharacter:release()
		end
		if iswTenCompany == true then
			if plattransform ~= nil then
				plattransform.gameObject:SetActive(false)
			end
		else
			if plattransform ~= nil then
				plattransform.gameObject:SetActive(true)
			end
		end
    end )

    local Background = gameObject.transform:Find("Tween_Lottry/Frame/Panel/Background")
    EventHelper.SetClick(Background, function()
        fields.UIGroup_WholeCard.gameObject:SetActive(false)
		fields.UIGroup_Result.gameObject:SetActive(true)
        SetState(ShowState.Show)
		if g_partnerCharacter ~= nil then
			g_partnerCharacter:release()
		end
		
		if showcharacter ~= nil then
			showcharacter:release()
		end
		if iswTenCompany == true then
			if plattransform ~= nil then
				plattransform.gameObject:SetActive(false)
			end
		else
			if plattransform ~= nil then
				plattransform.gameObject:SetActive(true)
			end
		end
    end )
end

--不写此函数 默认为 UIShowType.Default
local function uishowtype()
    return UIShowType.Refresh  --强制在切换tab页时回调show
    --return bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)
end

local function ondlgdialogrefresh() 
    SetOptionActive(not (CurrentState == ShowState.Before or CurrentState == ShowState.Show or CurrentState == ShowState.Stop))
end 

local g_testTalisman={}


local function clientCmd_showtestTalisman(params)
	if not isEnableClientCmd("/testTalisman") then
		   return 
	end 
	 if #params<6 then
	     return 
	 end
	release()
	local tempConfigLottery =  ConfigManager.getConfig("LotteryItemOffset")
	local position = Vector3(tonumber(params[3]),tonumber(params[4]),tonumber(params[5]))
	if tonumber(params[7])  == 1 then
		local pet = ConfigManager.getConfigData("petbasicstatus",tonumber(params[2]) )
        if pet then
            local modeldata = ConfigManager.getConfigData("model",pet.modelname)
				g_partnerCharacter =  Pet:new(0,tonumber(params[2]),0,true)
				g_partnerCharacter.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
				g_partnerCharacter:RegisterOnLoaded(function(go)
				if IsNull(g_partnerCharacter.m_Object)  then printyellow("no object??") return end
				plattransform.gameObject:SetActive(true)
				local trans         = g_partnerCharacter.m_Object.transform
				trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
				trans.transform.localScale = Vector3(tonumber(params[6]),tonumber(params[6]),tonumber(params[6]))
				trans.rotation = Quaternion.Euler(-90,0,0)
				trans.localPosition = position
				--SetModelOffset(trans,params[2])
				ExtendedGameObject.SetLayerRecursively(g_partnerCharacter.m_Object, define.Layer.LayerUICharacter)
				sortorder.enabled = false
				sortorder.enabled = true
				end)
				g_partnerCharacter:init(pet.PetSkin)
        end
	elseif tonumber(params[7]) == 2 then
		--local temptalisman = ConfigManager.getConfigData("TalismanBasic",tonumber(params[2]))
		local talismanmanager = require("ui.playerrole.talisman.talismanmanager")
		local tempGetTalisman = talismanmanager.GetCurrentTalisman()
		showcharacter = Talisman:new()
        showcharacter.m_AnimSelectType= cfg.skill.AnimTypeSelectType.UI
        showcharacter:RegisterOnLoaded(function(go)
            if IsNull(showcharacter.m_Object)  then printyellow("no object??") return end
			plattransform.gameObject:SetActive(true)
            local trans         = showcharacter.m_Object.transform
            trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
			trans.transform.localScale = Vector3(tonumber(params[6]),tonumber(params[6]),tonumber(params[6]))
            trans.rotation = Quaternion.Euler(-90,0,0)
            ExtendedGameObject.SetLayerRecursively(showcharacter.m_Object, define.Layer.LayerUICharacter)
			trans.transform.localPosition = position
			sortorder.enabled = false
			sortorder.enabled = true
		    
        end)
        showcharacter:init(tempGetTalisman,PlayerRole:Instance(), -1)
	end
	
	-- g_bDebugEnable=(params[2]=="1")
end
RegisterClientCmd("/testTalisman",clientCmd_showtestTalisman)



return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    second_update   = second_update,
    destroy         = destroy,
    refresh         = refresh,
    uishowtype      = uishowtype,
    showresult      = showresult,
    ondlgdialogrefresh = ondlgdialogrefresh,
}
