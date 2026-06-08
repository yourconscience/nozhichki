# Nozhichki -- Game Spec v1

Pizza territory-claiming game. You throw knives at a shared pizza to cut and claim slices. paper.io meets knife throwing.

## Platform & Stack

- macOS native app, Swift 6, SpriteKit + SwiftUI
- SpriteKit: gameplay arena, physics, animations
- SwiftUI: menus, inventory, item descriptions, HUD overlay
- Minimum target: macOS 14 Sonoma
- Single-player vs AI (v1), local multiplayer stretch goal

## Core Loop

1. Pizza is a circular arena divided into territory cells (grid or polygon mesh)
2. 4 players (1 human + 3 AI) take turns throwing knives
3. Thrown knife travels along a trajectory determined by the throwing style
4. Where the knife path intersects unclaimed or enemy territory, it cuts
5. Cut line splits territory -- the smaller piece flips to the thrower
6. Player eliminated when territory drops to 0%
7. Last player standing wins, or highest % when timer expires

## Arena

- Circular pizza, radius ~400pt
- Visual toppings are cosmetic zones (pepperoni, mushroom, olive, etc.)
- Territory tracked as polygon regions per player, color-coded
- Cut lines persist visually as score marks on the pizza

## Controls

- Mouse aim: direction from center
- Click/hold: charge power (affects range/speed)
- Release: throw
- Right-click or key: cycle throwing style
- Spacebar: activate item (if active item equipped)

---

## Knives (5)

Each knife has base stats that multiply with the throwing style. Player picks a knife before the game starts. Only Kitchen Knife is available on first play; others unlock through meta-progression.

| # | Knife | Speed | Power | Cut Width | Precision | Passive | Unlock |
|---|-------|-------|-------|-----------|-----------|---------|--------|
| 1 | **Kitchen Knife** | 3 | 3 | 3 | 3 | None -- balanced starter | Default |
| 2 | **Cleaver** | 1 | 5 | 5 | 2 | Cuts stun adjacent territory for 1 turn (can't be re-cut) | Win 3 games |
| 3 | **Stiletto** | 5 | 2 | 1 | 5 | Critical cut chance +15% | Win a game with >60% territory |
| 4 | **Santoku** | 4 | 3 | 2 | 4 | Every 3rd cut in a row grants a bonus cut (free throw) | Win a game using 5+ different throwing styles |
| 5 | **Nakiri** | 2 | 4 | 4 | 2 | Cuts against territory with toppings yield 20% more area | Win a game without using any active items |

### Knife Stats Explained

- **Speed**: base throw velocity multiplier (affects all styles)
- **Power**: how deep the cut goes -- higher power = larger territory chunk flipped on cut
- **Cut Width**: base width of the cut line (stacks with style's cut width)
- **Precision**: reduces random scatter on throw landing point

### Knife + Style Interaction

Final stats = (Knife base * 0.6) + (Style stat * 0.4). Example: Cleaver (CutWidth 5) + Spin Throw (CutWidth 4) = 5*0.6 + 4*0.4 = 4.6 effective cut width.

This means knife choice defines your identity, style choice adapts per-situation.

---

## Throwing Styles (13)

Each style defines trajectory shape, cut behavior, and trade-offs. Player unlocks styles by winning games; starts with 3 (Standard, Spin, Lob).

| # | Style | Trajectory | Cut Pattern | Speed | Range | Special |
|---|-------|-----------|-------------|-------|-------|---------|
| 1 | **Standard** | Straight line | Single straight cut | Medium | Long | None -- reliable baseline |
| 2 | **Spin Throw** | Straight line, knife rotates | Wider cut (2x width) | Medium | Medium | Cut width scales with distance traveled |
| 3 | **Lob** | Parabolic arc | Circle stamp at landing point | Slow | Medium | Ignores obstacles in flight; area damage on land |
| 4 | **No-Spin** | Straight, no wobble | Razor-thin cut but very long | Fast | Very Long | 1.5x cut length; narrowest cut |
| 5 | **Underhand** | Low arc, skims surface | Cuts along the arc path | Medium | Short | Cuts continuously along travel path, not just endpoint |
| 6 | **Ricochet** | Straight, bounces off arena edge | Cuts at each bounce point | Fast | Long (2 bounces) | Can hit behind cover; unpredictable |
| 7 | **Fan Throw** | 3 knives in a 30-degree spread | 3 parallel cuts | Fast | Medium | Less damage per knife; covers wide area |
| 8 | **Boomerang** | Outward arc, returns | Cuts on both outward and return paths | Medium | Medium | Double-cut opportunity; must catch on return for bonus |
| 9 | **Drill** | Tight spiral path | Circular cuts along spiral | Slow | Short | Carves out a chunk instead of a line |
| 10 | **Tomahawk** | Overhead arc, steep descent | Deep vertical cut at impact | Slow | Long | 2x cut depth; ignores first shield/block |
| 11 | **Sidearm** | Horizontal curve (left or right) | Curved cut line | Fast | Medium | Curves around obstacles; aim controls curve direction |
| 12 | **Quickdraw** | Instant, no travel time | Short straight cut | Instant | Very Short | No charge time; interrupt enemy cuts |
| 13 | **Cleaver Slam** | Short range slam | Wide area smash | Very Slow | Very Short | 3x cut width; screen shake; stuns adjacent players 1 turn |

### Style Stats

Each style has 5 stats, 1-5 scale:

```
             Speed  Range  CutWidth  Precision  Cooldown
Standard       3      4       2          4         1
Spin           3      3       4          3         1
Lob            2      3       1          2         2
No-Spin        4      5       1          5         1
Underhand      3      2       2          3         1
Ricochet       4      4       2          1         2
Fan            4      3       1          2         3
Boomerang      3      3       2          3         2
Drill          1      2       3          3         3
Tomahawk       2      4       4          2         2
Sidearm        4      3       2          4         1
Quickdraw      5      1       2          3         0
Cleaver Slam   1      1       5          2         4
```

Cooldown: turns before the style can be used again (0 = every turn).

---

## Items (62 total)

Binding of Isaac-style pool. Items drop from cut territory (random chance per cut). Player holds up to 1 active item + unlimited passives + 1 trinket.

### Passive Items (25)

Stat modifiers and permanent effects. Stack unless noted.

| # | Item | Effect |
|---|------|--------|
| 1 | **Sharp Edge** | +20% cut length |
| 2 | **Heavy Blade** | +30% cut width, -10% speed |
| 3 | **Oiled Handle** | +15% throw speed |
| 4 | **Whetstone** | Cuts steal 10% more territory |
| 5 | **Rubber Grip** | +1 range tier to all styles |
| 6 | **Pepperoni Shield** | First hit per round doesn't lose territory |
| 7 | **Extra Cheese** | Territory borders are sticky -- enemies cut 20% less from you |
| 8 | **Hot Sauce** | Cuts leave a burning trail; enemy territory touching it shrinks 1%/turn for 3 turns |
| 9 | **Garlic Crust** | Adjacent enemies can't cut within 50pt of your border |
| 10 | **Anchovy Aura** | AI players avoid cutting your territory (bias, not absolute) |
| 11 | **Double Dough** | +25% starting territory at round start |
| 12 | **Thin Crust** | -20% territory HP but +30% throw speed |
| 13 | **Stuffed Crust** | Border territory regenerates 2% per turn |
| 14 | **Sesame Seeds** | 10% chance any cut yields an extra item drop |
| 15 | **Olive Oil** | Knife slides 20% further after landing |
| 16 | **Mozzarella Stretch** | Cut lines extend 15% on both ends |
| 17 | **Basil Leaf** | Heal 5% territory after 3 consecutive successful cuts |
| 18 | **Truffle** | All stats +1 while you have the smallest territory |
| 19 | **Crushed Red Pepper** | Critical cuts (10% chance): 2x territory stolen |
| 20 | **Parmesan Dust** | See exact enemy territory percentages |
| 21 | **Rolling Pin** | +1 cut width to all styles permanently |
| 22 | **Pizza Stone** | Your territory can't be cut from more than one direction per turn |
| 23 | **Cast Iron** | -15% speed, +2 cut width, immune to knockback effects |
| 24 | **Flour Cloud** | Missed throws create a 50pt smoke cloud hiding territory borders for 2 turns |
| 25 | **Yeast** | Territory grows 1% passively each turn (cap: 5% total growth) |

### Active Items (17)

Cooldown-based. One equipped at a time. Press spacebar to activate.

| # | Item | Cooldown | Effect |
|---|------|----------|--------|
| 26 | **Pizza Cutter** | 5 turns | Next throw cuts in a full circle at landing point (radius = cut width) |
| 27 | **Meat Tenderizer** | 4 turns | Stun target player 1 turn; they skip their throw |
| 28 | **Oven Blast** | 6 turns | All enemy territory adjacent to yours shrinks 5% |
| 29 | **Dough Shield** | 3 turns | Block the next incoming cut completely |
| 30 | **Slice & Dice** | 5 turns | Throw 2 knives this turn instead of 1 |
| 31 | **Freezer** | 4 turns | Target player's territory borders freeze; can't expand for 2 turns |
| 32 | **Delivery Box** | 8 turns | Teleport your smallest disconnected territory chunk to your main body |
| 33 | **Spatula** | 3 turns | Flip: swap your territory with the nearest enemy's smallest chunk |
| 34 | **Microwave** | 6 turns | Rapidly expand a random border section by 8% |
| 35 | **Takeout Order** | 7 turns | Steal a random passive item from the leading player |
| 36 | **Napkin** | 2 turns | Erase the last cut made against you (undo 1 enemy cut) |
| 37 | **Tip Jar** | 5 turns | Convert 5% of your territory into a permanent fortified zone (can't be cut) |
| 38 | **Menu Swap** | 3 turns | Randomly change your current throwing style for this turn (ignores cooldowns) |
| 39 | **Pizza Peel** | 4 turns | Slide your entire territory 30pt in aimed direction |
| 40 | **Bread Basket** | 6 turns | Drop 3 random item pickups on the arena for anyone to collect |
| 41 | **Kitchen Timer** | 5 turns | Next 3 turns happen at 2x speed (your throws only) |
| 42 | **Doggy Bag** | Once | Save current territory state; if territory drops below 10%, restore to saved state |

### Trinkets (10)

Minor passive effects. One equipped at a time. Found less frequently.

| # | Item | Effect |
|---|------|--------|
| 43 | **Toothpick** | +5% precision to all styles |
| 44 | **Paper Plate** | -1 cooldown to current throwing style |
| 45 | **Checkered Tablecloth** | Territory borders are visible through smoke/obscure effects |
| 46 | **Pizza Box Lid** | 5% chance to block incoming cuts automatically |
| 47 | **Oregano Pinch** | Item drops are 10% more frequent |
| 48 | **Receipt** | See what item each enemy last picked up |
| 49 | **Straw Wrapper** | First throw each round has +20% range |
| 50 | **Grease Spot** | Enemy knives that land on your territory slide 10% off-target |
| 51 | **Crust Crumb** | Gain 0.5% territory for each turn you don't throw (stacks to 3%) |
| 52 | **Lucky Penny** | +3% critical cut chance |

### Cursed Items (10)

Risk-reward items. Appear rarely. Always offer a choice: take or leave.

| # | Item | Upside | Downside |
|---|------|--------|----------|
| 53 | **Pineapple** | +40% cut width | 25% of your cuts also damage your own territory |
| 54 | **Anchovy Curse** | +2 to all stats | Other players prioritize attacking you |
| 55 | **Soggy Bottom** | Double item drop rate | Territory loses 1% per turn passively |
| 56 | **Cold Pizza** | All cooldowns -2 | Throw speed -30% |
| 57 | **Ghost Pepper** | Cuts deal 2x territory damage | You take 1.5x territory damage |
| 58 | **Expired Coupon** | Start each round with a random active item charged | Lose your trinket slot |
| 59 | **Wrong Order** | Gain 2 random passives | Lose your active item slot |
| 60 | **Deep Dish** | +50% territory HP (harder to cut from you) | -40% throw range |
| 61 | **Burnt Crust** | Immune to fire/burn effects; +20% speed | Territory doesn't regenerate from any source |
| 62 | **Mystery Topping** | Gain a random stat +3 each round | Lose a random stat -2 each round |

---

## Progression

Two layers: meta-progression (persists across games) and in-game progression (per run).

### Meta-Progression

Persisted to disk (UserDefaults or JSON file). Tracks:

- **Games played / won**
- **Knife unlocks**: each knife has a specific unlock condition (see Knives table)
- **Throwing style unlocks**: start with 3 (Standard, Spin, Lob); unlock others by meeting conditions:

| Style | Unlock Condition |
|-------|-----------------|
| Standard | Default |
| Spin Throw | Default |
| Lob | Default |
| No-Spin | Land 10 cuts with Precision 4+ knives |
| Underhand | Win a game using only short-range styles |
| Ricochet | Hit 3 bounces in a single throw (happens naturally, tracked) |
| Fan Throw | Cut 3 different players in a single game |
| Boomerang | Successfully catch 5 boomerang returns (unlocks after Boomerang is first found as in-game pickup) |
| Drill | Carve out >10% territory in a single cut |
| Tomahawk | Eliminate a player with a single cut |
| Sidearm | Win 5 games |
| Quickdraw | Interrupt 3 enemy cuts across all games |
| Cleaver Slam | Win a game with the Cleaver knife |

Locked styles can still appear as one-time in-game pickups (temporary use, 1 game only). Using one this way counts toward its unlock condition.

### In-Game Progression (per run)

- Pick a knife before the game (from unlocked knives)
- Pick 1 of 3 random throwing styles (always includes Standard, rest from unlocked pool)
- Items drop from successful cuts: ~15% chance per cut
- Item rarity: Common 60%, Uncommon 25%, Rare 10%, Cursed 5%
- New throwing styles can drop as rare pickups mid-game (temporary, 1 game only)
- Win condition: eliminate all opponents or hold >50% territory

## AI Players

3 AI opponents with simple behavior tiers:

| Tier | Behavior |
|------|----------|
| **Timid** | Random throws, avoids conflict, targets empty space |
| **Aggressive** | Targets largest enemy, uses styles with best cut width |
| **Strategic** | Evaluates territory graph, targets weakest borders, saves active items for defense |

One of each tier per game in v1.

## Visual Direction

- Top-down view of a pizza
- Knife sprites per throwing style with distinct silhouettes
- Cut lines are visible score marks
- Territory color-coded with translucent player overlays
- Items show as spinning pickups on the pizza surface
- SwiftUI panels: left sidebar for inventory, bottom bar for style selector
- Particle effects: cheese spray on cuts, crumb explosions on big cuts

## Architecture (SpriteKit + SwiftUI)

```
NozhichkiApp (SwiftUI App)
├── MainMenuView (SwiftUI)
├── GameView (SwiftUI wrapper)
│   ├── GameScene (SKScene) -- all gameplay
│   │   ├── PizzaArena (SKNode) -- territory mesh + visuals
│   │   ├── KnifeNode (SKSpriteNode) -- animated knife per player
│   │   ├── ThrowingEngine -- trajectory calculation per style
│   │   ├── TerritoryManager -- polygon operations, ownership
│   │   ├── ItemDropNode (SKSpriteNode) -- pickup visuals
│   │   └── AIController -- per-player AI behavior
│   ├── HUDOverlay (SwiftUI) -- territory %, turn indicator
│   ├── StyleSelector (SwiftUI) -- bottom bar, style picker
│   └── InventoryPanel (SwiftUI) -- sidebar, items
├── ItemCatalog -- static item definitions
├── ThrowingStyleCatalog -- static style definitions
└── Models/
    ├── ThrowingStyle -- stats, trajectory type, cooldown
    ├── Item -- name, rarity, effect type, modifiers
    ├── Player -- territory, inventory, active style
    └── Territory -- polygon mesh, ownership, HP
```

## Key Technical Decisions

- Territory as polygon mesh, not grid. Polygons allow clean diagonal cuts and smooth visuals. Use clipper/polygon boolean operations for cut logic.
- Trajectory physics in SpriteKit: use SKAction paths for curved throws, manual position updates for straight/bouncing.
- Item effects as a modifier stack: each item registers stat modifiers or event hooks (on_cut, on_hit, on_turn_start, etc.)
- SwiftUI overlay via SpriteView with overlay modifiers.

## Scope Boundaries (v1)

IN:
- 5 knives with distinct stats and passives
- 13 throwing styles with full trajectory + cut behavior
- 62 items across 4 categories
- 3 AI opponents
- Single-player runs
- Meta-progression: knife and style unlocks persisted across games
- Basic sound effects (cut, stick, bounce, item pickup)
- Keyboard + mouse controls

OUT (future):
- Online multiplayer
- Additional knives / styles / items (extensible by design)
- Custom pizza shapes
- Level editor
- Gamepad support
- Leaderboards
