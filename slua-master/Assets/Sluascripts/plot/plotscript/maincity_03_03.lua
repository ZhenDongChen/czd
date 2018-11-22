local Plot = require("plot.plot")

PlotCutscene = {
	PlayRate = 1,
	config = {
		isLooping = false,
		isSkippable = false,
		independentMusic = false,
		hideUI = false,
		hideCharacter = false,
		showBorder = true,
		showCurtain = false,
		fadeInOutTime = 0.7,
		mainCameraControl = true,
		previewMode = false,
	},
	StartTime = 0,
	Duration = 2,
	CurrentState = 4,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_03",
	EndTime = 2,
	Type = "PlotDirector.PlotCutscene",
	ParentId = -1,
	PlotElements = {
		[1] = {
			ObjectName = "Role",
			OnGround = false,
			OffSetY = 0,
			PathMode = "Bessel",
			TangentMode = false,
			PositionVary = true,
			RotationVary = true,
			ScaleVary = true,
			ConstSpeed = false,
			Speed = 7,
			PathList = {
				[1] = {
					NodeTime = 0,
					Position = Vector3(40.98,54.13,-100),
					Rotation = Vector3(299.9999,180,143.04),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(40.98,54.13,-100),
					OutTangent = Vector3(40.98,54.13,-100),
				},
				[2] = {
					NodeTime = 1,
					Position = Vector3(46.66,50.2,-103.83),
					Rotation = Vector3(299.9999,180,157),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(46.66,50.2,-103.83),
					OutTangent = Vector3(46.66,50.2,-103.83),
				},
				[3] = {
					NodeTime = 2,
					Position = Vector3(48.178,43.634,-98.462),
					Rotation = Vector3(300,180,125.2),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(48.178,43.634,-98.462),
					OutTangent = Vector3(48.178,43.634,-98.462),
				},
			},
			StartTime = 0,
			Duration = 2,
			CurrentState = 4,
			Title = "Object Path",
			EndTime = 2,
			Type = "PlotDirector.PlotEventObjectPath",
			ParentId = 2,
		},
		[2] = {
			IndexName = "MainCharacter",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(40.92,54.27,-100),
			Rotation = Vector3(-60,180,0),
			LocalScale = Vector3(1,1,1),
			ObjectName = "Role",
			StartTime = 0,
			Duration = 1,
			CurrentState = 4,
			Title = "Object Special",
			EndTime = 1,
			Type = "PlotDirector.PlotEventObjectSpecialCreate",
			ParentId = 1,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene