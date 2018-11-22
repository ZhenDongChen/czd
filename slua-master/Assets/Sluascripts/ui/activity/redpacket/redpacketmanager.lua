local NetWork=require("network")
local UIManager=require("uimanager")
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local itemmanager = require "item.itemmanager"
local LimitTimeManager       = require("limittimemanager")
local ConfigManager 	  = require "cfg.configmanager"
local redpacketinfo 	  = require "ui.activity.redpacket.redpacketinfo"
local BonusManager = require("item.bonusmanager")
local timeutils = timeutils
local ItemManager = require("item.itemmanager")
local ChatManager = require"ui.chat.chatmanager"

--[[
<protocol name="CSendMoneyPackage">
	<variable name="packagetype" type="int"/>���ĺ�������,�߻�����
	<variable name="word" type="string"/>
	<variable name="channeltype" type="int"/>�����������绹�Ǽ��� ���Ͳο������е�ChannelType
</protocol>
--]]
local function send_CSendMoneyPackage(packagetype, word, channeltype)
    local msg = lx.gs.springactivity.msg.CSendMoneyPackage({packagetype=packagetype, word=word, channeltype=channeltype})
    printyellow("[redpacketmanager:send_CSendMoneyPackage] send:", msg)
    NetWork.send(msg)
end


local function GetReceiveNotifyMsg(msg)
    local currencydata = ItemManager.CreateItemBaseById(msg.moneytype, nil, msg.money)
    local packetinfo = redpacketinfo.GetRedPacketInfo(msg.packagetype)
    local packetitem= packetinfo and ItemManager.CreateItemBaseById(packetinfo.needitemid) or nil
    return string.format(LocalString.Red_Packet_Send_Notify, msg.sendername, packetitem and packetitem:GetName() or "")
end

local function on_SRedPackageNotify(msg)
    redpacketinfo.PushUnfetchedPacket(msg)
end
--[[
//֪ͨ����ȡ�ú���������
<protocol name="SMoneyPackageNotify">
	<variable name="packageid" type="long"/>
	<variable name="packagetype" type="int"/>���ĺ�������
	<variable name="sendername" type="string"/>
	<variable name="word" type="string"/>
</protocol>
--]]
-- local function on_SMoneyPackageNotify(msg)
--     printyellow("[redpacketmanager:on_SMoneyPackageNotify] receive:", msg)
        
--     redpacketinfo.PushUnfetchedPacket(msg)
        
--     --���½���
--     if msg.sendername==PlayerRole:GetName() and UIManager.isshow("activity.redpacket.dlgsendred") then
--         UIManager.hidedialog("activity.redpacket.dlgsendred")
--         UIManager.ShowSystemFlyText(LocalString.Red_Packet_Send_Success)
--     end
        
--     if msg and redpacketinfo.IsNormalRedPacket(msg.packagetype) then
--         local content = {}
-- 	    content.channel = msg.channeltype
--         content.invitechannel = msg.channeltype
--         content.name = ""        
--         content.sendername = ""
-- 	    content.text = GetReceiveNotifyMsg(msg)
-- 	    ChatManager.AddMessageInfo(content)
        
--         printyellow("[redpacketmanager:on_SMoneyPackageNotify] content:")
--         printt(content)
--     end
-- end

--[[
<protocol name="CGetMoney">
    <variable name="packageid" type="long"/>
</protocol>
--]]
local function send_CGetMoney(packageid, senderId)
    local msg = lx.gs.redpacket.msg.CGetMoney({packageid=packageid, senderid=senderId})
    printyellow("[redpacketmanager:send_CGetMoney] send:", msg)
    NetWork.send(msg)
end

local function GetFetchNotifyMsg(msg)
    local currencydata = ItemManager.CreateItemBaseById(msg.moneytype, nil, msg.money)
    local packetinfo = redpacketinfo.GetRedPacketInfo(msg.packagetype)
    local packetitem= packetinfo and ItemManager.CreateItemBaseById(packetinfo.needitemid) or nil
    return string.format(LocalString.Red_Packet_Open_Notify, msg.receivername, msg.sendername, packetitem and packetitem:GetName() or "", msg.money, currencydata and currencydata:GetName() or "")
end

--[[
<protocol name="SGetMoneyNotify">������ȡ�ɹ���������Ƶ���ڹ㲥������ֻ�ᷢ�͸�����������
	<enum name="OK" value="0"/>�ɹ�
	<enum name="FAIL" value="1"/>������ �����ѱ�����
	<enum name="EXCEED_MAX_TIME" value="2"/>������������ȡ����������
	<enum name="HAS_RECEIVE_THIE_RED_PACKAGE" value="3"/>�Ѿ���ȡ���ú���
	<variable name="result" type="int"/>
	<variable name="sendername" type="string"/>
	<variable name="receivername" type="string"/>
	<variable name="moneytype" type="int"/>
	<variable name="money" type="int"/>���õĽ���
</protocol>
--]]
-- old 
-- local function on_SGetMoneyNotify(msg)
--     printyellow("[redpacketmanager:on_SGetMoneyNotify] receive:", msg)
--     if msg.result~=lx.gs.springactivity.msg.SGetMoneyNotify.OK or msg.receivername==PlayerRole:GetName()then
--         redpacketinfo.PopUnfetchedPacket()   

