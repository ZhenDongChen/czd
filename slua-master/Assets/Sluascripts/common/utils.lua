local insert = table.insert
local fmt = string.format
local concat = table.concat
local tostring = tostring
local schar = string.char
local sbyte = string.byte
local find = string.find
local sub = string.sub
local type = type
local pairs = pairs
local ipairs = ipairs
local date = os.date
local print = print
local logError = logError
local require = require

local traceback = debug.traceback
local xpcall = xpcall

local function swap_value(t, a, b)
    local temp = t[a]
    t[a] = t[b]
    t[b] = temp
end

local function table_sort(t, cmp)
    for i = 1, #t do
        for j = #t, i + 1, -1 do
            if not cmp(t[j - 1],t[j]) then
                swap_value(t, j, j - 1)
            end
        end
    end
end

local function table_count(t)
    local count = 0
    for i, k in pairs(t) do
        count = count + 1
    end
    return count
end

local function table_sub_condition(t, condition)
    local t2 = {}
    for i, k in pairs(t) do
        if condition(i, k) then
            t2[i] = k
        end
    end
    return t2
end

local function table_sub_count(t, count)
    local t2 = {}
    for i, k in ipairs(t) do
        if i <= count then
            t2[i] = k
        end
    end
    return t2
end

local function CompareList(list1,list2, cmp)
    if list1 == list2 then
        return true
    else
        if nil==list1 or nil==list2 then
            return false
        elseif table.getn(list1) ~= table.getn(list2) then
            return false
        else
            if cmp then
                table_sort(list1, cmp)
                table_sort(list2, cmp)
            else
                table.sort(list1)
                table.sort(list2)
            end
            for i,value in ipairs(list1) do
                if value~=list2[i] then
                    printyellow(string.format("[utils:CompareList] list1[%s]=[%s] while list2[%s]=[%s], return false!", i,value, i,list2[i]))
                    return false
                end
            end
            return true
        end
    end
end

local function errhandler(e)
    logError(e)
end

local function my_xpcall(func, data)
    return xpcall(function() func(data) end, errhandler)
end

local function array_to_set(t)
    local r = {}
    for _, v in ipairs(t) do
        r[v] = true
    end
    return r
end

local function tolong(s)
    local n = 0
    for i = #s, 1, -1 do
        n = n * 256 + sbyte(s, i)
    end
    return n
end

local function bytes_to_string (bytes)
  local d = {}
  for i = 1, bytes.Length do
    local x = bytes[i]
    insert(d, schar(x >= 0 and x or x + 256))
  end
  return concat(d)
end

local function strtime(fmt, t)
    return date("%Y-%m-%d", t)
end

local function strtime1(t)
    return date("%Y-%m-%d %H:%M:%S", t)
end

-- 返回 hh:ss
local function strtime_inday(t)
    return date("%H:%M", t)
end

local function get_or_create(namespace)
  local t = _G
  local idx = 1
  while true do
    local start, ends = find(namespace, ".", idx, true)
    local subname = sub(namespace, idx, start and start - 1)
    local subt = t[subname]
    if not subt then
      subt = {}
      t[subname] = subt
    end
    t = subt
    if start then
      idx = ends + 1
    else
      return t
    end
  end
end

local function deep_copy_to(src, dst)
    for k, v in pairs(src) do
        if type(v) ~= "table" then
            dst[k] = v
        else
            dst[k] = dst[k] or {}
            deep_copy_to(v, dst[k])
        end
    end
end

local function shallow_copy_to(src, dst)
    for k, v in pairs(src) do
        dst[k] = v
    end
end

local function clear_table(t)
  if t == nil then return end
  for k, _ in pairs(t) do
    t[k] = nil
  end
end

local function copy_table(src)
	local inst={};
	local k, v;
	for k, v in pairs(src) do
		if type(v) == "table" then
			inst[k] = copy_table(v);
		else
			inst[k] = v;
		end
	end
	local mt = getmetatable(src);
	setmetatable(inst, mt);
	return inst;
end

local function create_obj(template, obj)
	local inst = obj or {};
	local k, v;
	for k, v in pairs(template) do
		if (not inst[k]) and type(v) ~= "function" then
			if type(v)== "table" and v ~= template then
				inst[k] = copy_table(v);
			end
		end
	end
	setmetatable(inst, template);
	template.__index = template;
	return inst;
end

local function Max(a,b)
    if a>=b then
        return a
    else
        return b
    end
end

local function Min(a,b)
    if a<=b then
        return a
    else
        return b
    end
end

