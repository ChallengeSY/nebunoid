## Nebunoid Level Editor
Nebunoid comes with a decently powerful level editor, allowing new community campaigns to be made.

### Available variations
Levels may be designed with a wide variety of variations in mind that alter the gameplay to varying degrees. There are a few restrictions, but it still allows for a lot of flexibility.

* Powerups (1): Allows blocks to drop capsules when they are damaged or destroyed
* Extra Height (2): The top part of the frame becomes detachable for extra play height
* Dual Paddles (4): The player controls two paddles, separated by some vertical space
* Double Juggling (8): Each life starts with two balls
* Cavity (16): Some balls are caged, and must be freed to aid the player
* Progressive (32): Rows will shift down at a progressively faster rate, resetting only when a life is lost. Overrides **Cavity**
* Steerable Balls (64): Paddle movement will manipulate any balls heading towards the ceiling
* Invisible (128): The level is invisible, flashing only when a block is hit
* Hyper Speed (256): Balls move 50% faster
* Boss Battle (512): Duke it out against a boss whose attacks can damage and destroy your paddle
* Horizontal Rotation (1024): Non-invincible blocks rotate horizontally across the board, wrapping as necessary. Overrides **Cavity**. Also overrides **Fusion Brushes**, if there are any invincible brushes present
* Fusion Brushes (2048): Blocks of the same "brush" fuse together to form bigger blocks
* Shrink Ceiling (4096): Paddle shrinks the first time a ball hits the ceiling on each life
* Breakable Ceiling (8192): Blocks respawn by brush almost indefinitely. Break and bypass the ceiling to clear the level instead
* Fatal Timer (16384): If time limit runs out, the game immediately ends no matter how many lives.  
  (Otherwise; if time runs out, one life is lost, and the rest of the level is skipped.)

#### Boss battles
Boss battles are handled a little differently than a regular level. Brush #1 is used to determine weapon firing points. Bioregenerative blocks apply their properties in 1 frame, but at the expense of causing damage to the boss. Finally, a boss' firing frequency is controlled by its maximum health, and it becomes more aggressive as it loses life.

When a ball causes damage to a boss, the damage the boss receives is controlled by the speed. Faster balls deal more damage per hit.

Fair warning; if both this gimmick and **Breakable Ceiling** are active, they share the same health system.

### Campaign editing controls
The editor uses mouse and keyboard to carry out its functionality. Several controls can be easily edited by tapping on a given control when highlighted.

#### Keyboard controls
* Ctrl+L: Loads a campaign folder, or creates a new one if it does not exist
* Ctrl+S: Saves the current level and campagin
* Plus sign: Goes forward one level
* Minus sign: Goes backward one level

### Level editing controls
In addition to highlighting controls mentioned above, mirror options can be adjusted by clicking on the block count display.

Block "brushes" are managed on a per-level basis. A new brush can be easily made by clicking on the empty + sign. Existing brushes can be edited by right clicking as such.

There can be a maximum of 35 brushes per level. There also exist automatically generated zap and bloom brushes (named after the respective effects); which are not accessible from the editor, but do not count against the 35 brush limit.

#### Keyboard controls
* 1-4: Quickly toggles a supported mirror control
* Arrow keys: Shifts the entire level horizontally or vertically, wrapping around as necessary
* Ctrl+G: Toggles the grid display
* Ctrl+P: Launches a program that immediately loads a single-level playtest "campaign"

#### New brush controls
Some influence can be performed over a brush by holding down key(s) while creating a brush. Presence is preferred over absence in case of conflicting keys, unless noted otherwise.

* **W**hite: Creates a white colored brush (max red/green/blue). Combinable with C/U/Y
* Blac**k**: Creates a black colored brush (zero red/green/blue). Combinable with R/G/B
* **R**ed: Creates a brush with maximum red
* **G**reen: Creates a brush with maximum green
* **B**lue: Creates a brush with maximum blue
* **C**yan: Creates a brush with zero red
* P**u**rple: Creates a brush with zero green
* **Y**ellow: Creates a brush with zero blue
* **I**nvisible: Creates an invisible brush (overrides all of the above)

### Block compositions
Nebunoid supports a fair amount of block types and compositions. 

* Soft block: These are the most basic blocks. They are simple in appearance, and go down in one hit
* Exploding block: These blocks explode (-1), destroying their surroundings in one hit. Some of them leave behind "bloomed" blocks (-2) in their wake
* Invincible block: These blocks are immune to normal damage. When in their final state, they can no longer score points, but no longer impede level progression
* Multi-Hit blocks: These blocks take multiple hits to destroy, chaining into another brush. Possible to form a repeating chain, causing blocks bound to such chains to also no longer impede progression
* Invisible block: These blocks are invisible. They may use *any* of the above properties. Vulnerable to Zap Blocks powerup
