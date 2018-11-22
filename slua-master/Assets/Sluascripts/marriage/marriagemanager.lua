local require = require
local unpack = unpack
local print = print
local network     = require("network")
local uimanager   = require("uimanager")
local BagManager  = require "character.bagmanager"
local ConfigManager = require("cfg.configmanager")
local ItemManager = require("item.itemmanager")
local BonusManager = require("item.bonusmanager")
local PlayerRole=require"character.playerrole"

local DialogType = enum
{
    "Propose = 1",
    "GetGift",
    "DivorceBook",
    "DivorceBookNotify",
}

local GiftsType = enum
{
    "Normal = 0",
    "Luxurious",
}

local ProposeRe = enum
{
    "Refuse = 0",
    "Agree",
}

local RoleInfoOpenUI = enum
{
    "None    = 0",
    "Propose",
    "Answer",
}

local m_selectedPlayerID
local m_selectedPlayerName
local m_coupleRoleID
local m_roleInfoOpenUI

local function CBuyXiushu()
    network.send(lx.gs.marriage.msg.CBuyXiushu(){})
end

local function CGetRoleInfo(roleId)
    network.send(lx.gs.role.msg.CGetRoleInfo({roleid = roleId}))
end

local function GetSelectedPlayerName()
    return m_selectedPlayerName
end

local function OpenProposeDlg() 
    --if not id then  return   end
    --m_selectedPlayerID = id
    --m_selectedPlayerName = name
    m_roleInfoOpenUI = RoleInfoOpenUI.Propose
    CGetRoleInfo(m_selectedPlayerID)   
    uimanager.showdialog("marriage.dlgmarriage",{uiType = DialogType.Propose, proposeName = m_selectedPlayerName})
end

local m_answerid
local m_answerName
local m_answerType
local m_answerOath
local function OpenProposeAnswerDlg(msg) 
    m_roleInfoOpenUI = RoleInfoOpenUI.Answer
    CGetRoleInfo(msg.proposeroleid)   
    m_answerid = msg.proposeroleid
    m_answerName = msg.proposerolename
    m_answerType = msg.proposetype
    m_answerOath = msg.proposeoath
    --[[uimanager.showdialog("marriage.dlgmarriageanswer",{
        proposeroleid = msg.proposeroleid, proposerolename = msg.proposerolename, 
        proposetype = msg.proposetype, proposeoath = msg.proposeoath})]]
end

local function OpenDivorceWithBookDlg()
    --if not id then  return   end
    --m_selectedPlayerID = id

    local marriageConfig = ConfigManager.getConfig("marrigeconfig")
    if BagManager.GetItemNumById(marriageConfig.divorceitemid) > 0 then
        uimanager.showdialog("marriage.dlgmarriage",{uiType = DialogType.DivorceBook, name = m_selectedPlayerName})
    else 
        uimanager.ShowAlertDlg({
            content      = string.format(LocalString.Marriage.DivorceBookBuy, marriageConfig.divorceprice.amount),
            sureText     = LocalString.Marriage.DivorceBookBuyButton,        
            callBackFunc = function()
                if PlayerRole:Instance():Ingot() < marriageConfig.divorceprice.amount then
                    ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,"dlgalert_reminderimportant")
                else
                    CBuyXiushu()
                end                
            end,
            immediate = true,
        })
    end
end

local function Release()
    m_selectedPlayerID = 0
    m_selectedPlayerName = ""
    m_coupleRoleID = 0
    m_roleInfoOpenUI = nil
end

local function IsMarriaged()
    if m_coupleRoleID == 0 then
        return false
    else
        return true
    end
end

local function GetCoupleRoleID()
    return m_coupleRoleID
end

local function SetCoupleRoleID(id)
    m_coupleRoleID = id
end

local function IsGiftsExist(giftType)
    local marriageConfig = ConfigManager.getConfig("marrigeconfig")
    local num = 0
    if giftType == GiftsType.Normal then
        num = BagManager.GetItemNumById(marriageConfig.marrigepack[1].marrigepackid)
    elseif giftType == GiftsType.Luxurious then
        num = BagManager.GetItemNumById(marriageConfig.marrigepack[2].marrigepackid)
    end

    if num > 0 then  
        return true
    else 
        return false
    end
