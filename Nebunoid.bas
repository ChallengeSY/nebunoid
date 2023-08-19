#IFNDEF __FB_DOS__
#DEFINE __USE_FBSOUND__
#ENDIF

#include "Nebunoid.bi"
#include "NNCampaign.bas"
windowtitle "Nebunoid 1.03"

if FileExists("portable") = 0 then
	#IF defined(__FB_WIN32__)
	if environ("APPDATA") <> "" then
		if Dir(environ("APPDATA")+"\Nebunoid",fbDirectory) = "" then
			mkdir(environ("APPDATA")+"\Nebunoid")
		end if
		chdir(environ("APPDATA")+"\Nebunoid")
	end if
	#ELSE
	if environ("HOME") <> "" then
		if Dir(environ("HOME")+"/.nebunoid",fbDirectory) = "" then
			mkdir(environ("HOME")+"/.nebunoid")
		end if
		chdir(environ("HOME")+"/.nebunoid")
	end if
	#ENDIF
end if

if ScreenCreated = 0 OR FileExists("FS.ini") then
	if FileExists("FS.ini") then
		Fullscreen = 1
		screen 20,24,2,GFX_FULLSCREEN OR GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
	else
		screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
	end if
	windowtitle "Nebunoid"
end if

'Foreground assets
SoftBrickPic = ImageCreate(48,24)
bload(MasterDir + "/gfx/soft.bmp",SoftBrickPic)
MultihitPic = ImageCreate(48,24)
bload(MasterDir + "/gfx/multi.bmp",MultihitPic)
InvinciblePic = ImageCreate(48,24)
bload(MasterDir + "/gfx/invincible.bmp",InvinciblePic)

SoftBrickPicMini = ImageCreate(24,24)
bload(MasterDir + "/gfx/softSm.bmp",SoftBrickPicMini)
MultihitPicMini = ImageCreate(24,24)
bload(MasterDir + "/gfx/multiSm.bmp",MultihitPicMini)
InvincibleMini = ImageCreate(24,24)
bload(MasterDir + "/gfx/invincibleSm.bmp",InvincibleMini)

for CapID as ubyte = 1 to 5
	CapsuleBar(CapID) = ImageCreate(38,19)
	PokerBar(CapID) = ImageCreate(38,19)
next CapID
bload(MasterDir + "/gfx/caps/blizzard.bmp",CapsuleBar(1))
bload(MasterDir + "/gfx/caps/grab.bmp",CapsuleBar(2))
bload(MasterDir + "/gfx/caps/repairs.bmp",CapsuleBar(3))
bload(MasterDir + "/gfx/caps/reverse.bmp",CapsuleBar(4))
bload(MasterDir + "/gfx/caps/slowpad.bmp",CapsuleBar(5))

CapsuleBarFrame = ImageCreate(63,15)
line CapsuleBarFrame,(0,0)-(62,14),rgb(0,0,0),bf
line CapsuleBarFrame,(0,0)-(62,14),rgb(255,255,255),b
line CapsuleBarFrame,(0,0)-(62,0),rgb(128,128,128)
line CapsuleBarFrame,(0,0)-(0,14),rgb(128,128,128)

BaseExplode = ImageCreate(176,24)
ExplodePic = ImageCreate(48,24)
bload(MasterDir + "/gfx/explode.bmp",BaseExplode)
BulletPic = ImageCreate(5,10)
bload(MasterDir + "/gfx/bullet.bmp",BulletPic)
MissilePic = ImageCreate(10,20)
bload(MasterDir + "/gfx/missile.bmp",MissilePic)
DiffStick = ImageCreate(600,64)
bload(MasterDir + "/gfx/diffstick.bmp",DiffStick)
DiffSelector = ImageCreate(30,64)
bload(MasterDir + "/gfx/selector.bmp",DiffSelector)

FramesetMerged = ImageCreate(1024,768)
bload(MasterDir + "/gfx/framesMerged.bmp",FramesetMerged)

Sideframes = ImageCreate(1024,768)
put Sideframes, (0,0), FramesetMerged, pset
line Sideframes,(32,0)-(991,95),rgb(255,0,255),bf
line Sideframes,(31,1)-(31,95),rgb(128,128,128)
line Sideframes,(992,1)-(992,95),rgb(255,255,255)

Topframe = ImageCreate(960,96)
put Topframe, (-32,0), FramesetMerged, pset
line Topframe,(0,1)-(0,95),rgb(255,255,255)
line Topframe,(959,1)-(959,95),rgb(128,128,128)

for CapID as ubyte = 1 to 26
	CapsulePic(CapID) = ImageCreate(38,19)
