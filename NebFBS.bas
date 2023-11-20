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
	ErrorFound as byte = 0
end type

' FBSound addon

dim as string LoadingTips(8) => {_
	"On Easy and below, one life is added to the player's stock upon completing a level if they are below the starting number of lives.", _
	"If a ball becomes stuck for a long period of time without making irreversible progress to the level, that ball will become metallic. Metallic balls will destroy any blocks in one hit.\n\nOn Very Easy, balls are metallic by default, making many levels that would otherwise be challenging trivial.", _
	"Powerup capsules with timed effects can be picked up multiple times, and the new capsule will add its duration to an existing duration of the same kind. This does not apply to powerdown capsules with timed effects.\n\nAdditionally, if a Fire Balls capsule is picked up while Breakthru Balls is active (or vise versa), then they combine to create Lightning Balls, which will reset the powerup timer. At that point, further extensions can be granted by picking up Fire Balls OR Breakthru Balls, at half the normal rate.", _
	"The Weakened Balls capsule serves two purposes. It will weaken balls that are not currently powered up (chance to sometimes not damage a brick that is hit), and will negate any powers of balls that are powered up.", _
	"Paddles are not allowed both bullet and missile ammunitions. Picking up a capsule that grants ammo for one kind of weapon will zero out the other weapon's ammo.", _
	"While the Extra Life capsule is normally Very Rare (gold background), it has a slightly higher appearance rate (equivalent to purple Rare) if the player is on their last life, and will not appear at all if the player already has maximum lives.", _
	"The Level Select system (F4) makes it easy to start a new game at any previously reached level, virtually eliminating the need to remember passwords. This system is not available on higher difficulties, mainly to prevent brute forcing.\n\nThe password system still has a devious use though. Secret levels are not available, until their secret has been uncovered (only initially available via password).", _
	"The Shuffle Levels option shuffles most levels in a campaign, at the expense of being unable to start a level from a password. The system neither shuffles fatal levels, nor will it touch locked secret levels. The highest level reached in each campaign is still saved (and complimented with stars and passwords), for when this option is switched off.", _
	"A Grabbing Paddle will automatically release each held ball after 5 seconds, mitigating the ability to score lots of points simply because there are a lot of balls in play. Several capsules cause balls to be released early."}

#include "fbsound_dynamic.bi"
dim as boolean loadOk
const clipCount = SFX_MAX - 1
const musCount = 32
dim shared as string data_path
data_path = MasterDir+"/sfx/"
dim shared as integer clipPause(clipCount), Flash, LoadColor, MusicIter, MusicActive
dim as string SFXNames(clipCount), IntroMessage
dim as any ptr LoadingBar

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

declare sub clean_up
declare sub shuffle_music

screen 20,24,2,GFX_ALPHA_PRIMITIVES OR GFX_NO_SWITCH
ScreenCreated = 1
screenset 1,0
TitleBanner = ImageCreate(281,60)
bload("gfx/banner.bmp",TitleBanner)

put (40,10),TitleBanner,trans
declare function word_wrap(Text as string) as string
declare function irandom(Minimum as integer, Maximum as integer) as integer

locate 6,1
print word_wrap("Tip: "+LoadingTips(irandom(0,ubound(LoadingTips))))
print

screencopy

LoadingBar = ImageCreate(640,31)
line LoadingBar,(0,0)-(639,30),rgb(0,0,0),bf
line LoadingBar,(0,0)-(639,0),rgb(255,255,255)
line LoadingBar,(0,0)-(0,30),rgb(255,255,255)

for Thickness as byte = 1 to 3
	line LoadingBar,(Thickness,Thickness)-(639-Thickness,30-Thickness),rgb(128,128,255),b
next Thickness
line LoadingBar,(5,26)-(635,26),rgb(255,255,255)
line LoadingBar,(635,5)-(635,26),rgb(255,255,255)

if fbs_Init(44100,2) = FALSE then
	open "stderr.txt" for output as #1
	print #1, "Unable to initialize audio!"
	close #1
	clean_up
	end 1
end if

dim shared as integer clipWave(clipCount), musicPlr

for PID as short = 0 to clipCount
	loadOk = fbs_Load_WAVFile(data_path & "modern/" & SFXNames(PID) & ".wav",@clipWave(PID))
	if loadOk = FALSE then
		print "Erorr! Unable to load clip ";PID
		sleep
		clean_up
		end 1
	end if
next PID

put (192,737),LoadingBar,pset
screencopy

dim shared as short MusicLoaded = 0, WarningsFound, TrackerVol, OtherMusVol
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

for Stream as short = 0 to MusicLoaded - 1
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
		end if
		line LoadingBar,(5,5)-(5+(Stream+1)/MusicLoaded*629,25),rgb(0,192,0),bf
		put (192,737),LoadingBar,pset
		screencopy
	end with
	if Stream >= 0 AND Command(1) = "-l" then
		MusicLoaded = 1
		exit for
	end if
next Stream

if WarningsFound > 0 then
	print "Note: The following songs could not be loaded. Offending songs will be ignored in the playlist."
	for Stream as short = 0 to MusicLoaded - 1
		with PlaySlot(Stream)
			if .ErrorFound then
				print "- ";.Filename
			end if
		end with
	next Stream
end if

while inkey <> "":wend
if Command(1) <> "-l" then
	do
		Flash += 3
		if Flash >= 192 then
			Flash = -192
		end if
		
		line LoadingBar,(5,5)-(634,25),rgb(0,abs(Flash),0),bf
		if WarningsFound > 0 then
			LoadColor = rgb(abs(Flash),abs(Flash),0)
		else
			LoadColor = rgb(0,abs(Flash),0)
		end if
		IntroMessage = "Press any key to continue..."
		
		put (192,737),LoadingBar,pset
		gfxstring(IntroMessage,512-gfxlength(IntroMessage,3,3,2)/2,745,3,3,2,rgb(255,255,255))
		screencopy
		sleep 15
	loop until inkey <> ""
end if

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

sub play_clip(ID as byte, Panning as short = 512, HertzMod as short = 100)
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
function convert_speed(InSpeed as double) as short
	return 100+(int(InSpeed)-8)*5
End Function
sub dynamic_speed_clip(BallSpeed as double, Panning as short = 512)
	play_clip(SFX_BALL,Panning,convert_speed(BallSpeed))
end sub
sub decrement_pauses
	for ID as ubyte = 0 to clipCount
		if clipPause(ID) > 0 then
			clipPause(ID) -= 1
		end if
	next ID
end sub

sub release_music
	fbs_Destroy_Sound(@musicPlr)
	MusicActive = 0
end sub
sub rotate_music
	if MusicPlrEnabled AND (MusicLoaded > 1 OR (MusicActive = 0 AND MusicLoaded > 0)) then
		release_music
		
		do
			MusicIter += 1
			if MusicIter >= MusicLoaded then
				MusicIter = 0
			end if
		loop until PlaySlot(MusicIter).ErrorFound = 0
		
		with PlaySlot(MusicIter)
			fbs_Play_Wave(.Waveform,-1,1,.Volume/100,0,@musicPlr)
		end with
		MusicActive = 1
	end if
end sub