end

local function EnableInputControlEdit( uiInput, bEnable)
    local collider = uiInput.gameObject:GetComponent("BoxCollider")
    if collider then
        collider.enabled = bEnable 
    end 
end

--*******************************************************************
local function CAttemptPropose(id, name)
    local marriageConfig = ConfigManager.getConfig("marrigeconfig")
    if PlayerRole.Instance().m_Level< marriageConfig.requirelevel then
        uimanager.ShowSystemFlyText(string.format(LocalString.Marriage.RequireLevel,marriageConfig.requirelevel))
    else
        m_selectedPlayerID = id
        m_selectedPlayerName = name
        network.send(lx.gs.marriage.msg.CAttemptPropose(){beproposedroleid=m_selectedPlayerID})
    end
    
end

local function CPropose(oath) --结婚请求
    if IsGiftsExist(GiftsType.Normal) then
        network.send(lx.gs.marriage.msg.CPropose(){beproposedroleid=m_selectedPlayerID, proposeoath = ""})
    elseif IsGiftsExist(GiftsType.Luxurious) then
        network.send(lx.gs.marriage.msg.CPropose(){beproposedroleid=m_selectedPlayerID, proposeoath = oath})
    else
        uimanager.ShowSystemFlyText(LocalString.Marriage.NoGift)
    end
    
end

local function CBeproposed(id, result, giftType, oath) --接受求婚
    network.send(lx.gs.marriage.msg.CBeproposed(){
        proposeroleid=id, proposeresult=result, proposetype = giftType, proposeoath = oath})
end

local function CDivorceWithBook(content) --ʹ����������������
    network.send(lx.gs.marriage.msg.CDivorceWithBook(){bedivorceroleid=m_coupleRoleID, bookcontent=content})
end

local function CDivorceWithDiscuss()  --������Э������
    network.send(lx.gs.marriage.msg.CDivorceWithDiscuss(){bedivorceroleid=m_coupleRoleID})
end

local function CBedivorceWithDiscuss(result) --�������ߵĴ�����Ϣ,0��ʾ�ܾ����飬1��ʾͬ������
    network.send(lx.gs.marriage.msg.CBedivorceWithDiscuss(){divorceroleid=m_coupleRoleID,divorceresult = result})
end

local function CBuyCaili(giftId) --�������ͣ�0��ʾ��ͨ��1��ʾ����
    network.send(lx.gs.marriage.msg.CBuyCaili(){cailitypeid = giftId})
end

local function CFriendWish(id, beid, type)
    network.send(lx.gs.marriage.msg.CFriendWish(){proposeroleid=id, beproposeroleid = beid, proposetype = type})
end

--*******************************************************************
local function onmsg_SMarriageInfo(msg)
    m_coupleRoleID = msg.coupleroleid
end

local function onmsg_SFriendWish(msg)
    local bonusItems = BonusManager.GetItemsOfServerBonus(msg.marrygift)
    local str = string.format(LocalString.Marriage.FriendWishMessage1,
        bonusItems[1]:GetNumber(),bonusItems[1]:GetName())
    uimanager.ShowSystemFlyText(str)
end

local function onmsg_SAttemptPropose(msg) --�ж��Ƿ�������������,�յ��ͱ�ʾ��������
    uimanager.hide("maimai.dlgmaimaicheckfriend")
    OpenProposeDlg()   
end

local function onmsg_SPropose(msg)  --��������,֪ͨ����˫��,0��ʾ����ʧ�ܣ�1��ʾ�����ɹ�   beproposedroleid��������id 
    if msg.beproposedroleid == PlayerRole.Instance().m_Id then --��������
        if msg.proposeresult == ProposeRe.Refuse then
            uimanager.ShowSystemFlyText(LocalString.Marriage.ProposeReRefusedFirst)
        else
            uimanager.ShowSystemFlyText(LocalString.Marriage.ProposeAgreeFirst)
            m_coupleRoleID = msg.proposeid
        end      
    else  --������
        if msg.proposeresult == ProposeRe.Refuse then
            uimanager.ShowSystemFlyText(LocalString.Marriage.ProposeReRefused)
        else
            uimanager.ShowSystemFlyText(LocalString.Marriage.ProposeAgree)
            m_coupleRoleID = msg.beproposedroleid
        end
    end 

    --���Ž�����Ч δ����
