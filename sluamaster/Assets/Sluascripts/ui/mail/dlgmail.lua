local Unpack = unpack
local String = string
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local NetWork = require("network")
local MailManager = require("ui.mail.mailmanager")
local ConfigManager = require("cfg.configmanager")
local ItemManager = require("item.itemmanager")
local BonusManager = require("item.bonusmanager")

local m_GameObject
local m_Name
local m_Fields
local m_MailIds = {}
local m_CurSelectedMailId = -1
local m_Mails = {}
local m_TotalNum = 0
local m_Patterns = {"http://[A-Za-z0-9%.%/%-%?_]*",
                    "https://[A-Za-z0-9%.%/%-%?_]*",
                    "ftp://[A-Za-z0-9%.%/%-%?_]*"}
                    
local m_Currencys = {
    10200001,
    10200003,
    10200005,
}

local itemState = false 

local function destroy()
end

local function show(params)
end

local function hide()
end

local function GetMailMode(mailId)
    local mailModel = ConfigManager.getConfigData("mail",mailId)
    return mailModel
end

local function GetSender(mail)
    local sender = ""
    if mail.sender == nil or mail.sender == "" then
        local mailModel = GetMailMode(mail.mailid)
        if mailModel ~= nil and mailModel.sender ~= nil then
            if mailModel.sender == cfg.mail.SenderType.SYSTEM then
                sender = LocalString.Mail_System
            elseif mailModel.sender == cfg.mail.SenderType.FAMILY then
                sender = LocalString.Mail_FamilyHead
            end
        end
    else
        sender = mail.sender
    end
    return sender
end

local function GetTitle(mail)
    local title = ""
    if mail.title == nil or mail.title == "" then
        local mailModel = GetMailMode(mail.mailid)
        if mailModel ~= nil and mailModel.title ~= nil then
            title = mailModel.title
        end
    else
        title = mail.title
    end
    return title
end

local function Convert(mailContent)
    local result = mailContent
    local function Convert(value) return "[url=" .. value .. "][436EEE]" .. value .. "[-][/url]" end
    for _,pattern in pairs(m_Patterns) do
        result = String.gsub(result,pattern,Convert)
    end
    return result
end

local function GetContent(mail)
    local content = ""
    if mail.content == nil or mail.content == "" then
        local mailModel = GetMailMode(mail.mailid)
        if mailModel ~= nil and mailModel.content ~= nil then
            local index = 0
            local result = String.gsub(mailModel.content, "{}", function() index = index + 1 return mail.params[index] or "" end)            
            content = result
        end
    else
        content=mail.content
    end
    content = Convert(content)
    return content
end

local function ClearDisplayMail()
    m_CurSelectedMailId = -1
    m_Fields.UILabel_Name.text = ""
    m_Fields.UILabel_Title.text = ""
    m_Fields.UILabel_Contents.text = ""
    m_Fields.UILabel_EXP.text = 0
    m_Fields.UILabel_Gold.text = 0
    m_Fields.UILabel_Ingot.text = 0
    m_Fields.UIList_Icon:Clear()
    m_Fields.UIGroup_Reward.gameObject:SetActive(false)
end

local function IsSpecialDisplay(id)
    local result = false
    for _,itemId in pairs(m_Currencys) do
        if itemId == id then
            result = true
            break
        end
    end
    return result
end

local function OnDisplayOneMail(mail)
    ClearDisplayMail()
    m_CurSelectedMailId = mail.id
    local UILabel_Name = m_Fields.UILabel_Name
    local sender = GetSender(mail)
    if sender then
        local text = ""
        if sender == LocalString.Mail_System then
            text = String.format(LocalString.Mail_Color[cfg.mail.SenderType.SYSTEM],sender)
        elseif sender == LocalString.Mail_FamilyHead then
            text = String.format(LocalString.Mail_Color[cfg.mail.SenderType.FAMILY],sender)
        end
        UILabel_Name.text = text
    end
    local UILabel_Title = m_Fields.UILabel_Title
    UILabel_Title.text = GetTitle(mail)
    local UILabel_Contents = m_Fields.UILabel_Contents
    UILabel_Contents.text = GetContent(mail)
    local currencys = mail.accessory.items
    if currencys then
        for key,value in pairs(currencys) do
			itemState = true
            if key == cfg.currency.CurrencyType.JingYan then
                m_Fields.UILabel_EXP.text = value
            elseif key == cfg.currency.CurrencyType.XuNiBi then
                m_Fields.UILabel_Gold.text = value              
            elseif key == cfg.currency.CurrencyType.BindYuanBao then
                m_Fields.UILabel_Ingot.text = value
            end
        end
    end
    local UIList_Icon = m_Fields.UIList_Icon
    local items = BonusManager.GetItemsOfServerBonus(mail.accessory)
    if items then          
        for key,value in pairs(items) do
            if IsSpecialDisplay(value:GetId()) == false then
                local UIListItem_Icon = UIList_Icon:AddListItem()
                BonusManager.SetRewardItem(UIListItem_Icon,value)   
            end                    
        end
    end   
    m_Fields.UIGroup_Reward.gameObject:SetActive(true)
    local UIButton_Extract = m_Fields.UIButton_Extract
    EventHelper.SetClick(UIButton_Extract,function()  
            local mailIds = {}
            mailIds[1] = mail.id          
            local msg = lx.gs.mail.msg.CObtainMailAccessory({mailids = mailIds})
            NetWork.send(msg)
    end)    