next CapID
PaddlePic = ImageCreate(1080,PaddleHeight)
BasePaddle = ImageCreate(1080,PaddleHeight)
bload(MasterDir + "/gfx/paddle.bmp",BasePaddle)

PaddleBar = ImageCreate(640,31)
#IFDEF __USE_FBSOUND__
put PaddleBar, (0,0), LoadingBar, pset
line PaddleBar,(5,5)-(634,25),rgb(0,0,0),bf
ImageDestroy(LoadingBar)
#ELSE
line PaddleBar,(0,0)-(639,30),rgb(0,0,0),bf
line PaddleBar,(0,0)-(639,0),rgb(255,255,255)
line PaddleBar,(0,0)-(0,30),rgb(255,255,255)

for Thickness as byte = 1 to 3
	line PaddleBar,(Thickness,Thickness)-(639-Thickness,30-Thickness),rgb(128,128,255),b
next Thickness
line PaddleBar,(5,26)-(635,26),rgb(255,255,255)
line PaddleBar,(635,5)-(635,26),rgb(255,255,255)
#ENDIF

'Background pooling
BGBrightness = 50
Background = ImageCreate(1024,768)
line Background,(0,0)-(1023,767),rgb(0,0,0),bf
NullString = dir(MasterDir + "/gfx/back/*.bmp",fbNormal)
while NullString <> ""
	BackList(BacksLoaded) = NullString
	BacksLoaded += 1
	if BacksLoaded > BackCount then exit while
	NullString = dir()
wend
shuffle_backs

if FileExists("conf.ini") then
	dim as byte PlayersFound = 0
	open "conf.ini" for input as #10
	do
		input #10, NullString
		select case NullString
			case "difficulty"
				PlayersFound += 1
				if PlayersFound <= 4 then
					with PlayerSlot(PlayersFound)
						input #10, .Difficulty
						.Difficulty = max(.Difficulty,1.0)
					end with
				else
					input #10, NullString
				end if
			case "handicap"
				input #10, AllowHandicap
			case "nohints"
				input #10, DisableHints
			case "campaign"
				line input #10, CampaignFolder
			case "enhanced"
				input #10, EnhancedGFX
			case "controls"
				input #10, ControlStyle
			case "campbarr"
				input #10, CampaignBarrier
			case "shuffle"
				input #10, ShuffleLevels
			case "bgbright"
				input #10, BGBrightness
				BGBrightness = max(min(BGBrightness,100),0)
		end select
	loop until eof(10)
	close #10
end if
if FileExists("xp.dat") then
	open "xp.dat" for input as #10
	input #10, TotalXP
	close #10
end if
if CampaignFolder = "" then CampaignFolder = "official/intro"
if PlayerSlot(1).Difficulty = 0 then PlayerSlot(1).Difficulty = 4.0
while inkey <> "":wend
while screenevent(@e):wend
screenset 1,0
setmouse(,,0,0)
if Command(1) = "-l" then 
	QuickPlayFile = Command(2)
	campaign_gameplay
	end 0
end if
dim as string TitleCapNames(1 to 26) => {"Slower Balls", "Split Balls", "Grabbing Paddle", "Spread Exploding", "Detonate Exploding", "Zap Blocks", _
	"Bullet Paddle", "Blizzard", "Fire Balls", "Breakthru Balls", "Missile Paddle", "Warp Level", "Extra Life", _
	"Faster Balls", "Weakened Balls", "Maximum Speed!", "Gravity Balls", "Reverse Paddle", "Slow Paddle", "", _
	"Expand Paddle", "Reduce Paddle", "Mystery Capsule", "Disruption", "Effect Extender", "Effect Negater"}
load_title_capsules
KeyboardSpeed = 20

