#include "NebEdit.bi" 
windowtitle "Nebunoid Level Editor"
screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH

'Foreground assets
SoftBrickPic = ImageCreate(48,24)
bload("gfx/soft.bmp",SoftBrickPic)
MultihitPic = ImageCreate(48,24)
bload("gfx/multi.bmp",MultihitPic)
InvinciblePic = ImageCreate(48,24)
bload("gfx/invincible.bmp",InvinciblePic)

SoftBrickPicMini = ImageCreate(24,24)
bload("gfx/softSm.bmp",SoftBrickPicMini)
MultihitPicMini = ImageCreate(24,24)
bload("gfx/multiSm.bmp",MultihitPicMini)
InvincibleMini = ImageCreate(24,24)
bload("gfx/invincibleSm.bmp",InvincibleMini)

BaseExplode = ImageCreate(176,24)
ExplodePic = ImageCreate(48,24)
bload("gfx/explode.bmp",BaseExplode)

FramesetMerged = ImageCreate(1024,768)
bload("gfx/framesMerged.bmp",FramesetMerged)

screenset 1,0
PlayerSlot(Player).LevelNum = 1
PlayerSlot(Player).Difficulty = 4

do
	cls
	Result = getmouse(MouseX,MouseY,0,ButtonCombo)
	put (0,0),FramesetMerged,trans
	ExploTick += 1
	with PlayerSlot(Player)
		line(32,576)-(991,576),rgb(255,255,255),,&b1100110011001100
		if (Gamestyle AND (1 SHL STYLE_PROGRESSIVE)) then
			line(32,672)-(991,672),rgb(255,255,255),,&b1100110011001100
		end if
		BrickCount = disp_wall(0,2)
	
		for BID as ubyte = 1 to min(BlockBrushes + 1,35)
			draw_brushes(BID)
		next BID
		
		if CondensedLevel then
			draw_bricks(1+int((MouseX-32)/24),1+int((MouseY-96)/24))
		else
			draw_bricks(1+int((MouseX-32)/48),1+int((MouseY-96)/24))
		end if
		
		'Brick count and coordinate displays
		if HighlightX > 0 AND HighlightY > 0 then
			ui_element("("+str(HighlightX)+","+str(HighlightY)+")",45,6,7,rgb(255,255,255))
		elseif MouseX >= 43 AND MouseY >= 5 AND MouseX < 170 AND MouseY < 32 then
			ui_element(commaSep(BrickCount),45,6,7,rgb(255,255,0))
			if ButtonCombo > 0 then
				mirror_options
			endif
		else
			ui_element(commaSep(BrickCount),45,6,7,rgb(255,255,255))
		end if

		'Game Style number display
		if MouseX >= 190 AND MouseY >= 5 AND MouseX < 317 AND MouseY < 32 then
			ui_element(commaSep(GameStyle),192,6,7,rgb(255,255,0))
			if ButtonCombo > 0 then
				edit_level_variations
			end if
		else
			ui_element(commaSep(GameStyle),192,6,7,rgb(255,255,255))
		end if
	
		'Player and Lives displays
		ui_element("E",343,6,0,rgb(128,128,128))
		if MouseX >= 384 AND MouseY >= 5 AND MouseX < 403 AND MouseY < 32 then
			ui_element(str(StartingLives),386,6,0,rgb(255,255,0))
			if ButtonCombo > 0 then
				edit_starting_lives
			end if
		elseif ExtraBarrierPoint then
			ui_element(str(StartingLives),386,6,0,rgb(128,255,255))
		else
			ui_element(str(StartingLives),386,6,0,rgb(255,255,255))
		end if 
		
		'Level time limit display
		TimeStr = str(int(LevelTimeLimit/60))+":"+_
			str(int(remainder(LevelTimeLimit,60)/10))+_
			str(int(remainder(LevelTimeLimit,10)))
		if MouseX >= 558 AND MouseY >= 5 AND MouseX < 649 AND MouseY < 32 then
			ui_element(TimeStr,560,6,5,rgb(255,255,0))
			if ButtonCombo > 0 then
				edit_time_limit
			end if
		else
			ui_element(TimeStr,560,6,5,rgb(255,255,255))
		end if
	
		'Boss/Ceiling health display
		if MouseX >= 669 AND MouseY >= 5 AND MouseX < 742 AND MouseY < 32 then
			ui_element(str(.BossMaxHealth),671,6,4,rgb(255,255,0))
			if ButtonCombo > 0 then
				edit_boss_health
			end if
		else
			ui_element(str(.BossMaxHealth),671,6,4,rgb(255,255,255))
		end if
	
		'Password display
		if MouseX >= 762 AND MouseY >= 5 AND MouseX < 907 AND MouseY < 32 then
			ui_element(CampaignPassword,764,6,0,rgb(255,255,0))
			if ButtonCombo > 0 then
				edit_level_password
			end if
		elseif CampaignPassword = "--------" then
			ui_element("Fatal!",764,6,7,rgb(255,128,128))
		elseif CampaignPassword <> "++++++++" then
			ui_element(CampaignPassword,764,6,0,rgb(255,255,255))
		end if
		
		'Level display
		if MouseX >= 933 AND MouseY >= 5 AND MouseX < 988 AND MouseY < 32 then
			ui_element(str(.LevelNum),935,6,3,rgb(255,255,0))
			if ButtonCombo > 0 then
				level_options
			end if
		else
			ui_element(str(.LevelNum),935,6,3,rgb(255,255,255))
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
				campaign_metadata
			end if
		else
			gfxstring(GameInfo,54,38,5,3,3,rgb(255,255,255))
		end if
		
		if BrushEditor then
			brush_editor_submenu
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
					CampaignFolder = "community/" + CampaignFolder
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
					clear_level
				end if
				if abs(InstruAlpha) = 320 then
					InstruAlpha = -316
				end if
				MirrorEditing = 0
				SelectedBrush = 0
				.LevelNum = 1
			end if
		elseif InType = chr(19) AND CampaignFolder <> "" then
			save_campaign(.LevelNum)
		elseif InType = chr(16) AND CampaignFolder <> "" then
			if LevelUnsaved then
				locate 48,1
				print space(127);
				locate 48,1
				print "This process will save the current level. Proceed anyway? (Y/N)";
				screencopy
				do
					InType = lcase(inkey)
					if InType = "y" then
						save_campaign(.LevelNum)
						exit do
					end if
				loop until InType = "n"
			end if
			
			if LevelUnsaved = 0 then
				locate 48,1
				print space(127);
				locate 48,1
				print "Quick playtest in session. This program is suspended until session is concluded.";
				screencopy
				exec(MasterDir + GameProgram,"-l "+quote(CampaignFolder + "/L" + str(.LevelNum)))
				InType = ""
				while inkey <> "":wend
			end if
		elseif InType = LeftArrow then
			shift_field(-1,0)
		elseif InType = RightArrow then
			shift_field(1,0)
		elseif InType = UpArrow then
			shift_field(0,-1)
		elseif InType = DownArrow then
			shift_field(0,1)
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
				if abs(InstruAlpha) = 320 then
					InstruAlpha = -316
				end if
				SelectedBrush = 0
				MirrorEditing = 0
				if FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/L" + str(.LevelNum) + ".txt") then
					load_level(.LevelNum)
				else
					clear_level
				end if
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
				if abs(InstruAlpha) = 320 then
					InstruAlpha = -316
				end if
				SelectedBrush = 0
				MirrorEditing = 0
				load_level(.LevelNum)
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
