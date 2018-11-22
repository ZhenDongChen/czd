local PlotDefine = require("plot.base.plotdefine");

local EventTransform = {}

function EventTransform.StartFunction(this)
    if this.TargetObject == nil then
        return
    end
    if this.ScaleVary then
        this.TargetObject.transform.localScale = this.LocalScale
    end
    if this.PositionVary then
        this.TargetObject.transform.position = this.Position
    end
    if this.RotationVary then
        this.TargetObject.transform.rotation = Quaternion.Euler(this.Rotation.x,this.Rotation.y,this.Rotation.z)
    end
    this.CurrentState = PlotDefine.ElementState.Started;
end