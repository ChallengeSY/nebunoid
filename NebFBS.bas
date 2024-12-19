enum SoundFX
	SFX_BRICK = 0
	SFX_EXPLODE
	SFX_HARDEN
	SFX_INVINCIBLE
	SFX_POWER_UP
	SFX_POWER_DOWN
	SFX_DEATH
	SFX_SHOOT_BULLET
	SFX_SHOOT_MISSILE
	SFX_LIFE
	SFX_BRICKS_RESPAWN
	SFX_WALL_BROKEN
	SFX_BALL
	SFX_WALL
	SFX_MAX
end enum

type MusicSpecs
	Filename as string
	Volume as integer
	Waveform as integer
	ErrorFound as byte = -1
end type

' FBSound addon
#include "fbthread.bi"
#include "fbsound_dynamic.bi"
dim shared as boolean loadOk
const clipCount = SFX_MAX - 1
const musCount = 32
dim shared as string data_path
data_path = MasterDir+"/sfx/"
dim shared as integer clipPause(clipCount), Flash, LoadColor, MusicIter, MusicActive
dim shared as byte StopPreload = 0
dim shared as any ptr PreloadLock, PreloadThread
dim as string SFXNames(clipCount), IntroMessage

dim shared as MusicSpecs PlaySlot(musCount)
dim shared as string MusList(musCount)

SFXNames(SFX_BRICK) = "brick"
SFXNames(SFX_EXPLODE) = "explode"
SFXNames(SFX_HARDEN) = "harden"
SFXNames(SFX_INVINCIBLE) = "invincible"
SFXNames(SFX_POWER_UP) = "powerup"
SFXNames(SFX_POWER_DOWN) = "powerdown"
SFXNames(SFX_DEATH) = "death"
SFXNames(SFX_SHOOT_BULLET) = "bullet"
SFXNames(SFX_SHOOT_MISSILE) = "missile"
SFXNames(SFX_LIFE) = "life"
SFXNames(SFX_BRICKS_RESPAWN) = "respawn"
SFXNames(SFX_WALL_BROKEN) = "wallBroken"
SFXNames(SFX_BALL) = "paddle"
SFXNames(SFX_WALL) = "wall"

declare sub cleanUp
declare sub shuffle_music
declare sub preloadMusic(ByVal InternalPtr as any ptr = 0)

screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
ScreenCreated = 1
screenset 1,0
TitleBanner = ImageCreate(281,60)
bload("gfx/banner.bmp",TitleBanner)

PreloadLock = MutexCreate

declare function word_wrap(Text as string) as string
declare function irandom(Minimum as integer, Maximum as integer) as integer

if fbs_Init(44100,2) = FALSE then
	open "stderr.txt" for output as #1
	print #1, "Unable to initialize audio!"
	close #1
	cleanUp
	end 1
end if

put (371,10),TitleBanner,trans
locate 6,1
if PreloadLock = 0 then
	print "Note: Multi-Thread loading unsuccessful. Falling back to main thread to pre-load songs."
	print
else
	print "Preloading sounds..."
	screencopy
end if

dim shared as integer clipWave(clipCount), musicPlr

for PID as short = 0 to clipCount
	loadOk = fbs_Load_WAVFile(data_path & "modern/" & SFXNames(PID) & ".wav",@clipWave(PID))
	if loadOk = FALSE then
		print "Erorr! Unable to load clip ";PID
		screencopy
		sleep
		cleanUp
		end 1
	end if
next PID

dim shared as short MusicLoaded = 0, MusicSuccess = 0, WarningsFound, TrackerVol, OtherMusVol
dim as string MusicFile

