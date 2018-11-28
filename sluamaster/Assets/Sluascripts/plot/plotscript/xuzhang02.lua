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
	Duration = 10,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "fenghuangfly",
	},
	Title = "xuzhang02",
	EndTime = 10,
	Type = "PlotDirector.PlotCutscene",
	ParentId = -1,
	PlotElements = {
		[1] = {
			MaskName = "Blockbar",
			Mode = "FadeIn",
			MaskValue = 1,
			MaskColor = Color(0,0,0,1),
			StartTime = 0,
			Duration = 0.5,
			CurrentState = 5,
			Title = "Mask",
			EndTime = 0.5,
			Type = "PlotDirector.PlotEventCameraMask",
			ParentId = 4,
		},
		[2] = {
			IndexName = "fenghuangfly",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(24.6,24.7,-10),
			Rotation = Vector3(0,0,0),
			LocalScale = Vector3(1,1,1),
			ObjectName = "FH",
			StartTime = 0,
			Duration = 10,
			CurrentState = 5,
			Title = "Object Create",
			EndTime = 10,
			Type = "PlotDirector.PlotEventObjectCreate",
			ParentId = 3,
		},
		[3] = {
			ProfessionDeviation = false,
			PositionVary = true,
			RotationVary = true,
			ScaleVary = true,
			Position = Vector3(26,28,-1000),
			Rotation = Vector3(0,0,0),
			LocalScale = Vector3(1,1,1),
			StartTime = 0,
			Duration = 0.1,
			CurrentState = 5,
			Title = "Transform",
			EndTime = 0.1,
			Type = "PlotDirector.PlotEventCameraTransform",
			ParentId = 1,
		},
		[4] = {
			ProfessionDeviation = false,
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
					Position = Vector3(26,28,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(26,28,-1000),
					OutTangent = Vector3(26,28,-1000),
				},
				[2] = {
					NodeTime = 2,
					Position = Vector3(21.52,22.32,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(21.52,22.32,-1000),
					OutTangent = Vector3(21.52,22.32,-1000),
				},
				[3] = {
					NodeTime = 3.5,
					Position = Vector3(30.15,23.69,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(30.15,23.69,-1000),
					OutTangent = Vector3(30.15,23.69,-1000),
				},
				[4] = {
					NodeTime = 4.5,
					Position = Vector3(27.8,31.25,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(27.8,31.25,-1000),
					OutTangent = Vector3(27.8,31.25,-1000),
				},
				[5] = {
					NodeTime = 6,
					Position = Vector3(20.02,30.05,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(20.02,30.05,-1000),
					OutTangent = Vector3(20.02,30.05,-1000),
				},
				[6] = {
					NodeTime = 7,
					Position = Vector3(21.07,22.7,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(21.07,22.7,-1000),
					OutTangent = Vector3(21.07,22.7,-1000),
				},
				[7] = {
					NodeTime = 8.5,
					Position = Vector3(28.37,23.96,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(28.37,23.96,-1000),
					OutTangent = Vector3(28.37,23.96,-1000),
				},
				[8] = {
					NodeTime = 9.9,
					Position = Vector3(33.32,27.86,-1000),
					Rotation = Vector3(0,0,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(33.32,27.86,-1000),
					OutTangent = Vector3(33.32,27.86,-1000),
				},
			},
			StartTime = 0.1,
			Duration = 9.9,
			CurrentState = 5,
			Title = "Path",
			EndTime = 10,
			Type = "PlotDirector.PlotEventCameraPath",
			ParentId = 1,
		},
		[5] = {
			MaskName = "Blockbar",
			Mode = "Keep",
			MaskValue = 1,
			MaskColor = Color(0,0,0,1),
			StartTime = 0.5,
			Duration = 9.5,
			CurrentState = 5,
			Title = "Mask",
			EndTime = 10,
			Type = "PlotDirector.PlotEventCameraMask",
			ParentId = 4,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene