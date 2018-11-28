local NetWork = require("network")
local UIManager = require("uimanager")
local m_Mails = {}

local OpenStatus = enum
{
    "UnRead = 0",
    "Read = 1",
}

local function GetMails()
    return m_Mails
end

local function OnMsg_SMailBox(d)
    m_Mails = (d.mails)
end

local function RefreshMailDlg()
    if UIManager.isshow("mail.dlgmail") then
        UIManager.call("mail.dlgmail","refresh")
    end
    if UIManager.isshow("dlgmain_open") then
        UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.MAIL)
    end
end

local function OnMsg_SNewMail(d)
    local mail = d.mail
    local hasMail = false
    for i = 1,#m_Mails do
        if m_Mails[i].id == mail.id then
            hasMail = true
            break
        end
    end
    if not hasMail then
        m_Mails[#m_Mails + 1] = mail
    end
    RefreshMailDlg()
end

local function OnMsg_SDelMail(d)
    local delMailIds = d.delmailids
    for i = 1,#delMailIds do
        for j = 1,#(m_Mails) do
            if m_Mails[j].id == delMailIds[i] then
                table.remove(m_Mails,j)                
                break
            end
        end
    end
    RefreshMailDlg()
end

local function OnMsg_SObtainMailAccessory(d)
    local mailIds = d.mailids
    for i = 1,#mailIds do
        for j = 1,#(m_Mails) do
            if m_Mails[j].id == mailIds[i] then
                table.remove(m_Mails,j)
                break
            end
        end
    end
    RefreshMailDlg()
end

local function OnMsg_SReadMail(d)
    local mailId=d.mailid
    for i = 1,#m_Mails do
        if m_Mails[i].id == mailId then
            m_Mails[i].read = OpenStatus.Read
            local DlgMail = require("ui.mail.dlgmail")
            DlgMail.SetMailOpened(mailId)
            break
        end
    end
end

local function UnRead()
    local status = false
    for _,mail in pairs(m_Mails) do
        if mail.read == OpenStatus.UnRead then
            status = true
            break
        end
    end
    return status
end

local function init()
      NetWork.add_listeners({
        {"lx.gs.mail.msg.SMailBox",OnMsg_SMailBox},
        {"lx.gs.mail.msg.SNewMail", OnMsg_SNewMail},
        {"lx.gs.mail.msg.SDelMail", OnMsg_SDelMail},
        {"lx.gs.mail.msg.SObtainMailAccessory", OnMsg_SObtainMailAccessory},
        {"lx.gs.mail.msg.SReadMail", OnMsg_SReadMail},
    })
end

return{
    init = init,
    GetMails = GetMails,
    UnRead = UnRead,
    OpenStatus = OpenStatus,
}
