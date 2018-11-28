local PlotDefine        = require("plot.base.plotdefine") 
local PlotAsset = Class:new()

function PlotAsset:__new(index, config, parentObject,cutscene)
    self.m_Index        = index
    self.m_Config       = config
    self.m_Type         = self.m_Config.assettype
    self.m_DetailType   = self.m_Config.detailtype
    self.m_State        = PlotDefine.AssetState.Inited
end

function PlotAsset:IsReady()
    return true
end

function PlotAsset:Destroy()
    return true
end

function PlotAsset:GetState()
    return self.m_State
end 

function PlotAsset:GetType()
    return self.m_Type, self.m_DetailType
end

return PlotAsset