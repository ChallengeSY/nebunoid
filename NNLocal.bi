const NumHints = 4
const TrapThreshold = 200
const CheatScore = 20000000
const LevelsPerPage = 28
dim shared as string CampaignName, CampaignLevelName, CampaignPassword, LevelDescription
dim shared as ushort StartingLives, HighLevel, CampaignBricks, _
	SecretLevels, AttackBricks
dim shared as integer BaseCapsuleValue, PowerTick, PaddleHealth, InitialExtraLife, SubsequentExtraLives, LevelTimeLimit
dim shared as short SpeedMod, BackIter
dim shared as ubyte CapID, ExtraBarrierPoint, GameHints(NumHints), LevelDesc, ContinuousSplit
dim shared as byte PaddleAdjust
dim shared as double ActiveDifficulty, AttackTick, BaseMaxSpeed

redim shared as integer ShuffleList(1)
dim shared as integer EndlessShuffList(TotalOfficialLevels)

BackIter = irandom(0,BacksLoaded-1)

sub applyDiffSpecs
	/'
    ' General rule of thumb; the higher the difficulty,
    ' the faster the gameplay, and the smaller the paddle/balls
	 '/
	ActiveDifficulty = PlayerSlot(Player).Difficulty
	if CampaignFolder = EndlessFolder AND ActiveDifficulty < 6.5 then
		ActiveDifficulty = min(max(PlayerSlot(Player).LevelNum^(1/2),ActiveDifficulty),6.5)
	end if
	
	BaseMaxSpeed = 20.5
	select case int(ActiveDifficulty+0.5)
		case DIFF_KIDS
			BaseMaxSpeed = 16.5
			MinSize = PAD_LG
			StandardSize = PAD_2XL
			MaxSize = PAD_3XL
			BallSize = BALL_LG
		case DIFF_VEASY
			BaseMaxSpeed = 16.5
			MinSize = PAD_LG
			StandardSize = PAD_XL
			MaxSize = PAD_3XL
			BallSize = BALL_LG
		case DIFF_EASY
			BaseMaxSpeed = 16.5
			MinSize = PAD_MED
			StandardSize = PAD_XL
			MaxSize = PAD_3XL
			BallSize = BALL_LG
		case DIFF_MEASY
			MinSize = PAD_MED
			StandardSize = PAD_LG
			MaxSize = PAD_2XL
			BallSize = BALL_MED
		case DIFF_MEDIUM
			MinSize = PAD_SM
			StandardSize = PAD_LG
			MaxSize = PAD_XL
			BallSize = BALL_MED
		case DIFF_MHARD
			MinSize = PAD_SM
			StandardSize = PAD_MED
			MaxSize = PAD_XL
			BallSize = BALL_MED
		case DIFF_HARD
			MinSize = PAD_XS
			StandardSize = PAD_MED
			MaxSize = PAD_XL
			BallSize = BALL_MED
		case DIFF_VHARD
			MinSize = PAD_XS
			StandardSize = PAD_MED
			MaxSize = PAD_LG
			BallSize = BALL_SM
		case DIFF_EXTREME
			MinSize = PAD_XS
			StandardSize = PAD_MED
			MaxSize = PAD_MED
			BallSize = BALL_SM
		case else
			MinSize = PAD_XS
			StandardSize = PAD_SM
			MaxSize = PAD_MED
			BallSize = BALL_SM
			if PlayerSlot(Player).Difficulty >= 11 then
				BaseMaxSpeed = 20.5 + int((PlayerSlot(Player).Difficulty - 10.5) * 2)
			end if
	end select
end sub

sub adjustSpeed(BallID as short, AdjustBy as double)
	with Ball(BallID)
		if .Speed < BaseMaxSpeed then
			.Speed = min(.Speed + AdjustBy,BaseMaxSpeed)
		else
			.Speed -= .025
		end if
	end with
end sub
function convertChar(InChar as string) as integer
	dim as ubyte BrickEquiv
	InChar = ucase(InChar)
	if InChar >= "1" AND InChar <= "9" then
		BrickEquiv = valint(InChar)
	elseif InChar >= "A" AND InChar <= "Z" then
		'Convert A-Z into brushes 10 - 35
		BrickEquiv = asc(InChar) - 55
	end if
	return BrickEquiv
end function
sub uiElement(Text as string, XPos as short, YPos as short, Length as short = 0, Coloring as uinteger = rgb(255,255,255))
	if len(Text) < Length then
		gfxString(Text,XPos+(Length-len(Text))*18,YPos,5,5,3,Coloring)
	else
		gfxString(Text,XPos,YPos,5,5,3,Coloring)
	end if
end sub
sub fixFirstLevel
	with PlayerSlot(1)
		.PerfectClear = 1
		.SetCleared = 0
	end with
end sub
sub resetPaddle(OnlyGoods as byte = 0)
	applyDiffSpecs
	renderPaddle(StandardSize)
	PaddleAdjust = 0
	with PlayerSlot(Player)
		if ActiveDifficulty < 1.45 then
			.BulletAmmo = 32
		else
			.BulletAmmo = 0
		end if
		.MissileAmmo = 0
	end with
	ContinuousSplit = 0
	with Paddle(1)
		if OnlyGoods = 0 then
			.Sluggish = 0
			.Reverse = 0
		end if
		.Spawned = 0
		.Repairs = 0
		.Grabbing = 0
		.Blizzard = 0
		
		.Fireball = 0
		.Breakthru = 0
		.WeakDmg = 0
		.GravBall = 0
	end with
	HoldAction = 1
	ProgressiveBounces = 0
	ProgressiveQuota = 8
end sub
sub emptyHand(PlayerID as byte)
	if PlayerID = 0 then
		for HandID as byte = 1 to 5
			NewPlrSlot.PokerHand(HandID) = 0
		next HandID
	else
		for HandID as byte = 1 to 5
			PlayerSlot(PlayerID).PokerHand(HandID) = 0
		next HandID
	end if
end sub
sub renderHand(SlotID as byte = 0)
	dim as string GemLetters(7) => {"", "R", "G", "B", "Y", "P", "C", "W"}
	dim as byte GemFound
	
	if SlotID > 0 then
		GemFound = PlayerSlot(Player).PokerHand(SlotID)
		if GemFound > 0 AND GemFound <= 7 then
			bload(MasterDir + "/gfx/caps/gem" + GemLetters(GemFound) + ".bmp",PokerBar(SlotID))
		else
			line PokerBar(SlotID),(0,0)-(37,18),rgb(255,0,255),bf
		end if
	else
		for HandID as byte = 1 to 5
			GemFound = PlayerSlot(Player).PokerHand(HandID)
			if GemFound > 0 AND GemFound <= 7 then
				bload(MasterDir + "/gfx/caps/gem" + GemLetters(GemFound) + ".bmp",PokerBar(HandID))
			else
				line PokerBar(HandID),(0,0)-(37,18),rgb(255,0,255),bf
			end if
		next HandID
	end if
end sub
function scoreHand as short
	dim as byte ColorCounts(7), PrimaryColor, HighestCounts(1)
	dim as short GemMultiplier
	for HandID as byte = 1 to 5
		ColorCounts(PlayerSlot(Player).PokerHand(HandID)) += 1
	next HandID
	
	for HighOrder as byte = 0 to 1
		for GemColor as byte = 1 to 7
			if ColorCounts(GemColor) > HighestCounts(HighOrder) AND (PrimaryColor <> GemColor OR HighOrder = 0) then
				HighestCounts(HighOrder) = ColorCounts(GemColor)
				if HighOrder = 0 then
					PrimaryColor = GemColor
				end if
			end if
		next GemColor
	next HighOrder
	
	if HighestCounts(0) = 5 then
		GemMultiplier = 50
	elseif HighestCounts(0) = 4 then
		GemMultiplier = 35
	elseif HighestCounts(0) = 3 AND HighestCounts(1) = 2 then
		GemMultiplier = 25
	elseif HighestCounts(0) = 3 then
		GemMultiplier = 10
	elseif HighestCounts(0) = 2 AND HighestCounts(1) = 2 then
		GemMultiplier = 5
	end if
	
	return GemMultiplier
end function
sub destroyBalls
	for BID as ubyte = 1 to NumBalls
		with Ball(BID)
			.X = 512
			.Y = 1000
			.Grabbed = 0
			.Gravity = 0
			.Trapped = 0
			.Duration = 0
			if .Speed > 0 then
				.Speed = 0
			end if
		end with
	next BID
	TotalBC = 0
