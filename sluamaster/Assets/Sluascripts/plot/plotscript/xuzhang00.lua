local Plot = require("plot.plot")

PlotCutscene = {
	PlayRate = 1,
	config = {
		isLooping = false,
		isSkippable = true,
		independentMusic = true,
		hideUI = true,
		hideCharacter = true,
		showBorder = true,
		showCurtain = true,
		fadeInOutTime = 0.7,
		mainCameraControl = true,
		previewMode = false,
	},
	StartTime = 0,
	Duration = 12,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "ui_zimu",
	},
	Title = "xuzhang00",
	EndTime = 12,
	Type = "PlotDirector.PlotCutscene",
	ParentId = -1,
	PlotElements = {
		[1] = {
			IndexName = "ui_zimu",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(0,0,-1),
			Rotation = Vector3(0,0,0),
			LocalScale = Vector3(1,1,1),
			ObjectName = "ZM",
			StartTime = 0,
			Duration = 1,
			CurrentState = 5,
			Title = "Object Create",
			EndTime = 1,
			Type = "PlotDirector.PlotEventObjectCreate",
			ParentId = 3,
		},
		[2] = {
			ProfessionDeviation = false,
			PositionVary = true,
			RotationVary = true,
			ScaleVary = true,
			Position = Vector3(0,0,-1000),
			Rotation = Vector3(0,0,0),
			LocalScale = Vector3(1,1,1),
			StartTime = 0,
			Duration = 1,
			CurrentState = 5,
			Title = "Transform",
			EndTime = 1,
			Type = "PlotDirector.PlotEventCameraTransform",
			ParentId = 1,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene