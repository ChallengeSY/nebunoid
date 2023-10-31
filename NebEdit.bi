#include "Nebunoid.bi"
#include "NNLocal.bas"

#IF defined(__FB_WIN32__) OR defined(__FB_DOS__)
const GameProgram = "\Nebunoid.exe"
#ELSE
const GameProgram = "/Nebunoid"
#ENDIF


dim as string TimeStr, GameInfo
dim as short InstruAlpha, InstruBeta, InstruGamma
dim shared as byte CampaignUnsaved, LevelUnsaved, SelectedBrush, BrushEditor, HighlightX, HighlightY, MirrorEditing
dim shared as short MaxLevels
dim shared as string MirrorOptions(3)
MirrorOptions(0) = "Mirror horizontally"
MirrorOptions(1) = "Mirror vertically"
MirrorOptions(2) = "Mirror from opposite corner"
MirrorOptions(3) = "Mirror diagonally"
Player = 1
CondensedLevel = 0

sub clear_level
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 40
			with PlayerSlot(Player).Tileset(XID,YID)
				.BrickID = 0
			end with
		next XID
	next YID
	
	for BID as ubyte = 1 to 35
		with Pallete(BID)
			.PColoring = 0
			.ScoreValue = 10
			.CalcedInvulnerable = 0
			.HitDegrade = 0
			.CanRegen = 0
		end with
	next BID
	
	MirrorEditing = 0
	Gamestyle = 3
	PlayerSlot(Player).BossMaxHealth = 0
	LevelTimeLimit = 0
	LevelDescription = ""
	CampaignLevelName = "Board "+str(PlayerSlot(Player).LevelNum)
	CampaignPassword = "++++++++"
	BlockBrushes = 0
	CondensedLevel = 0
end sub

sub edit_starting_lives
	dim as string NewTxtValue

	screenset 0,0
	locate 48,1
	print space(127);
	locate 48,1
	input ; "Enter starting lives: ",NewTxtValue
	screenset 1,0
	
	StartingLives = valint(NewTxtValue)
	if StartingLives < 1 then
		StartingLives = 1
	elseif StartingLives > 9 then
		StartingLives = 9
	end if
	ExtraBarrierPoint = abs(sgn(right(NewTxtValue,1) = "*"))
	CampaignUnsaved = 1
end sub

