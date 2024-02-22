#include "ABCgfx.bi"
#include "fbgfx.bi"
using FB
#include "vbcompat.bi"
dim shared as string QuickPlayFile
declare sub local_gameplay
const PlaytestName = "Quick Playtest Level"
const EndlessFolder = "official/endless"

const AIName = "Nebunoid Intelligence"
const DummyName = "Pumpkin Eater"

'Speed range specs
const DefaultSpeed = 8
const MinSpeed = 6
randomize timer

dim shared as string NullString, Masterdir
dim as byte ScreenCreated = 0
dim shared as byte MusicPlrEnabled
dim shared as any ptr TitleBanner
Masterdir = curdir
#IFDEF __USE_SDL__
#include "NebSDL.bas"
#ELSEIF defined(__USE_FBSOUND__)
#DEFINE __DISABLE_PI__
#include "NebFBS.bas"
#ELSE
#include "NebNull.bas"
#ENDIF

#IFDEF __FB_WIN32__
#include "windows.bi"
#ENDIF
#include "WordWrap.bi"

declare sub shop
declare sub generate_capsule(InX as byte, InY as byte, Explode as ubyte = 0)
'Keyboard commands
const EscapeKey = chr(27)
const UpArrow = chr(255,72)
const DownArrow = chr(255,80)
const LeftArrow = chr(255,75)
const RightArrow = chr(255,77)
const PageUp = chr(255,73)
const PageDn = chr(255,81)
const EnterKey = chr(13)
const Backspace = chr(8)
const XBox = chr(255,107)
const FunctionOne = chr(255,59)
const FunctionFour = chr(255,62)
const FunctionFive = chr(255,63)
const FunctionSeven = chr(255,65)
const FunctionEleven = chr(255,133)
const FunctionTwelve = chr(255,134)

const FPS = 60
const SavedHighSlots = 10
const TotalHighSlots = SavedHighSlots + 4
const TotalOfficialLevels = 266
const MaxBullets = 60
const BaseFlash = 128
const LevelClearDelay = 720
const ExplodeDelay = -6

enum Difficulties
	DIFF_KIDS = 1
	DIFF_VEASY
	DIFF_EASY
	DIFF_MEASY
	DIFF_MEDIUM
	DIFF_MHARD
	DIFF_HARD
	DIFF_VHARD
	DIFF_EXTREME
	DIFF_INSANE
end enum
enum DifferentGames
	STYLE_POWERUPS
	STYLE_EXTRA_HEIGHT
	STYLE_DUAL_PADDLES
	STYLE_DOUBLE_BALLS
	STYLE_CAVITY
	STYLE_PROGRESSIVE
	STYLE_STEER
	STYLE_INVIS
	STYLE_HYPER
	STYLE_BOSS
	STYLE_ROTATION
	STYLE_FUSION
	STYLE_SHRINK_CEILING
	STYLE_BREAKABLE_CEILING
	STYLE_FATAL_TIMER
	STYLE_BONUS
end enum

enum CapsuleDesigns
	CAP_SLOW = 1
	CAP_FAST
	CAP_EXPAND
	CAP_REDUCE
	CAP_LIFE
	CAP_BLIZZARD
	CAP_ZAP
	CAP_SPLIT_BALL
	CAP_DISRUPT
	CAP_MYSTERY
	CAP_MAXIMIZE
	CAP_GRAB
	CAP_SLOW_PAD
	CAP_WEP_BULLET
	CAP_WEP_MISSILE
	CAP_REVERSE
	CAP_SPREAD
	CAP_DETONATE
	CAP_EXTENDER
	CAP_NEGATER
	CAP_WEAK
	CAP_FIRE
	CAP_THRU
	CAP_GRAVITY
	CAP_WARP
	CAP_REPAIR
	CAP_GEM_R
	CAP_GEM_G
	CAP_GEM_B
	CAP_GEM_Y
	CAP_GEM_P
	CAP_GEM_C
	CAP_GEM_W
	CAP_MAX
end enum

enum ControlTypes
	CTRL_AI = -1
	CTRL_DESKTOP
	CTRL_LAPTOP
	CTRL_TABLET
	CTRL_KEYBOARD
	CTRL_JOYSTICK1
	CTRL_JOYSTICK2
	CTRL_JOYSTICK3
	CTRL_JOYSTICK4
end enum
const PAD_XS = 40
const PAD_SM = 80
const PAD_MED = 120
const PAD_LG = 160
const PAD_XL = 240
const PAD_2XL = 360
const PAD_3XL = 480
enum BallDesigns
	BALL_SM = 3
	BALL_MED
	BALL_LG
end enum

type Basics
	'Common Stuff
	X as single
	Y as single
	Spawned as ubyte
	Grabbed as double
	
	'Ball Stuff
	LHX as ubyte
	LHY as ubyte
	Angle as single
	Speed as single
	Invul as ushort
	Trapped as short
	Power as integer
	Duration as short
	Gravity as ushort
	ForceUngrab as ushort
	
	'Paddle Stuff
	Repairs as short
	Grabbing as short
	Sluggish as short
	Reverse as short
	Blizzard as short
end type
type ParticleSpecs
	X as Single
	Y as single
	XSpd as single
	YSpd as single
	Blending as short
	Coloring as uinteger
end type

type PalleteSpecs
	PColoring as uinteger
	ScoreValue as ushort
	DynamicValue as ubyte
	CanRegen as ubyte
	HitDegrade as byte
	ZapDegrade as short
	IncreaseSpeed as ubyte
	CalcedInvulnerable as byte
	UsedInlevel as ubyte
	TimesRespawned as ushort
end type
type TileSpecs
	BrickID as short
	BaseBricKID as short
	Flash as short
	HitTime as short
	LastBall as short
end type
type BackSpecs
	Filename as string
end type

type PlayerSpecs
	DispScore as uinteger
	Score as uinteger
	Lives as short
	Threshold as uinteger
	PerfectClear as byte
	Difficulty as double
	BulletAmmo as short
	MissileAmmo as short

	WarpTimer as short
	BossHealth as integer
	BossMaxHealth as integer
	BossLastHealth as integer
	BossLastHit as short
	LevelTimer as integer
	InitialLevel as short
	LevelNum as short
	PokerHand(5) as byte
	SetCleared as byte
	
	Tileset(41,24) as TileSpecs
	SavedGameStyle as uinteger
end type
type LevelsetSpecs
	Namee as string
	Folder as string
	Difficulty as string
	SetSize as integer
	TrueSize as integer
	StarsToUnlock as integer
	SetLocked as byte
	SetMastered as byte
end type
type HighSlot
	Namee as string
	RawScore as uinteger
	LevelStart as integer
	LevelFinal as integer
	Difficulty as double
	NewEntry as byte
end type

const ZapBrush = 36
const SwapBrush = ZapBrush + 1
const MaxPlayers = 6
dim shared as PlayerSpecs PlayerSlot(MaxPlayers), NewPlrSlot
dim shared as PalleteSpecs Pallete(SwapBrush)
dim shared as FB.event e
const MISC = 3
const ExplodeAniRate = 1
const NumBalls = 128
const MaxFallCaps = 12
const Particount = 2500
const BackCount = 99