end

local function onmsg_SBeproposed(msg)  --�����߿�ʼ�����󣬷�����֪ͨ����������������������  ˫����֪ͨ  
    if msg.proposeroleid ~= PlayerRole.Instance().m_Id then --������id
        OpenProposeAnswerDlg(msg)
    else
        uimanager.hidedialog("marriage.dlgmarriage")
        uimanager.ShowSystemFlyText(LocalString.Marriage.ProposeDiscussSend)
    end 
end

local function onmsg_SBuyCaili(msg)  
end

local function onmsg_SBuyXiushu(msg)
    OpenDivorceWithBookDlg()
end

local function onmsg_SBedivorceWithDiscuss(msg)  --������֪ͨ��������, 0��ʾ�ܾ����飬1��ʾͬ������ ֪ͨ˫��
    if msg.divorceroleid ~= PlayerRole.Instance().m_Id then
        uimanager.ShowAlertDlg({
            content      = LocalString.Marriage.DivorceDiscussRe,
            sureText     = LocalString.Marriage.DivorceAgree,
            cancelText   = LocalString.Marriage.DivorceRefuse,         
            callBackFunc = function()
                CBedivorceWithDiscuss(ProposeRe.Agree)
            end,
            callBackFunc1 = function()
                CBedivorceWithDiscuss(ProposeRe.Refuse)
            end,
            immediate = true,
        })
    else
        uimanager.ShowSystemFlyText(LocalString.Marriage.DivorceDiscussSend) 
    end   
end

local function onmsg_SDivorceWithBook(msg)  --ʹ����������������
    uimanager.ShowSystemFlyText(string.format(LocalString.Marriage.DivorceDone,msg.bedivorcerolename)) 
    m_coupleRoleID = 0 
end

local function onmsg_SDivorceWithDiscuss(msg)  --Э�������Ľ���,0��ʾ����ʧ�ܣ�1��ʾ�����ɹ� ֪ͨ˫�� bedivorceroleid������������id
    if msg.bedivorceroleid == PlayerRole.Instance().m_Id then    --����������
        if msg.divorceresult == ProposeRe.Refuse then
            uimanager.ShowSystemFlyText(LocalString.Marriage.DivorceDiscussConfirm)
        else
            uimanager.ShowSystemFlyText(string.format(LocalString.Marriage.DivorceDone,LocalString.Marriage.DivorceDoneName))
            m_coupleRoleID = 0  
        end
       
    else  --����������   
        if msg.divorceresult == ProposeRe.Refuse then
            uimanager.ShowAlertDlg({
                content      = LocalString.Marriage.DivorceBook,      
                callBackFunc = function()
                    OpenDivorceWithBookDlg()
                end,
                immediate = true,
            })
        else
            uimanager.ShowSystemFlyText(string.format(LocalString.Marriage.DivorceDone,msg.bedivorcerolename))
            m_coupleRoleID = 0  
        end 
    end  
end

local function onmsg_SFriendMarryNotify(msg)  --֪ͨ˫�����к��ѽ�����Ϣ  
    if msg.proposeroleid ~= PlayerRole.Instance().m_Id and msg.beproposeroleid ~= PlayerRole.Instance().m_Id then
        local marriageConfig = ConfigManager.getConfig("marrigeconfig")
        local moneyInfo1 = 0
        --local moneyInfo2 = 0
        if msg.proposetype == GiftsType.Normal then
            moneyInfo1 = marriageConfig.giftcurrency[1].currencys[1]
            --moneyInfo2 = marriageConfig.giftcurrency[1].currencys[2]
        elseif msg.proposetype == GiftsType.Luxurious then
           moneyInfo1 = marriageConfig.giftcurrency[2].currencys[1]
            --moneyInfo2 = marriageConfig.giftcurrency[2].currencys[2]
       end
       uimanager.ShowAlertDlg({
           sureText     = LocalString.Marriage.FriendWishButton, 
           content      = string.format(LocalString.Marriage.FriendWishMessage,msg.proposename,msg.beproposedname,
                                    moneyInfo1.amount),
           callBackFunc = function()
               CFriendWish(msg.proposeroleid, msg.beproposeroleid, msg.proposetype)
           end,
           immediate = true,
       })

    end
