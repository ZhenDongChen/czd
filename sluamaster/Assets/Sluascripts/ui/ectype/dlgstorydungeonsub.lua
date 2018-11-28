local Unpack = unpack
local tonumber = tonumber
local EventHelper = UIEventListenerHelper
local String = string
local uimanager = require("uimanager")
local ItemEnum = require("item.itemenum")
local ConfigManager = require "cfg.configmanager"
local ectypemanager = require "ectype.ectypemanager"
local LimitManager = require "limittimemanager"
local BonusManager = require("item.bonusmanager")
local TeamManager = require("ui.team.teammanager")

local BagManager = require "character.bagmanager"
local ItemManager = require("item.itemmanager")
local MultiEctypeManager = require("ui.ectype.multiectype.multiectypemanager")

local PlayerRole = require "character.playerrole"
local StoryEctypeManager = require "ui.ectype.storyectype.storyectypemanager"
local CheckCmd = require("common.checkcmd")
local EctypeDataManager
local EctypeDlgManager
local listeners

local name
local gameObject
local fields
local count = 1
local m_Star_Num = 0
local cur_chapter

local Type={
    Story=1,
    Multi=2,
}
local m_SectionData  = {}
local m_BasicData    = {}
local m_ResetData    = {}

local SweepReward
local m_Num
local m_Signing=false
local StarInfo
local star_num = 0
local RewardList = {}

local function GetSectionData()
	return m_SectionData
end

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
    end
end

local function destroy()
end

local function SetSectionStars(num)--设置当前选中章节的星的个数
	local index
	fields.UIList_Star:Clear()

	for index = 1, num do
		fields.UIList_Star:AddListItem()
	end
	for index = num + 1, 3 do
		local listItem = fields.UIList_Star:AddListItem()
		listItem.Controls["UISprite_Star01"].gameObject:SetActive(false)
	end
end

local function SetStars(list,num)  --设置左边每一小节的三星个数
	list:Clear()
	local index
	for  index = 1, num do
		list:AddListItem()
	end
	for  index = num + 1 ,3 do
		local listItem = list:AddListItem()
		listItem.Controls["UISprite_Star01"].gameObject:SetActive(false)
	end

end
--显示三星条件
local function Show3StarConditionInfo(dlgfields,name,params)

	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Revive.gameObject:SetActive(false)
    dlgfields.UILabel_Content_Single1.gameObject:SetActive(true)
    dlgfields.UILabel_Content_Single2.gameObject:SetActive(true)
    dlgfields.UILabel_Content_Single3.gameObject:SetActive(true)
	dlgfields.UILabel_Title.text = "获得三星条件"
	-- printt(m_SectionData["starcondition"])
    for k,v in pairs (m_SectionData["starcondition"]) do --三星列表条件（3个条件）
        local str = string.format(v.description ,v.value)
        if v.condition == cfg.ectype.StarCondition.CLEAR then
            dlgfields.UILabel_Content_Single1.text = str
        elseif v.condition == cfg.ectype.StarCondition.DEAD_TIMES_LOWER_THAN then
            dlgfields.UILabel_Content_Single2.text = str
        elseif v.condition == cfg.ectype.StarCondition.CLEAR_IN_SECONDS then
            dlgfields.UILabel_Content_Single3.text = str
        end
    end

end

local function Display3StarCondition()

	uimanager.show("common.dlgdialogbox_common",{type = 7,callBackFunc = Show3StarConditionInfo})


end

local function DisplayStoryDesc(params)
    if params then
        if params.name then
            fields.UILabel_StoryNum.text = params.name
        end
        if params.desc then
            fields.UILabel_StoryDes.text = params.desc
        end
        if params.texture then
            fields.UITexture_Ectype:SetIconTexture(params.texture)
        end
    end
end