declare sub level_options
sub campaign_metadata
	dim as integer NewIntValue
	dim as string NewStrValue
	
	locate 48,1
	print "Campaign metadata: ";
	color rgb(0,255,0)
	print "N";
	color rgb(255,255,255)
	print "ame / ";
	color rgb(0,255,0)
	print "L";
	color rgb(255,255,255)
	print "ives / ";
	color rgb(0,255,0)
	print "C";
	color rgb(255,255,255)
	print "apsule ("+str(BaseCapsuleValue)+") / ";
	color rgb(0,255,0)
	print "E";
	color rgb(255,255,255)
	print "xtra lives ("+str(InitialExtraLife)+" / "+str(SubsequentExtraLives)+") / E";
	color rgb(0,255,0)
	print "x";
	color rgb(255,255,255)
	print "ploding ("+str(ExplodingValue)+") / ";
	color rgb(0,255,0)
	print "S";
	color rgb(255,255,255)
	print "ecrets ("+str(SecretLevels)+") / Le";
	color rgb(0,255,0)
	print "v";
	color rgb(255,255,255)
	print "el options";
	screencopy
	do
		sleep 20
		InType = lcase(inkey)
		
		select case InType
			case "n"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter new campaign name: ",NewStrValue
				screenset 1,0
				
				if NewStrValue = PlaytestName OR NewStrValue = EndlessShuffle then
					Instructions = "Name forbidden because it is reserved"
					InstructExpire = timer + 10
				elseif instr(NewStrValue,".") > 0 OR instr(NewStrValue,"*") > 0 OR _
					instr(NewStrValue,"?") > 0 OR instr(NewStrValue,"/") > 0 OR instr(NewStrValue,"\") > 0 then
					Instructions = "Name forbidden for technical reasons"
					InstructExpire = timer + 10
				else
					CampaignName = NewStrValue
					CampaignUnsaved = 1
				end if
				exit do
			case "l"
				edit_starting_lives
				exit do
			case "c"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter base capsule value: ",BaseCapsuleValue
				screenset 1,0

				CampaignUnsaved = 1
				exit do

			case "e"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter points needed for extra lives (Initial, Subsequent): ", InitialExtraLife, SubsequentExtraLives
				screenset 1,0
				
				if InitialExtraLife < 0 then
					InitialExtraLife = 0
				end if
				if SubsequentExtraLives < 0 then
					SubsequentExtraLives = 0
				end if
				CampaignUnsaved = 1
				exit do

			case "x"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter exploding block value: ", NewIntValue
				screenset 1,0
				
				if NewIntValue < 0 then
					NewIntValue = 0
				end if
				ExplodingValue = NewIntValue
				CampaignUnsaved = 1
				exit do

			case "s"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter secret level threshold: ", NewIntValue
				screenset 1,0
				
				if NewIntValue < 0 then
					NewIntValue = 0
				end if
				SecretLevels = NewIntValue
				CampaignUnsaved = 1
				exit do
				
			case "v"
				level_options
				exit do
				
		end select
	loop until InType = EscapeKey
end sub

sub edit_level_password
	locate 48,1
	print space(127);
	locate 48,1
	print "Password metadata: ";
	color rgb(0,255,0)
	print "T";
	color rgb(255,255,255)
	print "ype a password / ";
	color rgb(0,255,0)
	print "R";
	color rgb(255,255,255)
	print "andom password / ";
	color rgb(0,255,0)
	print "N";
	color rgb(255,255,255)
	print "o password / ";
	color rgb(0,255,0)
	print "F";
	color rgb(255,255,255)
	print "atal level";
	screencopy
	do
		sleep 20
		InType = lcase(inkey)
		
		select case InType
			case "t"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				input ; "Enter new level password: ",CampaignPassword
				screenset 1,0
				
				if len(CampaignPassword) < 8 then
					Instructions = "Password too short"
					InstructExpire = timer + 10
					CampaignPassword = "++++++++"
				else
					CampaignPassword = ucase(left(CampaignPassword,8))
					for CharID as ubyte = 1 to 8
						if mid(CampaignPassword,CharID,1) < "A" OR mid(CampaignPassword,CharID,1) > "Z" then
							CampaignPassword = "++++++++"
							Instructions = "Only letters (A-Z) are allowed in a password"
							InstructExpire = timer + 10
						end if 
					next CharID
				end if
				
				LevelUnsaved = 1
				exit do
			case "r"
				CampaignPassword = ""
				for CharID as ubyte = 1 to 8
					CampaignPassword += chr(irandom(65,90))					
				next CharID
				LevelUnsaved = 1
				exit do
			case "n"
				CampaignPassword = "++++++++"
				LevelUnsaved = 1
				exit do
				
			case "f"
				CampaignPassword = "--------"
				LevelUnsaved = 1
				exit do
				
		end select
	loop until InType = EscapeKey
end sub

sub edit_level_variations
	dim as ubyte StyleID
	dim as string StyleNames(15) => {"Powerups", "Extra Height", "Dual Paddles", "Double Juggling", "Cavity", "Progressive", "Steerable Balls", "Invisible", _
		"Hyper Speed", "Boss Battle", "Horizontal Rotation", "", "Shrink Ceiling", "Breakable Ceiling", "Fatal Timer", "Bonus Level"}
	do
		locate 48,1
		print space(127);
		locate 48,1
		print "Variations selector (&b"& bin(Gamestyle,16);"): ";StyleNames(StyleID);" ";
		if (Gamestyle AND (1 SHL StyleID)) then
			color rgb(0,255,0)
			print "(active)";
			color rgb(255,255,255)
		else
			print "(inactive)";
		end if
		screencopy
		sleep 20
		InType = inkey
		
		select case InType
			case LeftArrow
				if StyleID > 0 then
					do
						StyleID -= 1
					loop until StyleNames(StyleID) <> ""
				end if
			case RightArrow
				if StyleID < 15 then
					do
						StyleID += 1
					loop until StyleNames(StyleID) <> ""
				end if
			case EnterKey, space(1)
				if (Gamestyle AND (1 SHL StyleID)) then
					Gamestyle -= 2^StyleID
				else
					Gamestyle += 2^StyleID
				end if
				
		end select
	loop until InType = EscapeKey
	LevelUnsaved = 1
end sub

sub edit_time_limit
	screenset 0,0
	locate 48,1
	print space(127);
	locate 48,1
	input ; "Enter new time limit (seconds): ",LevelTimeLimit
	screenset 1,0
	
	LevelUnsaved = 1
end sub

sub edit_boss_health
	screenset 0,0
	locate 48,1
	print space(127);
	locate 48,1
	input ; "Enter new boss/ceiling health: ",PlayerSlot(Player).BossMaxHealth
	screenset 1,0
	
	LevelUnsaved = 1
end sub

sub delete_level(LevID as short)
	dim as string OldFile, NewFile
	OldFile = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LevID)+".txt"
	kill(OldFile)
	
	for LID as short = LevID to 998
		OldFile = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LID+1)+".txt"
		NewFile = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LID)+".txt"
		if FileExists(OldFile) then
			name(OldFile,NewFile)
		else
			exit for
		end if
	next LID
	
	with PlayerSlot(Player)
		if .LevelNum > 1 then
			.LevelNum -= 1
		end if
		SelectedBrush = 0
		LevelUnsaved = 0
		load_level(.LevelNum)
	end with
end sub

sub swap_levels(LevelA as short, LevelB as short)
	dim as string FileA, FileB, FileX
	FileA = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LevelA)+".txt"
	FileB = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LevelB)+".txt"
	FileX = MasterDir + "/campaigns/" + CampaignFolder + "/LX.txt"
	
	if FileExists(FileA) AND FileExists(FileB) then
		name(FileA,FileX)
		name(FileB,FileA)
		name(FileX,FileB)
		
		PlayerSlot(Player).LevelNum = LevelB
	end if
end sub

sub duplicate_level(LevID as short, DestCampaign as string = CampaignFolder)
	dim as string OldFile, NewFile
	OldFile = MasterDir + "/campaigns/" + CampaignFolder + "/L"+str(LevID)+".txt"
	
	for LID as short = 1 to 999
		NewFile = MasterDir + "/campaigns/" + DestCampaign + "/L"+str(LID)+".txt"
		if FileExists(NewFile) = 0 then
			if FileCopy(OldFile,NewFile) = 0 then
				if LevelUnsaved = 0 AND DestCampaign = CampaignFolder then
					PlayerSlot(Player).LevelNum = LID
				end if
			else
				Instructions = "Duplication failed"
				InstructExpire = timer + 10
			end if
			exit for
		end if
	next LID
end sub

sub level_options
	dim as ubyte OptionsPage = 0
	dim as short SwapTarget
	dim as string CopyToFolder
	do
		locate 48,1
		print space(127);
		locate 48,1
		print "Level options: ";
		if OptionsPage = 0 then
			color rgb(0,255,0)
			print "N";
			color rgb(255,255,255)
			print "ame / ";
			color rgb(0,255,0)
			print "H";
			color rgb(255,255,255)
			print "int / ";
			color rgb(0,255,0)
			print "P";
			color rgb(255,255,255)
			print "assword / ";
			color rgb(0,255,0)
			print "G";
			color rgb(255,255,255)
			print "ame variations / ";
			color rgb(0,255,0)
			print "T";
			color rgb(255,255,255)
			print "ime limit / Toggle ";
			color rgb(0,255,0)
			print "c";
			color rgb(255,255,255)
			print "ondensation / ";
			color rgb(0,255,0)
			print "B";
			color rgb(255,255,255)
			print "oss health / ";
		else
			print "S";
			color rgb(0,255,0)
			print "w";
			color rgb(255,255,255)
			print "ap with another level / D";
			color rgb(0,255,0)
			print "u";
			color rgb(255,255,255)
			print "plicate level / ";
			color rgb(0,255,0)
			print "D";
			color rgb(255,255,255)
			print "elete level / Cop";
			color rgb(0,255,0)
			print "y";
			color rgb(255,255,255)
			print " to another campaign / ";
		end if
		color rgb(0,255,0)
		print "M";
		color rgb(255,255,255)
		print "ore options";
		screencopy
		sleep 20
		InType = lcase(inkey)
		
		select case InType
			case "n"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				line input ; "Enter new level name: ",CampaignLevelName
				screenset 1,0
				
				LevelUnsaved = 1
				exit do
			case "h"
				screenset 0,0
				locate 48,1
				print space(127);
				locate 48,1
				line input ; "Enter new level hint: ",LevelDescription
				screenset 1,0
				
				LevelUnsaved = 1
				exit do
				
			case "p"
				edit_level_password
				exit do
				
			case "g"
				edit_level_variations
				exit do
				
			case "t"
				edit_time_limit
				exit do
				
			case "b"
				edit_boss_health
				exit do
				
			case "c"
				CondensedLevel = 1 - CondensedLevel
				LevelUnsaved = 1
				exit do
				
			case "m"
				OptionsPage = 1 - OptionsPage
				
			case "d"
				if FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/L2.txt") then
					locate 48,1
					print space(127);
					locate 48,1
					color rgb(255,255,0)
					print "Warning! ";
					color rgb(255,255,255)
					print "This will permanently delete your level! Are you sure you wish to proceed? (Y/N)";
					screencopy
					do
						InType = lcase(inkey)
						if InType = "y" then
							delete_level(PlayerSlot(Player).LevelNum)
							exit do
						end if
					loop until InType = "n"
				else
					locate 48,1
					print space(127);
					locate 48,1
					print "You may not delete the last level of a campaign.";
					screencopy
					sleep
				end if
				exit do
				
			case "w"
				if FileExists(MasterDir + "/campaigns/" + CampaignFolder + "/L2.txt") then
					screenset 0,0
					locate 48,1
					print space(127);
					locate 48,1
					input ; "Enter level number to swap with: ",SwapTarget
					screenset 1,0
					if SwapTarget > 0 then
						swap_levels(PlayerSlot(Player).LevelNum,SwapTarget)
					end if
				else
					locate 48,1
					print space(127);
					locate 48,1
					print "You need at least two levels to swap.";
					screencopy
					sleep
				end if
				exit do
				
			case "u"
				if LevelUnsaved then
					locate 48,1
					print space(127);
					locate 48,1
					print "Level changes unsaved. This will duplicate the original level. Proceed anyway? (Y/N)";
					screencopy
					do
						InType = lcase(inkey)
						if InType = "y" then
							duplicate_level(PlayerSlot(Player).LevelNum)
							exit do
						end if
					loop until InType = "n"
				else
					duplicate_level(PlayerSlot(Player).LevelNum)
				end if
				exit do
				
			case "y"
				if LevelUnsaved then
					locate 48,1
					print space(127);
					locate 48,1
					print "Level changes unsaved. This will copy the original level. Proceed anyway? (Y/N)";
					screencopy
					do
						InType = lcase(inkey)
						if InType = "y" then
							screenset 0,0
							locate 48,1
							print space(127);
							locate 48,1
							line input ; "Enter campaign folder to copy to: ",CopyToFolder
							screenset 1,0
							if CopyToFolder <> "" then
								CopyToFolder = "community/"+CopyToFolder
								duplicate_level(PlayerSlot(Player).LevelNum,CopyToFolder)
							end if
							exit do
						end if
					loop until InType = "n"
				else
					screenset 0,0
					locate 48,1
					print space(127);
					locate 48,1
					line input ; "Enter campaign folder to copy to: ",CopyToFolder
					screenset 1,0
					if CopyToFolder <> "" then
						CopyToFolder = "community/"+CopyToFolder
						duplicate_level(PlayerSlot(Player).LevelNum,CopyToFolder)
					end if
				end if
				exit do
				
		end select
	loop until InType = EscapeKey
end sub