end

local function onmsg_SFriendWishNotify(msg)  --����ף����֪ͨ����˫���õ���ף��
    local bonusItems = BonusManager.GetItemsOfServerBonus(msg.wishgift)
    local str = string.format(LocalString.Marriage.FriendWishMessage2,msg.friendname,
        bonusItems[1]:GetNumber(),bonusItems[1]:GetName(), bonusItems[2]:GetNumber(),bonusItems[2]:GetName())
    uimanager.ShowSystemFlyText(str)
end

local function onmsg_SAllSomePeopleMarryNotify(msg)  --֪ͨȫ�������˽���  
    local dlguimain = require"ui.dlguimain"  
    local oath = ""
    if not msg.content or msg.content == "" then
        oath = LocalString.Marriage.ProposeOath
    else
        oath = msg.content
    end  
    if msg.proposegender == cfg.role.GenderType.MALE then      
        if msg.beproposegender == cfg.role.GenderType.MALE then
            dlguimain.AddMarriageBroadcast(string.format(LocalString.Marriage.MarriageBroadcastManMan, 
                msg.proposename, msg.beproposedname, oath))
        else
            dlguimain.AddMarriageBroadcast(string.format(LocalString.Marriage.MarriageBroadcastManWoman, 
                msg.proposename, msg.beproposedname, oath))
        end       
    else   
        if msg.beproposegender == cfg.role.GenderType.MALE then
            dlguimain.AddMarriageBroadcast(string.format(LocalString.Marriage.MarriageBroadcastWomanMan,
                msg.proposename, msg.beproposedname, oath))
        else
            dlguimain.AddMarriageBroadcast(string.format(LocalString.Marriage.MarriageBroadcastWomanWoman,
                msg.proposename, msg.beproposedname, oath))
        end            
    end
end

local function onmsg_SBedivorcedNotify(msg)  --ʹ��������֪ͨ��������
    uimanager.showdialog("marriage.dlgmarriage",{uiType = DialogType.DivorceBookNotify, bookcontent = msg.bookcontent, 
        divorcerolename = msg.divorcerolename, time = msg.divorcetime})
    m_coupleRoleID = 0 
end

local function onmsg_SGetRoleInfo(msg) 
    if m_roleInfoOpenUI == RoleInfoOpenUI.None then return end

    if msg == nil or msg.roleid == nil or msg.roleinfo == nil then
        return
    end

    if m_roleInfoOpenUI == RoleInfoOpenUI.Propose then
        uimanager.showdialog("marriage.dlgmarriage",{uiType = DialogType.Propose, 
            proposeName = m_selectedPlayerName, roleInfo = msg.roleinfo})
        m_roleInfoOpenUI = RoleInfoOpenUI.None
    elseif m_roleInfoOpenUI == RoleInfoOpenUI.Answer then
        uimanager.showdialog("marriage.dlgmarriageanswer",{
            proposeroleid = m_answerid, proposerolename = m_answerName, 
            proposetype = m_answerType, proposeoath = m_answerOath, roleInfo = msg.roleinfo})
        m_roleInfoOpenUI = RoleInfoOpenUI.None
    end  
end

--*******************************************************************
local function OpenDivorceWithDiscussDlg(id, name)    
    if not id then  return   end
    m_selectedPlayerID = id
    m_selectedPlayerName = name
    
    uimanager.ShowAlertDlg({
        content      = LocalString.Marriage.DivorceDiscuss,
        sureText     = LocalString.Marriage.DivorceButtonBook,
        cancelText   = LocalString.Marriage.DivorceButtonDiscuss, 
        showCloseButton = true,               
        callBackFunc = function()
            OpenDivorceWithBookDlg()
        end,
        callBackFunc1 = function()
            CDivorceWithDiscuss()
        end,
        immediate = true,
        })
