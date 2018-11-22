local print             = print
local unpack            = unpack
local require           = require
local format            = string.format
local network           = require("network")
local gameevent         = require("gameevent")
local UIManager         = require("uimanager")
local ConfigManager     = require("cfg.configmanager")
local utils             = require("common.utils")
local PlayerRole        = require("character.playerrole")
local LimitTimeManager  = require("limittimemanager")


local g_PagesInfo  = { }
local g_SkillAttrs = { }


-- 数据结构定义
local SkillData = Class:new()

function SkillData:__new(skillId, profession, addLevel, locked)
	self.skillId = skillId
	self.profession = profession
	self.data = SkillManager.GetSkill(skillId, PlayerRole:Instance().m_Gender)
	self.addLevel = addLevel
	self.bLocked = locked
end

local AmuletPageData = Class:new()

function AmuletPageData:__new(skillAttrList, locked)
	self.SkillAttrs = skillAttrList
end

local function GetPagesInfo()
	return g_PagesInfo
end

local function RefreshSkillAttrs()
	g_SkillAttrs = { }
	for pageIndex = 1, #g_PagesInfo do
		local pageData = g_PagesInfo[pageIndex]
		for _, skill in ipairs(pageData.SkillAttrs) do
			-- 本门派技能增加等级数据
			if PlayerRole:Instance().m_Profession == skill.profession then
				if not g_SkillAttrs[skill.skillId] then
					g_SkillAttrs[skill.skillId] = skill.addLevel
				else
					g_SkillAttrs[skill.skillId] = g_SkillAttrs[skill.skillId] + skill.addLevel
				end
			end
		end
	end
end

local function GetAmuletAttrs()
	return g_SkillAttrs
end

-- region msg
local function onmsg_SGetAmuletInfo(msg)
	-- print("onmsg_SGetAmuletInfo")
	local amuletPages = msg.amuletinfo.pagemap
	g_PagesInfo = { }
	for index, pageData in ipairs(amuletPages) do
		local skillDataList = { }
		for _, attr in ipairs(pageData.propmap) do
			local bSkillLocked = false
			if attr.islock == 1 then
				bSkillLocked = true
			end
			skillDataList[#skillDataList + 1] = SkillData:new(attr.skillid, attr.professionid, attr.addlevel, bSkillLocked)
		end
		g_PagesInfo[index] = AmuletPageData:new(skillDataList)
	end
	-- 更新本门派技能数据
	RefreshSkillAttrs()
	UIManager.refresh("playerrole.equip.dlgamuletenhance")
end

local function onmsg_SWashAmulet(msg)

end

local function onmsg_SApplyAmuletWashResult(msg)
	-- print("onmsg_SApplyAmuletWashResult")
	-- 更新指定页的skill列表信息
	local skillDataList = { }
	for _, attr in pairs(msg.changeprop) do
		local bSkillLocked = false
		if attr.islock == 1 then
			bSkillLocked = true
		end
		g_PagesInfo[msg.pageid].SkillAttrs[attr.propindex] = SkillData:new(attr.skillid, attr.professionid, attr.addlevel, bSkillLocked)
	end
	-- 清除洗炼结果界面
	local DlgAlert_AmuletWash = require("ui.playerrole.equip.dlgalert_amuletwash")
	DlgAlert_AmuletWash.hide()
	UIManager.hide("common.dlgdialogbox_complex")
	-- 更新本门派技能数据
	RefreshSkillAttrs()
	-- 刷新洗炼界面
	UIManager.refresh("playerrole.equip.dlgamuletenhance")
end

local function onmsg_SCancelAmuletWashResult(msg)
	-- print("onmsg_SCancelAmuletWashResult")
	-- 清除洗炼结果界面
	local DlgAlert_AmuletWash = require("ui.playerrole.equip.dlgalert_amuletwash")
	DlgAlert_AmuletWash.hide()
	UIManager.hide("common.dlgdialogbox_complex")
	-- 刷新洗炼界面
	UIManager.refresh("playerrole.equip.dlgamuletenhance")
end

local function onmsg_SLockAmulet(msg)
	-- print("onmsg_SLockAmulet")
	g_PagesInfo[msg.pageid].SkillAttrs[msg.amuletid].bLocked = true
	UIManager.refresh("playerrole.equip.dlgamuletenhance")
end

local function onmsg_SUnLockAmulet(msg)
	-- print("onmsg_SUnLockAmulet")
	g_PagesInfo[msg.pageid].SkillAttrs[msg.amuletid].bLocked = false
	UIManager.refresh("playerrole.equip.dlgamuletenhance")
end

local function onmsg_SAmuletPageOpenNotify(msg)
	-- print("onmsg_SAmuletPageOpenNotify")
	-- 重新获取数据
	network.create_and_send("lx.gs.amulet.CGetAmuletInfo")
end

-- endregion msg

local function Release()
	g_PagesInfo = { }
	g_SkillAttrs = { }
end

local function OnLogout()
	Release()
end

local function init()
	g_PagesInfo = { }
	g_SkillAttrs = { }
    network.add_listeners( {
		{ "lx.gs.amulet.SGetAmuletInfo", onmsg_SGetAmuletInfo },
		--{ "lx.gs.amulet.SWashAmulet", onmsg_SWashAmulet },
		{ "lx.gs.amulet.SApplyAmuletWashResult", onmsg_SApplyAmuletWashResult },
		{ "lx.gs.amulet.SCancelAmuletWashResult", onmsg_SCancelAmuletWashResult },
		{ "lx.gs.amulet.SLockAmulet", onmsg_SLockAmulet },
		{ "lx.gs.amulet.SUnLockAmulet", onmsg_SUnLockAmulet },
		{ "lx.gs.amulet.SAmuletPageOpenNotify", onmsg_SAmuletPageOpenNotify },
    } )
	gameevent.evt_system_message:add("logout", OnLogout)
end

return {
    init           = init,
	GetPagesInfo   = GetPagesInfo,
	GetAmuletAttrs = GetAmuletAttrs,
	SkillData      = SkillData,
	AmuletPageData = AmuletPageData,
}