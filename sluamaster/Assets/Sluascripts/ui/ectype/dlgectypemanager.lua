local DailyEctypeManager=require"ui.ectype.dailyectype.dailyectypemanager"
local LimitManager = require"limittimemanager"
local ConfigManager = require"cfg.configmanager"
local MultiEctypeManger = require"ui.ectype.multiectype.multiectypemanager"
local function TowerUnRead()
    local currentEctype = 60430001
    local cfgTower = ConfigManager.getConfigData("climbtowerectype",currentEctype)
    local CheckCmd=require"common.checkcmd"
    local validate,info=CheckCmd.CheckData({data=cfgTower.dailylimit,moduleid=cfg.cmd.ConfigId.CLIMB_TOWER_ECTYPE,cmdid=currentEctype})
    local validate2,info2 = CheckCmd.CheckData{data=cfgTower.levellimit,moduleid=cfg.cmd.ConfigId.CLIMB_TOWER_CCTYPE,cmdid=currentEctype}
    return validate and validate2
end

local function UnRead()
    local ModuleLockManager=require"ui.modulelock.modulelockmanager"
  
    return (ModuleLockManager.GetModuleStatusByIndex("ectype.dlgentrance_copy",2)==defineenum.ModuleStatus.UNLOCK and DailyEctypeManager.UnRead()) or (ModuleLockManager.GetModuleStatusByIndex("ectype.dlgentrance_copy",4)==defineenum.ModuleStatus.UNLOCK and TowerUnRead()) or (ModuleLockManager.GetModuleStatusByIndex("ectype.dlgentrance_copy",3)==defineenum.ModuleStatus.UNLOCK and MultiEctypeManger.UnRead())
end

local function init()
end

return{
    init = init,
    UnRead = UnRead,
    TowerUnRead = TowerUnRead,
}
