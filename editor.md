## Nebunoid Level Editor
Nebunoid comes with a decently powerful level editor, allowing new community campaigns to be made.

## Controls
The editor uses mouse and keyboard to carry out its functionality. Several controls can be easily edited by tapping on a given control when highlighted.

### Available variations
Levels may be designed with a wide variety of variations in mind that alter the gameplay to varying degrees. There are a few restrictions, but it still allows for a lot of flexibility.

* Powerups (1): Allows blocks to drop capsules when they are damaged or destroyed
* Extra Height (2): The top part of the frame becomes detachable for extra play height
* Dual Paddles (4): The player controls two paddles, separated by some vertical space
* Double Juggling (8): Each life starts with two balls
* Cavity (16): Some balls are caged, and must be freed to aid the player
* Progressive (32): Rows will shift down at a progressively faster rate, resetting only when a life is lost. Overrides Cavity
* Steerable Balls (64): Paddle movement will manipulate any balls heading towards the ceiling
* Invisible (128): The level is invisible, flashing only when a block is hit
* Hyper Speed (256): Balls move 50% faster
* Boss Battle (512): Duke it out against a boss whose attacks can damage and destroy your paddle. Negates Breakable Ceiling
* Horitonzal Rotation (1024): Non-invincible blocks rotate horizontally across the board, wrapping as necessary. Overrides Cavity
* Shrink Ceiling (4096): Paddle shrinks the first time a ball hits the ceiling on each life
* Breakable Ceiling (8192): Blocks respawn by brush indefinitely. Break and bypass the ceiling to clear the level instead. Negates Boss Battle
* Fatal Timer (16384): If time limit runs out, the game immediately ends no matter how many lives.  
  (Otherwise; if time runs out, one life is lost, and the rest of the level is skipped.)

#### Boss battles
Boss battles are handled a little differently than a regular level. Brush #1 is used to determine weapon firing points. Bioregenerative blocks apply their properties in 1 frame, but at the expense of causing damage to the boss. Finally, a boss' firing frequency is controlled by its maximum health, and it becomes more aggressive as it loses life.

When a ball causes damage to a boss, the damage the boss receives is controlled by the speed. Faster balls deal more damage per hit.

### Campaign editing controls

#### Keyboard controls
* Ctrl+L: Loads a campaign folder, or creates a new one if it does not exist
* Ctrl+S: Saves the current level and campagin
* Plus sign: Goes forward one level
* Minus sign: Goes backward one level

### Level editing controls
In addition to highlighting controls mentioned above, mirror options can be adjusted by clicking on the brick count display.

Brick "brushes" are managed on a per-level basis. A new brush can be easily made by clicking on the empty + sign. Existing brushes can be edited by right clicking on an existing brush.

#### Keyboard controls
* 1-4: Quickly toggles a supported mirror control
* Arrow keys: Shifts the entire level horizontally or vertically, wrapping around as necessary
* Ctrl+P: Launches a program that immediately loads a single-level playtest "campaign"
