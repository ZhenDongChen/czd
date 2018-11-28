local Plot = require("plot.plot")

PlotCutscene = {
	PlayRate = 1,
	config = {
		isLooping = false,
		isSkippable = false,
		independentMusic = true,
		hideUI = false,
		hideCharacter = false,
		showBorder = true,
		showCurtain = false,
		fadeInOutTime = 0.7,
		mainCameraControl = true,
		previewMode = false,
	},
	StartTime = 0,
	Duration = 2.59,
	CurrentState = 5,
	AssetIndexList = {
		[1] = "MainCharacter",
	},
	Title = "maincity_03_0111",
	EndTime = 2.59,
	Type = "PlotDirector.PlotCutscene",
	ParentId = -1,
	PlotElements = {
		[1] = {
			IndexName = "MainCharacter",
			Active = true,
			SetParent = false,
			ParentName = "",
			SetTrans = true,
			Position = Vector3(58.61,63,-100),
			Rotation = Vector3(-60,180,0),
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
		[2] = {
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
					Position = Vector3(58.3,62.84,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(58.3,62.84,-100),
					OutTangent = Vector3(58.3,62.84,-100),
				},
				[2] = {
					NodeTime = 0.5376455,
					Position = Vector3(57.48,63.41,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(57.48,63.41,-100),
					OutTangent = Vector3(57.48,63.41,-100),
				},
				[3] = {
					NodeTime = 1.17393,
					Position = Vector3(56.71,63.61,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(56.71,63.61,-100),
					OutTangent = Vector3(56.71,63.61,-100),
				},
				[4] = {
					NodeTime = 1.384917,
					Position = Vector3(56.1,63.43,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(56.1,63.43,-100),
					OutTangent = Vector3(56.1,63.43,-100),
				},
				[5] = {
					NodeTime = 1.543553,
					Position = Vector3(55.18,63.22,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(55.18,63.22,-100),
					OutTangent = Vector3(55.18,63.22,-100),
				},
				[6] = {
					NodeTime = 1.691543,
					Position = Vector3(54.53,62.69,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.53,62.69,-100),
					OutTangent = Vector3(54.53,62.69,-100),
				},
				[7] = {
					NodeTime = 1.867363,
					Position = Vector3(54.25,61.57,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.25,61.57,-100),
					OutTangent = Vector3(54.25,61.57,-100),
				},
				[8] = {
					NodeTime = 2.020546,
					Position = Vector3(54.21,60.7,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.21,60.7,-100),
					OutTangent = Vector3(54.21,60.7,-100),
				},
				[9] = {
					NodeTime = 2.188045,
					Position = Vector3(54.45,59.68,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.45,59.68,-100),
					OutTangent = Vector3(54.45,59.68,-100),
				},
				[10] = {
					NodeTime = 2.350285,
					Position = Vector3(54.59,58.58,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.59,58.58,-100),
					OutTangent = Vector3(54.59,58.58,-100),
				},
				[11] = {
					NodeTime = 2.49,
					Position = Vector3(54.83,57.76,-100),
					Rotation = Vector3(270,26,0),
					LocalScale = Vector3(1,1,1),
					InTangent = Vector3(54.83,57.76,-100),
					OutTangent = Vector3(54.83,57.76,-100),
				},
			},
			StartTime = 0.0999999,
			Duration = 2.49,
			CurrentState = 5,
			Title = "Object Path",
			EndTime = 2.59,
			Type = "PlotDirector.PlotEventObjectPath",
			ParentId = 2,
		},
		[3] = {
			CharactorGetMode = "Type",
			CharactorId = 0,
			CharactorType = 2,
			CharactorAction = "Jump",
			RelativeCoordinates = false,
			Navigate = false,
			TargetPosition = Vector3(0,0,0),
			ActionName = "",
			SkillId = 0,
			StartTime = 0.81,
			Duration = 1,
			CurrentState = 2,
			Title = "GameActor Action",
			EndTime = 1.81,
			Type = "PlotDirector.PlotEventGameActorAction",
			ParentId = 4,
		},
	},
}
setmetatable(PlotCutscene, {__index = Plot.PlotCutscene})
return PlotCutscene