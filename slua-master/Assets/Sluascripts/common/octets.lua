require("common.class")

local ipairs = ipairs
local pairs = pairs
local loadstring = loadstring
local tostring = tostring
local error = error

local insert = table.insert
local concat = table.concat

local schar = string.char
local sbyte = string.byte
local sub = string.sub
local fmt = string.format
local sfind = string.find

local fmod = math.fmod
local floor = math.floor

local unpack = unpack

local OctetsStream = OctetsStream
local OctetsWrap = Octets.Wrap
local ToString = Slua.ToString
local ToBytes = Slua.ToBytes

local os = {}

function os.new(data)
    return OctetsStream(OctetsWrap(ToBytes(data)))
end

function os.size(self)
	return self.Remaining
end

function os.push_bool(self, x)
    self:MarshalBool(x)
end

function os.pop_bool(self, x)
    return self:UnmarshalBool()
end

function os.push_byte(self, x)
    self:MarshalSbyte(x)
end

function os.pop_byte(self)
    return self:UnmarshalSbyte()
end

function os.push_short(self, x)
    self:MarshalShort(x)
end

function os.pop_short(self)
    return self:UnmarshalShort()
end

function os.push_int(self, x)
    self:MarshalInt(x)
end

function os.pop_int(self)
    return self:UnmarshalInt()
end

function os.push_long(self, x)
    self:MarshalLong(x)
end

function os.pop_long(self)
    return self:UnmarshalLong()
end

function os.push_float(self, x)
    self:MarshalFloat(x)
end

function os.pop_float(self)
    return self:UnmarshalFloat()
end

function os.push_double(self, x)
    self:MarshalDouble(x)
end

function os.pop_double(self)
    return self:UnmarshalDouble()
end

function os.push_string(self, x)
    self:MarshalString(x)
end

function os.pop_string(self)
    return self:UnmarshalString()
end

function os.push_octets(self, x)
  self:MarshalSizeBytes(ToBytes(x))
end

function os.pop_octets(self)
    return ToString(self:UnmarshalSizeBytes())
end 

function os.push_list(self, x, valueType)
  local size = #x
  self:MarshalSize(size)
  local fun = os["push_" .. valueType]
  for i = 1, size do 
    fun(self, x[i])
  end
end

function os.pop_list(self, valueType)
  local fun = os["pop_" .. valueType]
  local r = {}
  for i = 1, self:UnmarshalSize() do
    insert(r, fun(self))
  end
  return r
end

function os.push_set(self, x, valueType)
    local size = #x
    self:MarshalSize(size)
    local fun = os["push_" .. valueType]
    for i = 1, size do
        fun(self, x[i])
    end
end 

function os.pop_set(self, valueType)
    local fun = os["pop_" .. valueType]
    local r = {}
    for i = 1, self:UnmarshalSize() do
        insert(r, fun(self))
    end
    return r
end

local function get_table_size(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end 
  return n
end

function os.push_map(self, x, keyType, valueType)
  self:MarshalSize(get_table_size(x))
  local fun_key= os["push_" .. keyType]
  local fun_value= os["push_" .. valueType]
  for k, v in pairs(x) do
    fun_key(self, k)
    fun_value(self, v)
  end
end 

function os.pop_map(self, keyType, valueType)
  local size = self:UnmarshalSize()
  local fun_key   = os["pop_" .. keyType]
  local fun_value = os["pop_" .. valueType]
  local x = {}
  for i = 1, size do 
      local k = fun_key(self)
      local v = fun_value(self)
      x[k] = v
  end
  return x
end

local raw_types = { bool = "false", byte = 0, short = 0, int = 0, long = 0, float = 0.0, double = 0.0, string = "\"\"", octets="\"\"" }
local collection_types = {list = 1, set = 1, map = 2}

function get_full_type(namespace, vtype)
	if raw_types[vtype] ~= nil or not namespace or namespace == "" or sfind(vtype, ".", 1, true) then 
		return vtype:gsub("%.", "_")
	else
		return namespace:gsub("%.", "_") .. "_" .. vtype
	end
end


function os.add_type(ns, new_type)
	local c = {}
	local name = new_type.name
	local fullname = get_full_type(ns, name)
	insert(c, "local os = require 'common.octets'")
	
	insert(c, fmt("function os.push_%s(self, x)", fullname))
	for _, var in ipairs(new_type) do
		local vname = var.name
		local vtype = var.type
		local typeNum = collection_types[vtype]
		if not typeNum then
			insert(c, fmt("os.push_%s(self, x.%s or %s)", get_full_type(ns, vtype), vname, tostring(raw_types[vtype] or "{}")))
		elseif typeNum == 1 then 
			insert(c, fmt("os.push_%s(self, x.%s or {}, '%s')", vtype, vname, get_full_type(ns, var.value)))
		else 
			insert(c, fmt("os.push_%s(self, x.%s or {}, '%s', '%s')", vtype, vname, get_full_type(ns, var.key), get_full_type(ns, var.value)))
		end
	end	
	insert(c, "end")
	
	insert(c, fmt("function os.pop_%s(self)", fullname))
	insert(c, "local x = {}")
	for _, var in ipairs(new_type) do
		local vname = var.name
		local vtype = var.type
		local typeNum = collection_types[vtype]
		if not typeNum then
			insert(c, fmt("x.%s = os.pop_%s(self)", vname, get_full_type(ns, vtype)))
		elseif typeNum == 1 then 
			insert(c, fmt("x.%s = os.pop_%s(self, '%s')", vname, vtype, get_full_type(ns, var.value)))
		else 
			insert(c, fmt("x.%s = os.pop_%s(self, '%s', '%s')", vname, vtype, get_full_type(ns, var.key), get_full_type(ns, var.value)))
		end
	end	
	insert(c, "return x")
	insert(c, "end")
	local code = concat(c, "\n")
	local ret ,err = loadstring(code)
	if not ret then
	 print("add_type:", fullname, "fail.", ret, err)
	else
	 ret()	 
	end	
end
return os