dim shared as ushort MinSize, StandardSize, MaxSize, CapsFalling, BulletsInPlay, _
	Credits, CoinsPerCredit, CeleYear, BrickCount, XplodeCount, ZappableCount, Combo
dim shared as short PaddleSize, HintLevel, CampaignBarrier, BulletStart, BacksLoaded, BoxGlow
dim shared as HighSlot HighScore(TotalHighSlots)
dim shared as uinteger MouseX, MouseY, MouseColor, ButtonCombo, TotalXP, TotalStars
dim shared as uinteger GameStyle, TourneyStyle, TourneyScore, ShotIndex

dim shared as ubyte Fullscreen, JoyAnalog, JoyInvertAxes, TapWindow, CondensedLevel, AllowHandicap, ShuffleLevels, SpeedRunner
dim shared as integer LastActive, Result, OrigX(1), DesireX, JoyButtonCombo, ExplodingValue, BGBrightness, SpeedRunTimer
dim shared as single JoyAxis(7)
dim shared as short TotalBC, FrameSkip, PaddleCycle, ExplodeCycle, KeyboardSpeed, JoyKeySetting, ProgressiveBounces, BlockBrushes
dim shared as double ProgressiveQuota, InstructExpire, MisnExpire, TimeRem, Reminder = -1, _
	FrameTime, PaddlePercent, DifficultyRAM(MaxPlayers)
dim shared as string InType, ScoreFile, Instructions, CampaignFolder, BackList(BackCount), DiffTxt

dim shared as BackSpecs BackSlot(BackCount)
dim shared as Basics Paddle(2), Capsule(MaxFallCaps), Ball(NumBalls), Bullet(MaxBullets), LaserBeams(20,15)
dim shared as ParticleSpecs Particles(Particount)

dim shared as ubyte DQ, Player, NumPlayers, DispLives, Invis, GfxStyle, ExploTick, _
	BallSize,  MenuMode, HoldClick, HoldAction
dim shared as byte EnhancedGFX, GamePaused, TourneyValid, TotalMessages, TotalUnread, ControlStyle, SavedControls
dim shared as any ptr BulletPic, MissilePic, CapsulePic(26), CapsuleBar(5), CapsuleBarFrame, PokerBar(5), Background, PaddlePic, _
	SoftBrickPic, MultihitPic, InvinciblePic, ExplodePic, BaseExplode, SoftBrickConnL, SoftBrickConnR, SoftBrickConnT, SoftBrickConnB, _
	MultihitConnL, MultihitConnR, MultihitConnT, MultihitConnB, InvincibleConnL, InvincibleConnR, InvincibleConnT, InvincibleConnB, _
	SoftBrickPicMini, MultihitMini, InvincibleMini, SoftBrickConnMiniL, SoftBrickConnMiniR, SoftBrickConnMiniT, SoftBrickConnMiniB, _
	MultihitConnMiniL, MultihitConnMiniR, MultihitConnMiniT, MultihitConnMiniB, _
	InvincibleConnMiniL, InvincibleConnMiniR, InvincibleConnMiniT, InvincibleConnMiniB, _
	FramesetMerged, Sideframes, Topframe, DiffStick, DiffSelector, BasePaddle, PaddleBar

const Interpolation = 120 'Ball updates per frame
const CampaignsPerPage = 11 
const CustomizePerPage = 20
const PaddleHeight = 18
const CustomizePadding = 60
const CustomizeSelect = CustomizePadding - 5
dim shared as LevelsetSpecs OfficialCampaigns(CampaignsPerPage+1)
redim shared as LevelsetSpecs CommunityCampaigns(1)

enum BounceDirections
	BOUNCE_E = 1
	BOUNCE_NE
	BOUNCE_N
	BOUNCE_NW
	BOUNCE_W
	BOUNCE_SW
	BOUNCE_S
	BOUNCE_SE
end enum

function total_lives as integer
	dim as integer LivesFound
	for PID as ubyte = 1 to MaxPlayers
		with PlayerSlot(PID)
			LivesFound += .Lives
		end with
	next PID
	
	return LivesFound
end function

sub read_campaigns(StarsOnly as ubyte = 0)
	dim as integer CommunityFoldersFound = 0, LevelsCleared
	dim as string CommunityFolder
	TotalStars = 0
	
	for OCID as ubyte = 1 to 12 'Official campaigns first
		with OfficialCampaigns(OCID)
			.TrueSize = 0
			
			select case OCID
				case 1
					.Namee = "Introductory Training"
					.Folder = "official/intro"
					.Difficulty = "Easy"
					.SetSize = 10
				case 2
					.Namee = "Geometric Designs"
					.Folder = "official/geometry"
					.Difficulty = "Easy to Medium"
					.SetSize = 10
					.TrueSize = 15
				case 3
					.Namee = "Regular Season"
					.Folder = "official/regular"
					.Difficulty = "Easy to Hard"
					.SetSize = 30
					.TrueSize = 35
				case 4
					.Namee = "Fortified Letters"
					.Folder = "official/alphabet"
					.Difficulty = "Easy to Hard"
					.SetSize = 26
				case 5
					.Namee = "Electric Recharge"
					.Folder = "official/electric"
					.Difficulty = "Easy to Hard"
					.SetSize = 20
					.TrueSize = 25
				case 6
					.Namee = "Patriarch Memorial"
					.Folder = "official/memorial"
					.Difficulty = "Medium to Hard"
					.SetSize = 25
				case 7
					.Namee = "Fusion Designs"
					.Folder = "official/fusion"
					.Difficulty = "Medium to Hard"
					.SetSize = 20
					.StarsToUnlock = 15
				case 8
					.Namee = "Challenge Campaign"
					.Folder = "official/challenge"
					.Difficulty = "Hard to Extreme"
					.SetSize = 30
					.TrueSize = 35
					.StarsToUnlock = 25
				case 9
					.Namee = "Maximum Insanity"
					.Folder = "official/extreme"
					.Difficulty = "Very Hard to Extreme"
					.SetSize = 25
					.StarsToUnlock = 75
				case 10
					.Namee = "Celestial Journey"
					.Folder = "official/universe"
					.Difficulty = "Hard to Extreme"
					.SetSize = 40
					.TrueSize = 50
					.StarsToUnlock = 125
				case 11
					.Namee = "Endless Shuffle"
					.Folder = "official/endless"
					.Difficulty = "Unpredictable"
					.SetSize = 1000
					if TotalStars >= 236 then
						.StarsToUnlock = TotalOfficialLevels 'ALL of the previous levels
					else
						.StarsToUnlock = 1000 'Keep the player from knowing the exact requirement at first
					end if
				case 12
					.Namee = "(Community campaigns)"
					.SetSize = 0
				case else
					.Namee = ""
					.SetSize = 0
					.SetLocked = -1
			end select
			
			if .Namee <> "" AND .Folder <> EndlessFolder then
				if .TrueSize = 0 then
					.TrueSize = .SetSize
				end if
				
				if FileExists(.Namee+".dat") then
					open .Namee+".dat" for input as #19
					input #19, LevelsCleared
					close #19
					
					.SetMastered = -abs(sgn(FileExists(.Namee+".flag")))
					if .SetMastered AND LevelsCleared < .TrueSize then
						/'
						 ' Invalidate mastery if this was a false final level clear
						 ' (Keep the star credit, though)
						 '/
						.SetMastered = 0
					elseif .SetMastered = 0 then
						'Campaign has not been cleared; exclude a star from this calculation
						LevelsCleared -= 1
					end if
				else
					LevelsCleared = 0
				end if
				
				if OCID <= CampaignsPerPage then
					'In case a player died on a secret level, register it as having been seen
					.SetSize = max(.SetSize,LevelsCleared + 1 + .SetMastered)
					TotalStars += LevelsCleared
				end if
			end if
		end with
	next OCID
	
	if StarsOnly = 0 then
		'Scan community campaigns afterwards
		CommunityFolder = Dir(MasterDir+"/campaigns/community/*",fbDirectory)
		while len( CommunityFolder ) > 0
			if CommunityFolder <> "." AND CommunityFolder <> ".." then
				CommunityFoldersFound += 1
				redim preserve CommunityCampaigns(CommunityFoldersFound)
				with CommunityCampaigns(CommunityFoldersFound)
					.Namee = CommunityFolder
					.Folder = "community/"+CommunityFolder
					
					for LID as short = 1 to 999
						if FileExists(MasterDir+"/campaigns/"+.Folder+"/L"+str(LID)+".txt") = 0 then
							.SetSize = LID - 1
							exit for
						end if
					next LID
				end with
			end if
			CommunityFolder = Dir()
		wend
		
		OfficialCampaigns(12).SetSize = CommunityFoldersFound
	end if
end sub

sub load_title_capsules
	dim as string TitleCaps(1 to 26) => {"slow", "split", "grab", "spread", "detonate", "zap", "bullet", "blizzard", "fire", "thru", "missile", "warp", "life", _
		"fast", "weak", "max", "gravity", "reverse", "slowpad", "", "expand", "reduce", "mystery", "disruption", "extender", "negater"}
	for PID as byte = 1 to 26
		if TitleCaps(PID) <> "" then
			bload(Masterdir+"/gfx/caps/"+TitleCaps(PID)+".bmp",CapsulePic(PID))
		end if
	next PID
end sub 

sub toggle_fullscreen(ForceSetting as byte = 0)
	if (FullScreen = 0 OR ForceSetting = 1) AND ForceSetting <> -1 then
		FullScreen = 1
		screen 20,24,2,GFX_FULLSCREEN OR GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
		screenset 1,0
		setmouse(,,0,0)
		open "FS.ini" for output as #9
		close #9
	else
		FullScreen = 0
		screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
		screenset 1,0
		setmouse(,,0,0)
		kill("FS.ini")
	end if
end sub

sub draw_border(Model as any ptr, StartX as short, StartY as short, EndX as short, EndY as short, Opacity as short)
	line Model,(StartX,StartY)-(EndX,StartY),rgba(255,255,255,Opacity)
	line Model,(StartX,StartY)-(StartX,EndY),rgba(255,255,255,Opacity)
	line Model,(EndX,StartY+1)-(EndX,EndY-1),rgba(0,0,0,Opacity)
	line Model,(StartX+1,EndY)-(EndX,EndY),rgba(0,0,0,Opacity)
end sub
sub draw_box(StartX as short,StartY as short,EndX as short,EndY as short)
	BoxGlow -= 3
	if BoxGlow <= -128 then
		BoxGlow += 255
	end if

	dim as uinteger DrawColor
	dim as short PaintStr
	
	for BID as short = 0 to 4
		PaintStr = BoxGlow - (BID*24)
		while PaintStr <= -128
			PaintStr += 255
		wend
		DrawColor = rgba(255,128,128,128+abs(PaintStr))
		
		line(StartX+BID,StartY+BID)-(EndX-BID,StartY+BID),DrawColor
		line(StartX+BID,StartY+BID+1)-(StartX+BID,EndY-BID),DrawColor
		line(EndX-BID,StartY+BID+1)-(EndX-BID,EndY-BID),DrawColor
		line(StartX+BID+1,EndY-BID)-(EndX-BID-1,EndY-BID),DrawColor
	next BID
end sub

sub get_difficulty_names(DifficultyAmt as double)
	select case int(DifficultyAmt+0.5)
		case DIFF_KIDS
			DiffTxt = "Effortless"
		case DIFF_VEASY
			DiffTxt = "Very Easy"
		case DIFF_EASY
			DiffTxt = "Easy"
		case DIFF_MEASY
			DiffTxt = "Medium Easy"
		case DIFF_MEDIUM
			DiffTxt = "Medium"
		case DIFF_MHARD
			DiffTxt = "Medium Hard"
		case DIFF_HARD
			DiffTxt = "Hard"
		case DIFF_VHARD
			DiffTxt = "Very Hard"
		case DIFF_EXTREME
			DiffTxt = "Extreme"
		case else
			if DifficultyAmt < 11 then
				DiffTxt = "Insane"
			else
				DiffTxt = "Nightmare"
			end if
	end select
end sub

sub render_paddle(NewSize as short)
	if NewSize > 960 then
		NewSize = 960
	end if
	PaddleSize = NewSize
	PaddleCycle += 1
	if PaddleCycle >= 120*10 then
		PaddleCycle = 0
	end if
	put PaddlePic,(-int(PaddleCycle/10),0),BasePaddle,pset
	line PaddlePic,(PaddleSize,0)-(1079,PaddleHeight-1),rgb(255,0,255),bf
	for BID as ubyte = 0 to int(sqr(PaddleSize/20))
		draw_border(PaddlePic,BID,BID,PaddleSize-1-BID,PaddleHeight-1-BID,255-BID*32)
	next BID
end sub
sub particle_system
	if EnhancedGFX > 0 then
		for PID as ushort = 0 to Particount
			with Particles(PID)
				if .Y < 768 AND .Blending > 0 then
					.Coloring = rgba(retrivePrimary(.Coloring,RGBA_RED),_
						retrivePrimary(.Coloring,RGBA_GREEN),_
						retrivePrimary(.Coloring,RGBA_BLUE),.Blending)
					pset(.X,.Y),.Coloring
					if .Blending > 0 then
						.Blending -= 1
					end if
					.X += .XSpd
					.Y += .YSpd
					.YSpd += 1.6/60
				end if
			end with
		next
	else
		for PID as ushort = 0 to Particount
			with Particles(PID)
				.Y = 800
				.Blending = 0
			end with
		next
	end if
end sub
sub generate_particles(NewCount as integer, XL as byte, YL as byte, _
	ApplyColor as uinteger)
	dim as integer NewParticle, FreeParticles, TrueCount

	for PID as integer = 1 to Particount
		with Particles(PID)
			if .Y >= 768 OR .Blending <= 0 then
				FreeParticles += 1
			end if
		end with
	next PID
	
	if NewCount <= 100 then
		TrueCount = NewCount
	else
		TrueCount = 100 + int(sqr(NewCount - 100))
	end if

	for PID as integer = 1 to TrueCount
		if FreeParticles = 0 then
			exit for
		end if
		
		do
			NewParticle = irandom(1,Particount)
		loop until Particles(NewParticle).Y >= 768 OR _
			Particles(NewParticle).Blending <= 0

		with Particles(NewParticle)
			.X = 32 + ((XL - 1) * 48 + irandom(12,36))/(CondensedLevel+1)
			.Y = (YL - 1) * 24 + irandom(102,114)
			.YSpd = rnd * -2.5
			.XSpd = (rnd - 0.5) * 2
			.Blending = 255
			.Coloring = ApplyColor
		end with

		FreeParticles -= 1 
	next PID
end sub

sub force_release_balls
	for BID as short = 1 to NumBalls
		with Ball(BID)
			if .Grabbed > 0 then
				.Grabbed = int(.Grabbed/1000)*1000 + 1
			end if
			.ForceUngrab = 6
		end with
	next
end sub

sub optimal_direction(InBall as short, BrickX as byte, BrickY as byte)
	dim as short StartX, BWidth, StartY, BHeight
	dim as double CenterX, CenterY, PreviousX, PreviousY, DeltaX, DeltaY, NewDX, NewDY, NewDZ, InternalMultiplier
	dim as ubyte BounceAngle, SwapSpecs
	
	'Determine the coordinates and specs of the brick in question
	BWidth = 48/(CondensedLevel + 1)
	BHeight = 24
	StartX = 32+(BrickX-1)*BWidth
	StartY = 96+(BrickY-1)*BHeight

	'Consolidate adjacent bricks to form a larger mass
	if BrickX = 1 OR PlayerSlot(Player).TileSet(int(BrickX-1),BrickY).BrickID > 0 then
		StartX -= 48/(CondensedLevel + 1)
		BWidth += 48/(CondensedLevel + 1)
	end if
	if BrickX >= 20 * (CondensedLevel + 1) OR PlayerSlot(Player).TileSet(int(BrickX+1),BrickY).BrickID > 0 then
		BWidth += 48/(CondensedLevel + 1)
	end if

	if BrickY > 1 AND PlayerSlot(Player).TileSet(BrickX,int(BrickY-1)).BrickID > 0 then
		StartY -= 24
		BHeight += 24
	end if
	if BrickY < 20 AND PlayerSlot(Player).TileSet(BrickX,int(BrickY+1)).BrickID > 0 then
		BHeight += 24
	end if

	CenterX = StartX + BWidth/2
	CenterY = StartY + BHeight/2
			
	'Use the current vector and previous position
	with Ball(InBall)
		InternalMultiplier = int(.Speed) / 1.3 / Interpolation
		if (GameStyle AND (1 SHL STYLE_HYPER)) then
			InternalMultiplier *= 1.5
		end if
		
		DeltaX = cos(degtorad(.Angle))
		DeltaY = -sin(degtorad(.Angle))
		
		PreviousX = .X - DeltaX * InternalMultiplier
		PreviousY = .Y - DeltaY * InternalMultiplier

		NewDX = DeltaX
		NewDY = -DeltaY

		if (PreviousY >= StartY + BHeight) then
			BounceAngle = BOUNCE_S
		elseif (PreviousY <= StartY) then
			BounceAngle = BOUNCE_N
		end if
			
		if (PreviousX < StartX) then
			if BounceAngle = BOUNCE_S then
				BounceAngle = BOUNCE_SW
			elseif BounceAngle = BOUNCE_N then
				BounceAngle = BOUNCE_NW
			else
				BounceAngle = BOUNCE_W
			end if
		elseif (PreviousX > StartX + BWidth) then
			if BounceAngle = BOUNCE_S then
				BounceAngle = BOUNCE_SE
			elseif BounceAngle = BOUNCE_N then
				BounceAngle = BOUNCE_NE
			else
				BounceAngle = BOUNCE_E
			end if
		end if
	end with
	
	if BounceAngle = BOUNCE_NE OR BounceAngle = BOUNCE_NW then
		BounceAngle = BOUNCE_N
	elseif BounceAngle = BOUNCE_SE OR BounceAngle = BOUNCE_SW then
		BounceAngle = BOUNCE_S
	end if
	
	select case BounceAngle
		case BOUNCE_E
			NewDX = abs(DeltaX)
		case BOUNCE_NE
			NewDX = abs(DeltaX)
			NewDY = abs(DeltaY)
		case BOUNCE_N
			NewDY = abs(DeltaY)
			if NewDY = 0 then
				NewDY = -1
			end if
		case BOUNCE_NW
			NewDX = -abs(DeltaX)
			NewDY = abs(DeltaY)
		case BOUNCE_W
			NewDX = -abs(DeltaX)
		case BOUNCE_SW
			NewDX = -abs(DeltaX)
			NewDY = -abs(DeltaY)
		case BOUNCE_S
			NewDY = -abs(DeltaY)
			if NewDY = 0 then
				NewDY = -1
			end if
		case BOUNCE_SE
			NewDX = abs(DeltaX)
			NewDY = -abs(DeltaY)
	end select
	
	if SwapSpecs then
		NewDZ = NewDX
		NewDX = NewDY
		NewDY = NewDZ
	end if
	
	with Ball(InBall)
		.Angle = 3600 + radtodeg(atn(NewDY/NewDX))
		
		if NewDX < 0 then
			.Angle += 180
		end if
	end with
end sub
sub save_unlocks
	open "conf.ini" for output as #10
	for Plr as byte = 1 to MaxPlayers
		print #10, "difficulty,"& PlayerSlot(Plr).Difficulty
	next Plr
	print #10, "handicap,";AllowHandicap
	print #10, "hintlv,"& HintLevel
	print #10, "enhanced,"& EnhancedGFX
	print #10, "controls,";ControlStyle
	print #10, "campbarr,";CampaignBarrier
	print #10, "shuffle,";ShuffleLevels
	print #10, "bgbright,"& BGBrightness
	print #10, "musplayer,"& MusicPlrEnabled
	print #10, "xp,"& TotalXP
	print #10, "speedrun,";SpeedRunner
	close #10
	kill("xp.dat")
end sub

function ball_ct_bonus as byte
	'The Computer Player does not benefit from Multiball bonus
	if ControlStyle = CTRL_AI then
		return 1
	end if
	
	'Otherwise, more balls = more points per block; subject to Diminishing Returns
	return int(sqr(TotalBC) + 0.5)
end function

sub respawn_blocks(BrushID as short)
	dim as ushort BlocksRespawned = 0
	
	'Respawns all blocks that were origianlly bound to the selected brush
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 20*(CondensedLevel+1)
			with PlayerSlot(Player).TileSet(XID,YID)
				if .BrickID = 0 AND .BaseBrickID = BrushID then
					BlocksRespawned += 1
					.BrickID = .BaseBrickID
					.Flash = BaseFlash - 1
				end if
			end with
		next XID
	next YID
	
	if BlocksRespawned > 0 then
		'Damages the ceiling slightly
		with PlayerSlot(Player)
			.BossLastHealth = .BossHealth
			.BossLastHit = 0
			.BossHealth -= max(int(.BossMaxHealth/100),1)
			
			if .BossHealth <= 0 then
				play_clip(SFX_WALL_BROKEN)
			end if
		end with
		
		play_clip(SFX_BRICKS_RESPAWN)
	end if
end sub

