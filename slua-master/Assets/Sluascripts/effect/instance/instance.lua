local Instance = Class:new()

function Instance:__new()
    --print("<color=yellow>Character:__new()</color>")
    self:reset()
end

function Instance:reset()
  self.Dead = false
  self.ParentEffect = nil -- class Effect
  self.Object = nil -- class GameObject
  self.Loaded = false
  self.StartTime =0
end

function Instance:Update()
  
end

function Instance:Destroy()
    self.Dead = true
end


function Instance:CheckCanShow()
  
  return true
end



return Instance