end sub
sub destroyAmmo
	BulletStart = 1
	for MSID as ubyte = 1 to MaxBullets
		with Bullet(MSID)
			.Y = -100
		end with
	next MSID
end sub
sub destroyCapsules
	for CID as ubyte = 1 to MaxFallCaps
		Capsule(CID).Y = 800
	next CID
end sub
sub copyWall
	with NewPlrSlot
		.InitialLevel = .LevelNum

		for YID as byte = 1 to 24  
			for XID as byte = 1 to 40
				.Tileset(XID,YID) = PlayerSlot(1).Tileset(XID,YID)
			next XID
		next YID

		.SavedGameStyle = PlayerSlot(1).SavedGameStyle
		.BossMaxHealth = PlayerSlot(1).BossMaxHealth
		.BulletAmmo = PlayerSlot(1).BulletAmmo
	end with
end sub
function boxDetection(StartX as byte,StartY as byte,EndX as byte,EndY as byte) as byte
	dim as ubyte BoxSatisfied = 1
	for YID as byte = StartY to EndY 
		for XID as byte = StartX to EndX
			if XID = StartX OR XID = EndX OR YID = StartY OR YID = EndY then
				if PlayerSlot(Player).TileSet(XID,YID).BrickID = 0 then
					BoxSatisfied = 0
					exit for,for
				end if
			elseif PlayerSlot(Player).TileSet(XID,YID).BrickID > 0 then
				BoxSatisfied = 0
				exit for,for
			end if
		next XID
	next YID
	return BoxSatisfied
end function
sub generateCavity
	dim as ubyte BallsGenerated
	for BID as ubyte = 11 to 100
		with Ball(BID)
			.Y = 500
			.Speed = 0
			.Power = 0
			.LHX = 0
			.LHY = 0
			.Gravity = 0
		end with
	next BID
	
	if (GameStyle AND (1 SHL STYLE_CAVITY)) then
		for BoxHeight as ubyte = 2 to 5
			for BoxWidth as ubyte = 3 to 5
				for YID as ubyte = 1 to 20 - BoxHeight
					for XID as ubyte = 1 to 20 * (CondensedLevel + 1) - BoxWidth
						if boxDetection(XID,YID,XID+BoxWidth,YID+BoxHeight) then
							BallsGenerated += 1
							with Ball(10+Ballsgenerated)
								if CondensedLevel then
									.X = 20+(XID+BoxWidth/2)*24
								else
									.X = 8+(XID+BoxWidth/2)*48
								end if
								.Y = 84+(YID+BoxHeight/2)*24
								if PlayerSlot(Player).Difficulty < 3.5 then
									.Speed = 6
								else
									.Speed = 8
								end if
								.Power = -2
								.Angle = irandom(0,360)
								.Duration = 1
							end with
						end if
					next XID
				next YID
			next BoxWidth
		next BoxHeight
	end if
end sub
sub loadScores
	for HID as byte = 11 to TotalHighSlots
		with HighScore(HID)
			.Namee = ""
			.RawScore = 0
			.GameTime = -1
			.Difficulty = 1
			.LevelStart = 1
			.LevelFinal = 1
			.NewEntry = 0
		end with
	next HID
	
	if CampaignFolder = "community/misc" then
		for HID as byte = 1 to SavedHighSlots
			with HighScore(HID)
				.Namee = "Guest Debugger"
				.RawScore = CheatScore * (SavedHighSlots - HID + 1) / 10
				.Difficulty = (SavedHighSlots - HID) / 2 + 1
				.LevelStart = 1
				.LevelFinal = int(.Difficulty)
				.NewEntry = 0
			end with
		next HID
	else
		if FileExists(CampaignName+".csv") then
			dim as byte TimeCol = 0
			
			open CampaignName+".csv" for input as #1
			for HID as byte = 0 to SavedHighSlots
				if HID = 0 then
					dim as string ReadHeader
					line input #1, ReadHeader
					
					TimeCol = sgn(abs(instr(ReadHeader, "Game Time") > 0)) 
				else
					with HighScore(HID)
						input #1, .Namee
						input #1, .RawScore
						if TimeCol then
							input #1, .GameTime
						end if
						input #1, .LevelStart
						input #1, .LevelFinal
						input #1, .Difficulty
						.NewEntry = 0
					end with
				end if
			next HID
			close #1
		else
			for HID as byte = 1 to SavedHighSlots
				with HighScore(HID)
					.Namee = "No name"
					.RawScore = 0
					.GameTime = -1
					.LevelStart = 1
					.LevelFinal = 1
					.Difficulty = (SavedHighSlots - HID) / 2 + 1
					.NewEntry = 0
				end with
			next HID
		end if
	end if
end sub
sub saveScores
	if CampaignFolder <> "community/misc" then
		open CampaignName+".csv" for output as #1
		print #1, "Name,"+quote("Raw Score")+","+quote("Game Time")+","+quote("Level Started")+","+quote("Level Ended")+",Difficulty"  
		for HID as byte = 1 to SavedHighSlots
			with HighScore(HID)
				print #1, quote(.Namee);","& .RawScore;","& .GameTime;","& .LevelStart;","& .LevelFinal;","&.Difficulty  
			end with
		next HID
		close #1
	end if
end sub
sub setAuxPallete(WorkBrush as short, NewColoring as uinteger)
	dim as byte BrushDiv = 1
	select case WorkBrush
		case ZapBrush
			BrushDiv = 4
	end select 
	
	with Pallete(WorkBrush)
		if .PColoring = rgba(0,0,0,128) then
			.PColoring = rgba(retrivePrimary(NewColoring,RGBA_RED) / BrushDiv,_
				retrivePrimary(NewColoring,RGBA_GREEN) / BrushDiv,_
				retrivePrimary(NewColoring,RGBA_BLUE) / BrushDiv,_
				128)
		end if
	end with
end sub
function applyBlockProperties as ushort
	dim as short TestGrade
	dim as ubyte PalleteUsed(35)
	dim as ushort InvinFound = 0

	for BID as ushort = 1 to BlockBrushes
		with Pallete(BID)
			for PID as ushort = 1 to 35
				PalleteUsed(PID) = 0
			next PID
			
			if .PColoring = 0 then
				.ZapDegrade = 0
			else
				.ZapDegrade = BID
			end if
			.CalcedInvulnerable = 0
			TestGrade = BID
			while TestGrade > 0
				if TestGrade = Pallete(TestGrade).HitDegrade then
					.CalcedInvulnerable = 1
					if BID = TestGrade then
						setAuxPallete(ZapBrush,.PColoring)
					end if
					.ZapDegrade = ZapBrush
					exit while
				else
					if PalleteUsed(TestGrade) < 3 then
						PalleteUsed(TestGrade) += 1
						TestGrade = Pallete(TestGrade).HitDegrade
						if TestGrade > 0 then
							.ZapDegrade = TestGrade
						end if
					else
						if PalleteUsed(BID) >= 2 then
							.CalcedInvulnerable = 2
						else
							.CalcedInvulnerable = 1
						end if
						if .CalcedInvulnerable = 1 then
							setAuxPallete(ZapBrush,.PColoring)
						end if
						.ZapDegrade = ZapBrush
						exit while
					end if
				end if
			wend
			
			if TestGrade < 0 then
				.CalcedInvulnerable = TestGrade
				
				if TestGrade = -2 then
					setAuxPallete(BloomBrush,.PColoring)
				end if
			end if
			
			if .CalcedInvulnerable > 0 then
				InvinFound += 1
			end if
			
			if .CanRegen > 0 then
				for CID as ubyte = 1 to BlockBrushes
					if Pallete(CID).HitDegrade = BID then
						.CanRegen = CID
						exit for
					end if
				next CID
			end if
		end with
	next BID
	
	return InvinFound
end function

function loadLevelFile(LoadLevel as string) as integer
	dim as string FindBegin, LoadData, LoadFile
	dim as short MaxHeight = 20
	dim as ushort InvinFound = 0
	for BID as ushort = 1 to 35
		Pallete(BID) = Pallete(0)
	next BID
	LoadFile = MasterDir+"/campaigns/"+LoadLevel+".txt"
	open LoadFile for input as #1
	do
		input #1, FindBegin
		if eof(1) then
			print "ERROR: Failure to find the correct beginning from "+LoadFile+"."
			screencopy
			sleep
			return -1
		end if
	loop until FindBegin = "*BEGIN*"
	line input #1, NullString
	line input #1, NullString
	line input #1, LoadData
	CampaignLevelName = right(LoadData,len(LoadData)-25)
	line input #1, LoadData
	LevelDescription = right(LoadData,len(LoadData)-25)
	input #1, LoadData
	CampaignPassword = right(LoadData,len(LoadData)-25)
	input #1, LoadData
	GameStyle = valint(right(LoadData,len(LoadData)-25))
	
	'Overrides Cavity if a conflicting variation is found
	if (GameStyle AND (1 SHL STYLE_PROGRESSIVE)) OR (GameStyle AND (1 SHL STYLE_ROTATION)) then
		if (GameStyle AND (1 SHL STYLE_CAVITY)) then
			GameStyle -= 2^STYLE_CAVITY
		end if
	end if

	input #1, LoadData
	LevelTimeLimit = valint(right(LoadData,len(LoadData)-25))
	
	input #1, LoadData
	if lcase(left(LoadData,17)) = "level boss health" then
		PlayerSlot(Player).BossMaxHealth = valint(right(LoadData,len(LoadData)-25))
		input #1, LoadData
	else
		PlayerSlot(Player).BossMaxHealth = 0
	end if
	
	BlockBrushes = valint(right(LoadData,len(LoadData)-25))
	
	'Phase 1: Load the brushes
	for BID as ushort = 1 to BlockBrushes
		if BID <= 35 then
			with Pallete(BID)
				input #1, LoadData
				.PColoring = valint(right(LoadData,len(LoadData)-25))
				input #1, LoadData
				.ScoreValue = valint(right(LoadData,len(LoadData)-25))
				.DynamicValue = abs(sgn(right(LoadData,1) = "*"))
				input #1, LoadData
				.HitDegrade = valint(right(LoadData,len(LoadData)-25))
				.CanRegen = abs(sgn(right(LoadData,1) = "*"))
				input #1, LoadData
				.IncreaseSpeed = abs(sgn(ucase(right(LoadData,4)) = "TRUE" AND ActiveDifficulty >= 1.49))
			end with
		else
			line input #1, NullString
			line input #1, NullString
			line input #1, NullString
			line input #1, NullString
		end if
	next BID
	with Pallete(ZapBrush)
		.PColoring = rgba(0,0,0,128)
		.ScoreValue = int(BaseCapsuleValue / 10)
		.DynamicValue = 1
		.ZapDegrade = ZapBrush
		.UsedInlevel = 0
	end with
	with Pallete(BloomBrush)
		.PColoring = rgba(0,0,0,128)
		.ScoreValue = int(BaseCapsuleValue / 10)
		.DynamicValue = 1
		.ZapDegrade = BloomBrush
		.UsedInlevel = 0
	end with


	'Phase 2: Apply regeneration, breakability, and zappability
	InvinFound = applyBlockProperties
	line input #1, NullString
	line input #1, NullString
	line input #1, NullString
	line input #1, NullString
	if len(NullString) > 23 then
		CondensedLevel = 1
	else
		CondensedLevel = 0
	end if
	CampaignBricks = 0
	BrickCount = 0
	
	if (GameStyle AND (1 SHL STYLE_PROGRESSIVE)) then
		MaxHeight = 24
	end if
	
	'If Invin brushes are found, disallow Fusion if Rotation is active.
	if InvinFound > 0 AND sgn(GameStyle AND (1 SHL STYLE_ROTATION)) AND sgn(GameStyle AND (1 SHL STYLE_FUSION)) then
		GameStyle -= 2^STYLE_FUSION
	end if
	
	'Phase 3 - Create layout, but only if this is a fresh level
	if PlayerSlot(Player).PerfectClear > 0 AND PlayerSlot(Player).SetCleared = 0 then
		for YID as ubyte = 1 to 24
			line input #1, LoadData
			for XID as ubyte = 1 to 40
				with PlayerSlot(Player).TileSet(XID,YID)
					.Flash = 0
					.HitTime = 0
					.LastBall = 0
					if LoadData = "*END*" OR len(LoadData) < XID OR YID > MaxHeight then
						.BrickID = 0
					else
						.BrickID = convertChar(mid(LoadData,3+XID,1))
						if .BrickID > 0 AND .BrickID <> Pallete(PlayerSlot(Player).TileSet(XID,YID).BrickID).HitDegrade AND _
							Pallete(.BrickID).CalcedInvulnerable < 2 then
							CampaignBricks += 1
							BrickCount += 1
						end if
					end if
					.BaseBrickID = .BrickID
					if .BaseBrickID > 0 AND .BaseBrickID <= 35 AND Pallete(.BaseBrickID).HitDegrade >= 0 AND _
						Pallete(.BaseBrickID).CalcedInvulnerable = 0 then
						Pallete(.BaseBrickID).UsedInlevel = 1
					end if
				end with
			next XID
		next YID
		
		PlayerSlot(Player).SavedGameStyle = GameStyle
	else
		'If a life had been lost, read level data instead
		GameStyle = PlayerSlot(Player).SavedGameStyle

		for YID as ubyte = 1 to 24
			for XID as ubyte = 1 to 40
				with PlayerSlot(Player).TileSet(XID,YID)
					if .BrickID > 0 AND .BrickID <> Pallete(PlayerSlot(Player).TileSet(XID,YID).BrickID).HitDegrade AND _
						Pallete(.BrickID).CalcedInvulnerable < 2 then
						CampaignBricks += 1
						BrickCount += 1
					end if
				end with
			next XID
		next YID
	end if
	close #1
	
	return 0
end function
function loadLevel(LevNum as short) as integer
	if QuickPlayFile <> "" then
		return loadLevelFile(QuickPlayFile)
	end if
	if CampaignFolder = EndlessFolder then
		dim as string LevelFile
		dim as integer TrueNum = (LevNum - 1) mod TotalOfficialLevels + 1
		dim as integer LevelsLeftover = EndlessShuffList(TrueNum)
		
		if LevelsLeftover > 0 then
			applyDiffSpecs
			for OCID as ubyte = 1 to CampaignsPerPage
				with OfficialCampaigns(OCID)
					if LevelsLeftover > .TrueSize then
						LevelsLeftover -= .TrueSize
					else
						return loadLevelFile(.Folder+"/L"+str(LevelsLeftover))
					end if
				end with
			next OCID
		end if
	elseif ShuffleSet then
		return loadLevelFile(CampaignFolder+"/L"+str(ShuffleList(LevNum)))
	end if
	
	return loadLevelFile(CampaignFolder+"/L"+str(LevNum)) 
end function
function loadSettings as integer
	dim as string FindBegin, LoadData
	open MasterDir+"/campaigns/"+CampaignFolder+"/Settings.txt" for input as #1
	do
		input #1, FindBegin
		if eof(1) then
			print "ERROR: Failure to find the correct beginning from Settings."
			screencopy
			sleep
			return -1
		end if
	loop until FindBegin = "*BEGIN*"
	line input #1, NullString
	line input #1, NullString
	line input #1, LoadData
	CampaignName = right(LoadData,len(LoadData)-25) 
	
	input #1, LoadData
	StartingLives = valint(right(LoadData,len(LoadData)-25))
	ExtraBarrierPoint = abs(sgn(right(LoadData,1) = "*"))
	
	input #1, LoadData
	BaseCapsuleValue = valint(right(LoadData,len(LoadData)-25))
	input #1, LoadData
	InitialExtraLife = valint(right(LoadData,len(LoadData)-25))
	input #1, LoadData
	SubsequentExtraLives = valint(right(LoadData,len(LoadData)-25))
	input #1, LoadData
	ExplodingValue = valint(right(LoadData,len(LoadData)-25))
	input #1, LoadData
	SecretLevels = valint(right(LoadData,len(LoadData)-25))
	close #1
	
	return loadLevel(1)
end function
function checkLevel(LoadLev as short) as string
	if CampaignFolder = EndlessFolder then
		return "INFINITE"
	end if
	
	'Reads a password from the level to check
	dim as string FindBegin, LoadFile, LoadData, TestPassword
	LoadFile = MasterDir+"/campaigns/"+CampaignFolder+"/L"+str(LoadLev)+".txt"
	if FileExists(LoadFile) then
		open LoadFile for input as #1
		do
			input #1, FindBegin
			if eof(1) then
				return ""
			end if
		loop until FindBegin = "*BEGIN*"
		line input #1, NullString
		line input #1, NullString
		line input #1, NullString
		line input #1, NullString
		line input #1, LoadData
		TestPassword = ucase(right(LoadData,len(LoadData)-25))
		close #1
		return TestPassword
	else
		return ""
	end if
end function

function levelList as string
	dim as short SelectLevel = 1, LevelsRegistered, AdjustPagination, LegalLevel, LegalChoice
	dim as string LevelPass, OutPass

	do
		AdjustPagination = min(max(SelectLevel-ceil(LevelsPerPage/2),0),max(LevelsRegistered-LevelsPerPage,0))
		LevelsRegistered = 0
		cls
		gfxstring("Level list for "+CampaignName,0,0,5,4,4,rgb(0,255,255))
		for LevelID as short = 1 to HighLevel
			if LevelID = 1 then
				LegalLevel = 1
				LevelPass = "++++++++"
			else
				LevelPass = checkLevel(LevelID)
				if LevelPass <> "--------" AND LevelPass <> "++++++++" then
					LegalLevel = 1
				else
					LegalLevel = 0
				end if
			end if
			
			if LegalLevel then
				LevelsRegistered += 1
				
				if LevelsRegistered-AdjustPagination > 0 AND LevelsRegistered-AdjustPagination <= LevelsPerPage then
					if LevelsRegistered = SelectLevel then
						line(0,18+(LevelsRegistered-AdjustPagination)*25)-(1023,41+(LevelsRegistered-AdjustPagination)*25),rgb(0,0,128),bf
						LegalChoice = LegalLevel
						OutPass = LevelPass
					end if
					
					gfxstring("["+LevelPass+"] Level "+str(LevelID),0,20+(LevelsRegistered-AdjustPagination)*25,4,4,3,rgb(255,255,255))
				end if
			end if
		next LevelID
		
		if LevelsRegistered > 1 then
			gfxstring("Use [UP]/[DN] to navigate the levels. Press [ENTER] to quickly get a password.",0,20+(LevelsPerPage+1)*25,4,3,3,rgb(255,0,255))
		else
			gfxstring("No passwords have been collected for this campaign. Press [ESC] to return.",0,20+(LevelsPerPage+1)*25,4,3,3,rgb(255,0,255))
		end if
		screencopy
		sleep 15
		InType = inkey
		
		if InType = chr(27) then
			OutPass = "--------"
			exit do
		elseif InType = UpArrow then
			SelectLevel -= 1
		elseif InType = DownArrow then
			SelectLevel += 1
		elseif InType = PageUp then
			SelectLevel -= LevelsPerPage - 1 
		elseif InType = PageDn then
			SelectLevel += LevelsPerPage - 1
		end if
		
		if SelectLevel < 1 then
			SelectLevel = 1
		end if
		
		if SelectLevel > LevelsRegistered then
			SelectLevel = LevelsRegistered
		end if
	loop until InType = EnterKey AND LegalChoice
	
	if SelectLevel = 1 then
		OutPass = "--------"
	end if
	
	return OutPass
end function

function brickAdjacent(ChainX as short, ChainY as short, BasePallete as short) as integer
	dim as byte XDID, YDID, SlotsAdjacent
	
	for YID as byte = ChainY - 1 to ChainY + 1
		for XID as byte = ChainX - 1 to ChainX + 1
			XDID = XID
			YDID = YID
			if (GameStyle AND (1 SHL STYLE_ROTATION)) then
				if XDID <= 0 then
					XDID = XDID + 20 * (CondensedLevel + 1)
				elseif XDID > 20 * (CondensedLevel + 1) then
					XDID = XDID - 20 * (CondensedLevel + 1)
				end if
			end if
			
			if (GameStyle AND (1 SHL STYLE_PROGRESSIVE)) then
				if YDID <= 0 then
					YDID = YDID + 24
				elseif YDID > 24 then
					YDID = YDID - 24
				end if
			end if
			
			'Same type are considered adjacent and, thus, fair game to chain
			if XDID > 0 AND YDID > 0 AND XDID <= 40 AND YDID <= 24 AND abs(ChainX-XID) + abs(ChainY-YID) = 1 then
				with PlayerSlot(Player).TileSet(ChainX,ChainY)
					if .BaseBrickID = BasePallete AND PlayerSlot(Player).TileSet(XDID,YDID).Flash >= BaseFlash AND _
						PlayerSlot(Player).TileSet(XDID,YDID).BaseBrickID = .BaseBrickID AND _
						(PlayerSlot(Player).TileSet(XDID,YDID).Flash <> .Flash OR _
						PlayerSlot(Player).TileSet(XDID,YDID).LastBall <> .LastBall) then
						
						return -1
					end if
				end with
			end if 
		next XID
	next YID
	
	return 0
end function

sub damageBrick(BaseX as short, BaseY as short, NewPalette as short, NewID as short = 0, OnlySelf as byte = 0)
	dim as byte NewPaints
	
	with PlayerSlot(Player).TileSet(BaseX,BaseY)
		.Flash = BaseFlash
		.HitTime = 0
		.BrickID = NewPalette
		.LastBall = NewID
		
		if (Gamestyle AND (1 SHL STYLE_FUSION)) AND .BaseBrickID <> 0 AND OnlySelf = 0 then
			'Do chained damage
			do
				NewPaints = 0
				
				for YID as byte = 1 to 24			
					for XID as byte = 1 to 40
						if brickAdjacent(XID, YID, .BaseBrickID) then
							PlayerSlot(Player).TileSet(XID,YID).Flash = BaseFlash
							PlayerSlot(Player).TileSet(XID,YID).HitTime = 0
							PlayerSlot(Player).TileSet(XID,YID).BrickID = NewPalette
							PlayerSlot(Player).TileSet(XID,YID).LastBall = NewID
							NewPaints = 1
						end if
					next XID
				next YID
			loop until NewPaints = 0

			'Allow multiple hits on the very same frame
			for BID as byte = 1 to 24
				for AID as byte = 1 to 40
					with PlayerSlot(Player).TileSet(AID,BID)
						if .Flash >= BaseFlash then
							.Flash = BaseFlash - 1
						end if
					end with
				next AID
			next BID
		end if
	end with
end sub

sub incTickMark(ActiveObj as Basics)
	with ActiveObj
		.Trapped += 1
		if .Trapped >= TrapThreshold then
			if GameStyle AND (1 SHL STYLE_BOSS) then
				.Trapped = 0
				.Speed = 0
				TotalBC -= 1
				
				Instructions = "Balls that get stuck during a boss fight are removed from play"
				InstructExpire = timer + 12
				if TotalBC = 0 then
					PlayerSlot(Player).Lives += 1
				end if
			else
				.Trapped = 0
				.Power = 1
				.Duration = 60^2
				
				if HintLevel >= 3 then
					Instructions = "Balls that get stuck can now kill any blocks in one hit!"
					InstructExpire = timer + 12
				end if
			end if
		end if
	end with
end sub

sub brickCollisions(BallID as short)
	dim as ubyte HitFailed, PointsScored, ChooseParticle
	dim as uinteger ColorDestroyed
	dim as short ScoreMultiplier, BonusMultiplier, MinX, MaxX, MinY, MaxY, CenterX, CenterY, WidthX, FinalX, FinalY, NewPalette
	dim as single CalcDist, ShortestDist
	dim as integer ActualGain
	
	FinalX = -1 
	FinalY = -1 
	WidthX = 48/(1+CondensedLevel)
	MinX = (Ball(BallID).X-56)/WidthX
	MaxX = MinX + 2
	MinY = (Ball(BallID).Y-108)/24
	MaxY = MinY + 2
	ShortestDist = 1e6 - 1
	
	for YID as byte = MinY to MaxY
		for XID as byte = MinX to MaxX
			with Ball(BallID)
				if .Invul then
					'Skip this step, freshly spawned balls are unable to damage bricks
					exit sub
				end if
				
				if XID > 0 AND XID <= 40 AND YID > 0 AND YID <= 20 AND _
					PlayerSlot(Player).TileSet(XID,YID).BrickID > 0 AND (.LHX <> XID OR .LHY <> YID) AND _
					.X >= 32-BallSize+(XID-1)*WidthX AND .X <= 32+BallSize+(XID)*WidthX AND _
					.Y >= 96-BallSize+(YID-1)*24 AND .Y <= 96+BallSize+(YID)*24 then
					
					CenterX = 32+(XID-0.5)*WidthX
					CenterY = 96+(YID-0.5)*24
					CalcDist = sqr((.X - CenterX)^2 + (.Y - CenterY)^2)
					
					if CalcDist < ShortestDist then
						'If able to hit multiple bricks, favor the closest brick (relative to ball)
						ShortestDist = CalcDist
						FinalX = XID
						FinalY = YID
					end if
				end if
			end with
		next XID
	next YID
	
	'If a suitable match has been found, calculate the results accordingly
	with Ball(BallID)
		if FinalX > 0 AND FinalX <= 40 AND FinalY > 0 AND FinalY <= 20 then
			if .Power <= 1 then
				.LHX = FinalX
				.LHY = FinalY
			end if

			if .Power < 0 AND .Duration > 0 AND rnd < .4 AND _
				Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade >= 0 then
				'Weakened Balls have a chance of dealing 0 damage
				HitFailed = 1
			end if
			
			if .Power = -2 then
				'Ball is trapped in a cavity; deals no damage in this state
				optimalDirection(BallID,FinalX,FinalY)
			elseif HitFailed AND .Spawned = 0 then
				'Failed to damage a brick
				optimalDirection(BallID,FinalX,FinalY)
				
				if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).IncreaseSpeed then
					if .Speed < 12 then
						.Speed = 12
					else
						adjustSpeed(BallID,ActiveDifficulty / 50)
					end if
				else
					adjustSpeed(BallID,ActiveDifficulty / 100)
				end if

				NewPalette = PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID
				playClip(SFX_INVINCIBLE,.X,convertSpeed(.Speed))
				Invis = 12
			elseif .Invul = 0 AND .Spawned = 0 then
				'Breakthru Balls and Lightning Balls do not bounce off of blocks
				if .Power <> 3 AND .Power <> 4 then
					optimalDirection(BallID,FinalX,FinalY)
				end if

				if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade = PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID AND .Power <= 0 then
					'Invincible bricks are immune to normal damage
					NewPalette = PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID
					playClip(SFX_INVINCIBLE,.X,convertSpeed(.Speed))
					if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).IncreaseSpeed then
						if .Speed < 12 then
							.Speed = 12
						else
							adjustSpeed(BallID,ActiveDifficulty / 50)
						end if
					else
						adjustSpeed(BallID,ActiveDifficulty / 100)
					end if
					incTickMark(Ball(BallID))
				else
					'Deal damage accordingly
					dim as ubyte PalleteRef, NewBrick, ColorRef
					NewBrick = Pallete(PalleteRef).HitDegrade
					
					if .Power = 1 OR .Power = 2 then
						PalleteRef = Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).ZapDegrade
					else
						PalleteRef = PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID
					end if
					
					if .Power <= 0 then
						if Pallete(PalleteRef).CalcedInvulnerable >= 2 then
							incTickMark(Ball(BallID))
						elseif NewBrick = 0 OR Pallete(NewBrick).CanRegen = 0 then
							'Reset trap and (if needed) warp timer, but do not apply these to regen blocks
							.Trapped = 0
							if PlayerSlot(Player).WarpTimer < 1800 then
								PlayerSlot(Player).WarpTimer = 1800
							end if
						end if
					else
						'Blocks destroyed via assistance will reset the trap and warp timers anyway
						.Trapped = 0
						if PlayerSlot(Player).WarpTimer < 1800 then
							PlayerSlot(Player).WarpTimer = 1800
						end if
					end if
				
					if Pallete(PalleteRef).DynamicValue then
						ScoreMultiplier = int(.Speed) * 10
						BonusMultiplier = 100
						
						'Provide scoring incentative for power downs
						if PaddleSize <= 40 then
							BonusMultiplier += 50
						elseif PaddleSize <= 80 then
							BonusMultiplier += 35
						elseif PaddleSize <= 120 then
							BonusMultiplier += 20
						end if
						
						if Paddle(1).Sluggish > 0 then
							BonusMultiplier += 50
						end if

						if Paddle(1).Reverse > 0 then
							BonusMultiplier += 50
						end if

						ScoreMultiplier = int(ScoreMultiplier * BonusMultiplier/100)
					else
						ScoreMultiplier = 100
					end if
					
					ActualGain = int(Pallete(PalleteRef).ScoreValue * ballCtBonus * ScoreMultiplier / 100)

					with Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID)
						PlayerSlot(Player).Score += ActualGain
						PointsScored += ActualGain
						ColorRef = .HitDegrade
						if .PColoring = 0 then
							with Pallete(ColorRef)
								ColorDestroyed = rgb((retrivePrimary(.PColoring,RGBA_RED)+255)/2,_
									(retrivePrimary(.PColoring,RGBA_GREEN)+255)/2,_
									(retrivePrimary(.PColoring,RGBA_BLUE)+255)/2)
							end with
						else
							ColorDestroyed = rgb((retrivePrimary(.PColoring,RGBA_RED)+255)/2,_
								(retrivePrimary(.PColoring,RGBA_GREEN)+255)/2,_
								(retrivePrimary(.PColoring,RGBA_BLUE)+255)/2)
						end if
					end with
					if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).IncreaseSpeed then
						if .Speed < 12 then
							.Speed = 12
						else
							adjustSpeed(BallID,ActiveDifficulty / 50)
						end if
						if ProgressiveQuota > 4 then
							ProgressiveQuota = 4
						end if 
					else
						adjustSpeed(BallID,ActiveDifficulty / 100)
					end if
					
					generateCapsule(FinalX,FinalY)
					if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade < 0 OR .Power = 2 OR .Power = 4 then
						if .Power = 2 then
							PlayerSlot(Player).Score += 2 * ballCtBonus
							PointsScored += 2 * ballCtBonus
						end if
						NewPalette = min(ExplodeDelay,ExplodeDelay + (100 * (Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).CalcedInvulnerable + 1)))
					elseif .Power = 3 AND Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).CalcedInvulnerable >= 2 then
						NewPalette = 0
						playClip(SFX_BRICK,.X)
					elseif .Power = 1 then
						if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade > 0 then
							PlayerSlot(Player).Score += 2 * ballCtBonus
							PointsScored += 2 * ballCtBonus
						end if
						NewPalette = 0
						playClip(SFX_BRICK,.X)
					elseif Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade = PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID then
						NewPalette = 0
						playClip(SFX_BRICK,.X)
					else
						if Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade = 0 then
							playClip(SFX_BRICK,.X)
						else
							playClip(SFX_HARDEN,.X,convertSpeed(.Speed))
						end if
						NewPalette = Pallete(PlayerSlot(Player).TileSet(FinalX,FinalY).BrickID).HitDegrade
					end if
				end if
				Invis = 12
			end if

			if .Spawned = 0 AND .Power > -2 then
				damageBrick(FinalX,FinalY,NewPalette,BallID)
			end if
			generateParticles(PointsScored,FinalX,FinalY,ColorDestroyed)
		end if
	end with
end sub
sub generateCapsule(InX as byte, InY as byte, Explode as ubyte = 0)
	dim as ubyte Award, CapWeight(CAP_MAX)
	dim as short TotalWeight, RollPower, MaxRoll, CapsuleChance
	dim as string CapPic
	
	for CapID as byte = 1 to CAP_MAX - 1
		if CapID >= CAP_GEM_R then
			if ActiveDifficulty >= 1.5 then
				CapWeight(CapID) = 4
			else
				CapWeight(CapID) = 0
			end if
		else
			CapWeight(CapID) = 8
		end if
	next CapID
	
	CapWeight(CAP_BLIZZARD) = 4
	CapWeight(CAP_EXTENDER) = 4
	CapWeight(CAP_WEP_BULLET) = 4
	CapWeight(CAP_DISRUPT) = 4
	CapWeight(CAP_MYSTERY) = 4
	
	if Gamestyle AND (1 SHL STYLE_BOSS) then
		CapWeight(CAP_ZAP) = 0
		CapWeight(CAP_FIRE) = 0
		CapWeight(CAP_THRU) = 0
		CapWeight(CAP_WEAK) = 0
		CapWeight(CAP_WEP_MISSILE) = 0
	else
		CapWeight(CAP_THRU) = 2
		if ZappableCount > 0 OR (Gamestyle AND (1 SHL STYLE_INVIS)) then
			CapWeight(CAP_ZAP) = 4
		else
			CapWeight(CAP_ZAP) = 0
		end if
		CapWeight(CAP_FIRE) = 2
		CapWeight(CAP_WEP_MISSILE) = 2
		CapWeight(CAP_REPAIR) = 0
	end if
	
	with PlayerSlot(Player)
		if .Lives >= 9 + sgn(CampaignBarrier) OR CampaignFolder = EndlessFolder then
			CapWeight(CAP_LIFE) = 0
		elseif .Lives <= 1 then
			CapWeight(CAP_LIFE) = 2
		else
			CapWeight(CAP_LIFE) = 1
		end if
		
		if (SecretLevels > 0 AND .LevelNum >= SecretLevels - 1) OR _
			(checkLevel(.LevelNum + 1) = "" AND CampaignFolder <> EndlessFolder) then
			CapWeight(CAP_WARP) = 0
		else
			CapWeight(CAP_WARP) = 1
		end if
	end with
	
	if TotalBC * 2 > NumBalls then
		CapWeight(CAP_SPLIT_BALL) = 0
	end if

	if TotalBC + 7 > NumBalls then
		CapWeight(CAP_DISRUPT) = 0
	end if
	
	if XplodeCount = 0 then
		CapWeight(CAP_SPREAD) = 0
		CapWeight(CAP_DETONATE) = 0
	end if

	with PlayerSlot(Player)
		if ControlStyle = CTRL_AI then
			CapWeight(CAP_GRAB) = 0
			CapWeight(CAP_BLIZZARD) = 0
			CapWeight(CAP_MAXIMIZE) = 4
			CapWeight(CAP_GRAVITY) = 4
			CapWeight(CAP_SLOW_PAD) = 4
			CapWeight(CAP_NEGATER) = 2
			CapWeight(CAP_REVERSE) = 0
		elseif (ActiveDifficulty < 1.5 OR ActiveDifficulty >= 10.5) then
			CapWeight(CAP_FAST) = 0
			CapWeight(CAP_WEAK) = 0
			CapWeight(CAP_MAXIMIZE) = 0
			CapWeight(CAP_REVERSE) = 0
			CapWeight(CAP_SLOW_PAD) = 0
			CapWeight(CAP_GRAVITY) = 0
			CapWeight(CAP_NEGATER) = 0
		elseif ActiveDifficulty < 2.5 then
			CapWeight(CAP_FAST) = 4
			CapWeight(CAP_WEAK) = 4
			CapWeight(CAP_MAXIMIZE) = 0
			CapWeight(CAP_REVERSE) = 0
			CapWeight(CAP_SLOW_PAD) = 0
			CapWeight(CAP_GRAVITY) = 0
			CapWeight(CAP_NEGATER) = 1
		else
			CapWeight(CAP_MAXIMIZE) = 4
			CapWeight(CAP_GRAVITY) = 4
			CapWeight(CAP_REVERSE) = 2
			CapWeight(CAP_SLOW_PAD) = 2
			CapWeight(CAP_NEGATER) = 2
		end if
		
		for ICapID as byte = 1 to CAP_MAX
			TotalWeight += CapWeight(ICapID)
		next ICapID
		
		CapID += 1
		if CapID > MaxFallCaps then
			CapID = 1
		end if

		'Base capsule spawn rate (in percentage)
		if ActiveDifficulty >= 9.5 then
			CapsuleChance = 5
		elseif ActiveDifficulty >= 7.5 then
			CapsuleChance = 7
		elseif ActiveDifficulty >= 5.5 then
			CapsuleChance = 8
		elseif ActiveDifficulty >= 3.5 then
			CapsuleChance = 10
		else
			CapsuleChance = 12
		end if

		'Diminishing Returns if there are already falling capsules in play
		for DRCapID as byte = 1 to MaxFallCaps
			with Capsule(DRCapID)
				if .Y < 778 AND .Angle > 0 then
					CapsuleChance -= 1
				end if
			end with
		next DRCapID 
	end with
	
	with Capsule(CapID)
		if (.Angle = 0 OR .Y > 778) AND rnd < CapsuleChance / 100 AND _
			(GameStyle AND (1 SHL STYLE_POWERUPS)) AND PaddleSize > 0 then
			RollPower = irandom(1,TotalWeight)
			MaxRoll = 0
			
			for PowerBar as ubyte = 1 to CAP_MAX 
				MaxRoll += CapWeight(PowerBar)
				if RollPower <= MaxRoll then
					Award = PowerBar
					exit for
				end if
			next PowerBar

			.Angle = Award
			.Speed = 0

			select case Award
				case CAP_SLOW
					CapPic = "slow"
				case CAP_FAST
					CapPic = "fast"
				case CAP_EXPAND
					CapPic = "expand"
				case CAP_REDUCE
					CapPic = "reduce"
				case CAP_LIFE
					CapPic = "life"
				case CAP_REPAIR
					CapPic = "repairs"
				case CAP_BLIZZARD
					CapPic = "blizzard"
				case CAP_SPLIT_BALL
					CapPic = "split"
				case CAP_DISRUPT
					CapPic = "disruption"
				case CAP_ZAP
					CapPic = "zap"
				case CAP_MYSTERY
					CapPic = "mystery"
				case CAP_EXTENDER
					CapPic = "extender"
				case CAP_NEGATER
					CapPic = "negater"
				case CAP_WEAK
					CapPic = "weak"
				case CAP_FIRE
					CapPic = "fire"
				case CAP_THRU
					CapPic = "thru"
				case CAP_MAXIMIZE
					CapPic = "max"
				case CAP_GRAB
					CapPic = "grab"
				case CAP_SLOW_PAD
					CapPic = "slowpad"
				case CAP_WEP_BULLET
					CapPic = "bullet"
				case CAP_WEP_MISSILE
					CapPic = "missile"
				case CAP_REVERSE
					CapPic = "reverse"
				case CAP_SPREAD
					CapPic = "spread"
				case CAP_DETONATE
					CapPic = "detonate"
				case CAP_WARP
					CapPic = "warp"
				case CAP_GRAVITY
					CapPic = "gravity"
				case CAP_GEM_R
					CapPic = "gemR"
				case CAP_GEM_G
					CapPic = "gemG"
				case CAP_GEM_B
					CapPic = "gemB"
				case CAP_GEM_Y
					CapPic = "gemY"
				case CAP_GEM_P
					CapPic = "gemP"
				case CAP_GEM_C
					CapPic = "gemC"
				case CAP_GEM_W
					CapPic = "gemW"
			end select

			bload(Masterdir+"/gfx/caps/"+CapPic+".bmp",CapsulePic(CapID))
			.X = 32+(InX-0.5)*48/(CondensedLevel+1)
			.Y = 84+(InY)*24
			.Angle = Award
		end if
	end with
end sub

sub rotateBack(ForceLoad as byte = 0)
	if BacksLoaded > 1 OR (ForceLoad > 0 AND BacksLoaded > 0) then
		BackIter += 1
		if BackIter >= BacksLoaded then
			BackIter = 0
		end if
		
		with BackSlot(BackIter)
			bload(MasterDir+"/gfx/back/"+.Filename,Background)
		end with
	end if
end sub

sub auxillaryView(ByRef TextAlpha as short, ByRef TextBeta as short)
	dim as string DynamicString, DispDiff, DispLevel, DispLives, DispWeight
	dim as integer DynamicX, LowScores
	dim as uinteger TxtColoring
	dim as double WeightedScore
	Instructions = ""
	TextAlpha = 4
	TextBeta = 0
	LowScores = SavedHighSlots
	line(0,0)-(1023,767),rgba(0,0,0,192),bf
	
	'High Scores
	DynamicString = "High Scores for "+CampaignName
	DynamicX = 512 - gfxlength(DynamicString,5,5,3)/2
	gfxstring(DynamicString,DynamicX,100,5,5,3,rgb(255,0,255))
	
	for HID as ubyte = 0 to TotalHighSlots
		if HID = 0 then
			DynamicString = "Pos  Name                   Raw Score   Levels   Diff   XP Value"
			DynamicX = 512 - gfxlength(DynamicString,4,4,3)/2
			gfxstring(DynamicString,DynamicX,130+(HID)*25,4,4,3,rgb(0,255,255))
		else
			with HighScore(HID)
				DispDiff = left(str(.Difficulty+.001),len(str(int(.Difficulty)))+2)
				DispLevel = str(.LevelStart)+"-"+str(.LevelFinal)
				WeightedScore = .RawScore * .Difficulty
				if WeightedScore < 1e6 then
					DispWeight = commaSep(int(WeightedScore))
				elseif WeightedScore < 1e9 then
					DispWeight = commaSep(int(WeightedScore/1000))+"K"
				else
					DispWeight = commaSep(int(WeightedScore/1e6))+"M"
				end if
				
				DynamicString = space(2)+_
					left(.Namee,len(AIName))+space(max(len(AIName)-len(.Namee),0))+_
					space(32-len(AIName)-len(commaSep(.RawScore)))+commaSep(.RawScore)+_
					space(9-len(DispLevel))+DispLevel+_
					space(7-len(DispDiff))+DispDiff+_
					space(11-len(DispWeight))+DispWeight

				if HID > SavedHighSlots then
					'Also include 4 entries that (1) don't make the Top Ten or (2) were recently booted out of the Top Ten. 
					DynamicString = "---" + DynamicString
					TxtColoring = rgb(128,128,128)
				elseif .NewEntry then
					DynamicString = space(3-len(str(HID))) + str(HID) + DynamicString
					TxtColoring = rgb(255,255,0)
				else
					DynamicString = space(3-len(str(HID))) + str(HID) + DynamicString
					TxtColoring = rgb(255,255,255)
				end if
				
				DynamicX = 512 - gfxlength(DynamicString,4,4,3)/2
				if .RawScore > 0 OR HID <= SavedHighSlots then
					gfxstring(DynamicString,DynamicX,130+(HID)*25,4,4,3,TxtColoring)
				end if
			end with
		end if
	next HID
		
	'Hotseat Progression
	if NumPlayers > 0 then
		DynamicString = "Current Match Summary"
		DynamicX = 512 - gfxlength(DynamicString,5,5,3)/2
		gfxstring(DynamicString,DynamicX,550,5,5,3,rgb(255,0,255))
		
		for PID as ubyte = 0 to NumPlayers
			if PID = 0 then
				DynamicString = "Player      Score    Level   Lives   Diff"
				DynamicX = 512 - gfxlength(DynamicString,4,4,3)/2
				gfxstring(DynamicString,DynamicX,580+(PID)*25,4,4,3,rgb(0,255,255))
			else
				with PlayerSlot(PID)
					DispDiff = left(str(.Difficulty+.001),len(str(int(.Difficulty)))+2)
					DispLevel = str(.LevelNum)
					DispLives = str(.Lives)
					if Player = PID AND .Lives > 0 then
						TxtColoring = rgb(255,255,0)
					else
						TxtColoring = rgb(255,255,255)
					end if
					
					DynamicString = "Player "+str(PID)+space(10-len(commaSep(.Score)))+commaSep(.Score)+_
						space(8-len(DispLevel))+DispLevel+_
						space(8-len(DispLives))+DispLives+_
						space(7-len(DispDiff))+DispDiff
					DynamicX = 512 - gfxlength(DynamicString,4,4,3)/2
					gfxstring(DynamicString,DynamicX,580+(PID)*25,4,4,3,TxtColoring)
				end with
			end if
		next PID
	end if
	
end sub

sub highScoreInput(PlayerNum as byte, Automatic as byte = 0)
	if DQ OR CampaignName = PlaytestName OR PlayerSlot(PlayerNum).Difficulty > 12 then
		exit sub
	end if

	dim as byte NewPosition
	dim as string NewName, PrintStr
	dim as short CenterX
	for CheckHS as byte = 1 to TotalHighSlots
		if PlayerSlot(PlayerNum).Score * PlayerSlot(PlayerNum).Difficulty > HighScore(CheckHS).RawScore * HighScore(CheckHS).Difficulty then
			NewPosition = CheckHS
			exit for
		end if
	next CheckHS
	
	'New high score
	if NewPosition > 0 then
		if NewPosition < TotalHighSlots then
			for BumpHS as byte = (TotalHighSlots - 1) to NewPosition step -1
				HighScore(BumpHS+1) = HighScore(BumpHS)
			next BumpHS
		end if
		
		if NewPosition <= SavedHighSlots then
			if ControlStyle = CTRL_AI then
				NewName = AIName
			elseif Automatic = 0 then
				do
					screenevent(@e)
					line(302,349)-(721,449),rgb(0,0,0),bf
					line(302,349)-(721,449),rgb(255,255,255),b
					
					if NewPosition = 1 then
						PrintStr = "High Score achieved, Player "+str(PlayerNum)+"!!!"
					else
						PrintStr = "Position "+str(NewPosition)+" achieved, Player "+str(PlayerNum)+"!"
					end if
					CenterX = 512-gfxlength(PrintStr,4,3,3)/2
					gfxstring(PrintStr,CenterX,359,4,3,3,rgb(255,255,255))
					
					PrintStr = "Type to enter your name"
					CenterX = 512-gfxlength(PrintStr,4,3,3)/2
					gfxstring(PrintStr,CenterX,389,4,3,3,rgb(255,255,255))
					
					PrintStr = NewName
					CenterX = 512-gfxlength(PrintStr,4,3,3)/2
					gfxstring(PrintStr,CenterX,419,4,3,3,rgb(255,255,255))
					
					drawBox(372,414,651,443)
			
					sleep 10
					InType = inkey
					screencopy
					
					if (InType >= "A" AND InType <= "Z") OR (InType >= "a" AND InType <= "z") OR (InType >= "0" AND InType <= "9") OR InType = space(1) then
						NewName += InType
					elseif InType = Backspace then
						NewName = left(NewName,len(NewName)-1)
					end if
				loop until InType = EnterKey
				InType = chr(255)
				
				if lcase(NewName) = lcase(AIName) then
					NewName = DummyName
				end if
			end if
			if NewName = "" then
				NewName = "Anonymous"
			end if
		else
			NewName = "(Player "+str(PlayerNum)+")"
		end if
		
		with HighScore(NewPosition)
			.Namee = NewName
			.RawScore = PlayerSlot(PlayerNum).Score
			.GameTime = PlayerSlot(PlayerNum).PlayTime
			.LevelStart = PlayerSlot(PlayerNum).InitialLevel
			.LevelFinal = PlayerSlot(PlayerNum).LevelNum
			.Difficulty = PlayerSlot(PlayerNum).Difficulty
			.NewEntry = 1
		end with
		
		saveScores
	end if
end sub

sub freshLevel(PlrID as byte)
	with PlayerSlot(PlrID)
		if (GameStyle AND (1 SHL STYLE_BOSS)) OR (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
			.BossHealth = .BossMaxHealth
		end if
		.LevelTimer = LevelTimeLimit * 60
		if ActiveDifficulty < 3.5 then
			.LevelTimer *= 2
		end if
		.WarpTimer = 3600
		.PerfectClear = 1
	end with
end sub

sub gameOver
	setmouse(,,0,0)
	dim as string PrintStr
	dim as short CenterX
	dim as byte UseChoice, ValidChoice(2), LevelSkippable
	
	if NumPlayers > 1 then
		PrintStr = "Game Over, Player "+str(Player)
	else
		PrintStr = "Game Over"
	end if
	CenterX = 512-gfxlength(PrintStr,5,4,3)/2
	ValidChoice(2) = 1
	
	for Painting as short = 254 to 0 step -2
		line(0,314)-(1023,349),rgb(0,0,0),bf
		line(0,314)-(1023,314),rgb(255,255,255)
		gfxstring(PrintStr,CenterX,319,5,4,3,rgb(255,128,128))
		line(0,349)-(1023,349),rgb(255,255,255)
		line(0,314)-(1023,349),rgba(255,255,255,Painting),bf
		sleep 5
		screencopy
	next Painting
	
	with PlayerSlot(Player)
		if DQ = 0 then
			highScoreInput(Player)
			TotalXP += int(.Score * .Difficulty)
			saveConfig
		end if
		
		if .Score > 0 then
			.GameOverCombo += 1
		else
			.GameOverCombo = 0
		end if
		
		LevelSkippable = (.GameOverCombo >= 2 AND checkLevel(.LevelNum+1) <> "--------" AND checkLevel(.LevelNum+1) <> "" AND _
			(.LevelNum < SecretLevels - 1 OR SecretLevels <= 0))
	end with

	do
		screenevent(@e)
		line(302,349)-(721,449),rgb(0,0,0),bf
		line(302,349)-(721,449),rgb(255,255,255),b

		if CampaignPassword = "--------" OR CampaignFolder = EndlessFolder then
			ValidChoice(0) = 0
			ValidChoice(1) = 0
			UseChoice = 2
		else
			ValidChoice(0) = 1
			ValidChoice(1) = 1
		end if
		
		for COption as byte = 0 to 2
			select case COption
				case 0
					PrintStr = "Use a continue"
				case 1
					if LevelSkippable then
						PrintStr = "Skip level"
					elseif PlayerSlot(Player).Difficulty > 3.5 AND PlayerSlot(Player).Difficulty < 6.5 then
						PrintStr = "Reduce difficulty"
					else
						PrintStr = ""
						ValidChoice(1) = 0
					end if
				case 2
					PrintStr = "End game"
			end select
			CenterX = 512-gfxlength(PrintStr,4,3,3)/2
			if ValidChoice(COption) then
				if left(PrintStr,4) = "Skip" then
					gfxstring(PrintStr,CenterX,359+COption*30,4,3,3,rgb(255,255,128))
				else
					gfxstring(PrintStr,CenterX,359+COption*30,4,3,3,rgb(255,255,255))
				end if
			else
				gfxstring(PrintStr,CenterX,359+COption*30,4,3,3,rgb(128,128,128))
			end if
			
			if UseChoice = COption then
				drawBox(372,354+COption*30,651,383+COption*30)
			end if
		next COption

		sleep 10
		InType = inkey
		screencopy
		
		if InType = DownArrow then
			do
				UseChoice += 1
				if UseChoice > 2 then UseChoice = 0
			loop until ValidChoice(UseChoice)
		elseif InType = UpArrow then
			do
				UseChoice -= 1
				if UseChoice < 0 then UseChoice = 2
			loop until ValidChoice(UseChoice)
		end if
		if InType = XBox then
			UseChoice = 2
			exit do
		end if
	loop until InType = EnterKey AND ValidChoice(UseChoice)
	InType = chr(255)
	
	if UseChoice < 2 then
		with PlayerSlot(Player)
			if UseChoice = 1 AND LevelSkippable then
				'Skip level
				while .Difficulty >= 6.5
					.Difficulty -= 0.5
				wend
				
				.LevelNum += 1
				.GameOverCombo = 0
			else
				'Reduce difficulty (if appropriate)
				if (.Difficulty >= 6.5 AND .LevelNum > 1) OR UseChoice = 1 then
					if .Difficulty >= 11 then
						.Difficulty = 10
					elseif .Difficulty >= 8.5 then
						.Difficulty -= 1
					else
						.Difficulty = max(.Difficulty - 0.5,3.5)
					end if
				end if
			end if
			
			'Use a continue
			freshLevel(Player)
			loadLevel(.LevelNum)
			generateCavity
			.Score = 0
			.DispScore = 0
			.InitialLevel = .LevelNum
			emptyHand(Player)
			renderHand
			if InitialExtraLife = 0 then
				.Threshold = SubsequentExtraLives
			else
				.Threshold = InitialExtraLife
			end if
			.Lives = StartingLives + (ExtraBarrierPoint * CampaignBarrier)
		end with
	end if
	setmouse(,,0,1)
end sub

sub transferControl(GameEnded as ubyte = 0)
	dim as ubyte OldPlayer
	for LsrID as ubyte = 1 to 20
		for LsrPt as ubyte = 1 to 15
			with LaserBeams(LsrID,LsrPt)
				.Y = 768
			end with
		next LsrPt
	next LsrID
	SpeedMod = 100
	
	if NumPlayers > 1 then
		OldPlayer = Player
		
		do
			Player += 1
			if Player > NumPlayers then
				Player = 1
			end if
		loop until Player = OldPlayer OR Playerslot(Player).Lives > 0 OR GameEnded > 0
		generateCavity
		rotateBack
		loadLevel(PlayerSlot(Player).LevelNum)
		
		if Playerslot(Player).Lives > 0 AND ControlStyle >= CTRL_DESKTOP then
			GamePaused = 1
		end if
	end if
	
	if GameEnded = 0 then
		PaddleHealth = 110 * 60
		resetPaddle
		rotateMusic
	end if
	renderHand
end sub

sub capsuleMessage(NewText as string, AlwaysShow as byte = 0)
	if HintLevel >= 1 - AlwaysShow then
		Instructions = NewText
		InstructExpire = timer + max(5,2+len(NewText)/4)
	end if
end sub

sub shuffleLevels
	dim as short NumLevels, LID, LevelUsed
	if CampaignFolder = EndlessFolder then
		'Endless Shuffle randomizes ALL official campaigns levels!
		erase EndlessShuffList
		
		for LID = lbound(EndlessShuffList) to ubound(EndlessShuffList)
			do
				EndlessShuffList(LID) = irandom(1,TotalOfficialLevels)
				LevelUsed = 0
				
				for JID as short = 1 to LID - 1
					if EndlessShuffList(LID) = EndlessShuffList(JID) then
						LevelUsed = 1
						exit for
					end if
				next JID
			loop until LevelUsed = 0
		next LID
	else
		if ShuffleSet = 0 then
			exit sub
		end if
		
		'Determine the campaign size
		for LID = 1 to 999
			if FileExists(MasterDir+"/campaigns/"+CampaignFolder+"/L"+str(LID)+".txt") = 0 then
				NumLevels = LID - 1
				exit for
			end if 
		next LID
		
		redim ShuffleList(NumLevels)
		
		/'
		 ' Randomize most levels
		 ' - "Fatal level"s are intentionally excluded
		 ' - Secret levels are also excluded, if they have not already been known
		 '/
		for LID = 1 to NumLevels
			if checkLevel(LID) = "--------" OR (LID >= SecretLevels AND HighLevel < SecretLevels) then
				ShuffleList(LID) = LID
			else
				do
					ShuffleList(LID) = irandom(1,NumLevels)
					LevelUsed = sgn(abs(checkLevel(ShuffleList(LID)) = "--------" OR _
						(ShuffleList(LID) >= SecretLevels AND HighLevel < SecretLevels)))
					if LevelUsed = 0 then
						for JID as short = 1 to LID - 1
							if ShuffleList(LID) = ShuffleList(JID) then
								LevelUsed = 1
								exit for
							end if
						next JID
					end if
				loop until LevelUsed = 0
			end if
		next LID
	end if
end sub

sub beginLocalGame(InitPlayers as byte, InitLevel as short)
	if InitPlayers > 0 then
		setmouse(,,0,1)
	end if
	DQ = 0

	Player = 1
	NumPlayers = max(InitPlayers,1)
	resetPaddle
	destroyAmmo
	destroyBalls
	destroyCapsules
	LevelDesc = 0

	for HID as byte = 1 to 10
		HighScore(HID).NewEntry = 0
	next HID
	
	if InitPlayers >= 0 then
		if InitPlayers > 0 then
			ControlStyle = SavedControls
		else
			ControlStyle = CTRL_AI 
		end if
		
		if InitLevel = 1 then
			shuffleLevels
		
			fixFirstLevel
			loadLevel(1)
		else
			fixFirstLevel
			loadLevelFile(CampaignFolder+"/L"+str(InitLevel))
		end if
		rotateMusic
	else
		loadLevel(1)
	end if
	rotateBack
	generateCavity

	NewPlrSlot.LevelNum = InitLevel
	copyWall
	for PDID as ubyte = 1 to MaxPlayers
		DifficultyRAM(PDID) = PlayerSlot(PDID).Difficulty
		PlayerSlot(PDID) = NewPlrSlot
		PlayerSlot(PDID).Difficulty = DifficultyRAM(PDID)
		PlayerSlot(PDID).PlayTime = 0
		freshLevel(PDID)
		if PDID > InitPlayers AND (PDID <> 1 OR InitPlayers < 0) then
			PlayerSlot(PDID).Lives = 0
		end if
	next PDID
	renderHand

	FrameTime = timer
end sub