sub delete_brush(DelID as integer)
	for DID as ubyte = DelID to 34
		Pallete(DID) = Pallete(DID+1)
		
		with Pallete(DID)
			if .HitDegrade > DelID then
				.HitDegrade -= 1
			end if

			if .CanRegen > DelID then
				.CanRegen -= 1
			end if
		end with
	next DID
	
	Pallete(35).PColoring = 0
	
	for YID as ubyte = 1 to 24
		for XID as ubyte = 1 to 40
			with PlayerSlot(Player).TileSet(XID,YID)
				if .BrickID = DelID then
					.BrickID = 0
					.Flash = BaseFlash
				elseif .BrickID > DelID then
					.BrickID -= 1
				end if
			end with
		next XID
	next YID
	
	BlockBrushes -= 1
	SelectedBrush = 0 
end sub

sub brush_editor_submenu
	dim as integer NewRed, NewGreen, NewBlue, NewAlpha
	dim as longint NewClrInteger
	dim as string NewTxtValue
	
	do
		locate 48,1
		with Pallete(BrushEditor)
			print "Brush "+str(BrushEditor)+" options: ";
			color rgb(0,255,0)
			print "C";
			color rgb(255,255,255)
			print "olor / ";
			color rgb(0,255,0)
			print "S";
			color rgb(255,255,255)
			print "coring ("+str(.ScoreValue)+") / Connec";
			color rgb(0,255,0)
			print "t";
			color rgb(255,255,255)
			print " (--> "+str(.HitDegrade)+") / ";
			color rgb(0,255,0)
			print "B";
			color rgb(255,255,255)
			print "ioregen ("+str(.CanRegen)+") / Speed ";
			color rgb(0,255,0)
			print "i";
			color rgb(255,255,255)
			print "ncrease ("+str(.IncreaseSpeed)+") / D";
			color rgb(0,255,0)
			print "u";
			color rgb(255,255,255)
			print "plicate / ";
			color rgb(0,255,0)
			print "D";
			color rgb(255,255,255)
			print "elete";
			screencopy
			sleep 20
			InType = lcase(inkey)
			
			select case InType
				case "c"
					NewRed = retrivePrimary(.PColoring,RGBA_RED)
					NewGreen = retrivePrimary(.PColoring,RGBA_GREEN)
					NewBlue = retrivePrimary(.PColoring,RGBA_BLUE)
					NewAlpha = retrivePrimary(.PColoring,RGBA_ALPHA)
					
					do
						NewClrInteger = rgba(NewRed,NewGreen,NewBlue,NewAlpha)
						
						locate 48,1
						print space(127);
						locate 48,1
						print "Current color: ";
						color rgb(0,255,0)
						print "rgba";
						color rgb(255,255,255)
						print "("& NewRed;","& NewGreen;","& NewBlue;","& NewAlpha;") a.k.a. &";
						color rgb(0,255,0)
						print "h";
						color rgb(255,255,255)
						print hex(NewClrInteger,8);" ";
						color NewClrInteger
						print "[]";
						color rgb(255,255,255)
						screencopy
						sleep 20
						InType = lcase(inkey)
						select case InType
							case "r"
								screenset 0,0
								locate 48,1
								print space(127);
								locate 48,1
								input ; "Enter new red value: ",NewRed
								screenset 1,0
							case "g"
								screenset 0,0
								locate 48,1
								print space(127);
								locate 48,1
								input ; "Enter new green value: ",NewGreen
								screenset 1,0
							case "b"
								screenset 0,0
								locate 48,1
								print space(127);
								locate 48,1
								input ; "Enter new blue value: ",NewBlue
								screenset 1,0
							case "a"
								screenset 0,0
								locate 48,1
								print space(127);
								locate 48,1
								input ; "Enter new alpha value: ",NewAlpha
								screenset 1,0
							case "h"
								screenset 0,0
								locate 48,1
								print space(127);
								locate 48,1
								print "Enter new color hexadecimal (";
								color rgb(128,255,0)
								print "&hAARRGGBB";
								color rgb(255,255,255)
								input ; "): ",NewClrInteger
								screenset 1,0
								
								NewRed = retrivePrimary(NewClrInteger,RGBA_RED)
								NewGreen = retrivePrimary(NewClrInteger,RGBA_GREEN)
								NewBlue = retrivePrimary(NewClrInteger,RGBA_BLUE)
								NewAlpha = retrivePrimary(NewClrInteger,RGBA_ALPHA)
						end select
					loop until InType = EnterKey OR InType = EscapeKey
					.PColoring = NewClrInteger
					LevelUnsaved = 1
					exit do
				case "s"
					screenset 0,0
					locate 48,1
					print space(127);
					locate 48,1
					input ; "Enter new score value: ",NewTxtValue
					screenset 1,0
					
					.ScoreValue = valint(NewTxtValue)
					.DynamicValue = abs(sgn(right(NewTxtValue,1) = "*"))
					LevelUnsaved = 1
					exit do
				case "t"
					screenset 0,0
					locate 48,1
					print space(127);
					locate 48,1
					input ; "Connect this brush to which ID";NewRed
					screenset 1,0
					
					if NewRed < -1 then
						NewRed = -1
					elseif NewRed > 35 then
						NewRed = 35
					end if
					.HitDegrade = NewRed
					LevelUnsaved = 1
					exit do
				case "b"
					if .CanRegen = 0 then
						.CanRegen = 1
					else
						.CanRegen = 0
					end if 
					LevelUnsaved = 1
					exit do
					
				case "i"
					.IncreaseSpeed = 1 - .IncreaseSpeed 
					LevelUnsaved = 1
					exit do

				case "u"
					if BlockBrushes < 35 then
						BlockBrushes += 1
						Pallete(BlockBrushes) = Pallete(BrushEditor) 
						LevelUnsaved = 1
					end if
					exit do
					
				case "d"
					delete_brush(BrushEditor)
					LevelUnsaved = 1
					exit do
					
			end select
		end with
	loop until InType = EscapeKey
	apply_block_properties
	BrushEditor = 0
end sub

sub draw_brushes(BrushID as byte)
	dim as ubyte BrushX = BrushID
	dim as single BrushY = 25.5
	dim as string PrintChar
	
	with Pallete(BrushID)
		if BrushID > BlockBrushes then
			PrintChar = "+"
		elseif BrushID < 10 then
			PrintChar = str(BrushID)
		else
			PrintChar = chr(55+BrushID)
		end if
		
		if .PColoring = 0 then
			if CondensedLevel then
				line(32+(BrushX-1)*24,96+(BrushY-1)*24)-_
					(31+(BrushX)*24,95+(BrushY)*24),rgb(255,255,255),b,&b1010101010101010
				
				if SelectedBrush = BrushID then
					printgfx(PrintChar,41+(BrushX-1)*24,103+(BrushY-1)*24,2,rgb(255,255,0))
				else
					printgfx(PrintChar,41+(BrushX-1)*24,103+(BrushY-1)*24,2,rgb(255,255,255))
				end if
			else
				if BrushX > 20 then
					BrushX -= 20
					BrushY += 1
				endif
				
				line(32+(BrushX-1)*48,96+(BrushY-1)*24)-_
					(31+(BrushX)*48,95+(BrushY)*24),rgb(255,255,255),b,&b1010101010101010

				if SelectedBrush = BrushID then
					printgfx(PrintChar,53+(BrushX-1)*48,103+(BrushY-1)*24,2,rgb(255,255,0))
				else
					printgfx(PrintChar,53+(BrushX-1)*48,103+(BrushY-1)*24,2,rgb(255,255,255))
				end if
			end if
		elseif CondensedLevel then
			if BrushID = .HitDegrade OR .CalcedInvulnerable >= 2 then
				put(32+(BrushX-1)*24,96+(BrushY-1)*24),InvincibleMini,pset
			elseif .CalcedInvulnerable > 0 then
				put(32+(BrushX-1)*24,96+(BrushY-1)*24),InvincibleMini,pset
			elseif .HitDegrade < 0 then
				put(32+(BrushX-1)*24,96+(BrushY-1)*24),ExplodePic,trans
				XplodeCount += 1
			elseif .HitDegrade > 0 OR .CanRegen > 0 then
				put(32+(BrushX-1)*24,96+(BrushY-1)*24),MultihitPicMini,pset
			else 
				put(32+(BrushX-1)*24,96+(BrushY-1)*24),SoftBrickPicMini,pset
			end if
			line(32+(BrushX-1)*24,96+(BrushY-1)*24)-_
				(31+(BrushX)*24,95+(BrushY)*24),.PColoring,bf
				
			if retrivePrimary(.PColoring,RGBA_ALPHA) >= 224 then
				for OffsetY as byte = 0 to 2 step 2
					for OffsetX as byte = 0 to 2 step 2
						printgfx(PrintChar,40+(BrushX-1)*24+OffsetX,102+(BrushY-1)*24+OffsetY,2,rgb(0,0,0))
					next OffsetX
				next OffsetY
				
				if SelectedBrush = BrushID then
					printgfx(PrintChar,41+(BrushX-1)*24,103+(BrushY-1)*24,2,rgb(255,255,0))
				else
					printgfx(PrintChar,41+(BrushX-1)*24,103+(BrushY-1)*24,2,rgb(255,255,255))
				end if
			end if
				
			if SelectedBrush = BrushID then
				line(33+(BrushX-1)*24,97+(BrushY-1)*24)-_
					(30+(BrushX)*24,94+(BrushY)*24),rgb(255,255,255),b,&b1110011001100111
			end if
		else
			if BrushX > 20 then
				BrushX -= 20
				BrushY += 1
			endif
			
			if BrushID = .HitDegrade OR .CalcedInvulnerable >= 2 then
				put(32+(BrushX-1)*48,96+(BrushY-1)*24),InvinciblePic,pset
			elseif .CalcedInvulnerable > 0 then
				put(32+(BrushX-1)*48,96+(BrushY-1)*24),InvinciblePic,pset
			elseif .HitDegrade < 0 then
				put(32+(BrushX-1)*48,96+(BrushY-1)*24),ExplodePic,trans
				XplodeCount += 1
			elseif .HitDegrade > 0 OR .CanRegen > 0 then
				put(32+(BrushX-1)*48,96+(BrushY-1)*24),MultihitPic,pset
			else 
				put(32+(BrushX-1)*48,96+(BrushY-1)*24),SoftBrickPic,pset
			end if
			line(32+(BrushX-1)*48,96+(BrushY-1)*24)-_
				(31+(BrushX)*48,95+(BrushY)*24),.PColoring,bf
				
			if retrivePrimary(.PColoring,RGBA_ALPHA) >= 224 then
				for OffsetY as byte = 0 to 2 step 2
					for OffsetX as byte = 0 to 2 step 2
						printgfx(PrintChar,52+(BrushX-1)*48+OffsetX,102+(BrushY-1)*24+OffsetY,2,rgb(0,0,0))
					next OffsetX
				next OffsetY
				
				if SelectedBrush = BrushID then
					printgfx(PrintChar,53+(BrushX-1)*48,103+(BrushY-1)*24,2,rgb(255,255,0))
				else
					printgfx(PrintChar,53+(BrushX-1)*48,103+(BrushY-1)*24,2,rgb(255,255,255))
				end if
			end if

			if SelectedBrush = BrushID then
				line(33+(BrushX-1)*48,97+(BrushY-1)*24)-_
					(30+(BrushX)*48,94+(BrushY)*24),rgb(255,255,255),b,&b1110011001100111
			end if
		end if
		
		if MouseY >= 96+(BrushY-1)*24 AND MouseY < 96+BrushY*24 AND ButtonCombo > 0 then
			if CondensedLevel then
				if MouseX >= 32+(BrushX-1)*24 AND MouseX < 32+BrushX*24 then
					SelectedBrush = BrushID
				end if
			else
				if MouseX >= 32+(BrushX-1)*48 AND MouseX < 32+BrushX*48 then
					SelectedBrush = BrushID
				end if
			end if
			
			if ButtonCombo = 1 then
				if SelectedBrush > BlockBrushes then
					BlockBrushes += 1
					
					with Pallete(SelectedBrush)
						if rnd < 0.1 then
							.PColoring = rgba(ceil(irandom(0,4)*63.25),ceil(irandom(0,4)*63.25),ceil(irandom(0,4)*63.25),128)
						else
							.PColoring = rgba(irandom(0,255),irandom(0,255),irandom(0,255),128)
						end if
						.ScoreValue = 10
						.DynamicValue = 1
						.HitDegrade = 0
						.CanRegen = 0
						.IncreaseSpeed = 0
					end with
					LevelUnsaved = 1
				end if
			elseif ButtonCombo = 2 AND SelectedBrush <= BlockBrushes then
				BrushEditor = SelectedBrush
			end if
		end if
	end with
end sub

sub mirror_options
	dim as ubyte MirrorID
	do
		locate 48,1
		print space(127);
		locate 48,1
		print "Mirror selector (&b"& bin(MirrorEditing,4);"): ";MirrorOptions(MirrorID);" ";
		if (MirrorEditing AND (1 SHL MirrorID)) then
			color rgb(0,255,0)
			print "(active)";
			color rgb(255,255,255)
		else
			print "(inactive)";
		end if
		screencopy
		sleep 20
		InType = inkey
		for NID as ubyte = 1 to 4
			if InType = str(NID) then
				if (MirrorEditing AND (1 SHL (NID-1))) then
					MirrorEditing -= 2^(NID-1)
				else
					MirrorEditing += 2^(NID-1)
				end if
			end if
		next NID
		
		select case InType
			case LeftArrow
				if MirrorID > 0 then
					MirrorID -= 1
				end if
			case RightArrow
				if MirrorID < 3 then
					MirrorID += 1
				end if
			case EnterKey, space(1)
				if (MirrorEditing AND (1 SHL MirrorID)) then
					MirrorEditing -= 2^MirrorID
				else
					MirrorEditing += 2^MirrorID
				end if
				
		end select
	loop until InType = EscapeKey
end sub

sub draw_bricks(PaintX as byte, PaintY as byte)
	dim as byte SupportX, SupportY, SupportZ
	
	if PaintX > 0 AND PaintY > 0 AND PaintX <= 20*(1+CondensedLevel) AND PaintY <= 24 then
		with PlayerSlot(Player).TileSet(PaintX,PaintY)
			.Flash = max(.Flash,32)
			
			if SelectedBrush > 0 AND ButtonCombo = 1 then
				.BrickID = SelectedBrush
				.Flash = BaseFlash
				LevelUnsaved = 1
			elseif ButtonCombo = 2 then
				.BrickID = 0
				.Flash = BaseFlash
				LevelUnsaved = 1
			end if
		end with
		
		'Mirror brush horizontally
		if (MirrorEditing AND (1 SHL 0)) then
			SupportX = 1+20*(1+CondensedLevel)-PaintX 
			SupportY = PaintY
			
			with PlayerSlot(Player).TileSet(SupportX,SupportY)
				.Flash = max(.Flash,32)
				
				if SelectedBrush > 0 AND ButtonCombo = 1 then
					.BrickID = SelectedBrush
					.Flash = BaseFlash
					LevelUnsaved = 1
				elseif ButtonCombo = 2 then
					.BrickID = 0
					.Flash = BaseFlash
					LevelUnsaved = 1
				end if
			end with
		end if
		
		'Mirror brush verticaly
		if (MirrorEditing AND (1 SHL 1)) AND PaintY <= 20 then
			SupportX = PaintX 
			SupportY = 21-PaintY
			
			with PlayerSlot(Player).TileSet(SupportX,SupportY)
				.Flash = max(.Flash,32)
				
				if SelectedBrush > 0 AND ButtonCombo = 1 then
					.BrickID = SelectedBrush
					.Flash = BaseFlash
					LevelUnsaved = 1
				elseif ButtonCombo = 2 then
					.BrickID = 0
					.Flash = BaseFlash
					LevelUnsaved = 1
				end if
			end with
		end if
		
		'Mirror brush from opposite corner
		if (MirrorEditing AND (1 SHL 2)) AND PaintY <= 20 then
			SupportX = 1+20*(1+CondensedLevel)-PaintX 
			SupportY = 21-PaintY
			
			with PlayerSlot(Player).TileSet(SupportX,SupportY)
				.Flash = max(.Flash,32)
				
				if SelectedBrush > 0 AND ButtonCombo = 1 then
					.BrickID = SelectedBrush
					.Flash = BaseFlash
					LevelUnsaved = 1
				elseif ButtonCombo = 2 then
					.BrickID = 0
					.Flash = BaseFlash
					LevelUnsaved = 1
				end if
			end with
		end if
		
		'Mirror brush diagonally
		if (MirrorEditing AND (1 SHL 3)) AND PaintY <= 20 then
			if PaintX > 20 then
				SupportX = 41 - PaintY
				SupportY = 41 - PaintX
			else
				SupportX = PaintY
				SupportY = PaintX
			end if
						
			with PlayerSlot(Player).TileSet(SupportX,SupportY)
				.Flash = max(.Flash,32)
				
				if SelectedBrush > 0 AND ButtonCombo = 1 then
					.BrickID = SelectedBrush
					.Flash = BaseFlash
					LevelUnsaved = 1
				elseif ButtonCombo = 2 then
					.BrickID = 0
					.Flash = BaseFlash
					LevelUnsaved = 1
				end if
			end with

			'Apply previous mirrors to this brush
			if (MirrorEditing AND (1 SHL 0)) then
				SupportX = 1+20*(1+CondensedLevel)-SupportX 
				
				with PlayerSlot(Player).TileSet(SupportX,SupportY)
					.Flash = max(.Flash,32)
					
					if SelectedBrush > 0 AND ButtonCombo = 1 then
						.BrickID = SelectedBrush
						.Flash = BaseFlash
						LevelUnsaved = 1
					elseif ButtonCombo = 2 then
						.BrickID = 0
						.Flash = BaseFlash
						LevelUnsaved = 1
					end if
				end with

				SupportX = 1+20*(1+CondensedLevel)-SupportX 
			end if

			if (MirrorEditing AND (1 SHL 1)) then
				SupportY = 21-SupportY
				
				with PlayerSlot(Player).TileSet(SupportX,SupportY)
					.Flash = max(.Flash,32)
					
					if SelectedBrush > 0 AND ButtonCombo = 1 then
						.BrickID = SelectedBrush
						.Flash = BaseFlash
						LevelUnsaved = 1
					elseif ButtonCombo = 2 then
						.BrickID = 0
						.Flash = BaseFlash
						LevelUnsaved = 1
					end if
				end with

				SupportY = 21-SupportY
			end if

			if (MirrorEditing AND (1 SHL 2)) then
				SupportX = 1+20*(1+CondensedLevel)-SupportX 
				SupportY = 21-SupportY
				
				with PlayerSlot(Player).TileSet(SupportX,SupportY)
					.Flash = max(.Flash,32)
					
					if SelectedBrush > 0 AND ButtonCombo = 1 then
						.BrickID = SelectedBrush
						.Flash = BaseFlash
						LevelUnsaved = 1
					elseif ButtonCombo = 2 then
						.BrickID = 0
						.Flash = BaseFlash
						LevelUnsaved = 1
					end if
				end with
			end if
		end if
		
		HighlightX = PaintX
		HighlightY = PaintY
	else
		HighlightX = 0
		HighlightY = 0
	end if
end sub

sub shift_field(ShiftX as byte, ShiftY as byte)
	dim as byte MaxCols = 20*(CondensedLevel+1)
	dim as byte MaxRows = 20
	if (Gamestyle AND (1 SHL STYLE_PROGRESSIVE)) then
		MaxRows = 24
	end if
	
	if ShiftX = -1 then
		for YID as byte = 1 to 24
			for XID as byte = 0 to MaxCols-1
				PlayerSlot(Player).TileSet(XID,YID) = PlayerSlot(Player).TileSet(XID+1,YID)
			next XID
			PlayerSlot(Player).TileSet(MaxCols,YID) = PlayerSlot(Player).TileSet(0,YID)
		next YID
	elseif ShiftX = 1 then
		for YID as byte = 1 to 24
			PlayerSlot(Player).TileSet(0,YID) = PlayerSlot(Player).TileSet(MaxCols,YID)
			for XID as byte = MaxCols to 1 step -1
				PlayerSlot(Player).TileSet(XID,YID) = PlayerSlot(Player).TileSet(int(XID-1),YID)
			next XID
		next YID
	end if
	
	if ShiftY = -1 then
		for XID as byte = 1 to MaxCols
			for YID as byte = 0 to MaxRows-1
				PlayerSlot(Player).TileSet(XID,YID) = PlayerSlot(Player).TileSet(XID,YID+1)
			next YID
			PlayerSlot(Player).TileSet(XID,MaxRows) = PlayerSlot(Player).TileSet(XID,0)
		next XID
	elseif ShiftY = 1 then
		for XID as byte = 1 to MaxCols
			PlayerSlot(Player).TileSet(XID,0) = PlayerSlot(Player).TileSet(XID,MaxRows)
			for YID as byte = MaxRows to 1 step -1
				PlayerSlot(Player).TileSet(XID,YID) = PlayerSlot(Player).TileSet(XID,int(YID-1))
			next YID
		next XID
	end if
	
	LevelUnsaved = 1
end sub

sub save_level(SaveLvNum as short)
	dim as string SaveFile, PrintBlockChar, SpeedIncrease
	dim as short SaveRows = 20
	
	SaveFile = MasterDir+"/campaigns/" + CampaignFolder + "/L"+str(SaveLvNum)+".txt"
	open SaveFile for output as #2
	print #2, string(80,"=")
	print #2, "LEVEL DATA FILE - "+ucase(CampaignName)+" LEVEL "+str(SaveLvNum)
	print #2, string(80,"=")
	print #2, "*BEGIN*"
	print #2, string(80,"=")
	print #2,
	
	print #2, "Level Name            := "+CampaignLevelName
	print #2, "Level Description     := "+LevelDescription
	print #2, "Level Password        := "+CampaignPassword
	print #2, "Level game number     := "+str(Gamestyle)
	print #2, "Level time limit      := "+str(LevelTimeLimit)
	if (Gamestyle AND (1 SHL STYLE_BOSS)) XOR (Gamestyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
		print #2, "Level boss health     := "+str(PlayerSlot(Player).BossMaxHealth)
	end if
	print #2, "Number of Brushes     := "+str(BlockBrushes)
	
	if (Gamestyle AND (1 SHL STYLE_PROGRESSIVE)) then
		SaveRows = 24
	end if
	
	for BID as ubyte = 1 to BlockBrushes
		with Pallete(BID)
			if .IncreaseSpeed then
				SpeedIncrease = "TRUE"
			else
				SpeedIncrease = "FALSE"
			end if
			print #2, "Brush "+str(BID)+" Color"+space(10-len(str(BID)))+":= &h"+hex(.PColoring,8)
			print #2, "Brush "+str(BID)+" Score Value"+space(4-len(str(BID)))+":= "+str(.ScoreValue);
			if .DynamicValue then
				print #2, "*"
			else
				print #2,
			end if
			print #2, "Brush "+str(BID)+" Hit Degrade"+space(4-len(str(BID)))+":= "+str(.HitDegrade);
			if .CanRegen then
				print #2, "*"
			else
				print #2,
			end if
			print #2, "Brush "+str(BID)+" Increase Spd"+space(3-len(str(BID)))+":= "+SpeedIncrease
		end with
	next BID
	print #2,

	if CondensedLevel then
		print #2, "Level Grid  1111111111222222222233333333334"
		print #2, "   1234567890123456789012345678901234567890"
		print #2, string(43,"-")
		for YID as ubyte = 1 to SaveRows
			print #2, space(2-len(str(YID)))+str(YID)+"|";
			for XID as ubyte = 1 to 40
				with PlayerSlot(Player).TileSet(XID,YID)
					if .BrickID = 0 then
						PrintBlockChar = " "
					elseif .BrickID < 10 then
						PrintBlockChar = str(.BrickID)
					else
						PrintBlockChar = chr(55+.BrickID)
					end if
				end with
				print #2, PrintBlockChar;
			next XID
			print #2,
		next YID
	else
		print #2, "Level Grid  11111111112"
		print #2, "   12345678901234567890"
		print #2, string(23,"-")
		for YID as ubyte = 1 to SaveRows
			print #2, space(2-len(str(YID)))+str(YID)+"|";
			for XID as ubyte = 1 to 20
				with PlayerSlot(Player).TileSet(XID,YID)
					if .BrickID = 0 then
						PrintBlockChar = " "
					elseif .BrickID < 10 then
						PrintBlockChar = str(.BrickID)
					else
						PrintBlockChar = chr(55+.BrickID)
					end if
				end with
				print #2, PrintBlockChar;
			next XID
			print #2,
		next YID
	end if
	
	print #2,
	print #2, string(80,"=")
	print #2, "*END*"
	print #2, string(80,"=")
	close #2
	
	LevelUnsaved = 0
end sub

sub save_campaign(SaveLvNum as short)
	dim as string SaveFile
	mkdir(MasterDir+"/campaigns/community")
	mkdir(MasterDir+"/campaigns/" + CampaignFolder)
	SaveFile = MasterDir+"/campaigns/" + CampaignFolder + "/Settings.txt"
	open SaveFile for output as #3
	print #3, string(80,"=")
	print #3, "LEVEL DATA FILE - "+ucase(CampaignName)+" SETTINGS"
	print #3, string(80,"=")
	print #3, "*BEGIN*"
	print #3, string(80,"=")
	print #3,

	print #3, "Camapign Name         := "+CampaignName
	print #3, "Starting Lives        := "+str(StartingLives);
	if ExtraBarrierPoint then
		print #3, "*"
	else
		print #3,
	end if
	print #3, "Base capsule value    := "+str(BaseCapsuleValue)
	print #3, "Initial life bonus    := "+str(InitialExtraLife)
	print #3, "Life bonus every      := "+str(SubsequentExtraLives)
	print #3, "Exploding value       := "+str(ExplodingValue)
	print #3, "Secrets start at      := "+str(SecretLevels)
	print #3,

	print #3, string(80,"=")
	print #3, "*END*"
	print #3, string(80,"=")
	close #3

	save_level(SaveLvNum)
	CampaignUnsaved = 0
	Instructions = "Save successful"
	InstructExpire = timer + 5
end sub

sub reset_editor_specs
	MirrorEditing = 0
	SelectedBrush = 0
	if LevelDescription = "" then
		InstructExpire = 0
	else
		Instructions = LevelDescription
	end if
end sub