local function insidepolygon(polygon,p)
    local N=#polygon
    local counter = 0
    local i
    local xinters
    local p1
    local p2
    p1 = polygon[1]
    for i=2,(N+1) do
        if (i%N==0) then
            p2=polygon[i]
        else
            p2 = polygon[i % N]
        end
        if (p.z > Min(p1.z,p2.z)) then
            if (p.z <= Max(p1.z,p2.z)) then
                if (p.x <= Max(p1.x,p2.x)) then
                    if (p1.z ~= p2.z) then
                        xinters = (p.z-p1.z)*(p2.x-p1.x)/(p2.z-p1.z)+p1.x
                        if ((p1.x == p2.x) or (p.x <= xinters)) then
                            counter=counter+1
                        end
                    end
                end
            end
        end
        p1 = p2
    end
    if (counter % 2 == 0) then
        return false
    else
        return true
    end
end

--判断一个点是否在一个任意多边形内
local function insideAnyPolygon(polygon,p)
    local count = 0
    local n=#polygon
    local a
    local b
    a=polygon[1]
    for i=2,n+1 do
        if (i%n==0) then
            b = polygon[i]
        else
            b = polygon[i % n]
        end
        if((a.x <= p.x and p.x <= b.x) or (b.x <= p.x and p.x <= a.x)) then
            local r = (p.x - a.x) * (a.z - b.z) - (p.z - a.z) * (a.x - b.x)
            if (r == 0) then
                -- 在边上
                if (a.x ~= p.x or p.x ~= b.x or (a.z <= p.z and p.z <= b.z) or (b.z <= p.z and p.z <= a.z)) then
                    return true
                end
            elseif (r/(a.x-b.x) > 0) then
                count=count+1
            end
        end
        a=b
    end
    return (count%2==1)
end

--获取枚举名
local function getenumname(enumtype,enumvalue)
    for name,value in pairs(enumtype) do
        if value == enumvalue then
            return name
        end
    end
    return ""
end

--设置粒子特效scale
local function SetParticleSystemScale(gameObject,scale)
    if not gameObject or not scale or scale <= 0 or scale == 1 then
        return
    end

    local allParticleSystem = gameObject:GetComponentsInChildren(UnityEngine.ParticleSystem,true)
    for i = 1,allParticleSystem.Length do
        local particleSystem = allParticleSystem[i]
        if particleSystem then
            particleSystem.startSize = particleSystem.startSize * scale
            particleSystem.startSpeed = particleSystem.startSpeed * scale
            local renderer = particleSystem:GetComponent(UnityEngine.ParticleSystemRenderer,true)
            if renderer then
                renderer.lengthScale = renderer.lengthScale * scale
                renderer.velocityScale = renderer.velocityScale * scale
                -- print("renderer.lengthScale :"..renderer.lengthScale)
            end
        end
    end
end

local function SetDefaultComponent(go,com)
    if go then
        local component = go:GetComponent(com)
        if not component then
            component = go:AddComponent(com)
        end
        return component
    end
    return nil
end

local exceptions_mask

local masks = { 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC }

local value_masks = { 0x7F, 0x1F, 0x0F, 0x07, 0x03, 0x01}

local function bin_search(tb,val)
    local from,to
    from = 1
    to = #tb
    while from<=to do
        local mid = math.floor(from/2+to/2)
        if tb[mid] > val then
            to = mid - 1
        elseif tb[mid] < val then
            from = mid + 1
        else
            return tb[mid]
        end
    end
    return nil
end

local function IsExsception(val)
    if not exceptions_mask then
        exceptions_mask = {}
        local path = LuaHelper.GetPath("config/encode.txt")
        local file = io.open(path,"r")
        if file then
            while true do
                local num = file:read("*number")
                if not num then break end
                table.insert(exceptions_mask,num)
            end
            file:close()
        end
    end
	--printyellow("IsExsception  IsExsception:",val)
	--TODO 屏蔽客户端非法字符的判断
  --  local ret = bin_search(exceptions_mask,val)
	local ret = true
    if ret then
        printyellow("IsExsception")
    end
    return ret
end

local function IsChinese(val)
    local ret = val >= 0x4E00 and val <= 0x9FA5
    if ret then
        printyellow("IsChinese")
    end
    return ret
end

local ExpCharacters = {91,93,62,60,63,92,47,46,44,42,35,33,38,40,41,96,58,61,59}

local function IsInExpCharacters(c)
    for _,char in ipairs(ExpCharacters) do
      if c == char then
        return true
      end
    end
    return false
end

local function IsCharacter(bt)
    local ret = (bt>=48 and bt<=57) or (bt>=65 and bt <=90) or (bt>=97 and bt<=122) or IsInExpCharacters(bt)
    if ret then
        printyellow("IsCharacter")
    end
    return ret
