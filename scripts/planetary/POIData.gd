class_name POIData
extends Resource

enum POIType {
	CITY,       # general buildings, city districts
	MINING,     # extraction, raw minerals
	ENERGY,     # generators, power distribution
	OUTPOST,    # military, defense
	SCIENCE,    # research, anomaly study
	SPACEPORT,  # launch pads, orbital logistics — one per planet
	STATION,    # orbital station — ship-based district
	RESIDENTIAL,# population (housing) — built under a City
	COMMERCIAL, # markets, trade — built under a City
}

static var TYPE_LABELS: Array[String] = ["City", "Industrial", "Energy", "Outpost", "Science", "Spaceport", "Station", "Residential", "Commercial"]
static var TYPE_ICONS:  Array[String] = ["⬡", "⛏", "⚡", "⬡", "⚗", "🚀", "◈", "⌂", "◈"]

@export var label:         String  = "Site"
@export var poi_type:      POIType = POIType.CITY
@export var light_intensity: float = 1.0
@export var level:         int     = 1    # 1–5; grows as buildings are added

@export var constructing:       bool  = false
@export var construct_progress: float = 0.0
@export var construct_duration: float = 15.0

## Where on the planet this POI should appear.
@export var placement: LocationFinder.Placement = LocationFinder.Placement.LAND

## If true, use lon_deg / lat_deg as-is instead of auto-placing.
@export var manual_position: bool  = false
@export var lon_deg:         float = 0.0
@export var lat_deg:         float = 0.0

## Terrain under the district, sampled when it was placed (TerrainSampler.Terrain).
## -1 = not sampled yet (legacy saves) — use TerrainSampler.sample() to fill it.
@export var terrain: int  = -1
@export var coastal: bool = false

## Label of the City this district belongs to. Empty for cities themselves
## (and orbital stations). Cities are parent districts; every other surface
## district is built under one.
@export var parent_city: String = ""

## Natural resources measured at the placed site (ResourceMap.sample):
## { geothermal, solar, wind, tidal: 0..1, minerals: { resource_id: 0..1 } }.
## Empty until sampled.
@export var resource_tags: Dictionary = {}
## Visible features at this site and the share of their bonus: { "terrain_mountain": 1.0,
## "terrain_seacoast": 0.5, … } (FeatureMap.shares). Stored so the economy works
## for bodies that aren't on screen.
@export var site_features: Dictionary = {}
## Credits really paid for this settlement's shell (GDD §15.6; the first,
## free City paid 0). −1 = unknown (older saves): treated as 0.
@export var paid_credits: float = -1.0
## Materials really paid for the shell ({id: amount}; e.g. a Moon Production
## district's Ferrite). Refunded with the credits (KARARLAR §10).
@export var paid_materials: Dictionary = {}

## Settlement growth along roads: for each road (keyed by the district at its
## other end) the settlement size this district had when the road appeared.
## The settlement only stretches toward a road as it grows *after* that, so
## new roads never reshape a district instantly.
@export var spoke_birth: Dictionary = {}

## What the player sees (renameable, may repeat). `label` is the district's
## internal id: buildings, levels, City membership and neighbours key on it.
@export var display_name: String = ""
## Ids (labels) of the surface districts this one neighbours — written by the
## planet view from the settlement map; drives neighbour income.
@export var neighbors: Array = []
## Road-weight per income partner (label -> ×): thicker shared roads pay more.
@export var neighbor_weight: Dictionary = {}

func shown_name() -> String:
	return display_name if display_name != "" else label

## A City's own district keeps its role name ("Capital District") and gets a
## lore name of its own, picked once (playtest 28.10) and saved; renameable.
@export var capital_name: String = ""
const CAPITAL_NAMES: Array[String] = ["Founders' Hall", "First Light", "The Spire", "Ember Court",
	"Old Anchor", "Meridian Hall", "Hearthstone", "The Keel", "Lantern Square", "Concord Plaza",
	"Dawnpillar", "Wardens' Rest", "Signal Hill", "The Crucible", "Landing Stone", "Beacon Yard",
	"Covenant Hall", "Starwell", "The Old Mast", "Archive Row"]

func capital_shown_name() -> String:
	if capital_name == "":
		capital_name = CAPITAL_NAMES[absi(hash(label + display_name)) % CAPITAL_NAMES.size()]
	return capital_name

## A fresh internal id, unique on the planet.
static func make_key(data: PlanetData) -> String:
	var taken := {}
	for p: POIData in data.custom_pois:
		taken[p.label] = true
	var k := data.custom_pois.size() + 1
	while taken.has("d%d" % k):
		k += 1
	return "d%d" % k

## Legacy string tag kept for shader/ring logic only — do not use for type checks.
@export var type_tag: String = ""

## Orbital fields — only meaningful when poi_type == STATION
@export var orbit_angle:       float = 0.0
@export var orbit_speed:       float = 0.25  # rad/s
@export var orbit_inclination: float = 0.0
@export var orbit_node:        float = 0.0   # longitude rotation offset
@export var orbit_radius:      float = 1.35  # fraction of planet radius

func is_orbital() -> bool:
	return poi_type == POIType.STATION

## Cities (and a moon's outpost colony, their equivalent) are parent districts.
func is_city() -> bool:
	return poi_type == POIType.CITY or poi_type == POIType.OUTPOST

func max_building_slots() -> int:
	if poi_type == POIType.STATION:
		return level
	return level * 2   # Lv1=2, Lv2=4, Lv3=6, Lv4=8, Lv5=10

func type_label() -> String:
	return TYPE_LABELS[poi_type]
