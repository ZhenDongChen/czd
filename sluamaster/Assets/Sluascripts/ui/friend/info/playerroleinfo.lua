

local PlayerRoleInfo = Class:new()

function PlayerRoleInfo:__new(serverInfo)
    --self.

end
--[[
				<variable name="idolfrienddegree" type="map" key="long" value="int" comment="跟偶像的友好度，key为偶像的id"/>
				<variable name="idolawardclaiminfo" type="map" key="long" value="IdolAwardClaim" comment="偶像奖励的领取情况，key为偶像id，value为领取情况"/>
				<variable name="relations" type="map" key="int" value="MMInfoList" commnet="伴侣的信息"/>
				<variable name="allowfriendgetmm" type="int" comment="是否允许好友查看脉脉" />
				<variable name="allowstrangergetmm" type="int" comment="是否允许陌生人查看脉脉" />
                ]]
return PlayerRoleInfo