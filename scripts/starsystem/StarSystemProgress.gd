## Star System layer: the level of the home star system and what it allows.
## (Development: Mechanic-Test/Star-Map.)
##
## One layer above the planet (GDD §4.1, Tip 1): as a planet's level sets how
## many Cities it holds, the system's level sets how many worlds can be
## colonised and how many extra bodies (solar-orbit platforms, structures
## around a planet) can be built. Levelling up costs and takes play time, like a
## planet level-up. State lives in GameState (system_level, system_upgrade_*);
## a level-up that ran out is applied the next time anything asks (level()).
class_name StarSystemProgress
extends RefCounted

## TEST: the Star System view is always reachable (normally it opens on the way
## past the Moon, to Mars).
const TEST_ALWAYS_OPEN := true

const UPGRADE_COST_BASE := {"credits": 25000.0, "science": 4000.0}
const UPGRADE_COST_GROWTH := 3.0
const UPGRADE_SEC_BASE := 90.0


static func can_view() -> bool:
	return TEST_ALWAYS_OPEN or GameState.can_view_solar()


static func level() -> int:
	_settle()
	return GameState.system_level


## Worlds (planets and moons) that may be colonised: level + 1 (the home world
## and the Moon at level 1).
static func colony_capacity(lv: int = -1) -> int:
	return (level() if lv < 0 else lv) + 1


## Extra bodies (platforms on a solar orbit, structures around a planet): level − 1.
static func platform_capacity(lv: int = -1) -> int:
	return maxi(0, (level() if lv < 0 else lv) - 1)


## Colonised worlds of the home system (planets and their moons).
static func colonies_used() -> int:
	var n := 0
	var sd := GameState.get_home_solar()
	if sd == null:
		return 0
	for pd: PlanetData in sd.planets:
		if _colonised(pd.seed):
			n += 1
		for m: PlanetData in pd.moons:
			if _colonised(m.seed):
				n += 1
	return n


static func _colonised(seed_val: int) -> bool:
	var pp := GameState.find_planet(seed_val)
	return pp != null and pp.is_colonized


static func upgrade_cost() -> Dictionary:
	var out := {}
	var mult := pow(UPGRADE_COST_GROWTH, float(level() - 1))
	for k: String in UPGRADE_COST_BASE:
		out[k] = roundf(float(UPGRADE_COST_BASE[k]) * mult)
	return out


static func upgrade_sec() -> float:
	return UPGRADE_SEC_BASE * float(level())


static func is_upgrading() -> bool:
	_settle()
	return GameState.system_upgrade_end > 0.0


static func upgrade_progress() -> float:
	if not is_upgrading():
		return 0.0
	var s := GameState.system_upgrade_start
	return clampf((GameState.play_seconds - s) / maxf(GameState.system_upgrade_end - s, 0.001), 0.0, 1.0)


static func upgrade_left() -> float:
	return maxf(0.0, GameState.system_upgrade_end - GameState.play_seconds) if is_upgrading() else 0.0


## Why the level-up can't start now ("" when it can).
static func upgrade_block() -> String:
	if is_upgrading():
		return "Already levelling up"
	return Economy.cost_block(upgrade_cost())


static func start_upgrade() -> bool:
	if upgrade_block() != "" or not Economy.pay(upgrade_cost()):
		return false
	GameState.system_upgrade_start = GameState.play_seconds
	GameState.system_upgrade_end = GameState.play_seconds + upgrade_sec()
	return true


## Applies a finished level-up.
static func _settle() -> void:
	if GameState.system_upgrade_end > 0.0 and GameState.play_seconds >= GameState.system_upgrade_end:
		GameState.system_upgrade_end = 0.0
		GameState.system_upgrade_start = 0.0
		GameState.system_level += 1
		NewsFeed.post("The star system reached level %d." % GameState.system_level)
		AudioManager.play("level_up")
