## Nebunoid Manual
Nebunoid is a nebula themed Arkanoid/Breakout-type game. In this game, your objective is to bash through various colored blocks with a ball and a paddle, scoring as many points as you can while also clearing as many levels as possible.

When a campaign is started from scratch or resumed from a password, up to four players may play the game, alternating turns when a level is finished or when a life is lost by dropping the *last* ball.

### Gameplay
At the beginning of each life, the ball starts off slow, making it easy to rebound. Hitting the blocks, walls, and the paddle will make it go faster; making it harder to keep the ball in play.

Some blocks may *explode* upon contact, destroying themselves and adjacent blocks, and potentially triggering chain reactions. These blocks are also the only ones that will always be hit by weakened balls.

As soon as all of the scorable blocks are *eliminated* (from a regular ball's perspective), the level is cleared, bonuses are awarded, and a new level begins. The process repeats until either every life is exhausted (although a continue may be used to gain more lives), or until the campaign has been completed.

### Difficulty Levels
Nebunoid supports a difficulty scale for *each* player, allowing players of varying skill to participate.

| Difficulty  | Rating Range | Paddle Specs | Ball Speed | Capsule Chance(1) | Continue Penalty(2) | Extra perks  |
| :---        |         ---: |         ---: | :---       |              ---: | :---                | :---         |
| Effortless  |   1.0 -  1.4 |  160-360-480 | Slowed     |               12% | None                | No reds / Metal balls / Life restock / Bullet ammo |
| Very Easy   |   1.5 -  2.4 |  160-240-480 | Slowed     |               12% | None                | Limit red caps / Metal balls / Life restock |
| Easy        |   2.5 -  3.4 |  120-240-480 | Slowed     |               12% | None                | Life restock |
| Medium-Easy |   3.5 -  4.4 |  120-160-360 | Normal     |               10% | None(3)             | None         |
| Medium      |   4.5 -  5.4 |   80-160-240 | Normal     |               10% | None(3)             | None         |
| Medium-Hard |   5.5 -  6.4 |   80-120-240 | Normal     |                8% | None(3)             | None         |
| Hard        |   6.5 -  7.4 |   40-120-240 | Normal     |                8% | Reduce by 0.5       | None         |
| Very Hard   |   7.5 -  8.4 |   40-120-160 | Normal     |                7% | Reduce by 0.5       | None         |
| Extreme     |   8.5 -  9.4 |   40-120-120 | Normal     |                7% | Reduce by 1.0       | None         |
| Insane      |   9.5 - 10.9 |   40- 80-120 | Normal     |                5% | Reduce by 1.0       | None         |
| Nightmare   |  11.0 - 12.0 |   40- 80-120 | Increased  |                5% | Reduce to 10.0      | No red caps  |

(1) Maximum spawn chance; achieved when there are *no* falling capsules in play. Diminishing Returns decreases this chance (by 1% per capsule) as there are more capsules falling.  
(2) You can use the level select system (F4) or passwords to play the game from any level with a password.
    This system is unavailable if the "Shuffle Levels" option is active, or if one or more players has a continue penalty whenever they get a game over.  
(3) Alternatively, players can choose to reduce the difficulty by 0.5 to make their next credit easier. A player will not drop below Medium-Easy (difficulty 3.5) this way

----

### Powerup Capsules
Nebunoid has 27 capsules of varying power, and rarity. The power-up capsules are colored green, blue, purple, or gold (depending on its rarity), and may be collected to acquire special abilities. The power-down capsules are all colored red, and will generally make the gameplay more challenging when collected. Neutral capsules are colored grey, and can cause some interesting effects when collected. In any case, powerup capsules which have a more potent effect tend to spawn less frequently than weaker capsules.

These capsules also provide a little bit of recovery when in a boss battle.

#### Gem capsules
In addition, there is a collection of 7 gem-themed capsules available outside of Effortless difficulty. These capsules are used to form 5-gem poker-style hands. If a decent hand is formed this way, extra points will be awarded once the hand is complete. Unused gems at the end of the campaign also award points based on the same mechanics.

| Hand            | Value(1) |
| :---            |     ---: |
| Two pair        |      500 |
| Three of a kind |     1000 |
| Full House      |     2500 |
| Four of a kind  |     3500 |
| Five of a kind  |     5000 |

(1)Default score values, based on the base capsule value set in the campaign settings file.

----

### Campaigns
There are 216 levels, split into nine (9) official campaigns of varying size and difficulty. A wide variety of blocks are available, from multi-hit blocks, to invincible blocks, to blocks that can gain hit points over time. Various obstacles may be mixed together. Rumor has it that some campaigns may have hidden levels...

Stars are earned by completing levels for the first time. Harder campaigns require a certain number of stars to break their locks open.

A [level editor](editor.md) also exists, allowing community campaigns to be created.

#### Introductory Training
Introductory Training is a much shorter 10-level campaign, geared to introduce players new to the genre. Few obstacles exist throughout this campaign, and the player is given a maximum quantity of lives.

#### Regular Season
Regular Season is the most balanced campaign, containing 30 levels. A wide variety of obstacles are demonstrated in this campaign, but no bio blocks are present.

Save points are available for nearly every level in the campaign, being absent only from bonus levels (which usually compliment every 9 regular levels), and the last level of the campaign. Instead, players who lose their last life on the final level will not be permitted to continue, and must end their game.

#### Geometric Designs
Geometric Designs is a shorter than usual 10-level campaign. Although less accomodating than Introductory Training, this set is still modest in difficulty. Save points are present in every level, except for the final level.

#### Fortified Letters
Fortified Letters is moderately more challenging than Regular Season. Every English letter is represented in this campaign, for a total of 26 levels. Save points are present in every level, except for the final level (which disallows continues instead).

#### Patriarch Memorial
Patriarch Memorial is a moderate 25-level campaign, comprised mostly of artistic levels designed as a memory of the past. Save points are present in every level up to level 23. No continues are permitted beyond this level.

#### Electric Recharge
Electric Recharge is a moderate 20-level campaign; also comprised mostly of artistic levels, only they reference an computing themed universe. Save points are present in every level up to level 19, with the exception of level 13.

#### Challenge Campaign
The 30-level Challenge Campaign amps up the difficulty several notches by spamming strong blocks like it is hard to believe. Every level demonstrates one or more of the following: Invincible blocks, strong blocks (some will be bio-regenerative), and invisible blocks that may lead to any of the preceding elements

Additionally, save points appear less frequently than they did in previous campaigns; appearing every three levels starting with level 1, up to level 28. As usual, the final level disallows continues.

#### Maximum Insanity
Maximum Insanity makes Challenge Campaign look easy by mixing the most dangerous elements into 25 levels worth of sinister combinations. Save points appear even less frequently; every five levels starting with level 1, up to level 21.

#### Celestial Journey
Celestial Journey is the longest official campaign, at 40 levels. It makes plenty of cross-universe references, and is still on par with that of the **Challenge Campaign**.

Like Maximum Insanity, save points appear every five levels starting with level 1. Unlike previous campaigns, every ten levels starting at level 10 is a boss battle, and continues are disallowed on these levels.

*Nebunoid (C) 2023 Paul Ruediger. Nebulae artwork courtesy of NASA, ESA, and/or other astrophysical observatories and stations. Please check the [credits](credits.md) for more details.*