local function DisplayBonus()
--	printyellow("BonusManager",BonusManager)
--	printyellow("BonusManager",BonusManager.GetItemsByBonusConfig(m_SectionData.starbonus))
    local firstStarItems=BonusManager.GetItemsByBonusConfig(m_SectionData.starbonus)

    for _,item in pairs(firstStarItems) do
        if (item:GetDetailType()==ItemEnum.ItemType.Currency) then
            local currencyType = item:GetCurrencyType()
            BonusManager.SetCurrencyIcon(currencyType,fields.UISprite_RewardsType)
            fields.UILabel_RewardsNum.text = item:GetNumber()
        end
    end
    fields.UIList_SweepAwards:Clear()
    local passItems=BonusManager.GetItemsByBonusConfig(m_SectionData.ectypedrop)
    for _,item in pairs(passItems) do
        local listItem=fields.UIList_SweepAwards:AddListItem()
		local params = {}
		params.notShowAmount = true
        BonusManager.SetRewardItem(listItem,item,params)
    end
end

local function getStarInfo(params)
	StarInfo = params.starinfo
end

local function RefreshRedDot(SectionData)
	for i = 1, (fields.UIList_Level.Count) do
		local item = fields.UIList_Level:GetItemByIndex(i-1)
		if item and item.Data and SectionData.id == item.Data.id then
			local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE,item.Data.id) --挑战次数
			local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
			if item.Data.daylimit.num > m_Num then
				item.Controls["UISprite_Tip"].gameObject:SetActive(true)
			else
				item.Controls["UISprite_Tip"].gameObject:SetActive(false)
			end
			break
		end
	end
end

local function RefreshTimes(SectionData)
--	printyellow("RefreshTimes")
    local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE,SectionData.id)
    local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
--	printyellow("m_Num",m_Num)
    fields.UILabel_SweepedNum.text = (SectionData.daylimit.num  - m_Num) .. "/" .. SectionData.daylimit.num
	fields.UILabel_SweepMultiTime.text = String.format(LocalString.Ectype_Sweep,SectionData.daylimit.num  - m_Num) --N次扫荡次数显示
	RefreshRedDot(SectionData)
end

local function RefreshTiLi(SectionData)
	if EctypeDataManager.isNotEnoughTiLi(SectionData) == true then                    --体力
		fields.UILabel_StaminaNum.text= "[E9090D]" .. SectionData.costtili.amount or 0 ..LocalString.Ectype_Dot
	else
		fields.UILabel_StaminaNum.text= (SectionData.costtili.amount or 0)..LocalString.Ectype_Dot
    end
end

local function SignUp()
    if MultiEctypeManager.IsSigning() then
        fields.UIGroup_Button2.gameObject:SetActive(false)
        fields.UIGroup_Button3.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Cancel,function()
            uimanager.ShowAlertDlg({immediate = true,content=LocalString.MultiEctype_CancelSignTip,callBackFunc=function()
                    TeamManager.SendQuitTeam()
                end
            })
        end)
    else
        fields.UIGroup_Button2.gameObject:SetActive(true)
        fields.UIGroup_Button3.gameObject:SetActive(false)
        EventHelper.SetClick(fields.UIButton_Single,function()
            if (TeamManager.IsInTeam()) then
                uimanager.ShowAlertDlg({immediate = true,content=LocalString.MultiEctype_TeamSignTip,callBackFunc=function()
                    TeamManager.SendQuitTeam()
                    end
                })
            else
            end
        end)
        EventHelper.SetClick(fields.UIButton_Team,function()
            if (TeamManager.IsInTeam()) then
                if TeamManager.IsLeader() then
                else
                    uimanager.ShowSingleAlertDlg({content=LocalString.MultiEctype_NotLeader})
                end
            else
                uimanager.ShowSingleAlertDlg({content=LocalString.MultiEctype_SingleSignTip})
            end
        end)
    end
end