if Command(1) <> "-s" then
	'MP3 files
	MusicFile = dir(data_path+"/mus/*.mp3",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
	'OGG files
	MusicFile = dir(data_path+"/mus/*.ogg",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
	
	'Tracker files
	MusicFile = dir(data_path+"/mus/*.mod",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
	MusicFile = dir(data_path+"/mus/*.it",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
	MusicFile = dir(data_path+"/mus/*.xm",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
	MusicFile = dir(data_path+"/mus/*.s3m",fbNormal)
	while MusicFile <> ""
		MusList(MusicLoaded) = MusicFile
		MusicLoaded += 1
		if MusicLoaded > musCount then exit while
		MusicFile = dir()
	wend
end if

shuffle_music

open "sfx/mus/Settings.txt" for input as #2
input #2, NullString, OtherMusVol
input #2, NullString, TrackerVol
close #2

if Command(1) = "-k" then
	ReservedMB = valint(Command(2)) * 1e6	
end if

if PreloadLock = 0 then
	'No multi-thread, just pre-load the old way
	preloadMusic

	if WarningsFound > 0 then
		print "Some songs could not be loaded. Offending songs will be ignored in the playlist."
	end if
	
	while inkey <> "":wend
	if Command(1) <> "-l" then
		do
			Flash += 3
			if Flash >= 192 then
				Flash = -192
			end if
			
			if WarningsFound > 0 then
				LoadColor = rgb(abs(Flash),abs(Flash),0)
			else
				LoadColor = rgb(0,abs(Flash),0)
			end if
			IntroMessage = "Press any key to continue..."
			
			line (197,742)-(634,762),rgb(0,abs(Flash),0),bf
			gfxstring(IntroMessage,512-gfxlength(IntroMessage,3,3,2)/2,745,3,3,2,rgb(255,255,255))
			screencopy
			sleep 15
		loop until inkey <> ""
	end if
else
	'Success! Create a thread and go straight to main menu!
	PreloadThread = ThreadCreate(@preloadMusic)
end if

sub preloadMusic(ByVal InternalPtr as any ptr = 0)
	dim as any ptr LoadingBar

	if PreloadLock = 0 then
		LoadingBar = ImageCreate(640,31)
		bload("gfx/meter.bmp",LoadingBar)
		
		put (192,737),LoadingBar,pset
		screencopy
	end if
	
	kill("music.log")
	
	for Stream as short = 0 to MusicLoaded - 1
		if StopPreload then
			'Stop this process early, e.g. to close the program
			MusicLoaded = Stream
			exit for
		elseif fre < ReservedMB then
			'Stop further pre-loading to conserve RAM
			MusicLoaded = Stream
			exit for
		end if
		
		with PlaySlot(Stream)
			if right(.Filename,4) = ".ogg" then
				loadOk = fbs_Load_OGGFile(data_path & "mus/" & .Filename,@.Waveform)
				.Volume = OtherMusVol
			elseif right(.Filename,4) = ".mp3" then
				loadOk = fbs_Load_MP3File(data_path & "mus/" & .Filename,@.Waveform)
				.Volume = OtherMusVol
			else
				loadOk = fbs_Load_ModFile(data_path & "mus/" & .Filename,@.Waveform)
				.Volume = TrackerVol
			end if
			if loadOk = FALSE then
				WarningsFound += 1
				.ErrorFound = 1
				open "music.log" for append as #13
				print #13, .Filename + " could not be loaded."
				close #13
			else
				.ErrorFound = 0
				MusicSuccess += 1
			end if
			
			if PreloadLock = 0 then
				line LoadingBar,(5,5)-(5+(Stream+1)/MusicLoaded*629,25),rgb(0,192,0),bf
				put (192,737),LoadingBar,pset
				screencopy
			end if
		end with
		if Stream >= 0 AND Command(1) = "-l" then
			MusicLoaded = 1
			exit for
		end if
	next Stream
	
	if MusicSuccess = 0 then
		MusicLoaded = 0
	end if
	if PreloadLock = 0 then
		ImageDestroy(LoadingBar)
	end if
end sub

sub shuffle_music
	randomize timer

	dim as byte SlotUsed(musCount)
	dim as short UseSlot
	for Stream as short = 0 to MusicLoaded - 1
		do
			UseSlot = int(rnd * MusicLoaded)
		loop until SlotUsed(UseSlot) = 0
		
		PlaySlot(UseSlot).Filename = MusList(Stream)
		SlotUsed(UseSlot) = 1
	next Stream
	
	MusicIter = irandom(0,MusicLoaded-1)
	erase SlotUsed
end sub

sub playClip(ID as byte, Panning as short = 512, HertzMod as short = 100)
	if ID >= 0 then
		dim as ubyte PauseLength(0 to clipCount)
		for clipID as ubyte = 0 to clipCount
			PauseLength(clipID) = 1
		next clipID
		if clipPause(ID) = 0 then
			clipPause(ID) = PauseLength(ID)
			fbs_Play_Wave(clipWave(ID),,HertzMod/100,,(Panning-512)/512)
		end if
	end if
end sub
function convertSpeed(InSpeed as double) as short
	return 100+(int(InSpeed)-8)*5
End Function
sub dynamicSpeedClip(BallSpeed as double, Panning as short = 512)
	playClip(SFX_BALL,Panning,convertSpeed(BallSpeed))
end sub
sub decrementPauses
	for ID as ubyte = 0 to clipCount
		if clipPause(ID) > 0 then
			clipPause(ID) -= 1
		end if
	next ID
end sub

sub releaseMusic
	if MusicActive then
		fbs_Destroy_Sound(@musicPlr)
		MusicActive = 0
	end if
end sub
sub rotateMusic
	if MusicPlrEnabled AND (MusicLoaded > 1 OR (MusicActive = 0 AND MusicLoaded > 0)) then
		releaseMusic
		
		do
			MusicIter += 1
			if MusicIter >= MusicLoaded then
				MusicIter = 0
			end if
		loop until PlaySlot(MusicIter).ErrorFound = 0 OR MusicSuccess = 0
		
		with PlaySlot(MusicIter)
			if .ErrorFound = 0 then
				fbs_Play_Wave(.Waveform,-1,1,.Volume/100,0,@musicPlr)
				MusicActive = 1
			end if
		end with
	end if
end sub