'Main Menu
do
	MouseColor = rgb(128,255,128)
	cls
	put (0,0),Sideframes,trans
	Result = getmouse(MouseX,MouseY,0,ButtonCombo)
	put (40,10),TitleBanner,trans
	gfxstring("Copyright (C) 2023 Paul Ruediger",0,753,3,3,2,rgb(255,255,255))
	gfxstring("Exit",40,250,5,5,3,rgb(255,255,255))

	if CampaignFolder = "" then
		gfxstring("Play the game",40,150,5,5,3,rgb(128,128,128))
	else
		gfxstring("Play the game",40,150,5,5,3,rgb(255,255,255))
	end if
	
	gfxstring("Customize",40,200,5,5,3,rgb(255,255,255))
	
	gfxstring("Powerup Capsules",40,350,5,4,3,rgb(255,255,255))
	for PID as byte = 1 to 13
		put(40,375+PID*25),CapsulePic(PID),trans
		gfxstring(TitleCapNames(PID),80,375+PID*25,4,4,3,rgb(255,255,255))
	next PID

	gfxstring("Powerdown/Neutral Capsules",520,350,5,4,3,rgb(255,255,255))
	for PID as byte = 14 to 26
		put(520,375+(PID-13)*25),CapsulePic(PID),trans
		gfxstring(TitleCapNames(PID),560,375+(PID-13)*25,4,4,3,rgb(255,255,255))
	next PID
	
	MenuCapsules += 1
	if MenuCapsules >= 300 then
		MenuCapsules *= -1
	end if
	
	if MouseX >= 32 AND MouseX < 992 then
		if MouseY >= 140 AND MouseY < 185 AND CampaignFolder <> "" then
			draw_box(32,140,991,184)
			if ButtonCombo > 0 AND HoldClick = 0 then
				campaign_gameplay
				load_title_capsules
				MenuCapsules = 0
				while inkey <> "":wend
			end if
		elseif MouseY >= 190 AND MouseY < 235 then
			draw_box(32,190,991,234)
			if ButtonCombo > 0 AND HoldClick = 0 then
				HoldClick = 1
				shop
				MenuCapsules = 0
				while inkey <> "":wend
			end if
		end if
		if MouseY >= 240 AND MouseY < 285 then
			draw_box(32,240,991,284)
			if ButtonCombo > 0 AND HoldClick = 0 then
				exit do
			end if
		end if
	end if
	if InType = FunctionSeven then
		toggle_fullscreen
	end if
	if Result = 0 then
		disp_mouse(MouseX,MouseY,MouseColor)
	end if
	if HoldClick > 0 AND ButtonCombo = 0 then
		HoldClick = 0
	end if
	screencopy
	sleep 10
	InType = inkey
loop until InType = EscapeKey OR InType = XBox
if ControlStyle >= CTRL_KEYBOARD then
	ControlStyle = CTRL_DESKTOP
end if
save_unlocks

