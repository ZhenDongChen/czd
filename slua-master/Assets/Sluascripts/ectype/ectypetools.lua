local print = print
local require = require

local function Cross2(v1,v2)
    local tmp = v1.x*v2.y-v1.y*v2.x
    if tmp>0 then return 1
    elseif tmp<0 then return -1
    else return 0
    end
end

local function Cross(p1,p2,position)
    local v1= p2-p1
    local v2= position - p1
    return Cross2(v1,v2)
end

local function CheckInTheArea(pos,vertices)
    --local symbol = 0
    --for i,v in ipairs(vertices) do
    --    local tp1,tp2 = vertices[i],vertices[i==#vertices and 1 or i+1]
    --    local p1=Vector3(tp1.x,tp1.y,tp1.z)
    --    local p2=Vector3(tp2.x,tp2.y,tp2.z)
    --    local tmp = Cross(p1,p2,pos)
    --    if symbol == 0 then
    --        symbol = tmp
    --    elseif tmp~=0 and symbol~=0 and tmp~=symbol then
    --        return false
    --    end
    --end
    --return true
    local crossings = 0
    for i,v in ipairs(vertices) do
        local tp1,tp2 = vertices[i],vertices[i==#vertices and 1 or i+1]
        local p1=Vector2(tp1.x,tp1.y)
        local p2=Vector2(tp2.x,tp2.y)
        local slope = (p2.y - p1.y)/(p2.x-p1.x)
        local con1 = pos.x >= p1.x and pos.x <= p2.x
        local con2 = pos.x >= p2.x and pos.x <= p1.x
        local above = (pos.y<slope*(pos.x-p1.x)+p1.y)

        if (con1 or con2) and  above then
            crossings = crossings + 1
        end
    end
    return crossings%2 ~= 0
end

local function GetMidPoint(vertices)
    local x,y,z
    x=0
    y=0
    z=0
    local cnt=0
    for i,v in pairs(vertices) do
        x=x+v.x
        y=y+v.y
        z=z+v.z
        cnt=cnt+1
    end
    x=x/cnt
    y=y/cnt
    z=z/cnt
    return Vector3(x,y,z)
end

local function GetFixedTime(time)
    local total = math.floor(time)
    local h = math.floor(total/3600)
    local m = math.floor(total/60) - h*60
    local s = math.floor(total - h*3600 - m*60)
    return h,m,s
end

return {
    Cross = Cross,
    Cross2 = Cross2,
    CheckInTheArea = CheckInTheArea,
    GetMidPoint = GetMidPoint,
    GetFixedTime = GetFixedTime,
}
