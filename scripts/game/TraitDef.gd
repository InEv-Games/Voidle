class_name TraitDef
extends Resource

## One planet trait (PlanetTags), a file in res://resources/traits/: add or tune
## a trait there, no code needed. How often each rarity is rolled per slot is in
## Balance (trait_rarity_odds).

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color(0.72, 0.77, 0.88), Color(0.50, 0.92, 0.58), Color(0.45, 0.72, 1.00), Color(0.98, 0.80, 0.36)]

## Saved in planet_tags and tag_offers: don't rename a trait that shipped.
@export var trait_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
## { id: value }. A resource id takes a fraction (0.10 = +10%, "raw" means raw
## and processed output); PlanetTags.COUNT_EFFECTS take a whole number.
@export var effects: Dictionary = {}
## Empty: any world.
@export var allowed_planet_types: Array[PlanetData.Type] = []
## How often it is rolled among its own rarity; 0 = never (the home world's trait).
@export var weight: int = 10

func rarity_name() -> String:
	return RARITY_NAMES[rarity]

## The key of Balance trait_rarity_odds ("common", "rare", …).
func rarity_key() -> String:
	return rarity_name().to_lower()

func rarity_color() -> Color:
	return RARITY_COLORS[rarity]

func allows(planet_type: int) -> bool:
	return allowed_planet_types.is_empty() or planet_type in allowed_planet_types

static var _cache: Array[TraitDef] = []
static var _by_id: Dictionary = {}

## Sorted by id: seeded rolls must not depend on the folder's listing order.
static func all() -> Array[TraitDef]:
	if not _cache.is_empty():
		return _cache
	var dir := DirAccess.open("res://resources/traits")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			var path := file_name.trim_suffix(".remap")
			if not dir.current_is_dir() and path.ends_with(".tres"):
				var res := ResourceLoader.load("res://resources/traits/" + path) as TraitDef
				if res:
					_cache.append(res)
					_by_id[res.trait_id] = res
			file_name = dir.get_next()
	_cache.sort_custom(func(a: TraitDef, b: TraitDef) -> bool: return a.trait_id < b.trait_id)
	return _cache

static func find(id: String) -> TraitDef:
	if _cache.is_empty():
		all()
	return _by_id.get(id)
