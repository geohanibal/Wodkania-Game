"""Game constants for Vodkania Uprising."""

# Screen dimensions
SCREEN_WIDTH: int = 900
SCREEN_HEIGHT: int = 650

# World dimensions (100x100 tiles)
WORLD_WIDTH: int = 3200
WORLD_HEIGHT: int = 3200
TILE_SIZE: int = 32

# Frame rate
FPS: int = 60

# ── Colors ──────────────────────────────────────────────────────────────────
BLACK      = (0,   0,   0)
WHITE      = (255, 255, 255)
GRAY       = (160, 160, 160)
DARK_GRAY  = (80,  80,  80)
RED        = (220, 30,  30)
GREEN      = (30,  200, 30)
BLUE       = (30,  100, 220)
YELLOW     = (240, 220, 0)
ORANGE     = (240, 140, 0)
PURPLE     = (140, 0,   200)
CYAN       = (0,   210, 220)
DARK_RED   = (140, 0,   0)
DARK_GREEN = (0,   120, 0)
BROWN      = (139, 90,  43)
LIGHT_BLUE = (100, 180, 255)

# ── Player ──────────────────────────────────────────────────────────────────
PLAYER_SPEED: int = 3
PLAYER_START_SUPPORTERS: int = 5
WIN_SUPPORTERS: int = 50

# ── Police ──────────────────────────────────────────────────────────────────
POLICE_SPEED: int = 2
POLICE_DETECTION_BASE: int = 150
POLICE_CAPTURE_RANGE: int = 40

# ── Civilians ───────────────────────────────────────────────────────────────
CIVILIAN_SPEED: int = 1
CIVILIAN_WANDER_RANGE: int = 100
RECRUIT_RANGE: int = 60

# ── Factions ────────────────────────────────────────────────────────────────
FACTION_SPEED: int = 2
FACTION_STEAL_RANGE: int = 80
NUM_FACTIONS: int = 3

# ── Equipment types ─────────────────────────────────────────────────────────
EQUIP_GAS_MASK        = "gas_mask"
EQUIP_BATON           = "baton"
EQUIP_MEGAPHONE       = "megaphone"
EQUIP_PROTECTIVE_GEAR = "protective_gear"

# ── Difficulty escalation thresholds (in seconds) ───────────────────────────
DIFFICULTY_INTERVAL: int = 30   # add a police unit every N seconds
SPECIAL_FORCES_THRESHOLD: int = 20  # player supporters before special forces spawn
