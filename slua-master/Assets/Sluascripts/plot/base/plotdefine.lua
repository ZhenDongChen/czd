local ElementState={
	Created=0,
	Inited=1,
	Loaded=2,
	FadeIn=3,
	Started=4,
	Looping=5,
	Ended=6,
	FadeOut=7,
	Destroyed=6,
}



local PlayStateType = {
	Stop 	= 0,
	Play 	= 1,
	Pause 	= 2,
}

local StateType = {
	Create 	= 0,
	Init 	= 1,
	Load 	= 2,
	Start 	= 3,
	Loop 	= 4,
	End 	= 5,
	Ended 	= 6,
	Destroy = 7,
}

local AssetType = {
	Model = 0,
	Animator = 1,
	Animation = 2,
	Audio = 3,
}
local AssetState = {
	Inited = 0,
	Loading = 1,
	Finish = 2,
	Failed = 3,
}


return {
	ElementState 	= ElementState,
	PlayStateType 	= PlayStateType,
	StateType 		= StateType,
	AssetState		= AssetState,
}
