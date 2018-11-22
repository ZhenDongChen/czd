local Character = require "character.character"
local ConfigManager = require "cfg.configmanager"
local Utils=require"common.utils"
local MathUtils=require"common.mathutils"
local DefineEnum = require "defineenum"
local CharacterType = DefineEnum.CharacterType
local NetWork=require"network"
local UIManager=require"uimanager"
local SceneManager=require"scenemanager"
local PlayerRole=require"character.playerrole"
local Define = require("define")
local ResourceManager = require("resource.resourcemanager")

local ReAlertTime=5     --传送提示间隔
local ReTransferTime=1   --传送协议发送间隔

local AppearDis=50*SCALE_SPEED   --传送门显示距离
local MissDis=70*SCALE_SPEED     --传送门消失距离

local Portal = Class:new(Character)

function Portal:__new()
    Character.__new(self)
    self.m_Type = CharacterType.Portal
    self.m_Inside=false
    self.m_NeddHideEffect=false
end

function Portal:init(id,csvid)
    self.m_Id=id
    local CharacterManager=require"character.charactermanager"
    local warp=CharacterManager.GetWarp(id)
    if warp then
        self.m_Circle= {}
		self.m_Circle.radius = warp.circle.radius
		self.m_Circle.center = Vector3(warp.circle.center.x * SCALE_XY, warp.circle.center.y * SCALE_XY, 0);
        self.m_Name=warp.name
        self.m_Portal=warp.portal
        self.m_EffectPos=warp.effectPos
        self.m_EffectRotation=warp.effectRotation
        if self.m_Portal.effecttype==DefineEnum.PortalEffectType.STEREO then
            self.m_EffectName = cfg.map.Portal.portalindex1
        elseif self.m_Portal.effecttype==DefineEnum.PortalEffectType.GROUND then
            self.m_EffectName = cfg.map.Portal.portalindex2
        elseif self.m_Portal.effecttype==DefineEnum.PortalEffectType.HIDE then
            self.m_EffectName = cfg.map.Portal.portalindex1
            self.m_NeddHideEffect=true
        end
    end
end

function Portal:AddModel()
    self.m_Loading=true
    ResourceManager.LoadObject(self.m_EffectName, nil, function(asset_obj)
                if IsNull(asset_obj) then
                    return
                end
                self.m_Object=asset_obj
                self.m_Loading=nil
                local characterManagerObject = CharacterManager.GetCharacterManagerObject()
                if characterManagerObject ~= nil then
                    self.m_Object.transform:SetParent(characterManagerObject.transform)
                end
                if self.m_NeddHideEffect==true then
                    for i=0,(self.m_Object.transform.childCount-1) do
                        self.m_Object.transform:GetChild(i).gameObject:SetActive(false)
                    end
                end
                if self.m_EffectPos then
                    self.m_Object.transform.localPosition = self.m_EffectPos
                    self.m_Object.transform.localEulerAngles=Vector3(0, 0, self.m_EffectRotation)
                    if self.m_Portal.displaytext==true then
                        Util.Load("ui/dlgtransport_title.ui", define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
                            if IsNull(asset_obj) then
                                return
                            end
                            local nameObject = GameObject.Instantiate(asset_obj)
                            ExtendedGameObject.SetLayerRecursively(nameObject, Define.Layer.LayerDefault)
                            local m_UIName = nameObject.transform:Find("UILabel_Name"):GetComponent("UILabel")
                            m_UIName.text=self.m_Name
                            m_UIName.transform.gameObject:SetActive(true)
                            nameObject.transform:SetParent(self.m_Object.transform)
                            local posY=1.3  --传送门特效高度
                            if self.m_NeddHideEffect==true then
                                posY=0
                            end
                            nameObject.transform.localScale=Vector3(0.02,0.02,0.02)
                            nameObject.transform.localPosition=Vector3(0,posY,0)
                            self.m_NameObject=nameObject
                        end)
                    end
                end
                self.m_Object:SetActive(true)
            end)
end

function Portal:update()
    if self.m_Object then
        if MathUtils.DistanceOfXoY(self.m_Circle.center,PlayerRole:Instance():GetRefPos())<=MissDis then
            if (MathUtils.DistanceOfXoY(self.m_Circle.center,PlayerRole:Instance():GetRefPos())<=((self.m_Circle.radius * SCALE_XY) + 70))  and ((not PlayerRole:Instance():IsNavigating()) or (PlayerRole:Instance():IsNavigating() and PlayerRole:Instance().m_NavigateToWarp==true) or (self.m_Portal.transmode==1)) then
                if not self.m_Inside then
                    local dstMapId=self.m_Portal.dstworldmapid
                    local dstMapData=ConfigManager.getConfigData("worldmap",dstMapId)
                    self.m_Inside=true
                    if PlayerRole:Instance():GetLevel()<dstMapData.openlevel then
                        self.m_ReEnterTime=ReAlertTime
                        UIManager.ShowSingleAlertDlg({content=string.format(LocalString.WorldMap_EnterWorld,dstMapData.openlevel,dstMapData.mapname)})
                    else
						local taskmanager = require "taskmanager"
						local status = taskmanager.GetTaskStatus(self.m_Portal.donetask)
						if status ~= DefineEnum.TaskStatusType.Completed and self.m_Portal.donetask > 0 then
							self.m_ReEnterTime=ReAlertTime
						else
							self.m_ReEnterTime=ReTransferTime
							if PlayerRole:Instance().m_NavigateToWarp==true then
								PlayerRole:Instance().m_NavigateToWarp=nil
								PlayerRole:Instance():stop()
							end
							Game.JoyStickManager.singleton:Reset()
							if self.m_Portal.transmode==DefineEnum.PortalTransMode.FLY then
								local endPos=Vector3((self.m_Portal.dstregion.x),(self.m_Portal.dstregion.y),0)
								PlayerRole:Instance():StartPathFly(self.m_Portal.pathid, endPos, self.m_Portal.srcregionid)
							elseif self.m_Portal.transmode==DefineEnum.PortalTransMode.DIRECT then
								local message=map.msg.CTransferWorld({portalid=self.m_Portal.srcregionid})
								NetWork.send(message)
							end
						end
						
                    end
                else
                    self.m_ReEnterTime=self.m_ReEnterTime-Time.deltaTime
                    if self.m_ReEnterTime<=0 then
                        self.m_Inside=false
                    end
                end
            end
            if MathUtils.DistanceOfXoY(self.m_Circle.center,PlayerRole:Instance():GetRefPos())<=AppearDis then
                if not IsNull(self.m_NameObject) then
                    self.m_NameObject.transform.localRotation = cameraTransform.rotation
                end
            end
        else
            self:DestroyObject()
			self.m_Loading = false;
        end
    elseif self.m_Loading~=true then
        if MathUtils.DistanceOfXoY(self.m_Circle.center,PlayerRole:Instance():GetRefPos())<=AppearDis then
            self:AddModel()
        end
    end
end

return Portal