local function ShowSweepButton(dlgfields)            --显示两个扫荡按钮
	dlgfields.UIGroup_Revive.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	--printyellow("UILabel_Resurrection",dlgfields.UILabel_Resurrection)
	dlgfields.UILabel_Resurrection.gameObject:SetActive(false)
	dlgfields.UILabel_AutoStwpResurrection.gameObject:SetActive(false)
	dlgfields.UILabel_Props.gameObject:SetActive(false)
	dlgfields.UILabel_Money.gameObject:SetActive(false)
	dlgfields.UILabel_Times.text = "多次扫荡仅对VIP4及以上玩家开放"
	dlgfields.UILabel_Title.text = "提示"

	dlgfields.UILabel_SituResurrection.text = "扫荡1次"

    local m_Num = EctypeDataManager.GetUsedTimes(m_SectionData)
    local resNum = m_SectionData.daylimit.num - m_Num                   --剩余次数
    dlgfields.UILabel_StwpResurrection.text = "扫荡".. resNum .."次"

	EventHelper.SetClick(dlgfields.UIButton_SituResurrection, function() --扫荡按钮

		uimanager.hide(name)
		uimanager.hide("common.dlgdialogbox_common")
		uimanager.show("ectype.storyectype.dlgsweepawards",{SectionData = m_SectionData})

	end)

	EventHelper.SetClick(dlgfields.UIButton_StwpResurrection, function()
        if EctypeDataManager.isNotEnoughMultiTiLi(resNum,m_SectionData) then
			EctypeDlgManager.ShowReminderTiLi()
			uimanager.hide(name)
			uimanager.hide("common.dlgdialogbox_common")
			return
		end
		uimanager.hide(name)
		uimanager.hide("common.dlgdialogbox_common")
		uimanager.show("ectype.storyEctype.dlgsweepawards",{SectionData = m_SectionData,multisweep = true})

	end)

end



local function ShowSweepReward(params,dlgfields)
	local msg = SweepAwardsManager.GetSweepReward()
	dlgfields.UILabel_Title.text = "扫荡完成"
	dlgfields.UIGroup_RewardList.gameObject:SetActive(true)
    dlgfields.UIGroup_ItemShow.gameObject:SetActive(false)
	RefreshBonus(dlgfields,msg)
end

local function DisplayOneReward(rewardItem,reward)
	printyellow("display one reward fffffffffffffffffffffffffffffffffffff")
--	printt(reward)
	print(rewardItem.gameObject.transform.name)
	
	rewardItem.Controls["UITexture_Icon"]:SetIconTexture(reward:GetTextureName())
	rewardItem:SetText("UILabel_ItemIntroduce",reward:GetNumber())
	rewardItem:SetText("UILabel_ItemName",reward:GetName())
	rewardItem.gameObject:SetActive(true)
end

local function OnItemInit(go,wrapIndex,realIndex)
	--printyellow("》》》》》》》》》》OnItemInit go =>",go,"wrapIndex=>",wrapIndex,"realIndex=>",realIndex)
	if go == nil then
		return
	end
	local num = #RewardList --改
--	printyellow(">>>>>>",#RewardList)
	
	local UIListItem=go.gameObject:GetComponent(UIListItem)
	UIListItem.Controls["UISprite_Fragment"].gameObject:SetActive(false)
	UIListItem.Controls["UISprite_Binding"].gameObject:SetActive(false)
	UIListItem.Controls["UILabel_Amount"].gameObject:SetActive(false)
	UIListItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
	local UIGroup = UIListItem.Controls["UIGroup_All"]

	if (-realIndex+1) > num or (-realIndex+1)<1 then
        UIGroup.gameObject:SetActive(false)
    else
        UIGroup.gameObject:SetActive(true)

        if realIndex<0 then
            realIndex=-realIndex
        end
        local infoIndex=realIndex+1
         reward=RewardList[infoIndex]

        if UIListItem then
            DisplayOneReward(UIListItem,reward)
        end
    end
end

local function InitList(dlgfields,num)
    local wrapContent=dlgfields.UIList_ItemShow.gameObject:GetComponent(UIWrapContent)
	--printyellow(">>>>>>>>>>>>>InitList")
    if wrapContent==nil then
        return
    end
    wrapContent.itemSize=128
    wrapContent.minIndex=-num
    wrapContent.maxIndex=0
    EventHelper.SetWrapContentItemInit(wrapContent,OnItemInit)
    wrapContent.enabled=true

end





local function ShowBoxReward(params,dlgfields)
--	printyellow("ShowBoxReward")
--	printt(params.chapterinfo)
	dlgfields.UIGroup_ItemShow.gameObject:SetActive(true)

	local cur_chapter = params.chapterinfo[1].chapter
	local box_no = params.boxnumber    --Index是box的序号
	local Award = StoryEctypeManager.GetRewardListByBoxNo(cur_chapter,box_no)
--	printyellow("GetRewardListByBoxNo(cur_chapter,box_no)")
--	printt(Award)
	if Award then
		--RewardList = Award.award.bonuss
		RewardList = BonusManager.GetItemsOfSingleBonus(Award.award)
	end

	
	if #RewardList ~= 0 then
		InitList(dlgfields,#RewardList)
	end
	dlgfields.UILabel_Title.text = String.format(LocalString.Reward_Require_Star,StoryEctypeManager.GetRequireStarByBoxNo(cur_chapter,box_no) )
	dlgfields.UIList_Button:Clear()
	--printyellow("GetTotalStarsByChapterId(cur_chapter)",GetTotalStarsByChapterId(cur_chapter))
--	printyellow("GetRequireStarByBoxNo(cur_chapter,box_no)",GetRequireStarByBoxNo(cur_chapter,box_no))
	if StoryEctypeManager.GetTotalStarsByChapterId(cur_chapter) < StoryEctypeManager.GetRequireStarByBoxNo(cur_chapter,box_no) then
		--dlgfields.UIList_Button.gameObject:SetActive(false) --星数不够，领取按钮“变灰”
		local button_item = dlgfields.UIList_Button:AddListItem()
		local button_name = button_item.Controls["UILabel_ButtonName"]
		local btn = button_name.gameObject:GetComponent(UILabel)
		btn.text = LocalString.Task_GetReward
		UITools.SetButtonEnabled(button_item.gameObject:GetComponent(UIButton),false)

	else
		local button_item = dlgfields.UIList_Button:AddListItem()
		local button_name = button_item.Controls["UILabel_ButtonName"]
		local btn = button_name.gameObject:GetComponent(UILabel)
		local obtainRewardMatrix = StoryEctypeManager.GetObtainRewardMatrix()
		if obtainRewardMatrix[cur_chapter] and obtainRewardMatrix[cur_chapter][Award.awardid] then --rewardid 和箱子的id 是一样的
			btn.text = LocalString.DlgAchievement_StateName[2]
			UITools.SetButtonEnabled(button_item.gameObject:GetComponent(UIButton),false)
		else
			btn.text = LocalString.Task_GetReward
		end
		EventHelper.SetClick(button_item ,function () --单击领取按钮
			StoryEctypeManager.SendCObtainChapterReward({chapterid = cur_chapter,rewardindex = Award.awardid})
		end)
	end
end


local function DisplayOneSection(section)
--	printyellow("DisplayOneSection")
--	printt(section)
	fields.UILabel_RecommendedFCNum.text = section.battlepower or 0        --推荐战力

	if tonumber(fields.UILabel_RecommendedFCNum.text) > PlayerRole:Instance().m_Power then
--		fields.UILabel_MyFC.tint = Vector4(255,255,255,255)
		fields.UILabel_MyFC.text = colorutil.GetColorStr(colorutil.ColorType.Red,"(" ..PlayerRole:Instance().m_Power ..")")
	else
		fields.UILabel_MyFC.text = colorutil.GetColorStr(colorutil.ColorType.Green,"(" ..PlayerRole:Instance().m_Power ..")")
	end

	local bonuslist = BonusManager.GetItemsByBonusConfig(section.starbonus)
	fields.UILabel_RewardsNum.text = bonuslist[1]:GetNumber() or 0               --三星奖励


	if EctypeDataManager.isNotEnoughTiLi(section) == true then                    --体力
		fields.UILabel_StaminaNum.text= "[E9090D]" .. section.costtili.amount or 0 ..LocalString.Ectype_Dot
	else
		fields.UILabel_StaminaNum.text= (section.costtili.amount or 0)..LocalString.Ectype_Dot
    end
--	printyellow("rule ruler")

	local droplist = section.showitems --通关奖励
	fields.UIList_SweepAwards:Clear()
	for k,itemid in pairs (droplist) do
		local list_item = fields.UIList_SweepAwards:AddListItem()
		local params = {}
		params.notShowAmount = true
		BonusManager.SetRewardItem(list_item,ItemManager.CreateItemBaseById(itemid),params)
	end

	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE,section.id) --挑战次数
    local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
    fields.UILabel_SweepedNum.text = (section.daylimit.num  - m_Num) .. "/" .. section.daylimit.num

	fields.UITexture_Ectype:SetIconTexture(section.bgmpic) --背景图片
	fields.UILabel_StoryDungeonName.text = section.storyname--章节名字
	fields.UILabel_StoryDes.text = section.introduction     --章节介绍

	local starmatrix = StoryEctypeManager.GetStarMatrix()
	local num = 0
	if  starmatrix and  starmatrix[section.chapter] and starmatrix[section.chapter][section.section]then	-- 章节星的个数
		num = starmatrix[section.chapter][section.section]
	end
--	printt(starmatrix)
--	printyellow("SetSectionStars num",num)
	SetSectionStars(num)

end

local function RefreshRightButton(section)

		local starmatrix = StoryEctypeManager.GetStarMatrix()
		local Star_Num  = 0                 --当前章节所获得的星数
		if  starmatrix and  starmatrix[section.chapter] and starmatrix[section.chapter][section.section] then
			Star_Num = starmatrix[section.chapter][section.section]
		end
		local Used_Num  = EctypeDataManager.GetUsedTimes(section)  -- 当日已完成次数
		local Rest_Num  = section.daylimit.num - Used_Num          -- 剩余次数
		fields.UILabel_SweepMultiTime.text = String.format(LocalString.Ectype_Sweep,Rest_Num) --N次扫荡次数显示
        EventHelper.SetClick(fields.UIButton_Challenge, function() -- 单击“挑战”按钮，发送协议

			if PlayerRole:Instance().m_Level < section.openlevel.level then
				uimanager.ShowSystemFlyText(string.format(LocalString.Ectype_levelisnotenough,section.openlevel.level))
				return
			end

			if EctypeDataManager.isNotEnoughTiLi(section) then
				EctypeDlgManager.ShowReminderTiLi()
				return
			end

			if section.daylimit.num  - Used_Num > 0 then
				ectypemanager.RequestEnterEctype(section.id)
			else
				EctypeDlgManager.ShowReminder(section)
			end
        end)

        EventHelper.SetClick(fields.UIButton_Sweep, function()

           	if Star_Num < 3 then    --不足三星
				uimanager.ShowSystemFlyText(LocalString.Ectype_LessThanThreeStar)
				return
			end

			if EctypeDataManager.isNotEnoughTiLi(section) then

				EctypeDlgManager.ShowReminderTiLi()
				return
			end

			if section.daylimit.num  - Used_Num > 0 then
				--uimanager.hide(name)
				uimanager.show("ectype.storyectype.dlgsweepawards",{SectionData = section})
				--RefreshTimes(section)
			else

				EctypeDlgManager.ShowReminder(section)
			end
        end)

		EventHelper.SetClick(fields.UIButton_SweepSixTime, function()   --扫荡多次
			local resNum_CanSweep = EctypeDataManager.GetMaxResNumCanSweep(section)
--			printyellow("resNum_CanSweep",resNum_CanSweep)
			if Star_Num < 3 then    --不足三星
				uimanager.ShowSystemFlyText(LocalString.Ectype_LessThanThreeStar)
				return
			end

			if EctypeDataManager.isNotEnoughTiLi(section) then -- 扫一次也体力不够
				EctypeDlgManager.ShowReminderTiLi()
				return
			end

			if Rest_Num == 0 then   --剩余次数为0
				EctypeDlgManager.ShowReminder(section)
				return
			end

--			if EctypeDataManager.isNotEnoughMultiTiLi(Rest_Num,section) then
--				EctypeDlgManager.ShowReminderTiLi()
--				--uimanager.hide(name)
--				return
--			end
			--uimanager.hide(name)
			if resNum_CanSweep > Rest_Num then resNum_CanSweep = Rest_Num end
				uimanager.show("ectype.storyEctype.dlgsweepawards",{SectionData = section,multisweep = true,resNum_CanSweep = resNum_CanSweep})

--RefreshTimes(section)

		end)


end






local function refresh(params)


end



local function GetCurProgressLength(totalLength ,num,totalNum)
	return totalLength * (num/totalNum)
end

local function RefreshStarsProgress(params)
	local ChapterInfo = params.chapterdata
	local totalNumOfStars  = #ChapterInfo * 3 	  -- 当前章节星星总数

	local curNumOfStars    = StoryEctypeManager.GetTotalStarsByChapterId(ChapterInfo[1].chapter)										-- 当前章星星数


    fields.UIList_StarAmount.gameObject:GetComponent(UILabel).text = curNumOfStars .. "/" .. totalNumOfStars


	fields.UISlider_Star.gameObject:GetComponent(UISlider).value = curNumOfStars/totalNumOfStars

end

local function SetBoxGray(box_no)
	local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
	if box_no == 1 then
		
		--listItem.Controls["UITexture_Chapter"].shader= inactiveShader
		fields.UITexture_Normal_1.shader = inactiveShader
		--fields.UITexture_Grey_1.gameObject:SetActive(true)
	elseif box_no == 2 then
		fields.UITexture_Normal_2.shader = inactiveShader
		--fields.UITexture_Grey_2.gameObject:SetActive(true)
	elseif box_no == 3 then
		fields.UITexture_Normal_3.shader = inactiveShader
		--fields.UITexture_Grey_3.gameObject:SetActive(true)
	else
	end

end



local function RefreshBoxEffect(params)
	local cur_chapter = params.cur_chapter
	if not cur_chapter then return end
	local a1 = StoryEctypeManager.HasEnoughStarNum(cur_chapter,1) 
	local a2 = StoryEctypeManager.HasEnoughStarNum(cur_chapter,2)
	local a3 = StoryEctypeManager.HasEnoughStarNum(cur_chapter,3)
	local b1 = StoryEctypeManager.HasObtainedReward(cur_chapter,1)
	local b2 = StoryEctypeManager.HasObtainedReward(cur_chapter,2)
	local b3 = StoryEctypeManager.HasObtainedReward(cur_chapter,3)
	if b1 then SetBoxGray(1) end
	if b2 then SetBoxGray(2) end
	if b3 then SetBoxGray(3) end
	fields.UITexture_01.transform:Find("UITexture_Normal_1/UIGroup_Tween_Play_01").gameObject:SetActive(a1 and not b1)
	fields.UITexture_02.transform:Find("UITexture_Normal_2/UIGroup_Tween_Play_02").gameObject:SetActive(a2 and not b2)
	fields.UITexture_03.transform:Find("UITexture_Normal_3/UIGroup_Tween_Play_03").gameObject:SetActive(a3 and not b3)
end

local function RefreshRewardBox(params)
	local ChapterInfo = params.chapterdata


	fields.UITexture_01.transform:Find("UILabel_StarNum").gameObject:GetComponent(UILabel).text = StoryEctypeManager.GetRequireStarByBoxNo(ChapterInfo[1].chapter,1)
	fields.UITexture_02.transform:Find("UILabel_StarNum").gameObject:GetComponent(UILabel).text = StoryEctypeManager.GetRequireStarByBoxNo(ChapterInfo[1].chapter,2)
	fields.UITexture_03.transform:Find("UILabel_StarNum").gameObject:GetComponent(UILabel).text = StoryEctypeManager.GetRequireStarByBoxNo(ChapterInfo[1].chapter,3)



	EventHelper.SetClick(fields.UITexture_01,function()  --第一个宝箱

		uimanager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = ShowBoxReward,chapterinfo = ChapterInfo,boxnumber = 1})
	end)

	EventHelper.SetClick(fields.UITexture_02,function()  --第二个宝箱

		uimanager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = ShowBoxReward,chapterinfo = ChapterInfo,boxnumber = 2})
	end)

	EventHelper.SetClick(fields.UITexture_03,function()  --第三个宝箱

		uimanager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = ShowBoxReward,chapterinfo = ChapterInfo,boxnumber = 3})
	end)

