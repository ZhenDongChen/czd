
--[[
	把二进制字符串编码成ASCII字符串
	简单而言,就是把每个byte编码成两个字符,
	为什么不用base64？因为实现都比较复杂比较慢
--]]

local schar = string.char
local sbyte = string.byte
local insert = table.insert
local concat = table.concat

local mod = math.fmod
local floor = math.floor

local function encode(d)
	local s = {sbyte(d, 1, #d)}
	for i = 1, #d do
		local b = s[i]
		local low = mod(b, 16) + 65
		local high = floor(b/16) + 65
		s[i] = schar(high, low)
	end
	return concat(s)
end

local function decode(d)
	local s= {}
	for i = 1, #d, 2 do
		local high, low = sbyte(d, i, i+1)
		insert(s, schar((high - 65) * 16 + low - 65))
	end
	return concat(s)
end


local b = {}
for i = 0, 255 do
	insert(b, i)
end 
local s = schar(unpack(b))
local v = encode(s)
local u = decode(v)
assert(s == u)

return {
	encode = encode,
	decode = decode,
}