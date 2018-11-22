
local function Load(file,bOptional)
    local path = LuaHelper.GetPath(file)
    local file = io.open(path,"r")
	if not file then
	    if bOptional then
	       return 
		end
	end
    local xml = file:read("*all")

	local f= loadstring(xml)
    
    f()
end

local function SaveTableContent(file, obj)
    local objType = type(obj);
    if objType == "number" then
        file:write(obj);
    elseif objType == "string" then
        file:write(string.format("%q", obj));
    elseif objType == "boolean" then
        file:write(obj and "true" or "false")
    elseif objType == "table" then
            --把table的内容格式化写入文件
        file:write("{\n");
        for i, v in pairs(obj) do
            file:write("[");
            SaveTableContent(file, i);
            file:write("]=\n");
            SaveTableContent(file, v);
            file:write(", \n");
        end
        file:write("}\n");
    else
        if Local.LogManager then
            print("can't serialize a "..objType)
        end
    end
end


local userconfig_filename="userconfig.log"

Load("config/local.lua")
Load("config/localstring.lua")

Load(userconfig_filename,true)
if not UserConfig then
  UserConfig={}
end

Load("config/resversionurl.lua")


function SaveUserConfig()
    local path = LuaHelper.GetPath(userconfig_filename)
    local file = io.open(path,"w")
    assert(file);
    file:write("UserConfig = \n");
    SaveTableContent(file, UserConfig);
    file:write("\n");
    file:close();
end

function GetUserConfig(id,params)
    if not UserConfig[id] then
        UserConfig[id] = {}
    end
    local tb = UserConfig[id]
    for _,v in ipairs(params.path) do
        if tb[v]==nil then
            tb[v] = {}
        elseif type(tb[v]) ~= "table" then
            logError("path wrong" .. type(tb[v]))
            return
        end
        tb = tb[v]
    end
    return tb[params.idx]
end



Local.UIPersistentMap = {}


local function LoadUrlBoradCast()
    local path = LuaHelper.GetPath("config/urlbroadcast.lua")
    local file = io.open(path,"r")
    local xml = file:read("*all")
    return loadstring(xml)()
end

Local.BroadCastUrls = LoadUrlBoradCast()
if Local.UIPersistentList then
    for _,data in pairs(Local.UIPersistentList) do
        Local.UIPersistentMap[data] = true
    end
end