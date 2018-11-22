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
	Duration = 1.8,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_08",
	EndTime = 1.8,
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
					Position = Vector3(12.91,20.63,-100),
					Rotation = Vector3(300,180,97.8),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(12.91,20.63,-100),
					OutTangent = Vector3(12.91,20.63,-100),
				},
				[2] = {
					NodeTime = 0.4,
					Position = Vector3(16.74,19.44,-100),
					Rotation = Vector3(299.9999,180,82.25),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(16.74,19.44,-100),
					OutTangent = Vector3(16.74,19.44,-100),
				},
				[3] = {
					NodeTime = 1.1,
					Position = Vector3(27.11,19.5,-100),
					Rotation = Vector3(300,180,59.95),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(27.11,19.5,-100),
					OutTangent = Vector3(27.11,19.5,-100),
				},
				[4] = {
					NodeTime = 1.4,
					Position = Vector3(29.62,20.22,-100),
					Rotation = Vector3(300,180,3.6),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(29.62,20.22,-100),
					OutTangent = Vector3(29.62,20.22,-100),
				},
				[5] = {
					NodeTime = 1.8,
					Position = Vector3(29.5,22.3,-100),
					Rotation = Vector3(299.9999,180,347.98),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(29.5,22.3,-100),
					OutTangent = Vector3(29.5,22.3,-100),
				},
			},
			StartTime = 0,
			Duration = 1.8,
			CurrentState = 5,
			Title = "Object Path",
			EndTime = 1.8,
			Type = "PlotDirector.PlotEventObjectPath",
			ParentId = 2,
		},
		[2] = {
			IndexName = "MainCharacter",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(12.38,20.32,-100),
			Rotation = Vector3(-60,180,0),
			LocalScale = Vector3(1,1,1),
			ObjectName = "Role",
			StartTime = 0,
			Duration = 1,
			CurrentState = 5,
			Title = "Object Special",
			EndTime = 1,
			Type = "PlotDirector.PlotEventObjectSpecialCreate",
			ParentId = 1,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene