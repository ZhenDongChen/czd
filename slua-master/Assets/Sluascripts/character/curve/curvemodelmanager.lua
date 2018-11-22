local CurveData=require"character.curve.curvedata"
local DefineEnum=require"defineenum"
local CurveType=DefineEnum.TraceType

local m_CurveDatas={}
local m_CurveBuffer={}
local m_CurveDelete={}

local function AddCurveData(moveObject,callBackFunc,curveType,targetPos)
    if moveObject==nil then
        return
    end
    if curveType==nil then
        curveType=CurveType.Line
    end
    local curveData=CurveData:new()
    curveData:init({object=moveObject,callBack=callBackFunc,useTime=2,itemHeight=0,curveType=curveType,targetPos=targetPos})
    table.insert(m_CurveBuffer,curveData)    
end

local function AddCurveDatas()
    if (#m_CurveBuffer> 0) then
        for _,curveData in ipairs(m_CurveBuffer) do
            table.insert(m_CurveDatas,curveData)
        end
        m_CurveBuffer={}
    end
end

local function UpdateCurrentCurveDatas()
    for _,curveData in ipairs(m_CurveDatas) do
        if (curveData:LoadFinished()) then
            if (not (curveData:FlyFinished())) then
                curveData:update(Time.deltaTime)
            else
                table.insert(m_CurveDelete,curveData)
            end
        end
    end
    for _,curveData in ipairs(m_CurveDelete) do
        local i=1
        for _,oldCurveData in ipairs(m_CurveDatas) do
            if curveData==oldCurveData then
                table.remove(m_CurveDatas,i)
                break
            end
            i=i+1
        end
    end
end

local function DestoryCurveDatas()
    for _,curveData in ipairs(m_CurveDelete) do
        curveData:Destory()
    end
    utils.clear_table(m_CurveDelete)          
end

local function Update()
    AddCurveDatas()
    UpdateCurrentCurveDatas()
    DestoryCurveDatas()
end

local function init()
    gameevent.evt_update:add(Update)
end



return
{
    AddCurveData=AddCurveData, 
    init=init,
}