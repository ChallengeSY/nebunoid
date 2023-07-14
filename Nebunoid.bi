#include "ABCgfx.bi"
#include "fbgfx.bi"
using FB
#include "vbcompat.bi"
declare function convert_clip(ID as ubyte, Gfxstyle as ubyte) as byte
dim shared as string QuickPlayFile
declare sub campaign_gameplay
const PlaytestName = "Quick Playtest Level"

'Speed range specs
const DefaultSpeed = 8
const MinSpeed = 6
randomize timer

dim shared as string Masterdir
dim as byte ScreenCreated = 0
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

#include "WordWrap.bi"
#IFDEF __FB_WIN32__
#include "windows.bi"
#ENDIF

'#DEFINE __GAME_DEBUG__
declare sub shop
declare sub generate_campaign_capsule(InX as byte, InY as byte, Explode as ubyte = 0)
'Keyboard commands
const EscapeKey = chr(27)
const FunctionFour = chr(255,62)
const FunctionSeven = chr(255,65)
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
const FunctionTwelve = chr(255,134)

const FPS = 60
const SavedHighSlots = 10
const TotalHighSlots = SavedHighSlots + 4
const MaxBullets = 40
const BaseFlash = 128
const LevelClearDelay = 640
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
	STYLE_SHORT'
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
	CAP_FLASH
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
	CTRL_DESKTOP = 0
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
	CalcedInvulnerable as ubyte
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
	HotseatStamp as double

	'Campaign exclusive specs
	WarpTimer as short
	BossHealth as short
	BossMaxHealth as short
	BossLastHealth as short
	BossLastHit as short
	LevelTimer as integer
	InitialLevel as short
	LevelNum as short
	PokerHand(5) as byte
end type
type HighSlot
	Namee as string
	RawScore as uinteger
	LevelStart as integer
	LevelFinal as integer
	Difficulty as double
	NewEntry as byte
end type

const InvinZapped = 36
dim shared as PlayerSpecs PlayerSlot(4), NewPlrSlot
dim shared as PalleteSpecs Pallete(InvinZapped)
dim shared as FB.event e
const MISC = 5
const ExplodeAniRate = 1
const NumBalls = 128
const MaxFallCaps = 12
const Particount = 1250
const BackCount = 99

dim shared as string NullString
dim shared as TileSpecs Tileset(41,24)
dim shared as ushort MinSize, StandardSize, MaxSize, CapsFalling, BulletsInPlay, _
	Credits, CoinsPerCredit, CeleYear, BrickCount, XplodeCount, ZappableCount, Combo
dim shared as short PaddleSize, CampaignBarrier, BulletStart, BacksLoaded, BoxGlow, MenuCapsules
dim shared as HighSlot HighScore(TotalHighSlots)
dim shared as uinteger MouseX, MouseY, MouseColor, ButtonCombo, TotalXP
dim shared as uinteger GameStyle, TourneyStyle, TourneyScore, ShotIndex
dim shared as ubyte Fullscreen, JoyAnalog, JoyInvertAxes, ControlStyle, TapWindow, CondensedLevel
dim shared as integer LastActive, Result, OrigX(1), DesireX, JoyButtonCombo, ExplodingValue
dim shared as single JoyAxis(7)
dim shared as short TotalBC, FrameSkip, PaddleCycle, ExplodeCycle, KeyboardSpeed, JoyKeySetting, ProgressiveBounces, BlockBrushes
dim shared as double ProgressiveQuota, InstructExpire, MisnExpire, TimeRem, Reminder = -1, _
	FrameTime, PaddlePercent
dim shared as string InType, ScoreFile, Instructions, CampaignFolder, BackList(BackCount)
dim shared as BackSpecs BackSlot(BackCount)
dim shared as Basics Paddle(2), Capsule(MaxFallCaps), Ball(NumBalls), Bullet(MaxBullets), LaserBeams(20,15)
dim shared as ParticleSpecs Particles(Particount)
dim shared as ubyte DQ, Player, NumPlayers, DispLives, Invis, GfxStyle, ExploTick, _
	BallSize, AllowHandicap, DisableHints, ShuffleLevels, MenuMode, HoldClick, HoldAction
dim shared as byte EnhancedGFX, GamePaused, TourneyValid, TotalMessages, TotalUnread
dim shared as any ptr BulletPic, MissilePic, SoftBrickPic, MultihitPic, InvinciblePic, ExplodePic, BaseExplode, SoftBrickPicMini, MultihitPicMini, InvincibleMini, _
	CapsulePic(26), CapsuleBar(5), CapsuleBarFrame, PokerBar(5), Background, FramesetMerged, Sideframes, Topframe, DiffStick, DiffSelector, PaddlePic, BasePaddle, PaddleBar

const Interpolation = 120 'Ball updates per frame
const PerPage = 20
const PaddleHeight = 18
const CustomizePadding = 150
const CustomizeSelect = CustomizePadding - 5
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
	for PID as ubyte = 1 to 4
		with PlayerSlot(PID)
			LivesFound += .Lives
		end with
	next PID
	
	return LivesFound
end function

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
sub generate_particles(NewCount as ushort, XL as byte, YL as byte, _
	ApplyColor as uinteger)
	dim as ushort NewParticle, FreeParticles

	for PID as ushort = 1 to Particount
		with Particles(PID)
			if .Y >= 768 OR .Blending <= 0 then
				FreeParticles += 1
			end if
		end with
	next PID

	for PID as ushort = 1 to NewCount
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
	if BrickX = 1 OR Tileset(int(BrickX-1),BrickY).BrickID > 0 then
		StartX -= 48/(CondensedLevel + 1)
		BWidth += 48/(CondensedLevel + 1)
	end if
	if BrickX >= 20 * (CondensedLevel + 1) OR Tileset(int(BrickX+1),BrickY).BrickID > 0 then
		BWidth += 48/(CondensedLevel + 1)
	end if

	if BrickY > 1 AND Tileset(BrickX,int(BrickY-1)).BrickID > 0 then
		StartY -= 24
		BHeight += 24
	end if
	if BrickY < 20 AND Tileset(BrickX,int(BrickY+1)).BrickID > 0 then
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
	for Plr as byte = 1 to 4
		print #10, "difficulty,"& PlayerSlot(Plr).Difficulty
	next Plr
	print #10, "handicap,";AllowHandicap
	print #10, "nohints,";DisableHints
	print #10, "campaign,";CampaignFolder
	print #10, "enhanced,"& EnhancedGFX
	print #10, "controls,";ControlStyle
	print #10, "campbarr,";CampaignBarrier
	print #10, "shuffle,";ShuffleLevels
	close #10
	open "xp.dat" for output as #10
	print #10, TotalXP
	close #10
end sub

function ball_ct_bonus as byte
	'More balls = more points per block; subject to Diminishing Returns
	return int(sqr(TotalBC) + 0.5)
end function

sub respawn_blocks(BrushID as short)
	dim as ushort BlocksRespawned = 0
	
	'Respawns all blocks that were origianlly bound to the selected brush
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 20*(CondensedLevel+1)
			with Tileset(XID,YID)
				if .BrickID = 0 AND .BaseBrickID = BrushID then
					BlocksRespawned += 1
					.BrickID = .BaseBrickID
					.Flash = BaseFlash
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
		end with
		
		play_clip(SFX_BRICKS_RESPAWN)
	end if
