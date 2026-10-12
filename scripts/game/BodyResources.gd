class_name BodyResources
extends RefCounted

## Holds all ResourceData instances available on a single body (planet/moon/asteroid).
## Generated once per body seed and cached in GameState.

var body_seed:   int = 0
var rarity_min:  int = 1
var rarity_max:  int = 1

## { resource_id -> ResourceData }
var resources: Dictionary = {}

# ── Generation ────────────────────────────────────────────────────────────────

## The named raw resources a body carries (Economy.raw_for_body): fixed by
## body type, with rarer ones appearing further from home.
static func generate_for(pd: PlanetData) -> BodyResources:
	var br := BodyResources.new()
	br.body_seed = pd.seed
	br.rarity_min = 99
	br.rarity_max = 0
	for info: Dictionary in Economy.raw_for_body(pd):
		var rd := ResourceData.from_raw(info)
		br.resources[rd.resource_id()] = rd
		br.rarity_min = mini(br.rarity_min, rd.rarity)
		br.rarity_max = maxi(br.rarity_max, rd.rarity)
	if br.resources.is_empty():
		br.rarity_min = 1
		br.rarity_max = 1
	return br

## Convenience: returns all resources as an array, sorted by rarity then tier.
func as_array() -> Array[ResourceData]:
	var arr: Array[ResourceData] = []
	for rd in resources.values():
		arr.append(rd as ResourceData)
	arr.sort_custom(func(a: ResourceData, b: ResourceData) -> bool:
		return a.rarity < b.rarity if a.rarity != b.rarity else a.tier < b.tier)
	return arr

func get_by_tag(tag: ResourceData.Tag) -> Array[ResourceData]:
	var arr: Array[ResourceData] = []
	for rd in resources.values():
		if (rd as ResourceData).tag == tag:
			arr.append(rd as ResourceData)
	return arr

## Average power across all resources on this body.
func avg_power() -> float:
	var arr := as_array()
	if arr.is_empty():
		return 1.0
	var sum: float = 0.0
	for rd: ResourceData in arr:
		sum += rd.power
	return sum / float(arr.size())