end

local function get_bytes_value(bytes,len)
    local ret = 0
    local msk = 0x3F
    ret = bit.band(bytes[1],value_masks[len])
    for i=2,len do
        ret = bit.lshift(ret,6)
        ret = bit.bor(ret,bit.band(bytes[i],msk))
    end
    return ret
end

local function ReadFile(filepath,bNotCreate)

	print("+++++++++++++++++++++++++ReadTxt+++++++++++++++++++++++++++++++++++++++")
	print(filepath)
	local file = io.open(filepath,"rb")
	if file == nil then
		printyellow(string.format("{0}.txt ReadTxt is nil"),filepath)
		file = io.open(filepath,"w+")
	end
	
	local targetstring = file:read("*a")
	io.close(file)
	return targetstring
end

local function WriteFile(filepath,content)

	local file = io.open(filepath,"w+")
	if file == nil then
			printyellow(string.format("{0}.txt WriteTxt is nil"),filepath)
	end	
	local targetstring = file:write(content)
	print(targetstring)
	io.close(file)

end

local function CheckName(name)
    name = string.gsub(name,"%[%a%]","")
	
    name = string.gsub(name,"%[%a%a%]","")
	
    name = string.gsub(name,"%[%x%x%x%x%x%x%]","")
	
    local errmgr =  require"assistant.errormanager"

    local len = 0
    local k = 1
    while(k<=#name) do
        local bt = string.byte(name,k)

        if not bt then break end
        if len == 6 then
            exceptions_mask = nil
            return false , errmgr.GetErrorText(2803)
        end
        if IsCharacter(bt) then
            len = len + 1
        else
            code_len = 0
            for i=6,1,-1 do
                if bit.band(masks[i],bt) == masks[i] then
                    code_len = i
                    break
                end
            end
            local bytes = {bt}
            if code_len > 0 then
                for i=2,code_len do
                    local sbt = string.byte(name,k+i-1)
                    table.insert(bytes,sbt)
                end
                local val = get_bytes_value(bytes,code_len)
				
                if IsChinese(val) or IsExsception(val) then
                    k = k + code_len - 1
                    len = len + 1
                else
                    exceptions_mask = nil
					printyellow("key K:",k)
                    return false ,LocalString.ERR_ILLEAGE_NAME
                end
            else
                exceptions_mask = nil
                return false ,LocalString.ERR_WRONG_NAME
            end
        end
        k = k + 1
    end
    exceptions_mask = nil
    return true,name
end

----
--判断文件是否存在
local function IsValidBrace(str)
    local leftnum = 0
    local index = 1
    while index <= string.len(str) do
        if string.sub(str,index,index) == "{" then
            leftnum = leftnum + 1
        end
        if string.sub(str,index,index) == "}" then
            leftnum = leftnum - 1
        end
        if leftnum < 0 then
            return false
        end
        index = index + 1
    end
    return true
end

---
--读取文件中Table
local function StringToTable(str)
    local Table = { }
    if str == nil then
        printyellowmodule(Local.LogModuals.SettingManager,"This is a nil string")
    end

    if type(str) == "string" then
        local str1 = string.gsub(str,"({)(%d+)(=)","%1[%2]%3")
        local str2 = string.gsub(str1,"(,)(%d+)(=)","%1[%2]%3")
		print(str2)
		
        Table, err = assert(loadstring("return " .. str2))()
		
        if not Table then
            printyellowmodule(Local.LogModuals.SettingManager,err)
        end
        return Table
    else
        return Table
    end
end

nowTime = {}

return {
  bytes_to_string = bytes_to_string,
  array_to_set = array_to_set,
  strtime = strtime,
  strtime1 = strtime1,
  strtime_inday = strtime_inday,
  deep_copy_to = deep_copy_to,
  shallow_copy_to = shallow_copy_to,
  clear_table = clear_table,
  tolong = tolong,
  get_or_create = get_or_create,
  xpcall = my_xpcall,
  copy_table = copy_table,
  create_obj = create_obj,
  insidepolygon=insidepolygon,
  insideAnyPolygon=insideAnyPolygon,
  getenumname = getenumname,
  SetParticleSystemScale = SetParticleSystemScale,
  table_sort             = table_sort,
  CompareList = CompareList,
  table_count = table_count,
  table_sub_condition = table_sub_condition,
  table_sub_count = table_sub_count,
  SetDefaultComponent = SetDefaultComponent,
  ReadFile = ReadFile,
  WriteFile = WriteFile,
  CheckName = CheckName,
  IsValidBrace = IsValidBrace,
  StringToTable = StringToTable,
  nowTime = nowTime,
}
