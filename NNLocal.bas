#include "NNLocal.bi"
sub localGameplay
	dim as string InMusic, InPassword
	dim as short LevelClear, PassInput, InstruAlpha, InstruBeta, InstruGamma, Phase, AboveLine, HeadingUpwards, RotationFrame, _
		ProhibitSpawn, WepCooldown, DebugConsole, FreezeStr, ScoreTick, MinPlayHeight, ShowTopUI, RecalcGems
	dim as integer LoadErrors, BarrierStrength, MPAlternate, ScoreFilling, GracePeriod, ModdedHiScore
	dim as double LastPlayed, DispTime, MusicPitch
	dim as string ScoreRef, DiffName, GameInfo, TimeStr, DebugCode
	GamePaused = 0
	SpeedMod = 100
	InstruAlpha = 4
	
	Player = 1
	applyDiffSpecs
	
	DesireX = 512
	PaddleHealth = 6600
	ShowTopUI = 60

	ShuffleList(1) = 1
	fixFirstLevel
	if QuickPlayFile = "" then
		LoadErrors = load_settings
	else
		CampaignName = PlaytestName
		
		StartingLives = 9
		ExtraBarrierPoint = 1
		
		BaseCapsuleValue = 100
		InitialExtraLife = 0
		SubsequentExtraLives = 0
		ExplodingValue = 8
		SecretLevels = 2
	end if
	with NewPlrSlot
		.DispScore = 0
		.Score = 0
		.Lives = 0
		.LevelNum = 1
		.PerfectClear = 1
		if InitialExtraLife = 0 then
			.Threshold = SubsequentExtraLives
		else
			.Threshold = InitialExtraLife
		end if
		emptyHand(0)
	end with
	beginLocalGame(-1, 1)
	
	if LoadErrors then
		exit sub
	else
		loadScores
	end if
	
	if FileExists(CampaignName+".dat") then
		open CampaignName+".dat" for input as #2
		input #2, HighLevel
		close #2
	else
		HighLevel = 1
	end if

	for LsrID as ubyte = 1 to 20
		for LsrPt as ubyte = 1 to 15
			with LaserBeams(LsrID,LsrPt)
				.Y = 768
			end with
		next LsrPt
	next LsrID

	NewPlrSlot.Lives = StartingLives + (ExtraBarrierPoint * CampaignBarrier)
	InPassword = "--------"
	SavedControls = ControlStyle
	do
		PlayerSlot(0).Difficulty = max(PlayerSlot(1).Difficulty,_
			max(PlayerSlot(2).Difficulty,_
			max(PlayerSlot(3).Difficulty,_
			max(PlayerSlot(4).Difficulty,_
			max(PlayerSlot(5).Difficulty,_
			PlayerSlot(6).Difficulty)))))
		
		if ControlStyle > CTRL_KEYBOARD then
			getJoystick(ControlStyle-4,JoyButtonCombo,JoyAxis(0),JoyAxis(1),JoyAxis(2),JoyAxis(3),JoyAxis(4),JoyAxis(5),JoyAxis(6),JoyAxis(7))
			if JoyInvertAxes then
				for AxisID as byte = 0 to 7
					JoyAxis(AxisID) = -JoyAxis(AxisID)
				next AxisID
			end if
		end if
		
		with PlayerSlot(Player)
			PowerTick += SpeedMod
			
			screenevent(@e)
			FrameTime += 1/FPS
			cls
			decrementPauses
			if CampaignBarrier AND .Lives > 0 then
				BarrierStrength = .Lives - 1
			else
				BarrierStrength = 0
			end if
			if GamePaused = 0 then
				if PowerTick >= 100 then
					RotationFrame += 1
				end if
			end if
		end with
		
		ExploTick += 1
		
		AttackBricks = 0
		if RotationFrame >= 20 then
			if (GameStyle AND (1 SHL STYLE_ROTATION)) then
				dim as TileSpecs TilesetX(40)
				for YID as ubyte = 1 to 24
					if isBrickMovable(PlayerSlot(Player).TileSet(1,YID)) then
						for DXID as byte = 20*(CondensedLevel+1) to 2 step -1
							if isBrickMovable(PlayerSlot(Player).TileSet(DXID,YID)) then
								TilesetX(1) = PlayerSlot(Player).TileSet(DXID,YID)
								exit for
							end if
						next DXID
					else
						TilesetX(1) = PlayerSlot(Player).TileSet(1,YID)
					end if

					for XID as ubyte = 2 to 20*(CondensedLevel+1)
						if isBrickMovable(PlayerSlot(Player).TileSet(XID,YID)) then
							for DXID as byte = XID - 1 to 1 step -1
								if isBrickMovable(PlayerSlot(Player).TileSet(DXID,YID)) then
									TilesetX(XID) = PlayerSlot(Player).TileSet(DXID,YID)
									exit for
								end if

								if DXID = 1 then
									DXID = 21+20*(CondensedLevel)
								end if
							next DXID
						else
							TilesetX(XID) = PlayerSlot(Player).TileSet(XID,YID)
						end if
					next XID

					for XID as ubyte = 1 to 20*(CondensedLevel+1)
						PlayerSlot(Player).TileSet(XID,YID) = TilesetX(XID)
					next XID
				next YID
			end if
			RotationFrame = 0
		end if
		
		if (GameStyle AND (1 SHL STYLE_EXTRA_HEIGHT)) then
			MinPlayHeight = 0
		else
			MinPlayHeight = 96
		end if
		
		if (GameStyle AND (1 SHL STYLE_BOSS)) then
			for YID as ubyte = 1 to 20
				for XID as byte = 20*(CondensedLevel+1) to 1 step -1
					with PlayerSlot(Player).TileSet(XID,YID)
						if .BrickID = 1 then
							AttackBricks += 1
						elseif .BrickID > 0 AND Pallete(.BrickID).CanRegen > 0 AND _
							.BrickID <> Pallete(.BrickID).CanRegen then
							dim as short ComputeDamage
							.BrickID = Pallete(.BrickID).CanRegen
							
							if .LastBall > 0 then
								ComputeDamage = Ball(.LastBall).Speed
								ComputeDamage *= max(int(5.45 - ActiveDifficulty),1) 
							else
								ComputeDamage = 10
							end if
							
							with PlayerSlot(Player)
								if .BossLastHit > 6 then
									.BossLastHealth = .BossHealth
								end if
								.BossLastHit = 0
								.BossHealth -= ComputeDamage
							end with
							
						end if
					end with
				next XID
			next YID
	
			if TotalBC > 0 AND AttackBricks > 0 AND PaddleSize > 0 AND GamePaused = 0 then
				AttackTick += PlayerSlot(Player).BossMaxHealth / 5000 * ActiveDifficulty * SpeedMod / 100
	
				if AttackTick >= 50 + PlayerSlot(Player).BossHealth/PlayerSlot(Player).BossMaxHealth * 50 then
					dim as ubyte NewBeam, NewX, NewY
					dim as ushort NewAngle = irandom(220,320), NewSpeed = irandom(4,10)
					AttackTick = 0
	
					for Try as ubyte = 1 to 5
						NewBeam = irandom(1,20)
						with LaserBeams(NewBeam,1)
							if .Speed = 0 then
								do
									NewX = irandom(1,20)
									NewY = irandom(1,20)
								loop until PlayerSlot(Player).TileSet(NewX,NewY).BrickID = 1
							end if
						end with
	
						if NewX > 0 AND NewY > 0 then
							for LsrPt as ubyte = 1 to 15
								with LaserBeams(NewBeam,LsrPt)
									.Angle = NewAngle
									.X = 56 + (NewX - 1) * 48 + cos(degtorad(NewAngle)) * LsrPt
									.Y = 108 + (NewY - 1) * 24 - sin(degtorad(NewAngle)) * LsrPt
									.Speed = NewSpeed / 1.3
								end with
							next LsrPt
							exit for
						end if
					next Try
				end if
			else
				AttackTick = 0
			end if
		end if
		while BulletStart >= MaxBullets
			BulletStart -= MaxBullets
		wend
		
		ScoreTick += 1
		for PID as ubyte = 1 to NumPlayers
			with PlayerSlot(PID)
				if .Score - .DispScore > 50 then
					.DispScore += int((.Score-.DispScore)/50)
				elseif .DispScore < .Score then
					.DispScore += 1
				end if
			end with
		next PID
		
		if TotalBC > 0 AND ProhibitSpawn = 0 then
			ProhibitSpawn = 2
			PlayerSlot(Player).Lives += 1
		end if

		with PlayerSlot(Player)
			if DQ = 0 AND ControlStyle >= CTRL_DESKTOP then
				if .LevelNum > HighLevel AND .Lives > 0 then
					HighLevel = .LevelNum
					'Clear victory flag; likely new levels discovered
					kill(CampaignName+".flag")
				end if
			end if
			
			put(0,0),Background,pset
			line(0,0)-(1023,767),rgba(0,0,0,255-(BGBrightness/100*255)),bf
			if (MinPlayHeight > 0) then
				ShowTopUI = 60
				put(0,0),FramesetMerged,trans
			else
				put(0,0),Sideframes,trans
				if ShowTopUI >= 60 then
					put(32,0),Topframe,trans
				end if
			end if
			
			'Score display
			if .Score < 1e6 then
				ScoreRef = commaSep(.Score)
			elseif .Score < 1e8 then
				ScoreRef = commaSep(int(.Score/1e3))+"K"
			elseif .Score < 1e11 then
				ScoreRef = commaSep(int(.Score/1e6))+"M"
			else
				ScoreRef = commaSep(int(.Score/1e9))+"B"
			end if
			uiElement(ScoreRef,45,6,7,rgba(255,255,255,224))
			
			/'
			 ' Target score display - Changes based on number of players:
			 ' - If playing alone: Displays score needed to beat the next score on the High Scores
			 ' - If playing hosteat: Displays the game leader's score
			 '/
			if ShowTopUI >= 60 then
				dim as byte TargetPos = 10
				dim as uinteger TargetColoring
				
				if NumPlayers = 1 then
					if CampaignName = PlaytestName then
						ModdedHiScore = 0
						TargetPos = -1
					else
						do
							ModdedHiScore = ceil(HighScore(TargetPos).RawScore * HighScore(TargetPos).Difficulty / .Difficulty)
							TargetPos -= 1
						loop until TargetPos = 0 OR .Score < ModdedHiScore
					end if
				else
					ModdedHiScore = 0
					for PID as byte = 1 to NumPlayers
						if PID <> Player AND PlayerSlot(PID).Score > ModdedHiScore then
							ModdedHiScore = PlayerSlot(PID).Score
						end if
					next PID
				end if
				
				if ModdedHiScore < 1e6 then
					ScoreRef = commaSep(ModdedHiScore)
				elseif ModdedHiScore < 1e8 then
					ScoreRef = commaSep(int(ModdedHiScore / 1e3))+"K"
				elseif ModdedHiScore < 1e11 then
					ScoreRef = commaSep(int(ModdedHiScore / 1e6))+"M"
				else
					ScoreRef = commaSep(int(ModdedHiScore / 1e9))+"B"
				end if
				
				TargetColoring = rgba(255,255,255,224)
				if TargetPos = -1 then
					TargetColoring = rgba(128,128,128,224)
				elseif TargetPos = 0 then
					if .Score < ModdedHiScore then
						TargetColoring = rgba(255,215,0,224)
					else
						TargetColoring = rgba(0,255,255,224)
						if .Score < 1e6 then
							ScoreRef = commaSep(.Score)
						elseif .Score < 1e8 then
							ScoreRef = commaSep(int(.Score / 1e3))+"K"
						elseif .Score < 1e11 then
							ScoreRef = commaSep(int(.Score / 1e6))+"M"
						else
							ScoreRef = commaSep(int(.Score / 1e9))+"B"
						end if
					end if
				elseif TargetPos = 1 then
					TargetColoring = rgba(192,192,192,224)
				elseif TargetPos = 2 then
					TargetColoring = rgba(205,127,50,224)
				end if
				uiElement(ScoreRef,192,6,7,TargetColoring)
			end if
		
			'Timer display
			if .Lives > 0 AND BrickCount <= 3 AND LevelTimeLimit = 0 then
				if GamePaused = 0 AND LevelClear = 0 AND PowerTick >= 100 then
					.WarpTimer -= 1
				end if
				TimeRem = .WarpTimer / 60
				DispTime = int(TimeRem+1-(1e-10))
				TimeStr = str(int(DispTime/60))+":"+_
					str(int(remainder(DispTime,60)/10))+_
					str(int(remainder(DispTime,10)))
				uiElement(str(TimeStr),560,6,5,rgba(255,255,0,224))
	
				if .WarpTimer = 0 AND LevelClear = 0 then
					playClip(SFX_EXPLODE)
					LevelClear = 1
				elseif .WarpTimer > 1800 AND TotalBC = 0 then
					.WarpTimer = 1800
				end if
			
			elseif .Lives > 0 AND LevelTimeLimit > 0 then
				dim as uinteger DColor
				if TimeRem < 60 then
					if (GameStyle AND (1 SHL STYLE_FATAL_TIMER)) then
						DColor = rgb(255,32,32)
					else
						DColor = rgb(255,128,0)
					end if
				elseif TimeRem < 120 then
					DColor = rgb(255,255,0)
				else
					DColor = rgb(0,255,255)
				end if
				
				if GamePaused = 0 AND LevelClear = 0 AND PowerTick >= 100 then
					.LevelTimer -= 1
				end if
				TimeRem = .LevelTimer/60
				
				if TimeRem < 0 AND LevelClear = 0 then
					if (GameStyle AND (1 SHL STYLE_BONUS)) then
						playClip(SFX_EXPLODE)
						LevelClear = 1
					elseif (GameStyle AND (1 SHL STYLE_FATAL_TIMER)) = 0 AND .Lives > 1 then
						playClip(SFX_DEATH)
						.PerfectClear = 0
						.Lives -= 1
						LevelClear = 1
					else
						.Lives = 1
						ProhibitSpawn = 2
						destroyBalls
					end if
				end if

				DispTime = int(TimeRem+1-(1e-10))
				TimeStr = str(int(DispTime/60))+":"+_
					str(int(remainder(DispTime,60)/10))+_
					str(int(remainder(DispTime,10)))
				uiElement(TimeStr,560,6,5,DColor)
			elseif .WarpTimer < 3600 then
				TimeRem = .WarpTimer / 60
				DispTime = int(TimeRem+1-(1e-10))
				TimeStr = str(int(DispTime/60))+":"+_
					str(int(remainder(DispTime,60)/10))+_
					str(int(remainder(DispTime,10)))
					
				uiElement(TimeStr,560,6,5,rgba(128,128,128,224))
			elseif ShowTopUI >= 60 then
				uiElement("-:--",560,6,5,rgba(128,128,128,224))
			end if

			if ShowTopUI >= 60 then
				'Player and Lives displays
				uiElement(str(Player),343,6,0,rgba(255,255,255,224))
				if .Lives > 0 then
					if CampaignBarrier then
						DispLives = BarrierStrength
					elseif (GameStyle AND (1 SHL STYLE_BONUS)) then
						DispLives = .Lives
					else
						DispLives = .Lives - sgn(ProhibitSpawn)
					end if
					uiElement(str(DispLives),386,6,0,rgba(255,255,255,224))
				else
					DispLives = 0
					uiElement("0",386,6,0,rgba(255,64,64,224))
				end if
				
				'Ammo display
				if .MissileAmmo > 0 then
					dim as uinteger Coloring
					if WepCooldown = 0 then
						Coloring = rgb(255,255,255)
					else
						Coloring = rgb(255,255,0)
					end if
					
					if .MissileAmmo < 1000 then
						uiElement(str(.MissileAmmo)+"M",671,6,4,Coloring)
					else
						uiElement("+++M",671,6,4,Coloring)
					end if
				elseif .BulletAmmo > 0 then
					if .BulletAmmo < 1000 then
						uiElement(str(.BulletAmmo)+"B",671,6,4,rgb(255,255,255))
					else
						uiElement("+++B",671,6,4,rgb(255,255,255))
					end if
				else
					uiElement("----",671,6,4,rgb(128,128,128))
				end if
		
				'Password display
				if CampaignFolder = EndlessFolder then
					'Intentionally blank
				elseif CampaignPassword = "--------" then
					uiElement("Fatal!",764,6,7,rgb(255,128,128))
				elseif CampaignPassword <> "++++++++" AND .LevelNum <= HighLevel AND ShuffleLevels = 0 then
					if .Difficulty >= 6.5 then
						uiElement(CampaignPassword,764,6,0,rgb(128,128,128))
					else
						uiElement(CampaignPassword,764,6,0,rgb(255,255,255))
					end if
				end if
	
				'Level display
				uiElement(str(.LevelNum),935,6,3,rgb(255,255,255))
				GameInfo = CampaignName + ": " + CampaignLevelName
				
				if (GameStyle AND (1 SHL STYLE_BOSS)) = 0 AND (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) = 0 then
					if BrickCount > CampaignBricks then
						line(53,36)-(987,64),rgb(128,0,64),bf
					elseif BrickCount > 0 then
						line(53,36)-(53+BrickCount/CampaignBricks*934,64),rgb(64,0,64),bf
					end if
				end if
				
			end if
			
			if (GameStyle AND (1 SHL STYLE_BOSS)) OR (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
				if .BossHealth <= 0 then
					.BossHealth = 0
					if .BossLastHit = 1 AND (GameStyle AND (1 SHL STYLE_BOSS)) then
						playClip(SFX_WALL_BROKEN)
						for YID as ubyte = 1 to 24
							for XID as ubyte = 1 to 20*(CondensedLevel+1)
								PlayerSlot(Player).TileSet(XID,YID).BrickID = 0
							next XID
						next YID
					end if
				end if
	
				if .BossLastHit < 64 then
					line(53,36)-(53+.BossLastHealth/.BossMaxHealth*934,64),_
						rgba(255,255,255,192-(.BossLastHit * 3)),bf
					.BossLastHit += 1
				end if
				if .BossHealth > 0 then
					line(53,36)-(53+.BossHealth/.BossMaxHealth*934,64),_
						rgb(255-.BossHealth/.BossMaxHealth*255,_
						.BossHealth/.BossMaxHealth*192,0),bf
				end if
				
				if ShowTopUI < 60 then
					line(53,36)-(987,64),rgb(255,255,255),b
				end if
			end if

			if ShowTopUI >= 60 then
				gfxstring(GameInfo,54,38,5,3,3,rgb(255,255,255))
			end if
	
		end with
		
		if ShowTopUI < 59 OR (HeadingUpwards = 0 AND ShowTopUI < 60) then
			ShowTopUI += 1
		end if
		BrickCount = dispWall(PowerTick*(1-GamePaused),1)
		
		if CampaignBarrier then
			dim as uinteger BarrierColors(1 to 9) => {_
				rgba(255,0,0,64),_
				rgba(255,128,0,96),_
				rgba(255,255,0,112),_
				rgba(0,255,0,128),_
				rgba(0,255,255,144),_
				rgba(0,0,255,160),_
				rgba(255,0,255,176),_
				rgba(255,128,255,192),_
				rgba(255,255,255,192)}

			if BarrierStrength > 0 then
				line(0,736)-(1023,767),BarrierColors(BarrierStrength),bf
			end if
		end if
		
		if PaddleHealth > 0 AND PaddleHealth < 110 * 60 then
			dim as uinteger HealthColor
			dim as short DmgMulti = int(sqr(ActiveDifficulty) + 0.5)
			
			if PaddleHealth < 15 * DmgMulti * 60 then
				HealthColor = rgb(192,0,0)
			elseif PaddleHealth < 30 * DmgMulti * 60 then
				HealthColor = rgb(192,192,0)
			else
				HealthColor = rgb(64,192,64)
			end if
			
			put (192,737),PaddleBar,pset
			line(197,742)-(197+min(int(PaddleHealth/60),100)/100*629,762),HealthColor,bf
			
			if PowerTick >= 100 AND ((LevelClear = 0 AND GamePaused = 0) OR PaddleHealth >= 6000) then
				if Paddle(1).Repairs > 0 AND PaddleHealth < 6000 then
					PaddleHealth += 4
				else
					PaddleHealth += 1
				end if
			end if
		end if

		if (GameStyle AND (1 SHL STYLE_BOSS)) AND GamePaused = 0 then
			for LsrID as ubyte = 1 to 20
				for LsrPt as ubyte = 1 to 15
					with LaserBeams(LsrID,LsrPt)
						if .Y >= 768 then
							.Speed = 0
						else
							pset(.X,.Y),rgb(255,128,0)
							.X += cos(degtorad(.Angle)) * .Speed * (SpeedMod / 100)
							.Y -= sin(degtorad(.Angle)) * .Speed * (SpeedMod / 100)

							for PaddleID as byte = 1 to 2
								if .X >= Paddle(PaddleID).X - PaddleSize/2 AND .X < Paddle(PaddleID).X + PaddleSize/2 AND _
									.Y >= Paddle(PaddleID).Y AND .Y < Paddle(PaddleID).Y + PaddleHeight then
									.Angle = 0
									.Y = 768
									
									if PaddleHealth > 100 * 60 then
										PaddleHealth = 100 * 60
									end if
									
									PaddleHealth -= int(sqr(ActiveDifficulty) + 0.5) * 60
									
									if PaddleHealth <= 0 then
										renderPaddle(0)
									end if
								end if
							next PaddleID
						end if
					end with
				next LsrPt
			next LsrID

			if PaddleSize < StandardSize AND ProhibitSpawn = 0 AND PlayerSlot(Player).Lives > 0 then
				ProhibitSpawn = 1
			end if
		end if

		particleSystem
		
		if TotalBC > 0 AND ProhibitSpawn > 0 then
			GracePeriod = 240
		end if
		
		if TotalBC = 0 AND ProhibitSpawn > 0 AND GracePeriod > 0 then
			if (GameStyle AND (1 SHL STYLE_CAVITY)) AND NumPlayers > 1 AND PlayerSlot(Player).Lives > 0 then
				Instructions = "Waiting a few seconds..."
				InstructExpire = timer + 1
				GracePeriod -= 1
			else
				GracePeriod = 0
			end if
		end if 

		with PlayerSlot(Player)
			if TotalBC = 0 AND ProhibitSpawn > 0 AND GracePeriod = 0 AND CapsFalling = 0 AND BulletsInPlay = 0 AND LevelClear = 0 then
				playClip(SFX_DEATH)
				ProhibitSpawn = 0
				Combo = 0
				resetPaddle
				.PerfectClear = 0
	
				if (GameStyle AND (1 SHL STYLE_BONUS)) then
					LevelClear = 1
				else
					.Lives -= 1
				end if
				
				if .Lives = 0 then
					gameOver
					LastPlayed = timer
					FrameTime = timer
				end if
	
				if (GameStyle AND (1 SHL STYLE_BONUS)) = 0 then
					transferControl
				end if
			end if
		end with
			
		if TotalBC = 1 AND ContinuousSplit = 1 then
			forceReleaseBalls
			for BID as short = 1 to NumBalls
				with Ball(BID)
					if .Speed > 0 then
						for NewBall as short = 1 to 100
							with Ball(NewBall)
								if .Speed <= 0 then
									.Speed = int(Ball(BID).Speed)
									.X = Ball(BID).X
									.Y = Ball(BID).Y
									.Spawned = 0
									.Power = Ball(BID).Power
									.Duration = Ball(BID).Duration
									.Angle = Ball(BID).Angle + 90
									TotalBC += 1
									exit for,for
								end if
							end with
						next
					end if
				end with
			next BID
		end if
		
		if MusicActive then
			MusicPitch = SpeedMod/100
			if PlayerSlot(Player).Lives <= 1 OR (PlayerSlot(Player).LevelTimer < 3600 AND (GameStyle AND (1 SHL STYLE_FATAL_TIMER))) then
				MusicPitch *= 1.2
			end if
			#IFDEF __USE_FBSOUND__
			fbs_Set_SoundSpeed(musicPlr,MusicPitch)
			#ENDIF
		end if
		
		with Paddle(1)
			.Grabbed = .X
			.Y = 736 - PaddleHeight
			if GamePaused = 0 then
				if ControlStyle = CTRL_AI then
					dim as Basics Deepest
					dim as short ObjsFound = 0
					Deepest.Y = 600.0
					Deepest.X = Paddle(1).X
					
					for BID as short = 1 to NumBalls
						with Ball(BID)
							if .Y > Deepest.Y AND .Y < 736 + BallSize AND sin(degtorad(.Angle)) < 0 then
								Deepest.Y = .Y
								Deepest.X = .X
								ObjsFound += 1
							end if
						end with
					next BID
					
					for CID as short = 1 to MaxFallCaps
						with Capsule(CID)
							if .Y > Deepest.Y AND .Y < 736 AND .Angle <> CAP_SLOW AND .Angle <> CAP_NEGATER AND _
								.Angle <> CAP_SLOW_PAD AND .Angle <> CAP_WEAK AND .Angle <> CAP_GRAVITY then
								Deepest.Y = .Y
								Deepest.X = .X
								ObjsFound += 1
							end if
						end with
					next CID

					if ObjsFound > 0 AND (abs(DesireX - Deepest.X) > PaddleSize/2 OR abs(DesireX - Deepest.X) < PaddleSize/100) then 
						DesireX = Deepest.X + irandom(-PaddleSize/4,PaddleSize/4)
					elseif ObjsFound = 0 then
						DesireX = Deepest.X
					end if
				elseif ControlStyle <= CTRL_LAPTOP then
					Result = getmouse(MouseX,0,0,ButtonCombo)
					if Result = 0 then
						if .Reverse > 0 then
							DesireX = 1024 - MouseX
						else
							DesireX = MouseX
						end if
					else
						ButtonCombo = 0
					end if
					
				elseif ControlStyle = CTRL_TABLET then
					Result = getmouse(MouseX,0,0,ButtonCombo)
					
					if TapWindow > 0 then TapWindow -= 1 
					
					if Result = 0 then
						if ButtonCombo > 0 then
							if HoldClick = 0 then
								OrigX(0) = DesireX
								OrigX(1) = MouseX
								HoldClick = 1
							else
								if .Reverse > 0 then
									DesireX = OrigX(0) - (MouseX - OrigX(1))*2
								else
									DesireX = OrigX(0) + (MouseX - OrigX(1))*2
								end if
							end if
							
						elseif HoldClick = 1 then
							HoldClick = 0
							TapWindow = 7
						end if
					end if
					
					if .Sluggish = 0 then
						if DesireX < 32 + PaddleSize/2 then DesireX = 32 + PaddleSize/2
						if DesireX > 992 - PaddleSize/2 then DesireX = 992 - PaddleSize/2
					else
						if DesireX < 0 then DesireX = 0
						if DesireX > 1024 then DesireX = 1024
					end if
				elseif ControlStyle = CTRL_KEYBOARD then
					dim as byte MoveSpeed
					if (multikey(SC_LSHIFT) OR multikey(SC_RSHIFT)) AND multikey(SC_CONTROL) then
						MoveSpeed = KeyboardSpeed/4
					elseif (multikey(SC_LSHIFT) OR multikey(SC_RSHIFT)) OR multikey(SC_CONTROL) then
						MoveSpeed = KeyboardSpeed/2
					else
						MoveSpeed = KeyboardSpeed
					end if
					
					if multikey(SC_LEFT) then
						if .Reverse = 0 then
							DesireX -= MoveSpeed
						else
							DesireX += MoveSpeed
						end if
					end if
					if multikey(SC_RIGHT) then
						if .Reverse = 0 then
							DesireX += MoveSpeed
						else
							DesireX -= MoveSpeed
						end if
					end if
			
					if .Sluggish = 0 then
						if DesireX < 32 + PaddleSize/2 then DesireX = 32 + PaddleSize/2
						if DesireX > 992 - PaddleSize/2 then DesireX = 992 - PaddleSize/2
					else
						if DesireX < 0 then DesireX = 0
						if DesireX > 1024 then DesireX = 1024
					end if
				elseif ControlStyle > CTRL_KEYBOARD then
					if JoyAnalog = 0 then
						dim as byte MoveSpeed, SimulButtons = 0
						dim as double CombinedAxes
						for BID as byte = 0 to 31
							if BID <> JoyKeySetting AND (JoyButtonCombo AND (1 SHL BID)) then
								SimulButtons += 1
							end if  
						next
						for AxisID as byte = 0 to 7
							if JoyAxis(AxisID) > -999 then
								CombinedAxes += JoyAxis(AxisID)
							end if
						next AxisID
						
						if SimulButtons >= 2 then
							MoveSpeed = KeyboardSpeed/4
						elseif SimulButtons = 1 then
							MoveSpeed = KeyboardSpeed/2
						else
							MoveSpeed = KeyboardSpeed
						end if
						
						if CombinedAxes < -0.25 then
							if .Reverse = 0 then
								DesireX -= MoveSpeed
							else
								DesireX += MoveSpeed
							end if
						end if
						if CombinedAxes > 0.25 then
							if .Reverse = 0 then
								DesireX += MoveSpeed
							else
								DesireX -= MoveSpeed
							end if
						end if
				
						if .Sluggish = 0 then
							if DesireX < 32 + PaddleSize/2 then DesireX = 32 + PaddleSize/2
							if DesireX > 992 - PaddleSize/2 then DesireX = 992 - PaddleSize/2
						else
							if DesireX < 0 then DesireX = 0
							if DesireX > 1024 then DesireX = 1024
						end if
					else
						if .Reverse = 0 then
							DesireX = (JoyAxis(JoyKeySetting)+1)/2*1024
						else
							DesireX = 1024-(JoyAxis(JoyKeySetting)+1)/2*1024
						end if
				
						if .Sluggish = 0 then
							if DesireX < 32 + PaddleSize/2 then DesireX = 32 + PaddleSize/2
							if DesireX > 992 - PaddleSize/2 then DesireX = 992 - PaddleSize/2
						else
							if DesireX < 0 then DesireX = 0
							if DesireX > 1024 then DesireX = 1024
						end if
					end if
				end if
				
				if HoldAction > 0 AND actionButton(1) = 0 then
					HoldAction = 0
				end if
			
				if .Sluggish > 0 then
					.X = .X + int((DesireX - .X)/25 + 0.5)
				else
					.X = DesireX
				end if
				
			end if
			
			if .X < 32 + PaddleSize/2 then .X = 32 + PaddleSize/2
			if .X > 992 - PaddleSize/2 then .X = 992 - PaddleSize/2
			
			if PaddleSize > 0 then
				renderPaddle(PaddleSize)
				put (.X-PaddleSize/2,.Y),PaddlePic,trans
				if PlayerSlot(Player).MissileAmmo > 0 then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(255,64,64,128),bf
				elseif PlayerSlot(Player).BulletAmmo > 0 then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(255,255,0,128),bf
				elseif .Grabbing > 180 OR (remainder(.Grabbing,60) <= 30 AND .Grabbing > 0) then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(128,128,128,128),bf
				end if
			end if
			
			if GamePaused = 0 then
				'Blizzard does not influence its own timer
				if .Blizzard > 0 then
					if SpeedMod > 100 - FreezeStr then SpeedMod -= 1
					.Blizzard -= 1
				else
					FreezeStr = 0
					if SpeedMod < 100 then SpeedMod += 1
				end if	
				
				if PowerTick >= 100 then
					if .Reverse > 0 then
						.Reverse -= 1
						if .Reverse = 0 then 
							if ControlStyle <= CTRL_LAPTOP then
								MouseX = 1024 - MouseX
								setmouse(MouseX,MouseY)
							elseif ControlStyle = CTRL_TABLET then
								HoldClick = 0
								TapWindow = 0
							end if
						end if
					end if
					
					if .Sluggish > 0 then
						.Sluggish -= 1
						if .Sluggish = 0 then
							if .Reverse > 0 then
								MouseX = 1024 - .X
							else
								MouseX = .X
							end if
						end if
					end if
					
					if .Grabbing > 0 then
						.Grabbing -= 1
					end if
					if .Repairs > 0 then
						.Repairs -= 1
					end if
					if ProgressiveDelay > 0 then
						ProgressiveDelay -= 1
					end if
				end if
			end if
			
			if ShowTopUI >= 60 then
				if .Blizzard > 0 then
					put (40,71),CapsuleBar(1),trans
					put (81,73),CapsuleBarFrame,pset
					line(82,74)-(min(82+int(.Blizzard/60),112),86),rgb(255,255,0),bf
				end if
				if .Grabbing > 0 then
					put (120,71),CapsuleBar(2),trans
					put (161,73),CapsuleBarFrame,pset
					line(162,74)-(min(162+int(.Grabbing/60),192),86),rgb(255,255,0),bf
				end if
				if .Repairs > 0 then
					put (200,71),CapsuleBar(3),trans
					put (241,73),CapsuleBarFrame,pset
					line(242,74)-(min(242+int(.Repairs/60),272),86),rgb(255,255,0),bf
				end if
				if .Reverse > 0 then
					put (280,71),CapsuleBar(4),trans
					put (321,73),CapsuleBarFrame,pset
					line(322,74)-(min(322+int(.Reverse/30),352),86),rgb(255,255,0),bf
				end if
				if .Sluggish > 0 then
					put (360,71),CapsuleBar(5),trans
					put (401,73),CapsuleBarFrame,pset
					line(402,74)-(min(402+int(.Sluggish/30),432),86),rgb(255,255,0),bf
				end if
				if .Fireball > 0 then
					put (440,71),CapsuleBar(6),trans
					put (481,73),CapsuleBarFrame,pset
					line(482,74)-(min(482+int(.Fireball/40),512),86),rgb(255,255,0),bf
				end if
				if .Breakthru > 0 then
					put (520,71),CapsuleBar(7),trans
					put (561,73),CapsuleBarFrame,pset
					line(562,74)-(min(562+int(.Breakthru/40),592),86),rgb(255,255,0),bf
				end if
				if .WeakDmg > 0 then
					put (600,71),CapsuleBar(8),trans
					put (641,73),CapsuleBarFrame,pset
					line(642,74)-(min(642+int(.WeakDmg/30),672),86),rgb(255,255,0),bf
				end if
				if .GravBall > 0 then
					put (680,71),CapsuleBar(9),trans
					put (721,73),CapsuleBarFrame,pset
					line(722,74)-(min(722+int(.GravBall/30),752),86),rgb(255,255,0),bf
				end if
				
				for PokerID as byte = 1 to 5
					put (752+PokerID*40,71),PokerBar(PokerID),trans
				next PokerID
			else
				if .Blizzard > 0 AND (.Blizzard > 180 OR remainder(.Blizzard,60) < 30) then
					put (40,71),CapsuleBar(1),alpha,128
				end if
				if .Grabbing > 0 AND (.Grabbing > 180 OR remainder(.Grabbing,60) < 30) then
					put (120,71),CapsuleBar(2),alpha,128
				end if
				if .Repairs > 0 AND (.Repairs > 180 OR remainder(.Repairs,60) < 30) then
					put (200,71),CapsuleBar(3),alpha,128
				end if
				if .Reverse > 0 AND (.Reverse > 180 OR remainder(.Reverse,60) < 30) then
					put (280,71),CapsuleBar(4),alpha,128
				end if
				if .Sluggish > 0 AND (.Sluggish > 180 OR remainder(.Sluggish,60) < 30) then
					put (360,71),CapsuleBar(5),alpha,128
				end if
				if .Fireball > 0 AND (.Fireball > 180 OR remainder(.Fireball,60) < 30) then
					put (440,71),CapsuleBar(6),alpha,128
				end if
				if .Breakthru > 0 AND (.Breakthru > 180 OR remainder(.Breakthru,60) < 30) then
					put (520,71),CapsuleBar(7),alpha,128
				end if
				if .WeakDmg > 0 AND (.WeakDmg > 180 OR remainder(.WeakDmg,60) < 30) then
					put (600,71),CapsuleBar(8),alpha,128
				end if
				if .GravBall > 0 AND (.GravBall > 180 OR remainder(.GravBall,60) < 30) then
					put (680,71),CapsuleBar(9),alpha,128
				end if
				
				for PokerID as byte = 1 to 5
					put (752+PokerID*40,71),PokerBar(PokerID),alpha,128
				next PokerID
			end if
		end with
		
		with Paddle(2)
			.X = Paddle(1).X
			
			if PaddleSize > 0 AND (GameStyle AND (1 SHL STYLE_DUAL_PADDLES)) then
				.Y = 656 - PaddleHeight

				put (.X-PaddleSize/2,.Y),PaddlePic,trans
				if PlayerSlot(Player).MissileAmmo > 0 then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(255,64,64,128),bf
				elseif PlayerSlot(Player).BulletAmmo > 0 then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(255,255,0,128),bf
				elseif Paddle(1).Grabbing > 180 OR (remainder(Paddle(1).Grabbing,60) <= 30 AND Paddle(1).Grabbing > 0) then
					line(.X-PaddleSize/2,.Y)-(.X+PaddleSize/2-1,.Y+PaddleHeight-1),rgba(128,128,128,128),bf
				end if
			else
				.Y = -100
			end if
		end with

		AboveLine = 0
		HeadingUpwards = 0
		if WepCooldown > 0 then
			WepCooldown -= 1
		end if

		if PlayerSlot(Player).Lives > 0 then
			PlayerSlot(Player).PlayTime += 1
		end if
			
		if total_lives > 0 AND GamePaused = 0 AND LevelClear = 0 then
			if multikey(SC_TAB) then
				Instructions = "Auxilliary lists may not be accessed while a game is running."
				InstructExpire = timer + 7
			end if

			InPassword = "--------"
			if actionButton AND PaddleSize > 0 AND TotalBC > 0 AND WepCooldown = 0 then
				if PlayerSlot(Player).BulletAmmo > 0 AND Bullet(BulletStart).Y <= MinPlayHeight - 20 AND Bullet(BulletStart+1).Y <= MinPlayHeight - 20 then
					playClip(SFX_SHOOT_BULLET,Paddle(1).X)
					WepCooldown = 15
					
					for PaddleID as byte = 1 to 2
						if Paddle(PaddleID).Y > 0 then
							PlayerSlot(Player).BulletAmmo -= 2
							Bullet(BulletStart).Y = Paddle(PaddleID).Y - 10
							Bullet(BulletStart+1).Y = Paddle(PaddleID).Y - 10
							Bullet(BulletStart).X = Paddle(PaddleID).X-PaddleSize/2
							Bullet(BulletStart+1).X = Paddle(PaddleID).X+PaddleSize/2
							Bullet(BulletStart).Power = 0
							Bullet(BulletStart+1).Power = 0
							BulletStart += 2
						end if
					next PaddleID
					
					if PlayerSlot(Player).BulletAmmo < 0 then
						PlayerSlot(Player).BulletAmmo = 0
					end if
				end if
				
				if PlayerSlot(Player).MissileAmmo > 0 AND Bullet(BulletStart).Y <= MinPlayHeight - 20 then
					playClip(SFX_SHOOT_MISSILE,Paddle(1).X)
					WepCooldown = 90
					
					for PaddleID as byte = 2 to 1 step -1
						if Paddle(PaddleID).Y > 0 then
							PlayerSlot(Player).MissileAmmo -= 1
							Bullet(BulletStart).Y = Paddle(PaddleID).Y - 20
							Bullet(BulletStart).X = Paddle(PaddleID).X
							Bullet(BulletStart).Power = 2
							BulletStart += 2
							exit for
						end if
					next PaddleID
				end if
			end if
			
			' Handle bullets
			BulletsInPlay = 0
			for MSID as ubyte = 1 to MaxBullets
				with Bullet(MSID)
					if .Y > MinPlayHeight - 20 then
						dim as short XRef = int((.X + 14)/48), YRef = int((.Y - 72)/24)
						dim as ubyte ScoreBrick
						if CondensedLevel then
							XRef = int((.X - 8)/24)
							if XRef > 40 then
								XRef = 40
							end if
						elseif XRef > 20 then
							XRef = 20
						end if
						if XRef < 1 then XRef = 1
						.Y -= 5 * (SpeedMod / 100)
						
						BulletsInPlay += 1
						if .Power = 0 then
							put(.X-2,.Y),BulletPic,trans
							if YRef > 0 AND YRef <= 20 AND PlayerSlot(Player).TileSet(XRef,YRef).BrickID > 0 then
								if Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID).HitDegrade = 0 then
									ScoreBrick = 1
									playClip(SFX_BRICK,.X)
								elseif Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID).HitDegrade <> PlayerSlot(Player).TileSet(XRef,YRef).BrickID then
									ScoreBrick = 1
									playClip(SFX_HARDEN,.X)
								else
									playClip(SFX_INVINCIBLE,.X)
								end if
								
								if ScoreBrick then
									generateCapsule(XRef,YRef)
									with Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID)
										PlayerSlot(Player).Score += .ScoreValue
										generateParticles(.ScoreValue,XRef,YRef,rgb(255,255,255))
									end with
								end if
								
								Invis = 12
								damageBrick(XRef,YRef,Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID).HitDegrade,0)
								.Y = -25
							end if
						else
							put(.X-5,.Y),MissilePic,trans
							if YRef > 0 AND YRef <= 20 AND PlayerSlot(Player).TileSet(XRef,YRef).BrickID > 0 then
								dim as short RefBrick 
								ScoreBrick = Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID).ZapDegrade
								RefBrick = Pallete(PlayerSlot(Player).TileSet(XRef,YRef).BrickID).CalcedInvulnerable
								
								generateCapsule(XRef,YRef)
								with Pallete(ScoreBrick)
									PlayerSlot(Player).Score += .ScoreValue
									generateParticles(.ScoreValue,XRef,YRef,rgb(255,255,255))
								end with
								
								Invis = 12
								damageBrick(XRef,YRef,min(ExplodeDelay,ExplodeDelay + (100 * (RefBrick + 1))),0)
								.Y = -25
							end if
						end if
					end if
				end with
			next MSID
			
			with Paddle(1)
				.Fireball = 0
				.Breakthru = 0
				.WeakDmg = 0
				.GravBall = 0
			end with
			'Handle balls
			for BID as short = 1 to NumBalls
				with Ball(BID)
					if .Speed > 0 then
						if .Power > -2 then
							if (GameStyle AND (1 SHL STYLE_BOSS)) then
								.Power = 0
							elseif .Duration > 0 then
								if PowerTick >= 100 then
									.Duration -= 1
								end if
							elseif ActiveDifficulty < 2.5 then
								.Power = 1
							elseif .Power > 0 then
								.Power = 0
							end if
						end if
						
						select case .Power
							case -1
								Paddle(1).WeakDmg = max(.Duration, Paddle(1).WeakDmg)
							case 0
								if PlayerSlot(Player).Difficulty < 2.5 then
									Paddle(1).WeakDmg = max(.Duration, Paddle(1).WeakDmg)
								end if
							case 2
								Paddle(1).Fireball = max(.Duration, Paddle(1).Fireball)
							case 3
								Paddle(1).Breakthru = max(.Duration, Paddle(1).Breakthru)
							case 4
								Paddle(1).Fireball = max(.Duration, Paddle(1).Fireball)
								Paddle(1).Breakthru = max(.Duration, Paddle(1).Breakthru)
						end select
						Paddle(1).GravBall = max(.Gravity, Paddle(1).GravBall) 
						
						if sin(degtorad(.Angle)) > 0 AND .Power > -2 AND .Grabbed = 0 then
							HeadingUpwards = 1
						end if
						
						for Update as ubyte = 1 to Interpolation
							if .Grabbed > 0 then
								dim as byte RefPaddle
								
								if .Grabbed >= 1000 then
									RefPaddle = 2
								else
									RefPaddle = 1
								end if
								
								.Spawned = 0
								if Update = 1 then
									.X += Paddle(RefPaddle).X - Paddle(1).Grabbed
									if .X < 32 + BallSize then
										.X = 32 + BallSize
									elseif .X > 992 - BallSize then
										.X = 992 - BallSize
									end if
								end if
								
								.Y = Paddle(RefPaddle).Y - BallSize
								if Update = 1 AND PowerTick >= 100 then
									.Grabbed -= 1
								end if
								if actionButton OR PaddleSize = 0 OR .Grabbed = 1000 then
									.Grabbed = 0
								end if
							elseif (GameStyle AND (1 SHL STYLE_HYPER)) then
								if sin(degtorad(.Angle)) > 0 AND _
									(GameStyle AND (1 SHL STYLE_STEER)) AND _
									Update = 1 then
									if abs(Paddle(1).X - Paddle(1).Grabbed) > 0 then
										.X += Paddle(1).X - Paddle(1).Grabbed
										.Trapped = 0
									end if
									if .X < 32 + BallSize then
										.X = 32 + BallSize
									elseif .X > 992 - BallSize then
										.X = 992 - BallSize
									end if
								end if
								.X += int(.Speed)*cos(degtorad(.Angle))*1.5/1.3/Interpolation * (SpeedMod / 100)
								.Y += int(.Speed)*-sin(degtorad(.Angle))*1.5/1.3/Interpolation * (SpeedMod / 100)
							else
								if sin(degtorad(.Angle)) > 0 AND _
									(GameStyle AND (1 SHL STYLE_STEER)) AND _
									Update = 1 then
									if abs(Paddle(1).X - Paddle(1).Grabbed) > 0 then
										.X += Paddle(1).X - Paddle(1).Grabbed
										.Trapped = 0
									end if
									if .X < 32 + BallSize then
										.X = 32 + BallSize
									elseif .X > 992 - BallSize then
										.X = 992 - BallSize
									end if
								end if
								.X += int(.Speed)*cos(degtorad(.Angle))/1.3/Interpolation * (SpeedMod / 100)
								.Y += int(.Speed)*-sin(degtorad(.Angle))/1.3/Interpolation * (SpeedMod / 100)
							end if

							if (.Y < 736 + BallSize OR sin(degtorad(.Angle)) > 0 OR (GameStyle AND (1 SHL STYLE_BONUS))) AND _
								.Power >= -1 then
								AboveLine = 1
							end if

							if .X < 32 + BallSize AND _
								remainder(.Angle+3600,360) > 90 AND _
								remainder(.Angle+3600,360) < 270 AND _
								.Y < 736 + BallSize then
								'Bounce off left side

								if .LHX > 1 then
									.LHX = 0
									.LHY = 0
								end if

								playClip(SFX_WALL,.X,convertSpeed(.Speed))
								adjustSpeed(BID,ActiveDifficulty / 100)
								if .Power = -2 then
									.Power = 0
									TotalBC += 1
								end if
								incTickMark(Ball(BID))
								.Angle = 180 - .Angle
							elseif .X > 992 - BallSize AND _
								(remainder(.Angle+3600,360) < 90 OR _
								remainder(.Angle+3600,360) > 270) AND _
								.Y < 736 + BallSize then
								'Bounce off the right side

								if .LHX < 20 then
									.LHX = 0
									.LHY = 0
								end if

								playClip(SFX_WALL,.X,convertSpeed(.Speed))
								adjustSpeed(BID,ActiveDifficulty / 100)
								if .Power = -2 then
									.Power = 0
									TotalBC += 1
								end if
								incTickMark(Ball(BID))
								.Angle = 180 - .Angle
							end if
							brickCollisions(BID)
							
							'Bounce off paddle(s)
							for PaddleID as byte = 1 to 2
								if .Y > Paddle(PaddleID).Y - BallSize AND .Y < Paddle(PaddleID).Y + PaddleHeight + BallSize AND _
									remainder(.Angle+3600,360) > 180 AND _
									.X >= Paddle(PaddleID).X-PaddleSize/2-BallSize AND _
									.X <= Paddle(PaddleID).X+PaddleSize/2+BallSize AND _
									PaddleSize > 0 then
									'Bounce off paddle
									
									if PaddleSize > MinSize AND PaddleAdjust < 0 then
										renderPaddle(PaddleSize - 1)
									elseif PaddleSize < MaxSize AND PaddleAdjust > 0 then
										renderPaddle(PaddleSize + 1)
									end if
	
									.LHX = 0
									.LHY = 0
									if .Power = -2 then
										.Power = 0
										TotalBC += 1
									end if
									
									if ProgressiveDelay <= 0 then
										'Impose a delay in between bounces
										ProgressiveBounces += 1
										ProgressiveDelay = 9
									end if
	
									if ProgressiveBounces >= ProgressiveQuota AND (GameStyle AND (1 SHL STYLE_PROGRESSIVE)) then
										ProgressiveBounces = 0
										if ProgressiveQuota > 4 then
											ProgressiveQuota -= .5
										end if
										if ProgressiveQuota > 2 then
											ProgressiveQuota -= .25
										end if
										if ProgressiveQuota > 1 then
											ProgressiveQuota -= .25
										end if
										for XID as ubyte = 1 to 40
											PlayerSlot(Player).TileSet(XID,0) = PlayerSlot(Player).TileSet(XID,24)
										next XID

										for YID as byte = 24 to 1 step -1
											for XID as ubyte = 1 to 40
												PlayerSlot(Player).TileSet(XID,YID) = PlayerSlot(Player).TileSet(XID,(YID-1))
											next XID
										next YID
										
										playClip(SFX_POWER_DOWN,.X)
									end if

									PaddlePercent = (.X - Paddle(1).X+PaddleSize/2+BallSize)/(PaddleSize+BallSize*2) * 100
									if Paddle(1).Grabbing > 0 AND .ForceUngrab = 0 then
										.Grabbed = 300 + (PaddleID - 1) * 1000
									end if
									if GameStyle AND (1 SHL STYLE_BOSS) then
										.Trapped = 0
									else
										incTickMark(Ball(BID))
									end if
									.Spawned = 0
									dynamicSpeedClip(.Speed,.X)
									if .Speed < 20 then
										adjustSpeed(BID,ActiveDifficulty / 100)
									end if
									.Angle = int(165 - PaddlePercent/100*150 + .5)
	
									if (Gamestyle AND (1 SHL STYLE_DOUBLE_BALLS)) AND ProhibitSpawn = 1 then
										ProhibitSpawn = 2
										for BID as ubyte = 2 to NumBalls
											with Ball(BID)
												if .Speed <= 0 then
													if ActiveDifficulty >= 3.5 then
														.Speed = DefaultSpeed - irandom(0,30) / 100
													else
														.Speed = MinSpeed
													end if
													.Y = 384
													.X = irandom(100,924)
													.Spawned = 1
													.Duration = 0
													.Trapped = 0
													.Gravity = 0
													.Angle = irandom(210,330)
													TotalBC += 1
													exit for
												end if
											end with
										next BID
									end if
								end if
							next PaddleID
							
							if .Y < 96 AND (Gamestyle AND (1 SHL STYLE_EXTRA_HEIGHT)) then
								ShowTopUI = 0
							end if
							
							if .ForceUngrab > 0 AND PowerTick >= 100 then
								.ForceUngrab -= 1
							end if

							if .Y > 768 + BallSize AND sin(degtorad(.Angle)) < 0 AND (AboveLine > 0 OR BarrierStrength = 0) then
								'Fall off the playfield
								.X = 512
								.Y = -10
								.Speed = 0
								.Trapped = 0
								.Gravity = 0
								
								if .Power = -2 then
									.Power = 0
									TotalBC += 1
								end if

								TotalBC -= 1
								exit for
							elseif .Y < MinPlayHeight + BallSize then
								'Bounce off the top of the frame

								if .LHY > 1 OR MinPlayHeight < 96 then
									.LHX = 0
									.LHY = 0
								end if
								if .Power = -2 then
									.Power = 0
									TotalBC += 1
								end if

								playClip(SFX_WALL,.X,convertSpeed(.Speed))
								adjustSpeed(BID,ActiveDifficulty / 100)
								if (GameStyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
									with PlayerSlot(Player)
										if .BossHealth > 0 then
											.BossLastHealth = .BossHealth
											.BossLastHit = 0
											.BossHealth -= int(Ball(BID).Speed)
											.Score += int(Ball(BID).Speed) * ballCtBonus
											if .BossHealth <= 0 then
												playClip(SFX_WALL_BROKEN)
											end if
										else
											if LevelClear < 1 then
												LevelClear = 1
											end if
										end if
									end with
								else
									incTickMark(Ball(BID))
								end if
								.Y = MinPlayHeight + BallSize
								.Invul = 0
								.Angle = -.Angle
								if Paddle(1).Spawned = 0 AND (Gamestyle AND (1 SHL STYLE_SHRINK_CEILING)) then
									renderPaddle(PaddleSize - (StandardSize - MinSize))
									Paddle(1).Spawned = 1

									if PaddleSize < MinSize then
										renderPaddle(MinSize)
									end if
								end if
							end if
						next Update
						
						if abs(sin(degtorad(.Angle))) < 0.15 OR .Gravity > 0 then
							if .Grabbed = 0 then
								.Angle -= 0.5 * cos(degtorad(.Angle)) * SpeedMod/100
							end if
							if .Gravity > 0 AND PowerTick >= 100 then
								.Gravity -= 1
							end if
						end if
						
						if .Duration > 0 AND (remainder(.Duration,60) <= 30 OR .Duration >= 180) then
							if .Power < 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgba(255,255,255,96),bf
							elseif .Power = 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							elseif .Power = 1 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							elseif .Power = 2 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,64,64),bf
							elseif .Power = 3 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,0),bf
							elseif .Power = 4 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,255,255),bf
							end if
						else
							if ActiveDifficulty < 2.5 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							else
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							end if
						end if
						
						if .Gravity > 0 AND (remainder(.Gravity,60) <= 30 OR .Gravity >= 180) then
							line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,0,0),b,&b1010101010101010
						end if

					end if
				end with
			next BID
			
			if (InType = "p" OR DebugConsole OR (e.type = EVENT_WINDOW_LOST_FOCUS AND ControlStyle >= CTRL_DESKTOP)) AND LevelClear = 0 then
				GamePaused = 1
			end if
		elseif LevelClear > 0 then
			if multikey(SC_TAB) then
				Instructions = "Auxilliary lists may not be accessed while a game is running."
				InstructExpire = timer + 7
			end if
			
			dim as integer Bonuses(4), SetClear, NextLevel
			with PlayerSlot(Player)
				if (Gamestyle AND (1 SHL STYLE_BREAKABLE_CEILING)) then
					Bonuses(1) = .PerfectClear * BaseCapsuleValue * 7.5
					Bonuses(2) = 0
				else
					Bonuses(1) = .PerfectClear * BaseCapsuleValue * 5
					Bonuses(2) = BaseCapsuleValue
				end if
				
				GamePaused = 0
				AboveLine = 1
							
				for YID as ubyte = 1 to 24			
					for XID as ubyte = 1 to 20*(CondensedLevel+1)
						if PlayerSlot(Player).TileSet(XID,YID).BrickID <> 0 then
							Bonuses(2) = 0
							exit for,for
						end if
					next XID
				next YID
				
				NextLevel = .LevelNum + 1
				
				if ((NextLevel >= SecretLevels AND HighLevel < SecretLevels AND SecretLevels > 0) OR _
					checkLevel(NextLevel) = "") AND CampaignFolder <> EndlessFolder then
					Bonuses(4) = .Lives * BaseCapsuleValue * 2

					if RecalcGems AND LevelClear > 25 then
						.Score -= Bonuses(3)
					end if
					Bonuses(3) = score_hand * BaseCapsuleValue
					if RecalcGems then
						.Score += Bonuses(3)
						if .DispScore < .Score then
							.DispScore = .Score
						end if
						RecalcGems = 0
					end if

					SetClear = 1
				end if
			
				Bonuses(0) += Bonuses(1) + Bonuses(2) + Bonuses(3) + Bonuses(4)
				if LevelClear = 1 then
					setmouse(,,0,0)
					.Score += Bonuses(0)
					RecalcGems = 0
				end if 
			end with
			
			for MSID as ubyte = 1 to MaxBullets
				with Bullet(MSID)
					if .Y > MinPlayHeight - 20 then
						BulletsInPlay += 1
						if .Power = 0 then
							put(.X-2,.Y),BulletPic,trans
						else
							put(.X-5,.Y),MissilePic,trans
						end if
					end if
				end with
			next MSID
			for BID as short = 1 to NumBalls
				with Ball(BID)
					if .Speed > 0 then
						if .Duration > 0 AND (remainder(.Duration,60) <= 30 OR .Duration >= 180) then
							if .Power < 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgba(255,255,255,96),bf
							elseif .Power = 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							elseif .Power = 1 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							elseif .Power = 2 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,64,64),bf
							elseif .Power = 3 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,0),bf
							elseif .Power = 4 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,255,255),bf
							end if
						else
							if ActiveDifficulty < 2.5 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							else
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							end if
						end if
						
						if .Gravity > 0 AND (remainder(.Gravity,60) <= 30 OR .Gravity >= 180) then
							line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,0,0),b,&b1010101010101010
						end if

					end if
				end with
			next BID
			
			if SetClear = 1 then
				line(0,298)-(LevelClear,478),rgba(0,0,0,64),bf
				line(0,298)-(LevelClear,298),rgb(255,255,255)
				line(0,478)-(LevelClear,478),rgb(255,255,255)
				gfxstring("Flawless play   : "+str(Bonuses(1)),40,301,5,5,3,rgb(255,255,255))
				if (Gamestyle AND (1 SHL STYLE_BREAKABLE_CEILING)) = 0 then
					gfxstring("All blocks clear: "+str(Bonuses(2)),40,331,5,5,3,rgb(255,255,255))
				end if
				
				gfxstring("Unused gems     : "+str(Bonuses(3)),40,391,5,5,3,rgb(255,255,255))
				gfxstring("Lives leftover  : "+str(Bonuses(4)),40,421,5,5,3,rgb(255,255,255))
				gfxstring("Total bonus     : "+str(Bonuses(0)),40,451,5,5,3,rgb(255,255,255))
				
				PlayerSlot(Player).PlayTime -= 1
			else
				line(0,343)-(LevelClear,433),rgba(0,0,0,64),bf
				line(0,343)-(LevelClear,343),rgb(255,255,255)
				line(0,433)-(LevelClear,433),rgb(255,255,255)
				gfxstring("Flawless play   : "+str(Bonuses(1)),40,346,5,5,3,rgb(255,255,255))
				if (Gamestyle AND (1 SHL STYLE_BREAKABLE_CEILING)) = 0 then
					gfxstring("All blocks clear: "+str(Bonuses(2)),40,376,5,5,3,rgb(255,255,255))
				end if
				gfxstring("Total bonus     : "+str(Bonuses(0)),40,406,5,5,3,rgb(255,255,255))
			end if
			
			if GameHints(4) = 1 then GameHints(4) = 2
			
			if LevelClear < 1023 then
				LevelClear += 8
			end if
			
			if right(Instructions,14) = "Please wait..." OR right(Instructions,31) = "Perform [ACTION] to continue..." OR Instructions = "" then
				if LevelClear < LevelClearDelay then
					Instructions = "Level "+str(PlayerSlot(Player).LevelNum)+" completed! Please wait..."
				else
					Instructions = "Level "+str(PlayerSlot(Player).LevelNum)+" completed! Perform [ACTION] to continue..."
				end if
				InstructExpire = timer + 1
			end if
			
		elseif GamePaused then
			for MSID as ubyte = 1 to MaxBullets
				with Bullet(MSID)
					if .Y > MinPlayHeight - 20 then
						BulletsInPlay += 1
						if .Power = 0 then
							put(.X-2,.Y),BulletPic,trans
						else
							put(.X-5,.Y),MissilePic,trans
						end if
					end if
				end with
			next MSID
			for BID as short = 1 to NumBalls
				with Ball(BID)
					if .Speed > 0 then
						if .Duration > 0 AND (remainder(.Duration,60) <= 30 OR .Duration >= 180) then
							if .Power < 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgba(255,255,255,96),bf
							elseif .Power = 0 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							elseif .Power = 1 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							elseif .Power = 2 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,64,64),bf
							elseif .Power = 3 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,0),bf
							elseif .Power = 4 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,255,255),bf
							end if
						else
							if ActiveDifficulty < 2.5 then
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(128,128,255),bf
							else
								line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(255,255,255),bf
							end if
						end if
						
						if .Gravity > 0 AND (remainder(.Gravity,60) <= 30 OR .Gravity >= 180) then
							line(.X-BallSize,.Y-BallSize)-(.X+BallSize,.Y+BallSize),rgb(0,0,0),b,&b1010101010101010
						end if

						if .Invul > 0 AND .Y <= 360+BallSize then
							dim as ubyte RowFilled
							for YID as ubyte = 1 to 20
								if .Y >= 60+BallSize+(YID-1)*15 AND .Y <= 60-BallSize+(YID)*15 then
									RowFilled = 0
									for XID as ubyte = 1 to 20*(CondensedLevel+1)
										if PlayerSlot(Player).TileSet(XID,YID).BrickID > 0 then
											RowFilled += 1
										end if
									next XID
									if RowFilled = 0 then
										.Invul = 0
										exit for
									end if
								end if
							next YID
						else
							.Invul = 0
						end if
					end if
				end with
			next BID
			
			setmouse(,,0,0)
			if DebugConsole then
				with PlayerSlot(Player)
					if ucase(InType) >= "A" AND ucase(InType) <= "Z" then
						DebugCode += ucase(InType)
					elseif InType = chr(8) then
						DebugCode = left(DebugCode,len(DebugCode)-1)
					end if
					Instructions = "Please enter the code: "+DebugCode
					InstructExpire = timer + 1
					
					if InType = EnterKey then
						if DebugCode = "" then
							Instructions = "No code applied"
						elseif DebugCode = "LEVELAXE" then
							Instructions = "Level progress deleted"
							HighLevel = 1
							kill(CampaignName+".dat")
							kill(CampaignName+".flag")
						elseif DebugCode = "IWANTTOPLAY" then
							if NumPlayers >= MaxPlayers then
								Instructions = "No room to add another player"
							else
								dim as short LowestLevel = 999
								if PlayerSlot(0).Difficulty < 6.5 then
									for PID as ubyte = 1 to NumPlayers
										with PlayerSlot(PID)
											if .Lives > 0 then
												LowestLevel = min(LowestLevel,.LevelNum)
											end if
										end with
									next PID
									
									while LowestLevel > 1 AND checkLevel(LowestLevel) = "--------"
										LowestLevel -= 1
									wend
								else
									LowestLevel = NewPlrSlot.InitialLevel
								end if
								
								NumPlayers += 1
								PlayerSlot(NumPlayers) = NewPlrSlot
								with PlayerSlot(NumPlayers)
									.InitialLevel = LowestLevel
									.LevelNum = .LevelNum
									.Difficulty = DifficultyRAM(NumPlayers)

									freshLevel(NumPlayers)
								end with
								
								Instructions = "Here comes a new challenger! Turns will cycle as usual."
							end if
						elseif DebugCode = "SKIPTURN" then
							if NumPlayers <= 1 then
								Instructions = "No effect in a 1-player game"
							elseif TotalBC > 0 then
								Instructions = "Not available if there are already balls in play"
							else
								transferControl
								Instructions = "Skip successful. Ready to go, Player "+str(Player)+"?"
							end if
						elseif DebugCode = "PUMPKINEATER" then
							if DQ = 0 then
								Instructions = "Cheat mode turned on! High scores will not be saved"
								DQ = 1
							else
								Instructions = "Cheat mode already active"
							end if
						elseif DQ then
							if DebugCode = "IMMORTAL" then
								Instructions = "Extra lives granted"
								.Lives += 3
							elseif DebugCode = "BIGGIEPADDLE" then
								Instructions = "Paddle size increased"
								renderPaddle(PaddleSize + 70)
							elseif DebugCode = "PEWPEW" then
								.BulletAmmo += 100
								.MissileAmmo = 0
								Instructions = "Bullet stock granted"
							elseif DebugCode = "CAPSHOWER" then
								for GenID as byte = 1 to 120
									generateCapsule(irandom(1,20*(CondensedLevel+1)),irandom(1,20))
								next GenID
								Instructions = "Capsule shower granted"
							elseif DebugCode = "WARPAWAY" then
								if LevelClear < 1 then LevelClear = 1024
								Instructions = "Level warp granted"
							elseif DebugCode = "BACKINTIME" then
								loadLevel(.LevelNum)
								Instructions = "Level restart granted"
							elseif DebugCode = "TIMEFROST" then
								with Paddle(1)
									.Blizzard += 1800
								end with
								FreezeStr = (FreezeStr + 60) / 2 
								Instructions = "Blizzard granted"
							elseif DebugCode = "CURVEDOWN" then
								for BID as short = 1 to NumBalls
									with Ball(BID)
										if .Speed > 0 AND .Power <> -2 then
											.Gravity = 900
										end if
									end with
								next BID
								Instructions = "Gravity granted"
							else
								dim as ubyte PunishRoll
								forceReleaseBalls
								Instructions = "Trying to cheat? Take this!"
								PunishRoll = irandom(1,6)
								select case PunishRoll
									case 1
										.Lives -= 1
									case 2
										if .Score >= 10000 then
											.Score -= 10000
											.DispScore -= 10000
										else
											.Lives -= 1
										end if
									case 3
										resetPaddle(1)
									case 4
										for BID as short = 1 to NumBalls
											with Ball(BID)
												if .Speed > 0 then
													.Power = -1
													.Duration = 60*120
												end if
											end with
										next BID
									case 5
										Paddle(1).Sluggish = irandom(15,45) * 60
										Paddle(1).Reverse = irandom(15,45) * 60
										PaddleAdjust = -2
									case 6
										renderPaddle(5)
								end select
								if .Lives <= 0 AND NumPlayers > 1 then
									transferControl
								end if
							end if
						else
							Instructions = "Code unrecognized"
						end if
						
						with Paddle(1)
							if ControlStyle >= CTRL_DESKTOP AND ControlStyle <= CTRL_LAPTOP then
								if .Reverse > 0 then
									setmouse(1024-.X,240,0,1)
								else
									setmouse(.X,240,0,1)
								end if
							end if
						end with
						AboveLine = 1
						InstructExpire = timer + 5
						DebugConsole = 0
						HoldAction = 1
						GamePaused = 0
					end if
				end with
			else
				if NumPlayers > 1 then
					Instructions = "Game paused. Press P to resume, Player "+str(Player)+" (or press ESC to end this player)"
				else
					Instructions = "Game paused. Press P to resume, or press ESC to end current game"
				end if
				InstructExpire = timer + 1
				if multikey(SC_TAB) then
					auxillaryView(InstruAlpha, InstruBeta)
				end if
			end if
			
			if InType = "p" AND DebugConsole = 0 then
				if ControlStyle >= CTRL_DESKTOP AND ControlStyle <= CTRL_LAPTOP then
					with Paddle(1)
						if .Reverse > 0 then
							setmouse(1024-.X,240,0,1)
						else
							setmouse(.X,240,0,1)
						end if
					end with
				elseif ControlStyle = CTRL_TABLET then
					HoldClick = 0
					TapWindow = 0
				end if
				Instructions = "Game resumed"
				AboveLine = 1
				InstructExpire = timer + 5
				HoldAction = 1
				GamePaused = 0
			end if
		end if
		
		if InType = FunctionEleven AND total_lives > 0 then
			DebugCode = ""
			DebugConsole = 1 
		end if
		
		CapsFalling = 0
		for CapID as ubyte = 1 to MaxFallCaps
			with Capsule(CapID)
				if .Y < 778 then
					CapsFalling += 1
					put(.X-19,.Y-9),CapsulePic(CapID),trans
					if GamePaused = 0 then
						for PaddleID as byte = 1 to 2
							if PaddleSize > 0 AND .X + 19 > Paddle(PaddleID).X - PaddleSize/2 AND _
								.X - 19 < Paddle(PaddleID).X + PaddleSize/2 AND _
								.Y + 10 > Paddle(PaddleID).Y AND .Y - 9 < Paddle(PaddleID).Y + PaddleHeight then
								dim as ushort BonusPts, ChooseParticle
								.Y = 800
								if PaddleSize + 5 < MinSize then 
									renderPaddle(PaddleSize + 5)
								elseif PaddleSize < MinSize then 
									renderPaddle(MinSize)
								end if
								select case .Angle
									case CAP_SLOW
										capsuleMessage("SLOWER BALLS: All ball speeds slowed to minimum",-1)
										for BID as short = 1 to NumBalls
											with Ball(BID)
												if .Speed > 0 AND .Power <> -2 then
													.Speed = MinSpeed
													.Gravity = 0
												end if
											end with
										next BID
										playClip(SFX_POWER_UP,.X)
									case CAP_FAST
										capsuleMessage("FASTER BALLS",-1)
										for BID as short = 1 to NumBalls
											with Ball(BID)
												if .Speed > 0 AND .Power <> -2 then
													adjustSpeed(BID,min(4,int(ActiveDifficulty+0.5)))
												end if
											end with
										next BID
										playClip(SFX_POWER_DOWN,.X)
									case CAP_EXPAND
										if PaddleSize < MinSize then
											renderPaddle(MinSize)
										end if
										if PaddleSize < MaxSize then
											renderPaddle(PaddleSize + 40)
											if PaddleSize > MaxSize then
												renderPaddle(MaxSize)
											end if
										end if
										PaddleAdjust = max(PaddleAdjust,0)
										capsuleMessage("EXPAND PADDLE: Size +40 pixels = "+str(PaddleSize)+" pixels",-1)
										forceReleaseBalls
										playClip(SFX_POWER_UP,.X)
									case CAP_REDUCE
										if PaddleSize > MinSize then
											renderPaddle(PaddleSize - 40)
											if PaddleSize < MinSize then
												renderPaddle(MinSize)
											end if
										end if
										PaddleAdjust = min(PaddleAdjust,0)
										capsuleMessage("REDUCE PADDLE: Size -40 pixels = "+str(PaddleSize)+" pixels",-1)
										forceReleaseBalls
										playClip(SFX_POWER_DOWN,.X)
									case CAP_LIFE
										capsuleMessage("EXTRA LIFE")
										PlayerSlot(Player).Lives += 1
										playClip(SFX_LIFE,.X)
									case CAP_BLIZZARD
										capsuleMessage("BLIZZARD: Slow down movement speeds")
										with Paddle(1)
											.Blizzard += 1800
										end with
										FreezeStr = (FreezeStr + 60) / 2 
										playClip(SFX_POWER_UP,.X)
									case CAP_REPAIR
										capsuleMessage("FASTER REPAIRS: Repair rate temporarily quadrupled")
										Paddle(1).Repairs += 1800
										playClip(SFX_POWER_UP,.X)
									case CAP_DISRUPT
										dim as short TotalNew = 0, BallsFound, RollBall
										capsuleMessage("DISRUPTION: One ball splits into eight")
										forceReleaseBalls
										RollBall = irandom(1,TotalBC)
										
										for BID as short = 1 to NumBalls
											with Ball(BID)
												if .Speed > 0 AND .Power <> -2 then
													BallsFound += 1
													
													if BallsFound = RollBall then
														adjustSpeed(BID,4)
														for NewBall as short = 1 to 100
															with Ball(NewBall)
																if .Speed <= 0 then
																	TotalNew += 1
																	.Speed = int(Ball(BID).Speed)
																	.X = Ball(BID).X
																	.Y = Ball(BID).Y
																	.Gravity = Ball(BID).Gravity
																	.Spawned = 0
																	.Power = Ball(BID).Power
																	.Duration = Ball(BID).Duration
																	.Angle = Ball(BID).Angle + 45 * TotalNew
																	.ForceUngrab = 6
																	TotalBC += 1
																end if
																
																if TotalNew >= 7 then
																	exit for
																end if
															end with
														next
														exit for
													end if
												end if
											end with
										next BID
										playClip(SFX_POWER_UP,.X)
									case CAP_SPLIT_BALL
										dim as ubyte Splitted(NumBalls)
										capsuleMessage("SPLIT BALL",-1)
										forceReleaseBalls
										for BID as short = 1 to NumBalls
											with Ball(BID)
												if .Speed > 0 AND Splitted(BID) = 0 AND .Power <> -2 then
													for NewBall as short = 1 to 100
														with Ball(NewBall)
															if .Speed <= 0 then
																Splitted(NewBall) = 1
																.Speed = int(Ball(BID).Speed)
																.X = Ball(BID).X
																.Y = Ball(BID).Y
																.Gravity = Ball(BID).Gravity
																.Spawned = 0
																.Power = Ball(BID).Power
																.Duration = Ball(BID).Duration
																.Angle = Ball(BID).Angle + 90
																.ForceUngrab = 6
																TotalBC += 1
																exit for
															end if
														end with
													next
												end if
											end with
										next BID
										erase Splitted
										playClip(SFX_POWER_UP,.X)
									case CAP_ZAP
										capsuleMessage("ZAP BLOCKS: Remaining blocks are visible and soft")
										for YID as ubyte = 1 to 24
											for XID as ubyte = 1 to 20*(CondensedLevel+1)
												with Pallete(PlayerSlot(Player).TileSet(XID,YID).BrickID)
													with PlayerSlot(Player).TileSet(XID,YID)
														if .BrickID > 0 then
															.BrickID = Pallete(.BrickID).ZapDegrade
															.Flash = BaseFlash
															.HitTime = 0
															.LastBall = 0
															
															Pallete(.BrickID).CanRegen = 0
														end if
													end with
												end with
											next XID
										next YID
										
										if (Gamestyle AND (1 SHL STYLE_INVIS)) then
											Gamestyle -= 2^STYLE_INVIS
										end if
										playClip(SFX_POWER_UP,.X)
									case CAP_MYSTERY
										dim as single Effects = rnd
										if Effects < .05 then
											capsuleMessage("MYSTERY CAPSULE: Gradual Reduction",1)
											PaddleAdjust = -1
											playClip(SFX_POWER_DOWN,.X)
										elseif Effects < .15 then
											capsuleMessage("MYSTERY CAPSULE: Mega Reduce! Size = "+str(MinSize)+" pixels",1)
											renderPaddle(MinSize)
											forceReleaseBalls
											playClip(SFX_POWER_DOWN,.X)
										elseif Effects < .35 then
											renderPaddle(PaddleSize - 100)
											if PaddleSize < MinSize then
												renderPaddle(MinSize)
											end if
											forceReleaseBalls
											capsuleMessage("MYSTERY CAPSULE: Super Reduce! Size -100 = "+str(PaddleSize)+" pixels",1)
											playClip(SFX_POWER_DOWN,.X)
										elseif Effects < .4 then
											capsuleMessage("MYSTERY CAPSULE: Gradual Expansion",1)
											PaddleAdjust = 1
											playClip(SFX_POWER_UP,.X)
										elseif Effects < .6 then
											if PaddleSize < MinSize then
												renderPaddle(MinSize)
											end if
											renderPaddle(PaddleSize + 100)
											if PaddleSize > MaxSize then
												renderPaddle(MaxSize)
											end if
											forceReleaseBalls
											capsuleMessage("MYSTERY CAPSULE: Super Expand! Size +100 = "+str(PaddleSize)+" pixels",1)
											playClip(SFX_POWER_UP,.X)
										elseif Effects < .7 then
											dim as ubyte TotalNew = 0, Splitted(NumBalls)
											capsuleMessage("MYSTERY CAPSULE: Quad Split",1)
											forceReleaseBalls
											for BID as short = 1 to NumBalls
												with Ball(BID)
													if .Speed > 0 AND Splitted(BID) = 0 AND .Power <> -2 then
														TotalNew = 0
														for NewBall as short = 1 to 100
															with Ball(NewBall)
																if .Speed <= 0 then
																	TotalNew += 1
																	Splitted(NewBall) = 1
																	.Speed = int(Ball(BID).Speed)
																	.X = Ball(BID).X
																	.Y = Ball(BID).Y
																	.Spawned = 0
																	.Power = Ball(BID).Power
																	.Duration = Ball(BID).Duration
																	.Angle = Ball(BID).Angle + 90 * TotalNew
																	TotalBC += 1
																	if TotalNew >= 3 then
																		exit for
																	end if
																end if
															end with
														next
													end if
												end with
											next BID
											erase Splitted
											playClip(SFX_POWER_UP,.X)
										elseif Effects < .725 then
											dim as ubyte Splitted(NumBalls)
											capsuleMessage("MYSTERY CAPSULE: Split Deluxe",1)
											forceReleaseBalls
											ContinuousSplit = 1
											for BID as short = 1 to NumBalls
												with Ball(BID)
													if .Speed > 0 AND Splitted(BID) = 0 AND .Power <> -2 then
														for NewBall as short = 1 to 100
															with Ball(NewBall)
																if .Speed <= 0 then
																	Splitted(NewBall) = 1
																	.Speed = int(Ball(BID).Speed)
																	.X = Ball(BID).X
																	.Y = Ball(BID).Y
																	.Spawned = 0
																	.Power = Ball(BID).Power
																	.Duration = Ball(BID).Duration
																	.Angle = Ball(BID).Angle + 90
																	TotalBC += 1
																	exit for
																end if
															end with
														next
													end if
												end with
											next BID
											erase Splitted
											playClip(SFX_POWER_UP,.X)
										elseif Effects < .75 then
											capsuleMessage("MYSTERY CAPSULE: Deep Freeze!",1)
											Paddle(1).Blizzard = 3600
											FreezeStr = 60
											playClip(SFX_POWER_UP,.X)
										elseif Effects < .85 AND (Gamestyle AND (1 SHL STYLE_BOSS)) = 0 then
											capsuleMessage("MYSTERY CAPSULE: Random ball damage!",1)
											for BID as short = 1 to NumBalls
												with Ball(BID)
													if .Speed > 0 AND .Power >= -1 then
														.Power = irandom(1,4)
														if .Power < 2 then
															.Power -= 2
														end if
														.Duration = 20*60
													end if
												end with
											next BID
											forceReleaseBalls
											playClip(SFX_BRICKS_RESPAWN,.X)
										elseif Effects < .85 AND PaddleHealth < 97 * 60 then
											capsuleMessage("MYSTERY CAPSULE: Full repair!",1)
											PaddleHealth = 110 * 60
											playClip(SFX_POWER_UP,.X)
										else
											capsuleMessage("MYSTERY CAPSULE: No effect",1)
											playClip(SFX_INVINCIBLE,.X)
										end if
										InstructExpire = timer + 10
									case CAP_EXTENDER
										dim as byte ExtraLen = 15
										capsuleMessage("EFFECT EXTENDER: Timed effects last 0:"+str(ExtraLen)+" longer")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Duration > 0 AND .Power > -2 then
													.Duration += ExtraLen*60
												end if
												if .Gravity > 0 then
													.Gravity += ExtraLen*60
												end if
											end with
										next FID
										with Paddle(1)
											if .Grabbing > 0 then
												.Grabbing += ExtraLen*60
											end if
											if .Sluggish > 0 then
												.Sluggish += ExtraLen*60
											end if
											if .Repairs > 0 then
												.Repairs += ExtraLen*60
											end if
											if .Reverse > 0 then
												.Reverse += ExtraLen*60
											end if
											if .Blizzard > 0 then
												.Blizzard += ExtraLen*60
											end if
										end with
										playClip(SFX_POWER_UP,.X)
									case CAP_NEGATER
										capsuleMessage("EFFECT NEGATER: Timed effects ended early")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Power > -2 then
													.Duration = 0
													.Power = 0
												end if
												.Gravity = 0
											end with
										next FID
										with Paddle(1)
											.Grabbing = 0
											.Sluggish = 0
											.Repairs = 0
											.Reverse = 0
											.Blizzard = 0
										end with
										forceReleaseBalls
										playClip(SFX_POWER_DOWN,.X)
									case CAP_WEAK
										capsuleMessage("WEAKENED BALLS: Ball damage is temporarily inconsistent",-1)
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Power <> -2 then
													if .Power <= 0 then
														.Power = -1
													else
														.Power = 0
													end if
													.Duration = max(60^2/4,.Duration)
												end if
											end with
										next FID
										forceReleaseBalls
										playClip(SFX_POWER_DOWN,.X)
									case CAP_FIRE
										capsuleMessage("FIRE BALLS: Explosive damage")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Power <> -2 then
													if .Power = 2 then
														.Duration += 60^2/3
													elseif .Power = 4 then
														.Duration += 60^2/6
													else
														if .Power = 3 then
															.Power = 4
														else
															.Power = 2
														end if
														.Duration = 60^2/3
													end if
												end if
											end with
										next FID
										forceReleaseBalls
										playClip(SFX_POWER_UP,.X)
									case CAP_THRU
										capsuleMessage("BREAKTHRU BALLS: Balls do not bounce off of bricks")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Power <> -2 then
													if .Power = 3 then
														.Duration += 60^2/3
													elseif .Power = 4 then
														.Duration += 60^2/6
													else
														if .Power = 2 then
															.Power = 4
														else
															.Power = 3
														end if
														.Duration = 60^2/3
													end if
												end if
											end with
										next FID
										forceReleaseBalls
										playClip(SFX_POWER_UP,.X)
									case CAP_GRAVITY
										capsuleMessage("GRAVITY BALLS: Balls temporarily curve towards the paddle")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Power <> -2 then
													.Gravity = max(.Gravity,900)
												end if
											end with
										next FID
										forceReleaseBalls
										playClip(SFX_POWER_DOWN,.X)
									case CAP_MAXIMIZE
										capsuleMessage("MAXIMUM BALL SPEED!!! Brace yourself!")
										for FID as short = 1 to NumBalls
											with Ball(FID)
												if .Speed > 0 AND .Power <> -2 then
													.Speed = min(max(BaseMaxSpeed,.Speed + 2),BaseMaxSpeed + 2)
												end if
											end with
										next FID
										playClip(SFX_POWER_DOWN,.X)
									case CAP_GRAB
										capsuleMessage("GRABBING PADDLE",-1)
										Paddle(1).Grabbing += 1800
										playClip(SFX_POWER_UP,.X)
									case CAP_SLOW_PAD
										capsuleMessage("SLOW PADDLE")
										Paddle(1).Sluggish = max(Paddle(1).Sluggish,900)
										playClip(SFX_POWER_DOWN,.X)
									case CAP_WEP_BULLET
										capsuleMessage("BULLET PADDLE: Ammo that deals normal damage")
										PlayerSlot(Player).BulletAmmo += 100
										PlayerSlot(Player).MissileAmmo = 0
										playClip(SFX_POWER_UP,.X)
									case CAP_WEP_MISSILE
										capsuleMessage("MISSILE PADDLE: Ammo that deals explosive damage")
										PlayerSlot(Player).MissileAmmo += 10
										PlayerSlot(Player).BulletAmmo = 0
										playClip(SFX_POWER_UP,.X)
									case CAP_REVERSE
										capsuleMessage("REVERSE PADDLE")
										with Paddle(1)
											if .Reverse = 0 then
												if ControlStyle <= CTRL_LAPTOP then
													MouseX = 1024 - MouseX
													setmouse(MouseX,MouseY)
												elseif ControlStyle = CTRL_TABLET then
													HoldClick = 0
													TapWindow = 0
												end if
											end if
											
											.Reverse = max(.Reverse,900)
										end with
										playClip(SFX_POWER_DOWN,.X)
									case CAP_SPREAD
										dim as ubyte AlreadySpread(40,20)
										capsuleMessage("SPREAD EXPLODING",-1)
										for YID as byte = 1 to 20
											for XID as byte = 1 to 20*(CondensedLevel+1)
												with PlayerSlot(Player).TileSet(XID,YID)
													if Pallete(.BrickID).HitDegrade < 0 AND AlreadySpread(XID,YID) = 0 then
														AlreadySpread(XID,YID) = 1
		
														for YDID as byte = YID - 1 to YID + 1
															for XDID as byte = XID - 1 to XID + 1
																if XDID > 0 AND XDID <= 20*(CondensedLevel+1) AND _
																	YDID > 0 AND YDID <= 20 AND _
																	abs(XDID-XID) + abs(YDID-YID) = 1 AND _
																	Pallete(PlayerSlot(Player).TileSet(XDID,YDID).BrickID).HitDegrade >= 0 then
																	AlreadySpread(XDID,YDID) = 1
																	PlayerSlot(Player).TileSet(XDID,YDID).BrickID = PlayerSlot(Player).TileSet(XID,YID).BrickID
																	if PlayerSlot(Player).TileSet(XDID,YDID).BaseBrickID = 0 then
																		PlayerSlot(Player).TileSet(XDID,YDID).BaseBrickID = ZapBrush
																	end if
																end if
															next XDID
														next YDID
													elseif .BrickID = 0 AND (GameStyle AND (1 SHL STYLE_FUSION)) then
														.BaseBrickID = 0
													end if
												end with
											next XID
										next YID
										
										for YID as byte = 1 to 20
											for XID as byte = 1 to 20*(CondensedLevel+1)
												if AlreadySpread(XID,YID) then
													damageBrick(XID,YID,PlayerSlot(Player).TileSet(XID,YID).BrickID)
												end if
											next XID
										next YID
										erase AlreadySpread
										playClip(SFX_POWER_UP,.X)
									case CAP_DETONATE
										capsuleMessage("DETONATE EXPLODING",-1)
										for YID as ubyte = 1 to 20
											for XID as ubyte = 1 to 20*(CondensedLevel+1)
												with Pallete(PlayerSlot(Player).TileSet(XID,YID).BrickID)
													if .HitDegrade < 0 then
														PlayerSlot(Player).TileSet(XID,YID).BrickID = -1 + (.HitDegrade + 1) * 100
													end if
												end with
											next XID
										next YID
										playClip(SFX_POWER_UP,.X)
									case CAP_WARP
										capsuleMessage("WARP LEVEL")
										if LevelClear < 1 then
											LevelClear = 1
										end if
										playClip(SFX_POWER_UP,.X)
									case CAP_GEM_R, CAP_GEM_G, CAP_GEM_B, CAP_GEM_Y, CAP_GEM_P, CAP_GEM_C, CAP_GEM_W
										dim as string GemType, HandScored
										dim as byte GemsCollected = 1
										dim as short GemMultiplier = 0
										if .Angle = CAP_GEM_R then
											GemType = "RUBY"
										elseif .Angle = CAP_GEM_G then
											GemType = "EMERALD"
										elseif .Angle = CAP_GEM_B then
											GemType = "SAPPHIRE"
										elseif .Angle = CAP_GEM_Y then
											GemType = "TOPAZ"
										elseif .Angle = CAP_GEM_P then
											GemType = "AMETHYST"
										elseif .Angle = CAP_GEM_C then
											GemType = "TURQUOISE"
										elseif .Angle = CAP_GEM_W then
											GemType = "DIAMOND"
										end if
										
										for HandID as byte = 1 to 5
											if PlayerSlot(Player).PokerHand(HandID) > 0 then
												GemsCollected += 1
											end if
										next HandID
										if GemsCollected > 5 then
											emptyHand(Player)
											GemsCollected = 1
											renderHand
										elseif GemsCollected = 1 then
											renderHand
										end if
										
										PlayerSlot(Player).PokerHand(GemsCollected) = .Angle - CAP_GEM_R + 1
										if GemsCollected = 5 then
											GemMultiplier = score_hand
										end if
										renderHand(GemsCollected)
										RecalcGems = 1
										
										if GemMultiplier = 0 then
											capsuleMessage(GemType+" GEM collected",-1)
											playClip(SFX_HARDEN,.X)
										else
											PlayerSlot(Player).Score += BaseCapsuleValue * GemMultiplier
											
											if GemMultiplier = 50 then
												HandScored = "Five of a Kind!"
											elseif GemMultiplier = 35 then
												HandScored = "Four of a Kind"
											elseif GemMultiplier = 25 then
												HandScored = "Full House"
											elseif GemMultiplier = 10 then
												HandScored = "Three of a Kind"
											elseif GemMultiplier = 5 then
												HandScored = "Two Pair"
											end if
											
											capsuleMessage(GemType+" GEM collected: Bonus "+str(BaseCapsuleValue * GemMultiplier)+" for completing a "+HandScored)
											playClip(SFX_POWER_UP,.X)
											emptyHand(Player)
										end if
								end select
								
								PaddleHealth += 180
							
								PlayerSlot(Player).Score += BaseCapsuleValue
								BonusPts += BaseCapsuleValue
							elseif PaddleID = 1 then
								.Y += .Speed * (SpeedMod / 100) 
								.Speed += 3 / 32
								if .Speed > ActiveDifficulty * 1.5 then
									.Speed = ActiveDifficulty * 1.5
								end if
							end if
						next PaddleID
					end if
				end if
			end with
		next CapID

		with PlayerSlot(Player)
			if .Score >= .Threshold AND .Threshold > 0 AND .Lives > 0 AND LevelClear = 0 then
				if SubsequentExtraLives > 0 then
					if CampaignFolder = EndlessFolder then
						.Threshold *= 2
					else
						.Threshold += SubsequentExtraLives
					end if
					
					Instructions = "Extra life earned - Next life at "+commaSep(.Threshold)+" points"
				else
					.Threshold = 0
					Instructions = "Extra life earned"
				end if
				playClip(SFX_LIFE)
				.Lives += 1
				InstructExpire = timer + 10
			end if
		
			if CampaignBarrier then
				if .Lives > 10 then
					.Lives = 10
					Instructions = "Life limit exceeded!"
					InstructExpire = timer + 7
				end if
			else
				if .Lives > 9 then
					.Lives = 9
					Instructions = "Life limit exceeded!"
					InstructExpire = timer + 7
				end if
			end if
		end with

		if total_lives <= 0 AND ProhibitSpawn = 0 then
			if multikey(SC_TAB) then
				auxillaryView(InstruAlpha, InstruBeta)
			end if

			setmouse(,,0,0)
			releaseMusic
			Paddle(1).Blizzard = 0
			Paddle(1).Grabbing = 0
			if ucase(InType) >= "A" AND ucase(InType) <= "Z" AND PlayerSlot(0).Difficulty < 6.5 AND ShuffleLevels = 0 AND CampaignName <> PlaytestName then
				InPassword = right(InPassword,7) + ucase(InType)
			end if
			
			if InType = FunctionFour AND PlayerSlot(0).Difficulty < 6.5 AND ShuffleLevels = 0 AND CampaignFolder <> EndlessFolder AND CampaignName <> PlaytestName then
				InPassword = levelList
				FrameTime = timer
			end if

			if InPassword <> "--------" then
				Instructions = "Password: "+InPassword+" (Push 0-"+str(MaxPlayers)+" when done)"
				InstructExpire = timer + 1
				
				for PID as ubyte = 0 to MaxPlayers
					if InType = str(PID) then
						NumPlayers = PID
						PassInput = 1
						exit for
					end if
				next PID
				
				if PassInput = 1 then
					PassInput = 0
					dim as string ActualPassword
					dim as short TestNum = 2, Result
					do
						ActualPassword = checkLevel(TestNum)
						if (ActualPassword = InPassword AND InPassword <> "++++++++") then
							beginLocalGame(NumPlayers, TestNum)

							Instructions = "Password successful"
							InstructExpire = timer + 5
							exit do
						end if

						TestNum += 1
					loop until ActualPassword = ""

					InPassword = "--------"
					Phase = 0
				end if
			else
				for HID as ubyte = 0 to NumHints
					GameHints(HID) = abs(sgn(HintLevel < 3)) * 8
				next HID
				if NumPlayers > 1 then
					MPAlternate += 1
					if MPAlternate >= 400 then
						MPAlternate = 0
						transferControl(1)
					end if
				end if
				
				if PlayerSlot(0).Difficulty < 6.5 AND ShuffleLevels = 0 AND CampaignFolder <> EndlessFolder AND CampaignName <> PlaytestName AND Phase <> 0 then
					Instructions = "Push F4 to open the level screen"
				else
					Instructions = "Push 0-"+str(MaxPlayers)+" to start a new campaign with that many players"
				end if
				InstructExpire = timer + 1
			end if
		end if

		if GameHints(1) = 0 AND Ball(1).Speed >= 9 AND Ball(1).Speed < 10 then
			Instructions = "The ball speeds up automatically on its own"
			InstructExpire = timer + 10
			GameHints(1) = 1
		elseif GameHints(2) = 0 AND TotalBC > 2 then
			Instructions = "The more you juggle, the more points you earn."
			InstructExpire = timer + 10
			GameHints(2) = 1
		elseif total_lives > 0 AND GameHints(4) = 0 AND PlayerSlot(Player).WarpTimer < 3540 then
			Instructions = "When three breakable blocks remain, a warp timer starts"
			InstructExpire = timer + 10
			GameHints(4) = 1
		elseif TotalBC > 0 AND GameHints(0) < 1 then
			GameHints(0) = 1
		end if

		if CampaignBarrier then
			if AboveLine = 0 AND TotalBC > 0 AND BarrierStrength > 0 AND GamePaused = 0 then
				with PlayerSlot(Player)
					for BID as short = 1 to NumBalls
						with Ball(BID)
							if .Speed > 0 AND .Power >= -1 then
								.Angle = -.Angle
								.LHX = 0
								.LHY = 0
								.Spawned = 0
								.Invul = 0
								
								'Negate Gravity Balls, and cap Weakened balls to 3 seconds
								.Gravity = 0
								if .Power = -1 then
									.Duration = min(.Duration,180)
								end if
								
								if int(.Speed) > 14 then
									.Speed = 12
								elseif int(.Speed) > 12 then
									.Speed -= 2.2
								elseif int(.Speed) > 8 then
									.Speed -= 1.2
								elseif .Speed > 6.2 then
									.Speed -= .2
								end if
							end if
						end with
					next BID
					
					'Cap Slow Paddle and Reverse Paddle to just 3 seconds
					Paddle(1).Sluggish = min(Paddle(1).Sluggish,180)
					Paddle(1).Reverse = min(Paddle(1).Reverse,180)
					
					.Lives -= 1
					playClip(SFX_POWER_DOWN)
					PaddleHealth += 50 * 60
					.PerfectClear = 0
	
					if .Lives < 2 AND GameHints(3) < 2 then
						GameHints(3) = 2
						Instructions = "Once the barrier is broken, the game ends upon ball drain"
						InstructExpire = timer + 10
					elseif GameHints(3) = 0 then
						GameHints(3) = 1
						Instructions = "The barrier weakens every time it is used to rebound"
						InstructExpire = timer + 10
					end if

					if ProgressiveQuota < 4 then
						ProgressiveQuota += 2
					elseif ProgressiveQuota < 8 then
						ProgressiveQuota += 1
					end if
	
					if PaddleSize < MinSize then
						renderPaddle(MinSize)
					end if
					if PaddleSize < StandardSize - 40 then
						renderPaddle(PaddleSize + 40)
					elseif PaddleSize < StandardSize then
						renderPaddle(StandardSize)
					end if
				end with
			else
				'Kill off any balls that did not make their way back
				for BID as short = 1 to NumBalls
					with Ball(BID)
						if sin(degtorad(.Angle)) < 0 AND .Speed > 0 AND .Y > 768 + BallSize then
							.X = 320
							.Y = -10
							.Speed = 0
							.Gravity = 0
							TotalBC -= 1
							exit for
						end if
					end with
				next BID
			end if
		end if

		if InstruAlpha >= 320 then
			InstruAlpha = -320
		elseif InstruAlpha = 0 AND timer < InstructExpire then
			Phase = 1 - Phase
		elseif InstruAlpha = 0 OR Instructions = "" then
			InstruAlpha = 0
			Instructions = ""

			if GameHints(0) = 0 then
				GameHints(0) = 1
				select case ControlStyle
					case CTRL_AI
						Instructions = "The computer will automatically play this game"
					case CTRL_DESKTOP
						Instructions = "Perform [ACTION] (Click) to release a ball"
					case CTRL_LAPTOP, CTRL_KEYBOARD
						Instructions = "Perform [ACTION] (Spacebar) to release a ball"
					case CTRL_TABLET
						Instructions = "Perform [ACTION] (Double Tap) to release a ball"
					case else
						if JoyAnalog = 0 then
							Instructions = "Perform [ACTION] (Button "+str(JoyKeySetting)+") to release a ball"
						else
							Instructions = "Perform [ACTION] (Any Button) to release a ball"
						end if
				end select
				InstructExpire = timer + 10
			elseif GameHints(0) < 9 AND ControlStyle = CTRL_AI then
				GameHints(0) = 9
				Instructions = "Fair warning; the computer will neither give you stars nor new passwords!"
				InstructExpire = timer + 10
			elseif GameHints(4) = 1 AND PlayerSlot(Player).WarpTimer < 3540 then
				Instructions = "The level is considered cleared once time expires"
				InstructExpire = timer + 10
				GameHints(4) = 2
			elseif GameHints(4) = 2 AND PlayerSlot(Player).WarpTimer < 1740 then
				Instructions = "Below 0:30, further hits increase the warp timer"
				InstructExpire = timer + 10
				GameHints(4) = 3
			elseif LevelDesc = 0 AND HintLevel >= 2 AND len(LevelDescription) > 0 then
				LevelDesc = 1
				Instructions = LevelDescription
				InstructExpire = timer + 4 + len(LevelDescription)/10
 			end if
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
		
		gfxstring(Instructions,512-gfxlength(Instructions,5,3,3)/2,740,5,3,3,rgba(255,255,255,InstruGamma),rgba(255,255,255,InstruBeta))
		if (total_lives = 0 AND InPassword = "--------") OR timer > InstructExpire OR abs(InstruAlpha) < 320 then
			InstruAlpha += 4
		end if

		if SpeedMod < 100 then
			line(0,0)-(1023,767),rgba(128,128,255,(100-SpeedMod)/100*255),bf
		end if
		screencopy
		while timer < FrameTime + 1/60
			if Command(1) = "-k" then
				sleep 1
			end if
		wend
		InType = inkey
		if total_lives = 0 then
			for PID as ubyte = 0 to MaxPlayers
				if InType = str(PID) AND InPassword = "--------" then
					beginLocalGame(PID, 1)
					
					Instructions = ""
					InstructExpire = timer
				end if
			next PID
			
		elseif (ControlStyle = CTRL_AI OR actionButton) AND ProhibitSpawn = 0 then
			with Ball(1)
				if ActiveDifficulty >= 3.5 then
					.Speed = DefaultSpeed - irandom(0,30) / 100 
				else
					.Speed = MinSpeed
				end if
				.Y = 384
				.X = irandom(100,924)
				.Spawned = 1
				.Grabbed = 0
				.Duration = 0
				.Gravity = 0
				.Angle = irandom(210,330)
				TotalBC += 1
				ProhibitSpawn = 1
			end with
		end if
		
		if InType = FunctionFive AND total_lives > 0 then
			#IFDEF __USE_FBSOUND__
			MusicPlrEnabled = 1 - MusicPlrEnabled
			
			if MusicPlrEnabled then
				Instructions = "Music player activated"
				rotateMusic
			else
				Instructions = "Music player disabled"
				releaseMusic
			end if
			InstructExpire = timer + 5
			#ENDIF
		elseif InType = FunctionSeven then
			toggle_fullscreen
			if total_lives > 0 AND LevelClear = 0 then
				GamePaused = 1
			end if
			LastPlayed = timer
			FrameTime = timer
		elseif InType = FunctionTwelve then
			playClip(SFX_BRICKS_RESPAWN)
			bsave("screen"+str(ShotIndex)+".bmp",0)
			ShotIndex += 1
		end if

		if (BrickCount = 0 AND PlayerSlot(Player).Lives > 0) AND LevelClear = 0 then
			LevelClear = 1
		end if
		
		if LevelClear >= LevelClearDelay AND actionButton then
			if ControlStyle >= CTRL_DESKTOP then 
				setmouse(,,0,1)
			end if
			LevelClear = 0
			
			dim as ubyte InPlay
			destroyAmmo
			destroyCapsules
			
			with PlayerSlot(Player)
				if .Lives < StartingLives AND .Difficulty < 3.5 AND CampaignFolder <> EndlessFolder then
					.Lives += 1
				end if
				.LevelNum += 1
				.PerfectClear = 1
				.GameOverCombo = 0
				ProhibitSpawn = 0
				LevelDesc = 0

				for BID as short = 1 to NumBalls
					if Ball(BID).Speed > 0 then
						InPlay = 1
						exit for
					end if
				next BID
				destroyBalls
				
				if .LevelNum >= SecretLevels AND HighLevel < SecretLevels AND SecretLevels > 0 then
					playClip(SFX_EXPLODE)
					if DQ = 0 then
						highScoreInput(Player)
						if ControlStyle >= CTRL_DESKTOP then
							TotalXP += int(.Score * .Difficulty)
							if FileExists(CampaignName+".flag") = 0 then
								'Intentionally empty victory file
								open CampaignName+".flag" for output as #21
								close #21
							end if
						end if
					end if
					emptyHand(Player)
	
					LastPlayed = timer
					FrameTime = timer
					.LevelNum -= 1
					.Lives = 0
					.SetCleared = 1
					saveConfig
				elseif checkLevel(.LevelNum) <> "" then
					Gamestyle = 0
					rotateBack
					loadLevel(.LevelNum)
					freshLevel(Player)
					Paddle(1).Sluggish = 0
					Paddle(1).Spawned = 0
				else
					playClip(SFX_LIFE)
					if DQ = 0 then
						highScoreInput(Player)
						if ControlStyle >= CTRL_DESKTOP then
							TotalXP += int(.Score * .Difficulty * 2)
							if FileExists(CampaignName+".flag") = 0 then
								'Just like before, only this is for a true victory
								open CampaignName+".flag" for output as #21
								close #21
							end if
						end if
					end if
					emptyHand(Player)
	
					LastPlayed = timer
					FrameTime = timer
					.SetCleared = 1
					.LevelNum -= 1
					.Lives = 0
					saveConfig
				end if
			end with
			transferControl
			generateCavity
		end if
		
		while PowerTick >= 100
			PowerTick -= 100
		wend
		
		if InType = chr(27) then
			if total_lives > 0 AND GamePaused = 0 then
				GamePaused = 1
			elseif total_lives > 0 AND CampaignName <> PlaytestName then
				PlayerSlot(Player).Lives = 1
				PlayerSlot(Player).GameOverCombo = -1
				ProhibitSpawn = 2
				if GameStyle AND (1 SHL STYLE_BONUS) then
					GameStyle -= 2^STYLE_BONUS
				end if
				destroyAmmo
				destroyBalls
				destroyCapsules
				GamePaused = 0
			else
				exit do
			end if
		elseif InType = XBox then
			exit do
		end if
	loop
	releaseMusic
	for PID as ubyte = 1 to MaxPlayers
		with PlayerSlot(PID)
			if .Lives > 0 AND DQ = 0 then
				TotalXP += int(.Score * .Difficulty)
				highScoreInput(PID,1)
			end if
		end with
	next PID
	if CampaignName <> PlaytestName AND CampaignFolder <> "community/misc" then
		if HighLevel > 1 then
			open CampaignName+".dat" for output as #2
			print #2, HighLevel
			close #2
		end if
	end if
	ControlStyle = SavedControls
	kill("Stats.dat")
	if InType = XBox then
		cleanUp
		saveConfig
		end 0
	end if
	erase EndlessShuffList
	setmouse(,,0,0)
end sub