end

local function Refresh3StarCondition(section)
end

local function DisplayAllSections(params)
	local ChapterInfo = params.chapterdata

	fields.UIList_Level:Clear()
	for key,section in pairs (ChapterInfo) do
--		if not next(section)  then return end 
		local listItem = fields.UIList_Level:AddListItem()

		listItem.Controls["UILabel_Theme"].text = section.chapter .."-"..key.." " .. section.storyname --关卡的名字
		if section.storybossicon then
			listItem.Controls["UISprite_ChallengeIcon"].gameObject:SetActive(false)														   --是否是BOSS本
		else
			listItem.Controls["UISprite_BOSSIcon"].gameObject:SetActive(false)
		end
		local liststar = listItem.Controls["UIList_Star"]
		local starmatrix = StoryEctypeManager.GetStarMatrix()
		local num = 0
		if  starmatrix and  starmatrix[section.chapter] and starmatrix[section.chapter][key]then
			num = starmatrix[section.chapter][key]
		end
		SetStars(liststar,num)
		listItem.Data = section
		RefreshRedDot(section)
		EventHelper.SetClick(listItem,function()
			m_SectionData = section
			DisplayOneSection(section)
			RefreshRightButton(section)
		end)
	end


end

local function DisPlayChapterName()
	local chapterdata = ConfigManager.getConfig("chapter")
