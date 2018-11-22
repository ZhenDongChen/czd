local error = error
local network = require"network"
local chatmanager = require"ui.chat.chatmanager"
local gameObject
local name
local fields

local MsgQueue = Queue:new()
local PMDStartPos = 430
local PMDEndPos = -340
local cur_PMD_Position = 430
local isMsgScrolling = false
local cur_PMD_Message


local function IsPaomadengMsgEmpty()
	return MsgQueue:IsEmpty() 
end

local function GetCurPostionPaomadeng()
	return Vector3(cur_PMD_Position,-2,0)
end


local function PushBroadCastMsg(msg)
    if fields then
        if (MsgQueue:IsEmpty()) then       
            fields.UIGroup_SystemMessage.gameObject:SetActive(true)
        end
        MsgQueue:Push(msg)
    end
end


local function update()

    if (MsgQueue:IsEmpty()) then  --队列为空
        return
    end

    if not isMsgScrolling  then         --当前信息滚动显示结束
        isMsgScrolling = true
		cur_PMD_Message = MsgQueue:Last().value
		chatmanager.AddMessageInfo({channel = cfg.chat.ChannelType.SYSTEM,text = cur_PMD_Message})
		fields.UILabel_SystemMessage.text = cur_PMD_Message
    end

-- 	fields.UILabel_SystemMessage.transform.localPosition = Vector3(cur_PMD_Position,-2,0)
	cur_PMD_Position = cur_PMD_Position - 1.5
	if cur_PMD_Position < PMDEndPos then
		isMsgScrolling = false
		cur_PMD_Position = PMDStartPos

        MsgQueue:Pop()
		if MsgQueue:IsEmpty() then
            fields.UIGroup_SystemMessage.gameObject:SetActive(false)
        end
	end       
end


local function OnLogout()
	MsgQueue:Clear()
    fields.UIGroup_SystemMessage.gameObject:SetActive(false)
	cur_PMD_Position = PMDStartPos
	isMsgScrolling = false
	cur_PMD_Message = nil
end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
  
	gameevent.evt_update:add(update)
	gameevent.evt_system_message:add("logout", OnLogout)
end

return {
	init = init,
	update = update,
	PMD_TYPE = PMD_TYPE,
    PushBroadCastMsg = PushBroadCastMsg,
	IsPaomadengMsgEmpty = IsPaomadengMsgEmpty,
	GetCurPostionPaomadeng = GetCurPostionPaomadeng,
}