sub shop
	dim as string HelpText(0 to MISC) => {_
		"Select Folder", _
		"Choose an official campaign", _
		"Download and play community campaigns", _
		"Choose a difficulty", _
		"Choose control style", _
		"Manage other options"}
	dim as ubyte TotalCount(0 to MISC) => {0, 9, 0, 0, 12, 6}
	dim as ubyte CTRL_BUTTON_ACTION, CTRL_AXIS_MOVEMENT

	dim as string ItemDesc, CommunityFolder, CustomItem(MISC,42)
	dim as ubyte AFilter, PageNum, LongLen
	dim as ushort PosY, SelY
	dim as integer MinXP(42), JoyError(4), JoyButtons
	
	for JoyID as byte = 1 to 4
		JoyError(JoyID) = getJoystick(JoyID-1)
	next JoyID
	
	CommunityFolder = Dir(MasterDir+"/campaigns/community/*",fbDirectory)
	while len( CommunityFolder ) > 0 AND TotalCount(2) < 42
		if CommunityFolder <> "." AND CommunityFolder <> ".." then
			TotalCount(2) += 1
			CustomItem(2,TotalCount(2)) = CommunityFolder
		end if
		CommunityFolder = Dir()
	wend
	
	CustomItem(1,1) = "Introductory Training"
	CustomItem(1,2) = "Regular Season       "
	CustomItem(1,3) = "Geometric Designs    "
	MinXP(3) = 7.5e4
	CustomItem(1,4) = "Fortified Letters    "
	MinXP(4) = 2e5
	CustomItem(1,5) = "Patriarch Memorial   "
	MinXP(5) = 4.25e5
	CustomItem(1,6) = "Challenge Campaign   "
	MinXP(6) = 7.5e5
	CustomItem(1,7) = "Maximum Insantiy     "
	MinXP(7) = 2.5e6
	CustomItem(1,8) = "Celestial Journey    "
	MinXP(8) = 7.5e6
	CustomItem(1,9) = "Nebunoid Boss Rush   "
	MinXP(9) = 2e7

	'Hide secret campaign if not even close to unlocking
	if TotalXP < MinXP(9) * 0.75 then
		TotalCount(1) -= 1
	elseif TotalXP < MinXP(9) * 0.9 then
		CustomItem(1,9) = "???????? ???? ????   "
	end if

	dim as string Filter(0 to MISC) => {_
		"Select Folder", _
		"Official Campaigns ("+str(TotalCount(1))+")", _
		"Community Campaigns ("+str(TotalCount(2))+")", _
		"Difficulty", _
		"Controls", _
		"Miscellaneous"}
	dim as string ShortCampaignNames(1 to 42) => {"intro", "regular", "geometry", "alphabet", "memorial", "challenge", "extreme", "universe", "bossrush"}
	dim as string CampaignTxt(1 to 42) => {_
		"Introductory Training serves as a shorter, easier campaign for new players.",_
		"The Regular Season is a balanced campaign, and is recommended for all skill levels.",_
		"The Geometric Designs is another short campaign, of modest difficulty.",_
		"The Fortified Letters has levels that are, well, shaped into letters.", _
		"Designed in memory of a father, Patriarch Memorial is a moderate artistic set.", _
		"The Challenge Campaign makes heavy use of invincible and otherwise very strong blocks!", _
		"Do you have what it takes to overcome Maximum Insanity?", _
		"Celestial Journey is a massive campaign mostly depicting deep space elements!", _
		"Mastered the bosses of Nebunoid? Defeat them all again, without continuing!"}
	CustomItem(4,1) = "Desktop controls "
	CustomItem(4,2) = "Laptop controls  "
	CustomItem(4,3) = "Tablet controls  "
	CustomItem(4,4) = "Keyboard controls"
	CustomItem(4,5) = "USB controller 1 "
	CustomItem(4,6) = "USB controller 2 "
	CustomItem(4,7) = "USB controller 3 "
	CustomItem(4,8) = "USB controller 4 "
	CustomItem(4,10) = "Controller type"
	CustomItem(4,11) = "Invert axes    "
	CustomItem(MISC,1) = "Disable game hints     "
	CustomItem(MISC,2) = "Enhanced particle GFX  "
	CustomItem(MISC,3) = "Campaign barrier system"
	CustomItem(MISC,4) = "Shuffle levels         "
	CustomItem(MISC,5) = "Full screen setting    "
	CustomItem(MISC,6) = "Background brightness  "
	for PID as ubyte = 1 to 42
		if ShortCampaignNames(PID) <> "" then
			ShortCampaignNames(PID) = "official/"+ShortCampaignNames(PID)
		end if
		
		if len(CustomItem(2,PID)) > LongLen then
			LongLen = len(CustomItem(2,PID))
		end if
	next PID

	for PID as ubyte = 1 to TotalCount(2)
		while len(CustomItem(2,PID)) < LongLen
			CustomItem(2,PID) += space(1)
		wend
	next PID
	

	do
		MouseColor = rgb(0,255,128)
		cls
		Result = getmouse(MouseX,MouseY,0,ButtonCombo)
		gfxstring("Customize",5,5,7,7,3,rgb(255,128,0))
		gfxstring(commaSep(TotalXP)+" XP",517,5,7,7,3,rgb(0,128,255))

		for FID as ubyte = 0 to MISC
			if FID = 0 then
				gfxstring(Filter(FID),5,50+(FID*30),4,4,3,rgb(128,0,255))
			elseif AFilter = FID then
				if FID <= 3 then
					gfxstring(Filter(FID),5,50+(FID*30),4,4,3,rgb(128,0,128))
				else
					gfxstring(Filter(FID),517,50+((FID-3)*30),4,4,3,rgb(128,0,128))
				end if
			else
				if FID <= 3 then
					if TotalCount(2) > 0 OR FID <> 2 then 
						gfxstring(Filter(FID),5,50+(FID*30),4,4,3,rgb(255,0,255))
						if MouseY >= 45+(FID*30) AND MouseY < 75+(FID*30) AND MouseX < 512 then
							draw_box(0,45+(FID*30),511,74+(FID*30))
							if ButtonCombo > 0 AND HoldClick = 0 then
								AFilter = FID
								PageNum = 1
								Filter(0) = HelpText(FID)
							end if
						end if
					else
						gfxstring(Filter(FID),5,50+(FID*30),4,4,3,rgb(128,128,128))
					end if
				else
					gfxstring(Filter(FID),517,50+((FID-3)*30),4,4,3,rgb(255,0,255))
					if MouseY >= 45+((FID-3)*30) AND MouseY < 75+((FID-3)*30) AND MouseX >= 512 then
						draw_box(512,45+((FID-3)*30),1023,74+((FID-3)*30))
						if ButtonCombo > 0 AND HoldClick = 0 then
							AFilter = FID
							PageNum = 1
							Filter(0) = HelpText(FID)
						end if
					end if
				end if
			end if
		next FID

		if AFilter = 1 then
			ItemDesc = "Mouse over a campaign to see its description."
			for PID as ubyte = (PageNum-1)*PerPage+1 to (PageNum)*PerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(PerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(PerPage*30))
				if PID > TotalCount(AFilter) then
					exit for
				end if
				if CampaignFolder = ShortCampaignNames(PID) then
					gfxstring(CustomItem(1,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
					if MouseY >= CustomizeSelect+(PID*30) AND MouseY < SelY+25 then
						ItemDesc = CampaignTxt(PID)
					end if
				elseif TotalXP < MinXP(PID) then
					gfxstring(CustomItem(1,PID)+" ("+commaSep(MinXP(PID))+" XP)",5,PosY,4,4,3,rgb(128,128,128))
					if MouseY >= CustomizeSelect+(PID*30) AND MouseY < SelY+30 then
						ItemDesc = "You must reach the required experience total to unlock this campaign."
					end if
				else
					if MinXP(PID) = 0 then
						gfxstring(CustomItem(1,PID)+" (free)",5,PosY,4,4,3,rgb(255,255,255))
					else
						gfxstring(CustomItem(1,PID)+" (unlocked)",5,PosY,4,4,3,rgb(255,255,255))
					end if
					if MouseY >= CustomizeSelect+(PID*30) AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 AND HoldClick = 0 then
							CampaignFolder = ShortCampaignNames(PID)
						end if
						ItemDesc = CampaignTxt(PID)
					end if
				end if
			next PID
			
		elseif AFilter = 2 then
			for PID as ubyte = (PageNum-1)*PerPage+1 to (PageNum)*PerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(PerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(PerPage*30))
				if PID > TotalCount(AFilter) then
					exit for
				end if
				if CampaignFolder = "community/"+trim(CustomItem(2,PID)) then
					gfxstring(CustomItem(2,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
				else
					gfxstring(CustomItem(2,PID)+" (available)",5,PosY,4,4,3,rgb(255,255,255))
					if MouseY >= CustomizeSelect+(PID*30) AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 AND HoldClick = 0 then
							CampaignFolder = "community/"+trim(CustomItem(2,PID))
						end if
					end if
				end if
			next PID
			
		elseif AFilter = 3 then
			dim as short InX, CalcX, WarpSystem
			dim as double ApproxDiff, DiffUnlocked
			dim as string DiffTxt, ContinueSpecs, ExtraInfo
			
			dim as integer DiffXPUnlock(6) => {25000,350000,750000,1250000,2000000,3000000,5000000}
			dim as integer NextXPUnlock
			
			DiffUnlocked = 12
			for UID as byte = 0 to 6
				if TotalXP < DiffXPUnlock(UID) then
					DiffUnlocked = UID + 5
					NextXPUnlock = DiffXPUnlock(UID)
					exit for
				end if
			next UID
			
			CalcX = 182+PlayerSlot(PageNum).Difficulty*50

			put(222,300),DiffStick,trans
			if DiffUnlocked < 12 then
				line(194+(DiffUnlocked+0.5)*50,300)-(821,374),rgba(0,0,0,192),bf
			end if
			put(CalcX,300),DiffSelector,trans
			ApproxDiff = int(PlayerSlot(PageNum).Difficulty * 10 + 0.51) / 10
			
			if MouseX >= 222 AND MouseX < 822 AND MouseY >= 322 AND MouseY < 342 AND ButtonCombo > 0 then
				InX = MouseX - 247
				with PlayerSlot(PageNum)
					.Difficulty = 1 + InX/50
					
					if .Difficulty > min(DiffUnlocked + 0.4,12) then
						.Difficulty = min(DiffUnlocked + 0.4,12)
					end if
					if .Difficulty < 1 then
						.Difficulty = 1
					end if
				end with
			elseif ButtonCombo = 0 then
				PlayerSlot(PageNum).Difficulty = ApproxDiff
			end if
			
			ContinueSpecs = "None"
			WarpSystem = 1
			ExtraInfo = "None"
			select case int(ApproxDiff+0.5)
				case DIFF_KIDS
					DiffTxt = "Effortless"
					ExtraInfo = "Metal / No red caps / Restock / Slow speed / Bullet ammo"
				case DIFF_VEASY
					DiffTxt = "Very Easy"
					ExtraInfo = "Metal balls / Limit red caps / Life Restock / Slower speed"
				case DIFF_EASY
					DiffTxt = "Easy"
					ExtraInfo = "Life Restock / Slower speed"
				case DIFF_MEASY
					DiffTxt = "Medium Easy"
				case DIFF_MEDIUM
					DiffTxt = "Medium"
				case DIFF_MHARD
					DiffTxt = "Medium Hard"
				case DIFF_HARD
					DiffTxt = "Hard"
					ContinueSpecs = "Difficulty -0.5 per continue"
					WarpSystem = 0
				case DIFF_VHARD
					DiffTxt = "Very Hard"
					ContinueSpecs = "Difficulty -0.5 per continue"
					WarpSystem = 0
				case DIFF_EXTREME
					DiffTxt = "Extreme"
					ContinueSpecs = "Difficulty -1.0 per continue"
					WarpSystem = 0
				case else
					'' Special exception: Nightmare is not available until difficulty 11.0 or higher
					if ApproxDiff < 11 then
						DiffTxt = "Insane"
						ContinueSpecs = "Difficulty -1.0 per continue"
						WarpSystem = 0
					else
						DiffTxt = "Nightmare"
						ExtraInfo = "No red capsules"
						ContinueSpecs = "Difficulty drop to 10.0"
						WarpSystem = 0
					end if
			end select
			
			
			dim as double ComputeDiff = ApproxDiff + 1e-6
			
			if AllowHandicap then
				gfxstring("Difficulty for player "+str(PageNum)+": "+DiffTxt+" ("+left(str(ComputeDiff),len(str(int(ComputeDiff)))+2)+")",5,180,4,4,3,rgb(128,192,255))
			else
				gfxstring("Difficulty for everyone: "+DiffTxt+" ("+left(str(ComputeDiff),len(str(int(ComputeDiff)))+2)+")",5,180,4,4,3,rgb(128,192,255))
			end if
			if DiffUnlocked < 12 then
				gfxstring("Next difficulty unlock : "+commaSep(NextXPUnlock)+" XP",5,210,4,4,3,rgb(255,128,128))
			else
				gfxstring("All difficulties unlocked",5,210,4,4,3,rgb(128,128,128))
			end if
			
			gfxstring("Speed increase  : Every "+left(str(100/ApproxDiff),4)+" bounces/blocks",5,550,4,4,3,rgb(128,128,255))
			gfxstring("Continue penalty: "+ContinueSpecs,5,580,4,4,3,rgb(128,128,255))
			if WarpSystem then
				gfxstring("Warp system: Enabled",5,610,4,4,3,rgb(128,128,255))
			else
				gfxstring("Warp system: Disabled",5,610,4,4,3,rgb(128,128,255))
			end if
			gfxstring("Perks: "+ExtraInfo,5,640,4,4,3,rgb(128,128,255))

			if AllowHandicap then
				gfxstring("Handicap system: ON",5,700,4,4,3,rgb(255,0,255))
				if MouseY >= 695 AND MouseY < 724 AND MouseX < 512 then
					draw_box(0,695,511,724)
					if ButtonCombo > 0 AND HoldClick = 0 then
						HoldClick = 1
						PageNum = 1
						AllowHandicap = 0
					end if
				end if
				
				gfxstring("Next player",517,700,4,4,3,rgb(255,0,255))
				if MouseY >= 695 AND MouseY < 724 AND MouseX >= 512 then
					draw_box(512,695,1023,724)
					if ButtonCombo > 0 AND HoldClick = 0 then
						HoldClick = 1
						Pagenum += 1
						if PageNum > 4 then
							PageNum = 1
						end if
					end if
				end if
			else
				gfxstring("Handicap system: OFF",5,700,4,4,3,rgb(255,0,255))
				if MouseY >= 695 AND MouseY < 724 AND MouseX < 512 then
					draw_box(0,695,511,724)
					if ButtonCombo > 0 AND HoldClick = 0 then
						HoldClick = 1
						AllowHandicap = 1
					end if
				end if
				
				gfxstring("Next player",517,700,4,4,3,rgb(128,0,128))
				for Plr as byte = 2 to 4
					PlayerSlot(Plr).Difficulty = PlayerSlot(1).Difficulty
				next
			end if
			
		elseif AFilter = 4 then
			ItemDesc = "Mouse over a control style to see its description."
			
			if ControlStyle <= CTRL_TABLET then
				CustomItem(4,12) = "No settings    "
			elseif ControlStyle = CTRL_KEYBOARD then
				CustomItem(4,12) = "Movement speed "
			elseif JoyAnalog = 0 then
				CustomItem(4,12) = "Action button  "
			else
				CustomItem(4,12) = "Paddle axis    "
			end if

			for PID as ubyte = (PageNum-1)*PerPage+1 to (PageNum)*PerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(PerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(PerPage*30))
				if PID > TotalCount(AFilter) then
					exit for
				end if
				
				if MouseY >= SelY AND MouseY < SelY+30 AND CustomItem(4,PID) <> "" then
					select case PID-1
						case CTRL_DESKTOP
							ItemDesc = "Default: Move mouse to control paddle and click to perform actions (Release Ball / Shoot)"
						case CTRL_LAPTOP
							ItemDesc = "Move mouse to control paddle and spacebar to perform actions"
						case CTRL_TABLET
							ItemDesc = "Swipe to control the paddle. Spacebar or double tap to perform actions"
						case CTRL_KEYBOARD
							ItemDesc = "Arrow keys to move (with SHIFT/CTRL for finer movement) and spacebar for actions"
						case 9
							ItemDesc = "Choose between a digital controller (rigid axes only) and an analong controller (one or more flexible axes)"
					end select
				end if
				
				if PID = ControlStyle + 1 then
					gfxstring(CustomItem(4,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
					if PID - 1 > CTRL_KEYBOARD AND MouseY >= SelY AND MouseY < SelY+30 then
						ItemDesc = "Customize below. For safety reasons, this setting is not remembered across sessions"
					end if
				elseif PID <= 4 then
					gfxstring(CustomItem(4,PID)+" (available)",5,PosY,4,4,3,rgb(255,255,255))
					if MouseY >= SelY AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 then
							ControlStyle = PID - 1
						end if
					end if
				elseif PID <= 8 then
					dim as byte RefJoy = PID-4
					
					if JoyError(RefJoy) then
						gfxstring(CustomItem(4,PID)+" (disabled)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "No controller detected at this port"
						end if
					else
						gfxstring(CustomItem(4,PID)+" (available)",5,PosY,4,4,3,rgb(255,255,255))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Use and customize this USB Controller to play"
							
							draw_box(0,SelY,1023,SelY+29)
							if ButtonCombo > 0 then
								JoyAnalog = 0
								JoyKeySetting = 0	
								ControlStyle = PID - 1
							end if
						end if
					end if
				elseif PID = 10 then
					if ControlStyle <= CTRL_KEYBOARD then
						gfxstring(CustomItem(4,PID)+" (overridden)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Controller Type is available only for USB Controllers"
						end if
					else
						if JoyAnalog = 0 then
							gfxstring(CustomItem(4,PID)+" (Digital Controller)",5,PosY,4,4,3,rgb(255,255,255))
						else
							gfxstring(CustomItem(4,PID)+" (Analog Controller)",5,PosY,4,4,3,rgb(255,255,255))
						end if
						if MouseY >= SelY AND MouseY < SelY+30 then
							if JoyAnalog = 0 then
								ItemDesc = "A Digital Controller has only rigid axes. Click to change"
							else
								ItemDesc = "An Analog Controller has one or more flexible axes. Click to change"
							end if
							
							draw_box(0,SelY,1023,SelY+29)
							if ButtonCombo > 0 AND HoldClick = 0 then
								HoldClick = 1
								JoyAnalog = 1 - JoyAnalog
								JoyInvertAxes = 0
								JoyKeySetting = 0
							end if
						end if
					end if
				elseif PID = 11 then
					if ControlStyle <= CTRL_KEYBOARD then
						gfxstring(CustomItem(4,PID)+" (overridden)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Invert Axes is available only for USB Controllers"
						end if
					else
						if JoyInvertAxes = 0 then
							gfxstring(CustomItem(4,PID)+" (inactive)",5,PosY,4,4,3,rgb(255,255,255))
						else
							gfxstring(CustomItem(4,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
						end if
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Inverts all Controller axes to improve flexibility"

							draw_box(0,SelY,1023,SelY+29)
							if ButtonCombo > 0 AND HoldClick = 0 then
								HoldClick = 1
								JoyInvertAxes = 1 - JoyInvertAxes
							end if
						end if
					end if
				elseif PID = 12 then
					if ControlStyle <= CTRL_TABLET then
						gfxstring(CustomItem(4,PID),5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Customization is unavailable for this control style."
						end if
					elseif ControlStyle = CTRL_KEYBOARD then
						gfxstring(CustomItem(4,PID)+" ("+str(KeyboardSpeed)+" px/frame)",5,PosY,4,4,3,rgb(255,128,0))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "How quickly the paddle moves when using a keyboard. -+ to change rate"
						end if
						
						if InType = "_" OR InType = "-" then
							KeyboardSpeed = max(KeyboardSpeed - 4,12) 
						elseif InType = "=" OR InType = "+" then
							KeyboardSpeed = min(KeyboardSpeed + 4,40) 
						end if
					elseif JoyAnalog = 0 then
						getjoystick(ControlStyle-4,JoyButtons)
						if JoyButtons > 0 then
							JoyKeySetting = int(exLog(JoyButtons,2))
						end if
						
						gfxstring(CustomItem(4,PID)+" (button "+str(JoyKeySetting)+")",5,PosY,4,4,3,rgb(255,128,0))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "The primary button. Other buttons grant finer movement. All axes move the paddle"
						end if
					else
						getjoystick(ControlStyle-4,0,JoyAxis(0),JoyAxis(1),JoyAxis(2),JoyAxis(3),JoyAxis(4),JoyAxis(5),JoyAxis(6),JoyAxis(7))
						for AxisID as byte = 0 to 7
							if JoyAxis(AxisID) > -999 AND (JoyAxis(AxisID) > 0.01 OR JoyAxis(AxisID) < -0.01) then
								JoyKeySetting = AxisID
							end if
						next AxisID
						
						gfxstring(CustomItem(4,PID)+" (axis "+str(JoyKeySetting)+")",5,PosY,4,4,3,rgb(255,128,0))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "The chosen axis will be used to move the paddle. Any button performs actions"
						end if
					end if
				end if
			next PID
			
		elseif AFilter = MISC then
			ItemDesc = "Mouse over an item to see its description."

			for PID as ubyte = (PageNum-1)*PerPage+1 to (PageNum)*PerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(PerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(PerPage*30))
				if PID > TotalCount(AFilter) then
					exit for
				end if
				
				if MouseY >= SelY AND MouseY < SelY+30 then
					select case PID
						case 1
							ItemDesc = "While active, no game or capsule hints will be given, except mystery capsules"
						case 2
							ItemDesc = "Enables particles to drop when blocks are hit. Sometimes gets intensive"
						case 3
							ItemDesc = "Replaces a traditional life system with a barrier that weakens when used to rebound"
						case 4
							ItemDesc = "Shuffles most levels in a campaign, resulting in a different experience with each play"
						case 5
							ItemDesc = "Toggle between Full Screen and a Windowed application (Shortcut: F7)"
						case 6
							ItemDesc = "Determines how dark to make the backgrounds."
					end select
				end if
				
				if (PID = 1 AND DisableHints = 1) OR _
					(PID = 2 AND EnhancedGFX = 1) OR _
					(PID = 3 AND CampaignBarrier = 1) OR _
					(PID = 4 AND ShuffleLevels = 1) OR _
					(PID = 5 AND FullScreen = 1) then
					gfxstring(CustomItem(MISC,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
					if MouseY >= SelY AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 AND HoldClick = 0 then
							select case PID
								case 1
									DisableHints = 0
								case 2
									EnhancedGFX = 0
								case 3
									CampaignBarrier = 0
								case 4
									ShuffleLevels = 0
								case 5
									toggle_fullscreen(-1)
							end select
						end if
					end if
				elseif PID = 6 then
					gfxstring(CustomItem(MISC,PID)+" ("+str(BGBrightness)+"%)",5,PosY,4,4,3,rgb(255,255,255))
					if MouseY >= SelY AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 AND HoldClick = 0 then
							BGBrightness -= 25
							if BGBrightness < 0 then
							 	BGBrightness = 75
							end if
						end if
					end if
				else
					gfxstring(CustomItem(MISC,PID)+" (inactive)",5,PosY,4,4,3,rgb(255,255,255))
					if MouseY >= SelY AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 AND HoldClick = 0 then
							select case PID
								case 1
									DisableHints = 1
								case 2
									EnhancedGFX = 1
								case 3
									CampaignBarrier = 1
								case 4
									ShuffleLevels = 1
								case 5
									toggle_fullscreen(1)
							end select
						end if
					end if
				end if
			next PID
		end if
		if AFilter = 1 OR AFilter = 4 OR AFilter = 5 then
			gfxstring(ItemDesc,5,700,4,3,2,rgb(255,0,255))
		elseif AFilter = 2 then
			if PageNum > 1 then
				gfxstring("Previous page",5,700,4,4,3,rgb(255,0,255))
				if MouseY >= 695 AND MouseY < 724 AND MouseX < 512 then
					draw_box(0,695,511,724)
					if ButtonCombo > 0 AND HoldClick = 0 then
						Pagenum -= 1
					end if
				end if
			else
				gfxstring("Previous page",5,700,4,4,3,rgb(128,0,128))
			end if
			if PageNum < int(TotalCount(AFilter)/PerPage+1-1e-10) then
				gfxstring("Next page",517,700,3,3,2,rgb(255,0,255))
				if MouseY >= 695 AND MouseY < 724 AND MouseX >= 512 then
					draw_box(512,695,1023,724)
					if ButtonCombo > 0 AND HoldClick = 0 then
						Pagenum += 1
					end if
				end if
			else
				gfxstring("Next page",517,700,4,4,3,rgb(128,0,128))
			end if
		elseif AFilter = 4 then
			gfxstring(ItemDesc,5,700,4,3,2,rgb(255,0,255))
		end if
		gfxstring("Exit",5,730,4,4,3,rgb(255,255,255))
		if MouseY >= 725 AND MouseY < 754 then
			draw_box(0,725,1023,754)
			if ButtonCombo > 0 AND HoldClick = 0 then
				exit do
			end if
		end if
		if Result = 0 then
			disp_mouse(MouseX,MouseY,MouseColor)
		end if
		if ButtonCombo > 0 then
			HoldClick = 1
		else
			HoldClick = 0
		end if
		InType = inkey
		if InType = XBox then
			clean_up
			end 0
		end if
		screenevent(@e)
		screencopy
		sleep 10
	loop until InType = EscapeKey
	erase Filter, HelpText, TotalCount, CustomItem, CampaignTxt
end sub
