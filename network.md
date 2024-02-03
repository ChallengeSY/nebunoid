## Notice
Nebunoid does not have network multiplayer, but it is planned. Unless/until it is implemented, this document serves as a reference for what might be implemented into the game.

## Planned system
Nebunoid likely will go with a serverless system. Instead, the host shares the public/network IP address, and forwards a specific port. The visitor needs only to connect to a host to play together.

### Versus play
Usually when playing with someone, it is to defeat them in some fashion.

For example; we could do a mechanism where the blocks are shared between the two players (and from opposite sides), but that they would otherwise be controlling their own paddle(s) and balls.
* We would need to ditch the multi-ball multiplayer. Otherwise, one player could dominate the scoreboard if they were lucky with these capsules.
* Some levels are only possible to do from the bottom. We could add a flag that causes only the bottom half of the level to be visible, mirrored to the opposite half.
* Lives could be unlimited, _or_ they could reset on the beginning of each level. (Example: Losing all of your lives would cause you to sit out rest of the level. If this was to happen to both players, the rest of the level is skipped.)

### Co-op play
The above example is also co-op compatible. Instead of defeating another player, the objective could instead be to just clear a level set while having a limited set of shared lives.