end sub

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
		for BID as ubyte = 0 to 1
			draw_border(ExplodePic,BID,BID,23-BID,23-BID,255-BID*127)
		next BID
	else
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
			with Tileset(XID,YID)
				if YID <= MaxY then
					if .BrickID < -1 then
						'Exploding in progress
						if CondensedLevel then
							put(32+(XID-1)*24,96+(YID-1)*24),ExplodePic,trans
							line(32+(XID-1)*24,96+(YID-1)*24)-_
								(31+(XID)*24,95+(YID)*24),rgba(255,128,0,128),bf
						else
							put(32+(XID-1)*48,96+(YID-1)*24),ExplodePic,trans
							line(32+(XID-1)*48,96+(YID-1)*24)-_
								(31+(XID)*48,95+(YID)*24),rgba(255,128,0,128),bf
						end if
						if GamePaused = 0 then
							.BrickID += 1
						end if
						Count += 1
						Invis = 12
					elseif .BrickID = -1 then
						'Finish exploding
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
						
						for YDID as byte = YID - 1 to YID + 1
							for XDID as byte = XID - 1 to XID + 1
								if XDID > 0 AND XDID <= 20*(CondensedLevel+1) AND YDID > 0 AND YDID <= 20 then
									RefPallete = Tileset(XDID,YDID).BrickID
									
									if RefPallete > 0 OR (XDID = XID AND YDID = YID) then
										if (RefPallete > 0 AND Pallete(RefPallete).HitDegrade >= 0) OR _
											(XDID = XID AND YDID = YID) then
											
											if TotalBC > 0 then
												ScoreBonus = ball_ct_bonus * ExplodingValue
											elseif total_lives > 0 then
												ScoreBonus = ExplodingValue
											end if
											
											PlayerSlot(Player).Score += ScoreBonus
											Tileset(XDID,YDID).BrickID = 0
											Tileset(XDID,YDID).Flash = BaseFlash
											Invis = 12
											generate_campaign_capsule(XDID,YDID,1)
											generate_particles(ScoreBonus,XDID,YDID,rgb(255,192,160))
											
										else
											Tileset(XDID,YDID).BrickID = ExplodeDelay
											
											if (XDID > XID AND YID = YDID) OR YDID > YID then
												Tileset(XDID,YDID).BrickID -= 1 
												Tileset(XDID,YDID).HitTime = 0 
												Tileset(XDID,YDID).LastBall = 0 
											end if
											
											Tileset(XDID,YDID).Flash = BaseFlash
											generate_campaign_capsule(XDID,YDID,1)
											Invis = 12
										end if
										
									end if
								end if
							next XDID
						next YDID
	
						play_clip(SFX_EXPLODE,XPanning)
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
										if Tileset(XID,YID).BrickID < 10 then
											PrintChar = str(Tileset(XID,YID).BrickID)
										else	
											PrintChar = chr(55+Tileset(XID,YID).BrickID)
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
									if Tileset(XID,YID).BrickID < > .HitDegrade AND .CalcedInvulnerable < 2 then
										Count += 1
									end if
								elseif (Invis > 0 OR (GameStyle AND (1 SHL STYLE_INVIS)) = 0 OR total_lives = 0) then
									if CondensedLevel then
										if Tileset(XID,YID).BrickID = .HitDegrade OR .CalcedInvulnerable >= 2 then
											put(32+(XID-1)*24,96+(YID-1)*24),InvincibleMini,pset
										elseif .CalcedInvulnerable > 0 then
											put(32+(XID-1)*24,96+(YID-1)*24),InvincibleMini,pset
											Count += 1
										elseif .HitDegrade < 0 then
											put(32+(XID-1)*24,96+(YID-1)*24),ExplodePic,trans
											XplodeCount += 1
											Count += 1
										elseif .HitDegrade > 0 OR .CanRegen > 0 then
											put(32+(XID-1)*24,96+(YID-1)*24),MultihitPicMini,pset
											Count += 1
										else 
											put(32+(XID-1)*24,96+(YID-1)*24),SoftBrickPicMini,pset
											Count += 1
										end if
										line(32+(XID-1)*24,96+(YID-1)*24)-_
											(31+(XID)*24,95+(YID)*24),.PColoring,bf
									else
										if Tileset(XID,YID).BrickID = .HitDegrade OR .CalcedInvulnerable >= 2 then
											put(32+(XID-1)*48,96+(YID-1)*24),InvinciblePic,pset
										elseif .CalcedInvulnerable > 0 then
											put(32+(XID-1)*48,96+(YID-1)*24),InvinciblePic,pset
											Count += 1
										elseif .HitDegrade < 0 then
											put(32+(XID-1)*48,96+(YID-1)*24),ExplodePic,trans
											XplodeCount += 1
											Count += 1
										elseif .HitDegrade > 0 OR .CanRegen > 0 then
											put(32+(XID-1)*48,96+(YID-1)*24),MultihitPic,pset
											Count += 1
										else 
											put(32+(XID-1)*48,96+(YID-1)*24),SoftBrickPic,pset
											Count += 1
										end if
										line(32+(XID-1)*48,96+(YID-1)*24)-_
											(31+(XID)*48,95+(YID)*24),.PColoring,bf
									end if
								elseif Tileset(XID,YID).BrickID < > .HitDegrade AND .CalcedInvulnerable < 2 then
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

function convert_clip(ID as ubyte, Gfxstyle as ubyte) as byte
	select case ID
		case 24,25,26,27,28,29
			return 0
		case else
			return ID
	end select
end function

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

sub clean_up destructor
	if Command(1) <> "/c" then
		ImageDestroy(SoftBrickPic)
		ImageDestroy(MultihitPic)
		ImageDestroy(InvinciblePic)
		ImageDestroy(SoftBrickPicMini)
		ImageDestroy(MultihitPicMini)
		ImageDestroy(InvincibleMini)
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
end function