declare sub damage_brick(BaseX as short, BaseY as short, NewPalette as short, NewID as short = 0, OnlySelf as byte = 0)

function disp_wall(FrameTick as short, DispSetting as byte = 0) as integer
	dim as ubyte AlphaV
	dim as uinteger Coloring, ScoreBonus, Count, XPanning
	dim as byte RefPallete, MaxY
	dim as ubyte BlocksInPallete(35)
	dim as string PrintChar
	
	XplodeCount = 0
	ZappableCount = 0
	if ExploTick >= 6*(CondensedLevel+1) then
		ExplodeCycle += 32
		ExploTick = 0
	end if
	if ExplodeCycle >= 128*ExplodeAniRate then
		ExplodeCycle = 0
	end if
	
	put ExplodePic,(-int(ExplodeCycle/ExplodeAniRate),0),BaseExplode,pset
	if CondensedLevel then
		line ExplodePic,(24,0)-(47,23),rgb(255,0,255),bf
		
		if (Gamestyle AND (1 SHL STYLE_FUSION)) = 0 then
			for BID as ubyte = 0 to 1
				draw_border(ExplodePic,BID,BID,23-BID,23-BID,255-BID*127)
			next BID
		end if
	elseif (Gamestyle AND (1 SHL STYLE_FUSION)) = 0 then
		for BID as ubyte = 0 to 1
			draw_border(ExplodePic,BID,BID,47-BID,23-BID,255-BID*127)
		next BID
	end if
	
	if DispSetting = 2 then
		MaxY = 24
	else
		MaxY = 20
	end if
	
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 20*(CondensedLevel+1)
			with PlayerSlot(Player).Tileset(XID,YID)
				if YID <= MaxY then
					if .BrickID <= -1 then
						if CondensedLevel then
							XPanning = 48+(XID-1)*24
							put(32+(XID-1)*24,96+(YID-1)*24),ExplodePic,trans
							line(32+(XID-1)*24,96+(YID-1)*24)-_
								(31+(XID)*24,95+(YID)*24),rgba(255,128,0,128),bf
						else
							XPanning = 56+(XID-1)*48
							put(32+(XID-1)*48,96+(YID-1)*24),ExplodePic,trans
							line(32+(XID-1)*48,96+(YID-1)*24)-_
								(31+(XID)*48,95+(YID)*24),rgba(255,128,0,128),bf
						end if
						if GamePaused = 0 then
							if .BrickID < -1 then
								'Exploding in progress
								.BrickID += 1
								Invis = 12
							else
								'Finish exploding
								for YDID as byte = YID - 1 to YID + 1
									for XDID as byte = XID - 1 to XID + 1
										if XDID > 0 AND XDID <= 20*(CondensedLevel+1) AND YDID > 0 AND YDID <= 20 then
											RefPallete = PlayerSlot(Player).TileSet(XDID,YDID).BrickID
											
											if RefPallete > 0 OR (XDID = XID AND YDID = YID) then
												if (RefPallete > 0 AND Pallete(RefPallete).CalcedInvulnerable >= 0) OR _
													(XDID = XID AND YDID = YID) then
													
													if TotalBC > 0 then
														ScoreBonus = ball_ct_bonus * ExplodingValue
													elseif total_lives > 0 then
														ScoreBonus = ExplodingValue
													end if
													
													PlayerSlot(Player).Score += ScoreBonus
													damage_brick(XDID,YDID,0,0,(XDID = XID AND YDID = YID))
													Invis = 12
													generate_capsule(XDID,YDID,1)
													generate_particles(ScoreBonus,XDID,YDID,rgb(255,192,160))
													
												else
													damage_brick(XDID,YDID,ExplodeDelay,0)
													
													if (XDID > XID AND YID = YDID) OR YDID > YID then
														PlayerSlot(Player).TileSet(XDID,YDID).BrickID -= 1 
													end if
													
													generate_capsule(XDID,YDID,1)
													Invis = 12
												end if
												
											end if
										end if
									next XDID
								next YDID
								
								play_clip(SFX_EXPLODE,XPanning)
							end if
						end if
						
						Count += 1
						
					elseif .BrickID > 0 then
						'Other blocks
						if .BrickID <> Pallete(.BrickID).ZapDegrade then
							ZappableCount += 1
						end if
	
						if DispSetting >= 1 then
							with Pallete(.BrickID)
								if .PColoring = 0 then
									if DispSetting = 2 then
										if PlayerSlot(Player).TileSet(XID,YID).BrickID < 10 then
											PrintChar = str(PlayerSlot(Player).TileSet(XID,YID).BrickID)
										else	
											PrintChar = chr(55+PlayerSlot(Player).TileSet(XID,YID).BrickID)
										end if
	
										if CondensedLevel then
											line(32+(XID-1)*24,96+(YID-1)*24)-_
												(31+(XID)*24,95+(YID)*24),rgb(255,255,255),b,&b1010101010101010
												
											printgfx(PrintChar,41+(XID-1)*24,103+(YID-1)*24,2,rgb(255,255,255))
										else	
											line(32+(XID-1)*48,96+(YID-1)*24)-_
												(31+(XID)*48,95+(YID)*24),rgb(255,255,255),b,&b1010101010101010
												
											printgfx(PrintChar,53+(XID-1)*48,103+(YID-1)*24,2,rgb(255,255,255))
										end if
									end if
									if PlayerSlot(Player).TileSet(XID,YID).BrickID <> .HitDegrade AND .CalcedInvulnerable < 2 then
										Count += 1
									end if
								elseif (Invis > 0 OR (GameStyle AND (1 SHL STYLE_INVIS)) = 0 OR total_lives = 0) then
									dim as any ptr UseBrick, UseConnL, UseConnR, UseConnT, UseConnB
									
									if CondensedLevel then
										if .CalcedInvulnerable > 0 then
											UseBrick = InvincibleMini
											UseConnL = InvincibleConnMiniL
											UseConnR = InvincibleConnMiniR
											UseConnT = InvincibleConnMiniT
											UseConnB = InvincibleConnMiniB
											
											if PlayerSlot(Player).TileSet(XID,YID).BrickID <> .HitDegrade AND .CalcedInvulnerable < 2 then
												Count += 1
											end if
										elseif .HitDegrade < 0 then
											UseBrick = ExplodePic
											UseConnL = NULL
											UseConnR = NULL
											UseConnT = NULL
											UseConnB = NULL
											
											XplodeCount += 1
											Count += 1
										elseif .HitDegrade > 0 OR .CanRegen > 0 then
											UseBrick = MultihitMini
											UseConnL = MultihitConnMiniL
											UseConnR = MultihitConnMiniR
											UseConnT = MultihitConnMiniT
											UseConnB = MultihitConnMiniB
											
											Count += 1
										else 
											UseBrick = SoftBrickPicMini
											UseConnL = SoftBrickConnMiniL
											UseConnR = SoftBrickConnMiniR
											UseConnT = SoftBrickConnMiniT
											UseConnB = SoftBrickConnMiniB
											
											Count += 1
										end if
										put(32+(XID-1)*24,96+(YID-1)*24),UseBrick,trans
										with PlayerSlot(Player).TileSet(XID,YID)
											if (Gamestyle AND (1 SHL STYLE_FUSION)) AND .BaseBrickID > 0 then
												if Pallete(.BrickID).HitDegrade >= 0 then
													if XID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(int(XID-1),YID).BaseBrickID then
														put(32+(XID-1)*24,96+(YID-1)*24),UseConnL,trans
													end if
													if XID < 40 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID+1,YID).BaseBrickID then
														put(32+(XID-1)*24,96+(YID-1)*24),UseConnR,trans
													end if
													if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
														put(32+(XID-1)*24,96+(YID-1)*24),UseConnT,trans
													end if
													if YID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,YID+1).BaseBrickID then
														put(32+(XID-1)*24,96+(YID-1)*24),UseConnB,trans
													end if
												else
													'Complicated mini-exploding edge cases
													
													'Left connectors
													if XID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(int(XID-1),YID).BaseBrickID then
														pset(32+(XID-1)*24,96+(YID-1)*24),rgb(255,255,255)
														line(32+(XID-1)*24,97+(YID-1)*24)-(33+(XID-1)*24,97+(YID-1)*24),rgba(255,255,255,128)
														
														line(32+(XID-1)*24,94+(YID)*24)-(33+(XID-1)*24,94+(YID)*24),rgba(0,0,0,128)
														pset(32+(XID-1)*24,95+(YID)*24),rgb(0,0,0)
													else
														line(32+(XID-1)*24,96+(YID-1)*24)-(32+(XID-1)*24,95+(YID)*24),rgb(255,255,255)
														line(33+(XID-1)*24,97+(YID-1)*24)-(33+(XID-1)*24,94+(YID)*24),rgba(255,255,255,128)
													end if
													
													'Right connectors
													if XID < 40 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID+1,YID).BaseBrickID then
														pset(31+(XID)*24,96+(YID-1)*24),rgb(255,255,255)
														line(30+(XID)*24,97+(YID-1)*24)-(31+(XID)*24,97+(YID-1)*24),rgba(255,255,255,128)
														
														line(30+(XID)*24,94+(YID)*24)-(31+(XID)*24,94+(YID)*24),rgba(0,0,0,128)
														pset(31+(XID)*24,95+(YID)*24),rgb(0,0,0)
													else
														if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
															pset(31+(XID)*24,96+(YID-1)*24),rgb(0,0,0)
															pset(30+(XID)*24,97+(YID-1)*24),rgba(0,0,0,128)
														else
															pset(31+(XID)*24,96+(YID-1)*24),rgb(255,255,255)
															pset(30+(XID)*24,97+(YID-1)*24),rgba(255,255,255,128)
														end if
														
														line(31+(XID)*24,97+(YID-1)*24)-(31+(XID)*24,95+(YID)*24),rgb(0,0,0)
														line(30+(XID)*24,98+(YID-1)*24)-(30+(XID)*24,94+(YID)*24),rgba(0,0,0,128)
													end if
													
													'Top connectors
													if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
														pset(33+(XID-1)*24,96+(YID-1)*24),rgba(255,255,255,128)
														pset(30+(XID)*24,96+(YID-1)*24),rgba(0,0,0,128)
													else
														line(33+(XID-1)*24,96+(YID-1)*24)-(30+(XID)*24,96+(YID-1)*24),rgb(255,255,255)
														line(34+(XID-1)*24,97+(YID-1)*24)-(29+(XID)*24,97+(YID-1)*24),rgba(255,255,255,128)
													end if
													
													'Bottom connectors
													if YID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,YID+1).BaseBrickID then
														pset(33+(XID-1)*24,95+(YID)*24),rgba(255,255,255,128)
														pset(30+(XID)*24,95+(YID)*24),rgba(0,0,0,128)
													else
														line(33+(XID-1)*24,95+(YID)*24)-(30+(XID)*24,95+(YID)*24),rgb(0,0,0)
														line(34+(XID-1)*24,94+(YID)*24)-(29+(XID)*24,94+(YID)*24),rgba(0,0,0,128)
													end if
												end if
											end if
										end with
										
										line(32+(XID-1)*24,96+(YID-1)*24)-_
											(31+(XID)*24,95+(YID)*24),.PColoring,bf
									else
										if .CalcedInvulnerable > 0 then
											UseBrick = InvinciblePic
											UseConnL = InvincibleConnL
											UseConnR = InvincibleConnR
											UseConnT = InvincibleConnT
											UseConnB = InvincibleConnB
											
											if PlayerSlot(Player).TileSet(XID,YID).BrickID <> .HitDegrade AND .CalcedInvulnerable < 2 then
												Count += 1
											end if
										elseif .HitDegrade < 0 then
											UseBrick = ExplodePic
											UseConnL = NULL
											UseConnR = NULL
											UseConnT = NULL
											UseConnB = NULL
											
											XplodeCount += 1
											Count += 1
										elseif .HitDegrade > 0 OR .CanRegen > 0 then
											UseBrick = MultihitPic
											UseConnL = MultihitConnL
											UseConnR = MultihitConnR
											UseConnT = MultihitConnT
											UseConnB = MultihitConnB
											
											Count += 1
										else 
											UseBrick = SoftBrickPic
											UseConnL = SoftBrickConnL
											UseConnR = SoftBrickConnR
											UseConnT = SoftBrickConnT
											UseConnB = SoftBrickConnB
											
											Count += 1
										end if

										put(32+(XID-1)*48,96+(YID-1)*24),UseBrick,trans
										with PlayerSlot(Player).TileSet(XID,YID)
											if (Gamestyle AND (1 SHL STYLE_FUSION)) AND .BaseBrickID > 0 then
												if Pallete(.BrickID).HitDegrade >= 0 then
													if XID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(int(XID-1),YID).BaseBrickID then
														put(32+(XID-1)*48,96+(YID-1)*24),UseConnL,trans
													end if
													if XID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID+1,YID).BaseBrickID then
														put(32+(XID-1)*48,96+(YID-1)*24),UseConnR,trans
													end if
													if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
														put(32+(XID-1)*48,96+(YID-1)*24),UseConnT,trans
													end if
													if YID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,YID+1).BaseBrickID then
														put(32+(XID-1)*48,96+(YID-1)*24),UseConnB,trans
													end if
												else
													'Complicated exploding edge cases
													
													'Left connectors
													if XID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(int(XID-1),YID).BaseBrickID then
														pset(32+(XID-1)*48,96+(YID-1)*24),rgb(255,255,255)
														line(32+(XID-1)*48,97+(YID-1)*24)-(33+(XID-1)*48,97+(YID-1)*24),rgba(255,255,255,128)
														
														line(32+(XID-1)*48,94+(YID)*24)-(33+(XID-1)*48,94+(YID)*24),rgba(0,0,0,128)
														pset(32+(XID-1)*48,95+(YID)*24),rgb(0,0,0)
													else
														line(32+(XID-1)*48,96+(YID-1)*24)-(32+(XID-1)*48,95+(YID)*24),rgb(255,255,255)
														line(33+(XID-1)*48,97+(YID-1)*24)-(33+(XID-1)*48,94+(YID)*24),rgba(255,255,255,128)
													end if
													
													'Right connectors
													if XID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID+1,YID).BaseBrickID then
														pset(31+(XID)*48,96+(YID-1)*24),rgb(255,255,255)
														line(30+(XID)*48,97+(YID-1)*24)-(31+(XID)*48,97+(YID-1)*24),rgba(255,255,255,128)
														
														line(30+(XID)*48,94+(YID)*24)-(31+(XID)*48,94+(YID)*24),rgba(0,0,0,128)
														pset(31+(XID)*48,95+(YID)*24),rgb(0,0,0)
													else
														if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
															pset(31+(XID)*48,96+(YID-1)*24),rgb(0,0,0)
															pset(30+(XID)*48,97+(YID-1)*24),rgba(0,0,0,128)
														else
															pset(31+(XID)*48,96+(YID-1)*24),rgb(255,255,255)
															pset(30+(XID)*48,97+(YID-1)*24),rgba(255,255,255,128)
														end if
														
														line(31+(XID)*48,97+(YID-1)*24)-(31+(XID)*48,95+(YID)*24),rgb(0,0,0)
														line(30+(XID)*48,98+(YID-1)*24)-(30+(XID)*48,94+(YID)*24),rgba(0,0,0,128)
													end if
													
													'Top connectors
													if YID > 1 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,int(YID-1)).BaseBrickID then
														pset(33+(XID-1)*48,96+(YID-1)*24),rgba(255,255,255,128)
														pset(30+(XID)*48,96+(YID-1)*24),rgba(0,0,0,128)
													else
														line(33+(XID-1)*48,96+(YID-1)*24)-(30+(XID)*48,96+(YID-1)*24),rgb(255,255,255)
														line(34+(XID-1)*48,97+(YID-1)*24)-(29+(XID)*48,97+(YID-1)*24),rgba(255,255,255,128)
													end if
													
													'Bottom connectors
													if YID < 20 AND .BaseBrickID = PlayerSlot(Player).TileSet(XID,YID+1).BaseBrickID then
														pset(33+(XID-1)*48,95+(YID)*24),rgba(255,255,255,128)
														pset(30+(XID)*48,95+(YID)*24),rgba(0,0,0,128)
													else
														line(33+(XID-1)*48,95+(YID)*24)-(30+(XID)*48,95+(YID)*24),rgb(0,0,0)
														line(34+(XID-1)*48,94+(YID)*24)-(29+(XID)*48,94+(YID)*24),rgba(0,0,0,128)
													end if
												end if
											end if
										end with
										
										line(32+(XID-1)*48,96+(YID-1)*24)-_
											(31+(XID)*48,95+(YID)*24),.PColoring,bf
									end if
									
									if DispSetting = 2 AND retrivePrimary(.PColoring,RGBA_ALPHA) >= 224 then
										if PlayerSlot(Player).TileSet(XID,YID).BrickID < 10 then
											PrintChar = str(PlayerSlot(Player).TileSet(XID,YID).BrickID)
										else	
											PrintChar = chr(55+PlayerSlot(Player).TileSet(XID,YID).BrickID)
										end if
										
										if CondensedLevel then
											for OffsetY as byte = 0 to 2 step 2
												for OffsetX as byte = 0 to 2 step 2
													printgfx(PrintChar,40+(XID-1)*24+OffsetX,102+(YID-1)*24+OffsetY,2,rgb(0,0,0))
												next OffsetX
											next OffsetY
												
											printgfx(PrintChar,41+(XID-1)*24,103+(YID-1)*24,2,rgb(255,255,255))
										else	
											for OffsetY as byte = 0 to 2 step 2
												for OffsetX as byte = 0 to 2 step 2
													printgfx(PrintChar,52+(XID-1)*48+OffsetX,102+(YID-1)*24+OffsetY,2,rgb(0,0,0))
												next OffsetX
											next OffsetY
												
											printgfx(PrintChar,53+(XID-1)*48,103+(YID-1)*24,2,rgb(255,255,255))
										end if
									end if
								elseif PlayerSlot(Player).TileSet(XID,YID).BrickID <> .HitDegrade AND .CalcedInvulnerable < 2 then
									Count += 1
								end if
							end with
						else
							Count += 1
						end if
					end if
				end if
				
				if .Flash > 0 then
					if CondensedLevel then
						line(32+(XID-1)*24,96+(YID-1)*24)-_
							(31+(XID)*24,95+(YID)*24),rgba(255,255,255,.Flash),bf
					else
						line(32+(XID-1)*48,96+(YID-1)*24)-_
							(31+(XID)*48,95+(YID)*24),rgba(255,255,255,.Flash),bf
					end if
					.Flash -= 4
				end if
				
				if FrameTick >= 100 then
					.HitTime += 1
				end if
				if .BrickID > 0 AND .HitTime >= 240 AND Pallete(.BrickID).CanRegen > 0 then
					.BrickID = Pallete(.BrickID).CanRegen
					.HitTime = 0
					.LastBall = 0
				end if
				
				if .BrickID > 0 then
					dim as short UseID = .BaseBrickID
					
					if UseID <= 35 AND BlocksInPallete(UseID) = 0 then
						BlocksInPallete(UseID) = 1
					end if
				end if
				if DispSetting >= 2 AND ButtonCombo = 0 then
					.BaseBrickID = .BrickID
				end if
			end with
		next XID
	next YID
	
	if (Gamestyle AND (1 SHL STYLE_BREAKABLE_CEILING)) AND DispSetting < 2 AND PlayerSlot(Player).BossHealth > 0 then
		for BID as ubyte = 1 to BlockBrushes
			if Pallete(BID).UsedInlevel > 0 AND BlocksInPallete(BID) = 0 then
				respawn_blocks(BID)
			end if
		next BID
	end if
	if Invis > 0 then
		Invis -= 1
	end if
	return Count
