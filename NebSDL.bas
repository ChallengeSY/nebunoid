enum SoundFX
	SFX_BRICK = 0
	SFX_EXPLODE
	SFX_HARDEN
	SFX_INVINCIBLE
	SFX_POWER_UP
	SFX_POWER_DOWN
	SFX_DEATH
	SFX_SHOOT
	SFX_LIFE
	SFX_BALL = 10
	SFX_WALL = 28
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
dim shared as ubyte SoundVolume
dim shared as short MusicLoaded = 0
const clipCount = SFX_MAX - 1
#include "SDL\SDL.bi"
#include "SDL\SDL_mixer.bi"
dim shared as Mix_Chunk ptr clip(clipCount)
dim shared as integer clipChannel(clipCount), clipPause(clipCount)
dim shared music as Mix_Music ptr
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
clip(SFX_BRICK) = Mix_LoadWAV("sfx/modern/brick.wav")
for SPD as byte = 8 to 26
	clip(int(SFX_BALL+SPD-9)) = Mix_LoadWAV("sfx/modern/paddle"+str(SPD)+".wav")
next SPD
clip(SFX_EXPLODE) = Mix_LoadWAV("sfx/modern/explode.wav")
clip(SFX_HARDEN) = Mix_LoadWAV("sfx/modern/harden.wav")
clip(SFX_INVINCIBLE) = Mix_LoadWAV("sfx/modern/invincible.wav")
clip(SFX_POWER_UP) = Mix_LoadWAV("sfx/modern/powerup.wav")
clip(SFX_POWER_DOWN) = Mix_LoadWAV("sfx/modern/powerdown.wav")
clip(SFX_DEATH) = Mix_LoadWAV("sfx/modern/death.wav")
clip(SFX_SHOOT) = Mix_LoadWAV("sfx/modern/shoot.wav")
clip(SFX_WALL) = Mix_LoadWAV("sfx/modern/wall.wav")
music = NULL

sub play_clip(ID as byte, Panning as short = 320, HertzMod as short = 100)
	if ID >= 0 then
		dim as ubyte PauseLength(0 to clipCount)
		for clipID as ubyte = 0 to  clipCount
			select case clipID
				case SFX_SHOOT
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
	if int(BallSpeed) > MaxSpeed then
		play_clip(SFX_BALL+17)
	elseif int(BallSpeed) >= DefaultSpeed then
		play_clip(SFX_BALL+BallSpeed-8)
	else
		play_clip(SFX_BALL-1)
	end if
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
sub cleanSDL destructor
	release_music
	Mix_CloseAudio
	SDL_Quit
end sub
