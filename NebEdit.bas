#include "NebEdit.bi" 
windowtitle "Nebunoid Level Editor"
screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH

'Foreground assets
loadBrickGfx("gfx/blocks/")

FramesetMerged = ImageCreate(1024,768)
bload("gfx/framesMerged.bmp",FramesetMerged)

screenset 1,0
PlayerSlot(Player).LevelNum = 1
PlayerSlot(Player).PerfectClear = 1
ActiveDifficulty = 4

#IFNDEF __FB_DOS__
'Prep for binding a thread to it 
PlaytestLock = MutexCreate
#ENDIF

DispGrid = 1

do
	cls
	Result = getmouse(MouseX,MouseY,0,ButtonCombo)
	put (0,0),FramesetMerged,trans
	ExploTick += 1
	with PlayerSlot(Player)
		BrickCount = dispWall(0,2)
	
		for BID as ubyte = 1 to min(BlockBrushes + 1,35)
			drawBrushes(BID)
		next BID
		
		if CondensedLevel then
			drawBricks(1+int((MouseX-32)/24),1+int((MouseY-96)/24))
		else
			drawBricks(1+int((MouseX-32)/48),1+int((MouseY-96)/24))
		end if
		
		'Brick count and coordinate displays
		if HighlightX > 0 AND HighlightY > 0 then
			uiElement("("+str(HighlightX)+","+str(HighlightY)+")",45,6,7,rgb(255,255,255))
		elseif MouseX >= 43 AND MouseY >= 5 AND MouseX < 170 AND MouseY < 32 then
			uiElement(commaSep(BrickCount),45,6,7,rgb(255,255,0))
			if ButtonCombo > 0 then
				mirrorSubmenu
			endif
		else
			uiElement(commaSep(BrickCount),45,6,7,rgb(255,255,255))
		end if

		'Game Style number display
		if MouseX >= 190 AND MouseY >= 5 AND MouseX < 317 AND MouseY < 32 then
			uiElement(commaSep(GameStyle),192,6,7,rgb(255,255,0))
			if ButtonCombo > 0 then
				editLevelVariations
			end if
		else
			uiElement(commaSep(GameStyle),192,6,7,rgb(255,255,255))
		end if
	
		'Player and Lives displays
		uiElement("E",343,6,0,rgb(128,128,128))
		if MouseX >= 384 AND MouseY >= 5 AND MouseX < 403 AND MouseY < 32 then
			uiElement(str(StartingLives),386,6,0,rgb(255,255,0))
			if ButtonCombo > 0 then
				editStartingLives
			end if
		elseif ExtraBarrierPoint then
			uiElement(str(StartingLives),386,6,0,rgb(128,255,255))
		else
			uiElement(str(StartingLives),386,6,0,rgb(255,255,255))
		end if 
		
		'Level time limit display
		TimeStr = str(int(LevelTimeLimit/60))+":"+_
			str(int(remainder(LevelTimeLimit,60)/10))+_
			str(int(remainder(LevelTimeLimit,10)))
		if MouseX >= 558 AND MouseY >= 5 AND MouseX < 649 AND MouseY < 32 then
			uiElement(TimeStr,560,6,5,rgb(255,255,0))
			if ButtonCombo > 0 then
				editTimeLimit
			end if
		else
			uiElement(TimeStr,560,6,5,rgb(255,255,255))
		end if
		
		if .BossMaxHealth < 1e4 then
			BossHP = str(.BossMaxHealth)
		elseif .BossMaxHealth < 1e6 then
			BossHP = str(ceil(.BossMaxHealth/1e3))+"K"
		elseif .BossMaxHealth < 1e9 then
			BossHP = str(ceil(.BossMaxHealth/1e6))+"M"
		else
			BossHP = str(ceil(.BossMaxHealth/1e9))+"B"
		end if
	
		'Boss/Ceiling health display
		if MouseX >= 669 AND MouseY >= 5 AND MouseX < 742 AND MouseY < 32 then
			uiElement(BossHP,671,6,4,rgb(255,255,0))
			if ButtonCombo > 0 then
				editBossHealth
			end if
		else
			uiElement(BossHP,671,6,4,rgb(255,255,255))
		end if
	
		'Password display
		if MouseX >= 762 AND MouseY >= 5 AND MouseX < 907 AND MouseY < 32 then
			uiElement(CampaignPassword,764,6,0,rgb(255,255,0))
			if ButtonCombo > 0 then
				editLevelPassword
			end if
		elseif CampaignPassword = "--------" then
			uiElement("Fatal!",764,6,7,rgb(255,128,128))
		elseif CampaignPassword <> "++++++++" then
			uiElement(CampaignPassword,764,6,0,rgb(255,255,255))
		end if
		
		'Level display
		if MouseX >= 933 AND MouseY >= 5 AND MouseX < 988 AND MouseY < 32 then
			uiElement(str(.LevelNum),935,6,3,rgb(255,255,0))
			if ButtonCombo > 0 then
				levelOptions
			end if
		else
			uiElement(str(.LevelNum),935,6,3,rgb(255,255,255))
		end if
		
		if CampaignFolder = "" then
			GameInfo = "No campaign loaded. Press [CTRL]+[L] to create/load a campaign"

			if CampaignUnsaved OR LevelUnsaved then
				Instructions = "Reminder: This is an unsaveable design, because no campaign was loaded"
				InstructExpire = timer + 10
				CampaignUnsaved = 0
				LevelUnsaved = 0
			end if
		else
			GameInfo = CampaignName + ": " + CampaignLevelName
		end if

		if MouseX >= 53 AND MouseY >= 36 AND MouseX < 988 AND MouseY < 66 then
			gfxstring(GameInfo,54,38,5,3,3,rgb(255,255,0))
			if ButtonCombo > 0 then
				campaignMetadata
			end if
		else
			gfxstring(GameInfo,54,38,5,3,3,rgb(255,255,255))
		end if
		
		if BrushEditor then
			brushEditorSubmenu
		end if
		
		if InstruAlpha >= 320 then
			InstruAlpha = -320
		elseif InstruAlpha = 0 OR Instructions = "" then
			InstruAlpha = 0
			Instructions = ""

			if len(LevelDescription) > 0 then
				Instructions = LevelDescription
				InstructExpire = timer + 5
			end if
		elseif Instructions = LevelDescription then
			InstructExpire = timer + 5
		end if
		
		if InstruAlpha = 0 then
			InstruBeta = 0
			InstruGamma = 0
		else
			if InstruAlpha > 0 then
				InstruBeta = abs(InstruAlpha)
				InstruGamma = InstruAlpha - 64
				if InstruGamma < 0 then InstruGamma = 0
			else
				InstruGamma = abs(InstruAlpha)
				InstruBeta = InstruAlpha + 64
				if InstruBeta > 0 then
					InstruBeta = 0
				else
					InstruBeta = abs(InstruBeta)
				end if
			end if
			
			if InstruBeta > 255 then InstruBeta = 255
			if InstruGamma > 255 then InstruGamma = 255
		end if
		
		for QMID as ubyte = 1 to 4
			if InType = str(QMID) then
				if (MirrorEditing AND (1 SHL (QMID-1))) then
					MirrorEditing -= 2^(QMID-1)
					Instructions = MirrorOptions(int(QMID-1))+" deactivaated"
				else
					MirrorEditing += 2^(QMID-1)
					Instructions = MirrorOptions(int(QMID-1))+" activaated"
				end if
				InstructExpire = timer + 5
			end if
		next QMID
		
		gfxstring(Instructions,512-gfxlength(Instructions,5,3,3)/2,740,5,3,3,rgba(255,255,255,InstruGamma),rgba(255,255,255,InstruBeta))
		if timer > InstructExpire OR abs(InstruAlpha) < 320 then
			InstruAlpha += 4
		end if

		screencopy
		sleep 12
		InType = inkey
		if InType = chr(12) then
			if LevelUnsaved OR CampaignUnsaved then
				locate 48,1
				print "Campaign changes unsaved. Switch anyway? (Y/N)";
				screencopy
				do
					sleep
					InType = lcase(inkey)
					
					if InType = "y" then
						CampaignUnsaved = 0
						LevelUnsaved = 0
						exit do
					end if
				loop until InType = "n"
			end if
			
			if LevelUnsaved = 0 AND CampaignUnsaved = 0 then
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter campaign folder name: ",CampaignFolder
				screenset 1,0
				if instr(CampaignFolder,"/") > 0 OR instr(CampaignFolder,"\") > 0 OR _
					instr(CampaignFolder,".") > 0 OR instr(CampaignFolder,"*") > 0 OR instr(CampaignFolder,"?") > 0 then
					CampaignFolder = ""
					Instructions = "Name forbidden for technical reasons"
					InstructExpire = timer + 10
				end if
				if CampaignFolder <> "" then
					CampaignFolder = ActiveFolder + "/" + CampaignFolder
				end if
				if FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/Settings.txt") then
					load_settings
				else
					CampaignName = "Blank campaign"
					StartingLives = 3
					BaseCapsuleValue = 100
					InitialExtraLife = 0
					SubsequentExtraLives = 0
					ExplodingValue = 8
					SecretLevels = 0
					clearLevel
				end if
				resetEditorSpecs
				.LevelNum = 1
			end if
		elseif InType = CtrlG then
			DispGrid = 1 - DispGrid 
		elseif InType = CtrlS AND CampaignFolder <> "" then
			saveCampaign(.LevelNum)
		elseif InType = CtrlP AND CampaignFolder <> "" then
			if BrickCount = 0 then
				Instructions = "No blocks detected. Sequence aborted."
				InstructExpire = timer + 5
			elseif PlaytestUse then
				Instructions = "Nebunoid is already running! Sequence aborted."
				InstructExpire = timer + 7
			else
				if LevelUnsaved then
					locate 48,1
					print space(127);
					locate 48,1
					print "This process will save the current level. Proceed anyway? (Y/N)";
					screencopy
					do
						InType = lcase(inkey)
						if InType = "y" then
							saveCampaign(.LevelNum)
							if PlaytestLock = 0 then
								Instructions = ""
							end if
							exit do
						end if
					loop until InType = "n"
				end if
			
				if LevelUnsaved = 0 then
					if PlaytestLock = 0 then
						launchPlaytest
					else
						PlaytestSes = ThreadCreate(@launchPlaytest)
					end if
				endif
			end if
		elseif InType = LeftArrow then
			shiftField(-1,0)
		elseif InType = RightArrow then
			shiftField(1,0)
		elseif InType = UpArrow then
			shiftField(0,-1)
		elseif InType = DownArrow then
			shiftField(0,1)
		elseif (InType = "+" OR InType = "=") AND FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/L" + str(.LevelNum) + ".txt") then
			if LevelUnsaved then
				locate 48,1
				print "Level changes unsaved. Switch anyway? (Y/N)";
				screencopy
				do
					sleep
					InType = lcase(inkey)
					
					if InType = "y" then
						LevelUnsaved = 0
						exit do
					end if
				loop until InType = "n"
			end if
			
			if LevelUnsaved = 0 then
				.LevelNum += 1
				if FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/L" + str(.LevelNum) + ".txt") then
					loadLevel(.LevelNum)
				else
					clearLevel
				end if
				resetEditorSpecs
			end if
		elseif (InType = "-" OR InType = "_") AND .LevelNum > 1 then
			if LevelUnsaved then
				locate 48,1
				print "Level changes unsaved. Switch anyway? (Y/N)";
				screencopy
				do
					sleep
					InType = lcase(inkey)
					
					if InType = "y" then
						LevelUnsaved = 0
						exit do
					end if
				loop until InType = "n"
			end if
			
			if LevelUnsaved = 0 then
				.LevelNum -= 1
				loadLevel(.LevelNum)
				resetEditorSpecs
			end if
		elseif InType = EscapeKey OR InType = XBox then
			if LevelUnsaved OR CampaignUnsaved then
				locate 48,1
				print "Campaign changes unsaved. Exit anyway? (Y/N)";
				screencopy
				do
					sleep
					InType = lcase(inkey)
					
					if InType = "y" then
						exit do, do
					end if
				loop until InType = "n"
			else
				exit do
			end if
		end if
	end with
loop