end

local function SetMailOpened(id)
    local UIList_Mail = m_Fields.UIList_Mail
    if UIList_Mail.Count > 0 then
        local UIListItem_Mail = UIList_Mail:GetItemById(id)
        if UIListItem_Mail then
        end
    end
end

local function DisplayOneMail(mailItem,mail)
    mailItem.Id = mail.id
    mailItem.Data = mail
    mailItem:SetText("UILabel_Addressor",mail.sender)
    local title = GetTitle(mail)
    mailItem:SetText("UILabel_Theme",title)
    local sendTime = os.date("%Y-%m-%d %H:%M:%S",(mail.sendtime / 1000))
    mailItem:SetText("UILabel_Date",sendTime)
    local UISprite_FamilyIcon = mailItem.Controls["UISprite_FamilyIcon"]
    local UISprite_CopyIcon = mailItem.Controls["UISprite_CopyIcon"]
    if mail.mtype == cfg.mail.SenderType.FAMILY then
        UISprite_FamilyIcon.gameObject:SetActive(true)
        UISprite_CopyIcon.gameObject:SetActive(false)
    elseif mail.mtype == cfg.mail.SenderType.SYSTEM then
        UISprite_FamilyIcon.gameObject:SetActive(false)
        UISprite_CopyIcon.gameObject:SetActive(true)
    end
    local UISprite_Effect = mailItem.Controls["UISprite_Effect"]
    if m_CurSelectedMailId == mail.id then
        UISprite_Effect.gameObject:SetActive(true)
    else
        UISprite_Effect.gameObject:SetActive(false)
    end
    EventHelper.SetClick(mailItem,function()     
        if mail.read == MailManager.OpenStatus.UnRead then              
            local msg = lx.gs.mail.msg.CReadMail({mailid = mail.id})
            NetWork.send(msg)
        end
        if m_CurSelectedMailId ~= mail.id then
            UISprite_Effect.gameObject:SetActive(true)
            for i = 0,(m_Fields.UIList_Mail.Count - 1) do
                local tempItem = m_Fields.UIList_Mail:GetItemByIndex(i)
                if tempItem and tempItem.Id == m_CurSelectedMailId then
                    local spriteEffect = tempItem.Controls["UISprite_Effect"]
                    spriteEffect.gameObject:SetActive(false)
                end
            end    
            OnDisplayOneMail(mail)
        end              
    end)
    local UIButton_Check = mailItem.Controls["UIButton_Check"]
    local UIToggle_Check = UIButton_Check.transform:GetComponent("UIToggle")
    local selected = false
    for i,id in pairs(m_MailIds) do
        if id == mail.id then
            UIToggle_Check.value = true
            selected=true
            break
        end
    end
    if selected == false then
        UIToggle_Check.value = false
    end
    EventHelper.SetClick(UIButton_Check,function()                                           
        if UIToggle_Check.value then  
            local has = false
            for i = 1,#m_MailIds do
                if m_MailIds[i] == mail.id then
                    has = true
                    break
                end
            end
            if not has then
                m_MailIds[#m_MailIds + 1] = mail.id
            end
        else                    
            for i = 1,#m_MailIds do
                if m_MailIds[i] == mail.id then
                    table.remove(m_MailIds,i)
                    break
                end
            end 
            local UIButton_SelectAll = m_Fields.UIButton_SelectAll
            local UIToggle_SelectAll = UIButton_SelectAll.transform:GetComponent("UIToggle")
            UIToggle_SelectAll.value = false
        end               
    end)
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem == nil then
        return
    end
    local mail = m_Mails[m_TotalNum - realIndex + 1]
    if UIListItem then
        DisplayOneMail(UIListItem,mail)
    end
end

local function InitList(num)
    local wrapList = m_Fields.UIList_Mail.gameObject:GetComponent("UIWrapContentList")
    if wrapList == nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-2.1)
