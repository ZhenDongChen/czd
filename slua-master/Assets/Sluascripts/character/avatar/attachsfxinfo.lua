local attachsfxinfo = Class:new()

attachsfxinfo.EquipSfxType = enum{
    "WEAPON = 1",
    "WEAPON_LEFT",
    "CLOTH",
    "COUNT",
}

function attachsfxinfo:__new()
    self.sfxId 			= nil
	self.sfxType        = nil
	self.sfxFileName    = nil
    self.attachPoint 	= nil			
    self.sfxObject	    = nil
end

function attachsfxinfo:Release()
    self.sfxId 			= nil
	self.sfxType        = nil
	self.sfxFileName    = nil
    self.attachPoint 	= nil
    if self.sfxObject then
        GameObject.Destroy(self.sfxObject)
        self.sfxObject=nil
    end
end
 
return attachsfxinfo
