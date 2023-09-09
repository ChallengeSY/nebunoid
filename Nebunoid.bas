#IFNDEF __FB_DOS__
#DEFINE __USE_FBSOUND__
#ENDIF

#include "Nebunoid.bi"
#include "NNCampaign.bas"

if FileExists("portable") = 0 then
	#IFDEF __FB_WIN32__
	if environ("APPDATA") <> "" then
		if Dir(environ("APPDATA")+"\Nebunoid",fbDirectory) = "" then
			mkdir(environ("APPDATA")+"\Nebunoid")
		end if
		chdir(environ("APPDATA")+"\Nebunoid")
	end if
	#ELSEIF NOT defined(__FB_DOS__)
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

	if ScreenCreated = 0 then
		TitleBanner = ImageCreate(281,60)
		bload(MasterDir+"/gfx/banner.bmp",TitleBanner)
	end if
end if
windowtitle "Nebunoid 1.05"

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

MusicPlrEnabled = 1

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
			case "enhanced"
				input #10, EnhancedGFX
			case "controls"
				input #10, ControlStyle
			case "campbarr"
				input #10, CampaignBarrier
			case "shuffle"
				input #10, ShuffleLevels
			case "musplayer"
				input #10, MusicPlrEnabled
			case "bgbright"
				input #10, BGBrightness
				BGBrightness = max(min(BGBrightness,100),0)
			case "xp"
				input #10, TotalXP
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

	if MenuMode > 0 then
		gfxstring("Play the game",40,150,5,5,3,rgb(255,255,0))
	else
		gfxstring("Play the game",40,150,5,5,3,rgb(255,255,255))
	end if
	
	gfxstring("Customize",40,200,5,5,3,rgb(255,255,255))
	
	if MenuMode = 0 then
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
	elseif MenuMode = 1 then
		dim as uinteger Availability
		gfxstring("Official Campaign Selection",40,350,5,4,3,rgb(255,192,64))
		gfxstring(commaSep(TotalStars)+" stars",820,350,5,4,3,rgb(255,192,64))
		for Item as byte = 1 to CampaignsPerPage+1
			with OfficialCampaigns(Item)
				if .Namee <> "" then
					if Item < CampaignsPerPage+1 then
						if .StarsToUnlock = 0 then
							.SetLocked = 0
							Availability = rgb(255,255,255)
							gfxstring("(Free)",340,351+Item*30,4,3,3,Availability)
						elseif TotalStars >= .StarsToUnlock then
							.SetLocked = 0
							Availability = rgb(255,255,255)
							gfxstring("(Unlocked)",340,351+Item*30,4,3,3,Availability)
						else
							.SetLocked = -1
							Availability = rgb(128,128,128)
							gfxstring("("+commaSep(.StarsToUnlock)+" stars to unlock)",340,351+Item*30,4,3,3,Availability)
						end if
					else
						if .SetSize > 0 then
							Availability = rgb(255,255,255)
						else
							Availability = rgb(128,128,128)
						end if
						.SetLocked = (.SetSize = 0)
					end if
					gfxstring(.Namee,40,351+Item*30,4,3,3,Availability)
					if .SetMastered then
						gfxstring("Size "+str(.SetSize),820,351+Item*30,4,3,3,rgb(255,215,0))
					else
						gfxstring("Size "+str(.SetSize),820,351+Item*30,4,3,3,Availability)
					end if
				end if
			end with
		next Item
	else
		dim as uinteger Availability
		gfxstring("Community Campaign Selection",40,350,5,4,3,rgb(255,192,64))
		for Item as byte = 1*(MenuMode-2)*CampaignsPerPage to min((MenuMode-1)*CampaignsPerPage,OfficialCampaigns(12).SetSize)
			with CommunityCampaigns(Item)
				if .Namee <> "" then
					if .SetSize > 0 then
						Availability = rgb(255,255,255)
					else
						Availability = rgb(128,128,128)
					end if
					gfxstring(.Namee,40,351+Item*30,4,3,3,Availability)
					gfxstring("Size "+str(.SetSize),820,351+Item*30,4,3,3,Availability)
				end if
			end with
		next Item
		
		if MenuMode >= 1 + ceil(OfficialCampaigns(12).SetSize/11) then
			gfxstring("(Back to official campaigns)",40,351+(CampaignsPerPage+1)*30,4,3,3,rgb(255,255,255))
		else
			gfxstring("(More community campaigns)",40,351+(CampaignsPerPage+1)*30,4,3,3,rgb(255,255,255))
		end if
	end if
	
	if MouseX >= 32 AND MouseX < 992 then
		if MouseY >= 140 AND MouseY < 185 AND CampaignFolder <> "" then
			draw_box(32,140,991,184)
			if ButtonCombo > 0 AND HoldClick = 0 then
				read_campaigns
				MenuMode = iif(MenuMode = 0,1,0)
				HoldClick = 1
			end if
		elseif MouseY >= 190 AND MouseY < 235 then
			draw_box(32,190,991,234)
			if ButtonCombo > 0 AND HoldClick = 0 then
				HoldClick = 1
				shop
				MenuMode = 0
				while inkey <> "":wend
			end if
		end if
		if MouseY >= 240 AND MouseY < 285 then
			draw_box(32,240,991,284)
			if ButtonCombo > 0 AND HoldClick = 0 then
				exit do
			end if
		end if
		
		if MenuMode = 1 then
			'Official campaign mouse input
			for YID as ubyte = 1 to CampaignsPerPage+1
				with OfficialCampaigns(YID)
					if MouseY >= 346+YID*30 AND MouseY <= 375+YID*30 AND .Namee <> "" AND .SetLocked = 0 then
						draw_box(32,346+YID*30,991,375+YID*30)
						if ButtonCombo > 0 AND HoldClick = 0 then
							if YID = 12 then
								'Switch to community campaigns
								MenuMode += 1
								HoldClick = 1
							else
								CampaignFolder = .Folder
								campaign_gameplay
								load_title_capsules
								MenuMode = 0
								while inkey <> "":wend
							end if
						end if
					end if
				end with
			next YID
		elseif MenuMode > 1 then
			dim as integer ReadID
			
			'Community campaign mouse input
			for YID as ubyte = 1 to CampaignsPerPage+1
				ReadID = YID + (MenuMode-2)*CampaignsPerPage
				
				with CommunityCampaigns(ReadID)
					if ReadID <= OfficialCampaigns(12).SetSize AND MouseY >= 346+YID*30 AND MouseY <= 375+YID*30 AND .Namee <> "" AND .SetSize > 0 then
						draw_box(32,346+YID*30,991,375+YID*30)
						if ButtonCombo > 0 AND HoldClick = 0 then
							if YID = 12 then
								MenuMode += 1
							else
								CampaignFolder = .Folder
								campaign_gameplay
								load_title_capsules
								MenuMode = 0
								while inkey <> "":wend
							end if
						end if
					end if
				end with
			next YID
			
			if MouseY >= 346+(CampaignsPerPage+1)*30 AND MouseY <= 375+(CampaignsPerPage+1)*30 then
				draw_box(32,346+(CampaignsPerPage+1)*30,991,375+(CampaignsPerPage+1)*30)
				if ButtonCombo > 0 AND HoldClick = 0 then
					'Cycle community campaign pages; or go back to official campaigns if final page
					if MenuMode >= 1 + ceil(OfficialCampaigns(12).SetSize/11) then
						MenuMode = 1
					else
						MenuMode += 1
					end if
					HoldClick = 1
				end if
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
	dim as ubyte TotalCount(0 to MISC) => {0, 0, 12, 7}
	dim as ubyte CTRL_BUTTON_ACTION, CTRL_AXIS_MOVEMENT

	dim as string ItemDesc, CommunityFolder, CustomItem(MISC,12)
	dim as ubyte AFilter, PageNum, LongLen
	dim as ushort PosY, SelY
	dim as integer JoyError(4), JoyButtons
	
	for JoyID as byte = 1 to 4
		JoyError(JoyID) = getJoystick(JoyID-1)
	next JoyID
	
	dim as string Filter(0 to MISC) => {_
		"Folders", _
		"Difficulty", _
		"Controls", _
		"Miscellaneous"}

	CustomItem(2,1) = "Desktop controls "
	CustomItem(2,2) = "Laptop controls  "
	CustomItem(2,3) = "Tablet controls  "
	CustomItem(2,4) = "Keyboard controls"
	CustomItem(2,5) = "USB controller 1 "
	CustomItem(2,6) = "USB controller 2 "
	CustomItem(2,7) = "USB controller 3 "
	CustomItem(2,8) = "USB controller 4 "
	CustomItem(2,10) = "Controller type"
	CustomItem(2,11) = "Invert axes    "
	CustomItem(MISC,1) = "Disable game hints     "
	CustomItem(MISC,2) = "Enhanced particle GFX  "
	CustomItem(MISC,3) = "Campaign barrier system"
	CustomItem(MISC,4) = "Shuffle levels         "
	CustomItem(MISC,5) = "Full screen setting    "
	CustomItem(MISC,6) = "Background brightness  "
	CustomItem(MISC,7) = "Music player           "
	
	read_campaigns(1)
	
	do
		MouseColor = rgb(0,255,128)
		cls
		Result = getmouse(MouseX,MouseY,0,ButtonCombo)
		gfxstring("Customize",5,5,7,7,3,rgb(255,128,0))
		gfxstring(commaSep(TotalStars)+" stars",517,5,7,7,3,rgb(0,128,255))

		for FID as ubyte = 0 to MISC
			if FID = 0 then
				gfxstring(Filter(FID),5+256*FID,50,4,4,3,rgb(128,0,255))
			elseif AFilter = FID then
				gfxstring(Filter(FID),5+256*FID,50,4,4,3,rgb(128,0,128))
			else
				gfxstring(Filter(FID),5+256*FID,50,4,4,3,rgb(255,0,255))
				if MouseY >= 45 AND MouseY < 75 AND MouseX > 256*FID AND MouseX < 256*(FID+1) then
					draw_box(256*FID,45,256*(FID+1)-1,74)
					if ButtonCombo > 0 AND HoldClick = 0 then
						AFilter = FID
						PageNum = 1
					end if
				end if
			end if
		next FID

		if AFilter = 1 then
			dim as short InX, CalcX, WarpSystem
			dim as double ApproxDiff, DiffUnlocked
			dim as string DiffTxt, ContinueSpecs, ExtraInfo
			
			dim as integer DiffStarsUnlock(4) => {25,50,75,100,125}
			dim as integer NextStarsUnlock
			
			DiffUnlocked = 12
			for UID as byte = 0 to ubound(DiffStarsUnlock)
				if TotalStars < DiffStarsUnlock(UID) then
					DiffUnlocked = UID + 7
					NextStarsUnlock = DiffStarsUnlock(UID)
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
				dim as uinteger PlrColor
				
				for PID as ubyte = 1 to 4
					if PageNum = PID then
						PlrColor = rgb(128,192,255)
					else
						PlrColor = rgb(128,128,255)
					end if
					gfxstring("Difficulty for player "+str(PID)+": "+DiffTxt+" ("+left(str(ComputeDiff),len(str(int(ComputeDiff)))+2)+")",5,(PID+2)*30,4,4,3,PlrColor)
				next PID
			else
				gfxstring("Difficulty for everyone: "+DiffTxt+" ("+left(str(ComputeDiff),len(str(int(ComputeDiff)))+2)+")",5,90,4,4,3,rgb(128,192,255))
				for PID as ubyte = 2 to 4
					gfxstring("Difficulty for player "+str(PID)+": "+DiffTxt+" ("+left(str(ComputeDiff),len(str(int(ComputeDiff)))+2)+")",5,(PID+2)*30,4,4,3,rgb(64,64,128))
				next PID
			end if
			if DiffUnlocked < 12 then
				gfxstring("Next difficulty unlock : "+commaSep(NextStarsUnlock)+" stars",5,210,4,4,3,rgb(255,128,128))
			else
				gfxstring("All difficulties unlocked",5,210,4,4,3,rgb(128,128,128))
			end if
			
			gfxstring("Speed increase  : Every "+left(str(100/ApproxDiff),4)+" bounces/blocks",5,550,4,4,3,rgb(128,128,255))
			gfxstring("Continue penalty: "+ContinueSpecs,5,580,4,4,3,rgb(128,128,255))
			if WarpSystem then
				gfxstring("Level select: Enabled",5,610,4,4,3,rgb(128,128,255))
			else
				gfxstring("Level select: Disabled",5,610,4,4,3,rgb(128,128,255))
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
			
		elseif AFilter = 2 then
			ItemDesc = "Mouse over a control style to see its description."
			
			if ControlStyle <= CTRL_TABLET then
				CustomItem(2,12) = "No settings    "
			elseif ControlStyle = CTRL_KEYBOARD then
				CustomItem(2,12) = "Movement speed "
			elseif JoyAnalog = 0 then
				CustomItem(2,12) = "Action button  "
			else
				CustomItem(2,12) = "Paddle axis    "
			end if

			for PID as ubyte = (PageNum-1)*CustomizePerPage+1 to (PageNum)*CustomizePerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(CustomizePerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(CustomizePerPage*30))
				if PID > TotalCount(AFilter) then
					exit for
				end if
				
				if MouseY >= SelY AND MouseY < SelY+30 AND CustomItem(2,PID) <> "" then
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
					gfxstring(CustomItem(2,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
					if PID - 1 > CTRL_KEYBOARD AND MouseY >= SelY AND MouseY < SelY+30 then
						ItemDesc = "Customize below. For safety reasons, this setting is not remembered across sessions"
					end if
				elseif PID <= 4 then
					gfxstring(CustomItem(2,PID)+" (available)",5,PosY,4,4,3,rgb(255,255,255))
					if MouseY >= SelY AND MouseY < SelY+30 then
						draw_box(0,SelY,1023,SelY+29)
						if ButtonCombo > 0 then
							ControlStyle = PID - 1
						end if
					end if
				elseif PID <= 8 then
					dim as byte RefJoy = PID-4
					
					if JoyError(RefJoy) then
						gfxstring(CustomItem(2,PID)+" (disabled)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "No controller detected at this port"
						end if
					else
						gfxstring(CustomItem(2,PID)+" (available)",5,PosY,4,4,3,rgb(255,255,255))
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
						gfxstring(CustomItem(2,PID)+" (overridden)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Controller Type is available only for USB Controllers"
						end if
					else
						if JoyAnalog = 0 then
							gfxstring(CustomItem(2,PID)+" (Digital Controller)",5,PosY,4,4,3,rgb(255,255,255))
						else
							gfxstring(CustomItem(2,PID)+" (Analog Controller)",5,PosY,4,4,3,rgb(255,255,255))
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
						gfxstring(CustomItem(2,PID)+" (overridden)",5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Invert Axes is available only for USB Controllers"
						end if
					else
						if JoyInvertAxes = 0 then
							gfxstring(CustomItem(2,PID)+" (inactive)",5,PosY,4,4,3,rgb(255,255,255))
						else
							gfxstring(CustomItem(2,PID)+" (active)",5,PosY,4,4,3,rgb(0,255,0))
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
						gfxstring(CustomItem(2,PID),5,PosY,4,4,3,rgb(128,128,128))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "Customization is unavailable for this control style."
						end if
					elseif ControlStyle = CTRL_KEYBOARD then
						gfxstring(CustomItem(2,PID)+" ("+str(KeyboardSpeed)+" px/frame)",5,PosY,4,4,3,rgb(255,128,0))
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
						
						gfxstring(CustomItem(2,PID)+" (button "+str(JoyKeySetting)+")",5,PosY,4,4,3,rgb(255,128,0))
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
						
						gfxstring(CustomItem(2,PID)+" (axis "+str(JoyKeySetting)+")",5,PosY,4,4,3,rgb(255,128,0))
						if MouseY >= SelY AND MouseY < SelY+30 then
							ItemDesc = "The chosen axis will be used to move the paddle. Any button performs actions"
						end if
					end if
				end if
			next PID
			
		elseif AFilter = MISC then
			ItemDesc = "Mouse over an item to see its description."

			for PID as ubyte = (PageNum-1)*CustomizePerPage+1 to (PageNum)*CustomizePerPage
				PosY = CustomizePadding+(PID*30)-((PageNum-1)*(CustomizePerPage*30))
				SelY = CustomizeSelect+(PID*30)-((PageNum-1)*(CustomizePerPage*30))
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
						case 7
							ItemDesc = "Determines whether music will play while a game is in progress (Shortcut: F5)"
					end select
				end if
				
				#IFNDEF __USE_FBSOUND__
				if PID = 7 then
					gfxstring(CustomItem(MISC,PID)+" (unsupported)",5,PosY,4,4,3,rgb(128,128,128))
				elseif (PID = 1 AND DisableHints = 1) OR _
					(PID = 2 AND EnhancedGFX = 1) OR _
					(PID = 3 AND CampaignBarrier = 1) OR _
					(PID = 4 AND ShuffleLevels = 1) OR _
					(PID = 5 AND FullScreen = 1) then
				#ELSE
				if (PID = 1 AND DisableHints = 1) OR _
					(PID = 2 AND EnhancedGFX = 1) OR _
					(PID = 3 AND CampaignBarrier = 1) OR _
					(PID = 4 AND ShuffleLevels = 1) OR _
					(PID = 5 AND FullScreen = 1) OR _
					(PID = 7 AND MusicPlrEnabled = 1) then
				#ENDIF
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
								case 7
									MusicPlrEnabled = 0
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
								case 7
									MusicPlrEnabled = 1
							end select
						end if
					end if
				end if
			next PID
		end if
		if AFilter > 1 then
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
	erase Filter, TotalCount, CustomItem
end sub
