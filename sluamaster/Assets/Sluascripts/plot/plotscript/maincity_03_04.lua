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
	Duration = 2.2,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_04",
	EndTime = 2.2,
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
					Position = Vector3(43.74,35.06,-100),
					Rotation = Vector3(299.9999,180,39.75),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(43.74,35.06,-100),
					OutTangent = Vector3(43.74,35.06,-100),
				},
				[2] = {
					NodeTime = 0.6,
					Position = Vector3(48.57,37.66,-100),
					Rotation = Vector3(300,180,203.92),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(48.57,37.66,-100),
					OutTangent = Vector3(48.57,37.66,-100),
				},
				[3] = {
					NodeTime = 1.2,
					Position = Vector3(43.51,31.53,-100),
					Rotation = Vector3(299.9999,180,170.83),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(43.51,31.53,-100),
					OutTangent = Vector3(43.51,31.53,-100),
				},
				[4] = {
					NodeTime = 2.2,
					Position = Vector3(46.14,18.41,-106.91),
					Rotation = Vector3(300,180,156.11),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(46.14,18.41,-106.91),
					OutTangent = Vector3(46.14,18.41,-106.91),
				},
			},
			StartTime = 0,
			Duration = 2.2,
			CurrentState = 5,
			Title = "Object Path",
			EndTime = 2.2,
			Type = "PlotDirector.PlotEventObjectPath",
			ParentId = 2,
		},
		[2] = {
			IndexName = "MainCharacter",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(0,0,0),
			Rotation = Vector3(0,0,0),
			LocalScale = Vector3(0.75,0.75,0.75),
			ObjectName = "Role",
			StartTime = 0,
			Duration = 1,
			CurrentState = 5,
			Title = "object_special",
			EndTime = 1,
			Type = "PlotDirector.PlotEventObjectSpecialCreate",
			ParentId = 1,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene