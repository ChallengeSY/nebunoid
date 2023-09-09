const NumHints = 4
const TrapThreshold = 200
const CheatScore = 20000000
dim shared as string CampaignName, CampaignLevelName, CampaignPassword, LevelDescription
dim shared as ushort StartingLives, HighLevel, CampaignBricks, _
	SecretLevels, AttackBricks
dim shared as integer BaseCapsuleValue, PowerTick, PaddleHealth, InitialExtraLife, SubsequentExtraLives, LevelTimeLimit
dim shared as short SpeedMod, BackIter
dim shared as ubyte CapID, ExtraBarrierPoint, GameHints(NumHints), LevelDesc, ContinuousSplit
dim shared as byte ConstIncrease, PaddleAdjust
dim shared as double BoostIncrease, AttackTick, BaseMaxSpeed
redim shared as integer ShuffleList(1)

BackIter = irandom(0,BacksLoaded-1)

sub apply_diff_specs
	/'
    ' General rule of thumb; the higher the difficulty,
    ' the faster the gameplay, and the smaller the paddle/balls
	 '/
	BaseMaxSpeed = 20.5
	select case int(PlayerSlot(Player).Difficulty+0.5)
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

sub adjust_speed(BallID as short, AdjustBy as double)
	with Ball(BallID)
		if .Speed < BaseMaxSpeed then
			.Speed = min(.Speed + AdjustBy,BaseMaxSpeed)
		else
			.Speed -= .025
		end if
	end with
end sub
function convert_char(InChar as string) as integer
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
sub ui_element(Text as string, XPos as short, YPos as short, Length as short = 0, Coloring as uinteger = rgb(255,255,255))
	if len(Text) < Length then
		gfxString(Text,XPos+(Length-len(Text))*18,YPos,5,5,3,Coloring)
	else
		gfxString(Text,XPos,YPos,5,5,3,Coloring)
	end if
end sub
sub reset_paddle(OnlyGoods as byte = 0)
	apply_diff_specs
	render_paddle(StandardSize)
	ConstIncrease = 0
	BoostIncrease = 0
	PaddleAdjust = 0
	if PlayerSlot(Player).Difficulty < 1.45 then
		PlayerSlot(Player).BulletAmmo = 32
	else
		PlayerSlot(Player).BulletAmmo = 0
	end if
	PlayerSlot(Player).MissileAmmo = 0
	ContinuousSplit = 0
	if OnlyGoods = 0 then
		Paddle(1).Sluggish = 0
		Paddle(1).Reverse = 0
	end if
	Paddle(1).Spawned = 0
	Paddle(1).Repairs = 0
	Paddle(1).Grabbing = 0
	Paddle(1).Blizzard = 0
	HoldAction = 1
	ProgressiveBounces = 0
	ProgressiveQuota = 8
end sub
sub empty_hand(PlayerID as byte)
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
sub render_hand(SlotID as byte = 0)
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
function score_hand as short
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
sub destroy_balls
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
sub destroy_ammo
	for MSID as ubyte = 1 to MaxBullets
		with Bullet(MSID)
			.Y = -100
		end with
	next MSID
end sub
sub destroy_capsules
	for CID as ubyte = 1 to MaxFallCaps
		Capsule(CID).Y = 800
	next CID
end sub
function box_detection(StartX as byte,StartY as byte,EndX as byte,EndY as byte) as byte
	dim as ubyte BoxSatisfied = 1
	for YID as byte = StartY to EndY 
		for XID as byte = StartX to EndX
			if XID = StartX OR XID = EndX OR YID = StartY OR YID = EndY then
			if Tileset(XID,YID).BrickID = 0 then
					BoxSatisfied = 0
					exit for,for
				end if
			elseif Tileset(XID,YID).BrickID > 0 then
				BoxSatisfied = 0
				exit for,for
			end if
		next XID
	next YID
	return BoxSatisfied
end function
sub generate_cavity
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
						if box_detection(XID,YID,XID+BoxWidth,YID+BoxHeight) then
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
sub load_scores
	for HID as byte = 11 to TotalHighSlots
		with HighScore(HID)
			.Namee = ""
			.RawScore = 0
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
			open CampaignName+".csv" for input as #1
			for HID as byte = 0 to SavedHighSlots
				with HighScore(HID)
					input #1, .Namee
					input #1, .RawScore
					input #1, .LevelStart
					input #1, .LevelFinal
					input #1, .Difficulty
					.NewEntry = 0
				end with
			next HID
			close #1
		else
			for HID as byte = 1 to SavedHighSlots
				with HighScore(HID)
					.Namee = "No name"
					.RawScore = 0
					.LevelStart = 1
					.LevelFinal = 1
					.Difficulty = (SavedHighSlots - HID) / 2 + 1
					.NewEntry = 0
				end with
			next HID
		end if
	end if
end sub
sub save_scores
	if CampaignFolder <> "community/misc" then
		open CampaignName+".csv" for output as #1
		print #1, "Name,"+quote("Raw Score")+","+quote("Level Started")+","+quote("Level Ended")+",Difficulty"  
		for HID as byte = 1 to SavedHighSlots
			with HighScore(HID)
				print #1, quote(.Namee);","& .RawScore;","& .LevelStart;","& .LevelFinal;","&.Difficulty  
			end with
		next HID
		close #1
	end if
end sub
sub set_zapped_pallete(NewColoring as uinteger)
	with Pallete(InvinZapped)
		if .PColoring = rgba(0,0,0,128) then
			.PColoring = rgba(retrivePrimary(NewColoring,RGBA_RED) / 4,_
				retrivePrimary(NewColoring,RGBA_GREEN) / 4,_
				retrivePrimary(NewColoring,RGBA_BLUE) / 4,_
				128)
		end if
	end with
end sub
sub apply_block_properties
	dim as short TestGrade
	dim as ubyte PalleteUsed(35)

	for BID as ushort = 1 to BlockBrushes
		with Pallete(BID)
			for PID as ushort = 1 to 35
				PalleteUsed(PID) = 0
			next PID
			
			if .PColoring = 0 then
				.ZapDegrade = InvinZapped
			else
				.ZapDegrade = BID
			end if
			TestGrade = BID
			while TestGrade > 0
				if TestGrade = Pallete(TestGrade).HitDegrade then
					.CalcedInvulnerable = 1
					if BID = TestGrade then
						set_zapped_pallete(.PColoring)
					end if
					.ZapDegrade = InvinZapped
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
							set_zapped_pallete(.PColoring)
						end if
						.ZapDegrade = InvinZapped
						exit while
					end if
				end if
			wend

			if .CanRegen > 0 then
				for CID as ubyte = 1 to BlockBrushes
					if Pallete(CID).HitDegrade = BID then
						.CanRegen = CID
						exit for
					end if
				next CID
			end if
		end with
	next
end sub

function load_level_file(LoadLevel as string) as integer
	dim as string FindBegin, LoadData, LoadFile
	dim as short MaxHeight = 20
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
	Gamestyle = valint(right(LoadData,len(LoadData)-25))
	
	'Overrides Cavity if a conflicting variation is found
	if (GameStyle AND (1 SHL STYLE_CAVITY)) AND ((GameStyle AND (1 SHL STYLE_PROGRESSIVE)) OR (GameStyle AND (1 SHL STYLE_ROTATION))) then
		GameStyle -= 2^STYLE_CAVITY
	end if
	'Bonus levels override a Fatal Timer
	if (GameStyle AND (1 SHL STYLE_FATAL_TIMER)) AND (GameStyle AND (1 SHL STYLE_BONUS)) then
		GameStyle -= 2^STYLE_FATAL_TIMER
	end if
	'Boss Battle and Breakable Ceiling use many of the same mechanics, so they negate each other instead
	if (GameStyle AND (1 SHL STYLE_BOSS)) AND (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
		GameStyle -= 2^STYLE_BOSS + 2^STYLE_BREAKABLE_CEILING
	end if

	input #1, LoadData
	LevelTimeLimit = valint(right(LoadData,len(LoadData)-25))
	
	input #1, LoadData
	if left(LoadData,17) = "Level boss health" then
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
				.IncreaseSpeed = abs(sgn(ucase(right(LoadData,4)) = "TRUE" AND PlayerSlot(Player).Difficulty >= 1.49))
			end with
		else
			line input #1, NullString
			line input #1, NullString
			line input #1, NullString
			line input #1, NullString
		end if
	next BID
	with Pallete(InvinZapped)
		.PColoring = rgba(0,0,0,128)
		.ScoreValue = int(BaseCapsuleValue / 10)
		.DynamicValue = 1
		.ZapDegrade = InvinZapped
		.UsedInlevel = 0
	end with

	'Phase 2: Apply regeneration, breakability, and zappability
	apply_block_properties
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
	
	'Phase 3 - Create layout
	for YID as ubyte = 1 to 24
		line input #1, LoadData
		for XID as ubyte = 1 to 40
			with Tileset(XID,YID)
				.Flash = 0
				.HitTime = 0
				.LastBall = 0
				if LoadData = "*END*" OR len(LoadData) < XID OR YID > MaxHeight then
					.BrickID = 0
				else
					.BrickID = convert_char(mid(LoadData,3+XID,1))
					if .BrickID > 0 AND Tileset(XID,YID).BrickID <> Pallete(Tileset(XID,YID).BrickID).HitDegrade AND _
						Pallete(.BrickID).CalcedInvulnerable < 2 then
						CampaignBricks += 1
						BrickCount += 1
					end if
				end if
				.BaseBrickID = .BrickID
				if .BaseBrickID > 0 AND .BaseBrickID <= 35 AND Pallete(.BaseBrickID).CalcedInvulnerable = 0 then
					Pallete(.BaseBrickID).UsedInlevel = 1
				end if
			end with
		next XID
	next YID
	close #1
	
	return 0
end function
function load_level(LevNum as short) as integer
	if QuickPlayFile <> "" then
		return load_level_file(QuickPlayFile)
	end if
	if ShuffleLevels then
		return load_level_file(CampaignFolder+"/L"+str(ShuffleList(LevNum)))
	end if
	
	return load_level_file(CampaignFolder+"/L"+str(LevNum)) 
end function
function load_settings as integer
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
	
	return load_level(1)
end function
function check_level(LoadLevel as short) as string
	'Reads a password from the level to check
	dim as string FindBegin, LoadFile, LoadData, TestPassword
	LoadFile = MasterDir+"/campaigns/"+CampaignFolder+"/L"+str(LoadLevel)+".txt"
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

sub shuffle_levels
	dim as short NumLevels, LID, LevelUsed
	if ShuffleLevels = 0 then
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
		if check_level(LID) = "--------" OR (LID >= SecretLevels AND HighLevel < SecretLevels) then
			ShuffleList(LID) = LID
		else
			do
				ShuffleList(LID) = irandom(1,NumLevels)
				LevelUsed = sgn(abs(check_level(ShuffleList(LID)) = "--------" OR _
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
end sub

function level_list as string
	dim as short SelectLevel = 1, LevelsRegistered, AdjustPagination, LegalLevel, LegalChoice
	dim as string LevelPass, OutPass

	do
		AdjustPagination = min(max(SelectLevel-15,0),max(LevelsRegistered-29,0))
		LevelsRegistered = 0
		cls
		gfxstring("Level list for "+CampaignName,0,0,5,4,4,rgb(0,255,255))
		for LevelID as short = 1 to HighLevel
			if LevelID = 1 then
				LegalLevel = 1
				LevelPass = "++++++++"
			else
				LevelPass = check_level(LevelID)
				if LevelPass <> "--------" AND LevelPass <> "++++++++" then
					LegalLevel = 1
				else
					LegalLevel = 0
				end if
			end if
			
			if LegalLevel then
				LevelsRegistered += 1
				
				if LevelsRegistered-AdjustPagination > 0 AND LevelsRegistered-AdjustPagination < 30 then
					if LevelsRegistered = SelectLevel then
						line(0,18+(LevelsRegistered-AdjustPagination)*25)-(1023,41+(LevelsRegistered-AdjustPagination)*25),rgb(0,0,128),bf
						LegalChoice = LegalLevel
						OutPass = LevelPass
					end if
					
					gfxstring("["+LevelPass+"] Level "+str(LevelID),0,20+(LevelsRegistered-AdjustPagination)*25,4,4,3,rgb(255,255,255))
				end if
			end if
		next LevelID
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
			SelectLevel -= 28
		elseif InType = PageDn then
			SelectLevel += 28
		end if
		
		if SelectLevel < 1 then
			SelectLevel = 1
		end if
		
		if SelectLevel > LevelsRegistered then
			SelectLevel = LevelsRegistered
		end if
	loop until InType = chr(13) AND LegalChoice
	
	if SelectLevel = 1 then
		OutPass = "--------"
	end if
	
	return OutPass
end function

sub campaign_collisions(BallID as short)
	dim as ubyte HitFailed, PointsScored, ChooseParticle
	dim as uinteger ColorDestroyed
	dim as short ScoreMultiplier, BonusMultiplier, ActualGain, MinX, MaxX, MinY, MaxY
	
	if CondensedLevel then
		MinX = (Ball(BallID).X-44)/24
	else
		MinX = (Ball(BallID).X-56)/48
	end if
	MaxX = MinX + 2
	MinY = (Ball(BallID).Y-108)/24
	MaxY = MinY + 2
	
	for YID as byte = MinY to MaxY
		for XID as byte = MinX to MaxX
			with Ball(BallID)
				if XID > 0 AND XID <= 40 AND YID > 0 AND YID <= 20 AND .Invul = 0 AND _
					Tileset(XID,YID).BrickID > 0 AND (.LHX <> XID OR .LHY <> YID) AND _
					.X >= 32-BallSize+(XID-1)*48/(CondensedLevel + 1) AND _
					.X <= 32+BallSize+(XID)*48/(CondensedLevel + 1) AND _
					.Y >= 96-BallSize+(YID-1)*24 AND .Y <= 96+BallSize+(YID)*24 then
					if .Power <= 1 then
						.LHX = XID
						.LHY = YID
					end if

					if .Power < 0 AND .Duration > 0 AND rnd < .4 AND _
						Pallete(Tileset(XID,YID).BrickID).HitDegrade >= 0 then
						HitFailed = 1
					end if
					
					if .Spawned = 0 AND .Power > -2 then
						Tileset(XID,YID).Flash = BaseFlash
						Tileset(XID,YID).HitTime = 0
						Tileset(XID,YID).LastBall = BallID
					end if
					
					if .Power = -2 then
						optimal_direction(BallID,XID,YID)
					elseif HitFailed AND .Spawned = 0 then
						optimal_direction(BallID,XID,YID)
						
						if Pallete(Tileset(XID,YID).BrickID).IncreaseSpeed then
							if .Speed < 12 then
								.Speed = 12
							else
								adjust_speed(BallID,PlayerSlot(Player).Difficulty / 50)
							end if
						else
							adjust_speed(BallID,PlayerSlot(Player).Difficulty / 100)
						end if

						play_clip(SFX_INVINCIBLE,.X,convert_speed(.Speed))
						Invis = 12
					elseif .Invul = 0 AND .Spawned = 0 then
						'Breakthru Balls and Lightning Balls do not bounce off of blocks
						if .Power <> 3 AND .Power <> 4 then
							optimal_direction(BallID,XID,YID)
						end if

						if Pallete(Tileset(XID,YID).BrickID).HitDegrade = Tileset(XID,YID).BrickID AND .Power <= 0 then
							play_clip(SFX_INVINCIBLE,.X,convert_speed(.Speed))
							if Pallete(Tileset(XID,YID).BrickID).IncreaseSpeed then
								if .Speed < 12 then
									.Speed = 12
								else
									adjust_speed(BallID,PlayerSlot(Player).Difficulty / 50)
								end if
							else
								adjust_speed(BallID,PlayerSlot(Player).Difficulty / 100)
							end if
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
									
									if DisableHints = 0 then
										Instructions = "Balls that get stuck can now kill any blocks in one hit!"
										InstructExpire = timer + 12
									end if
								end if
							end if
						else
							dim as ubyte PalleteRef, NewBrick, ColorRef
							NewBrick = Pallete(PalleteRef).HitDegrade
							
							if .Power = 1 OR .Power = 2 then
								PalleteRef = Pallete(Tileset(XID,YID).BrickID).ZapDegrade
							else
								PalleteRef = Tileset(XID,YID).BrickID
							end if
							
							if .Power <= 0 then
								if Pallete(PalleteRef).CalcedInvulnerable >= 2 then
									.Trapped += 1
									if .Trapped >= TrapThreshold then
										if GameStyle AND (1 SHL STYLE_BOSS) then
											.Trapped = 0
											.Speed = 0
											TotalBC -= 1
		
											Instructions = "Balls that get stuck during a boss fight are removed from play"
											InstructExpire = timer + 12
											if TotalBC = 0 AND CampaignBarrier = 0 then
												PlayerSlot(Player).Lives += 1
											end if
										else
											.Trapped = 0
											.Power = 1
											.Duration = 60^2
											
											if DisableHints = 0 then
												Instructions = "Balls that get stuck can now kill any blocks in one hit!"
												InstructExpire = timer + 12
											end if
										end if
									end if
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
							
							ActualGain = int(Pallete(PalleteRef).ScoreValue * ball_ct_bonus * ScoreMultiplier / 100)

							with Pallete(Tileset(XID,YID).BrickID)
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
							if Pallete(Tileset(XID,YID).BrickID).IncreaseSpeed then
								if .Speed < 12 then
									.Speed = 12
								else
									adjust_speed(BallID,PlayerSlot(Player).Difficulty / 50)
								end if
								if ProgressiveQuota > 4 then
									ProgressiveQuota = 4
								end if 
							else
								adjust_speed(BallID,PlayerSlot(Player).Difficulty / 100)
							end if
							
							generate_campaign_capsule(XID,YID)
							if Pallete(Tileset(XID,YID).BrickID).HitDegrade < 0 OR .Power = 2 OR .Power = 4 then
								if .Power = 2 then
									PlayerSlot(Player).Score += 2 * ball_ct_bonus
									PointsScored += 2 * ball_ct_bonus
								end if
								Tileset(XID,YID).BrickID = ExplodeDelay
							elseif .Power = 3 AND Pallete(Tileset(XID,YID).BrickID).CalcedInvulnerable >= 2 then
								Tileset(XID,YID).BrickID = 0
								play_clip(SFX_BRICK,.X)
							elseif .Power = 1 then
								if .Duration > 0 then
									PlayerSlot(Player).Score += 2 * ball_ct_bonus
									PointsScored += 2 * ball_ct_bonus
								end if
								Tileset(XID,YID).BrickID = 0
								play_clip(SFX_BRICK,.X)
							elseif Pallete(Tileset(XID,YID).BrickID).HitDegrade = Tileset(XID,YID).BrickID then
								Tileset(XID,YID).BrickID = 0
								play_clip(SFX_BRICK,.X)
							else
								if Pallete(Tileset(XID,YID).BrickID).HitDegrade = 0 then
									play_clip(SFX_BRICK,.X)
								else
									play_clip(SFX_HARDEN,.X,convert_speed(.Speed))
								end if
								Tileset(XID,YID).BrickID = Pallete(Tileset(XID,YID).BrickID).HitDegrade
							end if
						end if
						Invis = 12
					end if

					generate_particles(PointsScored,XID,YID,ColorDestroyed)
					exit sub
				end if
			end with
		next XID
	next YID
end sub
sub generate_campaign_capsule(InX as byte, InY as byte, Explode as ubyte = 0)
	dim as ubyte Award, CapWeight(CAP_MAX)
	dim as short TotalWeight, RollPower, MaxRoll, CapsuleChance
	dim as string CapPic
	
	for CapID as byte = 1 to CAP_MAX - 1
		if CapID >= CAP_GEM_R then
			if PlayerSlot(Player).Difficulty >= 1.5 then
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
		if ZappableCount > 0 then
			CapWeight(CAP_ZAP) = 4
		else
			CapWeight(CAP_ZAP) = 0
		end if
		CapWeight(CAP_FIRE) = 2
		CapWeight(CAP_WEP_MISSILE) = 2
		CapWeight(CAP_REPAIR) = 0
	end if
	
	with PlayerSlot(Player)
		if .Lives <= 1 then
			CapWeight(CAP_LIFE) = 2
		elseif .Lives < 9 + sgn(CampaignBarrier) then
			CapWeight(CAP_LIFE) = 1
		else
			CapWeight(CAP_LIFE) = 0
		end if
	end with
	CapWeight(CAP_WARP) = 1
	
	if (Gamestyle AND (1 SHL STYLE_INVIS)) = 0 then
		CapWeight(CAP_FLASH) = 0
	end if
	
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
		if .Difficulty < 1.5 OR .Difficulty >= 10.5 then
			CapWeight(CAP_FAST) = 0
			CapWeight(CAP_WEAK) = 0
			CapWeight(CAP_MAXIMIZE) = 0
			CapWeight(CAP_REVERSE) = 0
			CapWeight(CAP_SLOW_PAD) = 0
			CapWeight(CAP_GRAVITY) = 0
			CapWeight(CAP_NEGATER) = 0
		elseif .Difficulty < 2.5 then
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
		if .Difficulty >= 9.5 then
			CapsuleChance = 5
		elseif .Difficulty >= 7.5 then
			CapsuleChance = 7
		elseif .Difficulty >= 5.5 then
			CapsuleChance = 8
		elseif .Difficulty >= 3.5 then
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
				case CAP_FLASH
					CapPic = "flashlight"
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
sub export_board
	open "Hotseat"+str(Player)+".dat" for output as #5
	print #5, Gamestyle
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 40
			print #5, ""& Tileset(XID,YID).BrickID;
			if XID < 40 then
				print #5, ",";
			else
				print #5, 
			end if
		next XID
	next YID
	close #5
	
	PlayerSlot(Player).HotseatStamp = FileDateTime("Hotseat"+str(Player)+".dat")
end sub

sub import_board
	dim as string LevelFile = CampaignFolder+"/L"+str(PlayerSlot(Player).LevelNum)
	load_level(PlayerSlot(Player).LevelNum)
	if FileExists("Hotseat"+str(Player)+".dat") then
		'Penalize anomalies
		if abs(FileDateTime("Hotseat"+str(Player)+".dat") - PlayerSlot(Player).HotseatStamp) > 1e-6 then
			PlayerSlot(Player).Lives = max(PlayerSlot(Player).Lives - 1,1)
			Instructions = "Tampering detected!!! Penalty -1 life for incoming player!"
			InstructExpire = timer + 30
		end if
		
		open "Hotseat"+str(Player)+".dat" for input as #6
		input #6, Gamestyle
		for YID as ubyte = 1 to 24
			for XID as ubyte = 1 to 40
				with Tileset(XID,YID)
					input #6, .BrickID
					.HitTime = 0
					.LastBall = 0
				end with
			next XID
		next YID
		close #6
	end if
	generate_cavity
end sub

sub rotate_back(ForceLoad as byte = 0)
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

sub auxillary_view(ByRef TextAlpha as short, ByRef TextBeta as short)
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
					left(.Namee,20)+space(max(20-len(.Namee),0))+_
					space(12-len(commaSep(.RawScore)))+commaSep(.RawScore)+_
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

sub high_score_input(PlayerNum as byte, Automatic as byte = 0)
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
				with HighScore(BumpHS+1)
					.Namee = HighScore(BumpHS).Namee
					.RawScore = HighScore(BumpHS).RawScore
					.LevelStart = HighScore(BumpHS).LevelStart
					.LevelFinal = HighScore(BumpHS).LevelFinal
					.Difficulty = HighScore(BumpHS).Difficulty
					.NewEntry = HighScore(BumpHS).NewEntry
				end with
			next BumpHS
		end if
		
		if NewPosition <= SavedHighSlots then
			if Automatic = 0 then
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
					
					draw_box(372,414,651,443)
			
					sleep 10
					InType = inkey
					screencopy
					
					if (InType >= "A" AND InType <= "Z") OR (InType >= "a" AND InType <= "z") OR (InType >= "0" AND InType <= "9") then
						NewName += InType
					elseif InType = Backspace then
						NewName = left(NewName,len(NewName)-1)
					end if
				loop until InType = chr(13)
				InType = chr(255)
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
			.LevelStart = PlayerSlot(PlayerNum).InitialLevel
			.LevelFinal = PlayerSlot(PlayerNum).LevelNum
			.Difficulty = PlayerSlot(PlayerNum).Difficulty
			.NewEntry = 1
		end with
		
		save_scores
	end if
end sub

sub fresh_level(PlrID as byte)
	with PlayerSlot(PlrID)
		if (GameStyle AND (1 SHL STYLE_BOSS)) OR (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
			.BossHealth = .BossMaxHealth
		end if
		.LevelTimer = LevelTimeLimit * 60
		if .Difficulty < 3.5 then
			.LevelTimer *= 2
		end if
		.WarpTimer = 3600
		.PerfectClear = 1
	end with
end sub

sub game_over
	setmouse(,,0,0)
	dim as string PrintStr
	dim as short CenterX
	dim as byte UseChoice, ValidChoice(2)
	
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
			high_score_input(Player)
			TotalXP += int(.Score * .Difficulty)
			save_unlocks
		end if
	end with

	do
		screenevent(@e)
		line(302,349)-(721,449),rgb(0,0,0),bf
		line(302,349)-(721,449),rgb(255,255,255),b

		if CampaignPassword = "--------" then
			ValidChoice(0) = 0
			ValidChoice(1) = 0
			UseChoice = 2
		else
			if PlayerSlot(Player).Difficulty < 6.5 OR PlayerSlot(Player).LevelNum = 1 then
				ValidChoice(0) = 1
			else
				ValidChoice(0) = 0
			end if

			if PlayerSlot(Player).Difficulty > 3.5 then
				ValidChoice(1) = 1
			else
				ValidChoice(1) = 0
			end if
		end if
		
		for COption as byte = 0 to 2
			select case COption
				case 0
					PrintStr = "Restart level"
				case 1
					PrintStr = "Reduce difficulty"
				case 2
					PrintStr = "End game"
			end select
			CenterX = 512-gfxlength(PrintStr,4,3,3)/2
			if ValidChoice(COption) then
				gfxstring(PrintStr,CenterX,359+COption*30,4,3,3,rgb(255,255,255))
			else
				gfxstring(PrintStr,CenterX,359+COption*30,4,3,3,rgb(128,128,128))
			end if
			
			if UseChoice = COption then
				draw_box(372,354+COption*30,651,383+COption*30)
			end if
		next COption

		sleep 10
		InType = inkey
		screencopy
		
		if InType = DownArrow then
			UseChoice += 1
			if UseChoice > 2 then UseChoice = 0
		elseif InType = UpArrow then
			UseChoice -= 1
			if UseChoice < 0 then UseChoice = 2
		end if
		if InType = XBox then
			UseChoice = 2
			exit do
		end if
	loop until InType = chr(13) AND ValidChoice(UseChoice)
	InType = chr(255)
	
	if UseChoice < 2 then
		'Use a continue
		with PlayerSlot(Player)
			if UseChoice = 1 then
				if .Difficulty >= 11 then
					.Difficulty = 10
				elseif .Difficulty >= 8.5 then
					.Difficulty -= 1
				else
					.Difficulty = max(.Difficulty - 0.5,3.5)
				end if
			end if
			
			load_level(.LevelNum)
			generate_cavity
			fresh_level(Player)
			.Score = 0
			.DispScore = 0
			.InitialLevel = .LevelNum
			empty_hand(Player)
			render_hand
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

sub transfer_control(GameEnded as ubyte = 0)
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
		if GameEnded = 0 then
			export_board
		end if
		
		do
			Player += 1
			if Player > NumPlayers then
				Player = 1
			end if
		loop until Player = OldPlayer OR Playerslot(Player).Lives > 0 OR GameEnded > 0
		import_board
		rotate_back
		
		if Playerslot(Player).Lives > 0 then
			GamePaused = 1
		end if
	end if
	
	if GameEnded = 0 then
		PaddleHealth = 110 * 60
		reset_paddle
		rotate_music
	end if
	render_hand
end sub

sub capsule_message(NewText as string, AlwaysShow as byte = 0)
	if DisableHints = 0 OR AlwaysShow then
		Instructions = NewText
		InstructExpire = timer + max(5,2+len(NewText)/4)
	end if
end sub

