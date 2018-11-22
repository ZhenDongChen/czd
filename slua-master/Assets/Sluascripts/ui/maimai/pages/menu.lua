local UIManager     = require("uimanager")
local MaimaiHelper  = require("ui.maimai.base.maimaihelper")
local MaimaiManager = require("ui.maimai.maimaimanager")
local TeamManager   = require("ui.team.teammanager")
local MarriageManager = require("marriage.marriagemanager")

local EventHelper 	= UIEventListenerHelper

local name, gameObject, fields


--{"查看圈子","查看","送花","组队","私聊","删除","离婚"}

local MenuItems = {
    [1] = { text    = LocalString.Maimai.Menu[1],
            action  = function(maimaiInfo, relation)
                        MaimaiManager.ShowMaimaiDialog(maimaiInfo:GetId())
                    end,},
    [2] = { text    = LocalString.Maimai.Menu[2],
            action  = function(maimaiInfo,relation)
                        UIManager.showdialog("otherplayer.dlgotherroledetails",{ roleId = maimaiInfo:GetId() })
                    end,},
    [3] = { text    = LocalString.Maimai.Menu[3],
            action  = function(maimaiInfo,relation)
                        UIManager.show("friend.dlgsendflower", { targetType = cfg.item.FlowerType.PLAYER, targetId = maimaiInfo:GetId() })
                    end,},
    [4] = { text    = LocalString.Maimai.Menu[4],
            action  = function(maimaiInfo,relation)
                        TeamManager.SendInviteJoinTeam(maimaiInfo:GetId())
                    end,},
    [5] = { text    = LocalString.Maimai.Menu[5],
            action  = function(maimaiInfo,relation)
                     --   printyellow("Private Chat",name)
                    --    UIManager.hidedialog("maimai.dlgmaimai")
                        UIManager.showdialog("chat.dlgchat01",{id = maimaiInfo:GetId(), name = maimaiInfo.m_Role.m_Name, index = 2})
                    end,},
    [6] = { text    = LocalString.Maimai.Menu[6],
            action  = function(maimaiInfo,relation)
                        if relation == cfg.friend.MaimaiRelationshipType.BanLvNan or relation == cfg.friend.MaimaiRelationshipType.BanLvNv then
                            MarriageManager.OpenDivorceWithDiscussDlg(maimaiInfo:GetId(),maimaiInfo.m_Role.m_Name)
                        else
                            MaimaiManager.DeleteMaimai(maimaiInfo:GetId(), relation)
                        end
                    end,},
    [7] = { text    = LocalString.Maimai.Menu[8],
            action  = function(maimaiInfo,relation)
                        TeamManager.SendGetPlayerLocation(maimaiInfo:GetId())
                        if UIManager.isshow("maimai.tabmaimai") then
                            UIManager.hidedialog("maimai.dlgmaimai")
                        end
                    end,},

    }




local function ResetMenuText(maimaiInfo,relation)
    local name = MaimaiHelper.GetRelationDeleteText(relation)
    MenuItems[6].text = name
end




local function ShowMenu(position, maimaiInfo, relation, mode)

    local menuCount
    if mode == "Player" then
        menuCount = #MenuItems
    else
        menuCount = #MenuItems -3
    end


    ResetMenuText(maimaiInfo,relation)

    fields.UIGroup_Menu.gameObject:SetActive(true)
    fields.UIGroup_Menu.gameObject.transform.position = Vector3(0,0,0)
    --fields.UIList_Menu.gameObject.transform.position = Vector3
    fields.UISprite_Background.gameObject.transform.position = position

    UIHelper.ResetItemNumberOfUIList(fields.UIList_Menu,menuCount)
    
    

    
    if mode == "Player" then
		for i = 1,menuCount do
			local menuUIItem = fields.UIList_Menu:GetItemByIndex(i-1)
			menuUIItem:SetText("UILabel_Text",MenuItems[i].text)

			local button = menuUIItem:GetComponent("UIButton")
			local action = MenuItems[i].action
			local text = MenuItems[i].text
			EventHelper.SetClick(button,function()
				--printyellow("action==============================")
				fields.UIGroup_Menu.gameObject:SetActive(false)
				action(maimaiInfo,relation)
			end)
		end
	else
		--脉脉中查看圈子的功能内点击所有的关系弹出的下拉框功能列表上只有4个功能按钮选项依次为“查看圈子”、“查看”、“组队”、“私聊”
		local tabIndex = {1,2,4,5}
		for i=1,menuCount do
			local menuUIItem = fields.UIList_Menu:GetItemByIndex(i-1)
			menuUIItem:SetText("UILabel_Text",MenuItems[tabIndex[i]].text)

			local button = menuUIItem:GetComponent("UIButton")
			local action = MenuItems[tabIndex[i]].action
			local text = MenuItems[tabIndex[i]].text
			EventHelper.SetClick(button,function()
				--printyellow("action==============================")
				fields.UIGroup_Menu.gameObject:SetActive(false)
				action(maimaiInfo,relation)
			end)
		end
	end


end




local function show(position, maimaiInfo, relation, mode,index)
    local positionY = 0
    if index >=4 and index <= 6  or index == 10 then 
        positionY =  0.42
    end
    if maimaiInfo:GetId() == PlayerRole:Instance().m_Id or relation == -1 then
        return
    end

    fields.UIGroup_Menu.gameObject:SetActive(true)
    ShowMenu(Vector3(position.x+0.22,position.y+positionY,position.z),maimaiInfo,relation, mode)
    EventHelper.SetClick(fields.UISprite_Back,function()
        --printyellow("hide==============================")
        fields.UIGroup_Menu.gameObject:SetActive(false)
    end)
end

local function hide()
    fields.UIGroup_Menu.gameObject:SetActive(false)
end

local function init(nameIn, gameObjectIn, fieldsIn)
    name, gameObject, fields = nameIn, gameObjectIn, fieldsIn
end

return {
    init = init,
    show = show,
    hide = hide,
}