--         --���½���
--         if UIManager.isshow("activity.redpacket.dlgred") then
--             UIManager.call("activity.redpacket.dlgred","refresh",msg)
--         end     
--     end
    
--     if msg.result==lx.gs.springactivity.msg.SGetMoneyNotify.OK then
--         local content = {}
-- 	    content.channel = msg.channeltype
--         content.invitechannel = msg.channeltype
--         content.name = ""        
--         content.sendername = ""
-- 	    content.text = GetFetchNotifyMsg(msg)
-- 	    ChatManager.AddMessageInfo(content)
        
--         --printyellow("[redpacketmanager:on_SGetMoneyNotify] content:")
--         --printt(content)
--     end
-- end
local function on_SGetMoneyNotify(msg)
    local pkgInfo = redpacketinfo.PopUnfetchedPacket()
    --
    redpacketinfo.curGetResult = nil
    if msg.redpacketinfo.result==0 then
        redpacketinfo.curGetResult = msg.redpacketinfo;
        if UIManager.isshow("activity.redpacket.dlgredinfo") then
            UIManager.call("activity.redpacket.dlgredinfo", "refresh", msg.redpacketinfo)
        else
            UIManager.show("activity.redpacket.dlgredinfo", msg.redpacketinfo)
        end
        -- if UIManager.isshow("activity.redpacket.dlgred") then
        --     UIManager.call("activity.redpacket.dlgred","refresh",msg)
        -- end
    end
end

local function on_SError(msg)
    if msg.errcode==cfg.error.ErrorCode.NO_SUCH_REDPACKAGE or 
        msg.errcode==cfg.error.ErrorCode.NO_SUCH_REDPACKAGETYPE then
        printyellow("[redpacketmanager:on_SError] receive:", msg)
        local pkgInfo = redpacketinfo.PopUnfetchedPacket()
        redpacketinfo.curGetResult = nil

        --���½���
        -- if UIManager.isshow("activity.redpacket.dlgred") then
        --     UIManager.call("activity.redpacket.dlgred","refresh",msg)
        -- end
    end
end

--[[
<protocol name="CGetRoleList">
	<variable name="packageid" type="long"/>
</protocol>
--]]
local function send_CGetRoleList(packageid)
    local msg = lx.gs.springactivity.msg.CGetRoleList({packageid=packageid})
    printyellow("[redpacketmanager:send_CGetRoleList] send:", msg)
    NetWork.send(msg)
end

--[[
<protocol name="SGetRoleList">
	<variable name="packageid" type="long"/>
	<variable name="moneytype" type="int"/>
	<variable name="roles" type="map" key="string" value="int"/>
</protocol>
--]]
local function on_SGetRoleList(msg)
    printyellow("[redpacketmanager:on_SGetRoleList] receive:", msg)
    UIManager.show("activity.redpacket.dlgredinfo", msg)
end

local function UnReadSend()
    --return redpacketinfo.GetSendCount()<redpacketinfo.GetSendLimit()
    return false
end

local function UnReadReceive()
    return redpacketinfo.GetReceiveCount()<redpacketinfo.GetReceiveLimit() and redpacketinfo.GetUnfetchedCount()>0
end

local function init()
    --printyellow("[redpacketmanager:init] init!")
    redpacketinfo.init()

    --test
    --local msg = {id=1, nextbonusid=4, dayindex=1}
    --on_SActivity(msg)

    NetWork.add_listeners({
        --{"lx.gs.springactivity.msg.SMoneyPackageNotify",on_SMoneyPackageNotify},
        --{"lx.gs.springactivity.msg.SGetMoneyNotify",on_SGetMoneyNotify},
        --{"lx.gs.springactivity.msg.SGetRoleList",on_SGetRoleList},
        {"lx.gs.redpacket.msg.SRedPackageNotify",on_SRedPackageNotify},
        {"lx.gs.redpacket.msg.SGetMoneyNotify",on_SGetMoneyNotify},
        {"lx.gs.SError",on_SError},        
    })
end

return
{
    init     = init,
    UnReadSend  = UnReadSend,
    UnReadReceive = UnReadReceive,
    send_CGetMoney = send_CGetMoney,
    send_CSendMoneyPackage = send_CSendMoneyPackage,
    send_CGetRoleList = send_CGetRoleList,
    on_SRedPackageNotify = on_SRedPackageNotify,
    on_SGetMoneyNotify = on_SGetMoneyNotify,
}
