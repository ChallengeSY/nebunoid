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
	SFX_BALL
	SFX_WALL
	SFX_BRICKS_RESPAWN
	SFX_WALL_BROKEN
	SFX_MAX
end enum

'These functions are intentionally blank to allow for flexibility
dim shared as integer MusicLoaded = 0, MusicActive

sub playClip(ID as byte, Panning as short = 320, HertzMod as short = 100)

end sub
sub dynamicSpeedClip(BallSpeed as double, Panning as short = 320)

end sub
sub decrementPauses

end sub
sub releaseMusic

end sub
sub rotateMusic

end sub
function convertSpeed(InSpeed as double) as short
	return 100+(int(InSpeed)-8)*5
end function