end

local function refresh(params)
	itemState = false
    m_Mails = MailManager:GetMails()
    local UIList_Mail = m_Fields.UIList_Mail
    local UIButton_SelectAll = m_Fields.UIButton_SelectAll
    local UIToggle_SelectAll = UIButton_SelectAll.transform:GetComponent("UIToggle")
    if UIToggle_SelectAll.value then
        UIToggle_SelectAll.value = false
    end
    local UILabel_None = m_Fields.UILabel_None
    if m_Mails then       
        m_TotalNum = #m_Mails
        InitList(m_TotalNum)
        UILabel_None.gameObject:SetActive(false)
        if m_TotalNum == 0 then
            m_CurSelectedMailId = -1
            UILabel_None.gameObject:SetActive(true)   
        end  
    end
    if m_CurSelectedMailId ~= -1 then
        local hasDisplay = false
        for i=1,#m_Mails do
            if m_Mails[i].id == m_CurSelectedMailId then
                hasDisplay = true
                break
            end
        end 
        if not hasDisplay then
            if #m_Mails == 0 then
                ClearDisplayMail()
            else               
                local tempItem = m_Fields.UIList_Mail:GetItemByIndex(0)               
                if tempItem then
                    local spriteEffect = tempItem.Controls["UISprite_Effect"]
                    spriteEffect.gameObject:SetActive(true)
                    OnDisplayOneMail(tempItem.Data)
                end
                
            end
        end 
    else
        if #m_Mails > 0 then
            local tempItem = m_Fields.UIList_Mail:GetItemByIndex(0)            
            if tempItem then
                local spriteEffect = tempItem.Controls["UISprite_Effect"]
                spriteEffect.gameObject:SetActive(true)
                OnDisplayOneMail(tempItem.Data)
            end         
        else
            ClearDisplayMail()
        end           
    end
end

local function update()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)    
    EventHelper.SetClick(m_Fields.UIButton_BatchExtraction,function()  
        --获取选中的ids  
        if #m_MailIds > 0 then
            local msg = lx.gs.mail.msg.CObtainMailAccessory({mailids = m_MailIds})
            NetWork.send(msg) 
        else
            UIManager.ShowSingleAlertDlg({content = LocalString.Mail_NotChooseMail})       
        end
    end)
    EventHelper.SetClick(m_Fields.UIButton_BatchRemove,function()
        if #m_MailIds > 0 then
			if itemState then
				local params = {}
				params.immediate = true
				params.content = LocalString.Mail_AbandonUnTakenAttach
				params.callBackFunc = function()
					local msg = lx.gs.mail.msg.CDelMail({delmailids = m_MailIds})
					NetWork.send(msg)             
				end
				UIManager.ShowAlertDlg(params)
			else
				local msg = lx.gs.mail.msg.CDelMail({delmailids = m_MailIds})
				NetWork.send(msg)             
			end
        else           
            UIManager.ShowSingleAlertDlg({content=LocalString.Mail_NotChooseMail})
        end    
    end)   
    EventHelper.SetClick(m_Fields.UIButton_SelectAll,function() 
            local UIButton_SelectAll = m_Fields.UIButton_SelectAll
            local UIToggle_SelectAll = UIButton_SelectAll.transform:GetComponent("UIToggle")
            local UIList_Mail = m_Fields.UIList_Mail    
            local value = UIToggle_SelectAll.value        
            for i = 0,UIList_Mail.Count - 1 do
                local UIListItem_Mail = UIList_Mail:GetItemByIndex(i)
                local UIButton_Check = UIListItem_Mail.Controls["UIButton_Check"]
                local UIToggle_Check = UIButton_Check.transform:GetComponent("UIToggle")
                UIToggle_Check.value = value
            end
            m_MailIds = {}
            if value then
              local mails = MailManager:GetMails()
              for i = 1,#mails do
                m_MailIds[i] = mails[i].id
              end
            end
        end
    )
    local mails=MailManager:GetMails()    
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  SetMailOpened=SetMailOpened
}