--	printyellow("DisPlayChapterName()")
--	printt(chapterdata)
	fields.UILabel_ChapterName.text = chapterdata[cur_chapter].chaptername
end

local function show(params)
	--printyellow("show GetMaxViPLevel",GetMaxVIPLevel())
	cur_chapter = params.chapterdata[1].chapter
	StoryEctypeManager.SetCurChapter(cur_chapter)
	local item = {}
	item.cur_chapter = cur_chapter
	RefreshBoxEffect(item)
	DisPlayChapterName()
	m_SectionData = params.chapterdata[1]
	DisplayOneSection(params.chapterdata[1])
	RefreshRightButton(params.chapterdata[1])
	DisplayAllSections(params)
	RefreshStarsProgress(params)
	RefreshRewardBox(params)

	EventHelper.SetClick(fields.UIButton_3StarsCondition,function()
		Display3StarCondition()
	end)
end

local function hide()
--	printyellow("hide dlgstorydungeonsub")

--	uimanager.call("ectype.tabstorydungeon","DisPlayAllChapter")
end



local function update()
end





local function init(params)
    name, gameObject, fields = Unpack(params)
	EctypeDataManager = require "ui.ectype.storyectype.ectypedatamanager"
    EctypeDlgManager = require"ui.ectype.storyectype.ectypedlgmanager"


	--fields.UIGroup_Left.gameObject:SetActive(true)
    --fields.UIGroup_LeftMatchedTeam.gameObject:SetActive(false)



--    EventHelper.SetClick(fields.UISprite_MainBlack,function()
--        uimanager.hidedialog(name)
--    end)

--	EventHelper.SetClick(fields.UIButton_Close,function()
--		--printyellow("Close")
--        uimanager.hide(name)
--    end)
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
	GetSectionData = GetSectionData,
	RefreshRedDot    = RefreshRedDot,
	RefreshTimes = RefreshTimes,
	RefreshRightButton = RefreshRightButton,
	RefreshTiLi = RefreshTiLi,
	RefreshBoxEffect = RefreshBoxEffect,
}
