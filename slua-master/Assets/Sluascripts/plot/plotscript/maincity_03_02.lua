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
	Duration = 2.6,
	CurrentState = 3,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_02",
	EndTime = 2.6,
	Type = "PlotDirector.PlotCutscene",
	ParentId = -1,
	PlotElements = {
		[1] = {
			ObjectName = "",
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
					Position = Vector3(62.19,27.27,-100.2),
					Rotation = Vector3(300,180,295.46),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(62.19,27.27,-100.2),
					OutTangent = Vector3(62.19,27.27,-100.2),
				},
				[2] = {
					NodeTime = 0.4,
					Position = Vector3(59.99,27.83292,-100.525),
					Rotation = Vector3(300,180,212.73),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(59.99,27.83292,-100.525),
					OutTangent = Vector3(59.99,27.83292,-100.525),
				},
				[3] = {
					NodeTime = 0.9,
					Position = Vector3(57.15,25.39759,-99.5231),
					Rotation = Vector3(300,180,231.9),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(57.15,25.39759,-99.5231),
					OutTangent = Vector3(57.15,25.39759,-99.5231),
				},
				[4] = {
					NodeTime = 1.3,
					Position = Vector3(55.2,24.62434,-98.52242),
					Rotation = Vector3(300,180,166.48),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(55.2,24.62434,-98.52242),
					OutTangent = Vector3(55.2,24.62434,-98.52242),
				},
				[5] = {
					NodeTime = 1.8,
					Position = Vector3(57.32,20.35203,-97.52226),
					Rotation = Vector3(300,180,265.45),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(57.32,20.35203,-97.52226),
					OutTangent = Vector3(57.32,20.35203,-97.52226),
				},
				[6] = {
					NodeTime = 2.5,
					Position = Vector3(51.72,19.99555,-96.51971),
					Rotation = Vector3(300,180,324.03),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(51.72,19.99555,-96.51971),
					OutTangent = Vector3(51.72,19.99555,-96.51971),
				},
			},
			StartTime = 0,
			Duration = 2.5,
			CurrentState = 2,
			Title = "Object Path",
			EndTime = 2.5,
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
			LocalScale = Vector3(1,1,1),
			ObjectName = "Role",
			StartTime = 0.01,
			Duration = 1,
			CurrentState = 2,
			Title = "object_special",
			EndTime = 1.01,
			Type = "PlotDirector.PlotEventObjectSpecialCreate",
			ParentId = 1,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene