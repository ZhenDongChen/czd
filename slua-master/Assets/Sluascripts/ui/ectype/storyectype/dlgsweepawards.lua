local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ItemEnum = require("item.itemenum")
local ConfigManager = require "cfg.configmanager"
local ectypemanager = require "ectype.ectypemanager"
local LimitManager = require "limittimemanager"
local BonusManager = require("item.bonusmanager")
local network = require("network")
local DlgDialog = require "ui.dlgdialog"
local PlayerRole = require "character.playerrole"
local BagManager = require "character.bagmanager"
local TimeUtil = require "common.timeutils"
local ItemManager = require("item.itemmanager")
local StoryEctypeManager = require "ui.ectype.storyectype.storyectypemanager"
local BagManager       = require "character.bagmanager"
local EctypeDataManager = require "ui.ectype.storyectype.ectypedatamanager"
local EctypeDlgManager = require"ui.ectype.storyectype.ectypedlgmanager"

local name
local gameObject
local fields

local count = 1
local SweepReward = {}
local resNum = 0
local m_SectionData = {}
local m_ResetData = {}
local m_Num
local bonusYuanBao = 0 
local bonusExp = 0 
local isCanMultiSweep = false
local lastTime 
local sweeptimes 
local resNum_CanSweep 
local listeners 


local function NumToCharacter(num)
    if num == 1 then
        return "一"
    elseif num == 2 then
        return "二"
    elseif num == 3 then
        return "三"
    elseif num == 4 then
        return "四"
    elseif num == 5 then
        return "五"
    elseif num == 6 then
        return "六"
    elseif num == 7 then
        return "七"
    elseif num == 8 then
        return "八"
    elseif num == 9 then
        return "九"
    elseif num == 10 then
        return "十"
	elseif num == 11 then
		return "十一"
    elseif num == 12 then
		return "十二"
    elseif num == 13 then
		return "十三"
    elseif num == 14 then
		return "十四"
    elseif num == 15 then
		return "十五"
    else
		num = "零"
	end
end

local function update()
--	printyellow("sweep update")
	if isCanMultiSweep then
		if isSweepOver and (sweeptimes == 1 or TimeUtil.getTime() - lastTime >= 0.01 )then
--		if isSweepOver  then
			printyellow("sweeptimes",sweeptimes)
			isSweepOver = false
			ectypemanager.RequestSweepStoryEctype(m_SectionData.id)
		end 
	end 
end

local function hide(name)

end


local function refresh(params)

end

local function destroy()
end


local function GetSweepReward()
	return SweepReward

end

local function RePositionWhenNeeded()
	fields.UIScrollView_SweepCount:MoveRelative(Vector3(0, 200, 0))
end

local function RefreshBonus(msg)
	if msg  then
		local list_item = fields.UIList_SweepCount:AddListItem()
		list_item.Controls["UILabel_SweepCountNum"].text = "第" .. NumToCharacter(count) .."次"
		if count >= 3 then 	RePositionWhenNeeded() end 
		count = count + 1
		local list_award = list_item.Controls["UIList_SweepAward"]
		if msg.serverbonus then
			local bonuslist = BonusManager.GetItemsOfServerBonus(msg.serverbonus)
		    for key,item in pairs(bonuslist) do
				local item_award = list_award:AddListItem()
				item_award.Controls["UILabel_GainedAward"].text = item:GetName()
				BonusManager.SetRewardItem(item_award,item,params)
			end
		end

        bonusExp = bonusExp + msg.currency:GetNumber()			
		fields.UILabel_ExpGained.text = bonusExp 
		fields.UILabel_MoneyGained.text = 0

	end



	sweeptimes = sweeptimes + 1 
	lastTime = TimeUtil.getTime()
	if resNum_CanSweep and sweeptimes > resNum_CanSweep then isCanMultiSweep = false end 

	resNum = resNum - 1          
	if resNum == 0 then fields.UILabel_SweepOnce.text = "重置次数" end  
	isSweepOver = true 
end

local function Reset()
--	fields.UIList_SweepCount:Clear()
	count = 1
end

local function show(params)

	fields.UILabel_ExpGained.text = 0 
	fields.UILabel_MoneyGained.text = 0
	bonusExp = 0
	lastTime = TimeUtil.getTime()

	m_SectionData = params.SectionData
	m_Num = EctypeDataManager.GetUsedTimes(m_SectionData)
	m_ResetData  = ConfigManager.getConfig("storyconfig")
	sweeptimes = 1 
	resNum = m_SectionData.daylimit.num - m_Num
--          printyellow("resNum",m_SectionData.daylimit.num - m_Num )
	if params.multisweep then
		resNum_CanSweep = params.resNum_CanSweep

		isCanMultiSweep = true
		isSweepOver = true
		resNum = resNum_CanSweep
 	else
		ectypemanager.RequestSweepStoryEctype(m_SectionData.id)
--		resNum = resNum - 1
	end

	
--	printyellow("show sweep")
	if resNum == 0 then
		fields.UILabel_SweepOnce.text = "重置次数"
	end

	EventHelper.SetClick(fields.UIButton_SweepOnce,function()
--		printyellow("resNum",resNum)

		if EctypeDataManager.isNotEnoughTiLi(m_SectionData) then
			EctypeDlgManager.ShowReminderTiLi()
			return
		end

		if resNum == 0 then

			EctypeDlgManager.ShowReminder(m_SectionData)
			network.remove_listeners(listeners)
			UIManager.hide(name)
			return
		end

		ectypemanager.RequestSweepStoryEctype(m_SectionData.id)

	end)

	EventHelper.SetClick(fields.UIButton_SweepConfirm,function()
	    Reset()
--		if UIManager.isshow("ectype.storyectype.dlgsweepawards") then
		network.remove_listeners(listeners)
			UIManager.hide(name)
--		end 
	end)
end

local function onmsg_SSweepStoryEctype(msg)
--	printyellow("onmsg_SSweepStoryEctype")
	SweepReward.serverbonus = msg.bonus     
                                                  --服务器的奖励
	local ectypedrop = BonusManager.GetItemsOfSingleBonus(m_SectionData.ectypedrop) --通关奖励
	for _,item in pairs(ectypedrop) do
		if ItemManager.IsCurrency(item:GetConfigId()) then
			SweepReward.currency = item
		end 
	end 
--	printyellow("onmsg_SSweepStoryEctype SweepReward")
	if SweepReward then
		RefreshBonus(SweepReward)
	end
                                          --剩余次数减1
	if UIManager.isshow("ectype.dlgstorydungeonsub") then
		UIManager.call("ectype.dlgstorydungeonsub","RefreshTimes",m_SectionData)      --更新次数
		UIManager.call("ectype.dlgstorydungeonsub","RefreshRightButton",m_SectionData)--更新按钮
		UIManager.call("ectype.dlgstorydungeonsub","RefreshTiLi",m_SectionData)       --更新体力
	end

end

local function init(params)
    name, gameObject, fields = Unpack(params)

   listeners =  network.add_listeners({
        { "lx.gs.map.msg.SSweepStoryEctype",onmsg_SSweepStoryEctype},
    })
	

end

local function uishowtype()
    return UIShowType.DestroyWhenHide
end
return {
  uishowtype = uishowtype,
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  GetSweepReward = GetSweepReward,
  NumToCharacter = NumToCharacter,
}
