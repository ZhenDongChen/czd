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
		fadeInOutTime = 1.3,
		mainCameraControl = true,
		previewMode = false,
	},
	StartTime = 0,
	Duration = 2,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_07",
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
					Position = Vector3(8.56,14.58,-100),
					Rotation = Vector3(299.9999,180,348.73),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(8.56,14.58,-100),
					OutTangent = Vector3(8.56,14.58,-100),
				},
				[2] = {
					NodeTime = 0.6,
					Position = Vector3(6.79,17.5,-100),
					Rotation = Vector3(300,180,359.9),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(6.79,17.5,-100),
					OutTangent = Vector3(6.79,17.5,-100),
				},
				[3] = {
					NodeTime = 0.9,
					Position = Vector3(6.8,19.7,-100),
					Rotation = Vector3(300,180,45.8),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(6.8,19.7,-100),
					OutTangent = Vector3(6.8,19.7,-100),
				},
				[4] = {
					NodeTime = 1.1,
					Position = Vector3(8.05,20.2,-98.99),
					Rotation = Vector3(300,180,41.40001),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(8.05,20.2,-98.99),
					OutTangent = Vector3(8.05,20.2,-98.99),
				},
				[5] = {
					NodeTime = 1.3,
					Position = Vector3(9.620001,21.39,-97.99),
					Rotation = Vector3(300,180,38.51),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(9.620001,21.39,-97.99),
					OutTangent = Vector3(9.620001,21.39,-97.99),
				},
			},
			StartTime = 0,
			Duration = 1.3,
			CurrentState = 5,
			Title = "Object Path",
			EndTime = 1.3,
			Type = "PlotDirector.PlotEventObjectPath",
			ParentId = 2,
		},
		[2] = {
			IndexName = "MainCharacter",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(9.1,14.55,-108.4),
			Rotation = Vector3(300,180,-1.707548E-06),
			LocalScale = Vector3(1,1,1),
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