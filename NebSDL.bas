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

/'
SDL add-on

Libraries needed (5):
* SDL
* SDL_mixer
* LibOGG
* LibVorbis
* LibVorbisFile
'/
dim shared as double LastVolume
dim shared as ubyte SoundVolume, MusicActive
dim shared as short MusicLoaded = 0
const clipCount = SFX_MAX - 1
#include "SDL\SDL.bi"
#include "SDL\SDL_mixer.bi"
dim shared as Mix_Chunk ptr clip(clipCount)
dim shared as integer clipChannel(clipCount), clipPause(clipCount)
dim shared music as Mix_Music ptr
dim as string SFXNames(clipCount)
for CID as ubyte = 0 to clipCount
	clip(CID) = NULL
	clipChannel(CID) = -1
next CID
dim video as SDL_Surface ptr
dim event as SDL_Event
dim audio_rate as integer
dim audio_format as Uint16
dim audio_channels as integer
dim audio_buffers as integer
audio_rate = 44100
audio_format = AUDIO_S16
audio_channels = 2
audio_buffers = 4096/2
SDL_Init(SDL_INIT_AUDIO)
if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) then
	open "stderr.txt" for output as #1
	print #1, "Unable to open audio!"
	close #1
	end 1
end if

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

for PID as short = 0 to clipCount
	clip(PID) = Mix_LoadWAV("sfx/modern/"+SFXNames(PID)+".wav")
next PID
music = NULL

sub play_clip(ID as byte, Panning as short = 320, HertzMod as short = 100)
	if ID >= 0 then
		dim as ubyte PauseLength(0 to clipCount)
		for clipID as ubyte = 0 to  clipCount
			select case clipID
				case SFX_SHOOT_BULLET
					PauseLength(clipID) = 15
				case SFX_POWER_UP, SFX_POWER_DOWN
					PauseLength(clipID) = 12
				case SFX_DEATH
					PauseLength(clipID) = 18
				case else
					PauseLength(clipID) = 6
			end select
		next clipID
		if clipPause(ID) = 0 then
			clipPause(ID) = PauseLength(ID) * 2/3
			clipChannel(ID) = Mix_PlayChannel(-1, clip(ID), 0)
		end if
	end if
end sub
sub dynamic_speed_clip(BallSpeed as double, Panning as short = 320)
	play_clip(SFX_BALL)
end sub
sub decrement_pauses
	for ID as ubyte = 0 to clipCount
		if clipPause(ID) > 0 then
			clipPause(ID) -= 1
		end if
	next ID
end sub
function convert_speed(InSpeed as double) as short
	return 100+(int(InSpeed)-8)*5
end function
sub release_music
	Mix_HaltMusic
	Mix_FreeMusic(music)
	music = NULL
end sub
sub rotate_music
	'Currently unimplemented with the SDL framework
end sub
sub cleanSDL destructor
	release_music
	Mix_CloseAudio
	SDL_Quit
end sub
