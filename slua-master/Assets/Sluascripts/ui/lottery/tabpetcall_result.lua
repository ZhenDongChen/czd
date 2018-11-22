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

local  quality_ranks = {
	[cfg.item.EItemColor.PURPLE] = "Texture_Excellent",
	[cfg.item.EItemColor.ORANGE] = "Texture_Perfect",
	[cfg.item.EItemColor.RED] = "Texture_Peerless",
}


--模型加载
local function OnModelLoaded(go)
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

local function SetModelOffset(go,itemid)
	local modeloffset = ConfigManager.getConfigData("lotteryitemoffset",itemid)
	if modeloffset and go then
		go.transform.localPosition = Vector3(modeloffset.x,modeloffset.y,-2000)
		go.transform.localScale = Vector3(modeloffset.scale,modeloffset.scale,modeloffset.scale)
	else
		go.transform.localPosition = Vector3.zero
		go.transform.localScale = Vector3.one
	end
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
						plattransform.gameObject.transform.localPosition = Vector3(0,0,-2500)
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
				g_partnerCharacter =  Pet:new(0,PetID,0,true)
				g_partnerCharacter.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
				g_partnerCharacter:RegisterOnLoaded(function(go)
				if IsNull(g_partnerCharacter.m_Object)  then printyellow("no object??") return end
				plattransform.gameObject:SetActive(true)
				local trans         = g_partnerCharacter.m_Object.transform
				trans.parent        = plattransform.gameObject.transform:Find("zhaomu")
				trans.rotation = Quaternion.Euler(-90,0,0)
				SetModelOffset(trans,PetID)
				ExtendedGameObject.SetLayerRecursively(g_partnerCharacter.m_Object, define.Layer.LayerUICharacter)
				end)
				g_partnerCharacter:init()
			fields.UITexture_Rank:SetIconTexture(quality_ranks[pet.basiccolor])
			--g_partnerCharacter:CriticalLoadModel({modeldata})
			fields.UILabel_Reward.text = string.format(LocalString.ComposeResult,colorutil.GetQualityColorText(pet.basiccolor,pet.name))
        end
	
	if pickloadingEffectTransform ~= nil then
		pickloadingEffectTransform.gameObject:SetActive(false)
		pickloadingEffectTransform.gameObject:SetActive(true)
	end
	
end

local function init(params)
	 name, gameObject, fields    = unpack(params)
end



local function update()
	if g_partnerCharacter then
		g_partnerCharacter.m_Avatar:Update()
	end
end

local function show(PetID)
	ConformityLottery(PetID)
	EventHelper.SetClick(fields.UITexture_Background, function()
		uimanager.hidecurrentdialog()
	end)
	
	--TODO做背景UI的拉伸铺满全屏
	local Background = gameObject.transform:Find("Tween_Lottry/Frame/Panel/Background")
	if Background~=nil then
        local uiTex = Background.gameObject:GetComponent("UITexture")
        if uiTex~=nil then
            uimanager.SetUITextureFit(uiTex)
        end
    end

end

local function refresh()
	
end

local function destroy()

end

local function hide()
	if plattransform ~= nil then
		GameObject.Destroy(plattransform)
	end

	if g_partnerCharacter ~= nil then
		g_partnerCharacter:release()
		g_partnerCharacter = nil
	end
end



-----------------------------------------------------------------------------



return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    destroy         = destroy,
    refresh         = refresh,
    uishowtype      = uishowtype,
}
