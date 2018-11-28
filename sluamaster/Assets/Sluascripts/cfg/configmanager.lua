
local os = require "cfg.structs"
local AllCsvCfgs
local csv_combine
function create_datastream(file)
    return os.new(LuaHelper.GetPath("config/csv/" .. file))
end

local function getConfig(configname)
    if AllCsvCfgs then
        return AllCsvCfgs[configname]
    end
	
    return nil
end

local function getConfigData(configname,index)
    local config = getConfig(configname)
    if config then
        return config[index]
    end
	
    return nil
end

local function GetHeadIcon(profession, gender)
    local dataprofession = ConfigManager.getConfigData("profession", profession)
    if not dataprofession then return "" end
    local datamodel = ConfigManager.getConfigData("model",
     gender == cfg.role.GenderType.MALE and dataprofession.modelname or dataprofession.modelname2)
    if not datamodel then return "" end
    return datamodel.headicon
end

local function loadCsv()
    AllCsvCfgs = require "cfg.configs"
	
end

local function loadCsv_combine()
	
	csv_combine = getConfig("csv_combine")

	for targetTableID,v in pairs(csv_combine) do 
		printyellow(targetTableID)
		printyellow(v.target)
		if AllCsvCfgs[v.target] == nil then
			AllCsvCfgs[v.target] = {}
		end
		if AllCsvCfgsp[v.src] == nil then
			printyellow("target Source data is nil please check"..v.src)
		else
			table.insert(AllCsvCfgs[v.target],AllCsvCfgsp[v.src]) 
		end				
	end
end	

	
local function init()
	
    AllCsvCfgs = {}
    loadCsv()	

end



return
{
    init              = init,
    getConfig         = getConfig,
    getConfigData     = getConfigData,
    GetHeadIcon       = GetHeadIcon,
	loadCsv_combine   = loadCsv_combine,
}