end function

sub disp_mouse(MX as integer, MY as integer, MC as uinteger)
	for NID as ubyte = 1 to 10
		line (MX+NID,MY+NID)-(MX+20,MY+10),MC
		line (MX+NID,MY+NID)-(MX+10,MY+20),MC
	next NID
	line (MX,MY)-(MX+20,MY+10),rgb(0,0,0)
	line (MX,MY)-(MX+10,MY+20),rgb(0,0,0)
	line (MX+20,MY+10)-(MX+10,MY+10),rgb(0,0,0)
	line (MX+10,MY+10)-(MX+10,MY+20),rgb(0,0,0)
end sub

sub shuffle_backs
	randomize timer

	dim as byte SlotUsed(BackCount)
	dim as short UseSlot
	for Stream as short = 0 to BacksLoaded - 1
		do
			UseSlot = int(rnd * BacksLoaded)
		loop until SlotUsed(UseSlot) = 0
		
		BackSlot(UseSlot).Filename = BackList(Stream)
		SlotUsed(UseSlot) = 1
	next Stream
	
	erase SlotUsed
end sub

sub load_brick_gfx(BasePath as string)
	'Rectangular bricks
	SoftBrickPic = ImageCreate(48,24)
	bload(BasePath+"soft.bmp",SoftBrickPic)
	MultihitPic = ImageCreate(48,24)
	bload(BasePath+"multi.bmp",MultihitPic)
	InvinciblePic = ImageCreate(48,24)
	bload(BasePath+"invincible.bmp",InvinciblePic)

	'Rectangular brick connectors
	SoftBrickConnL = ImageCreate(48,24)
	bload(BasePath+"softConnL.bmp",SoftBrickConnL)
	SoftBrickConnR = ImageCreate(48,24)
	bload(BasePath+"softConnR.bmp",SoftBrickConnR)
	SoftBrickConnT = ImageCreate(48,24)
	bload(BasePath+"softConnT.bmp",SoftBrickConnT)
	SoftBrickConnB = ImageCreate(48,24)
	bload(BasePath+"softConnB.bmp",SoftBrickConnB)

	MultihitConnL = ImageCreate(48,24)
	bload(BasePath+"multiConnL.bmp",MultihitConnL)
	MultihitConnR = ImageCreate(48,24)
	bload(BasePath+"multiConnR.bmp",MultihitConnR)
	MultihitConnT = ImageCreate(48,24)
	bload(BasePath+"multiConnT.bmp",MultihitConnT)
	MultihitConnB = ImageCreate(48,24)
	bload(BasePath+"multiConnB.bmp",MultihitConnB)

	InvincibleConnL = ImageCreate(48,24)
	bload(BasePath+"invinConnL.bmp",InvincibleConnL)
	InvincibleConnR = ImageCreate(48,24)
	bload(BasePath+"invinConnR.bmp",InvincibleConnR)
	InvincibleConnT = ImageCreate(48,24)
	bload(BasePath+"invinConnT.bmp",InvincibleConnT)
	InvincibleConnB = ImageCreate(48,24)
	bload(BasePath+"invinConnB.bmp",InvincibleConnB)
	
	'Square bricks
	SoftBrickPicMini = ImageCreate(24,24)
	bload(BasePath+"softSm.bmp",SoftBrickPicMini)
	MultihitMini = ImageCreate(24,24)
	bload(BasePath+"multiSm.bmp",MultihitMini)
	InvincibleMini = ImageCreate(24,24)
	bload(BasePath+"invincibleSm.bmp",InvincibleMini)
	
	'Square brick connectors
	SoftBrickConnMiniL = ImageCreate(24,24)
	bload(BasePath+"softSmConnL.bmp",SoftBrickConnMiniL)
	SoftBrickConnMiniR = ImageCreate(24,24)
	bload(BasePath+"softSmConnR.bmp",SoftBrickConnMiniR)
	SoftBrickConnMiniT = ImageCreate(24,24)
	bload(BasePath+"softSmConnT.bmp",SoftBrickConnMiniT)
	SoftBrickConnMiniB = ImageCreate(24,24)
	bload(BasePath+"softSmConnB.bmp",SoftBrickConnMiniB)

	MultihitConnMiniL = ImageCreate(24,24)
	bload(BasePath+"multiSmConnL.bmp",MultihitConnMiniL)
	MultihitConnMiniR = ImageCreate(24,24)
	bload(BasePath+"multiSmConnR.bmp",MultihitConnMiniR)
	MultihitConnMiniT = ImageCreate(24,24)
	bload(BasePath+"multiSmConnT.bmp",MultihitConnMiniT)
	MultihitConnMiniB = ImageCreate(24,24)
	bload(BasePath+"multiSmConnB.bmp",MultihitConnMiniB)

	InvincibleConnMiniL = ImageCreate(24,24)
	bload(BasePath+"invinSmConnL.bmp",InvincibleConnMiniL)
	InvincibleConnMiniR = ImageCreate(24,24)
	bload(BasePath+"invinSmConnR.bmp",InvincibleConnMiniR)
	InvincibleConnMiniT = ImageCreate(24,24)
	bload(BasePath+"invinSmConnT.bmp",InvincibleConnMiniT)
	InvincibleConnMiniB = ImageCreate(24,24)
	bload(BasePath+"invinSmConnB.bmp",InvincibleConnMiniB)

	'Special exploding picture
	BaseExplode = ImageCreate(176,24)
	ExplodePic = ImageCreate(48,24)
	bload(BasePath+"explode.bmp",BaseExplode)
