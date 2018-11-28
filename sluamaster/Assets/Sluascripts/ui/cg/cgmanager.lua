local NetWork=require("network")
local UIManager=require("uimanager")     
local gameevent = require "gameevent" 

local m_CurrentVedioName
local m_PlayEndCallback

local function PlayCG(vedioname, callback, mode)
	print("cgmanager")
    if IsNullOrEmpty(vedioname) then  
        print("[cgmanager:PlayCG] vedio Is Null Or Empty, abort!")  
        if callback then
            callback(vedioname)
        end
        m_CurrentVedioName = nil
        m_PlayEndCallback = nil
    else    
        print(string.format("[cgmanager:PlayCG] PlayCG [%s], mode:", vedioname), mode)
        m_CurrentVedioName = vedioname
        m_PlayEndCallback = callback
        Game.SceneMgr.Instance:PlayVideo(vedioname, mode)
    end
end

local MsgPlayVedioEnd = "msgplayvedioend"
local function OnMsgPlayVedioEnd(param)
    print("[cgmanager:OnMsgPlayVedioEnd] play vedio end:", param)
    if m_PlayEndCallback then
        m_PlayEndCallback(m_CurrentVedioName)
    end
    m_CurrentVedioName = nil
    m_PlayEndCallback = nil
end

local function init()
	gameevent.evt_system_message:add(MsgPlayVedioEnd, OnMsgPlayVedioEnd)
end

return{
    init=init,
    PlayCG = PlayCG,
}