end

local function Logout()
    Release()
end

local function init()
    network.add_listeners({
         {"lx.gs.marriage.msg.SMarriageInfo",            onmsg_SMarriageInfo},
         {"lx.gs.marriage.msg.SFriendWish",              onmsg_SFriendWish},
         {"lx.gs.marriage.msg.SAttemptPropose",          onmsg_SAttemptPropose},          
         {"lx.gs.marriage.msg.SPropose",                 onmsg_SPropose},            --��������,֪ͨ���鷽,0��ʾ����ʧ�ܣ�1��ʾ�����ɹ�         
         {"lx.gs.marriage.msg.SBeproposed",              onmsg_SBeproposed},      --�����߿�ʼ�����󣬷�����֪ͨ����������������������           
         {"lx.gs.marriage.msg.SBuyCaili",                onmsg_SBuyCaili},          
         {"lx.gs.marriage.msg.SBuyXiushu",               onmsg_SBuyXiushu},          
         {"lx.gs.marriage.msg.SBedivorceWithDiscuss",    onmsg_SBedivorceWithDiscuss}, --������֪ͨ��������         
         {"lx.gs.marriage.msg.SDivorceWithBook",         onmsg_SDivorceWithBook},           --ʹ����������������          
         {"lx.gs.marriage.msg.SDivorceWithDiscuss",      onmsg_SDivorceWithDiscuss},     --Э�������Ľ���,0��ʾ����ʧ�ܣ�1��ʾ�����ɹ�        

        -- notify
         {"lx.gs.marriage.msg.SFriendMarryNotify",       onmsg_SFriendMarryNotify},  --֪ͨ˫�����к��ѽ�����Ϣ  
         {"lx.gs.marriage.msg.SFriendWishNotify",        onmsg_SFriendWishNotify},    --����ף����֪ͨ����˫���õ���ף��
         {"lx.gs.marriage.msg.SAllSomePeopleMarryNotify",onmsg_SAllSomePeopleMarryNotify}, --֪ͨȫ�������˽���       
         {"lx.gs.marriage.msg.SBedivorcedNotify",        onmsg_SBedivorcedNotify},     --ʹ��������֪ͨ��������  
         {"lx.gs.marriage.msg.SBedivorcedNotify",        onmsg_SBedivorcedNotify},     --ʹ��������֪ͨ��������    

         {"lx.gs.role.msg.SGetRoleInfo",                 onmsg_SGetRoleInfo},     
    })

    local gameevent = require "gameevent"
    gameevent.evt_system_message:add("logout", Logout)
end

return{
    DialogType            = DialogType,
    GiftsType             = GiftsType,
    ProposeRe             = ProposeRe,
    init                  = init,
    OpenProposeDlg        = OpenProposeDlg,
    OpenDivorceWithDiscussDlg = OpenDivorceWithDiscussDlg,
    CAttemptPropose       = CAttemptPropose,
    CPropose              = CPropose,
    CBeproposed           = CBeproposed,
    CDivorceWithBook      = CDivorceWithBook,
    CDivorceWithDiscuss   = CDivorceWithDiscuss,
    CBedivorceWithDiscuss = CBedivorceWithDiscuss,
    CBuyCaili             = CBuyCaili,
    CFriendWish           = CFriendWish,
    CBuyXiushu            = CBuyXiushu,
    IsGiftsExist          = IsGiftsExist,
    IsMarriaged           = IsMarriaged,
    GetCoupleRoleID       = GetCoupleRoleID,
    EnableInputControlEdit= EnableInputControlEdit,
    GetSelectedPlayerName = GetSelectedPlayerName,
    SetCoupleRoleID       = SetCoupleRoleID,
    ClearUIType           = ClearUIType,
    Release               = Release,
}