end sub

sub clean_up destructor
	if Command(1) <> "/c" then
		ImageDestroy(SoftBrickPic)
		ImageDestroy(SoftBrickConnL)
		ImageDestroy(SoftBrickConnR)
		ImageDestroy(SoftBrickConnT)
		ImageDestroy(SoftBrickConnB)
		ImageDestroy(MultihitPic)
		ImageDestroy(MultihitConnL)
		ImageDestroy(MultihitConnR)
		ImageDestroy(MultihitConnT)
		ImageDestroy(MultihitConnB)
		ImageDestroy(InvinciblePic)
		ImageDestroy(InvincibleConnL)
		ImageDestroy(InvincibleConnR)
		ImageDestroy(InvincibleConnT)
		ImageDestroy(InvincibleConnB)

		ImageDestroy(BaseExplode)
		ImageDestroy(ExplodePic)
		
		ImageDestroy(SoftBrickPicMini)
		ImageDestroy(SoftBrickConnMiniL)
		ImageDestroy(SoftBrickConnMiniR)
		ImageDestroy(SoftBrickConnMiniT)
		ImageDestroy(SoftBrickConnMiniB)
		ImageDestroy(MultihitMini)
		ImageDestroy(MultihitConnMiniL)
		ImageDestroy(MultihitConnMiniR)
		ImageDestroy(MultihitConnMiniT)
		ImageDestroy(MultihitConnMiniB)
		ImageDestroy(InvincibleMini)
		ImageDestroy(InvincibleConnMiniL)
		ImageDestroy(InvincibleConnMiniR)
		ImageDestroy(InvincibleConnMiniT)
		ImageDestroy(InvincibleConnMiniB)
		
		ImageDestroy(Background)
		ImageDestroy(FramesetMerged)
		ImageDestroy(Topframe)
		ImageDestroy(Sideframes)
		ImageDestroy(BulletPic)
		ImageDestroy(MissilePic)
		for CapID as ubyte = 1 to MaxFallCaps
			if CapID <= 5 then
				ImageDestroy(CapsuleBar(CapID))
				ImageDestroy(PokerBar(CapID))
			end if
			ImageDestroy(CapsulePic(CapID))
		next CapID
		ImageDestroy(CapsuleBarFrame)
		ImageDestroy(DiffStick)
		ImageDestroy(DiffSelector)
		ImageDestroy(PaddlePic)
		ImageDestroy(PaddleBar)
		ImageDestroy(TitleBanner)
	end if
end sub

function actionButton(HoldCheck as byte = 0) as integer
	if HoldAction = 0 OR HoldCheck > 0 then
		select case ControlStyle
			case CTRL_AI
				return -1
			case CTRL_DESKTOP
				return ButtonCombo
			case CTRL_LAPTOP, CTRL_KEYBOARD
				return multikey(SC_SPACE)
			case CTRL_TABLET
				return multikey(SC_SPACE) OR (ButtonCombo AND (TapWindow > 0))
			case else
				if JoyAnalog = 0 then
					'Selected button if digital controller
					return JoyButtonCombo AND (1 SHL JoyKeySetting)
				else
					'Any button if analog controller
					return JoyButtonCombo > 0
				end if
		end select
	end if
	
	return (ControlStyle = CTRL_AI)
end function

