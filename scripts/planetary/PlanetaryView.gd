extends Control

@export var initial_planet: PlanetData
@export var random_on_start: bool = true
@export var debug_seed: int = 12345

@onready var planet_renderer: ColorRect = $PlanetContainer/PlanetRenderer
@onready var poi_layer: Node2D = $POILayer

var current_data:      PlanetData
var _local_system:     Array[PlanetData] = []   # planet + all its moons, flat
var _system_solar:     SolarData                # to restore when going back
var _solar_btn:        Button = null            # shown when solar is unlocked
var _companion_moons:  Array[ColorRect] = []
var _system_dock:      Control = null
var _details_panel:    Control = null
var _hovering_ui:      bool    = false
var _orbitron:         Font
var _ring_back:    Node2D = null
var _ring_front:   Node2D = null
var _ring_angle:   float  = 0.0
var _ring_particles: Array[Dictionary] = []
var _light_angle:  float  = 0.8
const LIGHT_SPEED: float = 0.04   # radians per second
## Tracks which district POI is currently shown in the district panel.
## Used by _on_building_constructed to refresh panel without DOM traversal.
var _active_district_poi: POIData = null
var _inner_tab_active: String = "SURFACE"  # "SURFACE" or "ORBITAL"
var _panel_scroll_pos: int = 0             # preserved across refreshes
## District / City panel body scroll — kept while the same district refreshes.
var _district_body_scroll: ScrollContainer = null
var _district_scroll_label: String = ""
var _overview_energy_val: Label = null   # kept for live energy updates
var _orbital_layer: OrbitalLayer = null
var _mission_builder_overlay: Control = null  # non-null while Mission Builder is open

## Active rocket launch animation state. Empty when no launch in progress.
## Keys: rocket(Control), radius(float), angle_rel(float), alpha(float),
##       phase(int 0=rise/1=turn/2=fade), phase_t(float), on_complete(Callable),
##       planet_seed(int), orbit_inc(float), insert_angle_rel(float), planet_r(float)
var _rocket_anims: Array[Dictionary] = []
## Station deploy particle anims: {ship, ctrl, t, duration}
var _deploy_anims: Array[Dictionary] = []
## Toast log container — created lazily, anchored bottom-left.
var _toast_container: VBoxContainer = null
var _ship_panel: PanelContainer = null
var _radial_menu: Control = null
## Maps building pm_key -> bool indicating if its mineral switcher tray is expanded
var _open_mineral_switchers: Dictionary = {}

## Live district construction progress bars.
var _district_pbars: Dictionary = {}
var _planet_upgrade_pbar: ProgressBar = null
var _district_upgrade_pbars: Dictionary = {}  # poi_label -> ProgressBar

# ── Tutorial highlight state ──────────────────────────────────────────────────
var _tut_highlight:      String  = ""     # current highlight target id
var _tut_highlight_node: Control = null   # specific UI node being pulsed
var _tut_node_tween:     Tween   = null
var _tut_panel_node:     Control = null   # right-panel card secondary pulse
var _tut_panel_tween:    Tween   = null
var _poi_overview_cards: Dictionary = {}  # poi.label -> PanelContainer card

# ── Zoom / pan ────────────────────────────────────────────────────────────────
# Zooming scales the shader's planet radius; the pixel grid keeps its on-screen
# size, so zooming in resolves more terrain detail. Horizontal drag spins the
# globe, vertical drag tilts it (PlanetRenderer), so any latitude can be centred.
const ZOOM_MIN:  float = 1.0
## Zoomed out past the planet (Local System unlocked): neighbouring bodies show
## in the top-right corner (CompanionBodies) and can be clicked to switch to.
const ZOOM_SYSTEM: float = 0.62
const ZOOM_MAX:  float = 5.0    # last step (4x → 5x) is the "city view": markers fade out
const ZOOM_STEP: float = 1.25
## On-screen planet size at 1x zoom, relative to the type-based size.
const PLANET_VIEW_SCALE: float = 0.75
## Ring size relative to the planet radius (matches the original look).
const RING_SCALE: float = 1.4
## Surface district count is uncapped for now (planet level no longer limits it).
const UNLIMITED_SURFACE_DISTRICTS: bool = true
## Per-building level upgrades ("^" button). Off: buildings only have a count.
const BUILDING_LEVELS_ENABLED: bool = false
const RING_VIEW_ANGLE: float = 0.263   # asin(0.26) — the original fixed ring ellipse
var _zoom:        float   = 1.0
var _zoom_target: float   = 1.0
var _zoom_anchor: Vector2 = Vector2.INF   # global point kept under the cursor while zooming
## Double-click on a city → focus it: last click's time (ms) and district label
var _last_click_ms: int = 0
var _last_click_label: String = ""
## Zoom a double-clicked City opens at: district icons fully shown, below the
## closest "city view" where markers fade out.
const CITY_FOCUS_ZOOM: float = 2.6
## Empty-map click: one step up the hierarchy — District → City → Planet.
func _go_up_one_level() -> void:
	if _active_district_poi != null and _active_district_poi in current_data.custom_pois \
			and _active_district_poi.is_orbital():
		_build_orbit_panel(current_data)
		return
	if _active_district_poi != null and _active_district_poi in current_data.custom_pois \
			and not _active_district_poi.is_orbital():
		var city := _city_of(_active_district_poi)
		if city != null:
			_build_city_panel(city, current_data)
			return
	_city_panel_poi = null
	_build_planet_overview(current_data)   # (shows the City while the planet view is locked)

## City panel being shown (the City as a whole), or null.
var _city_panel_poi: POIData = null
## The Orbit panel is showing (see _build_orbit_panel).
var _orbit_panel_open: bool = false
const CompanionScript := preload("res://scripts/planetary/CompanionBodies.gd")
var _companions: Control = null          # CompanionBodies
var _companion_parent: PlanetData = null # the planet, when viewing one of its moons
var _switching_body: bool = false
## Territories grow in from 0 after a body switch (district_reveal uniform).
var _district_reveal: float = 1.0
var _reveal_tween: Tween = null
var _reveal_ghost: Control = null
## Ships flying between this body and a neighbour, drawn on _transit_canvas.
var _transits: Array[ShipData] = []
var _transit_canvas: Control = null
## body -> its stand-in while a switch animation runs (flights follow them).
var _switch_ghosts: Dictionary = {}
const DescentScript := preload("res://scripts/planetary/DescentFX.gd")
## The colony lander is on its way down (OrbitalLayer DescentFX).
var _lander_descending: bool = false
## The first City must be founded (placement can't be cancelled meanwhile).
var _mandatory_city: bool = false
## Picking the Moon landing site (Found First Settlement) — see _begin_lunar_landing.
var _lunar_landing: bool = false
## "Name your city" box is open — planet clicks are ignored.
var _naming_open: bool = false
const DOUBLE_CLICK_MS: int = 350
var _base_radius:      float = 0.42

# ── Side panel slide ──────────────────────────────────────────────────────────
# The right panel can slide off-screen; the planet view (and the HUD energy
# readout) widen with it so the globe stays centred in whatever space is left.
const PANEL_FRACTION:  float = 0.3    # panel width as a fraction of the screen
const PANEL_SLIDE_SEC: float = 0.35
var _panel_open:       bool    = true
var _panel_t:          float   = 1.0  # 1 = fully open, 0 = fully hidden
var _panel_tween:      Tween   = null
var _panel_toggle_btn: Button  = null

# ── Low-res planet render ─────────────────────────────────────────────────────
# The planet shader is quantised to a pixel-art grid (pixel_count cells tall),
# so running it per screen pixel repeats each cell's work ~100× on a zoomed,
# HiDPI view. Instead the shader renders one fragment per cell into a small
# SubViewport, which a TextureRect scales up with nearest filtering. The
# PlanetRenderer node stays (hidden) for input, geometry and shader parameters —
# its material is shared with the low-res canvas.
var _planet_vp:   SubViewport = null
var _planet_px:   ColorRect   = null
var _planet_view: TextureRect = null

# ── Resource lenses & roads ───────────────────────────────────────────────────
## Role overlay shown by the role buttons ("" = none) — FeatureMap.ROLES keys.
var _role: String = ""
var _lens_bar: Control = null
var _lens_buttons: Dictionary = {}      # role -> Button
var _roads_dirty: bool = false
var _maps_ready_seed: int = -1          # planet whose terrain / resource / road maps are built
var _route_cache: Dictionary = {}       # "lonA,latA|lonB,latB" -> route

# ── Manual district placement ─────────────────────────────────────────────────
var _placing_def: DistrictDef = null   # non-null while the player picks a site
var _placing_parent: POIData   = null   # City the new district is built under (null = founding a City)
var _moving_poi: POIData       = null   # settlement being moved (placement mode commits a move)
var _place_hint:  Control     = null

func _make_system(root: PlanetData) -> Array[PlanetData]:
	var arr: Array[PlanetData] = [root]
	for m in root.moons:
		arr.append(m)
	return arr


func _ready() -> void:
	CursorManager.set_state(CursorManager.State.NORMAL)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("Background"):
		get_node("Background").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if planet_renderer:
		planet_renderer.mouse_filter = Control.MOUSE_FILTER_PASS
		if planet_renderer.get_parent() is Control:
			(planet_renderer.get_parent() as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	_orbitron = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")
	planet_renderer.planet_clicked.connect(_on_planet_clicked)
	_setup_lowres_planet()
	ShipManager.ship_arrived.connect(_on_ship_arrived_here)
	ProductionManager.city_leveled.connect(_on_city_leveled)
	_build_panel_toggle()
	tree_exiting.connect(func() -> void: HUDManager.set_view_area_fraction(1.0 - PANEL_FRACTION))
	poi_layer.territory_lookup = _territory_at_screen
	SettingsManager.night_shadow_changed.connect(func(v: float) -> void:
		if planet_renderer.material:
			(planet_renderer.material as ShaderMaterial).set_shader_parameter("night_shadow", v))
	poi_layer.poi_clicked.connect(_on_district_clicked)
	get_tree().root.size_changed.connect(_on_resize)
	# back button removed — navigation handled via system dock / unlock flow
	GameState.unlock_changed.connect(_on_unlock_changed)
	GameState.expedition_changed.connect(_on_expedition_changed)
	if GameState.has_meta("focus_lander"):   # came here from the HUD's lander notice
		var fl_seed := int(GameState.get_meta("focus_lander"))
		GameState.remove_meta("focus_lander")
		(func() -> void: focus_lander_at(fl_seed)).call_deferred()
	GameState.planet_progress_changed.connect(func(seed_val: int) -> void:
		_build_system_panel()
		if current_data != null and seed_val == current_data.seed:
			_update_panel(current_data)
			_refresh_pois(current_data)
			_build_details_panel(current_data)
			_refresh_active_panel())
	_refresh_solar_btn()
	_register_mission_tasks()
	_register_context_commands()
	GameState.minerals_discovered.connect(_on_minerals_discovered)
	TutorialManager.highlight_changed.connect(_on_tutorial_highlight)
	TutorialManager.highlight_cleared.connect(_on_tutorial_highlight_clear)
	get_node("/root/SkillTree").skill_unlocked.connect(func(_id: String) -> void:
		for k: String in _bar_meta:
			_refresh_bar_label_status(k)
		_refresh_district_energy_lbl()
		if current_data != null:
			_update_panel(current_data)
			if _active_district_poi == null:
				_refresh_active_panel()
			else:
				_build_district_panel(_active_district_poi, current_data))

	# load from transition if navigating from SolarView or first launch
	var planet_to_load: PlanetData = SceneTransition.pending_data as PlanetData
	if planet_to_load != null:
		SceneTransition.pending_data = null
		if planet_to_load.moons.is_empty():
			planet_to_load.generate_moons(planet_to_load.seed)
		_system_solar = planet_to_load.get_meta("__solar_data") as SolarData \
			if planet_to_load.has_meta("__solar_data") \
			else GameState.get_home_solar()
		_local_system = _make_system(planet_to_load)
	elif initial_planet != null:
		# inspector-assigned planet (editor testing)
		if initial_planet.moons.is_empty():
			initial_planet.generate_moons(initial_planet.seed)
		planet_to_load = initial_planet
		_local_system = _make_system(planet_to_load)
	else:
		# game start — always load home planet from GameState (Terran, persistent seed)
		planet_to_load = GameState.get_home_planet()
		_local_system  = _make_system(planet_to_load)
	# restore light angle, advancing it by however much real time passed while away
	var now := Time.get_unix_time_from_system() as int
	if GameState.light_last_unix > 0:
		var elapsed := float(now - GameState.light_last_unix)
		GameState.light_angle = fposmod(GameState.light_angle + elapsed * LIGHT_SPEED, TAU)
	_light_angle = GameState.light_angle
	GameState.light_last_unix = now

	load_planet(planet_to_load)
	if GameState.showcase_mode:
		_enter_showcase_layout()
	# back/forward may have asked for a specific panel of this planet
	var nav_sub: Dictionary = NavigationManager.pending_sub
	if not nav_sub.is_empty():
		_apply_nav_sub(nav_sub)
	NavigationManager.end_apply()
	_nav_visit_current()

# ── Navigation history (NavigationManager) ───────────────────────────────────

## Restores a history entry in place when it is this planet (else the scene reloads).
func nav_apply(entry: Dictionary) -> bool:
	var pd := entry.get("data") as PlanetData
	if current_data == null or pd == null or pd.seed != current_data.seed:
		return false
	_apply_nav_sub(entry.get("sub", {}))
	return true

## Opens the panel a history entry points at: overview, a City, a district or the Orbit.
func _apply_nav_sub(sub: Dictionary) -> void:
	if current_data == null:
		return
	var key := "city" if sub.has("city") else ("district" if sub.has("district") else "")
	var target: POIData = null
	if key != "":
		for p: POIData in current_data.custom_pois:
			if p.label == String(sub[key]):
				target = p
				break
	if sub.has("orbit") and GameState.get_planet(current_data.seed).orbit_level > 0:
		_build_orbit_panel(current_data)
	elif key == "city" and target != null:
		_build_city_panel(target, current_data)
	elif key == "district" and target != null:
		_build_district_panel(target, current_data)
		if not target.is_orbital():
			_select_district_on_planet(target.label)
	else:   # overview, or the City/district no longer exists
		_active_district_poi = null
		_city_panel_poi = null
		poi_layer.deselect_all()
		_build_planet_overview(current_data)
	_reveal_panel()

# ── Right-click actions (CommandRegistry + ContextMenu) ──────────────────────

## The City / district / station under the cursor, or null.
func _poi_at_screen(global_pos: Vector2) -> POIData:
	if current_data == null:
		return null
	var idx := _territory_at_screen(global_pos)
	if idx < 0:
		idx = poi_layer._hovered_index
	if idx < 0 or idx >= poi_layer._pois.size():
		return null
	return _find_poi(current_data, String(poi_layer._pois[idx].get("label", "")))

## Right-click: the actions for what's under the cursor (a POI, else the surface).
func _open_context_menu(global_pos: Vector2) -> void:
	if current_data == null or _placing_def != null or _naming_open or GameState.showcase_mode:
		return
	if not _is_over_planet_area(global_pos):   # e.g. over the side panel
		return
	var poi := _poi_at_screen(global_pos)
	var kind := ""
	var target: Variant = null
	var title := ""
	var subtitle := ""
	var pp := GameState.get_planet(current_data.seed)
	if poi != null:
		target = poi
		title = poi.shown_name()
		if poi.is_orbital():
			kind = "station"
			subtitle = "Space Station"
		elif poi.is_city():
			kind = "city"
			subtitle = "City  ·  Lv %d" % Leveling.city_level(pp, poi)
		else:
			kind = "district"
			subtitle = "%s  ·  Lv %d" % [poi.type_tag.capitalize(), int(pp.district_levels.get(poi.label, 1))]
		if poi.constructing:
			subtitle += "  ·  under construction"
	else:
		kind = "surface"
		target = {"pos": global_pos, "hit": _screen_to_lonlat(global_pos)}
		title = current_data.planet_name
		subtitle = "Surface" if bool(target["hit"]["hit"]) else "Space"
	var cmds := CommandRegistry.commands_for(kind, target)
	if cmds.is_empty():
		return
	AudioManager.play("click")
	ContextMenu.open(self, title, subtitle, cmds, global_pos)

## Why `poi` can't level up now ("" when it can). Shared by the panel button and the menu.
func _district_level_up_block(poi: POIData, planet: PlanetData) -> String:
	var pp := GameState.get_planet(planet.seed)
	var lv: int = pp.district_levels.get(poi.label, 1)
	if pp.is_district_upgrading(poi.label):
		return "Already upgrading"
	if lv >= Balance.cfg.max_district_level:
		return "Max level"
	var block := Leveling.district_level_block(planet, pp, poi)
	if block != "":
		return block
	if GameState.credits < Leveling.district_level_credits(lv):
		return "Not enough credits"
	return ""

func _district_level_up(poi: POIData, planet: PlanetData) -> bool:
	var pp := GameState.get_planet(planet.seed)
	var lv: int = pp.district_levels.get(poi.label, 1)
	if _district_level_up_block(poi, planet) != "" or not pp.can_upgrade_district(poi.label) \
			or not GameState.spend_credits(Leveling.district_level_credits(lv)):
		AudioManager.play("error")
		return false
	AudioManager.play("construct")
	pp.level_paid[poi.label] = float(pp.level_paid.get(poi.label, 0.0)) + Leveling.district_level_credits(lv)
	pp.upgrade_district(poi.label)
	GameState.planet_progress_changed.emit(planet.seed)
	return true

func _city_level_up_block(city: POIData, planet: PlanetData) -> String:
	var pp := GameState.get_planet(planet.seed)
	var block := Leveling.city_level_block(planet, pp, city)
	if block != "":
		return block
	if GameState.credits < Leveling.city_level_credits(Leveling.city_level(pp, city) + 1):
		return "Not enough credits"
	return ""

func _city_level_up(city: POIData, planet: PlanetData) -> bool:
	var pp := GameState.get_planet(planet.seed)
	var price := Leveling.city_level_credits(Leveling.city_level(pp, city) + 1)
	if _city_level_up_block(city, planet) != "" or not GameState.spend_credits(price):
		AudioManager.play("error")
		return false
	AudioManager.play("construct")
	var ck := "city:" + city.label
	pp.level_paid[ck] = float(pp.level_paid.get(ck, 0.0)) + price
	pp.city_upgrading[city.label] = 0.0   # ProductionManager finishes it (city_leveled)
	GameState.planet_progress_changed.emit(planet.seed)
	return true

## Why a new district can't be placed in `city` right now ("" when it can).
func _add_district_block(city: POIData, def: DistrictDef) -> String:
	var pp := GameState.get_planet(current_data.seed)
	if city.constructing:
		return "The City is still under construction"
	if Leveling.city_district_count(current_data, city) >= Leveling.city_max_districts(Leveling.city_level(pp, city)):
		return "City is full — level the City up"
	if def.max_per_planet > 0 and DistrictDef.count_on_planet(def, current_data) >= def.max_per_planet:
		return "Limit reached (%d per planet)" % def.max_per_planet
	if GameState.credits < DistrictDef.placement_cost(def, current_data, city.label):
		return "Not enough credits"
	return ""

func _open_poi_panel(poi: POIData) -> void:
	_reveal_panel()
	if poi.is_orbital():
		_build_orbit_panel(current_data)
	elif poi.is_city():
		_build_city_panel(poi, current_data)
	else:
		_build_district_panel(poi, current_data)
		_select_district_on_planet(poi.label)

## Default actions for things on the planet view. Other systems can add more
## for the same kinds with CommandRegistry.add_provider.
func _register_context_commands() -> void:
	CommandRegistry.add_provider("city", self, _city_commands)
	CommandRegistry.add_provider("district", self, _district_commands)
	CommandRegistry.add_provider("station", self, _station_commands)
	CommandRegistry.add_provider("surface", self, _surface_commands)

const CMD_OPEN_COL  := Color(0.60, 0.75, 1.0)
const CMD_LEVEL_COL := Color(0.55, 1.0, 0.65)
const CMD_BUILD_COL := Color(1.0, 0.85, 0.45)
const CMD_MANAGE_COL := Color(0.80, 0.80, 0.88)
const CMD_DANGER_COL := Color(1.0, 0.55, 0.45)

func _city_commands(city: POIData) -> Array:
	var pp := GameState.get_planet(current_data.seed)
	var lv := Leveling.city_level(pp, city)
	var cap_lv: int = pp.district_levels.get(city.label, 1)
	var out: Array = [
		GameCommand.make("open_city", "Open City", _open_poi_panel.bind(city), Callable(),
			{"icon": "▤", "color": CMD_OPEN_COL}),
		GameCommand.make("open_capital", "Open Capital District", _open_capital.bind(city),
			_under_construction_block.bind(city), {"icon": "◆", "color": CMD_OPEN_COL}),
		GameCommand.make("focus_city", "Focus City", _focus_city.bind(city), Callable(),
			{"icon": "◎", "color": CMD_OPEN_COL}),
		GameCommand.make("city_level_up", "Level up City  (Lv %d → %d)" % [lv, lv + 1],
			_city_level_up_and_open.bind(city), _city_level_up_block.bind(city, current_data),
			{"icon": "▲", "color": CMD_LEVEL_COL,
			 "cost": "◈ " + HUDManager.fmt_credits(Leveling.city_level_credits(lv + 1)),
			 "tooltip": "Needs %d total district levels in the City." % Leveling.city_level_req(lv + 1)}),
		GameCommand.make("capital_level_up", "Level up Capital District  (Lv %d → %d)" % [cap_lv, cap_lv + 1],
			_district_level_up_and_open.bind(city), _district_menu_block.bind(city),
			{"icon": "△", "color": CMD_LEVEL_COL,
			 "cost": "◈ " + HUDManager.fmt_credits(Leveling.district_level_credits(cap_lv))}),
	]
	for def: DistrictDef in _district_options(current_data, false, city):
		out.append(GameCommand.make("add_district_" + def.type_key(), "Add %s" % def.display_name,
			_begin_district_placement.bind(def, city), _add_district_block.bind(city, def),
			{"icon": def.icon if def.icon != "" else "+", "color": CMD_BUILD_COL,
			 "cost": "◈ " + HUDManager.fmt_credits(DistrictDef.placement_cost(def, current_data, city.label)),
			 "tooltip": "Pick a site near %s for the new district." % city.shown_name()}))
	out.append_array(_manage_commands(city))
	return out

func _district_commands(poi: POIData) -> Array:
	var pp := GameState.get_planet(current_data.seed)
	var lv: int = pp.district_levels.get(poi.label, 1)
	var out: Array = [
		GameCommand.make("open_district", "Open District", _open_poi_panel.bind(poi),
			_under_construction_block.bind(poi), {"icon": "▤", "color": CMD_OPEN_COL}),
		GameCommand.make("district_level_up", "Level up  (Lv %d → %d)" % [lv, lv + 1],
			_district_level_up_and_open.bind(poi), _district_menu_block.bind(poi),
			{"icon": "▲", "color": CMD_LEVEL_COL,
			 "cost": "◈ " + HUDManager.fmt_credits(Leveling.district_level_credits(lv))}),
	]
	var city := _city_of(poi)
	if city != null:
		out.append(GameCommand.make("open_parent_city", "Open %s" % city.shown_name(),
			_open_poi_panel.bind(city), Callable(), {"icon": "▣", "color": CMD_OPEN_COL}))
		out.append(GameCommand.make("focus_city", "Focus City", _focus_city.bind(city), Callable(),
			{"icon": "◎", "color": CMD_OPEN_COL}))
	out.append_array(_manage_commands(poi))
	return out

# ── Settlement management (GDD §15, KARARLAR §6) ─────────────────────────────

## Remove buildings, clear, reset, move and demolish for a City or district.
func _manage_commands(poi: POIData) -> Array:
	var out: Array = []
	if GameState.showcase_mode or poi.is_orbital():
		return out
	var pp := GameState.get_planet(current_data.seed)
	var rate := Settlement.refund_rate()
	for b: Dictionary in pp.buildings_in_district(poi.label):
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def == null:
			continue
		out.append(GameCommand.make("remove_" + def.building_id, "Remove 1 × %s  (%d left)" % [def.display_name, int(b.get("amount", 1)) - 1],
			_remove_one_building.bind(b), Callable(),
			{"icon": "−", "color": CMD_MANAGE_COL,
			 "cost": "+◈ " + HUDManager.fmt_credits(Settlement.remove_refund(b, 1)),
			 "tooltip": "Refund %d%% of what this building cost. Materials aren't refunded." % int(round(rate * 100.0))}))
	var what := "City" if poi.is_city() else "district"
	out.append(GameCommand.make("move", "Move %s…" % what, _begin_move.bind(poi),
		Settlement.move_block.bind(current_data, poi),
		{"icon": "✥", "color": CMD_MANAGE_COL,
		 "cost": "◈ " + HUDManager.fmt_credits(Settlement.move_fee(current_data, poi)),
		 "tooltip": "Pick a new site. Fee: 10%% of the credits paid for it%s." % (
			" and its districts — they move with it" if poi.is_city() else "")}))
	out.append(GameCommand.make("clear", "Clear buildings…", _confirm_settlement.bind("clear", poi),
		Settlement.block.bind("clear", current_data, poi), {"icon": "⌫", "color": CMD_DANGER_COL,
		 "tooltip": "Removes every building%s; the shell, name, place and levels stay." % (" in the City and its districts" if poi.is_city() else "")}))
	out.append(GameCommand.make("reset", "Reset to Lv1…", _confirm_settlement.bind("reset", poi),
		Settlement.block.bind("reset", current_data, poi), {"icon": "↺", "color": CMD_DANGER_COL,
		 "tooltip": "Back to an empty Lv1 shell%s." % (" — its districts are removed" if poi.is_city() else "")}))
	out.append(GameCommand.make("demolish", "Demolish %s…" % what, _confirm_settlement.bind("demolish", poi),
		Settlement.block.bind("demolish", current_data, poi), {"icon": "✖", "color": CMD_DANGER_COL,
		 "tooltip": "Removes it%s. The planet itself stays." % (" with all its districts" if poi.is_city() else "")}))
	return out

func _remove_one_building(entry: Dictionary) -> void:
	var refund := Settlement.remove_buildings(GameState.get_planet(current_data.seed), entry, 1)
	AudioManager.play("click")
	_show_unlock_toast("Building removed", "+%s cr refunded" % Economy.fmt(refund))
	_refresh_active_panel()

func _confirm_settlement(kind: String, poi: POIData) -> void:
	var pv := Settlement.preview(kind, current_data, poi)
	var verb: String = {"clear": "Clear", "reset": "Reset", "demolish": "Demolish"}[kind]
	var data := current_data
	ConfirmPanel.ask(self, "%s %s?" % [verb, poi.shown_name()], String(pv["text"]), verb.to_upper(),
		func() -> void:
			if Settlement.block(kind, data, poi) != "":
				AudioManager.play("error")
				return
			var refund := 0.0
			match kind:
				"clear":    refund = Settlement.clear(data, poi)
				"reset":    refund = Settlement.reset(data, poi)
				"demolish": refund = Settlement.demolish(data, poi)
			AudioManager.play("click")
			_show_unlock_toast("%s done" % verb, "+%s cr refunded" % Economy.fmt(refund))
			if kind == "demolish" and _panel_open:
				_set_panel_open(false)
			load_planet(data))

func _try_move_here(site: Vector2) -> void:
	var poi := _moving_poi
	var block := Settlement.move_site_block(current_data, poi, site)
	if block == "" and not poi.is_city() and not _placement_system_check(_placing_def, site.x, site.y)["ok"]:
		block = "Too far from its City"
	if block == "":
		block = Settlement.move_block(current_data, poi)
	if block != "":
		AudioManager.play("error")
		_show_unlock_toast("Can't move here", block)
		return
	var fee := Settlement.move_fee(current_data, poi)
	if not Settlement.move(current_data, poi, site):
		AudioManager.play("error")
		return
	AudioManager.play("construct")
	_end_district_placement()
	_show_unlock_toast("%s moved" % poi.shown_name(), "Fee %s cr" % Economy.fmt(fee))
	load_planet(current_data)

## Starts placement mode for moving a settlement (its whole subtree follows).
func _begin_move(poi: POIData) -> void:
	var def := ProductionManager.district_def(poi)
	if def == null:
		return
	_begin_district_placement(def, null if poi.is_city() else _city_of(poi))
	_moving_poi = poi
	_show_unlock_toast("Move %s" % poi.shown_name(),
		"Click the new site. Fee %s cr." % Economy.fmt(Settlement.move_fee(current_data, poi)))

func _station_commands(poi: POIData) -> Array:
	return [GameCommand.make("open_orbit", "Open Orbit", _open_poi_panel.bind(poi), Callable(),
		{"icon": "◈", "color": CMD_OPEN_COL})]

func _surface_commands(t: Dictionary) -> Array:
	var out: Array = []
	var city_def := DistrictDef.find(DistrictDef.Type.CITY)
	if city_def != null:
		out.append(GameCommand.make("found_city_here", "Found City here",
			_found_city_at.bind(city_def, t["pos"]), _found_city_here_block.bind(bool(t["hit"]["hit"])),
			{"icon": "✚", "color": CMD_BUILD_COL,
			 "cost": "◈ " + HUDManager.fmt_credits(DistrictDef.placement_cost(city_def, current_data)),
			 "tooltip": "Starts City placement at this spot. If it can't be built exactly here, placement stays open so you can pick another site."}))
	out.append(GameCommand.make("planet_overview", "Planet overview", _show_planet_overview, Callable(),
		{"icon": "▤", "color": CMD_OPEN_COL}))
	out.append(GameCommand.make("star_system", "Star system view", _go_back, _star_system_block,
		{"icon": "☉", "color": CMD_OPEN_COL}))
	return out

# small targets for the commands above (bound with .bind)
func _under_construction_block(poi: POIData) -> String:
	return "Under construction" if poi.constructing else ""

func _district_menu_block(poi: POIData) -> String:
	return "Under construction" if poi.constructing else _district_level_up_block(poi, current_data)

func _open_capital(city: POIData) -> void:
	_reveal_panel()
	_build_district_panel(city, current_data)
	_select_district_on_planet(city.label)

func _city_level_up_and_open(city: POIData) -> void:
	if _city_level_up(city, current_data):
		_open_poi_panel(city)

func _district_level_up_and_open(poi: POIData) -> void:
	if _district_level_up(poi, current_data):
		_open_poi_panel(poi)

func _found_city_here_block(on_ground: bool) -> String:
	if not on_ground:
		return "Point at the planet's surface"
	if not GameState.get_planet(current_data.seed).is_colonized:
		return "This world isn't colonized"
	return _found_city_block(current_data)

func _found_city_at(city_def: DistrictDef, pos: Vector2) -> void:
	_begin_district_placement(city_def, null)
	_try_place_district(pos)

func _show_planet_overview() -> void:
	_reveal_panel()
	_apply_nav_sub({})

func _star_system_block() -> String:
	return "" if GameState.can_view_solar() else "Star system not unlocked yet"

func _nav_visit(planet: PlanetData, sub: Dictionary, label: String) -> void:
	if planet != null:
		NavigationManager.visit(NavigationManager.planet_entry(planet, sub, label))

## Records whichever panel is showing (same precedence as _refresh_active_panel).
func _nav_visit_current() -> void:
	if current_data == null:
		return
	if _city_panel_poi != null and _city_panel_poi in current_data.custom_pois:
		_nav_visit(current_data, {"city": _city_panel_poi.label}, _city_panel_poi.display_name)
	elif _orbit_panel_open:
		_nav_visit(current_data, {"orbit": true}, "Orbit")
	elif _active_district_poi != null and _active_district_poi in current_data.custom_pois:
		_nav_visit(current_data, {"district": _active_district_poi.label}, _active_district_poi.display_name)
	else:
		_nav_visit(current_data, {}, "")

## Showcase (read-only viewer): no side panel or tab, the globe fills the screen.
func _enter_showcase_layout() -> void:
	_panel_open = false
	_apply_panel_t(0.0)
	($SidePanel as Control).visible = false
	if _panel_toggle_btn != null:
		_panel_toggle_btn.visible = false

func _save_light_angle() -> void:
	GameState.light_angle     = _light_angle
	GameState.light_last_unix = Time.get_unix_time_from_system() as int

# ── Tutorial highlight helpers ───────────────────────────────────────────────

func _on_tutorial_highlight(target_id: String) -> void:
	_tut_highlight = target_id
	if target_id == "construction_wait":
		if is_instance_valid(_tut_highlight_node):
			_tut_highlight_node.modulate = Color.WHITE
		if _tut_node_tween != null and _tut_node_tween.is_valid():
			_tut_node_tween.kill()
		_tut_highlight_node = null
		_stop_tut_panel_pulse()
		TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))

func _on_tutorial_highlight_clear() -> void:
	_tut_highlight = ""
	if is_instance_valid(_tut_highlight_node):
		_tut_highlight_node.modulate = Color.WHITE
	if _tut_node_tween != null and _tut_node_tween.is_valid():
		_tut_node_tween.kill()
	_tut_highlight_node = null
	_stop_tut_panel_pulse()
	TutorialManager.set_allowed_rects([])
	TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))

func _start_tut_node_pulse(node: Control) -> void:
	if _tut_node_tween != null and _tut_node_tween.is_valid():
		_tut_node_tween.kill()
	if is_instance_valid(_tut_highlight_node) and _tut_highlight_node != node:
		_tut_highlight_node.modulate = Color.WHITE
	if not is_instance_valid(node):
		return
	node.modulate = Color.WHITE
	_tut_node_tween = create_tween().set_loops()
	_tut_node_tween.tween_property(node, "modulate", Color(2.2, 2.0, 1.6, 1.0), 0.50)
	_tut_node_tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.50)

func _start_tut_panel_pulse(node: Control) -> void:
	_stop_tut_panel_pulse()
	if not is_instance_valid(node):
		return
	_tut_panel_node = node
	node.modulate = Color.WHITE
	_tut_panel_tween = create_tween().set_loops()
	_tut_panel_tween.tween_property(node, "modulate", Color(2.2, 2.0, 1.6, 1.0), 0.50)
	_tut_panel_tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.50)

func _stop_tut_panel_pulse() -> void:
	if _tut_panel_tween != null and _tut_panel_tween.is_valid():
		_tut_panel_tween.kill()
	if is_instance_valid(_tut_panel_node):
		_tut_panel_node.modulate = Color.WHITE
	_tut_panel_node = null
	_tut_panel_tween = null

func _notify_tutorial_district_opened(poi: POIData, root: VBoxContainer) -> void:
	if TutorialManager._waiting_for_bid != "":
		return
	var target_bid := TutorialManager.get_action_building_target()
	if target_bid == "":
		return
	var buildable := BuildingDef.for_poi_and_planet(poi.poi_type, current_data.planet_type)
	var can_here := false
	for def in buildable:
		if def.building_id == target_bid:
			can_here = true
			break
	if not can_here:
		return
	# the slot cards sit inside the panel's scrolling body, not directly under root
	var card := _find_slot_card(root)
	if card != null:
		_tut_highlight_node = card
		_start_tut_node_pulse(_tut_highlight_node)

## First empty-slot card anywhere under `node` (null if none).
func _find_slot_card(node: Node) -> Control:
	for child in node.get_children():
		if child is PanelContainer and child.has_meta("is_slot_card"):
			return child as Control
		var deeper := _find_slot_card(child)
		if deeper != null:
			return deeper
	return null

func _notify_tutorial_planet_level_up_btn(btn: Button) -> void:
	if TutorialManager.get_action_step_type() != "planet_level_up": return
	_tut_highlight_node = btn
	_start_tut_node_pulse(btn)

func _notify_tutorial_district_upgrade_btn(btn: Button) -> void:
	if TutorialManager.get_action_step_type() != "district_upgrade": return
	_tut_highlight_node = btn
	_start_tut_node_pulse(btn)

func _notify_tutorial_district_type_dropdown(dd: PanelContainer) -> void:
	if TutorialManager._waiting_for_bid != "":
		return
	if TutorialManager.get_action_step_type() != "district":
		return
	var target_id: int = TutorialManager.get_action_district_target()
	if target_id < 0:
		return
	var vbox := dd.get_child(0) as VBoxContainer
	if vbox == null:
		return
	for child in vbox.get_children():
		if child is Button and child.has_meta("district_def_id"):
			if int(child.get_meta("district_def_id")) == target_id:
				_tut_highlight_node = child as Control
				_start_tut_node_pulse(_tut_highlight_node)
				return

func _update_tutorial_highlight() -> void:
	if not TutorialManager._action_block_on:
		return
	var allowed: Array[Rect2] = []
	var vp := get_viewport().get_visible_rect()
	var px := _panel_right_edge()
	var planet_area := Rect2(px, 0.0, vp.size.x - px, vp.size.y)
	# Construction wait
	if TutorialManager._waiting_for_bid != "":
		TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))
		_stop_tut_panel_pulse()
		for card_v in _poi_overview_cards.values():
			if card_v != null and is_instance_valid(card_v):
				allowed.append((card_v as Control).get_global_rect())
		allowed.append(planet_area)
		TutorialManager.set_allowed_rects(allowed)
		return
	if _tut_highlight == "":
		return
	# Specific dropdown row
	if is_instance_valid(_tut_highlight_node) and (
			_tut_highlight_node.has_meta("building_id") or
			_tut_highlight_node.has_meta("district_def_id")):
		TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))
		allowed.append(_tut_highlight_node.get_global_rect())
		TutorialManager.set_allowed_rects(allowed)
		return
	# Slot card / ADD DISTRICT button
	if is_instance_valid(_tut_highlight_node):
		TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))
		var parent := _tut_highlight_node.get_parent()
		if parent != null:
			for sib in parent.get_children():
				if sib is Control and sib.has_meta("is_slot_card"):
					allowed.append((sib as Control).get_global_rect())
		if allowed.is_empty():
			allowed.append(_tut_highlight_node.get_global_rect())
		allowed.append(planet_area)
		TutorialManager.set_allowed_rects(allowed)
		return
	# POI ring modes
	var ring_pos := Vector2(-999.0, -999.0)
	var panel_lbl := ""
	match _tut_highlight:
		"capital":
			var cap_key := TutorialManager._first_city_key(current_data) if current_data != null else ""
			if cap_key != "":
				ring_pos = poi_layer.get_poi_screen_pos(cap_key)
			panel_lbl = cap_key
			if ring_pos.x > -900.0:
				allowed.append(Rect2(ring_pos - Vector2(90, 90), Vector2(180, 180)))
			var cap_card_v = _poi_overview_cards.get(cap_key, null)
			if cap_card_v != null and is_instance_valid(cap_card_v):
				allowed.append((cap_card_v as Control).get_global_rect())
		"generator_district":
			if _active_district_poi != null:
				if planet_renderer != null:
					ring_pos = planet_renderer.global_position + Vector2(
						planet_renderer.size.x * 0.25, planet_renderer.size.y * 0.65)
				allowed.append(planet_area)
			else:
				for poi in poi_layer._pois:
					var lbl: String = poi.get("label", "") if poi is Dictionary else poi.label
					var orb: bool = poi.get("is_orbital", false) if poi is Dictionary else poi.is_orbital()
					var city: bool = poi.get("data", {}).get("is_city", false) if poi is Dictionary else poi.is_city()
					if not orb and not city and lbl != "":
						ring_pos = poi_layer.get_poi_screen_pos(lbl)
						var cv = _poi_overview_cards.get(lbl, null)
						if cv != null and is_instance_valid(cv):
							allowed.append((cv as Control).get_global_rect())
						break
				if ring_pos.x > -900.0:
					allowed.append(Rect2(ring_pos - Vector2(90, 90), Vector2(180, 180)))
		"planet_level_up_btn":
			if is_instance_valid(_tut_highlight_node):
				allowed.append(_tut_highlight_node.get_global_rect())
			allowed.append(planet_area)
		"district_upgrade_btn", "city_level_up_btn":
			if is_instance_valid(_tut_highlight_node):
				allowed.append(_tut_highlight_node.get_global_rect())
			allowed.append(planet_area)
		"add_district":
			if planet_renderer != null:
				ring_pos = planet_renderer.global_position + planet_renderer.size * 0.5
			if is_instance_valid(_tut_highlight_node):
				allowed.append(_tut_highlight_node.get_global_rect())
			elif ring_pos.x > -900.0:
				allowed.append(Rect2(ring_pos - Vector2(90, 90), Vector2(180, 180)))
		"construction_wait":
			TutorialManager.set_highlight_pos(Vector2(-999.0, -999.0))
			if _active_district_poi != null:
				var cv = _poi_overview_cards.get(_active_district_poi.label, null)
				if cv != null and is_instance_valid(cv):
					allowed.append((cv as Control).get_global_rect())
			allowed.append(planet_area)
			TutorialManager.set_allowed_rects(allowed)
			return
	# Always allow planet drag and all district overview cards
	allowed.append(planet_area)
	for card_v in _poi_overview_cards.values():
		if card_v != null and is_instance_valid(card_v):
			allowed.append((card_v as Control).get_global_rect())
	TutorialManager.set_highlight_pos(ring_pos)
	TutorialManager.set_allowed_rects(allowed)
	# Panel card pulse
	var want_card_v = _poi_overview_cards.get(panel_lbl, null)
	var want_card: Control = (want_card_v as Control) if (want_card_v != null and is_instance_valid(want_card_v)) else null
	if want_card != _tut_panel_node:
		if want_card == null:
			_stop_tut_panel_pulse()
		else:
			_start_tut_panel_pulse(want_card)

# ─────────────────────────────────────────────────────────────────────────────

## Leaves the planet view for the star system (the Local System view is gone —
## a body's moons show in the corner when zoomed out). Needs the system unlocked.
func _go_back() -> void:
	if not GameState.can_view_solar():
		return
	AudioManager.set_construction_active(false)
	_save_light_angle()
	var sd := _system_solar if _system_solar != null else GameState.get_home_solar()
	SceneTransition.go("res://scenes/solar/SolarView.tscn", sd)

func _on_unlock_changed(_key: String, _val: bool) -> void:
	_refresh_solar_btn()

func _refresh_solar_btn() -> void:
	pass   # navigation via right-click only


func _input(event: InputEvent) -> void:
	if SkillTreeView.is_open:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).double_click \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if _try_follow_lander((event as InputEventMouseButton).global_position):
			get_viewport().set_input_as_handled()
			return
	# Right-click / ESC cancels district placement
	if _placing_def != null:
		var cancel := false
		if event is InputEventKey:
			var cke := event as InputEventKey
			cancel = cke.pressed and cke.keycode == KEY_ESCAPE
		elif event is InputEventMouseButton:
			var cmb := event as InputEventMouseButton
			cancel = cmb.pressed and cmb.button_index == MOUSE_BUTTON_RIGHT
		if cancel and _mandatory_city:
			get_viewport().set_input_as_handled()   # the first City must be founded
			return
		if cancel:
			_end_district_placement()
			AudioManager.play("click")
			get_viewport().set_input_as_handled()
			return
	# ESC closes radial menu if open
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE and _radial_menu != null:
			_close_radial_menu()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Showcase is read-only: no right-click actions (navigate with NavigationManager)
		if GameState.showcase_mode and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			return
		# Tutorial deselect: during generator-district step with panel open,
		# left-click on planet area closes it so ADD DISTRICT becomes visible.
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT \
				and _tut_highlight == "generator_district" and _active_district_poi != null:
			var click := mb.position
			if click.x > _panel_right_edge():
				_tut_highlight_node = null
				_go_up_one_level()
				get_viewport().set_input_as_handled()
				return
		# Close slot dropdown on any click outside it
		if mb.pressed and _active_slot_dropdown != null \
				and is_instance_valid(_active_slot_dropdown):
			var dd_rect := _active_slot_dropdown.get_global_rect()
			if not dd_rect.has_point(get_viewport().get_mouse_position()):
				_active_slot_dropdown.queue_free()
				_active_slot_dropdown = null
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			# Check if right-clicking on a ship → ship radial menu
			if _orbital_layer != null and is_instance_valid(_orbital_layer):
				var ship_hit := _orbital_layer._ship_at(mb.global_position)
				if ship_hit != null:
					if _orbital_layer._selected_ship != ship_hit:
						_orbital_layer.select_ship(ship_hit)
					_show_radial_menu(ship_hit, mb.global_position, _orbital_layer)
					get_viewport().set_input_as_handled()
					return
			# Right-click is for actions only — going back/up lives in the
			# navigation HUD (NavigationManager). With a ship selected, empty space
			# keeps the ship's planet menu; otherwise the context menu (CommandRegistry).
			if _orbital_layer != null and _orbital_layer._selected_ship != null \
					and _poi_at_screen(mb.global_position) == null:
				_show_planet_radial_menu(mb.global_position)
			else:
				_open_context_menu(mb.global_position)
			get_viewport().set_input_as_handled()
		# Wheel / pinch only zoom. Leaving the planet view on zoom-out is disabled
		# for now — it will be bound to another control.
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			if _is_over_planet_area(mb.global_position):
				_set_zoom_target(_zoom_target / ZOOM_STEP, mb.global_position)
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			if _is_over_planet_area(mb.global_position):
				_set_zoom_target(_zoom_target * ZOOM_STEP, mb.global_position)
				get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		if _is_over_planet_area(mg.position):
			_set_zoom_target(_zoom_target * mg.factor, mg.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		# 2-finger drag moves the globe like a mouse drag: x spins, y tilts.
		var pg := event as InputEventPanGesture
		if _is_over_planet_area(pg.position):
			var r_px := _planet_r_px()
			if r_px > 0.0:
				var spin_r := r_px * maxf(cos(planet_renderer.tilt), 0.35)
				planet_renderer.set_rotation_offset(planet_renderer.get_rotation_offset() + pg.delta.x / spin_r)
				if not planet_renderer.tilt_locked:
					planet_renderer.set_tilt(planet_renderer.tilt - pg.delta.y / r_px)
			get_viewport().set_input_as_handled()

func load_planet(data: PlanetData) -> void:
	var planet_changed: bool = current_data == null or current_data.seed != data.seed
	if planet_changed:
		_inner_tab_active = "SURFACE"
		_panel_scroll_pos = 0   # reset scroll on planet switch
		_zoom = ZOOM_MIN
		_zoom_target = ZOOM_MIN
		planet_renderer.set_tilt(0.0)
		_end_district_placement()
		_orbit_panel_open = false
	current_data = data
	if planet_changed:
		_active_district_poi = null   # clear stale reference on planet switch
	_open_mineral_switchers.clear()
	GameState.active_planet_seed = data.seed
	GameState.cache_planet_data(data)
	_setup_material(data)
	# Sync light state to the renderer for this planet
	planet_renderer.local_time_offset = data.local_time_offset
	planet_renderer.light_angle       = _light_angle
	planet_renderer._update_light_direction()
	_update_panel(data)
	_build_companion_moons(data)
	_build_rings(data)
	_build_system_panel()
	poi_layer.setup(planet_renderer)
	poi_layer.clear_pois()
	_setup_orbital_layer(data.seed)
	_build_details_panel(data)

	_refresh_pois(data)
	if planet_changed:
		_route_cache.clear()
		poi_layer.roads = []
		_set_role("")
	_prepare_planet_maps(data)
	# rotate so the first (primary) POI faces the viewer when arriving at a planet
	if planet_changed and poi_layer._pois.size() > 0:
		planet_renderer.set_rotation_offset(poi_layer._pois[0]["lon"])
	_migrate_orbit(data)
	_setup_companions(data)
	_refresh_active_panel()   # e.g. stay on the City you just added a district to
	call_deferred("_maybe_require_first_city")

## A colonised world with no City yet (a new game's home): the player must pick
## the site of the first City — placement can't be cancelled until it's founded.
## Where a ship lands: a Spaceport's City if one faces us, else the nearest
## visible City / district to the ship. Returns Vector2(lon, lat) radians
## (Vector2.INF when there's nowhere to land).
func _ship_landing_site(ship_pos: Vector2) -> Vector2:
	if current_data == null:
		return Vector2.INF
	var pp := GameState.get_planet(current_data.seed)
	var best: POIData = null
	var best_score := INF
	for poi: POIData in current_data.custom_pois:
		if poi.is_orbital() or poi.constructing:
			continue
		var v: Vector3 = poi_layer.project(deg_to_rad(poi.lon_deg), deg_to_rad(poi.lat_deg))
		if v.z <= 0.0:
			continue
		var score := Vector2(v.x, v.y).distance_to(ship_pos)
		for b: Dictionary in pp.buildings_in_district(poi.label):
			if b.get("building_id", "") == "spaceport":
				score *= 0.25   # strongly prefer the port
		if poi.is_city():
			score *= 0.7
		if score < best_score:
			best_score = score
			best = poi
	if best == null:
		return Vector2.INF
	return Vector2(deg_to_rad(best.lon_deg), deg_to_rad(best.lat_deg))

# ── Neighbouring bodies (zoom out) ──────────────────────────────────────────

## Bodies shown beside `data` when zoomed out: its moons, or — for a moon — its
## planet and sibling moons. Sets _companion_parent.
func _companion_list(data: PlanetData) -> Array[PlanetData]:
	var out: Array[PlanetData] = []
	_companion_parent = null
	if data == null:
		return out
	if data.planet_type == PlanetData.Type.MOON:
		var sd := _system_solar if _system_solar != null else GameState.get_home_solar()
		if sd != null:
			for p: PlanetData in sd.planets:
				if p.moons.has(data):
					_companion_parent = p
					break
		if _companion_parent != null:
			out.append(_companion_parent)
			for m: PlanetData in _companion_parent.moons:
				if m != data:
					out.append(m)
	else:
		for m: PlanetData in data.moons:
			out.append(m)
	return out

## Zooming out past the planet needs the Local System (Lunar Program) and a neighbour.
func _system_zoom_ok() -> bool:
	return GameState.can_view_moon() and _companions != null and not _companions.bodies.is_empty()

func _setup_companions(data: PlanetData) -> void:
	var cont := planet_renderer.get_parent() as Control
	if _companions == null or not is_instance_valid(_companions):
		_companions = CompanionScript.new()
		cont.add_child(_companions)
		_companions.body_clicked.connect(_switch_to_body)
	cont.move_child(_companions, cont.get_child_count() - 1)
	_companions.setup(_companion_list(data), _companion_parent)
	if not _system_zoom_ok() and _zoom_target < ZOOM_MIN:
		_zoom_target = ZOOM_MIN

func _tick_companions() -> void:
	if _companions == null or not is_instance_valid(_companions):
		return
	_companions.light_angle = planet_renderer.light_angle
	if _switching_body:
		pass   # the switch animation drives the fade
	elif _system_zoom_ok():
		_companions.fade = clampf((ZOOM_MIN - _zoom) / (ZOOM_MIN - ZOOM_SYSTEM), 0.0, 1.0)
	else:
		_companions.fade = 0.0
	_tick_transits()

# ── Flights between bodies ───────────────────────────────────────────────────
# A ship flying to a neighbouring body is a ShipManager journey. Its route is a
# function of travel_progress, rebuilt every frame from where both bodies are
# on screen right now (stand-ins during a switch), so it never breaks: from the
# origin's limb it curves onto the destination orbit, arriving tangent to that
# orbit at the point facing the origin — ShipManager then continues the orbit
# from exactly there (meta "arrival_angle"). The trail is the route behind it.

## Where a body is drawn now: {c, r, rot, tilt} in global px (empty if not shown).
func _body_screen(pd: PlanetData) -> Dictionary:
	if pd == null:
		return {}
	if _switch_ghosts.has(pd) and is_instance_valid(_switch_ghosts[pd]):
		var g: ColorRect = _switch_ghosts[pd]
		var gr := g.get_global_rect()
		return {"c": gr.get_center(), "r": gr.size.y * 0.40,
			"rot": float((g.material as ShaderMaterial).get_shader_parameter("rotation_offset")), "tilt": 0.0}
	if _switching_body:
		return {}
	if pd == current_data:
		var oc := planet_renderer.global_position + planet_renderer.size * 0.5
		if _orbital_layer != null and is_instance_valid(_orbital_layer):
			oc = _orbital_layer.get_global_rect().position + _orbital_layer._center_now()
		return {"c": oc, "r": float(planet_renderer._planet_radius_px),
			"rot": planet_renderer.get_rotation_offset(), "tilt": planet_renderer.tilt}
	if _companions != null and _companions.bodies.has(pd):
		var cc: Vector2 = _companions.center_of(pd)
		if cc.is_finite():
			return {"c": cc, "r": _companions.radius_of(pd), "rot": _companions.spin(), "tilt": 0.0}
	return {}

## A point of `ship`'s orbit around a body drawn per `b` (OrbitalLayer._project
## maths): Vector3(x, y, z) global px, z > 0 = behind the body.
static func _orbit_screen(ship: ShipData, a: float, b: Dictionary) -> Vector3:
	var rr: float = float(b["r"]) * ship.orbit_radius
	var px := rr * cos(a)
	var py := rr * sin(a) * sin(ship.orbit_inclination)
	var pz := rr * sin(a) * cos(ship.orbit_inclination)
	var rot: float = float(b["rot"]) + ship.orbit_node
	var rx := px * cos(rot) + pz * sin(rot)
	var rz := -px * sin(rot) + pz * cos(rot)
	var t: float = b["tilt"]
	var c: Vector2 = b["c"]
	return Vector3(c.x + rx, c.y + py * cos(t) - rz * sin(t), py * sin(t) + rz * cos(t))

func _bodies_in_view() -> Array[PlanetData]:
	var out: Array[PlanetData] = []
	if current_data != null:
		out.append(current_data)
	if _companions != null:
		for b: PlanetData in _companions.bodies:
			out.append(b)
	return out

func _find_body(seed_val: int) -> PlanetData:
	for b: PlanetData in _bodies_in_view():
		if b.seed == seed_val:
			return b
	return null

func _tick_transits() -> void:
	_transits.clear()
	var hidden := {}
	var seeds := {}
	for b: PlanetData in _bodies_in_view():
		seeds[b.seed] = true
	for b: PlanetData in _bodies_in_view():
		for ship: ShipData in ShipManager.ships_for(b.seed):
			if ship.is_travelling() and seeds.has(ship.dest_seed) and ship.dest_seed != b.seed:
				_transits.append(ship)
				hidden[ship.ship_id] = true
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.hidden_ships = hidden   # we draw these, not their old orbit
	if _transit_canvas == null or not is_instance_valid(_transit_canvas):
		_transit_canvas = Control.new()
		_transit_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transit_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_transit_canvas.z_index = 31   # above switch stand-ins
		_transit_canvas.draw.connect(_draw_transits)
		(planet_renderer.get_parent() as Control).add_child(_transit_canvas)
	_transit_canvas.visible = _orbits_shown
	_transit_canvas.queue_redraw()

# A transfer is three legs over travel_progress (like Apollo's): ride the
# origin's parking orbit up to the burn point, fly the transfer arc, then ride
# the destination orbit for a while — so the journey ends already orbiting.
# The orbit legs are true 3D orbit projections (hidden behind their body); the
# arc leaves and joins them along the orbit direction. Burn / arrival angles
# are chosen once and saved on the ship.
const DEPART_FRAC := 0.2       # share of the journey spent on the origin orbit
const CAPTURE_FRAC := 0.2      # … and on the destination orbit
const DEPART_ARC := 1.4        # radians of parking orbit flown before the burn
const CAPTURE_ARC := 1.0       # radians of destination orbit flown before arrival
const PARKING_RADIUS := 1.15   # origin parking orbit (planet radii)

## The orbit point of `ship` around a body drawn per `b`, at `radius` planet
## radii (default: the ship's own orbit radius).
func _orbit_pt(ship: ShipData, a: float, b: Dictionary, radius := -1.0) -> Vector3:
	var bb := b.duplicate()
	if radius > 0.0:
		bb["r"] = float(b["r"]) * radius / ship.orbit_radius
	return _orbit_screen(ship, a, bb)

static func _hidden_by(v: Vector3, b: Dictionary) -> bool:
	return v.z > 0.0 and Vector2(v.x, v.y).distance_to(b["c"]) < float(b["r"])

## WASD / arrow keys turn the globe (A/D spin, W/S tilt) — not while typing,
## in the console, or with the Upgrade Tree open. Slower when zoomed in.
const KEY_SPIN_SPEED := 1.6   # rad/s at the widest zoom
func _tick_key_spin(delta: float) -> void:
	if SkillTreeView.is_open or _naming_open or _switching_body:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	var dc := get_node_or_null("/root/DevConsole")
	if dc != null and bool(dc.get("_open")):
		return
	var spin := 0.0
	var tilt := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		spin -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		spin += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		tilt += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		tilt -= 1.0
	if spin == 0.0 and tilt == 0.0:
		return
	var speed := KEY_SPIN_SPEED / maxf(_zoom, 0.5) * delta
	if spin != 0.0:
		planet_renderer.set_rotation_offset(planet_renderer.get_rotation_offset() + spin * speed)
	if tilt != 0.0 and not planet_renderer.tilt_locked:
		planet_renderer.set_tilt(planet_renderer.tilt + tilt * speed * 0.6)

## Picks the burn / arrival angles the first time a route is drawn: the burn on
## the side of the origin facing the destination, the arrival on the side of
## the destination facing the origin (both on the visible side).
func _plan_transfer(ship: ShipData, ob: Dictionary, db: Dictionary) -> void:
	var dir: float = signf(ship.orbit_speed) if ship.orbit_speed != 0.0 else 1.0
	if is_nan(ship.transfer_depart_angle):
		ship.transfer_depart_angle = _facing_angle(ship, ob, db["c"], _depart_radius(ship))
	if is_nan(ship.transfer_arrive_angle):
		ship.transfer_arrive_angle = _facing_angle(ship, db, ob["c"], -1.0) + dir * CAPTURE_ARC

## The orbit a transfer leaves from: traffic its own ring, others the parking orbit.
static func _depart_radius(ship: ShipData) -> float:
	return ship.orbit_radius if ship.ship_type == "freighter" else PARKING_RADIUS

func _facing_angle(ship: ShipData, b: Dictionary, toward: Vector2, radius: float) -> float:
	var c: Vector2 = b["c"]
	var want := (toward - c).normalized()
	var best_a := 0.0
	var best := -INF
	for i in 72:
		var a := TAU * float(i) / 72.0
		var v := _orbit_pt(ship, a, b, radius)
		if v.z > 0.0:
			continue
		var d := (Vector2(v.x, v.y) - c).normalized().dot(want)
		if d > best:
			best = d
			best_a = a
	return best_a

## Where a transfer is at progress p: Vector3(x, y, 1 if hidden behind a body).
## Vector3.INF when an end isn't on screen.
func _transfer_point(ship: ShipData, p: float, ob: Dictionary, db: Dictionary) -> Vector3:
	if ship.ship_type == "freighter":   # traffic: Central Orbit → Central Orbit
		var hp := _hub_route_point(ship, p, ob, db)
		if hp.is_finite():
			return hp
	var dir: float = signf(ship.orbit_speed) if ship.orbit_speed != 0.0 else 1.0
	var burn := ship.transfer_depart_angle
	var entry := ship.transfer_arrive_angle - dir * CAPTURE_ARC
	var park := _depart_radius(ship)
	if p <= DEPART_FRAC:
		var a := burn - dir * DEPART_ARC * (1.0 - p / DEPART_FRAC)
		if ship.ship_type == "freighter":   # traffic leaves from where it orbits
			var lead := fposmod((burn - ship.orbit_angle) * dir, TAU)
			a = ship.orbit_angle + dir * lead * (p / DEPART_FRAC)
		var v := _orbit_pt(ship, a, ob, park)
		return Vector3(v.x, v.y, 1.0 if _hidden_by(v, ob) else 0.0)
	if p >= 1.0 - CAPTURE_FRAC:
		var k := (p - (1.0 - CAPTURE_FRAC)) / CAPTURE_FRAC
		var v := _orbit_pt(ship, entry + dir * CAPTURE_ARC * k, db)
		return Vector3(v.x, v.y, 1.0 if _hidden_by(v, db) else 0.0)
	# transfer arc: leaves the parking orbit and joins the destination orbit
	# along their directions of travel
	var a0 := _orbit_pt(ship, burn, ob, park)
	var a0n := _orbit_pt(ship, burn + dir * 0.05, ob, park)
	var c0 := _orbit_pt(ship, entry, db)
	var c0p := _orbit_pt(ship, entry - dir * 0.05, db)
	var s := Vector2(a0.x, a0.y)
	var e := Vector2(c0.x, c0.y)
	var span := s.distance_to(e)
	var p1 := s + (Vector2(a0n.x, a0n.y) - s).normalized() * span * 0.5
	var p2 := e - (e - Vector2(c0p.x, c0p.y)).normalized() * span * 0.5
	var t := (p - DEPART_FRAC) / (1.0 - DEPART_FRAC - CAPTURE_FRAC)
	var u := 1.0 - t
	var q := s * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + e * t * t * t
	return Vector3(q.x, q.y, 0.0)

func _draw_transits() -> void:
	var cv := _transit_canvas
	var o := cv.global_position
	var mouse := cv.get_global_mouse_position()
	var hovered: ShipData = null
	var hovered_pos := Vector2.ZERO
	for ship: ShipData in _transits:
		var ob := _body_screen(_find_body(ship.orbit_seed))
		var db := _body_screen(_find_body(ship.dest_seed))
		if ob.is_empty() or db.is_empty():
			continue
		_plan_transfer(ship, ob, db)
		var p := clampf(ship.travel_progress, 0.0, 1.0)
		# the route ahead, faint and dashed — traffic throws it out as it sets off
		var reach := clampf(p / 0.12, 0.0, 1.0) if ship.ship_type == "freighter" else 1.0
		var lane_a := 0.30 if ship.ship_type == "freighter" else 0.35
		var end_q := lerpf(p, 1.0, reach)
		var prev := _transfer_point(ship, p, ob, db)
		for q in range(1, 41):
			var cur := _transfer_point(ship, lerpf(p, end_q, float(q) / 40.0), ob, db)
			if q % 2 == 0 and prev.z < 0.5 and cur.z < 0.5:
				cv.draw_line(Vector2(prev.x, prev.y) - o, Vector2(cur.x, cur.y) - o, Color(0.65, 0.85, 1.0, lane_a), 1.0)
			prev = cur
		# trail: the route just behind (hidden where a body covers it)
		const TRAIL := 0.12
		for k in 18:
			var q := p - TRAIL * float(k + 1) / 18.0
			if q < 0.0:
				break
			var tp := _transfer_point(ship, q, ob, db)
			if tp.z < 0.5:
				draw_trail_dot(cv, Vector2(tp.x, tp.y) - o, 1.0 - float(k) / 18.0)
		var at := _transfer_point(ship, p, ob, db)
		if at.z > 0.5:
			continue   # behind a body right now
		var pos := Vector2(at.x, at.y)
		if pos.distance_to(mouse) <= 8.0:
			hovered = ship
			hovered_pos = pos
		var nx := _transfer_point(ship, minf(1.0, p + 0.004), ob, db)
		var heading := (Vector2(nx.x, nx.y) - pos).normalized() if Vector2(nx.x, nx.y).distance_to(pos) > 0.01 else Vector2.RIGHT
		# engine burn, glued to the hull on the side away from the heading
		var burn_at := 0.0 if ship.ship_type == "freighter" else DEPART_FRAC
		if p > burn_at - 0.03 and p < burn_at + 0.12:
			var hue: float = 0.45 + randf() * 0.25
			var f := (pos - o - Vector2.ONE).floor() - (heading * 3.0).round()
			cv.draw_rect(Rect2(f, Vector2(2, 2)), Color(1.0, hue, 0.05, 0.9))
		var col := Color(1.0, 0.92, 0.40) if ship == hovered else Color(1, 1, 1, 0.92)
		draw_ship_sprite(cv, pos - o, ship.ship_type, col)
	if hovered != null:   # same nameplate as ships in orbit
		_draw_transit_label(cv, hovered_pos - o, hovered, ob_center_of(hovered) - o)
		if not _transit_hover:
			AudioManager.play("hover")
		_transit_hover = true
	else:
		_transit_hover = false
	# mid-switch the orbital layer is down: keep the stand-ins' ships flying
	for pd: PlanetData in _switch_ghosts:
		var b := _body_screen(pd)
		if b.is_empty():
			continue
		for ship: ShipData in ShipManager.ships_for(pd.seed):
			if ship.is_travelling():
				continue
			var v := _orbit_screen(ship, ship.orbit_angle, b)
			if _hidden_by(v, b):
				continue
			cv.draw_rect(Rect2(Vector2(v.x, v.y) - o - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.92))

## Screen point of a world's Central Orbit (`b` from _body_screen); z > 0 is
## behind the body. Vector3.INF when it has none.
func _hub_point(seed_val: int, b: Dictionary) -> Vector3:
	var hub := Leveling.orbit_hub(GameState.get_planet_data(seed_val))
	if hub == null or hub.constructing or b.is_empty():
		return Vector3.INF
	var proxy := ShipData.new()   # same orbit maths as ships
	proxy.orbit_radius = hub.orbit_radius
	proxy.orbit_inclination = hub.orbit_inclination
	proxy.orbit_node = hub.orbit_node
	return _orbit_screen(proxy, hub.orbit_angle, b)

## A freighter's place on its hub-to-hub route: leaves its world's Central
## Orbit outward, bends toward the other world and comes in to its Central
## Orbit. z = 1 while over a disc whose hub sits behind it.
func _hub_route_point(ship: ShipData, p: float, ob: Dictionary, db: Dictionary) -> Vector3:
	var ha := _hub_point(ship.orbit_seed, ob)
	var hb := _hub_point(ship.dest_seed, db)
	if not ha.is_finite() or not hb.is_finite():
		return Vector3.INF
	var a := Vector2(ha.x, ha.y)
	var b := Vector2(hb.x, hb.y)
	var ca: Vector2 = ob["c"]
	var cb: Vector2 = db["c"]
	var to_b := (cb - ca).normalized()
	var dist := a.distance_to(b)
	var out_a := ((a - ca).normalized() + to_b).normalized()
	var out_b := ((b - cb).normalized() - to_b).normalized()
	var t := smoothstep(0.0, 1.0, p)
	var q := a.bezier_interpolate(a + out_a * dist * 0.4, b + out_b * dist * 0.4, b, t)
	# a little to the side, by ship, so traffic reads as several ships
	q += to_b.orthogonal() * (float(posmod(hash(ship.ship_id), 5)) - 2.0) * 1.5 * sin(t * PI)
	var hidden := (ha.z > 0.0 and q.distance_to(ca) < float(ob["r"])) \
		or (hb.z > 0.0 and q.distance_to(cb) < float(db["r"]))
	return Vector3(q.x, q.y, 1.0 if hidden else 0.0)

## The eye button: orbits, ships and the flights between worlds.
var _orbits_shown := true

static func draw_trail_dot(cv: CanvasItem, p: Vector2, a: float) -> void:
	cv.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.65, 0.25, a * 0.55))

## A ship's own pixel art (OrbitalLayer's sprites), unrotated like in orbit.
static func draw_ship_sprite(cv: CanvasItem, pos: Vector2, ship_type: String, col: Color) -> void:
	var p := (pos - Vector2.ONE).floor()
	match ship_type:
		"lander":
			cv.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(6, 4)), col)
			cv.draw_rect(Rect2(p + Vector2(0, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0, col.a))
			cv.draw_rect(Rect2(p + Vector2(-4, 2), Vector2(2, 2)), Color(col, col.a * 0.8))
			cv.draw_rect(Rect2(p + Vector2(4, 2), Vector2(2, 2)), Color(col, col.a * 0.8))
		"station":
			cv.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(6, 6)), col)
			cv.draw_rect(Rect2(p + Vector2(-8, 0), Vector2(6, 2)), Color(0.30, 0.60, 1.0, col.a))
			cv.draw_rect(Rect2(p + Vector2(4, 0), Vector2(6, 2)), Color(0.30, 0.60, 1.0, col.a))
		_:
			cv.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(2, 2)), col)
			cv.draw_rect(Rect2(p + Vector2(0, -2), Vector2(2, 2)), col)
			cv.draw_rect(Rect2(p, Vector2(2, 2)), col)

var _transit_hover := false

func ob_center_of(ship: ShipData) -> Vector2:
	var b := _body_screen(_find_body(ship.orbit_seed))
	return b["c"] if not b.is_empty() else Vector2.ZERO

## Hover nameplate for a ship between worlds: leader line + name + where to.
func _draw_transit_label(cv: CanvasItem, spos: Vector2, ship: ShipData, from_c: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	const FONT_SIZE: int = 10
	var horiz_dir: float = 1.0 if spos.x >= from_c.x else -1.0
	var vert_dir: float = -1.0 if spos.y >= from_c.y else 1.0
	var diag_end := spos + Vector2(horiz_dir * 9.8, vert_dir * 14.0)
	var horiz_end := diag_end + Vector2(horiz_dir * 20.0, 0.0)
	var accent := Color(1.0, 0.95, 0.55, 0.85)
	cv.draw_line(spos, diag_end, Color(accent, 0.65), 1.0, true)
	cv.draw_line(diag_end, horiz_end, Color(accent, 0.65), 1.0, true)
	var dest := GameState.get_planet_data(ship.dest_seed)
	var left := int(ceil((1.0 - ship.travel_progress) * ship.travel_duration))
	var label := "%s → %s · %d:%02d" % [ship.ship_name, dest.planet_name if dest != null else "?",
		floori(float(left) / 60.0), left % 60]
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var label_pos := horiz_end + Vector2(horiz_dir * 3.0, text_size.y * 0.35)
	if horiz_dir < 0.0:
		label_pos.x -= text_size.x
	for ox: int in [-1, 0, 1]:
		for oy: int in [-1, 0, 1]:
			if ox == 0 and oy == 0: continue
			cv.draw_string(font, label_pos + Vector2(ox, oy), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.75))
	cv.draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, accent)

## A flight reached a body: if we're watching from the other end, follow it.
func _on_ship_arrived_here(ship: ShipData) -> void:
	if current_data == null or ship.ship_type != "lander":
		return
	var dest := _find_body(ship.orbit_seed)
	if dest != null and dest != current_data:
		var cc: Vector2 = _companions.center_of(dest)
		if cc.is_finite():
			var r: float = _companions.radius_of(dest) / 0.40
			_switch_to_body(dest, Rect2(cc - Vector2(r, r) * 0.5, Vector2(r, r)))
			return
	_refresh_active_panel()

## Planet radius (fraction of view height) and shader cell count _setup_material
## gives `pd` — so a switch can animate to the body's real on-screen size.
func _base_radius_for(pd: PlanetData) -> float:
	return clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * PLANET_VIEW_SCALE

func _pixel_count_for(pd: PlanetData) -> float:
	var sz := clampf(pd.planet_size, 0.2, 2.0)
	return 140.0 if sz <= 1.2 else roundf(clampf(140.0 * (sz / 1.2), 140.0, 280.0))

## A stand-in body for the switch animation (radius 0.40 of its rect).
## On-screen rect a body's globe fills (radius 0.40 of it), live — follows the
## planet area as the side panel slides.
func _globe_rect(base_radius: float, zoom: float) -> Rect2:
	var cont := planet_renderer.get_parent() as Control
	var centre := planet_renderer.global_position + planet_renderer.size * 0.5
	var sz := Vector2.ONE * cont.size.y * base_radius * zoom / 0.40
	return Rect2(centre - sz * 0.5, sz)

func _body_ghost(pd: PlanetData, rect: Rect2, cells: float) -> ColorRect:
	var g := ColorRect.new()
	g.material = CompanionScript._material_for(pd, rect.size.x)
	(g.material as ShaderMaterial).set_shader_parameter("pixel_count", cells)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.z_index = 30
	(planet_renderer.get_parent() as Control).add_child(g)
	g.global_position = rect.position
	g.size = rect.size
	return g

## Clicked a neighbour: it grows into the centre at its real size while this
## body shrinks into the corner slot it will hold, then the view loads it —
## still zoomed out, so the old body is the neighbour now.
func _switch_to_body(pd: PlanetData, from_rect: Rect2) -> void:
	if _switching_body or pd == current_data:
		return
	_switching_body = true
	_end_district_placement()
	AudioManager.play("click")
	# a fade-in still running from the last switch would fight this one
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if _reveal_ghost != null and is_instance_valid(_reveal_ghost):
		_reveal_ghost.queue_free()
	var cont := planet_renderer.get_parent() as Control
	var old := current_data
	var centre := planet_renderer.global_position + planet_renderer.size * 0.5
	# where things end up
	var new_list := _companion_list(pd)
	var new_parent := _companion_parent
	_companion_list(old)   # restore _companion_parent for the current body
	var slots: Dictionary = _companions.predict_rects(new_list, new_parent)
	var old_slot: Rect2 = slots.get(old, Rect2(Vector2(cont.size.x + 40.0, -200.0), Vector2(96, 96)))
	old_slot.position += _companions.global_position
	var cell_new := cont.size.y / _pixel_count_for(pd)
	var cell_old := cont.size.y / _pixel_count_for(old)
	var new_size := Vector2.ONE * cont.size.y * _base_radius_for(pd) * ZOOM_SYSTEM / 0.40
	var old_size := Vector2.ONE * cont.size.y * _base_radius * _zoom / 0.40
	# stand-ins: the clicked body, and ours in place of the live globe
	var g_new := _body_ghost(pd, from_rect, from_rect.size.y * 0.5)
	var g_old := _body_ghost(old, Rect2(centre - old_size * 0.5, old_size), old_size.y / cell_old)
	_switch_ghosts = {pd: g_new, old: g_old}
	# the bigger world always passes in front (going to the Moon and coming back)
	g_old.z_index = 31 if old.planet_size >= pd.planet_size else 29
	_companions.fade = 0.0
	for n: CanvasItem in [_planet_view, poi_layer, _orbital_layer]:
		if n != null and is_instance_valid(n):
			n.modulate.a = 0.0
	# spin + sunlight slide from each body's corner look to its globe look (and
	# back), so neither stand-in pops when it is swapped for the real thing
	var la: float = planet_renderer.light_angle
	var spin0: float = _companions.spin()
	var rot_old: float = planet_renderer.get_rotation_offset()
	var rot_new := spin0
	for p: POIData in pd.custom_pois:
		if not p.is_orbital():
			rot_new = deg_to_rad(p.lon_deg)   # load_planet faces the first district
			break
	var shade := func(g: ColorRect, body: PlanetData, r0: float, r1: float, t: float) -> void:
		var r := lerp_angle(r0, r1, t)
		var m := g.material as ShaderMaterial
		m.set_shader_parameter("rotation_offset", r)
		m.set_shader_parameter("light_direction", CompanionScript.light_dir(la + body.local_time_offset + r))
	shade.call(g_new, pd, spin0, rot_new, 0.0)
	shade.call(g_old, old, rot_old, spin0, 0.0)
	const DUR := 0.8
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float) -> void:
		shade.call(g_new, pd, spin0, rot_new, t)
		shade.call(g_old, old, rot_old, spin0, t), 0.0, 1.0, DUR)
	# targets are re-read every frame: the side panel may slide meanwhile
	var from_new := from_rect
	var from_old := Rect2(centre - old_size * 0.5, old_size)
	tw.tween_method(func(t: float) -> void:
		var live := _globe_rect(_base_radius_for(pd), ZOOM_SYSTEM)
		var r := Rect2(from_new.position.lerp(live.position, t), from_new.size.lerp(live.size, t))
		g_new.global_position = r.position
		g_new.size = r.size
		var slot: Rect2 = _companions.predict_rects(new_list, new_parent).get(old,
			Rect2(Vector2(cont.size.x + 40.0, -200.0), Vector2(96, 96)))
		slot.position += _companions.global_position
		g_old.global_position = from_old.position.lerp(slot.position, t)
		g_old.size = from_old.size.lerp(slot.size, t), 0.0, 1.0, DUR)
	tw.tween_method(func(c: float) -> void: (g_new.material as ShaderMaterial).set_shader_parameter("pixel_count", c),
		from_rect.size.y * 0.5, new_size.y / cell_new, DUR)
	tw.tween_method(func(c: float) -> void: (g_old.material as ShaderMaterial).set_shader_parameter("pixel_count", c),
		old_size.y / cell_old, old_slot.size.y * 0.5, DUR)
	await tw.finished
	if pd.planet_type == PlanetData.Type.MOON or _companion_parent == pd:
		pd.set_meta("__solar_data", _system_solar if _system_solar != null else GameState.get_home_solar())
	_district_reveal = 0.0
	load_planet(pd)
	planet_renderer.set_rotation_offset(rot_new)   # exactly where the stand-in stopped
	_zoom = ZOOM_SYSTEM
	_zoom_target = ZOOM_SYSTEM
	_apply_zoom()
	_companions.fade = 1.0
	_planet_view.modulate.a = 1.0
	_switch_ghosts.clear()
	g_old.queue_free()
	# the stand-in dissolves into the real globe; then settlements, lights,
	# markers and orbits come in instead of popping
	var tw2 := create_tween().set_parallel(true)
	_reveal_tween = tw2
	_reveal_ghost = g_new
	tw2.tween_property(g_new, "modulate:a", 0.0, 0.45)
	tw2.tween_property(self, "_district_reveal", 1.0, 1.3).set_delay(0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for n: CanvasItem in [poi_layer, _orbital_layer]:
		if n != null and is_instance_valid(n):
			tw2.tween_property(n, "modulate:a", 1.0, 0.6).set_delay(0.9)
	tw2.chain().tween_callback(g_new.queue_free)
	_switching_body = false

# ── Moon landing ─────────────────────────────────────────────────────────────

## PREPARE LANDER on an uncolonised Moon (GDD §20.4): pays once, the lander
## is prepared for 30 s at the home Spaceport and then flies on its own.
func _setup_moon_colonize_button(btn: Button, data: PlanetData) -> void:
	var refresh := func() -> void:
		if not is_instance_valid(btn):
			return
		var ex := GameState.expedition("lander")
		var lst := String(ex.get("state", ""))
		if lst == "preparing":
			btn.text = "PREPARING LANDER — %ds" % int(ceil(float(ex.get("prep_left", 0.0))))
			btn.modulate = Color(0.85, 0.9, 1.0)
		elif lst == "launching":
			btn.text = "LANDER LIFTING OFF"
			btn.modulate = Color(0.85, 0.9, 1.0)
		elif lst == "orbiting":
			btn.text = "LANDER CIRCLING HOME — %d%%" % int(round((1.0 - float(ex.get("loop_left", TAU)) / TAU) * 100.0))
			btn.modulate = Color(0.85, 0.9, 1.0)
		else:
			btn.text = "PREPARE LANDER"
			btn.modulate = Color.WHITE if GameState.moon_colonize_block(data.seed) == "" else Color(0.6, 0.62, 0.7)
	refresh.call()
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(refresh)
	btn.add_child(timer)
	btn.mouse_entered.connect(func() -> void:
		var block := GameState.moon_colonize_block(data.seed)
		TooltipManager.show_tip("Colonize " + data.planet_name,
			"Prepare a lander at your home Spaceport (%ds), then it flies to the Moon (%ds) and parks in orbit. Pick where to found your first City here — the first City is free.\n\n" % [
				int(GameState.LANDER_PREP_SEC), int(GameState.MOON_TRANSIT_SEC)]
			+ _full_cost_bb(GameState.LANDER_COST, 0, data, GameState.get_planet(data.seed))
			+ ("" if block == "" else "\n\n" + _bb(block, BB_BAD))))
	btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	btn.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if GameState.start_moon_colonization(data.seed):
			AudioManager.play("click")
			refresh.call()
			_go_to_spaceport()   # watch the lander being built at the Spaceport
		else:
			AudioManager.play("error"))

## The final rocket on the Moon's page (GDD §20.12–§20.18): its state, cost,
## target and the button that starts its preparation.
func _add_rocket_section(page: Control, data: PlanetData) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var head := Label.new()
	head.text = "FINAL ROCKET"
	_apply_orbitron(head, 10)
	head.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	box.add_child(head)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.scroll_active = false
	info.add_theme_font_size_override("normal_font_size", 10)
	box.add_child(info)
	var btn := Button.new()
	_apply_orbitron(btn, 10)
	box.add_child(btn)
	var refresh := func() -> void:
		if not is_instance_valid(info):
			return
		var ex := GameState.expedition("rocket")
		var st := String(ex.get("state", ""))
		var tgt := int(ex.get("target_seed", -1))
		var tname := "none — right-click a planet in the Solar System view"
		var tpd: PlanetData = GameState.get_planet_data(tgt) if tgt >= 0 else null
		if tpd != null:
			tname = tpd.planet_name
		var lines: Array[String] = []
		lines.append("Moonstone mined on the Moon  %s / 100" % Economy.fmt(minf(GameState.moon_local_moonstone, 100.0)))
		match st:
			"":
				lines.append("Cost  " + _full_cost_bb(GameState.ROCKET_COST, 0, data, GameState.get_planet(data.seed)))
				lines.append("Preparation %ds · flight %ds" % [int(GameState.ROCKET_PREP_SEC), int(GameState.ROCKET_FLIGHT_SEC)])
				var block := GameState.rocket_block()
				if block != "":
					lines.append(_bb(block, BB_BAD))
				btn.visible = true
				btn.text = "PREPARE ROCKET"
				btn.disabled = block != ""
			"preparing":
				lines.append("Preparing — %ds left" % int(ceil(float(ex.get("prep_left", 0.0)))))
				lines.append("Target  " + tname)
				btn.visible = false
			"ready":
				lines.append("Ready — waiting for a target")
				lines.append(_bb("Right-click a planet in the Solar System view to pick it.", BB_WARN))
				btn.visible = false
			"in_transit":
				lines.append("On its way to %s — %ds left" % [tname, int(ceil(float(ex.get("flight_left", 0.0))))])
				btn.visible = false
			"arrived":
				lines.append(_bb("Arrived at %s — Civilization 1 reached." % tname, "#8ef59a"))
				btn.visible = false
		info.text = "\n".join(lines)
	refresh.call()
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(refresh)
	box.add_child(timer)
	btn.pressed.connect(func() -> void:
		if GameState.start_rocket():
			AudioManager.play("click")
			refresh.call()
		else:
			AudioManager.play("error"))
	page.add_child(box)

## The lander parked in orbit, as an "ORBIT" entry of the Moon's page: from
## here the player initiates colonization (picks the first City's site).
func _add_found_settlement_button(page: Control) -> void:
	var head := Label.new()
	head.text = "ORBIT"
	_apply_orbitron(head, 9)
	head.add_theme_color_override("font_color", Color(0.55, 0.65, 0.95))
	page.add_child(head)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_panel_style())
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	card.add_child(row)
	var hub_lbl := Label.new()
	hub_lbl.text = "◈  Central Orbit — set up by the lander"
	_apply_orbitron(hub_lbl, 9)
	hub_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	row.add_child(hub_lbl)
	var name_lbl := Label.new()
	name_lbl.text = "◆  Colony Lander"
	_apply_orbitron(name_lbl, 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	row.add_child(name_lbl)
	var scanned := GameState.is_scanned(current_data.seed)
	var paid := GameState.landing_paid.has(current_data.seed)
	var note := Label.new()
	note.text = ("Surface scanned. " if scanned else "Scan the surface first (free) to see where things thrive. ") \
		+ ("Initiate colonization and pick the site of the first City." if paid \
		else "Landing the first City: %s." % Economy.cost_text(GameState.LANDING_COST))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_orbitron(note, 8)
	note.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0))
	row.add_child(note)
	page.add_child(card)
	var btn := Button.new()
	btn.text = "INITIATE COLONIZATION"
	_apply_orbitron(btn, 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.32, 0.12)
	sb.content_margin_top = 10; sb.content_margin_bottom = 10
	sb.set_border_width_all(1)
	sb.border_color = Color(0.25, 0.75, 0.30, 0.8)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var hb := sb.duplicate() as StyleBoxFlat
	hb.bg_color = Color(0.15, 0.48, 0.18)
	btn.add_theme_stylebox_override("hover", hb)
	btn.add_theme_color_override("font_color", Color(0.80, 1.0, 0.82))
	btn.pressed.connect(_begin_lunar_landing)
	if not scanned:
		var scan_btn := Button.new()
		scan_btn.text = "SCAN SURFACE  ·  free"
		_apply_orbitron(scan_btn, 11)
		scan_btn.pressed.connect(func() -> void: _start_surface_scan(current_data))
		page.add_child(scan_btn)
		btn.disabled = true
		btn.tooltip_text = "Scan the surface first"
	elif not paid and not Economy.can_pay(GameState.LANDING_COST):
		btn.disabled = true
		btn.tooltip_text = Economy.cost_block(GameState.LANDING_COST)
	if not paid:
		btn.text += "  ·  " + Economy.cost_text(GameState.LANDING_COST)
	page.add_child(btn)

## The lander leaves the home Spaceport: when the home world is on screen it
## lifts off from the Capital like a station launch, then GameState lets it
## lap the planet once and sends it to the Moon.
func _on_expedition_changed(kind: String) -> void:
	if kind != "lander" or current_data == null or GameState.showcase_mode:
		return
	var ex := GameState.expedition("lander")
	if String(ex.get("state", "")) != "launching" or bool(ex.get("animating", false)):
		return
	if current_data.seed != GameState.home_planet_seed:
		return
	var pad := _spaceport_pad(current_data)
	if pad == null:
		return
	ex["animating"] = true
	_rotate_to_lon(pad.lon_deg, 0.5)
	_play_rocket_animation(current_data.seed, pad, _on_lander_lifted, "", "Colony Lander", "lander")
	_refresh_active_panel()

## The district that holds the Spaceport (a Capital), else the first City.
func _spaceport_pad(data: PlanetData) -> POIData:
	var pad: POIData = null
	var pp := GameState.get_planet(data.seed)
	for p: POIData in data.custom_pois:
		if p.is_city() and not p.is_orbital() and not p.constructing:
			if pp.buildings_in_district(p.label).any(
					func(b: Dictionary) -> bool: return b.get("building_id", "") == "spaceport"):
				return p
			if pad == null:
				pad = p
	return pad

## After PREPARE LANDER: fly to the home world and show the Spaceport's district
## (its panel shows the build; its marker gets a construction bar).
var _focus_spaceport_pending := false

func _go_to_spaceport() -> void:
	var home := GameState.get_planet_data(GameState.home_planet_seed)
	if home == null:
		return
	_focus_spaceport_pending = true
	if current_data != null and current_data.seed != home.seed:
		var from := Rect2()
		var cc: Vector2 = _companions.center_of(home) if _companions != null else Vector2.INF
		if cc.is_finite():
			var cr: float = _companions.radius_of(home) / 0.40
			from = Rect2(cc - Vector2(cr, cr) * 0.5, Vector2(cr, cr))
		_switch_to_body(home, from)

func _tick_spaceport_focus() -> void:
	# the lander's build as a construction bar on the Spaceport's marker
	var bars := {}
	var ex := GameState.expedition("lander")
	if current_data != null and current_data.seed == GameState.home_planet_seed \
			and String(ex.get("state", "")) == "preparing":
		var pad := _spaceport_pad(current_data)
		if pad != null:
			bars[pad.label] = 1.0 - float(ex.get("prep_left", 0.0)) / GameState.LANDER_PREP_SEC
	poi_layer.extra_progress = bars
	if not _focus_spaceport_pending or _switching_body or current_data == null \
			or current_data.seed != GameState.home_planet_seed:
		return
	_focus_spaceport_pending = false
	var pad2 := _spaceport_pad(current_data)
	if pad2 == null:
		return
	_focus_on_site(pad2.lon_deg, pad2.lat_deg, 0.6)
	_set_zoom_target(maxf(_zoom_target, 1.8), Vector2.INF)
	_open_capital(pad2)

# ── Moon lander: orbit, departure and camera follow ──────────────────────────

## Planet-frame direction (OrbitalLayer's frame) of a surface point.
static func _frame_dir(lon: float, lat: float) -> Vector3:
	return Vector3(cos(lat) * sin(lon), -sin(lat), -cos(lat) * cos(lon))

## The lander's orbit starts exactly where its lift-off ended and carries on in
## the direction it was flying (so it reads as one continuous flight).
func _fit_lander_orbit(ship: ShipData, d: Dictionary) -> void:
	var fallback := Vector2(float(d["poi_lon"]) + float(d["sweep_target"]), float(d["lat_target"]))
	var a: Vector2 = d.get("last_abs", fallback)
	var b: Vector2 = d.get("prev_abs", a)
	var p := _frame_dir(a.x, a.y)
	var tdir := _frame_dir(b.x, b.y)
	tdir = p - tdir
	tdir -= p * tdir.dot(p)
	if tdir.length() < 1e-6:
		tdir = p.cross(Vector3.UP)
		if tdir.length() < 1e-6:
			tdir = Vector3.RIGHT
	tdir = tdir.normalized()
	var nrm := p.cross(tdir).normalized()
	var inc := acos(clampf(-nrm.y, -1.0, 1.0))
	var node := atan2(nrm.x, nrm.z) if sin(inc) > 1e-5 else 0.0
	var u := Vector3(cos(node), 0.0, -sin(node))
	var w := Vector3(cos(inc) * sin(node), sin(inc), cos(inc) * cos(node))
	ship.orbit_inclination = inc
	ship.orbit_node = node
	ship.orbit_angle = atan2(p.dot(w), p.dot(u))
	ship.orbit_radius = 1.06
	ship.orbit_speed = absf(ship.orbit_speed) if ship.orbit_speed != 0.0 else 0.1

## The lander ship in the home orbit (null when it isn't there).
func _home_lander_ship() -> ShipData:
	if GameState.expedition_state("lander") != "orbiting":
		return null
	var id := String(GameState.expedition("lander").get("ship_id", ""))
	for sh: ShipData in ShipManager.ships_for(GameState.home_planet_seed):
		if sh.ship_id == id:
			return sh
	return null

## The lander's rocket while it lifts off (its animation record), or {}.
func _lander_rocket() -> Dictionary:
	for d: Dictionary in _rocket_anims:
		if String(d.get("ship_type", "")) == "lander" and is_instance_valid(d.get("rocket")):
			return d
	return {}

## Screen direction of the Moon from a point: its corner slot when shown,
## else up-right (where the corner slots are).
func _moon_dir_from(p: Vector2) -> Vector2:
	var moon := GameState.home_moon()
	if moon != null and _companions != null:
		var cc: Vector2 = _companions.center_of(moon)
		if cc.is_finite() and cc.distance_to(p) > 1.0:
			return (cc - p).normalized()
	return Vector2(0.75, -0.66).normalized()

## While the home world is on screen, the orbiting lander leaves at the point
## of its orbit that heads for the Moon (after at least ~40% of a lap).
func _tick_lander_watch() -> void:
	if current_data == null or current_data.seed != GameState.home_planet_seed:
		return
	var ship := _home_lander_ship()
	if ship == null or _orbital_layer == null or not is_instance_valid(_orbital_layer) or not _depart_fx.is_empty():
		return
	var ex := GameState.expedition("lander")
	ex["watched_ms"] = Time.get_ticks_msec()
	if float(ex.get("loop_left", TAU)) > TAU * 0.6:
		return
	var v0 := _orbital_layer._project(ship, ship.orbit_angle)
	if _orbital_layer._is_occluded(v0):
		return
	var v1 := _orbital_layer._project(ship, ship.orbit_angle + 0.02 * signf(ship.orbit_speed))
	var dir := Vector2(v1.x - v0.x, v1.y - v0.y)
	if dir.length() < 1e-4:
		return
	var lc := _orbital_layer.get_global_rect().position + _orbital_layer._center_now()
	var p0 := lc + Vector2(v0.x, v0.y)
	if dir.normalized().dot(_moon_dir_from(p0)) > 0.92:
		_start_lander_departure(ship, p0, dir.normalized())

# departure: { t, dur, p0, dir, target, ring: PackedVector2Array, trail: Array }
var _depart_fx: Dictionary = {}
var _depart_canvas: Control = null
const DEPART_SEC := 2.6

func _start_lander_departure(ship: ShipData, p0: Vector2, dir: Vector2) -> void:
	var lc := _orbital_layer.get_global_rect().position + _orbital_layer._center_now()
	var ring := PackedVector2Array()
	var ring_vis := PackedByteArray()
	for i in 91:   # the orbit ahead of the ship, closed by the departure
		var v := _orbital_layer._project(ship, ship.orbit_angle + signf(ship.orbit_speed) * TAU * float(i) / 90.0)
		ring.append(lc + Vector2(v.x, v.y))
		ring_vis.append(0 if _orbital_layer._is_occluded(v) else 1)
	var moon := GameState.home_moon()
	var target := p0 + _moon_dir_from(p0) * 1600.0
	if moon != null and _companions != null and _companions.center_of(moon).is_finite():
		target = _companions.center_of(moon)
	_depart_fx = {"t": 0.0, "p0": p0, "dir": dir, "target": target, "ring": ring,
		"ring_vis": ring_vis, "trail": [], "pos": p0}
	if _depart_canvas == null or not is_instance_valid(_depart_canvas):
		_depart_canvas = Control.new()
		_depart_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_depart_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_depart_canvas.z_index = 40
		_depart_canvas.draw.connect(_draw_lander_departure)
		(planet_renderer.get_parent() as Control).add_child(_depart_canvas)
	AudioManager.play("rocket", -6.0)
	GameState.depart_lander_now()   # the flight to the Moon starts now

func _tick_departure_fx(delta: float) -> void:
	if _depart_fx.is_empty():
		return
	_depart_fx["t"] = float(_depart_fx["t"]) + delta
	var k := clampf(float(_depart_fx["t"]) / DEPART_SEC, 0.0, 1.0)
	var s := k * k   # accelerating
	var p0: Vector2 = _depart_fx["p0"]
	var c: Vector2 = p0 + (_depart_fx["dir"] as Vector2) * 220.0
	var tg: Vector2 = _depart_fx["target"]
	var pos := p0.lerp(c, s).lerp(c.lerp(tg, s), s)
	_depart_fx["pos"] = pos
	var trail: Array = _depart_fx["trail"]
	trail.push_front(pos)
	while trail.size() > 22:
		trail.pop_back()
	if is_instance_valid(_depart_canvas):
		_depart_canvas.queue_redraw()
	if k >= 1.0:
		_depart_fx = {}
		if is_instance_valid(_depart_canvas):
			_depart_canvas.queue_redraw()
		# step back so the flight between the worlds is in view
		if current_data != null and current_data.seed == GameState.home_planet_seed:
			_set_zoom_target(ZOOM_SYSTEM, Vector2.INF)

func _draw_lander_departure() -> void:
	if _depart_fx.is_empty():
		return
	var cv := _depart_canvas
	var o := cv.get_global_rect().position
	var k := clampf(float(_depart_fx["t"]) / DEPART_SEC, 0.0, 1.0)
	# the orbit line closes behind the ship as it speeds away
	var ring: PackedVector2Array = _depart_fx["ring"]
	var vis: PackedByteArray = _depart_fx["ring_vis"]
	var keep := int(float(ring.size()) * clampf(1.0 - k * 1.6, 0.0, 1.0))
	var start := ring.size() - keep
	for i in range(maxi(start, 1), ring.size()):
		if vis[i] == 1 and vis[i - 1] == 1 and (i % 6) < 3:
			cv.draw_line(ring[i - 1] - o, ring[i] - o, Color(1, 1, 1, 0.35 * (1.0 - k)), 1.2, true)
	# exhaust trail
	var trail: Array = _depart_fx["trail"]
	for i in trail.size():
		var a := (1.0 - float(i) / float(trail.size())) * 0.8
		var tp: Vector2 = trail[i]
		cv.draw_rect(Rect2(tp - o - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.7, 0.3, a))
	# the lander
	var pos: Vector2 = _depart_fx["pos"]
	cv.draw_rect(Rect2(pos - o - Vector2(2, 2), Vector2(5, 5)), Color(0.95, 0.97, 1.0))

# ── Camera follow (double-click the lander) ──────────────────────────────────
var _cam_follow_lander := false

func _tick_follow_ship(delta: float) -> void:
	var ship: ShipData = null
	if current_data != null:
		for sh: ShipData in ShipManager.ships_for(current_data.seed):
			if sh.ship_id == _cam_follow_ship_id:
				ship = sh
	# let go when the player drags, or the ship lands / leaves this world
	if planet_renderer._dragging or ship == null or ship.is_travelling() or ship.traffic_state == "pad" \
			or _orbital_layer == null or not is_instance_valid(_orbital_layer):
		_cam_follow_ship_id = ""
		return
	var f := _orbital_layer._frame_point(ship, ship.orbit_angle).normalized()
	var k := 1.0 - exp(-delta * 5.0)
	planet_renderer.set_rotation_offset(lerp_angle(planet_renderer.get_rotation_offset(), atan2(f.x, -f.z), k))
	planet_renderer.set_tilt(lerpf(planet_renderer.tilt, asin(clampf(-f.y, -1.0, 1.0)), k))

## Where the lander is on screen right now (Vector2.INF if not here).
func _lander_screen_pos() -> Vector2:
	if not _depart_fx.is_empty():
		return _depart_fx["pos"]
	var d := _lander_rocket()
	if not d.is_empty():
		return (d["container"] as Control).get_global_rect().position + (d["rocket"] as Control).position
	var ship := _home_lander_ship()
	if ship != null and current_data != null and current_data.seed == GameState.home_planet_seed \
			and _orbital_layer != null and is_instance_valid(_orbital_layer):
		var v := _orbital_layer._project(ship, ship.orbit_angle)
		if not _orbital_layer._is_occluded(v):
			return _orbital_layer.get_global_rect().position + _orbital_layer._center_now() + Vector2(v.x, v.y)
	return Vector2.INF

## Surface point under the lander (lon, lat), for the follow camera; INF if none.
func _lander_lonlat() -> Vector2:
	var d := _lander_rocket()
	if not d.is_empty():
		return Vector2(float(d["poi_lon"]) + float(d["lon_sweep"]), float(d["poi_lat"]) + float(d["lat_sweep"]))
	var ship := _home_lander_ship()
	if ship != null and _orbital_layer != null and is_instance_valid(_orbital_layer):
		var f := _orbital_layer._frame_point(ship, ship.orbit_angle).normalized()
		return Vector2(atan2(f.x, -f.z), asin(clampf(-f.y, -1.0, 1.0)))
	return Vector2.INF

var _cam_follow_ship_id := ""   # any other ship in this world's orbit

func _try_follow_lander(at: Vector2) -> bool:
	var p := _lander_screen_pos()
	if not p.is_finite() or p.distance_to(at) > 18.0:
		# any other ship here (freighters, shuttles): double-click follows it too
		if _orbital_layer != null and is_instance_valid(_orbital_layer):
			var hit := _orbital_layer._ship_at(at, true)
			if hit != null:
				_cam_follow_ship_id = hit.ship_id
				_cam_follow_lander = false
				AudioManager.play("click")
				_show_unlock_toast("Following %s" % hit.ship_name, "Drag the planet to release the camera.")
				return true
		return false
	_cam_follow_ship_id = ""
	_cam_follow_lander = true
	AudioManager.play("click")
	_show_unlock_toast("Following the lander", "Drag the planet to release the camera.")
	return true

func _tick_cam_follow(delta: float) -> void:
	if _cam_follow_ship_id != "":
		_tick_follow_ship(delta)
		return
	if not _cam_follow_lander:
		return
	if planet_renderer._dragging or current_data == null or current_data.seed != GameState.home_planet_seed:
		_cam_follow_lander = false
		return
	if not _depart_fx.is_empty():
		return   # the departure plays in screen space
	var ll := _lander_lonlat()
	if not ll.is_finite():
		if GameState.expedition_state("lander") != "launching":
			_cam_follow_lander = false   # it has left this world
		return
	var k := 1.0 - exp(-delta * 5.0)
	planet_renderer.set_rotation_offset(lerp_angle(planet_renderer.get_rotation_offset(), ll.x, k))
	planet_renderer.set_tilt(lerpf(planet_renderer.tilt, ll.y, k))

func _on_lander_lifted() -> void:
	var newest: ShipData = null
	for sh: ShipData in ShipManager.ships_for(GameState.home_planet_seed):
		if sh.ship_type == "lander" and not sh.is_travelling():
			newest = sh
	GameState.lander_in_orbit(newest)

## Opens the Moon with its orbit in view and the lander card on screen (the
## HUD's "lander reached the Moon" notice).
func focus_lander_at(moon_seed: int) -> void:
	var moon := GameState.get_planet_data(moon_seed)
	if moon == null:
		return
	if current_data != null and current_data.seed != moon_seed:
		var from := Rect2()
		var cc: Vector2 = _companions.center_of(moon) if _companions != null else Vector2.INF
		if cc.is_finite():
			var cr: float = _companions.radius_of(moon) / 0.40
			from = Rect2(cc - Vector2(cr, cr) * 0.5, Vector2(cr, cr))
		_switch_to_body(moon, from)
	_set_zoom_target(ZOOM_MIN, Vector2.INF)
	_reveal_panel()
	_show_planet_overview()

func _begin_lunar_landing() -> void:
	var city_def := DistrictDef.find(DistrictDef.Type.CITY)
	if city_def == null or current_data == null:
		return
	# the landing module is paid once; a cancelled site choice can be retried free
	if not GameState.landing_paid.has(current_data.seed):
		if not Economy.pay(GameState.LANDING_COST):
			AudioManager.play("error")
			return
		GameState.landing_paid[current_data.seed] = true
		GameState.save()
	if GameState.moon_lander(current_data.seed) == null:   # the module undocks from the Central Orbit
		GameState.spawn_lander_from_hub(current_data.seed)
	AudioManager.play("click")
	_lunar_landing = true
	_begin_district_placement(city_def)

## Where the transfer flight hands over to the lander's orbit: beside the moon,
## on the side the home world is on.
func _lander_entry_point(center: Vector2, r_px: float, home: Vector2) -> Vector2:
	var dir := (home - center).normalized() if home.is_finite() else Vector2(0.7, -0.7)
	return center + dir * r_px * 1.35

## The colony lander is a real ship in the moon's orbit (OrbitalLayer draws,
## spins and lands it). Here: make sure it exists while it should, and park a
## freshly arrived one where the transfer flight came in.
func _tick_lander(_delta: float) -> void:
	if _lunar_landing and _placing_def == null and not _naming_open and not _lander_descending:
		_lunar_landing = false   # placement was cancelled: the module docks back
		if current_data != null and GameState.moon_lander(current_data.seed) != null:
			ShipManager.remove_ship(current_data.seed, GameState.moon_lander(current_data.seed).ship_id)
	if current_data == null or current_data.planet_type != PlanetData.Type.MOON:
		return
	var pp := GameState.get_planet(current_data.seed)
	if pp.lander_state != 1 or _lander_descending:
		return
	if Leveling.orbit_hub(current_data) == null:   # saves from before the Central Orbit
		GameState.deploy_central_orbit(current_data.seed)
	var ship := GameState.moon_lander(current_data.seed)
	if ship == null:
		if not _lunar_landing:
			return   # only the Central Orbit is up there until colonization starts
		ship = GameState.spawn_lander_from_hub(current_data.seed)
	if ship.has_meta("aim_home") and _orbital_layer != null and is_instance_valid(_orbital_layer) \
			and _orbital_layer._planet_radius > 0.0:
		ship.remove_meta("aim_home")
		var lc := _orbital_layer.get_global_rect().position + _orbital_layer._center_now()
		var home_c: Vector2 = _companions.center_of(_companion_parent) \
			if _companions != null and _companion_parent != null else Vector2.INF
		var want := _lander_entry_point(lc, _orbital_layer._planet_radius, home_c)
		var best_a := ship.orbit_angle
		var best_d := INF
		for i in 72:
			var a := TAU * float(i) / 72.0
			var v := _orbital_layer._project(ship, a)
			if _orbital_layer._is_occluded(v):
				continue
			var d := (lc + Vector2(v.x, v.y)).distance_to(want)
			if d < best_d:
				best_d = d
				best_a = a
		ship.orbit_angle = best_a
		_orbital_layer._reveal[ship.ship_id] = {"progress": 0.0, "spawn_angle": best_a}

## The lander leaves its orbit and comes down on `site` (OrbitalLayer → DescentFX);
## the City is founded at touchdown.
func _land_lander(nm: String, def: DistrictDef, site: Vector2) -> void:
	var data := current_data
	var ship := GameState.moon_lander(data.seed)
	if ship == null:
		ship = GameState.spawn_lander_from_hub(data.seed)
	_lander_descending = true
	AudioManager.play("rocket", -6.0)
	_orbital_layer.start_landing(ship, site,
		func() -> void:
			_lander_descending = false
			_lunar_landing = false
			if GameState.moon_lander(data.seed) != null:
				ShipManager.remove_ship(data.seed, GameState.moon_lander(data.seed).ship_id)
			if current_data != data:
				return
			AudioManager.play("construct")
			GameState.mark_landed(data.seed)
			_spawn_district(data, nm, def, site, "")
			poi_layer.spawn_floating_text(rad_to_deg(site.x), rad_to_deg(site.y), "Touchdown!", Color(0.65, 1.0, 0.7), 14))

func _maybe_require_first_city() -> void:
	if GameState.showcase_mode:
		return
	if current_data == null or _placing_def != null or _naming_open:
		return
	var pp := GameState.get_planet(current_data.seed)
	if pp == null or not pp.is_colonized:
		return
	if PlanetData.get_shader_type(current_data.planet_type) == PlanetData.ShaderType.GAS:
		return
	for p: POIData in current_data.custom_pois:
		if p.is_city() and not p.is_orbital():
			return
	if current_data.seed != GameState.home_planet_seed:
		return   # other worlds: the lander waits for "Found First Settlement"
	var city_def := DistrictDef.find(DistrictDef.Type.CITY)
	if city_def == null:
		return
	_mandatory_city = true
	# start with the panel already tucked away (no open-then-slide flicker on a new game)
	var was_open := _panel_open
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_open = false
	_apply_panel_t(0.0)
	_begin_district_placement(city_def)
	_reopen_panel_after_place = was_open

## Bakes the exact GPU terrain for CPU lookups, then re-reads everything that was
## sampled from the (inexact) GDScript noise fallback in the meantime.
## Terrain map → resource maps → road graph, each built once per planet.
func _prepare_planet_maps(data: PlanetData) -> void:
	var mode := TerrainMap.mode_for(data)
	if mode >= 0 and not TerrainMap.has_map(data.seed, mode):
		await _bake_terrain_map(data)
	if current_data != data:
		return
	if not ResourceMap.has_map(data.seed):
		await ResourceMap.build(data, self)
	if current_data != data:
		return
	# sample resource tags for districts placed before the maps existed
	for pd: POIData in data.custom_pois:
		if not pd.is_orbital() and pd.manual_position and pd.resource_tags.is_empty():
			pd.resource_tags = ResourceMap.sample(data.seed, deg_to_rad(pd.lon_deg), deg_to_rad(pd.lat_deg))
	# visible features: drawn by the shader, read by the economy (stored per district)
	FeatureMap.build(data)
	for pd: POIData in data.custom_pois:
		if not pd.is_orbital() and pd.manual_position:
			pd.site_features = FeatureMap.shares(data, deg_to_rad(pd.lon_deg), deg_to_rad(pd.lat_deg))
	_apply_feature_texture()
	RoadNetwork.for_planet(data)   # graph builds on a worker thread
	_maps_ready_seed = data.seed
	_roads_dirty = true
	_rebuild_lens_bar()
	_refresh_lens()

## Hands the planet shader its feature grid (FeatureMap) once built.
func _apply_feature_texture() -> void:
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null or current_data == null:
		return
	var tex := FeatureMap.texture(current_data.seed)
	mat.set_shader_parameter("feature_tex", tex)
	mat.set_shader_parameter("feature_on", 1.0 if tex != null else 0.0)
	mat.set_shader_parameter("feature_strength", _feature_strength())
	var rivers := FeatureMap.river_texture(current_data.seed)
	mat.set_shader_parameter("river_tex", rivers)
	mat.set_shader_parameter("river_on", 1.0 if rivers != null else 0.0)
	mat.set_shader_parameter("river_vis", smoothstep(ZOOM_RIVER_START, ZOOM_RIVER_FULL, _zoom))

## Terrain features are painted softly; a role lens brings them out.
const FEATURE_STRENGTH      := 0.5
const FEATURE_STRENGTH_LENS := 0.9

func _feature_strength() -> float:
	return FEATURE_STRENGTH_LENS if _role != "" else FEATURE_STRENGTH

func _bake_terrain_map(data: PlanetData) -> void:
	await TerrainMap.bake(data, self)
	if current_data != data or not TerrainMap.has_map(data.seed, TerrainMap.mode_for(data)):
		return
	for pd: POIData in data.custom_pois:
		if pd.is_orbital() or not pd.manual_position:
			continue
		var t := TerrainSampler.sample(data, deg_to_rad(pd.lon_deg), deg_to_rad(pd.lat_deg))
		pd.terrain = t["terrain"]
		pd.coastal = t["coastal"]
	_refresh_pois(data)   # also resolves auto-placed districts against real terrain
	_refresh_active_panel()

func _clean_custom_pois(data: PlanetData) -> void:
	if data == null or data.custom_pois.is_empty():
		return
	var cleaned: Array[POIData] = []
	for item in data.custom_pois:
		if typeof(item) == TYPE_DICTIONARY:
			var untyped = [item][0]
			var pd := POIData.new()
			pd.lon_deg = float(untyped.get("lon_deg", 0.0))
			pd.lat_deg = float(untyped.get("lat_deg", 0.0))
			pd.label = str(untyped.get("label", ""))
			pd.manual_position = true
			if untyped.has("data") and typeof(untyped["data"]) == TYPE_DICTIONARY:
				var pdata: Dictionary = untyped["data"]
				pd.type_tag = str(pdata.get("type", ""))
				pd.light_intensity = float(pdata.get("light_intensity", 1.0))
				if pd.type_tag == "station":
					pd.poi_type = POIData.POIType.STATION
			cleaned.append(pd)
		elif item is POIData:
			cleaned.append(item as POIData)
	data.custom_pois = cleaned

func _refresh_pois(data: PlanetData) -> void:
	_clean_custom_pois(data)
	poi_layer.clear_pois()
	var pois: Array[Dictionary] = []
	if data.custom_pois.size() > 0:
		var lf := LocationFinder.new(data.seed, data.sea_level,
				data.terrain_roughness, data.continent_scale)
		for pd: POIData in data.custom_pois:
			if pd.is_orbital():
				continue  # orbital districts drawn by OrbitalLayer, not POILayer
			var lon: float
			var lat: float
			if pd.manual_position:
				lon = deg_to_rad(pd.lon_deg)
				lat = deg_to_rad(pd.lat_deg)
			else:
				var pos: Vector2 = lf.find(pd.placement)
				lon = pos.x
				lat = pos.y
				# Store resolved position back so rotation and overview card can use it
				pd.lon_deg = rad_to_deg(lon)
				pd.lat_deg = rad_to_deg(lat)
				# Only lock it in once the real terrain map is available — until then
				# LocationFinder sees the inexact noise fallback and may pick water.
				var map_mode := TerrainMap.mode_for(data)
				pd.manual_position = map_mode < 0 or TerrainMap.has_map(data.seed, map_mode)
			if pd.terrain < 0 and pd.manual_position:
				var t := TerrainSampler.sample(data, lon, lat)
				pd.terrain = t["terrain"]
				pd.coastal = t["coastal"]
			pois.append({
				"lon_deg": rad_to_deg(lon), "lat_deg": rad_to_deg(lat),
				"label": pd.label,
				"data": {
					"poi": pd,   # live state (e.g. construction progress) for the map
					"pp": GameState.get_planet(data.seed),   # live level-up progress
					"name": pd.shown_name(),
					"type": pd.type_tag,
					"is_city": pd.is_city(),
					"light_intensity": pd.light_intensity,
					"night_size": _district_night_size(data, pd.label),
				}
			})

	var pp_poi := GameState.get_planet(data.seed)
	for poi in pois:
		var d: Dictionary = poi["data"].duplicate()
		d["district_level"] = 1
		if pp_poi != null:
			var dp: POIData = d.get("poi")
			d["district_level"] = Leveling.city_level(pp_poi, dp) if dp != null and dp.is_city() \
				else pp_poi.district_levels.get(poi["label"], 1)
			if dp != null and dp.is_city():
				d["capital_level"] = pp_poi.district_levels.get(poi["label"], 1)
		poi_layer.add_poi(poi["lon_deg"], poi["lat_deg"], poi["label"], d)

	_upload_territories(data)
	# After POIs are loaded, sync night sizes so shader glow starts correctly
	_update_poi_night_sizes(data)
	_refresh_poi_lights(data)

## Rebuilds whichever right-panel view is open (district / City, or the planet
## overview) in place, instead of jumping back to the overview.
func _refresh_active_panel() -> void:
	if current_data == null:
		return
	if _city_panel_poi != null and _city_panel_poi in current_data.custom_pois:
		_build_city_panel(_city_panel_poi, current_data)
	elif _orbit_panel_open:
		_build_orbit_panel(current_data)
	elif _active_district_poi != null and _active_district_poi in current_data.custom_pois:
		_build_district_panel(_active_district_poi, current_data)
		if not _active_district_poi.is_orbital():
			_select_district_on_planet(_active_district_poi.label)   # keep its map highlight
	else:
		_build_planet_overview(current_data)

func redraw() -> void:
	var pd := PlanetData.from_seed(randi() % 99999)
	pd.generate_moons(pd.seed)
	_local_system = _make_system(pd)
	_system_solar  = null
	load_planet(pd)

func _setup_material(data: PlanetData) -> void:
	var shader := load(PlanetData.get_shader_path(data.planet_type)) as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var sz: float = clamp(data.planet_size, 0.2, 2.0)
	var base_radius: float = clamp(0.42 * sz, 0.10, 0.48)
	# scale pixel_count only when planet is large (>1.2) to preserve pixel art feel
	var pcount: float = 140.0
	if sz > 1.2:
		pcount = round(clamp(140.0 * (sz / 1.2), 140.0, 280.0))
	# Carry over the renderer's current spin: load_planet() also runs when a district
	# is placed, and a fresh material at 0 would show a different patch of the globe
	# than the markers (which read the renderer) until the next drag.
	mat.set_shader_parameter("rotation_offset",   planet_renderer.get_rotation_offset())
	mat.set_shader_parameter("planet_radius",     base_radius)
	mat.set_shader_parameter("pixel_count",       pcount)
	mat.set_shader_parameter("seed",              data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)
	_base_radius      = base_radius * PLANET_VIEW_SCALE
	mat.set_shader_parameter("tilt", planet_renderer.tilt)
	mat.set_shader_parameter("night_shadow", SettingsManager.night_shadow)

	var stype := PlanetData.get_shader_type(data.planet_type)
	match stype:
		PlanetData.ShaderType.ROCKY:
			mat.set_shader_parameter("cloud_speed",        data.cloud_speed)
			mat.set_shader_parameter("cloud_coverage",     data.cloud_coverage)
			mat.set_shader_parameter("has_clouds",         1.0 if data.has_clouds else 0.0)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density if data.has_atmosphere else 0.0)
			mat.set_shader_parameter("sea_level",          data.sea_level)
			mat.set_shader_parameter("continent_scale",    data.continent_scale)
			mat.set_shader_parameter("continentality", data.effective_continentality())
			mat.set_shader_parameter("specular_strength",  data.specular_strength)
			mat.set_shader_parameter("city_lights",        data.city_lights)
			var colors := PlanetData.get_colors(data.planet_type)
			for key in colors:
				mat.set_shader_parameter(key, colors[key])
		PlanetData.ShaderType.GAS:
			mat.set_shader_parameter("cloud_speed",        data.cloud_speed)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density)
			var colors := PlanetData.get_colors(data.planet_type)
			mat.set_shader_parameter("color_band_a",     colors.get("color_sand",        Vector3(0.72, 0.55, 0.35)))
			mat.set_shader_parameter("color_band_b",     colors.get("color_forest",      Vector3(0.50, 0.32, 0.18)))
			mat.set_shader_parameter("color_storm",      colors.get("color_snow",        Vector3(0.88, 0.82, 0.72)))
			mat.set_shader_parameter("color_atmosphere", colors.get("color_atmosphere",  Vector3(0.72, 0.55, 0.35)))
		PlanetData.ShaderType.MOON:
			var colors := PlanetData.get_colors(data.planet_type)
			mat.set_shader_parameter("color_highland", colors.get("color_mountain",  Vector3(0.62, 0.60, 0.56)))
			mat.set_shader_parameter("color_mare",     colors.get("color_deep_ocean",Vector3(0.22, 0.21, 0.20)))
			mat.set_shader_parameter("color_rim",      colors.get("color_snow",      Vector3(0.78, 0.76, 0.72)))
			mat.set_shader_parameter("color_floor",    colors.get("color_ocean",     Vector3(0.16, 0.15, 0.14)))
		PlanetData.ShaderType.ASTEROID:
			mat.set_shader_parameter("irregularity", data.irregularity)
			mat.set_shader_parameter("elongation",   1.0 + data.irregularity * 0.8)

	planet_renderer.material = mat
	if _planet_px != null:
		_planet_px.material = mat   # same instance: every parameter set reaches the low-res render
	_apply_zoom()
	_refresh_lens()

# ── District territories ──────────────────────────────────────────────────────
# Each surface district owns a pixel region on the globe (district_territory.gdshaderinc).
# It grows with district level and active buildings, and hosts the night lights.

## How many districts the planet shader draws at once (must match MAX_DISTRICTS
## in district_territory.gdshaderinc). Gameplay (roads, neighbours, sizes, hit
## tests) uses every district; only the drawing is capped — to the ones nearest
## the middle of the view, refreshed as the globe turns (_push_shader_districts).
const MAX_TERRITORIES:     int   = 128
# Settlement radius = BASE + SIZE·√(Σ building weights).
# A fresh district is a hamlet of a few pixels; housing grows it fastest.
const SETTLE_BASE_DEG:     float = 0.9
const SETTLE_SIZE_DEG:     float = 1.1
const TERRITORY_WARP:      float = 0.18   # edge raggedness — same as the shader
## Hide district borders while zoomed out (fully visible from ZOOM_BORDER_FULL).
## Non-city districts (markers, labels, arcs) fade in between these zoom levels.
## Closest zoom: small bodies (the Moon) zoom further so their towns get as
## close as Earth's.
func _zoom_max() -> float:
	return minf(ZOOM_MAX * TerrainSampler.body_scale(current_data), 12.0)

## Rivers fade in between these zoom levels.
const ZOOM_RIVER_START:    float = 1.5
const ZOOM_RIVER_FULL:     float = 2.3
const ZOOM_DETAIL_START:   float = 1.3
const ZOOM_DETAIL_FULL:    float = 1.8
## Markers + labels visibility (fades to 0 while H is held).
var _marker_vis_t: float = 1.0
## Roads / sea lanes / ports / ships fade in between these zoom levels.
const ZOOM_ROADS_START:    float = 1.5
const ZOOM_ROADS_FULL:     float = 2.2
const ZOOM_BORDER_START:   float = 1.4
const ZOOM_BORDER_FULL:    float = 2.0
## { n: Vector3 world normal, r: float angular radius } — same order as poi_layer._pois.
var _territories: Array[Dictionary] = []
# Settlements stretch along the roads leaving them — must match the shader include.
const MAX_SPOKES:    int   = 4
const SPOKE_STRETCH: float = 1.6
const SPOKE_SHARP:   float = 12.0
## Settlement growth (Σ building weights) after a road appears for its lobe to fully form.
const SPOKE_GROWTH:  float = 2.0
## Per territory: Array of Vector4(unit tangent xyz in shader-world space, growth w 0..1).
var _spokes: Array = []

## Settlement growth per Capital District / City level.
const CAPITAL_SIZE_PER_LEVEL: float = 1.2
## Σ settlement weights of the finished buildings in a district (the Capital
## District also grows with its levels).
func _district_settlement_size(data: PlanetData, district_label: String) -> float:
	var pp := GameState.get_planet(data.seed)
	if pp == null:
		return 0.0
	var total := 0.0
	# The Capital District grows from its own buildings and from levelling up
	# (district + City levels) — not from the districts around it.
	var me := _find_poi(data, district_label)
	if me != null and me.is_city():
		total += CAPITAL_SIZE_PER_LEVEL * float(int(pp.district_levels.get(district_label, 1)) - 1 \
			+ Leveling.city_level(pp, me) - 1)
	for b: Dictionary in pp.buildings_in_district(district_label):
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		var w: float = def.settlement_weight() if def != null else 0.5
		total += w * float(b.get("amount", 1))
	return total

## Settlement size comes from buildings only — not from level, because level now
## derives from neighbours, and neighbours from settlement size.
func _territory_radius_deg(data: PlanetData, pd: POIData) -> float:
	var k := TerrainSampler.body_scale(data)   # same km size on a small body
	if pd.constructing:
		return SETTLE_BASE_DEG * 0.7 * k
	return (SETTLE_BASE_DEG + SETTLE_SIZE_DEG * sqrt(_district_settlement_size(data, pd.label))) * k

## Surface districts that count as neighbours of each other (settlements within
## NEIGHBOR_GAP_DEG). Returns index pairs into the territory / poi_layer order.
func _neighbor_pairs() -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	var gap := deg_to_rad(TerrainSampler.NEIGHBOR_GAP_DEG * TerrainSampler.body_scale(current_data))
	for a in _territories.size():
		for b in range(a + 1, _territories.size()):
			var ta: Dictionary = _territories[a]
			var tb: Dictionary = _territories[b]
			var ang := acos(clampf((ta["n"] as Vector3).dot(tb["n"]), -1.0, 1.0))
			if ang <= float(ta["r"]) + float(tb["r"]) + gap:
				pairs.append(Vector2i(a, b))
	return pairs

## Labels of the districts neighbouring `district_label` on the current planet.
func district_neighbors(district_label: String) -> Array[String]:
	var out: Array[String] = []
	var idx := -1
	for i in poi_layer._pois.size():
		if poi_layer._pois[i]["label"] == district_label:
			idx = i
	if idx < 0:
		return out
	for p: Vector2i in _neighbor_pairs():
		if p.x == idx: out.append(poi_layer._pois[p.y]["label"])
		elif p.y == idx: out.append(poi_layer._pois[p.x]["label"])
	return out

## A district built on water (sea districts: platforms, sea-lane endpoints).
static func _is_sea_site(pd: POIData) -> bool:
	return pd.terrain >= 0 and TerrainSampler.is_water(pd.terrain)

## Share of a settlement's pixels lit at night, from its running buildings.
static func _territory_light(active: int) -> float:
	return 0.0 if active <= 0 else clampf(0.3 + float(active) * 0.07, 0.0, 1.0)

static func _lonlat_to_world(lon: float, lat: float) -> Vector3:
	return Vector3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat))

## Shader slot of each territory (-1 = not drawn this frame) and the reverse.
var _slot_of: PackedInt32Array = PackedInt32Array()
var _slot_terr: PackedInt32Array = PackedInt32Array()
var _shader_view_n := Vector3.ZERO

## World normal at the middle of the view.
func _view_center_n() -> Vector3:
	var hit := _screen_to_lonlat(planet_renderer.global_position + planet_renderer.size * 0.5)
	if not hit["hit"]:
		return Vector3.ZERO
	return _lonlat_to_world(float(hit["lon"]), float(hit["lat"]))

## Sends the territories the shader draws: all of them when they fit, else the
## MAX_TERRITORIES nearest the middle of the view.
func _push_shader_districts() -> void:
	var order: Array = range(_territories.size())
	var vc := _view_center_n()
	_shader_view_n = vc
	if order.size() > MAX_TERRITORIES and vc != Vector3.ZERO:
		order.sort_custom(func(a, b) -> bool:
			return (_territories[a]["n"] as Vector3).dot(vc) > (_territories[b]["n"] as Vector3).dot(vc))
		order = order.slice(0, MAX_TERRITORIES)
	_slot_of = PackedInt32Array()
	_slot_of.resize(_territories.size())
	_slot_of.fill(-1)
	_slot_terr = PackedInt32Array()
	var pos := PackedVector4Array()
	var col := PackedVector4Array()
	var sea := PackedFloat32Array()
	for ti in order:
		var t: Dictionary = _territories[ti]
		var n: Vector3 = t["n"]
		_slot_of[ti] = _slot_terr.size()
		_slot_terr.append(ti)
		pos.append(Vector4(n.x, n.y, n.z, float(t["r"])))
		col.append(t["col"])
		sea.append(float(t["sea"]))
	var count := pos.size()
	while pos.size() < MAX_TERRITORIES:
		pos.append(Vector4.ZERO)
		col.append(Vector4.ZERO)
		sea.append(0.0)
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("district_pos",   pos)
	mat.set_shader_parameter("district_col",   col)
	mat.set_shader_parameter("district_count", count)
	mat.set_shader_parameter("district_sea",   sea)
	_push_shader_spokes()

func _push_shader_spokes() -> void:
	var buf := PackedVector4Array()
	buf.resize(MAX_TERRITORIES * MAX_SPOKES)
	for slot in _slot_terr.size():
		var ti: int = _slot_terr[slot]
		if ti >= _spokes.size():
			continue
		var list: Array = _spokes[ti]
		for k in mini(list.size(), MAX_SPOKES):
			buf[slot * MAX_SPOKES + k] = list[k]
	var mat := planet_renderer.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("district_spokes", buf)

## Territory index → shader slot (-1 when not drawn).
func _shader_slot(ti: int) -> int:
	return _slot_of[ti] if ti >= 0 and ti < _slot_of.size() else -1

func _upload_territories(data: PlanetData) -> void:
	_territories.clear()
	for pd: POIData in data.custom_pois:
		if pd.is_orbital():
			continue
		var n := _lonlat_to_world(deg_to_rad(pd.lon_deg), deg_to_rad(pd.lat_deg))
		var r := deg_to_rad(_territory_radius_deg(data, pd))
		var c: Color = poi_layer._marker_color(pd.type_tag)
		# Night lights scale with active buildings: none while constructing / empty.
		var light: float = 0.0 if pd.constructing \
			else _territory_light(_district_night_size(data, pd.label))
		_territories.append({"n": n, "r": r, "poi": pd,
			"col": Vector4(c.r, c.g, c.b, light), "sea": 1.0 if _is_sea_site(pd) else 0.0})
	# Neighbour pairs drive the arcs and label merging in POILayer; roads are
	# routed separately (_rebuild_roads).
	var pairs := _neighbor_pairs()
	_store_neighbors(pairs)
	_push_label_clusters(pairs)
	_sync_level_labels(data)
	_roads_dirty = true
	_push_shader_districts()
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("poi_count",      0)

## Connected-component id per territory: districts linked through neighbour
## pairs form one "system".
func _components(pairs: Array[Vector2i]) -> Array[int]:
	var comp: Array[int] = []
	for i in _territories.size():
		comp.append(i)
	var changed := true
	while changed:   # tiny union-find: propagate the smallest index through pairs
		changed = false
		for pr: Vector2i in pairs:
			var m := mini(comp[pr.x], comp[pr.y])
			if comp[pr.x] != m or comp[pr.y] != m:
				comp[pr.x] = m
				comp[pr.y] = m
				changed = true
	return comp

## Routes every road link over the terrain (RoadNetwork) and hands them to POILayer.
## Routes are cached by endpoints, so only new links are routed.
func _rebuild_roads() -> void:
	# The road graph must see the baked terrain — never build it before that.
	if current_data == null or _maps_ready_seed != current_data.seed:
		return
	var net := RoadNetwork.for_planet(current_data)
	if not net.is_ready():
		return   # try again next frame
	_roads_dirty = false
	var out: Array = []
	var routed: Array = []   # { a, b, route } for settlement spokes
	for pr: Vector2i in _road_links():
		var a: POIData = _territories[pr.x]["poi"]
		var b: POIData = _territories[pr.y]["poi"]
		var key := "%.2f,%.2f|%.2f,%.2f" % [a.lon_deg, a.lat_deg, b.lon_deg, b.lat_deg]
		if not _route_cache.has(key):
			_route_cache[key] = net.route(deg_to_rad(a.lon_deg), deg_to_rad(a.lat_deg),
				deg_to_rad(b.lon_deg), deg_to_rad(b.lat_deg),
				_is_sea_site(a), _is_sea_site(b))
		var r: Dictionary = _route_cache[key]
		if not r.is_empty():
			if not r.has("port_names"):
				r["port_names"] = _port_names(r.get("ports", PackedVector2Array()))
			out.append(r)
			routed.append({"a": pr.x, "b": pr.y, "route": r})
	poi_layer.roads = out
	_set_spokes_from_routes(routed)
	_store_road_relations(routed)

## Neighbour income runs along roads: two districts are income partners when a
## road links them directly (a road merely passing through a third district
## gives that one nothing). Each partner pays × road weight: the thicker the
## shared road (how many routes run along it), the more — up to ROAD_BONUS_MAX.
const ROAD_BONUS_PER_SHARE := 0.3
const ROAD_BONUS_MAX := 2.0

func _store_road_relations(routed: Array) -> void:
	# land cells (½° grid) → how many routes use them
	var cell_routes := {}
	var route_cells: Array = []
	for rk in routed.size():
		var cells := {}
		var r: Dictionary = routed[rk]["route"]
		for seg: Dictionary in r.get("segments", []):
			if seg.get("sea", false):
				continue
			for pt: Vector2 in seg["points"]:
				cells[Vector2i(roundi(rad_to_deg(pt.x) * 2.0), roundi(rad_to_deg(pt.y) * 2.0))] = true
		route_cells.append(cells)
		for c in cells:
			cell_routes[c] = int(cell_routes.get(c, 0)) + 1
	for t: Dictionary in _territories:
		(t["poi"] as POIData).neighbors = []
		(t["poi"] as POIData).neighbor_weight = {}
	var pairs: Array[Vector2i] = []
	for rk in routed.size():
		var a: POIData = _territories[routed[rk]["a"]]["poi"]
		var b: POIData = _territories[routed[rk]["b"]]["poi"]
		var cells: Dictionary = route_cells[rk]
		var thick := 1.0
		if not cells.is_empty():
			var sum := 0.0
			for c in cells:
				sum += float(cell_routes[c])
			thick = sum / float(cells.size())
		var w := clampf(1.0 + ROAD_BONUS_PER_SHARE * (thick - 1.0), 1.0, ROAD_BONUS_MAX)
		for pr: Array in [[a, b], [b, a]]:
			var me: POIData = pr[0]
			var other: POIData = pr[1]
			if not me.neighbors.has(other.label):
				me.neighbors.append(other.label)
			me.neighbor_weight[other.label] = snappedf(w, 0.01)
		pairs.append(Vector2i(mini(routed[rk]["a"], routed[rk]["b"]), maxi(routed[rk]["a"], routed[rk]["b"])))
	poi_layer.income_pairs = pairs

## Each port is named after the nearest district ("Port Capital").
func _port_names(ports: PackedVector2Array) -> PackedStringArray:
	var names := PackedStringArray()
	for pt: Vector2 in ports:
		var n := _lonlat_to_world(pt.x, pt.y)
		var best := INF
		var best_label := ""
		for t: Dictionary in _territories:
			var d := acos(clampf(n.dot(t["n"]), -1.0, 1.0))
			if d < best:
				best = d
				best_label = (t["poi"] as POIData).label
		names.append(best_label)
	return names

## Road network: every pair of neighbouring districts, plus — so everything
## stays connected — inside each City a minimum spanning tree over the City and
## its districts; between cities, a direct road / sea lane for every pair.
## Returns territory index pairs.
func _road_links() -> Array[Vector2i]:
	var links: Array[Vector2i] = []
	var groups := {}   # city territory index -> Array[int]
	for i in _territories.size():
		var c := _city_index_of(i)
		if c < 0:
			continue
		if not groups.has(c):
			groups[c] = []
		groups[c].append(i)
	for c in groups:
		links.append_array(_mst(groups[c]))
	# every pair of cities gets its own road / sea lane — port to port, not
	# hopping through a third city
	var cities: Array = groups.keys()
	for i in cities.size():
		for j in range(i + 1, cities.size()):
			links.append(Vector2i(int(cities[i]), int(cities[j])))
	# every pair of neighbouring districts gets its own road as well
	var seen := {}
	for l: Vector2i in links:
		seen[Vector2i(mini(l.x, l.y), maxi(l.x, l.y))] = true
	for pr: Vector2i in _neighbor_pairs():
		var key := Vector2i(mini(pr.x, pr.y), maxi(pr.x, pr.y))
		if not seen.has(key):
			seen[key] = true
			links.append(pr)
	return links

## Prim's minimum spanning tree over territory indices, by surface distance.
func _mst(nodes: Array) -> Array[Vector2i]:
	var links: Array[Vector2i] = []
	if nodes.size() < 2:
		return links
	var in_tree := {nodes[0]: true}
	while in_tree.size() < nodes.size():
		var best := Vector2i(-1, -1)
		var best_d := INF
		for a: int in in_tree:
			for b: int in nodes:
				if in_tree.has(b):
					continue
				var d := acos(clampf((_territories[a]["n"] as Vector3).dot(_territories[b]["n"]), -1.0, 1.0))
				if d < best_d:
					best_d = d
					best = Vector2i(a, b)
		in_tree[best.y] = true
		links.append(best)
	return links

## Mirrors pp.district_levels (raised by hand with population) onto the map labels.
func _sync_level_labels(data: PlanetData) -> void:
	var pp := GameState.get_planet(data.seed)
	if pp == null:
		return
	for i in mini(_territories.size(), poi_layer._pois.size()):
		var pd: POIData = _territories[i]["poi"]
		poi_layer._pois[i]["data"]["district_level"] = Leveling.city_level(pp, pd) if pd.is_city() \
			else pp.district_levels.get(pd.label, 1)
		if pd.is_city():
			poi_layer._pois[i]["data"]["capital_level"] = pp.district_levels.get(pd.label, 1)

## Writes each district's neighbours (ids) onto its POIData — neighbour income
## (drawn as roads; the economy uses real km, see Location.gd) — and gives POILayer the
## income links to draw on hover: map neighbours, plus City ↔ its districts,
## each tinted by what the receiving district gets.
func _store_neighbors(pairs: Array[Vector2i]) -> void:
	var lists: Array = []
	for i in _territories.size():
		lists.append([])
	for pr: Vector2i in pairs:
		lists[pr.x].append((_territories[pr.y]["poi"] as POIData).label)
		lists[pr.y].append((_territories[pr.x]["poi"] as POIData).label)
	var links: Array[Vector2i] = pairs.duplicate()
	for i in _territories.size():
		var c := _city_index_of(i)
		if c >= 0 and c != i and not pairs.has(Vector2i(mini(i, c), maxi(i, c))):
			links.append(Vector2i(mini(i, c), maxi(i, c)))
	if poi_layer.income_pairs.is_empty():
		poi_layer.income_pairs = links   # until the roads are routed
	poi_layer.income_tint = _income_tint

## Colour of the income `receiver` gets from `giver` (indices into the territory
## order): the resource's colour, or a dim grey when it gets nothing from it.
func _income_tint(receiver: int, giver: int) -> Color:
	if receiver < 0 or giver < 0 or receiver >= _territories.size() or giver >= _territories.size():
		return Color(0.55, 0.60, 0.70)
	var rp: POIData = _territories[receiver]["poi"]
	var gp: POIData = _territories[giver]["poi"]
	var rdef := ProductionManager.district_def(rp)
	var gets: Dictionary = rdef.income_from(gp.type_tag) if rdef != null else {}
	if gets.is_empty():
		return Color(0.55, 0.60, 0.70, 0.7)
	return Economy.color_of(gets.keys()[0])

## Tells POILayer which districts are neighbours (cluster id) and how big they
## are, so zoomed out it can show one label per crowded cluster.
func _push_label_clusters(pairs: Array[Vector2i]) -> void:
	var cluster := _components(pairs)
	# Alt overlay arcs: every district flows to the City it belongs to
	var city_links: Array[Vector2i] = []
	for i in _territories.size():
		var c := _city_index_of(i)
		if c >= 0 and c != i:
			city_links.append(Vector2i(i, c))
	poi_layer.links = city_links
	poi_layer.neighbor_pairs = pairs
	for i in mini(poi_layer._pois.size(), _territories.size()):
		poi_layer._pois[i]["data"]["cluster"] = cluster[i]
		poi_layer._pois[i]["data"]["size"]    = _territories[i]["r"]

## Which territory owns a surface point (index into poi_layer._pois), or -1:
## the closest-reaching district (borders split overlaps evenly). Mirrors
## district_owner() in district_territory.gdshaderinc.
func _territory_owner(lon: float, lat: float) -> int:
	if _territories.is_empty() or current_data == null:
		return -1
	var rn := _lonlat_to_world(lon, lat)
	var owner := _territory_owner_raw(rn)
	if owner < 0:
		return -1
	# drop exclaves — mirrors district_owner() in the shader include
	const EXCLAVE_CHECKS := 6
	var c: Vector3 = _territories[owner]["n"]
	for k in range(1, EXCLAVE_CHECKS + 1):
		var t := float(k) / float(EXCLAVE_CHECKS + 1)
		if _territory_owner_raw(c.lerp(rn, t).normalized()) != owner:
			return -1
	return owner

func _territory_owner_raw(rn: Vector3) -> int:
	var ll := Vector2(atan2(rn.x, rn.z), asin(clampf(-rn.y, -1.0, 1.0)))
	var lon := ll.x
	var lat := ll.y
	var w := TerrainMap.warp(current_data.seed, lon, lat)
	if is_nan(w):
		w = PlanetNoise.noise3(rn * 22.0, current_data.seed)
	var warp := w * TERRITORY_WARP
	var best := 2.0
	var owner := -1
	for i in _territories.size():
		var t: Dictionary = _territories[i]
		var ang := acos(clampf(rn.dot(t["n"]), -1.0, 1.0))
		var score: float = ang / maxf(float(t["r"]) * _spoke_stretch(i, rn), 0.0001) + warp
		if score < best:
			best = score
			owner = i
	return owner if best < 1.0 else -1

## Mirrors spoke_stretch() in district_territory.gdshaderinc.
func _spoke_stretch(i: int, rn: Vector3) -> float:
	if i >= _spokes.size():
		return 1.0
	var c: Vector3 = _territories[i]["n"]
	var t := rn - c * rn.dot(c)
	if t.length() < 0.00001:
		return 1.0
	t = t.normalized()
	var best := 0.0
	for s: Vector4 in _spokes[i]:
		best = maxf(best, s.w * pow(maxf(t.dot(Vector3(s.x, s.y, s.z)), 0.0), SPOKE_SHARP))
	return 1.0 + SPOKE_STRETCH * best

## Records which way each route leaves its two districts and uploads the spokes.
func _set_spokes_from_routes(routed: Array) -> void:
	_spokes.clear()
	for i in _territories.size():
		_spokes.append([])
	for item: Dictionary in routed:
		# Settlements only stretch along the land road leaving them — never out
		# over a sea lane (a city can't grow onto the water toward its port).
		var segs: Array = item["route"].get("segments", [])
		if segs.is_empty():
			continue
		if not segs[0].get("sea", false):
			_add_spoke(item["a"], segs[0]["points"], false, item["b"])
		if not segs[segs.size() - 1].get("sea", false):
			_add_spoke(item["b"], segs[segs.size() - 1]["points"], true, item["a"])
	_push_shader_spokes()

## Direction the route leaves territory i: toward the first route point a bit
## beyond the settlement edge. Its strength is how much the district has grown
## since this road first appeared (recorded in POIData.spoke_birth).
func _add_spoke(i: int, pts: PackedVector2Array, from_end: bool, other: int) -> void:
	if i < 0 or i >= _territories.size() or (_spokes[i] as Array).size() >= MAX_SPOKES:
		return
	var c: Vector3 = _territories[i]["n"]
	var reach := maxf(float(_territories[i]["r"]) * 1.5, 0.02)
	var target := Vector3.ZERO
	var count := pts.size()
	if count < 2:
		return
	var leaves := false
	for k in count:
		var pt := pts[count - 1 - k] if from_end else pts[k]
		var w := _lonlat_to_world(pt.x, pt.y)
		target = w
		if acos(clampf(w.dot(c), -1.0, 1.0)) >= reach:
			leaves = true
			break
	if not leaves:
		return   # the land road ends (at a port) before leaving the settlement
	var t := target - c * target.dot(c)
	if t.length() <= 0.00001:
		return
	var pd: POIData = _territories[i]["poi"]
	var other_label: String = (_territories[other]["poi"] as POIData).label if other >= 0 else ""
	var size_now := _district_settlement_size(current_data, pd.label)
	if not pd.spoke_birth.has(other_label):
		pd.spoke_birth[other_label] = size_now
	var grown := clampf((size_now - float(pd.spoke_birth[other_label])) / SPOKE_GROWTH, 0.0, 1.0)
	var d := t.normalized()
	(_spokes[i] as Array).append(Vector4(d.x, d.y, d.z, grown))

func _territory_at_screen(global_pos: Vector2) -> int:
	if not _is_over_planet_area(global_pos):
		return -1
	var hit := _screen_to_lonlat(global_pos)
	if not hit["hit"]:
		return -1
	var owner := _territory_owner(hit["lon"], hit["lat"])
	# zoomed out, districts are hidden — only cities can be hovered / clicked
	if owner >= 0 and poi_layer.detail < 0.5 and not (_territories[owner]["poi"] as POIData).is_city():
		return -1
	return owner

func _refresh_poi_lights(data: PlanetData) -> void:
	if current_data == null or current_data.seed != data.seed:
		return
	_upload_territories(data)

func _update_panel(data: PlanetData) -> void:
	var name_label  := $SidePanel/PanelContent/PlanetName as Label
	var type_label  := $SidePanel/PanelContent/PlanetType as Label
	var type_names  := ["Terran", "Arid", "Ice", "Volcanic", "Barren", "Gas Giant", "Moon", "Asteroid"]
	if name_label: name_label.text = data.planet_name
	if type_label:
		var pp := GameState.get_planet(data.seed)
		var lv_str := "  ·  Lv %d" % pp.level if pp.is_colonized else ""
		type_label.text = type_names[data.planet_type] + lv_str
		type_label.visible = true
	_build_system_panel()

var _name_form_overlay: Control = null

func _show_district_name_form_modal(data: PlanetData, def: DistrictDef) -> void:
	if _name_form_overlay != null and is_instance_valid(_name_form_overlay):
		_name_form_overlay.queue_free()
		_name_form_overlay = null

	var panel_content := $SidePanel/PanelContent

	var overlay := PanelContainer.new()
	overlay.add_theme_stylebox_override("panel", _make_hud_style(Color(0.06, 0.08, 0.17, 0.98), 8))
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.z_index = 20

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	overlay.add_child(vbox)

	# Header row: icon + type name + close
	var header := HBoxContainer.new()
	var type_lbl := Label.new()
	type_lbl.text = "%s  %s" % [def.icon, def.display_name]
	_apply_orbitron(type_lbl, 10)
	type_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(type_lbl)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	_apply_orbitron(close_btn, 9)
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	close_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		_name_form_overlay = null)
	header.add_child(close_btn)
	vbox.add_child(header)

	var desc_lbl := Label.new()
	desc_lbl.text = def.description
	_apply_orbitron(desc_lbl, 8)
	desc_lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.72))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	# Cost row
	var cost: float = DistrictDef.placement_cost(def, data)
	var cost_row := HBoxContainer.new()
	var cost_icon := Label.new()
	cost_icon.text = "◈"
	_apply_orbitron(cost_icon, 9)
	cost_icon.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_icon)
	var cost_lbl := Label.new()
	cost_lbl.text = HUDManager.fmt_credits(cost)
	_apply_orbitron(cost_lbl, 9)
	cost_lbl.add_theme_color_override("font_color",
		Color(0.55, 0.70, 0.40) if GameState.credits >= cost else Color(0.85, 0.32, 0.32))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_lbl)
	vbox.add_child(cost_row)

	var name_edit := LineEdit.new()
	name_edit.text             = def.suggest_name(data)
	name_edit.placeholder_text = "District name..."
	name_edit.custom_minimum_size = Vector2(0, 28)
	_apply_orbitron(name_edit, 10)
	vbox.add_child(name_edit)

	var confirm := Button.new()
	confirm.text = "▶  PLACE DISTRICT"
	_apply_orbitron(confirm, 9)
	confirm.add_theme_color_override("font_color",       Color(0.90, 0.82, 0.45))
	confirm.add_theme_color_override("font_hover_color", Color(1.00, 0.95, 0.60))
	_live_enable(confirm, func() -> bool: return GameState.credits >= cost)
	var cap_def  := def
	var cap_data := data
	var cap_cost := cost
	confirm.pressed.connect(func() -> void:
		if not GameState.spend_credits(cap_cost):
			return
		var lbl: String = name_edit.text.strip_edges()
		if lbl.is_empty(): lbl = cap_def.display_name
		if is_instance_valid(overlay):
			overlay.queue_free()
		_name_form_overlay = null
		_spawn_district(cap_data, lbl, cap_def))
	vbox.add_child(confirm)

	panel_content.add_child(overlay)
	_name_form_overlay = overlay
	name_edit.grab_focus()

## `site` = Vector2(lon_rad, lat_rad) picked by the player; INF = auto-place.
func _spawn_district(data: PlanetData, lbl: String, def: DistrictDef, site: Vector2 = Vector2.INF,
		parent_city: String = "") -> void:
	var poi          := POIData.new()
	# the price at this moment is what was just paid for it (refund ledger)
	poi.paid_credits = DistrictDef.placement_cost(def, data, "" if def.is_system_anchor() else parent_city)
	poi.label        = POIData.make_key(data)   # internal id; `lbl` is the shown name
	poi.display_name = lbl
	poi.parent_city  = "" if def.is_system_anchor() else parent_city
	poi.poi_type     = def.to_poi_type()
	poi.type_tag     = DistrictDef.Type.keys()[def.id].to_lower()
	poi.placement    = def.placement
	poi.constructing = true
	poi.construct_progress = 0.0
	poi.construct_duration = def.construction_duration

	if def.is_orbital:
		var rng := RandomNumberGenerator.new()
		rng.seed = data.seed ^ 0xC4F3A1
		poi.orbit_angle       = rng.randf_range(0.0, TAU)
		poi.orbit_speed       = 0.01
		poi.orbit_inclination = rng.randf_range(0.35, 1.1)
		poi.orbit_node        = rng.randf_range(0.0, TAU)
		poi.orbit_radius      = 1.06
		poi.light_intensity   = 0.0
		poi.manual_position   = true
		# Pick a surface district as the launch pad (prefer Capital, else first surface POI)
		var surface_pois_launch: Array[POIData] = []
		for p: POIData in data.custom_pois:
			if not p.is_orbital() and not p.constructing:
				surface_pois_launch.append(p)
		var launch_poi: POIData = null
		for p: POIData in surface_pois_launch:
			if p.is_city():
				launch_poi = p; break
		if launch_poi == null and not surface_pois_launch.is_empty():
			launch_poi = surface_pois_launch[0]
		# Rotate planet to face the launch pad, then start rocket
		if launch_poi != null:
			_rotate_to_lon(launch_poi.lon_deg, 0.5)
		AudioManager.play("construct")
		AchievementManager.notify_trigger(AchievementDef.Trigger.FIRST_DISTRICT)
		AchievementManager.notify_trigger(AchievementDef.Trigger.FIRST_ORBITAL)
		# Set construct_duration to match rocket animation BEFORE appending so ProductionManager
		# never reads the stale def.construction_duration value.
		const _BASE_LD: float = 22.0
		const _REF_R:   float = 200.0
		const _DEPLOY:  float = 2.2
		poi.construct_duration = (planet_renderer._planet_radius_px / _zoom / _REF_R) * _BASE_LD + _DEPLOY
		# Add immediately so panel shows "Constructing"; OrbitalLayer skips constructing=true pois
		data.custom_pois.append(poi)
		_play_rocket_animation(data.seed, launch_poi, func() -> void:
			poi.constructing = false
			poi.construct_progress = 1.0
			AudioManager.play("building_done")
			GameState.planet_progress_changed.emit(data.seed),
			"", "Pioneer", "station", {}, "", "", "", 0, false, [], poi)
		load_planet(data)
	else:
		poi.light_intensity = 2.0 if def.is_system_anchor() else 1.0
		var pos := site
		if not pos.is_finite():
			# Pre-seed LocationFinder with existing district positions so new ones spread out.
			var lf := LocationFinder.new(
				data.seed ^ (data.custom_pois.size() * 0xBEEF),
				data.sea_level, data.terrain_roughness, data.continent_scale)
			for existing: POIData in data.custom_pois:
				if existing.manual_position:
					var lon := deg_to_rad(existing.lon_deg)
					lf._used_lons.append(lon)
					if existing.poi_type == def.to_poi_type():
						lf._used_lons.append(fposmod(lon + deg_to_rad(5.0), TAU))
			pos = lf.find(def.placement)
		poi.lon_deg = rad_to_deg(pos.x)
		poi.lat_deg = rad_to_deg(pos.y)
		poi.manual_position = true
		var t := TerrainSampler.sample(data, pos.x, pos.y)
		poi.terrain = t["terrain"]
		poi.coastal = t["coastal"]
		poi.resource_tags = ResourceMap.sample(data.seed, pos.x, pos.y)
		poi.site_features = FeatureMap.shares(data, pos.x, pos.y)
		AudioManager.play("construct")
		AchievementManager.notify_trigger(AchievementDef.Trigger.FIRST_DISTRICT)
		data.custom_pois.append(poi)
		GameState.district_placed.emit(data.seed, def.id)
		load_planet(data)

func _apply_orbitron(node: CanvasItem, size: int) -> void:
	if _orbitron == null:
		return
	node.add_theme_font_override("font", _orbitron)
	node.add_theme_font_size_override("font_size", size)

# ── Details Panel ─────────────────────────────────────────────────────────────

func _build_details_panel(data: PlanetData) -> void:
	if _details_panel and is_instance_valid(_details_panel):
		_details_panel.queue_free()
		_details_panel = null

	var container: Control = planet_renderer.get_parent()
	var pp := GameState.get_planet(data.seed)

	# Root wrapper — freed as one unit via _details_panel
	var root := Control.new()
	root.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	root.z_as_relative   = false
	root.z_index         = 200
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(root)
	_details_panel = root

	if not ProductionManager.building_progress_changed.is_connected(_on_production_update):
		ProductionManager.building_progress_changed.connect(_on_production_update)
	if not ProductionManager.resource_produced.is_connected(_on_resource_produced):
		ProductionManager.resource_produced.connect(_on_resource_produced)


func _make_hud_style(col: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.25, 0.30, 0.50, 0.35)
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left   = 10.0
	s.content_margin_right  = 10.0
	s.content_margin_top    = 8.0
	s.content_margin_bottom = 8.0
	return s

func _details_row(parent: VBoxContainer, label: String, value: String,
		val_color: Color = Color(0.85, 0.90, 1.0)) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(lbl, 9)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	var val := Label.new()
	val.text = value
	_apply_orbitron(val, 9)
	val.add_theme_color_override("font_color", val_color)
	hbox.add_child(lbl)
	hbox.add_child(val)
	parent.add_child(hbox)
	return hbox

## Vivid rarity-based border color (hue = rarity, always max sat/brightness).
func _rarity_border_color(rarity: int) -> Color:
	var r: float = clampf(float(rarity - 1) / 14.0, 0.0, 1.0)
	var hue: float
	if r < 0.33:
		hue = lerp(0.60, 0.35, r / 0.33)
	elif r < 0.66:
		hue = lerp(0.35, 0.78, (r - 0.33) / 0.33)
	else:
		hue = lerp(0.78, 0.12, (r - 0.66) / 0.34)
	return Color.from_hsv(hue, 0.88, 1.00)

## Format large numbers with K / M / B suffix.
func _fmt_amount(n: float) -> String:
	if n >= 1_000_000_000.0:
		return "%.1fB" % (n / 1_000_000_000.0)
	elif n >= 1_000_000.0:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000.0:
		return "%.1fK" % (n / 1_000.0)
	return "%.0f" % n

## Item-style resource card. Rarity = thick left border color. Tier = icon shape.
## show_count=false → compact square chip (discovery grid, no amount).
## show_count=true  → full-width card: icon left, formatted count right, no name label.
func _mineral_icon_cell(rd: ResourceData, show_count: bool, stored: float = 0.0) -> PanelContainer:
	var rarity_col := _rarity_border_color(rd.rarity)

	var cell := PanelContainer.new()
	var s    := StyleBoxFlat.new()
	s.bg_color            = Color(0.07, 0.08, 0.13, 0.92)
	s.border_color        = rarity_col
	s.border_width_left   = 3
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left     = 4; s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4; s.corner_radius_bottom_right = 4
	s.content_margin_left   = 5; s.content_margin_right  = 6
	s.content_margin_top    = 4; s.content_margin_bottom = 4
	cell.add_theme_stylebox_override("panel", s)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	if show_count:
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(inner)

	var tex       := MineralIcon.make(rd.tier, rd.display_color)
	var icon_rect := TextureRect.new()
	icon_rect.texture             = tex
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter      = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon_rect)

	if show_count:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(spacer)

		var count_lbl := Label.new()
		count_lbl.text = _fmt_amount(stored)
		_apply_orbitron(count_lbl, 9)
		count_lbl.add_theme_color_override("font_color",
			Color(0.95, 0.97, 1.0) if stored > 0.0 else Color(0.42, 0.45, 0.55))
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(count_lbl)

	var tier_suffix := ResourceData.TIER_SUFFIXES[clampi(rd.tier - 1, 0, ResourceData.TIER_SUFFIXES.size() - 1)]
	var tip_body := "R%d  ·  T%d %s" % [rd.rarity, rd.tier, tier_suffix]
	cell.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip(rd.unique_name, tip_body))
	cell.mouse_exited.connect(func() -> void:
		TooltipManager.hide_tip())

	return cell

## Square grid card: icon top, count bottom, fixed width. Used in resource grid.
func _mineral_grid_card(rd: ResourceData, stored: float, show_count: bool, sub_label: String = "", pp: PlanetProgress = null) -> PanelContainer:
	var rarity_col := _rarity_border_color(rd.rarity)

	var card := PanelContainer.new()
	var s    := StyleBoxFlat.new()
	s.bg_color            = Color(0.07, 0.08, 0.13, 0.92)
	s.border_color        = rarity_col
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 5; s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5; s.corner_radius_bottom_right = 5
	s.content_margin_left   = 6; s.content_margin_right  = 6
	s.content_margin_top    = 6; s.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", s)
	card.custom_minimum_size = Vector2(44, 44) if not show_count else Vector2(52, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var tex       := MineralIcon.make(rd.tier, rd.display_color)
	var icon_rect := TextureRect.new()
	icon_rect.texture   = tex
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if show_count:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vbox)

		icon_rect.custom_minimum_size   = Vector2(28, 28)
		icon_rect.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(icon_rect)

		var count_lbl := Label.new()
		count_lbl.text = _fmt_amount(stored)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_orbitron(count_lbl, 10)
		count_lbl.add_theme_color_override("font_color",
			Color(0.95, 0.97, 1.0) if stored > 0.0 else Color(0.42, 0.45, 0.55))
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(count_lbl)
	else:
		var vbox2 := VBoxContainer.new()
		vbox2.add_theme_constant_override("separation", 2)
		vbox2.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vbox2)

		icon_rect.custom_minimum_size   = Vector2(32, 32)
		icon_rect.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox2.add_child(icon_rect)

		if sub_label != "":
			var sl := Label.new()
			sl.text = sub_label
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_apply_orbitron(sl, 7)
			sl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.90))
			sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox2.add_child(sl)

	# Hover juice: scale up + yellow border highlight, z_index brings to front
	card.mouse_entered.connect(func() -> void:
		AudioManager.play("poi_hover")
		card.z_index = 10
		card.pivot_offset = card.size * 0.5
		var tw := card.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2(1.10, 1.10), 0.12)
		s.border_color = Color(1.0, 0.90, 0.25))
	card.mouse_exited.connect(func() -> void:
		card.z_index = 0
		card.pivot_offset = card.size * 0.5
		var tw := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.10)
		s.border_color = rarity_col)

	var tier_suffix := ResourceData.TIER_SUFFIXES[clampi(rd.tier - 1, 0, ResourceData.TIER_SUFFIXES.size() - 1)]
	var cap_rd := rd
	var cap_pp := pp
	card.mouse_entered.connect(func() -> void:
		var header := "R%d  ·  T%d %s" % [cap_rd.rarity, cap_rd.tier, tier_suffix]
		var rid    := cap_rd.resource_id()
		if cap_pp == null:
			TooltipManager.show_tip(cap_rd.unique_name, header)
			return
		# Compute per-building income / expense for this resource
		var income_lines: Array[String] = []
		var expense_lines: Array[String] = []
		var net: float = 0.0
		var raw_here: Dictionary = GameState.get_body_resources(cap_pp.planet_seed).resources
		for entry: Dictionary in cap_pp.buildings:
			if entry.get("constructing", false): continue
			var def := BuildingDef.find(entry.get("building_id", ""))
			if def == null: continue
			var amt: int     = entry.get("amount", 1)
			var cycle: float = def.tick_duration if def.tick_duration > 0.0 else 1.0
			# Producer: mines split their raw output over the planet's raw resources
			if def.outputs.has(Economy.RAW) and raw_here.has(rid):
				var rate: float = ProductionManager.output_per_cycle(cap_pp, entry, def, Economy.RAW) \
					/ float(raw_here.size()) / cycle
				income_lines.append("+%.2f/s  %s" % [rate, def.display_name])
				net += rate
			# Consumer: a converter whose fixed recipe uses this resource
			if def.inputs.has(rid):
				var rate: float = float(def.inputs[rid]) * float(amt) / cycle
				expense_lines.append("−%.2f/s  %s" % [rate, def.display_name])
				net -= rate
		var body_lines: Array[String] = [header]
		if not income_lines.is_empty() or not expense_lines.is_empty():
			body_lines.append("")
			body_lines.append_array(income_lines)
			body_lines.append_array(expense_lines)
		var net_cost: String = ""
		if not income_lines.is_empty() or not expense_lines.is_empty():
			var net_sign := "+" if net >= 0.0 else ""
			net_cost = "%s%.2f / s" % [net_sign, net]
		TooltipManager.show_tip(cap_rd.unique_name, "\n".join(body_lines), net_cost)
		# Tint Net label red when negative
		if net_cost != "":
			TooltipManager.set_cost_color(Color(0.35, 0.85, 0.45) if net >= 0.0 else Color(0.90, 0.38, 0.28)))
	card.mouse_exited.connect(func() -> void:
		TooltipManager.hide_tip())

	return card

func _details_section(parent: VBoxContainer, title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	_apply_orbitron(lbl, 8)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.45, 0.65))
	parent.add_child(lbl)
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.2, 0.25, 0.4, 0.4)
	sep_style.content_margin_top    = 0
	sep_style.content_margin_bottom = 0
	sep.add_theme_stylebox_override("separator", sep_style)
	parent.add_child(sep)

func _fill_uncolonized_details(vbox: VBoxContainer, data: PlanetData) -> void:
	_fill_modifiers_section(vbox, data)
	_details_section(vbox, "PLANET INFO")
	_details_row(vbox, "Type", PlanetData.Type.keys()[data.planet_type].capitalize())
	var size_str := "Small" if data.planet_size < 0.8 else ("Large" if data.planet_size > 1.3 else "Medium")
	_details_row(vbox, "Size", size_str)
	if data.has_atmosphere:
		var atm := "Thin" if data.atmosphere_density < 0.4 else ("Dense" if data.atmosphere_density > 0.7 else "Standard")
		_details_row(vbox, "Atm.", atm)
	else:
		_details_row(vbox, "Atm.", "None", Color(0.6, 0.4, 0.4))
	_details_section(vbox, "STATUS")
	_details_row(vbox, "Colony", "Not established", Color(0.65, 0.45, 0.35))
	_fill_deposits_section(vbox, data)

func _fill_colonized_details(vbox: VBoxContainer, data: PlanetData, _pp: PlanetProgress) -> void:
	_fill_modifiers_section(vbox, data)
	_details_section(vbox, "PLANET INFO")
	_details_row(vbox, "Type", PlanetData.Type.keys()[data.planet_type].capitalize())
	var size_str := "Small" if data.planet_size < 0.8 else ("Large" if data.planet_size > 1.3 else "Medium")
	_details_row(vbox, "Size", size_str)
	if data.has_atmosphere:
		var atm := "Thin" if data.atmosphere_density < 0.4 else ("Dense" if data.atmosphere_density > 0.7 else "Standard")
		_details_row(vbox, "Atm.", atm)
	else:
		_details_row(vbox, "Atm.", "None", Color(0.6, 0.4, 0.4))
	_fill_deposits_section(vbox, data)

## Left panel "MINERALS" — the body's minerals once discovered (a Production
## building or district completed here). Every site on the body yields all of them.
func _fill_deposits_section(vbox: VBoxContainer, data: PlanetData) -> void:
	if Economy.raw_for_body(data).is_empty():
		return
	_details_section(vbox, "MINERALS")
	if not GameState.is_body_surveyed(data.seed):
		_details_row(vbox, "Unknown", "build Production here", Color(0.55, 0.60, 0.78))
		return
	var br := GameState.get_body_resources_for(data)
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	for r: Dictionary in Economy.discovered_raw_for_body(data):
		var rd: ResourceData = br.resources.get(r["id"], null)
		if rd != null:
			grid.add_child(_mineral_grid_card(rd, 0.0, false, ""))
	vbox.add_child(grid)

## Active building count for a district (for night-light glow size).
## Excludes constructing and user-paused buildings.
func _district_night_size(data: PlanetData, district_label: String) -> int:
	var pp := GameState.get_planet(data.seed)
	var total: int = 0
	var entries := pp.buildings_in_district(district_label)
	for i in entries.size():
		var b: Dictionary = entries[i]
		if b.get("constructing", false):
			continue
		var global_idx: int = pp.building_real_index(b)
		var pm_key: String  = "%d:%s:%s" % [data.seed, district_label, b.get("uid", "-1")]
		if ProductionManager.is_user_paused(pm_key):
			continue
		total += b.get("amount", 1)
	# A finished district is lived in even before it has buildings; a City
	# also glows with every district built under it.
	var me := _find_poi(data, district_label)
	if me != null and not me.constructing:
		total += 2 if me.is_city() else 1
		if me.is_city():
			for child: POIData in data.custom_pois:
				if child.parent_city == district_label and not child.constructing and not child.is_orbital():
					total += 1
	return total

func _update_poi_night_sizes(data: PlanetData) -> void:
	for i in poi_layer._pois.size():
		var label: String = poi_layer._pois[i]["label"]
		poi_layer._pois[i]["data"]["night_size"] = _district_night_size(data, label)

## Returns total energy balance (positive = surplus) and per-district breakdown dict.
func _planet_energy_breakdown(pp: PlanetProgress, data: PlanetData) -> Dictionary:
	var total: float = 0.0
	var by_district: Dictionary = {}  # label -> float
	for b: Dictionary in pp.buildings:
		var contrib := ProductionManager.entry_energy(pp, b)
		if contrib == 0.0:
			continue
		var label: String = b.get("district_id", "")
		total += contrib
		by_district[label] = by_district.get(label, 0.0) + contrib
	for poi: POIData in data.custom_pois:
		var base_e := ProductionManager.district_base(pp, poi, Economy.ENERGY)
		if base_e != 0.0 and not poi.is_orbital():
			total += base_e
			by_district[poi.label] = by_district.get(poi.label, 0.0) + base_e
	var result: Dictionary = { "total": total }
	for poi: POIData in data.custom_pois:
		if by_district.has(poi.label):
			result[poi.label] = by_district[poi.label]
	return result

func _planet_energy_balance(_pp: PlanetProgress) -> float:
	return ProductionManager.get_global_energy()

func _fill_modifiers_section(vbox: VBoxContainer, data: PlanetData) -> void:
	var mods := PlanetModifier.for_planet(data.planet_type)
	if mods.is_empty():
		return
	var tag_row := HFlowContainer.new()
	tag_row.add_theme_constant_override("h_separation", 4)
	tag_row.add_theme_constant_override("v_separation", 5)
	tag_row.size_flags_horizontal = Control.SIZE_FILL
	for m: PlanetModifier in mods:
		var positive := m.is_positive()
		var tag := Button.new()
		tag.text = "%s %s" % [m.display_name, m.value_label()]
		tag.flat = true
		_apply_orbitron(tag, 8)
		# Outer glow/outline wrapper — dark stroke around the pill
		var outer := PanelContainer.new()
		var os := StyleBoxFlat.new()
		os.bg_color    = Color(0.0, 0.0, 0.0, 0.55)
		os.border_color = Color(0.0, 0.0, 0.0, 0.45)
		os.border_width_left = 1; os.border_width_right  = 1
		os.border_width_top  = 1; os.border_width_bottom = 1
		os.corner_radius_top_left     = 5; os.corner_radius_top_right    = 5
		os.corner_radius_bottom_left  = 5; os.corner_radius_bottom_right = 5
		os.content_margin_left   = 1; os.content_margin_right  = 1
		os.content_margin_top    = 1; os.content_margin_bottom = 1
		outer.add_theme_stylebox_override("panel", os)
		outer.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var border_col := Color(0.35, 0.85, 0.48, 0.90) if positive else Color(0.88, 0.32, 0.32, 0.90)
		var bg_col     := Color(0.07, 0.18, 0.10, 0.88) if positive else Color(0.18, 0.06, 0.06, 0.88)
		var s := StyleBoxFlat.new()
		s.bg_color = bg_col
		s.border_color = border_col
		s.border_width_left = 1; s.border_width_right  = 1
		s.border_width_top  = 1; s.border_width_bottom = 1
		s.corner_radius_top_left     = 4; s.corner_radius_top_right    = 4
		s.corner_radius_bottom_left  = 4; s.corner_radius_bottom_right = 4
		s.content_margin_left = 6; s.content_margin_right  = 6
		s.content_margin_top  = 2; s.content_margin_bottom = 2
		tag.add_theme_stylebox_override("normal",  s)
		tag.add_theme_stylebox_override("hover",   s)
		tag.add_theme_stylebox_override("pressed", s)
		tag.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
		tag.add_theme_color_override("font_color",
			Color(0.55, 0.96, 0.62) if positive else Color(1.0, 0.58, 0.58))
		outer.add_child(tag)
		var cap_m := m
		tag.mouse_entered.connect(func() -> void:
			TooltipManager.show_tip(cap_m.display_name, cap_m.description))
		tag.mouse_exited.connect(func() -> void:
			TooltipManager.hide_tip())
		tag_row.add_child(outer)
	vbox.add_child(tag_row)

func _build_system_panel() -> void:
	if _system_dock and is_instance_valid(_system_dock):
		_system_dock.queue_free()
		_system_dock = null
		
	# The bottom dock showing the local system moons has been removed
	# since players can now view and click moons in the Local System mode.

func _build_companion_moons(_data: PlanetData) -> void:
	pass   # replaced by bottom dock in _build_system_panel

func _on_planet_hover_on() -> void:
	pass

func _on_planet_hover_off() -> void:
	pass

func _position_companions() -> void:
	pass

func _setup_lowres_planet() -> void:
	var cont := planet_renderer.get_parent() as Control
	_planet_vp = SubViewport.new()
	_planet_vp.transparent_bg = true
	_planet_vp.disable_3d = true
	_planet_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_planet_vp.size = Vector2i(64, 64)
	_planet_px = ColorRect.new()
	_planet_px.material = planet_renderer.material
	_planet_vp.add_child(_planet_px)
	cont.add_child(_planet_vp)
	_planet_view = TextureRect.new()
	_planet_view.texture = _planet_vp.get_texture()
	_planet_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_planet_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_planet_view.stretch_mode = TextureRect.STRETCH_SCALE
	_planet_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(_planet_view)
	cont.move_child(_planet_view, planet_renderer.get_index() + 1)
	# the full-res renderer no longer draws; it keeps handling input + geometry
	planet_renderer.visible = false

## Sizes the low-res render to exactly one texel per planet pixel and lays the
## upscaled view over the renderer's rect (same centre, same height).
func _update_aspect() -> void:
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null:
		return
	# The renderer is hidden (it only handles input + geometry) — keep its rect
	# glued to the container explicitly rather than trusting hidden-layout updates.
	var cont := planet_renderer.get_parent() as Control
	if cont != null and (planet_renderer.position != Vector2.ZERO or planet_renderer.size != cont.size):
		planet_renderer.position = Vector2.ZERO
		planet_renderer.size = cont.size
	var s := planet_renderer.size
	if s.y <= 0.0:
		return
	var vh := maxi(1, int(round(float(mat.get_shader_parameter("pixel_count")))))
	var cell := s.y / float(vh)
	var vw := int(ceil(s.x / cell))
	vw += vw % 2   # even width keeps the globe centred on a texel boundary
	mat.set_shader_parameter("aspect_ratio", float(vw) / float(vh))
	if _planet_vp == null:
		return
	if _planet_vp.size != Vector2i(vw, vh):
		_planet_vp.size = Vector2i(vw, vh)
		_planet_px.size = Vector2(vw, vh)
	_planet_view.z_index = planet_renderer.z_index
	_planet_view.size = Vector2(float(vw) * cell, s.y)
	_planet_view.position = planet_renderer.position + Vector2((s.x - _planet_view.size.x) * 0.5, 0.0)
	poi_layer.pixel_grid_origin = _planet_view.global_position

func _on_resize() -> void:
	await get_tree().process_frame
	_apply_zoom()

func _setup_orbital_layer(planet_seed: int) -> void:
	# Same planet reloaded (a district placed, a level gained…): keep the layer,
	# so ships mid-landing and orbit reveals aren't cut off.
	if _orbital_layer != null and is_instance_valid(_orbital_layer) \
			and not _orbital_layer.is_queued_for_deletion() and _orbital_layer._planet_seed == planet_seed:
		return
	# Disconnect any previous ShipManager bindings to avoid accumulation
	if ShipManager.ship_added.is_connected(_on_ship_roster_changed):
		ShipManager.ship_added.disconnect(_on_ship_roster_changed)
	if ShipManager.ship_arrived.is_connected(_on_ship_roster_changed):
		ShipManager.ship_arrived.disconnect(_on_ship_roster_changed)
	# Remove old layer if switching planets
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.queue_free()
	var layer := OrbitalLayer.new()
	layer.z_index = 5   # above planet, below HUD rings
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	planet_renderer.get_parent().add_child(layer)
	layer.setup(planet_seed)
	layer.ship_hovered.connect(func(_ship: ShipData, _pos: Vector2) -> void:
		pass)   # Name drawn directly on OrbitalLayer canvas (like districts)
	layer.ship_unhovered.connect(func() -> void:
		pass)
	layer.ship_clicked.connect(func(ship: ShipData) -> void:
		TooltipManager.hide_tip()
		layer.suppress_label = true
		_show_ship_panel(ship, layer))
	layer.ship_deselected.connect(func() -> void:
		layer.suppress_label = false
		_close_ship_panel()
		_close_radial_menu())
	layer.ship_right_clicked.connect(func(ship: ShipData, gpos: Vector2) -> void:
		_show_radial_menu(ship, gpos, layer))
	layer.landing_site_for = _ship_landing_site
	layer.ship_landed.connect(func(landed_ship: ShipData) -> void:
		# Return cargo to planet storage on landing
		var dest_pp := GameState.get_planet(landed_ship.orbit_seed)
		if dest_pp != null and not landed_ship.cargo.is_empty():
			for res_id: String in landed_ship.cargo:
				GameState.add_resource(res_id, float(landed_ship.cargo[res_id]))
			GameState.planet_progress_changed.emit(landed_ship.orbit_seed)
		if current_data != null: _refresh_active_panel())
	ShipManager.ship_arrived.connect(_on_ship_roster_changed)
	ShipManager.ship_added.connect(_on_ship_roster_changed)
	layer.station_poi_clicked.connect(func(poi_label: String) -> void:
		if current_data == null: return
		for poi: POIData in current_data.custom_pois:
			if poi.label == poi_label and poi.is_orbital():
				_active_district_poi = poi
				layer.set_selected_station(poi_label)
				poi_layer.deselect_all()
				_reveal_panel()
				_build_district_panel(poi, current_data)
				return)
	_orbital_layer = layer
	_add_orbit_toggle(planet_renderer.get_parent(), layer)
	_register_ship_commands(layer)

func _on_ship_roster_changed(ship: ShipData) -> void:
	if current_data != null and ship.orbit_seed == current_data.seed:
		_refresh_active_panel()

func _register_ship_commands(layer: OrbitalLayer) -> void:
	ShipCommandRegistry.register_callable("deselect",
		func(ship: ShipData, _l: OrbitalLayer) -> void: layer.deselect())
	ShipCommandRegistry.register_callable("land",
		func(ship: ShipData, _l: OrbitalLayer) -> void:
			_close_ship_panel()
			layer.start_landing(ship))
	ShipCommandRegistry.register_callable("solar_view",
		func() -> void:
			CursorManager.set_state(CursorManager.State.EXIT)
			_go_back())
	ShipCommandRegistry.register_callable("rendezvous",
		func(ship: ShipData, _l: OrbitalLayer) -> void:
			_show_rendezvous_picker(ship, layer))
	if layer.rendezvous_reached.get_connections().is_empty():
		layer.rendezvous_reached.connect(func(ship: ShipData, target: ShipData) -> void:
			# rendezvous reached
			# Floating text at meeting point
			var sv := layer._project(ship, ship.orbit_angle)
			var r: float = layer._planet_radius * ship.orbit_radius
			var nx: float = sv.x / r; var ny: float = sv.y / r
			var lat_r: float = -asin(clampf(ny, -1.0, 1.0))
			var lon_r: float = asin(clampf(nx / maxf(cos(lat_r), 0.01), -1.0, 1.0))
			poi_layer.spawn_floating_text(
				rad_to_deg(lon_r + layer._planet_rotation), rad_to_deg(lat_r),
				"Rendezvous", Color(0.30, 0.92, 1.0, 1.0), 12)
			# Execute rendezvous_tasks from the current move_station entry
			var lon_deg2: float = rad_to_deg(lon_r + layer._planet_rotation)
			var lat_deg2: float = rad_to_deg(lat_r) + 2.0
			var ms_task: Dictionary = ship.mission_tasks[ship.mission_task_index]
			ship.mission_task_index += 1  # past move_station
			for t: Dictionary in ms_task.get("rendezvous_tasks", []):
				var ttype: String = t.get("type", "")
				if ttype == "deliver":
					for res_id: String in ship.cargo:
						target.cargo[res_id] = target.cargo.get(res_id, 0) + ship.cargo[res_id]
					ship.cargo.clear()
					poi_layer.spawn_floating_text(lon_deg2, lat_deg2, "Delivered!", Color(0.35, 1.0, 0.50, 1.0), 11)
				elif ttype == "pickup":
					var res_id: String = t.get("transfer_resource", "")
					var want: int      = t.get("transfer_amount", 0)
					var avail: int     = int(target.cargo.get(res_id, 0))
					var take: int      = mini(want, avail)
					if take > 0:
						target.cargo[res_id] = avail - take
						ship.cargo[res_id]   = ship.cargo.get(res_id, 0) + take
					poi_layer.spawn_floating_text(lon_deg2, lat_deg2, "Loaded x%d!" % take, Color(0.35, 1.0, 0.50, 1.0), 11)
			# Normalize orbit_node for clean landing trajectory
			if ship.orbit_node != 0.0:
				var anchor: Vector2 = layer._project_2d(ship, ship.orbit_angle)
				ship.orbit_node = 0.0
				var a: float = ship.orbit_angle
				for _i: int in 16:
					var p0: Vector2 = layer._project_2d(ship, a)
					var p1: Vector2 = layer._project_2d(ship, a + 0.005)
					var tangent: Vector2 = (p1 - p0) / 0.005
					var err: Vector2 = p0 - anchor
					if tangent.length_squared() < 0.0001:
						break
					a -= err.dot(tangent) / tangent.length_squared()
				ship.orbit_angle = a
			_advance_mission(ship))

## Ship info panel — appears at bottom-left of planet view when a ship is selected.
func _show_ship_panel(ship: ShipData, layer: OrbitalLayer) -> void:
	_close_ship_panel()
	# Station ships also open the district panel immediately
	if ship.ship_type == "station" and current_data != null:
		_open_station_district(ship, planet_renderer.get_parent())
	var planet_cont: Control = planet_renderer.get_parent()

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.08, 0.14, 0.92)
	ps.border_color = Color(1.0, 0.92, 0.30, 0.70)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(5)
	ps.content_margin_left = 14; ps.content_margin_right  = 14
	ps.content_margin_top  = 10; ps.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", ps)
	panel.z_index = 10
	panel.custom_minimum_size = Vector2(180, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Name + status on the same row (name left, status right)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var name_lbl := Label.new()
	name_lbl.text = ship.ship_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(name_lbl, 11)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30))
	title_row.add_child(name_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "In orbit" if not ship.is_travelling() else "En route…"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_orbitron(status_lbl, 9)
	status_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.95, 0.80))
	title_row.add_child(status_lbl)

	# Cargo — inventory card style matching PlanetOverview
	if not ship.cargo.is_empty():
		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color(1, 1, 1, 0.12))
		vbox.add_child(sep)
		var cargo_grid := GridContainer.new()
		cargo_grid.columns = 4
		cargo_grid.add_theme_constant_override("h_separation", 4)
		cargo_grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(cargo_grid)
		for rid: String in ship.cargo:
			var rd: ResourceData = GameState.known_resources.get(rid, null)
			if rd == null:
				continue
			cargo_grid.add_child(_mineral_grid_card(rd, ship.cargo[rid], true))

	# ── Capacity row ─────────────────────────────────────────────────────────
	var cap_sep := HSeparator.new()
	cap_sep.add_theme_color_override("color", Color(1, 1, 1, 0.10))
	vbox.add_child(cap_sep)

	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 6)
	vbox.add_child(cap_row)

	var cargo_hint := Label.new()
	cargo_hint.text = "right-click for actions"
	cargo_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(cargo_hint, 7)
	cargo_hint.add_theme_color_override("font_color", Color(0.4, 0.5, 0.7, 0.5))
	cargo_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_row.add_child(cargo_hint)

	# Cargo weight used / capacity — bottom right
	var ship_cap: int = 60 if ship.ship_type == "station" else 20
	var ship_used: int = 0
	for rid: String in ship.cargo:
		var rd2: ResourceData = GameState.known_resources.get(rid, null)
		if rd2 != null:
			ship_used += (rd2.rarity + rd2.tier - 1) * int(ship.cargo[rid])
	var cap_lbl3 := Label.new()
	cap_lbl3.text = "%d / %d" % [ship_used, ship_cap]
	_apply_orbitron(cap_lbl3, 7)
	cap_lbl3.add_theme_color_override("font_color",
		Color(0.42, 0.88, 0.58) if ship_used <= ship_cap else Color(0.95, 0.38, 0.28))
	cap_lbl3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cap_lbl3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_row.add_child(cap_lbl3)

	panel.anchor_left = 0; panel.anchor_top = 0
	panel.anchor_right = 0; panel.anchor_bottom = 0
	planet_cont.add_child(panel)
	_ship_panel = panel

func _close_ship_panel() -> void:
	if _ship_panel != null and is_instance_valid(_ship_panel):
		_ship_panel.queue_free()
	_ship_panel = null

## Info panel for a ship that is currently launching (not yet in orbit).
func _show_launch_info_panel(anim_d: Dictionary, container: Control) -> void:
	_close_ship_panel()

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.08, 0.14, 0.92)
	ps.border_color = Color(1.0, 0.92, 0.30, 0.70)
	ps.set_border_width_all(1); ps.set_corner_radius_all(5)
	ps.content_margin_left = 14; ps.content_margin_right  = 14
	ps.content_margin_top  = 10; ps.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", ps)
	panel.z_index = 10
	panel.custom_minimum_size = Vector2(180, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var name_lbl := Label.new()
	name_lbl.text = anim_d.get("ship_name", "Ship")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(name_lbl, 11)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30))
	title_row.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = anim_d.get("ship_type", "shuttle").capitalize()
	_apply_orbitron(type_lbl, 9)
	type_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0, 0.75))
	title_row.add_child(type_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "launching to orbit"
	_apply_orbitron(status_lbl, 8)
	status_lbl.add_theme_color_override("font_color", Color(0.45, 0.90, 0.65, 0.80))
	vbox.add_child(status_lbl)

	# Cargo
	var cargo: Dictionary = anim_d.get("ship_cargo", {})
	if not cargo.is_empty():
		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color(1, 1, 1, 0.12))
		vbox.add_child(sep)
		var cargo_grid := GridContainer.new()
		cargo_grid.columns = 4
		cargo_grid.add_theme_constant_override("h_separation", 4)
		cargo_grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(cargo_grid)
		for rid: String in cargo:
			var rd: ResourceData = GameState.known_resources.get(rid, null)
			if rd != null:
				cargo_grid.add_child(_mineral_grid_card(rd, float(cargo[rid]), true))

	container.add_child(panel)
	_ship_panel = panel
	# Store rocket ref so _process can follow it each frame
	var rocket: Control = anim_d.get("rocket", null)
	panel.set_meta("launch_rocket", rocket if rocket != null else Control.new())
	if rocket != null and is_instance_valid(rocket):
		panel.position = rocket.position + Vector2(16, -40)

func _close_radial_menu() -> void:
	if _radial_menu != null and is_instance_valid(_radial_menu):
		_radial_menu.queue_free()
	_radial_menu = null
	CursorManager.set_state(CursorManager.State.NORMAL)

func _show_planet_radial_menu(global_pos: Vector2) -> void:
	var defs := ShipCommandRegistry.get_planet_commands()
	var actions: Array[Dictionary] = []
	for def: ShipCommandDef in defs:
		if not ShipCommandRegistry.has_callable(def.command_id):
			continue
		var cb: Callable = ShipCommandRegistry.get_callable(def.command_id)
		actions.append({
			"icon":   def.icon,
			"label":  def.label,
			"color":  def.color,
			"action": func() -> void: cb.call(),
		})
	if actions.is_empty():
		return
	_show_radial_menu_at(actions, global_pos)

func _show_radial_menu(ship: ShipData, global_pos: Vector2, layer: OrbitalLayer) -> void:
	var defs := ShipCommandRegistry.get_ship_commands(ship.ship_type)
	var actions: Array[Dictionary] = []
	for def: ShipCommandDef in defs:
		if not ShipCommandRegistry.has_callable(def.command_id):
			continue
		var cb: Callable = ShipCommandRegistry.get_callable(def.command_id)
		actions.append({
			"icon":   def.icon,
			"label":  def.label,
			"color":  def.color,
			"action": func() -> void: cb.call(ship, layer),
		})
	if actions.is_empty():
		return
	_show_radial_menu_at(actions, global_pos, ship)

func _show_radial_menu_at(actions: Array[Dictionary], global_pos: Vector2,
		follow_ship: ShipData = null) -> void:
	_close_radial_menu()
	var container: Control = planet_renderer.get_parent()
	var local_pos: Vector2 = global_pos - container.get_global_rect().position

	const RADIUS:   float = 52.0
	const BTN_R:    float = 16.0
	const FADE_DUR: float = 0.12

	var menu := Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.z_index = 20
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(menu)
	_radial_menu = menu

	# Full-screen backdrop: click outside closes menu
	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close_radial_menu())
	menu.add_child(backdrop)

	# ESC is handled in _input when _radial_menu != null

	# Pivot: all radial elements live here; repositioned each frame when following a ship
	var pivot := Control.new()
	pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot.z_index = 1
	pivot.position = local_pos
	menu.add_child(pivot)
	if follow_ship != null:
		menu.set_meta("follow_ship", follow_ship)
		menu.set_meta("pivot_node",  pivot)

	# Connector lines — drawn in pivot-local space (origin = ship center)
	var lines_ctrl := Control.new()
	lines_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line_fade: Array[float] = [0.0]
	var line_endpoints: Array[Vector2] = []
	lines_ctrl.draw.connect(func() -> void:
		for ep: Vector2 in line_endpoints:
			lines_ctrl.draw_line(Vector2.ZERO, ep,
				Color(0.5, 0.6, 0.9, 0.25 * line_fade[0]), 1.0, true))
	pivot.add_child(lines_ctrl)

	var n: int = actions.size()
	for i in n:
		var angle: float = -PI * 0.5 + (float(i) / maxf(float(n), 1.0)) * TAU if n > 1 else -PI * 0.5
		var btn_center: Vector2 = Vector2(cos(angle), sin(angle)) * RADIUS
		line_endpoints.append(btn_center)

		var btn_ctrl := Control.new()
		btn_ctrl.position = btn_center - Vector2(BTN_R, BTN_R)
		btn_ctrl.custom_minimum_size = Vector2(BTN_R * 2.0, BTN_R * 2.0)
		btn_ctrl.size                = Vector2(BTN_R * 2.0, BTN_R * 2.0)
		btn_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_ctrl.z_index = 2

		var ac: Dictionary        = actions[i]
		var btn_color: Color      = ac["color"]
		var btn_hovered: Array[bool]  = [false]
		var fade_ref: Array[float]    = [0.0]

		btn_ctrl.draw.connect(func() -> void:
			var f: float = fade_ref[0]
			var h: bool  = btn_hovered[0]
			btn_ctrl.draw_circle(Vector2(BTN_R, BTN_R), BTN_R,
				Color(0.06, 0.08, 0.18, 0.93 * f))
			if h:
				btn_ctrl.draw_circle(Vector2(BTN_R, BTN_R), BTN_R,
					Color(btn_color, 0.18 * f))
			var pts := PackedVector2Array()
			for k in 24:
				var a: float = float(k) / 24.0 * TAU
				pts.append(Vector2(BTN_R + cos(a) * (BTN_R - 1.0),
								   BTN_R + sin(a) * (BTN_R - 1.0)))
			pts.append(pts[0])
			btn_ctrl.draw_polyline(pts, Color(btn_color, (0.75 if h else 0.40) * f), 1.5, true)
			var font: Font = ThemeDB.fallback_font
			var txt: String = ac["icon"]
			var tsz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			var tp := Vector2(BTN_R - tsz.x * 0.5, BTN_R + tsz.y * 0.38)
			btn_ctrl.draw_string(font, tp + Vector2(0, 1), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.55 * f))
			btn_ctrl.draw_string(font, tp, txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(btn_color, f)))

		var lbl := Label.new()
		lbl.text = ac["label"]
		_apply_orbitron(lbl, 7)
		lbl.add_theme_color_override("font_color", Color(btn_color, 0.70))
		var font_tmp: Font = ThemeDB.fallback_font
		var lsz := font_tmp.get_string_size(ac["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
		lbl.position = Vector2(BTN_R - lsz.x * 0.5, BTN_R * 2.0 + 3.0)
		btn_ctrl.add_child(lbl)

		btn_ctrl.mouse_entered.connect(func() -> void:
			btn_hovered[0] = true
			btn_ctrl.queue_redraw()
			CursorManager.set_state(CursorManager.State.POINTER))
		btn_ctrl.mouse_exited.connect(func() -> void:
			btn_hovered[0] = false
			btn_ctrl.queue_redraw()
			CursorManager.set_state(CursorManager.State.NORMAL))
		btn_ctrl.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton:
				var mb2 := ev as InputEventMouseButton
				if mb2.button_index == MOUSE_BUTTON_LEFT and mb2.pressed:
					_close_radial_menu()
					(ac["action"] as Callable).call())

		pivot.add_child(btn_ctrl)

		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v: float) -> void:
			fade_ref[0] = v
			line_fade[0] = v
			btn_ctrl.queue_redraw()
			lines_ctrl.queue_redraw(), 0.0, 1.0, FADE_DUR)

## Orbit visibility toggle — bottom-right corner of planet view.
func _add_orbit_toggle(planet_cont: Control, layer: OrbitalLayer) -> void:
	for ch: Node in planet_cont.get_children():
		if ch.get_meta("orbit_toggle", false):
			ch.queue_free()

	const SIZE := 36.0
	var btn := Control.new()
	btn.set_meta("orbit_toggle", true)
	btn.custom_minimum_size = Vector2(SIZE, SIZE)
	btn.z_index = 12
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.tooltip_text = "Toggle orbits"

	var visible_ref: Array = [true]   # [0] = orbits visible
	btn.draw.connect(func() -> void:
		var is_vis: bool = visible_ref[0]
		var bg    := Color(0.06, 0.08, 0.14, 0.82)
		var border := Color(0.35, 0.55, 0.90, 0.55 if is_vis else 0.30)
		var icon_c := Color(0.55, 0.78, 1.0, 1.0 if is_vis else 0.35)
		var c      := Vector2(SIZE * 0.5, SIZE * 0.5)
		# Background rounded rect
		btn.draw_rect(Rect2(1, 1, SIZE - 2, SIZE - 2), bg)
		btn.draw_rect(Rect2(1, 1, SIZE - 2, SIZE - 2), border, false, 1.5)
		# Orbit ellipse: wide ellipse around center
		var pts: PackedVector2Array = []
		for i in 32:
			var a: float = (float(i) / 32.0) * TAU
			pts.append(c + Vector2(cos(a) * 12.0, sin(a) * 5.0))
		btn.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(icon_c, 0.70), 1.2, true)
		# Small satellite: cross at orbit's right side
		var sp := c + Vector2(12.0, 0.0)
		btn.draw_rect(Rect2(sp + Vector2(-1, -1), Vector2(2, 2)), icon_c)
		btn.draw_rect(Rect2(sp + Vector2(-3, 0),  Vector2(2, 1)), icon_c)
		btn.draw_rect(Rect2(sp + Vector2( 2, 0),  Vector2(2, 1)), icon_c)
		# Eye shape in center
		if is_vis:
			btn.draw_arc(c, 5.0, -PI * 0.55, PI * 0.55, 12, icon_c, 1.2, true)
			btn.draw_arc(c, 5.0,  PI * 0.45, PI * 1.55, 12, icon_c, 1.2, true)
			btn.draw_circle(c, 2.0, icon_c)
		else:
			# Crossed-out eye
			btn.draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), icon_c, 1.5, true))

	btn.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				layer.visible = not layer.visible
				visible_ref[0] = layer.visible
				_orbits_shown = layer.visible   # flights and lanes between worlds too
				btn.queue_redraw())

	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))

	planet_cont.add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	btn.offset_bottom = -12
	btn.offset_left   = 40   # clear of the panel's open/close tab
	btn.offset_top    = btn.offset_bottom - SIZE
	btn.offset_right  = btn.offset_left + SIZE

func _process(delta: float) -> void:
	_poll_slot_dropdown(delta)
	_tick_spaceport_focus()
	_tick_surface_scan(delta)
	_tick_lander_watch()
	_tick_departure_fx(delta)
	_tick_cam_follow(delta)
	if absf(($SidePanel as Control).offset_top - _hud_bar_height()) > 0.5:
		_apply_panel_t(_panel_t)
	_update_tutorial_highlight()
	_update_aspect()
	_tick_zoom(delta)
	_update_placement_hover()
	_tick_lander(delta)
	_tick_companions()
	_tick_key_spin(delta)
	if _reveal_ghost != null and is_instance_valid(_reveal_ghost) and not _switching_body:
		var gr := _globe_rect(_base_radius, _zoom)   # fading stand-in stays on the real globe
		_reveal_ghost.global_position = gr.position
		_reveal_ghost.size = gr.size
	var pmat := planet_renderer.material as ShaderMaterial
	if pmat != null:
		pmat.set_shader_parameter("district_reveal",   _district_reveal)
		pmat.set_shader_parameter("district_hover",    _shader_slot(poi_layer._hovered_index))
		pmat.set_shader_parameter("district_selected", _shader_slot(poi_layer._selected_index))
		# More districts than the shader draws: re-pick the visible ones as the globe turns
		if _territories.size() > MAX_TERRITORIES:
			var vc := _view_center_n()
			if vc != Vector3.ZERO and (_shader_view_n == Vector3.ZERO or vc.dot(_shader_view_n) < cos(deg_to_rad(4.0))):
				_push_shader_districts()
		pmat.set_shader_parameter("border_alpha", smoothstep(ZOOM_BORDER_START, ZOOM_BORDER_FULL, _zoom))
	# Holding Alt shows the network overview: every district (any zoom) with an
	# arc to the City it belongs to. Borders / ranges stay hidden — too busy.
	var overview := Input.is_key_pressed(KEY_ALT) and current_data != null
	poi_layer.show_overlay = overview
	# Holding Ctrl shows every district's border (any zoom).
	var all_borders := Input.is_key_pressed(KEY_CTRL) and current_data != null
	if pmat != null:
		pmat.set_shader_parameter("show_all_borders", 1.0 if all_borders else 0.0)
		if all_borders:
			pmat.set_shader_parameter("border_alpha", 1.0)
	# zoomed out only cities show; their districts fade in as you zoom
	poi_layer.detail = 1.0 if overview else smoothstep(ZOOM_DETAIL_START, ZOOM_DETAIL_FULL, _zoom)
	# hold H to hide markers + labels and see just the planet and its cities
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	var hide_markers := Input.is_key_pressed(KEY_H) and not typing and not overview
	_marker_vis_t = lerpf(_marker_vis_t, 0.0 if hide_markers else 1.0, 1.0 - exp(-delta * 16.0))
	poi_layer.marker_vis = _marker_vis_t
	# roads, sea lanes, ports and ships only once you're close
	poi_layer.road_vis = smoothstep(ZOOM_ROADS_START, ZOOM_ROADS_FULL, _zoom)
	if pmat != null:
		poi_layer.light_dir = (pmat.get_shader_parameter("light_direction") as Vector3).normalized()
	if _roads_dirty:
		_rebuild_roads()

	# Construction loop audio — active whenever any POI is constructing
	if current_data != null:
		var any_constructing := false
		for p: POIData in current_data.custom_pois:
			if p.constructing:
				any_constructing = true
				break
		AudioManager.set_construction_active(any_constructing)

	if _ring_back != null or _ring_front != null:
		_ring_angle = planet_renderer.get_rotation_offset()
		if _ring_back  and is_instance_valid(_ring_back):  _ring_back.queue_redraw()
		if _ring_front and is_instance_valid(_ring_front): _ring_front.queue_redraw()

	_light_angle = fposmod(_light_angle + delta * LIGHT_SPEED, TAU)
	_apply_light_angle()
	_update_cursor()
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer._planet_radius   = planet_renderer._planet_radius_px
		_orbital_layer._planet_rotation = planet_renderer.get_rotation_offset()
		_orbital_layer._planet_tilt     = planet_renderer.tilt
		var _oc: Control = planet_renderer.get_parent()
		_orbital_layer._planet_center   = planet_renderer.global_position + planet_renderer.size * 0.5 - _oc.get_global_rect().position
		# Advance space station orbit angles
		if current_data != null:
			for poi: POIData in current_data.custom_pois:
				if poi.is_orbital():
					poi.orbit_angle = fposmod(poi.orbit_angle + poi.orbit_speed * delta, TAU)
		_orbital_layer.queue_redraw()
		# Keep ship panel glued to selected ship, on opposite side from nameplate leader
		if _ship_panel != null and is_instance_valid(_ship_panel):
			# Launch panel: follow rocket position
			if _ship_panel.has_meta("launch_rocket"):
				var lrocket: Control = _ship_panel.get_meta("launch_rocket")
				if is_instance_valid(lrocket):
					_ship_panel.position = lrocket.position + Vector2(16, -_ship_panel.size.y * 0.5)
				else:
					_close_ship_panel()  # rocket finished, close panel
			else:
				var sel: ShipData = _orbital_layer._selected_ship
				if sel != null:
					var sv := _orbital_layer._project(sel, sel.orbit_angle)
					var spos := _orbital_layer._planet_center + Vector2(sv.x, sv.y)
					var panel_size := _ship_panel.size
					var cont_size  := _oc.size
					var center_x := cont_size.x * 0.5
					var label_goes_right: bool = spos.x >= center_x
					var px: float
					if label_goes_right:
						px = spos.x - panel_size.x - 16.0
					else:
						px = spos.x + 16.0
					px = clampf(px, 8.0, cont_size.x - panel_size.x - 8.0)
					var py: float = spos.y - panel_size.y * 0.5
					py = clampf(py, 8.0, cont_size.y - panel_size.y - 8.0)
					_ship_panel.position = Vector2(px, py)

		# Follow ship with radial menu pivot
		if _radial_menu != null and is_instance_valid(_radial_menu) \
				and _radial_menu.has_meta("follow_ship"):
			var fship: ShipData = _radial_menu.get_meta("follow_ship")
			var piv: Control    = _radial_menu.get_meta("pivot_node")
			if fship != null and is_instance_valid(piv):
				var sv := _orbital_layer._project(fship, fship.orbit_angle)
				if _orbital_layer._is_occluded(sv):
					_close_radial_menu()
				else:
					piv.position = _orbital_layer._planet_center + Vector2(sv.x, sv.y)

	if current_data != null:
		var pp := GameState.get_planet(current_data.seed)
		if pp != null and _planet_upgrade_pbar != null and is_instance_valid(_planet_upgrade_pbar):
			_planet_upgrade_pbar.value = pp.upgrade_progress * 100.0
		if pp != null:
			var _stale_dlabels: Array = []
			for dlabel in _district_upgrade_pbars:
				var dpbar = _district_upgrade_pbars[dlabel]
				if not is_instance_valid(dpbar):
					_stale_dlabels.append(dlabel)
				else:
					(dpbar as ProgressBar).value = pp.district_upgrading.get(dlabel, 0.0) * 100.0
			for dl in _stale_dlabels:
				_district_upgrade_pbars.erase(dl)

		# display only — ProductionManager advances (and finishes) construction
		for poi_label in _district_pbars:
			var pbar: ProgressBar = _district_pbars[poi_label]
			if is_instance_valid(pbar):
				for poi: POIData in current_data.custom_pois:
					if poi.label == poi_label:
						pbar.value = poi.construct_progress * 100.0
						break

	# Launch / deploy animations assume an untilted globe — lock the tilt only
	# while one is really flying, so a launch that never reports back can't
	# freeze the up/down camera for good.
	planet_renderer.tilt_locked = _tilt_lock_needed()
	if not _rocket_anims.is_empty():
		_tick_rocket_anim(delta)

	if not _deploy_anims.is_empty():
		_tick_deploy_anims(delta)

var _was_dragging: bool = false
func _update_cursor() -> void:
	if planet_renderer == null or planet_renderer._planet_radius_px <= 0:
		return
	if planet_renderer._dragging:
		CursorManager.set_state(CursorManager.State.GRAB)
		_was_dragging = true
	elif _was_dragging:
		CursorManager.set_state(CursorManager.State.NORMAL)
		_was_dragging = false

func _apply_light_angle() -> void:
	if planet_renderer == null:
		return
	# Just update the value — PlanetRenderer._process calls _update_light_direction()
	# at the END of every frame (after both parent and child _process have run),
	# so light_direction is always computed with fresh rotation_offset + light_angle.
	planet_renderer.light_angle = _light_angle



func _rotate_to_lon(lon_deg: float, duration: float = 0.45) -> void:
	var target  := fposmod(deg_to_rad(lon_deg), TAU)
	var current := fposmod(planet_renderer.get_rotation_offset(), TAU)
	var diff    := fposmod(target - current + PI, TAU) - PI
	var tween   := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(v: float) -> void: planet_renderer.set_rotation_offset(v),
		current, current + diff, duration)
	# (launch animations follow the camera tilt — no need to level it first)

## Spins and tilts the globe so (lon, lat) lands in the centre of the view.
## The view centre sits at latitude = tilt, so tilt goes to the site's latitude;
## set_tilt() clamps it to the polar limit (±MAX_TILT).
func _focus_on_site(lon_deg: float, lat_deg: float, duration: float = 0.45) -> void:
	var target  := fposmod(deg_to_rad(lon_deg), TAU)
	var current := fposmod(planet_renderer.get_rotation_offset(), TAU)
	var diff    := fposmod(target - current + PI, TAU) - PI
	var tween   := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(v: float) -> void: planet_renderer.set_rotation_offset(v),
		current, current + diff, duration)
	if not planet_renderer.tilt_locked:
		var tilt_target := clampf(deg_to_rad(lat_deg), -planet_renderer.MAX_TILT, planet_renderer.MAX_TILT)
		tween.parallel().tween_method(
			func(v: float) -> void: planet_renderer.set_tilt(v),
			planet_renderer.tilt, tilt_target, duration)

# ── Resource lenses ───────────────────────────────────────────────────────────

func _lens_button_style(active: bool, tint: Color = Color(0.55, 0.70, 1.0)) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.10, 0.13, 0.24, 0.95) if active else Color(0.05, 0.07, 0.13, 0.88)
	st.border_color = Color(1.0, 0.85, 0.40, 0.9) if active else Color(tint, 0.35)
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.content_margin_left = 8; st.content_margin_right = 8
	st.content_margin_top = 4;  st.content_margin_bottom = 4
	return st

func _make_lens_button(text: String, tint: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	_apply_orbitron(b, 8)
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
	b.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	b.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		on_press.call())
	return b

## Role buttons at the bottom of the planet view: pick a role (Energy,
## Population, Production, Science, Commercial) to see where it thrives — the
## visible features that boost it, strong (solid) or good (dotted). Same data as
## the map and the economy (FeatureMap.role_texture). Click again to clear.
func _rebuild_lens_bar() -> void:
	if _lens_bar != null and is_instance_valid(_lens_bar):
		_lens_bar.queue_free()
	_lens_buttons.clear()
	if current_data == null or not FeatureMap.has_map(current_data.seed):
		return
	if _role != "" and not GameState.is_scanned(current_data.seed):
		_set_role("")   # a lens left on from another world
	var cont := planet_renderer.get_parent() as Control
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.z_index = 50
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for role: String in FeatureMap.ROLES:
		var info: Dictionary = FeatureMap.ROLES[role]
		var tint: Color = info["tint"]
		var cap_role := role
		var b := _make_lens_button(String(info["label"]).to_upper(), tint, func() -> void:
			if not GameState.is_scanned(current_data.seed):
				AudioManager.play("error")
				_show_unlock_toast("Not scanned yet", "Scan this world's surface from orbit to use its lenses.")
				return
			_set_role("" if _role == cap_role else cap_role))
		if not GameState.is_scanned(current_data.seed):
			b.modulate = Color(0.5, 0.5, 0.55, 0.6)   # locked until the surface is scanned
		b.set_meta("tint", tint)
		var tip := "Where %s thrives here:\n%s\n\nSolid: +%d%% or more  ·  dotted: +%d%% or more.\nHalf the bonus applies within %d km of a feature." % [
			String(info["label"]).to_lower(), FeatureMap.role_features_text(role),
			int(FeatureMap.ROLE_STRONG * 100.0), int(FeatureMap.ROLE_GOOD * 100.0), int(Balance.cfg.terrain_near_km)]
		b.mouse_entered.connect(func() -> void: TooltipManager.show_tip(String(info["label"]), tip))
		b.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
		_lens_buttons[role] = b
		row.add_child(b)
	cont.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_lens_bar = row
	_style_lens_bar()

## Orbital surface scan: a bright band sweeps the globe once, then the role
## lenses of this world work (GameState.scanned_bodies).
var _scan_fx: Dictionary = {}
var _scan_canvas: Control = null
const SCAN_SEC := 2.8

func _start_surface_scan(data: PlanetData) -> void:
	if data == null or GameState.is_scanned(data.seed) or not _scan_fx.is_empty():
		return
	AudioManager.play("click")
	_set_zoom_target(ZOOM_MIN, Vector2.INF)
	_scan_fx = {"t": 0.0, "seed": data.seed}
	if _scan_canvas == null or not is_instance_valid(_scan_canvas):
		_scan_canvas = Control.new()
		_scan_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scan_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_scan_canvas.z_index = 45
		_scan_canvas.draw.connect(_draw_surface_scan)
		(planet_renderer.get_parent() as Control).add_child(_scan_canvas)

func _tick_surface_scan(delta: float) -> void:
	if _scan_fx.is_empty():
		return
	_scan_fx["t"] = float(_scan_fx["t"]) + delta
	if is_instance_valid(_scan_canvas):
		_scan_canvas.queue_redraw()
	if float(_scan_fx["t"]) >= SCAN_SEC:
		var seed_val: int = _scan_fx["seed"]
		_scan_fx = {}
		GameState.scanned_bodies[seed_val] = true
		GameState.save()
		AudioManager.play("building_done")
		_show_unlock_toast("Surface scanned", "The role lenses of this world are open.")
		_rebuild_lens_bar()
		_refresh_active_panel()

func _draw_surface_scan() -> void:
	if _scan_fx.is_empty():
		return
	var cv := _scan_canvas
	var k := clampf(float(_scan_fx["t"]) / SCAN_SEC, 0.0, 1.0)
	var c := planet_renderer.global_position + planet_renderer.size * 0.5 - cv.get_global_rect().position
	var r := float(planet_renderer._planet_radius_px)
	# the band runs across the disc left → right; scanned side keeps a faint grid
	var x := lerpf(-r, r, k)
	for yy in range(int(-r), int(r), 3):
		var half := sqrt(maxf(r * r - float(yy * yy), 0.0))
		if absf(x) > half:
			continue
		cv.draw_rect(Rect2(c + Vector2(x - 2.0, float(yy)), Vector2(4, 3)), Color(0.55, 1.0, 0.85, 0.85))
		cv.draw_rect(Rect2(c + Vector2(x - 14.0, float(yy)), Vector2(12, 3)), Color(0.55, 1.0, 0.85, 0.18))
	for gx in range(int(-r), int(x), 18):
		var half2 := sqrt(maxf(r * r - float(gx * gx), 0.0))
		cv.draw_line(c + Vector2(float(gx), -half2), c + Vector2(float(gx), half2), Color(0.55, 1.0, 0.85, 0.07), 1.0)

func _style_lens_bar() -> void:
	for role: String in _lens_buttons:
		var b: Button = _lens_buttons[role]
		var st := _lens_button_style(role == _role, b.get_meta("tint", Color.WHITE))
		for state: String in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, st)

## Shows one role's overlay ("" = none).
func _set_role(role: String) -> void:
	_role = role
	_refresh_lens()

## Pushes the current role overlay to the planet shader.
func _refresh_lens() -> void:
	_style_lens_bar()
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null:
		return
	var tex: ImageTexture = null
	if current_data != null and _role != "":
		tex = FeatureMap.role_texture(current_data.seed, _role)
	mat.set_shader_parameter("lens_tex", tex)
	mat.set_shader_parameter("lens_alpha", 1.0 if tex != null else 0.0)
	mat.set_shader_parameter("wind_vis", 1.0 if _role == "energy" else 0.0)
	var wind_tex: ImageTexture = FeatureMap.wind_texture(current_data.seed) if current_data != null else null
	mat.set_shader_parameter("wind_tex", wind_tex)
	mat.set_shader_parameter("wind_on", 1.0 if wind_tex != null else 0.0)
	mat.set_shader_parameter("feature_strength", _feature_strength())

# ── Side panel slide ──────────────────────────────────────────────────────────

func _build_panel_toggle() -> void:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.z_index = 201
	btn.z_as_relative = false
	btn.tooltip_text = ""
	_apply_orbitron(btn, 12)
	var st := _make_hud_style(Color(0.07, 0.08, 0.13, 0.95), 0)
	st.corner_radius_top_right = 6
	st.corner_radius_bottom_right = 6
	st.border_color = Color(0.2, 0.25, 0.4, 0.5)
	st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.border_width_left = 0
	st.content_margin_left = 6; st.content_margin_right = 6
	var hov := st.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.12, 0.16, 0.30, 0.98)
	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_color_override("font_color",       Color(0.55, 0.70, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	btn.pressed.connect(func() -> void:
		AudioManager.play("click")
		_set_panel_open(not _panel_open))
	add_child(btn)
	_panel_toggle_btn = btn
	# If content ever widens the panel past its anchors, keep the tab on its edge
	($SidePanel as Control).resized.connect(_place_panel_toggle)
	($SidePanel as Control).item_rect_changed.connect(_place_panel_toggle)
	_apply_panel_t(_panel_t)

## Puts the open/close tab on the side panel's actual right edge.
func _place_panel_toggle() -> void:
	if _panel_toggle_btn == null:
		return
	var x := _panel_right_edge()
	_panel_toggle_btn.anchor_left   = 0.0
	_panel_toggle_btn.anchor_right  = 0.0
	_panel_toggle_btn.anchor_top    = 0.5
	_panel_toggle_btn.anchor_bottom = 0.5
	_panel_toggle_btn.offset_left   = x
	_panel_toggle_btn.offset_right  = x + 26.0
	_panel_toggle_btn.offset_top    = -28.0
	_panel_toggle_btn.offset_bottom = 28.0

## Slides the side panel in if it's hidden (used when the player selects something).
func _reveal_panel() -> void:
	if not _panel_open and not GameState.showcase_mode:
		_set_panel_open(true)

func _set_panel_open(open: bool) -> void:
	if open and GameState.showcase_mode:
		return
	_panel_open = open
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_panel_tween.tween_method(_apply_panel_t, _panel_t, 1.0 if open else 0.0, PANEL_SLIDE_SEC)

## Screen x of the side panel's right edge (0 when it's slid away).
func _panel_right_edge() -> float:
	var panel := $SidePanel as Control
	return maxf(0.0, panel.position.x + panel.size.x)

## Height of the HUD's resource bar — the side panel starts below it.
func _hud_bar_height() -> float:
	var cp = HUDManager.get("credits_panel")
	if cp != null and is_instance_valid(cp as Node) and (cp as Control).size.y > 4.0:
		return (cp as Control).size.y + 6.0
	return 58.0

## Lays out panel, planet area, toggle tab and HUD for a slide position t (1 = open).
## The panel lives on the left, under the resource bar; the globe fills the rest.
func _apply_panel_t(t: float) -> void:
	_panel_t = t
	var panel := $SidePanel as Control
	panel.anchor_left  = -PANEL_FRACTION * (1.0 - t)
	panel.anchor_right = PANEL_FRACTION * t
	panel.offset_left  = 0.0
	panel.offset_right = 0.0
	panel.offset_top   = _hud_bar_height()
	($PlanetContainer as Control).anchor_left  = PANEL_FRACTION * t
	($PlanetContainer as Control).anchor_right = 1.0
	HUDManager.set_view_area_fraction(1.0 - PANEL_FRACTION * t)
	if _panel_toggle_btn != null:
		_panel_toggle_btn.text = "‹" if _panel_open else "›"
		_place_panel_toggle()
	if _toast_container != null and is_instance_valid(_toast_container):
		_toast_container.offset_left = PANEL_FRACTION * t * get_viewport_rect().size.x + 14.0

# ── Zoom / pan ────────────────────────────────────────────────────────────────

## True when the point is over the globe area and not over a UI control on top of it.
func _is_over_planet_area(global_pos: Vector2) -> bool:
	var cont := planet_renderer.get_parent() as Control
	if cont == null or not cont.get_global_rect().has_point(global_pos):
		return false
	# Only controls that actually swallow the mouse (panels, buttons…) block it;
	# pass-through HUD layers and the planet itself don't.
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered == null or hovered == planet_renderer or hovered == cont \
		or hovered.mouse_filter != Control.MOUSE_FILTER_STOP

func _set_zoom_target(z: float, anchor: Vector2) -> void:
	_zoom_target = clampf(z, ZOOM_SYSTEM if _system_zoom_ok() else ZOOM_MIN, _zoom_max())
	_zoom_anchor = anchor

func _apply_zoom() -> void:
	var mat := planet_renderer.material as ShaderMaterial
	var cont := planet_renderer.get_parent() as Control
	if mat == null or cont == null or cont.size.y <= 0.0:
		return
	# Radius may exceed the rect once zoomed in — the shader just fills the view.
	mat.set_shader_parameter("planet_radius", _base_radius * _zoom * cont.size.y / planet_renderer.size.y)
	# rivers only show close up: hidden on the whole globe, fade in as you zoom
	mat.set_shader_parameter("river_vis", smoothstep(ZOOM_RIVER_START, ZOOM_RIVER_FULL, _zoom))
	# Orbits and rings grow with the planet; keep them out of the HUD while zoomed.
	cont.clip_contents = _zoom > ZOOM_MIN + 0.001
	_update_aspect()
	planet_renderer._update_radius()

func _tick_zoom(delta: float) -> void:
	if is_equal_approx(_zoom, _zoom_target):
		return
	var prev := _zoom
	_zoom = lerpf(_zoom, _zoom_target, 1.0 - exp(-delta * 14.0))
	if absf(_zoom - _zoom_target) < 0.002:
		_zoom = _zoom_target
	_keep_anchor_fixed(prev, _zoom)
	_apply_zoom()

## Spins/tilts the globe so the surface under the zoom anchor stays roughly under it.
func _keep_anchor_fixed(z0: float, z1: float) -> void:
	if not _zoom_anchor.is_finite() or not _screen_to_lonlat(_zoom_anchor)["hit"]:
		return
	var cont := planet_renderer.get_parent() as Control
	var d: Vector2 = _zoom_anchor - (planet_renderer.global_position + planet_renderer.size * 0.5)
	var r0: float = cont.size.y * _base_radius * z0
	var r1: float = cont.size.y * _base_radius * z1
	var k: float = 1.0 / r0 - 1.0 / r1   # angle the anchor drifts by, per px of offset
	planet_renderer.set_rotation_offset(planet_renderer.get_rotation_offset()
		+ d.x * k / maxf(cos(planet_renderer.tilt), 0.35))
	if not planet_renderer.tilt_locked:
		planet_renderer.set_tilt(planet_renderer.tilt - d.y * k)

func _planet_r_px() -> float:
	var mat := planet_renderer.material as ShaderMaterial
	if mat == null:
		return 0.0
	return planet_renderer.size.y * float(mat.get_shader_parameter("planet_radius"))

## Global screen point → surface point. Returns { hit, lon, lat } (radians).
func _screen_to_lonlat(global_pos: Vector2) -> Dictionary:
	var r := _planet_r_px()
	if r <= 0.0:
		return {"hit": false}
	var center := planet_renderer.global_position + planet_renderer.size * 0.5
	var d := (global_pos - center) / r
	if d.length_squared() > 1.0:
		return {"hit": false}
	var ll: Vector2 = planet_renderer.view_to_lonlat(Vector3(d.x, d.y, sqrt(1.0 - d.length_squared())))
	return {"hit": true, "lon": ll.x, "lat": ll.y}

# ── Manual district placement ─────────────────────────────────────────────────

## `parent` = the City a district is built under; null when founding a City.
## The side panel slides away while placing (more map to aim at) and comes
## back afterwards if it was open.
var _reopen_panel_after_place := false

func _begin_district_placement(def: DistrictDef, parent: POIData = null) -> void:
	_end_district_placement()
	# the first City on a world with a lander in orbit is always a landing
	if def.is_system_anchor() and current_data != null and _city_count(current_data) == 0 \
			and GameState.get_planet(current_data.seed).lander_state == 1:
		_lunar_landing = true
	if _panel_open:
		_reopen_panel_after_place = true
		_set_panel_open(false)
	_placing_def = def
	_placing_parent = parent
	poi_layer.placement_mode = true
	poi_layer.spacing_deg = TerrainSampler.min_spacing_deg(current_data)
	poi_layer.placement_rings = _placement_rings(def, parent)
	poi_layer.deselect_all()
	CursorManager.set_state(CursorManager.State.NORMAL)
	_show_place_hint(def)

func _end_district_placement() -> void:
	if _reopen_panel_after_place:
		_reopen_panel_after_place = false
		_set_panel_open(true)
	_ghost_road_key = ""
	if poi_layer:
		poi_layer.ghost_roads = []
	_placing_def = null
	_placing_parent = null
	_moving_poi = null
	if poi_layer:
		poi_layer.placement_mode = false
		poi_layer.clear_ghost()
	if _place_hint != null and is_instance_valid(_place_hint):
		_place_hint.queue_free()
	_place_hint = null

func _show_place_hint(def: DistrictDef) -> void:
	var cont := planet_renderer.get_parent() as Control
	var hint := PanelContainer.new()
	hint.add_theme_stylebox_override("panel", _make_hud_style(Color(0.06, 0.08, 0.16, 0.92), 6))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.z_index = 50
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(vbox)
	var title := Label.new()
	title.text = "PLACE  %s  %s   ·   ◈ %s" % [def.icon, def.display_name.to_upper(),
		HUDManager.fmt_credits(DistrictDef.placement_cost(def, current_data, _parent_label()))]
	var found_pop := Economy.founding_pop(def, current_data, _parent_label())
	if found_pop > 0:
		title.text += "   ·   ☺ %s pop" % Economy.fmt(found_pop)
	_apply_orbitron(title, 10)
	title.add_theme_color_override("font_color", Color(0.90, 0.82, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	var help := Label.new()
	help.text = "Click a site on %s  ·  Drag to rotate  ·  Scroll to zoom  ·  Right-click to cancel" \
		% TerrainSampler.placement_label(def.placement)
	if _lunar_landing:
		title.text = "CHOOSE THE LANDING SITE"
	if _mandatory_city:
		title.text = "CHOOSE THE SITE OF YOUR CAPITAL"
		help.text = "Click a site on %s  ·  Drag to rotate  ·  Scroll to zoom" \
			% TerrainSampler.placement_label(def.placement)
	_apply_orbitron(help, 7)
	help.add_theme_color_override("font_color", Color(0.55, 0.62, 0.80))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(help)
	cont.add_child(hint)
	# Sits below the top HUD bar now that the globe extends behind it.
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 88)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_place_hint = hint

## Faint preview of the roads a district placed here would get: to every
## would-be neighbour and to the nearest settlement of its City. Routed without
## committing them, recomputed only when the cursor moves to a new cell.
var _ghost_road_key := ""
func _update_ghost_roads(lon: float, lat: float, neighbors: Array) -> void:
	var key := "%d,%d" % [roundi(rad_to_deg(lon) * 2.0), roundi(rad_to_deg(lat) * 2.0)]
	if key == _ghost_road_key:
		return
	_ghost_road_key = key
	var out: Array = []
	var net := RoadNetwork.for_planet(current_data)
	if net.is_ready():
		var targets := {}
		for i in neighbors:
			targets[int(i)] = true
		if _placing_parent != null:
			var best := -1
			var best_d := INF
			var n := _lonlat_to_world(lon, lat)
			for i in _city_group(_placing_parent.label):
				var d := acos(clampf(n.dot(_territories[i]["n"]), -1.0, 1.0))
				if d < best_d:
					best_d = d
					best = i
			if best >= 0:
				targets[best] = true
		for i in targets:
			if i >= _territories.size():
				continue
			var pd: POIData = _territories[i]["poi"]
			var r := net.route(lon, lat, deg_to_rad(pd.lon_deg), deg_to_rad(pd.lat_deg),
				false, _is_sea_site(pd), false)
			if not r.is_empty():
				out.append(r)
	poi_layer.ghost_roads = out

func _update_placement_hover() -> void:
	if _placing_def == null or current_data == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var hit := _screen_to_lonlat(mouse)
	if not hit["hit"] or not _is_over_planet_area(mouse):
		poi_layer.clear_ghost()
		return
	var chk := TerrainSampler.check_site(current_data, _placing_def, hit["lon"], hit["lat"])
	if _moving_poi != null:   # the moved settlement and its districts must all fit
		var mb := Settlement.move_site_block(current_data, _moving_poi, Vector2(hit["lon"], hit["lat"]))
		chk["ok"] = mb == ""
		chk["reason"] = mb
	var t: Dictionary = chk["terrain"]
	var site_name := TerrainSampler.label(t["terrain"], current_data.planet_type)
	if t["coastal"] and t["terrain"] != TerrainSampler.Terrain.COAST:
		site_name += "  ·  Coastal"
	var sys := _placement_system_check(_placing_def, hit["lon"], hit["lat"])
	var lines := _placement_detail_lines(_placing_def, chk, sys)
	lines.append_array(_site_resource_lines(_placing_def,
		ResourceMap.sample(current_data.seed, hit["lon"], hit["lat"]), t["coastal"], int(t["terrain"]),
		hit["lon"], hit["lat"]))
	_update_ghost_roads(hit["lon"], hit["lat"], sys["neighbors"])
	poi_layer.set_ghost(hit["lon"], hit["lat"], chk["ok"] and sys["ok"], site_name, lines,
		_placing_def.type_key(), sys["neighbors"])

func _find_poi(data: PlanetData, poi_label: String) -> POIData:
	if poi_label == "":
		return null
	for pd: POIData in data.custom_pois:
		if pd.label == poi_label:
			return pd
	return null

func _parent_label() -> String:
	return _placing_parent.label if _placing_parent != null else ""

## Territory index of the City a territory belongs to (itself for a City), or -1.
func _city_index_of(i: int) -> int:
	var pd: POIData = _territories[i]["poi"]
	if pd.is_city():
		return i
	for j in _territories.size():
		if (_territories[j]["poi"] as POIData).label == pd.parent_city:
			return j
	return -1

## Territory indices of a City and every district built under it.
func _city_group(city_label: String) -> Array[int]:
	var out: Array[int] = []
	for i in _territories.size():
		var pd: POIData = _territories[i]["poi"]
		if pd.label == city_label or pd.parent_city == city_label:
			out.append(i)
	return out

## Rules beyond terrain for a new district at (lon, lat). Cities may be founded
## anywhere outside other cities' territory (TerrainSampler.check_site); any
## other district must neighbour its City or one of that City's districts.
## Returns { ok, reason, neighbors: Array[int] (territory indices), anchor: String }.
## Surface cities on a planet.
static func _city_count(data: PlanetData) -> int:
	var n := 0
	for p: POIData in data.custom_pois:
		if p.is_city() and not p.is_orbital():
			n += 1
	return n

## How far beyond its settlements a City's districts may be placed: grows by
## CITY_REACH_PER_LV_DEG for every level the City has.
const CITY_REACH_PER_LV_DEG: float = 3.0
func _city_reach_rad(city_label: String) -> float:
	var lv := 1
	if current_data != null:
		var pp := GameState.get_planet(current_data.seed)
		if pp != null:
			lv = pp.district_levels.get(city_label, 1)
	return deg_to_rad((SETTLE_BASE_DEG + TerrainSampler.NEIGHBOR_GAP_DEG * 1.3
		+ CITY_REACH_PER_LV_DEG * float(lv - 1)) * TerrainSampler.body_scale(current_data))

func _placement_system_check(def: DistrictDef, lon: float, lat: float) -> Dictionary:
	var n := _lonlat_to_world(lon, lat)
	var reach := deg_to_rad((SETTLE_BASE_DEG + TerrainSampler.NEIGHBOR_GAP_DEG)
		* TerrainSampler.body_scale(current_data))   # neighbour test
	var neighbors: Array[int] = []
	for i in _territories.size():
		var t: Dictionary = _territories[i]
		if acos(clampf(n.dot(t["n"]), -1.0, 1.0)) <= reach + float(t["r"]):
			neighbors.append(i)
	if def.is_system_anchor() or _placing_parent == null:
		return {"ok": true, "reason": "", "neighbors": neighbors, "anchor": ""}
	var group := _city_group(_placing_parent.label)
	# within the City's reach (grows with the City's level) of any of its settlements
	var city_reach := _city_reach_rad(_placing_parent.label)
	var ok := false
	for i in group:
		var tg: Dictionary = _territories[i]
		if acos(clampf(n.dot(tg["n"]), -1.0, 1.0)) <= city_reach + float(tg["r"]):
			ok = true
			break
	reach = city_reach
	var reason := ""
	if not ok:
		# how far outside the City's reach this spot is
		var best := INF
		for j in group:
			var t: Dictionary = _territories[j]
			best = minf(best, acos(clampf(n.dot(t["n"]), -1.0, 1.0)) - reach - float(t["r"]))
		reason = "%s is %s beyond reach" % [_placing_parent.shown_name(), _surface_km(best)] \
			if best < INF else "Must be built near %s" % _placing_parent.shown_name()
	return {"ok": ok, "reason": reason, "neighbors": neighbors, "anchor": _placing_parent.shown_name()}

## Dotted rings shown while placing: a City's no-found zone when founding a City,
## otherwise the reach of the parent City's group. [{lon, lat, r, color}]
func _placement_rings(def: DistrictDef, parent: POIData) -> Array:
	var rings: Array = []
	if current_data == null:
		return rings
	if def.is_system_anchor():
		var city_r := deg_to_rad(TerrainSampler.city_spacing_deg(current_data))
		for pd: POIData in current_data.custom_pois:
			if pd.is_city() and not pd.is_orbital():
				rings.append({"lon": deg_to_rad(pd.lon_deg), "lat": deg_to_rad(pd.lat_deg),
					"r": city_r, "color": Color(1.0, 0.65, 0.30, 0.45)})
	elif parent != null:
		var reach := _city_reach_rad(parent.label)
		for i in _city_group(parent.label):
			var pd: POIData = _territories[i]["poi"]
			rings.append({"lon": deg_to_rad(pd.lon_deg), "lat": deg_to_rad(pd.lat_deg),
				"r": reach + float(_territories[i]["r"]), "color": Color(0.45, 0.85, 1.0, 0.40)})
	return rings

## Angular distance → readable surface distance (same km as the economy, Location.radius_km).
func _surface_km(angle_rad: float) -> String:
	var r := Location.radius_km(current_data) if current_data != null else Balance.cfg.planet_radius_km
	return _km_text(angle_rad * r)

static func _km_text(km: float) -> String:
	return "%d km" % int(round(km)) if km < 10000.0 else "%.1fk km" % (km / 1000.0)

## Detail lines for the placement preview: outcome, system, neighbours, bonuses.
## Each entry is [text, Color].
func _placement_detail_lines(def: DistrictDef, chk: Dictionary, sys: Dictionary) -> Array:
	var good := Color(0.45, 1.0, 0.55)
	var bad  := Color(1.0, 0.45, 0.40)
	var info := Color(0.65, 0.82, 1.0)
	var lines: Array = []
	if not chk["ok"]:
		lines.append([chk["reason"], bad])
	elif not sys["ok"]:
		lines.append([sys["reason"], bad])
	else:
		lines.append(["Click to place", good])
	if def.is_system_anchor():
		lines.append(["Founds a new city", info])
	elif sys["anchor"] != "":
		lines.append(["District of %s" % sys["anchor"], info])
	return lines

## Feature lines for a site ({ feature_id: share }): one per feature, with what
## it boosts, e.g. ["On Mountain: +20% Production, +30% Science", colour].
func _feature_lines(site: Dictionary) -> Array:
	var out: Array = []
	var table: Dictionary = Balance.cfg.terrain_bonuses
	for fid: String in FeatureMap.IDS:
		if not site.has(fid):
			continue
		var share := float(site[fid])
		var parts: Array[String] = []
		var row: Dictionary = table.get(fid, {})
		for fam: String in row:
			parts.append("+%s%% %s" % [_pct(float(row[fam]) * share), _family_label(fam)])
		var where := "On" if share >= 1.0 else "Near"
		out.append(["%s %s: %s" % [where, FeatureMap.feature_name(fid), ", ".join(parts)],
			Color(0.95, 0.85, 0.55) if share >= 1.0 else Color(0.80, 0.74, 0.55)])
	return out

static func _family_label(fam: String) -> String:
	match fam:
		"energy_solar":      return "Solar"
		"energy_wind":       return "Wind"
		"energy_tidal":      return "Tidal"
		"energy_geothermal": return "Geothermal"
	return fam.capitalize()

## "+25% cr · +10% sci" — the terrain bonus a district's base outputs get here.
func _terrain_bonus_text(poi: POIData, outputs: Dictionary) -> String:
	var parts: Array[String] = []
	for id: String in outputs:
		var b := FeatureMap.terrain_mult(current_data, poi, id) - 1.0
		if b > 0.004:
			parts.append("+%s%% %s" % [_pct(b), Economy.INFO.get(id, {}).get("short", id)])
	return " · ".join(parts)

## Location bonus as text lines (Location.breakdown): the total, then each part;
## `detailed` also names every contributing district.
func _location_lines(loc: Dictionary, detailed: bool = false) -> Array[String]:
	var out: Array[String] = []
	var total: float = float(loc["mult"]) - 1.0
	out.append("Location  +%d%%" % int(round(total * 100.0)))
	var nearest: float = float(loc["nearest_km"])
	if nearest == INF:
		out.append("  +%d%%  distance — no other district on this world" % int(round(float(loc["distance"]) * 100.0)))
	else:
		out.append("  +%s%%  distance — nearest %s (%s)" % [_pct(float(loc["distance"])),
			_km_text(nearest), Location.band_label(loc["band"])])
	if float(loc["proximity"]) > 0.0:
		out.append("  +%s%%  same-type (and linked) districts nearby" % _pct(float(loc["proximity"])) \
			if SkillTree.is_unlocked("cross_networks") else "  +%s%%  same-type districts nearby" % _pct(float(loc["proximity"])))
	if float(loc["centre"]) > 0.0:
		out.append("  +%s%%  City centres in reach" % _pct(float(loc["centre"])))
	if detailed:
		for src: Dictionary in loc["sources"]:
			out.append("      +%s%%  %s  · %s%s" % [_pct(float(src["share"])), (src["poi"] as POIData).shown_name(),
				_km_text(float(src["km"])), "  (linked)" if src["kind"] == "cross" else ""])
	return out

static func _pct(v: float) -> String:
	var p := v * 100.0
	return "%d" % int(round(p)) if is_equal_approx(p, round(p)) else "%.1f" % p

## Resource lines for the placement preview: tag values at the site and which
## site-dependent buildings this district type could build there.
func _site_resource_lines(def: DistrictDef, tags: Dictionary, coastal: bool, terrain: int = -1,
		lon: float = 0.0, lat: float = 0.0) -> Array:
	var lines: Array = []
	if tags.is_empty():
		return lines
	var dim := Color(0.70, 0.74, 0.86)
	lines.append([_tags_text(tags, coastal), Color(0.95, 0.85, 0.55)])
	var mins := _minerals_text(tags)
	if mins != "":
		lines.append([mins, dim])
	# which site-dependent buildings this spot enables / lacks
	var probe := POIData.new()
	probe.coastal = coastal
	probe.resource_tags = tags
	probe.terrain = terrain
	probe.type_tag = def.type_key()
	probe.poi_type = def.to_poi_type()
	probe.lon_deg = rad_to_deg(lon)
	probe.lat_deg = rad_to_deg(lat)
	probe.site_features = FeatureMap.shares(current_data, lon, lat)
	if not def.is_system_anchor() and _placing_parent != null:   # the City's features carry over
		probe.parent_city = _placing_parent.label
	for ln: Array in _feature_lines(probe.site_features):
		lines.append(ln)
	if not def.base_outputs.is_empty() and current_data != null:
		var ppv := GameState.get_planet(current_data.seed)
		var tb := _terrain_bonus_text(probe, def.base_outputs)
		lines.append(["Base: %s%s" % [_district_base_text(ppv, probe), "   terrain %s" % tb if tb != "" else ""],
			Color(0.55, 0.95, 0.60)])
		var loc := Location.breakdown(current_data, probe)
		for ln: String in _location_lines(loc):
			lines.append([ln, Color(0.65, 0.85, 1.0) if float(loc["mult"]) > 1.005 else Color(0.60, 0.64, 0.75)])
	var enabled: Array[String] = []
	var missing: Array[String] = []
	for b: BuildingDef in BuildingDef.for_poi_and_planet(def.to_poi_type(), current_data.planet_type):
		if b.required_tag == "" and not b.requires_coastal and b.required_terrain.is_empty():
			continue
		if b.site_block_reason(probe) == "":
			enabled.append(b.display_name)
		else:
			missing.append(b.display_name)
	if not enabled.is_empty():
		lines.append(["Enables: " + ", ".join(enabled), Color(0.45, 1.0, 0.55)])
	if not missing.is_empty():
		lines.append(["Not here: " + ", ".join(missing), Color(0.60, 0.62, 0.72)])
	return lines

## "Coastal · Geo 62% · Solar 80% · Wind 30% · Tidal 0%"
func _tags_text(tags: Dictionary, coastal: bool) -> String:
	var parts: Array[String] = []
	if coastal:
		parts.append("Coastal")
	for key: String in ResourceMap.ENERGY_KEYS:
		parts.append("%s %d%%" % [BuildingDef.tag_label(key).left(5), int(round(float(tags.get(key, 0.0)) * 100.0))])
	return "  ·  ".join(parts)

## "Ferrite 70% · Cobalt 20%" (strongest first, top 3)
func _minerals_text(tags: Dictionary) -> String:
	var mins: Dictionary = tags.get("minerals", {})
	if mins.is_empty() or current_data == null:
		return ""
	var names := {}
	for mi: Dictionary in ResourceMap.mineral_info(current_data.seed):
		names[mi["id"]] = mi["name"]
	var ids: Array = mins.keys()
	ids.sort_custom(func(a, b) -> bool: return float(mins[a]) > float(mins[b]))
	var parts: Array[String] = []
	for rid in ids.slice(0, 3):
		parts.append("%s %d%%" % [names.get(rid, rid), int(round(float(mins[rid]) * 100.0))])
	return "  ·  ".join(parts)

func _try_place_district(global_pos: Vector2) -> void:
	var hit := _screen_to_lonlat(global_pos)
	if not hit["hit"] or current_data == null:
		return
	var def := _placing_def
	if _moving_poi != null:
		_try_move_here(Vector2(hit["lon"], hit["lat"]))
		return
	var chk := TerrainSampler.check_site(current_data, def, hit["lon"], hit["lat"])
	if not chk["ok"] or not _placement_system_check(def, hit["lon"], hit["lat"])["ok"]:
		AudioManager.play("error")
		return
	var parent_label := _parent_label()
	var cost := DistrictDef.placement_cost(def, current_data, parent_label)
	var full := DistrictDef.placement_full_cost(def, current_data, parent_label)
	if not Economy.can_pay(full):
		AudioManager.play("error")
		_show_unlock_toast("Can't build here yet", Economy.cost_block(full))
		return
	var site := Vector2(hit["lon"], hit["lat"])
	if def.is_system_anchor():
		# Founding a City: name it first (the site stays highlighted meanwhile)
		_prompt_city_name(def, site, cost)
		return
	Economy.pay(full)
	_end_district_placement()
	_spawn_district(current_data, def.suggest_name(current_data, parent_label), def, site, parent_label)

## Modal "Name your city" box; founding happens on confirm.
func _prompt_city_name(def: DistrictDef, site: Vector2, cost: float) -> void:
	if _naming_open:
		return
	_naming_open = true
	var layer := CanvasLayer.new()
	layer.layer = 210
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _make_hud_style(Color(0.06, 0.08, 0.16, 0.97), 8))
	box.custom_minimum_size = Vector2(360, 0)
	layer.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	var title := Label.new()
	title.text = "NAME YOUR CAPITAL" if _mandatory_city else ("NAME YOUR FIRST %s CITY" % current_data.planet_name.to_upper() if _lunar_landing else "NAME YOUR CITY")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(title, 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	v.add_child(title)
	var edit := LineEdit.new()
	edit.text = def.suggest_name(current_data)
	edit.max_length = 28
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(edit, 11)
	v.add_child(edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var ok_btn := Button.new()
	ok_btn.text = ("LAND HERE" if _lunar_landing else "FOUND CITY") + ("" if cost <= 0.0 else "  ·  ◈ %s" % HUDManager.fmt_credits(cost))
	_apply_orbitron(ok_btn, 10)
	row.add_child(ok_btn)
	var cancel_btn: Button = null
	if not _mandatory_city:
		cancel_btn = Button.new()
		cancel_btn.text = "CANCEL"
		_apply_orbitron(cancel_btn, 10)
		row.add_child(cancel_btn)
	var close := func() -> void:
		_naming_open = false
		if is_instance_valid(layer):
			layer.queue_free()
	var confirm := func() -> void:
		var nm := edit.text.strip_edges()
		if nm.is_empty():
			nm = def.suggest_name(current_data)
		if current_data == null or not GameState.spend_credits(cost):
			AudioManager.play("error")
			close.call()
			return
		close.call()
		_mandatory_city = false
		var landing := _lunar_landing
		_end_district_placement()
		if landing:
			_land_lander(nm, def, site)
			return
		AudioManager.play("construct")
		_spawn_district(current_data, nm, def, site, "")
	ok_btn.pressed.connect(confirm)
	edit.text_submitted.connect(func(_t: String) -> void: confirm.call())
	if cancel_btn != null:
		cancel_btn.pressed.connect(func() -> void:
			AudioManager.play("click")
			close.call())
	await get_tree().process_frame
	if not is_instance_valid(box):
		return
	box.position = (get_viewport().get_visible_rect().size - box.size) * 0.5
	edit.grab_focus()
	edit.select_all()

func _on_planet_clicked(_screen_pos: Vector2) -> void:
	if _naming_open or GameState.showcase_mode:
		return
	if _placing_def != null:
		_try_place_district(_screen_pos)
		return
	var owned := _territory_at_screen(_screen_pos)
	if owned >= 0:
		AudioManager.play("poi_select")
		poi_layer.select_poi(owned)
		_on_district_clicked(owned, {})
		return
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.deselect()
	if current_data != null:
		_go_up_one_level()

	var hit := _screen_to_lonlat(_screen_pos)
	if hit["hit"]:
		var lat_d := rad_to_deg(float(hit["lat"]))
		var lon_d := rad_to_deg(float(hit["lon"]))

		if DevConsole.show_planet_coords:
			var text := "%.1f : %.1f" % [lon_d, lat_d]
			poi_layer.spawn_floating_text(lon_d, lat_d, text, Color(0.4, 1.0, 0.4), 7)

		# Terrain sound + particle burst based on planet type
		if current_data != null:
			_spawn_terrain_hit(_screen_pos, current_data.planet_type)

	poi_layer.deselect_all()
	_build_planet_overview(current_data)

func _show_colonize_popup(data: PlanetData, pp: PlanetProgress) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 250
	
	var popup := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.09, 0.18, 0.97)
	ps.border_color = Color(0.25, 0.45, 0.80, 0.55)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(6)
	ps.content_margin_left = 20; ps.content_margin_right = 20
	ps.content_margin_top = 20; ps.content_margin_bottom = 20
	popup.add_theme_stylebox_override("panel", ps)
	
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	popup.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	
	var title := Label.new()
	title.text = "Establish Outpost" if data.planet_type == PlanetData.Type.MOON else "Colonize Planet"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(title, 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(title)
	
	var desc := Label.new()
	desc.text = "Cost: %s Credits\nTime: 30 Seconds" % HUDManager.fmt_credits(1000.0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(desc, 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc)
	
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	
	var confirm := Button.new()
	confirm.text = "CONFIRM"
	_apply_orbitron(confirm, 12)
	confirm.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	confirm.pressed.connect(func():
		overlay.queue_free()
		if GameState.colonize_planet(data.seed):
			_build_planet_overview(data)
	)
	if GameState.credits < 1000.0:
		confirm.disabled = true
	
	var cancel := Button.new()
	cancel.text = "CANCEL"
	_apply_orbitron(cancel, 12)
	cancel.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	cancel.pressed.connect(func(): overlay.queue_free())
	
	btn_row.add_child(confirm)
	btn_row.add_child(cancel)
	vbox.add_child(btn_row)
	
	popup.add_child(vbox)
	overlay.add_child(popup)
	get_viewport().add_child(overlay)

## Keeps a cost-gated button's enabled state current: re-checks `can_use`
## a few times a second, so it lights up as soon as the resources are there
## (no reopening the panel).
func _live_enable(btn: BaseButton, can_use: Callable) -> void:
	btn.disabled = not bool(can_use.call())
	var t := Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.timeout.connect(func() -> void:
		var ok := bool(can_use.call())
		if btn.disabled == ok:
			btn.disabled = not ok)
	btn.add_child(t)

## How much of a level-up cost key the player has: credits, a resource id, or
## "ANY_T<n>" (all raw minerals of that tier together).
func _level_cost_have(k: String) -> float:
	if k == "credits":
		return GameState.credits
	if k.begins_with("ANY_T"):
		var tier := k.trim_prefix("ANY_T").to_int()
		var total := 0.0
		for rid: String in GameState.global_resources:
			var rd: ResourceData = GameState.known_resources.get(rid) as ResourceData
			if rd != null and rd.tag == ResourceData.Tag.RAW_MINERAL and rd.tier == tier:
				total += GameState.global_resources[rid]
		return total
	return GameState.global_resources.get(k, 0.0)

## What levelling the planet gives and needs (the button's tooltip).
func _planet_level_tip(data: PlanetData, pp: PlanetProgress) -> String:
	var next := pp.level + 1
	var have := Leveling.planet_city_levels(data, pp)
	var need := Leveling.planet_level_req(next)
	var cities_now := Leveling.max_cities(pp)
	var lines: Array[String] = ["Raise %s to Lv %d:" % [data.planet_name, next],
		_bb("+1 City slot (%d → %d)" % [cities_now, cities_now + 1], Economy.color_of(Economy.POPULATION)),
		"",
		"Needs %d total City levels on this planet — you have %d." % [need, have],
		_bb("City levels come from levelling up each City (the Orbit counts too).", BB_DIM)]
	var cost := pp.get_upgrade_cost()
	if cost.has("credits"):
		lines.append("")
		lines.append("Cost  " + _res_bb(Economy.CREDITS, float(cost["credits"]), ""))
	var block := Leveling.planet_level_block(data, pp)
	if block != "":
		lines.append("")
		lines.append(_bb("➡ " + block, BB_BAD))
	elif cost.has("credits") and GameState.credits < float(cost["credits"]):
		lines.append("")
		lines.append(_bb("➡ Not enough credits", BB_BAD))
	return "\n".join(lines)

func _show_level_up_popup(pp: PlanetProgress) -> void:
	if pp.is_upgrading:
		return
		
	# Full-screen dim overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 250
	
	var popup := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.09, 0.18, 0.97)
	ps.border_color = Color(0.25, 0.45, 0.80, 0.55)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(6)
	ps.content_margin_left = 20; ps.content_margin_right = 20
	ps.content_margin_top = 20; ps.content_margin_bottom = 20
	popup.add_theme_stylebox_override("panel", ps)
	
	# Center popup inside overlay
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	popup.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	
	var req_title := Label.new()
	req_title.text = "Level Up to %d" % (pp.level + 1)
	req_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(req_title, 14)
	req_title.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	vbox.add_child(req_title)
	
	var cost := pp.get_upgrade_cost()
	var can_afford := true
	
	if cost.has("credits"):
		var has_amt: float = GameState.credits
		var cost_amt: float = cost["credits"]
		
		var cred_box := HBoxContainer.new()
		cred_box.alignment = BoxContainer.ALIGNMENT_CENTER
		cred_box.add_theme_constant_override("separation", 12)
		
		var c_lbl := Label.new()
		c_lbl.text = "Credits:"
		_apply_orbitron(c_lbl, 10)
		c_lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.25))
		
		var v_lbl := Label.new()
		v_lbl.text = "%d / %d" % [has_amt, cost_amt]
		_apply_orbitron(v_lbl, 10)
		
		if has_amt >= cost_amt:
			v_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			v_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
			can_afford = false
			
		cred_box.add_child(c_lbl)
		cred_box.add_child(v_lbl)
		vbox.add_child(cred_box)
		
	var res_flow := HFlowContainer.new()
	res_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	res_flow.add_theme_constant_override("h_separation", 8)
	res_flow.add_theme_constant_override("v_separation", 8)
	
	for k in cost.keys():
		var k_str: String = str(k)
		if k_str == "credits":
			continue
			
		var cost_amt: float = cost[k]
		var has_amt: float = 0.0
		var display_rd: ResourceData = null
		
		if k_str.begins_with("ANY_T"):
			var tier := k_str.trim_prefix("ANY_T").to_int()
			for rid: String in GameState.global_resources:
				var rd: ResourceData = GameState.known_resources.get(rid) as ResourceData
				if rd != null and rd.tag == ResourceData.Tag.RAW_MINERAL and rd.tier == tier:
					has_amt += GameState.global_resources[rid]

			display_rd = ResourceData.new()
			display_rd.tier = tier
			display_rd.rarity = 1
			display_rd.display_color = Color(0.65, 0.65, 0.70)
			display_rd.unique_name = "Any T%d Mineral" % tier
		else:
			has_amt = GameState.global_resources.get(k_str, 0.0)
			display_rd = GameState.known_resources.get(k_str) as ResourceData
		
		if has_amt < cost_amt:
			can_afford = false
			
		if display_rd != null:
			var card := _mineral_grid_card(display_rd, has_amt, true, "", pp)
			
			var card_vbox = card.get_child(0)
			var lbl = card_vbox.get_child(1) as Label
			lbl.text = "%d/%d" % [has_amt, cost_amt]
			if has_amt >= cost_amt:
				lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			else:
				lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
				
			res_flow.add_child(card)
			
	if res_flow.get_child_count() > 0:
		vbox.add_child(res_flow)
	
	# Planet level follows the cities: needs enough total city levels
	var pd_lv: PlanetData = GameState.get_planet_data(pp.planet_seed)
	var lv_block := Leveling.planet_level_block(pd_lv, pp) if pd_lv != null else ""
	var req_lbl := Label.new()
	req_lbl.text = "Requires %d total city levels  (have %d)" % [
		Leveling.planet_level_req(pp.level + 1), Leveling.planet_city_levels(pd_lv, pp) if pd_lv != null else 0]
	req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(req_lbl, 9)
	req_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4) if lv_block != "" else Color(0.4, 0.9, 0.4))
	vbox.add_child(req_lbl)
	if lv_block != "":
		can_afford = false

	var rew_lbl := Label.new()
	rew_lbl.text = "Upon Level Up:\n+1 City allowed (%d → %d)" % [Leveling.max_cities(pp), Leveling.max_cities(pp) + 1]
	rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(rew_lbl, 9)
	rew_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	vbox.add_child(rew_lbl)
	
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 24)
	
	var cancel := Button.new()
	cancel.text = "CANCEL"
	_apply_orbitron(cancel, 10)
	var cancel_sb := StyleBoxFlat.new()
	cancel_sb.bg_color = Color(0.15, 0.15, 0.2)
	cancel_sb.set_corner_radius_all(4)
	cancel_sb.content_margin_top = 6; cancel_sb.content_margin_bottom = 6
	cancel_sb.content_margin_left = 12; cancel_sb.content_margin_right = 12
	cancel.add_theme_stylebox_override("normal", cancel_sb)
	cancel.pressed.connect(func(): overlay.queue_free())
	btns.add_child(cancel)
	
	var up_btn := Button.new()
	up_btn.text = "CONFIRM"
	_apply_orbitron(up_btn, 10)
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.2, 0.45, 0.7) if can_afford else Color(0.2, 0.25, 0.35)
	btn_sb.set_corner_radius_all(4)
	btn_sb.content_margin_top = 6; btn_sb.content_margin_bottom = 6
	btn_sb.content_margin_left = 12; btn_sb.content_margin_right = 12
	up_btn.add_theme_stylebox_override("normal", btn_sb)
	up_btn.add_theme_color_override("font_color", Color.WHITE if can_afford else Color(0.5, 0.55, 0.6))
	var lv_ok := lv_block == ""
	_live_enable(up_btn, func() -> bool:
		if not lv_ok:
			return false
		for k in cost.keys():
			if _level_cost_have(str(k)) < float(cost[k]):
				return false
		return true)
	up_btn.pressed.connect(func():
		for k in cost.keys():
			var k_str: String = str(k)
			if k_str == "credits":
				GameState.spend_credits(cost[k])
			elif k_str.begins_with("ANY_T"):
				var tier := k_str.trim_prefix("ANY_T").to_int()
				var remain: float = cost[k]
				var available: Array[ResourceData] = []
				for rid: String in GameState.global_resources:
					var rd: ResourceData = GameState.known_resources.get(rid) as ResourceData
					if rd != null and rd.tag == ResourceData.Tag.RAW_MINERAL and rd.tier == tier and GameState.global_resources[rid] > 0:
						available.append(rd)
				available.sort_custom(func(a: ResourceData, b: ResourceData) -> bool: return a.rarity < b.rarity)
				for rd: ResourceData in available:
					var rid := rd.resource_id()
					var take: float = minf(remain, GameState.global_resources.get(rid, 0.0))
					GameState.global_resources[rid] = GameState.global_resources.get(rid, 0.0) - take
					remain -= take
					if remain <= 0.01:
						break
				GameState.global_resources_changed.emit()
			else:
				GameState.consume_resource(k_str, cost[k])
		AudioManager.play("level_up")
		pp.is_upgrading = true
		pp.upgrade_progress = 0.0
		pp.upgrade_duration = 5.0 * pp.level  # Lv2=5s, Lv3=10s, etc.
		if current_data != null:
			_build_planet_overview(current_data)
		overlay.queue_free()
	)
	btns.add_child(up_btn)
	
	vbox.add_child(btns)
	
	# Close on dim click
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			overlay.queue_free()
	)
	# But stop clicks from falling through the popup to the dim background
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	
	popup.add_child(vbox)
	
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(popup)
	overlay.add_child(c)
	
	get_viewport().add_child(overlay)

## Small rounded chip for the planet overview (size, atmosphere, modifiers, deposits).
func _info_chip(text: String, col: Color, tip_title: String, tip_body: String,
		icon: Texture2D = null) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(col.r, col.g, col.b, 0.08)
	st.border_color = Color(col.r, col.g, col.b, 0.55)
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.content_margin_left = 6; st.content_margin_right = 6
	st.content_margin_top = 2;  st.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", st)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon != null:
		var ic := TextureRect.new()
		ic.texture = icon
		ic.custom_minimum_size = Vector2(10, 10)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
	var l := Label.new()
	l.text = text
	_apply_orbitron(l, 7)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	pc.add_child(row)
	pc.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip(tip_title, tip_body))
	pc.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return pc

func _make_overview_tab_btn(label: String, is_active: bool) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.toggle_mode    = true
	btn.button_pressed = is_active
	btn.focus_mode     = Control.FOCUS_NONE
	_apply_orbitron(btn, 8)
	var s_on := StyleBoxFlat.new()
	s_on.bg_color            = Color(0.12, 0.18, 0.35, 0.95)
	s_on.border_color        = Color(1.0, 0.92, 0.30, 0.55)
	s_on.border_width_bottom = 2
	s_on.content_margin_top  = 5; s_on.content_margin_bottom = 5
	var s_off := StyleBoxFlat.new()
	s_off.bg_color            = Color(0.06, 0.08, 0.14, 0.0)
	s_off.border_color        = Color(0.3, 0.35, 0.55, 0.25)
	s_off.border_width_bottom = 1
	s_off.content_margin_top  = 5; s_off.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal",          s_off)
	btn.add_theme_stylebox_override("hover",           s_off)
	btn.add_theme_stylebox_override("pressed",         s_on)
	btn.add_theme_stylebox_override("hover_pressed",   s_on)
	btn.add_theme_color_override("font_color",         Color(0.45, 0.52, 0.75))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.30))
	btn.add_theme_color_override("font_hover_color",   Color(0.75, 0.82, 1.0))
	return btn

func _on_colonize_progress_changed(planet_seed: int, key: String, progress: float, pbar: Variant, bind_seed: int) -> void:
	if planet_seed == bind_seed and key == "colonize":
		if is_instance_valid(pbar):
			(pbar as ProgressBar).value = progress * 100.0

func _build_planet_overview(data: PlanetData) -> void:
	_orbit_panel_open = false
	if data == null:
		return
	# The planet view opens once a City reaches Lv 2; until then show the City.
	if not GameState.planet_view_unlocked:
		for p: POIData in data.custom_pois:
			if p.is_city() and not p.is_orbital():
				_build_city_panel(p, data)
				return
	_city_panel_poi = null
	_nav_visit(data, {}, "")
	var panel_content := $SidePanel/PanelContent
	var old := panel_content.get_node_or_null("DistrictBuildPanel")
	if old:
		# Save active scroll position before destroying
		for child in old.get_children():
			if child is ScrollContainer:
				if (child as ScrollContainer).visible:
					_panel_scroll_pos = (child as ScrollContainer).scroll_vertical
					break
		old.name = "__freeing_district__"   # free name slot before queue_free
		old.queue_free()
		_bar_meta.clear()
		_active_slot_dropdown = null
	poi_layer.deselect_all()
	_active_district_poi = null   # overview shown — don’t auto-reopen on construction
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.set_selected_station("")

	var pp := GameState.get_planet(data.seed)

	var root := VBoxContainer.new()
	root.name = "DistrictBuildPanel"
	root.add_theme_constant_override("separation", 8)
	root.add_child(HSeparator.new())



	# ── PLANET page (stored resources live in the HUD's top bar) ─────────────
	var planet_page := VBoxContainer.new()
	planet_page.add_theme_constant_override("separation", 6)
	root.add_child(planet_page)

	_overview_energy_val = null  # energy shown in top-center HUD

	# ── Pre-split POIs (needed for counts before tab section) ─────────────────
	var surface_pois: Array[POIData] = []
	var orbital_pois: Array[POIData] = []
	for poi: POIData in data.custom_pois:
		if poi.is_orbital():
			orbital_pois.append(poi)
		elif poi.is_city():
			surface_pois.append(poi)   # districts are listed inside their City

	# ── Planet info: one row of chips — size, atmosphere, modifiers, deposits ──
	var info_row := HFlowContainer.new()
	info_row.add_theme_constant_override("h_separation", 4)
	info_row.add_theme_constant_override("v_separation", 4)
	planet_page.add_child(info_row)

	var p_size_str := "Small" if data.planet_size < 0.8 else ("Large" if data.planet_size > 1.3 else "Medium")
	var p_atm_str: String
	if data.has_atmosphere:
		p_atm_str = "Thin" if data.atmosphere_density < 0.4 else ("Dense" if data.atmosphere_density > 0.7 else "Standard")
	else:
		p_atm_str = "None"
	info_row.add_child(_info_chip(p_size_str, Color(0.70, 0.76, 0.95), "Size", "%s planet." % p_size_str))
	info_row.add_child(_info_chip("Atm. " + p_atm_str, Color(0.70, 0.76, 0.95), "Atmosphere",
		"No atmosphere." if p_atm_str == "None" else "%s atmosphere." % p_atm_str))

	for m: PlanetModifier in PlanetModifier.for_planet(data.planet_type):
		info_row.add_child(_info_chip("%s %s" % [m.display_name, m.value_label()],
			Color(0.55, 0.96, 0.62) if m.is_positive() else Color(1.0, 0.58, 0.58),
			m.display_name, m.description + "\n\n" + m.value_label()))

	# Minerals: a chip per discovered mineral; unknown until the first Production here
	if not Economy.raw_for_body(data).is_empty() and not GameState.is_body_surveyed(data.seed):
		info_row.add_child(_info_chip("Minerals ?", Color(0.55, 0.60, 0.78), "Unknown minerals",
			"Complete a Production building or district on this world to discover what it holds.\nEvery site on the body yields its whole mineral set."))
	for r: Dictionary in Economy.discovered_raw_for_body(data):
		info_row.add_child(_info_chip(r["name"], r["color"], r["name"],
			"Mined anywhere on this world by Production buildings and districts.\nStock: %s" % Economy.fmt(Economy.amount(r["id"])),
			MineralIcon.make(1, r["color"])))

	if not pp.is_colonized:
		var unc_spacer := Control.new()
		unc_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		planet_page.add_child(unc_spacer)

		var col_sep := HSeparator.new()
		var col_sep_s := StyleBoxFlat.new(); col_sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
		col_sep.add_theme_stylebox_override("separator", col_sep_s)
		planet_page.add_child(col_sep)

		if pp.is_colonizing:
			var pbar := ProgressBar.new()
			pbar.custom_minimum_size = Vector2(0, 32)
			pbar.value = pp.colonize_progress * 100.0
			pbar.show_percentage = false
			
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color(0.1, 0.15, 0.25)
			bg.corner_radius_top_left = 4; bg.corner_radius_top_right = 4
			bg.corner_radius_bottom_left = 4; bg.corner_radius_bottom_right = 4
			
			var fg := StyleBoxFlat.new()
			fg.bg_color = Color(0.3, 0.8, 0.4)
			fg.corner_radius_top_left = 4; fg.corner_radius_top_right = 4
			fg.corner_radius_bottom_left = 4; fg.corner_radius_bottom_right = 4
			
			pbar.add_theme_stylebox_override("background", bg)
			pbar.add_theme_stylebox_override("fill", fg)
			
			var plabel := Label.new()
			plabel.text = "Lander in transit..." if data.planet_type == PlanetData.Type.MOON else ("Establishing..." if data.planet_type == PlanetData.Type.ASTEROID else "Colonizing...")
			plabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plabel.set_anchors_preset(Control.PRESET_FULL_RECT)
			_apply_orbitron(plabel, 12)
			pbar.add_child(plabel)
			
			planet_page.add_child(pbar)
			
			# Listen for progress updates
			for conn in ProductionManager.building_progress_changed.get_connections():
				if conn["callable"].get_object() == self and conn["callable"].get_method() == "_on_colonize_progress_changed":
					ProductionManager.building_progress_changed.disconnect(conn["callable"])
			ProductionManager.building_progress_changed.connect(_on_colonize_progress_changed.bind(pbar, data.seed))
		elif not GameState.can_play_on(data.seed):
			# post-demo inspection: other worlds can be looked at, not settled
			var note := Label.new()
			note.text = "Preview — settling new worlds is Civilization 1 content, not playable in the demo."
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_apply_orbitron(note, 9)
			note.add_theme_color_override("font_color", Color(0.65, 0.6, 0.85))
			planet_page.add_child(note)
		else:
			var col_btn := Button.new()
			if data.planet_type == PlanetData.Type.MOON or data.planet_type == PlanetData.Type.ASTEROID:
				col_btn.text = "BUILD OUTPOST"
			else:
				col_btn.text = "COLONIZE"
			_apply_orbitron(col_btn, 12)
			var col_sb := StyleBoxFlat.new()
			col_sb.bg_color = Color(0.10, 0.28, 0.45)
			col_sb.content_margin_top = 10; col_sb.content_margin_bottom = 10
			col_btn.add_theme_stylebox_override("normal", col_sb)
			var col_hb := col_sb.duplicate() as StyleBoxFlat
			col_hb.bg_color = Color(0.15, 0.42, 0.65)
			col_btn.add_theme_stylebox_override("hover", col_hb)
			col_btn.add_theme_color_override("font_color", Color.WHITE)
			if data.planet_type == PlanetData.Type.MOON:
				_setup_moon_colonize_button(col_btn, data)
			else:
				col_btn.pressed.connect(func() -> void:
					_show_colonize_popup(data, pp)
				)
			planet_page.add_child(col_btn)
		
		root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_content.add_child(root)
		return

	if pp.lander_state == 1 and _city_count(data) == 0:
		_add_found_settlement_button(planet_page)
	if data.planet_type == PlanetData.Type.MOON and _city_count(data) > 0 and not GameState.showcase_mode:
		_add_rocket_section(planet_page, data)

	# ── District slot indicators ─────────────────────────────────────────────
	var st := get_node_or_null("/root/SkillTree")
	var has_orbital_unlocked := false
	for p_def: DistrictDef in DistrictDef.all():
		if p_def.is_orbital and p_def.max_per_planet > 0:
			if p_def.unlock_skill == "" or (st != null and st.is_unlocked(p_def.unlock_skill)):
				has_orbital_unlocked = true
	var p_max_orbital: int = pp.max_orbital_districts

	# ── Tab bar ───────────────────────────────────────────────────────────────
	var tab_sep := HSeparator.new()
	var tab_sep_s := StyleBoxFlat.new()
	tab_sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	tab_sep.add_theme_stylebox_override("separator", tab_sep_s)
	root.add_child(tab_sep)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 0)
	root.add_child(tab_row)

	_inner_tab_active = "SURFACE"   # stations live in the Orbit card now
	var dist_btn:    Button = _make_overview_tab_btn("CITIES  %d" % Leveling.cities_used(data, pp), true)
	var orbital_btn: Button = _make_overview_tab_btn("ORBITAL  %d/%d" % [orbital_pois.size(), p_max_orbital],
		_inner_tab_active == "ORBITAL")
	tab_row.add_child(dist_btn)

	# ── DISTRICTS scroll + page ───────────────────────────────────────────────
	var dist_scroll := ScrollContainer.new()
	dist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dist_scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	root.add_child(dist_scroll)
	_style_scroll(dist_scroll)
	var _saved_scroll := _panel_scroll_pos
	dist_scroll.call_deferred("set", "scroll_vertical", _saved_scroll)

	var districts_page := VBoxContainer.new()
	districts_page.add_theme_constant_override("separation", 8)
	districts_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_scroll.add_child(districts_page)

	_poi_overview_cards.clear()
	_stop_tut_panel_pulse()
	for poi: POIData in surface_pois:
		districts_page.add_child(_build_district_overview_card(poi, data, pp, panel_content, root))
	if pp.orbit_level > 0:
		districts_page.add_child(_build_orbit_card(data, pp))

	var can_add_surface := UNLIMITED_SURFACE_DISTRICTS or surface_pois.size() < pp.max_districts
	if can_add_surface:
		var add_dist_card := _build_add_district_card(data, true, false)
		districts_page.add_child(add_dist_card)
	# Tutorial: districts are added from a City's panel — point at the first City
	if TutorialManager.get_action_step_type() == "district" and districts_page.get_child_count() > 0:
		_tut_highlight_node = districts_page.get_child(0) as Control
		_start_tut_node_pulse(_tut_highlight_node)

	# ── ORBITAL scroll + page ─────────────────────────────────────────────────
	var orb_scroll := ScrollContainer.new()
	orb_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	orb_scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	orb_scroll.visible = false
	root.add_child(orb_scroll)
	_style_scroll(orb_scroll)
	orb_scroll.call_deferred("set", "scroll_vertical", _saved_scroll)

	var orbital_page := VBoxContainer.new()
	orbital_page.add_theme_constant_override("separation", 8)
	orbital_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orb_scroll.add_child(orbital_page)

	for poi: POIData in orbital_pois:
		orbital_page.add_child(_build_district_overview_card(poi, data, pp, panel_content, root))

	var can_add_orbital := orbital_pois.size() < pp.max_orbital_districts
	orbital_page.add_child(_build_add_district_card(data, can_add_orbital, true))

	# ── Tab switching ─────────────────────────────────────────────────────────
	if not has_orbital_unlocked and _inner_tab_active == "ORBITAL":
		_inner_tab_active = "SURFACE"

	dist_btn.toggled.connect(func(on: bool) -> void:
		if on:
			_inner_tab_active = "SURFACE"
			orbital_btn.button_pressed = false
			dist_scroll.visible = true
			orb_scroll.visible  = false
		else:
			if _inner_tab_active == "SURFACE":
				dist_btn.set_pressed_no_signal(true))
	orbital_btn.toggled.connect(func(on: bool) -> void:
		if on:
			_inner_tab_active = "ORBITAL"
			dist_btn.button_pressed = false
			dist_scroll.visible = false
			orb_scroll.visible  = true
		else:
			if _inner_tab_active == "ORBITAL":
				orbital_btn.set_pressed_no_signal(true))
	# Restore correct visibility based on saved state
	dist_scroll.visible = (_inner_tab_active == "SURFACE")
	orb_scroll.visible  = (_inner_tab_active == "ORBITAL") and has_orbital_unlocked

	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# --- LEVEL UP SECTION ---
	var lvl_sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	lvl_sep.add_theme_stylebox_override("separator", sep_style)
	root.add_child(lvl_sep)

	if pp.is_upgrading:
		var up_lbl := Label.new()
		up_lbl.text = "UPGRADING TO LV %d..." % (pp.level + 1)
		up_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_orbitron(up_lbl, 10)
		up_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		root.add_child(up_lbl)

		_planet_upgrade_pbar = ProgressBar.new()
		_planet_upgrade_pbar.custom_minimum_size.y = 12
		_planet_upgrade_pbar.show_percentage = false
		_planet_upgrade_pbar.value = pp.upgrade_progress * 100.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.1, 0.15)
		var sbf := StyleBoxFlat.new()
		sbf.bg_color = Color(0.4, 0.9, 0.4)
		_planet_upgrade_pbar.add_theme_stylebox_override("background", sb)
		_planet_upgrade_pbar.add_theme_stylebox_override("fill", sbf)
		root.add_child(_planet_upgrade_pbar)
	else:
		_planet_upgrade_pbar = null
		
		var up_btn := Button.new()
		up_btn.text = "PLANET  Lv %d  →  Lv %d" % [pp.level, pp.level + 1]
		up_btn.focus_mode = Control.FOCUS_NONE
		_apply_orbitron(up_btn, 9)
		var btn_sb := StyleBoxFlat.new()
		btn_sb.bg_color = Color(0.08, 0.20, 0.12, 0.85)
		btn_sb.border_color = Color(0.35, 0.80, 0.45, 0.6)
		btn_sb.set_border_width_all(1)
		btn_sb.set_corner_radius_all(4)
		btn_sb.content_margin_top = 6; btn_sb.content_margin_bottom = 6
		up_btn.add_theme_stylebox_override("normal", btn_sb)
		var h_sb := btn_sb.duplicate() as StyleBoxFlat
		h_sb.bg_color = Color(0.12, 0.30, 0.18, 0.95)
		up_btn.add_theme_stylebox_override("hover", h_sb)
		up_btn.add_theme_stylebox_override("pressed", h_sb)
		up_btn.add_theme_color_override("font_color", Color(0.70, 1.0, 0.75))
		up_btn.mouse_entered.connect(func():
			AudioManager.play("hover")
			TooltipManager.show_tip("Planet level up", _planet_level_tip(data, pp)))
		up_btn.mouse_exited.connect(func(): TooltipManager.hide_tip())
		up_btn.pressed.connect(func(): AudioManager.play("click"); _show_level_up_popup(pp))
		root.add_child(up_btn)
		_notify_tutorial_planet_level_up_btn(up_btn)

	panel_content.add_child(root)

## Compact card for a ship in the Orbital tab.
func _build_orbital_ship_card(ship: ShipData) -> PanelContainer:
	var card := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.07, 0.10, 0.18, 0.85)
	s.border_color = Color(0.35, 0.42, 0.70, 0.40)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 10; s.content_margin_right  = 10
	s.content_margin_top  =  7; s.content_margin_bottom =  7
	card.add_theme_stylebox_override("panel", s)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	# Name + status column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = ship.ship_name
	_apply_orbitron(name_lbl, 10)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30))
	vbox.add_child(name_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "En route…" if ship.is_travelling() else "In orbit"
	_apply_orbitron(status_lbl, 8)
	status_lbl.add_theme_color_override("font_color", Color(0.50, 0.68, 0.95, 0.75))
	vbox.add_child(status_lbl)

	# Cargo summary (icon count)
	if not ship.cargo.is_empty():
		var cargo_row := HBoxContainer.new()
		cargo_row.add_theme_constant_override("separation", 3)
		vbox.add_child(cargo_row)
		for rid: String in ship.cargo:
			var rd: ResourceData = GameState.known_resources.get(rid, null)
			if rd == null: continue
			cargo_row.add_child(_mineral_grid_card(rd, ship.cargo[rid], true))

	# Select button
	var sel_btn := Button.new()
	sel_btn.text = "Select"
	_apply_orbitron(sel_btn, 8)
	var bs := StyleBoxFlat.new()
	bs.bg_color     = Color(0.10, 0.18, 0.35, 0.85)
	bs.border_color = Color(1.0, 0.92, 0.30, 0.45)
	bs.set_border_width_all(1)
	bs.set_corner_radius_all(3)
	bs.content_margin_left = 8; bs.content_margin_right  = 8
	bs.content_margin_top  = 3; bs.content_margin_bottom = 3
	sel_btn.add_theme_stylebox_override("normal",  bs)
	sel_btn.add_theme_stylebox_override("hover",   bs)
	sel_btn.add_theme_stylebox_override("pressed", bs)
	sel_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30, 0.85))
	sel_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	sel_btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))

	var cap_ship := ship
	sel_btn.pressed.connect(func() -> void:
		if _orbital_layer != null and is_instance_valid(_orbital_layer):
			_orbital_layer.select_ship(cap_ship)
			# Rotate planet so the ship's current position faces the viewer (rz < 0)
			# px,pz = ship position in orbit plane (normalized)
			var px: float = cos(cap_ship.orbit_angle)
			var pz: float = sin(cap_ship.orbit_angle) * cos(cap_ship.orbit_inclination)
			# rot_target such that rx=0 and rz<0: atan2(-px, pz) + PI
			var rot_target: float = atan2(-px, pz) + PI
			_rotate_to_lon(rad_to_deg(rot_target - cap_ship.orbit_node)))
	hbox.add_child(sel_btn)

	return card

func _build_resources_section(parent: VBoxContainer, data: PlanetData, pp: PlanetProgress) -> void:
	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	sep.add_theme_stylebox_override("separator", sep_s)
	parent.add_child(sep)

	var title := Label.new()
	title.text = "RESOURCES"
	_apply_orbitron(title, 8)
	title.add_theme_color_override("font_color", Color(0.40, 0.45, 0.65))
	parent.add_child(title)

	# Collect global resources with amount > 0, resolved from known_resources
	var stored_entries: Array[ResourceData] = []
	for rid: String in GameState.global_resources:
		var amt: float = GameState.global_resources[rid]
		if amt <= 0.0:
			continue
		var rd: ResourceData = GameState.known_resources.get(rid, null)
		if rd == null:
			continue
		stored_entries.append(rd)
	stored_entries.sort_custom(func(a: ResourceData, b: ResourceData) -> bool:
		return a.rarity < b.rarity if a.rarity != b.rarity else a.tier < b.tier)

	if stored_entries.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "No resources stored"
		_apply_orbitron(none_lbl, 8)
		none_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		parent.add_child(none_lbl)
		return

	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for rd: ResourceData in stored_entries:
		var stored: float = GameState.global_resources.get(rd.resource_id(), 0.0)
		grid.add_child(_mineral_grid_card(rd, stored, true, "", pp))
	parent.add_child(grid)

## Station cards: stations don't level, so a station glyph instead of a level.
func _station_tile() -> PanelContainer:
	var tile := PanelContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(40, 40)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.11, 0.24, 0.95)
	sb.border_color = Color(0.60, 0.55, 1.0, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	tile.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = "◈"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.75, 0.70, 1.0))
	tile.add_child(l)
	return tile

## Coloured "LV / n" tile for district and City cards (gold rim for a City).
func _level_badge(lv: int, is_city: bool) -> PanelContainer:
	var col := Leveling.level_color(lv)
	var tile := PanelContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(40, 40)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 0.95)
	sb.border_color = Color(1.0, 0.85, 0.35) if is_city else col
	sb.set_border_width_all(2 if is_city else 1)
	sb.set_corner_radius_all(4)
	tile.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(v)
	var cap := Label.new()
	cap.text = "LV"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(cap, 7)
	cap.add_theme_color_override("font_color", Color(col, 0.8))
	v.add_child(cap)
	var num := Label.new()
	num.text = str(lv)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(num, 18)
	num.add_theme_color_override("font_color", col.lightened(0.2))
	v.add_child(num)
	return tile

## `as_capital`: a City shown as its Capital District (inside the City panel);
## otherwise a City card opens the City panel.
func _build_district_overview_card(poi: POIData, planet: PlanetData, pp: PlanetProgress,
		_panel_content: VBoxContainer, _root: VBoxContainer, as_capital: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.set_meta("poi_label", poi.label)
	_poi_overview_cards[poi.label] = card
	var s := _card_panel_style()
	s.bg_color = Color(0.07, 0.09, 0.17, 0.80)
	card.add_theme_stylebox_override("panel", s)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 48)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",   8)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_bottom",  6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Big level number on the left
	var as_city := poi.is_city() and not as_capital
	var dist_lv_ov: int = Leveling.city_level(pp, poi) if as_city else pp.district_levels.get(poi.label, 1)
	if poi.is_orbital():
		hbox.add_child(_station_tile())
	else:
		hbox.add_child(_level_badge(dist_lv_ov, as_city))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 1)

	var n_lbl := Label.new()
	n_lbl.text = "Capital District" if as_capital else poi.shown_name()
	n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(n_lbl, 10)
	n_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))

	var t_lbl := Label.new()
	var district_buildings := pp.buildings_in_district(poi.label)
	var total_size: int = 0
	for eb: Dictionary in district_buildings:
		total_size += eb.get("amount", 1)
	t_lbl.text = ("Capital" if as_capital else poi.type_label()) + "  ·  Size %d" % total_size
	if poi.is_orbital():
		var mod := "no module yet"
		for eb: Dictionary in district_buildings:
			var mdef := BuildingDef.find(eb.get("building_id", ""))
			if mdef != null:
				mod = mdef.display_name + ("  (building)" if eb.get("constructing", false) else "")
		t_lbl.text = "Station  ·  " + mod
	if as_city:
		var n_children := 0
		for child: POIData in planet.custom_pois:
			if child.parent_city == poi.label:
				n_children += 1
		t_lbl.text += "  ·  %d district%s" % [n_children, "" if n_children == 1 else "s"]
	t_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(t_lbl, 8)
	t_lbl.add_theme_color_override("font_color", Color(0.42, 0.48, 0.68))

	info.add_child(n_lbl); info.add_child(t_lbl)

	# Base income (own + neighbours) with a thin bar for its cycle
	if not poi.constructing and not poi.is_orbital() and ProductionManager.district_def(poi) != null:
		var inc_txt := _district_base_text(pp, poi)
		if inc_txt != "":
			var inc_lbl := Label.new()
			inc_lbl.text = inc_txt
			inc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inc_lbl.clip_text = true
			_apply_orbitron(inc_lbl, 7)
			inc_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60, 0.9))
			info.add_child(inc_lbl)
			# energy / housing are continuous — only stock income has a cycle
			var d_inc := ProductionManager.district_income(pp, poi)
			if ProductionManager._has_stock_income(d_inc):
				var cyc_col := Color(0.45, 0.85, 0.55)
				for rid: String in d_inc:
					if rid != Economy.ENERGY and rid != Economy.POPULATION:
						cyc_col = Economy.color_of(rid) if rid != Economy.RAW else Color(0.85, 0.78, 0.70)
						break
				var p_seed := planet.seed
				var p_label := poi.label
				card.add_child(_cycle_fill(func() -> float: return ProductionManager.base_progress(p_seed, p_label), cyc_col))

	# being built / levelled: the shared hazard fill behind the whole card
	var c_poi := poi
	if poi.constructing:
		card.add_child(_hazard_fill(func() -> float: return c_poi.construct_progress))
		t_lbl.text = "Constructing..."
	elif as_city and pp.city_upgrading.has(poi.label):
		card.add_child(_hazard_fill(func() -> float: return float(pp.city_upgrading.get(c_poi.label, 1.0))))
		t_lbl.text = "City levelling up…"
	elif not as_city and pp.is_district_upgrading(poi.label):
		card.add_child(_hazard_fill(func() -> float: return float(pp.district_upgrading.get(c_poi.label, 1.0))))

	hbox.add_child(info)

	# Whole card clickable — no separate arrow button
	var cap_poi    := poi
	var cap_planet := planet
	var cap_card   := card
	var norm_s2 := card.get_theme_stylebox("panel") as StyleBoxFlat
	var hov_s2  := norm_s2.duplicate() as StyleBoxFlat
	hov_s2.bg_color = Color(0.10, 0.14, 0.28, 0.92)
	card.mouse_entered.connect(func() -> void:
		AudioManager.play("district_hover")
		cap_card.add_theme_stylebox_override("panel", hov_s2)
		if cap_poi.constructing:
			TooltipManager.show_tip("Constructing", "This District is not fully operational yet.\nBuild time: %.0fs" % cap_poi.construct_duration)
		CursorManager.set_state(CursorManager.State.POINTER))
	card.mouse_exited.connect(func() -> void:
		cap_card.add_theme_stylebox_override("panel", norm_s2)
		TooltipManager.hide_tip()
		CursorManager.set_state(CursorManager.State.NORMAL))
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			if cap_poi.is_orbital():
				# Rotate planet so station faces camera, then highlight.
				# Derive equatorial longitude by inverting _project_poi: rx=0, rz<0.
				if _orbital_layer != null and is_instance_valid(_orbital_layer):
					_orbital_layer.set_selected_station(cap_poi.label)
				var eq_lon: float = rad_to_deg(
					atan2(cos(cap_poi.orbit_angle),
						-sin(cap_poi.orbit_angle) * cos(cap_poi.orbit_inclination))
					- cap_poi.orbit_node)
				_rotate_to_lon(eq_lon)
			else:
				_select_district_on_planet(cap_poi.label)
				_focus_on_site(cap_poi.lon_deg, cap_poi.lat_deg)
			if cap_poi.constructing:
				TooltipManager.show_tip("Constructing", "This District is not fully operational yet.\nBuild time: %.0fs" % cap_poi.construct_duration)
				return
			if as_city:
				_build_city_panel(cap_poi, cap_planet)
			else:
				_build_district_panel(cap_poi, cap_planet))
	return card

func _style_scroll(sc: ScrollContainer) -> void:
	# Thin, non-overlapping scrollbar styled to match the dark UI
	var vsb := sc.get_v_scroll_bar()
	vsb.custom_minimum_size = Vector2(4, 0)
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.10, 0.12, 0.20, 0.0)
	vsb.add_theme_stylebox_override("scroll", norm)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color        = Color(0.35, 0.45, 0.75, 0.55)
	grabber.corner_radius_top_left     = 2; grabber.corner_radius_top_right    = 2
	grabber.corner_radius_bottom_left  = 2; grabber.corner_radius_bottom_right = 2
	vsb.add_theme_stylebox_override("grabber",       grabber)
	vsb.add_theme_stylebox_override("grabber_hover",  grabber)
	vsb.add_theme_stylebox_override("grabber_pressed", grabber)

func _select_district_on_planet(label: String) -> void:
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.set_selected_station("")
	for i in poi_layer._pois.size():
		if poi_layer._pois[i].get("label", "") == label:
			poi_layer.select_poi(i)
			return

## parent == null on the planet overview (founds a City); a City → adds a district under it.
func _build_add_district_card(data: PlanetData, enabled: bool, orbital_only: bool = false,
		parent: POIData = null) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Orbital tab: don't show the card at all when slots are full
	if orbital_only and not enabled:
		return wrapper
	# Planet overview: no free City slot and no Orbit to found → no card;
	# the planet level-up button below says what opens the next City
	if parent == null and not orbital_only and not GameState.showcase_mode:
		var slot_pp := GameState.get_planet(data.seed)
		if slot_pp != null and Leveling.cities_used(data, slot_pp) >= slot_pp.max_cities() \
				and not _orbit_option_visible(data):
			return wrapper

	var card := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.12, 0.22, 0.55) if enabled else Color(0.05, 0.06, 0.10, 0.35)
	s.border_color = Color(0.28, 0.40, 0.75, 0.45) if enabled else Color(0.18, 0.22, 0.35, 0.30)
	s.border_width_left = 1; s.border_width_right  = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = 5; s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5; s.corner_radius_bottom_right = 5
	s.content_margin_left   = 10; s.content_margin_right  = 10
	s.content_margin_top    = 8;  s.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", s)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(card)

	var hbox := HBoxContainer.new()
	card.add_child(hbox)

	var plus_lbl := Label.new()
	plus_lbl.text = "+"
	_apply_orbitron(plus_lbl, 14)
	plus_lbl.add_theme_color_override("font_color",
		Color(0.45, 0.60, 1.0, 0.9) if enabled else Color(0.30, 0.35, 0.50, 0.5))
	plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(plus_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

	var txt := Label.new()
	if not enabled:
		txt.text = "SLOTS FULL"
	elif orbital_only or parent != null:
		txt.text = "ADD DISTRICT"
	else:
		txt.text = "FOUND CITY"
	_apply_orbitron(txt, 8)
	txt.add_theme_color_override("font_color",
		Color(0.55, 0.70, 1.0, 0.75) if enabled else Color(0.35, 0.38, 0.52, 0.6))
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(txt)

	var founds_city := parent == null and not orbital_only
	if founds_city:   # the cost and what's in the way, before the player tries
		card.mouse_entered.connect(func() -> void: TooltipManager.show_tip("Found City", _found_city_tip(data)))
		card.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	if enabled:
		card.mouse_entered.connect(func() -> void:
			AudioManager.play("hover")
			CursorManager.set_state(CursorManager.State.POINTER))
		card.mouse_exited.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.NORMAL))
		# Dropdown — an overlay on its own layer, so it never pushes the panel around
		var dropdown_ref: Array[Node] = [null]
		var cap_data  := data
		var cap_card  := card
		card.gui_input.connect(func(e: InputEvent) -> void:
			if not (e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
					and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
				return
			AudioManager.play("click")
			# Toggle
			if dropdown_ref[0] != null and is_instance_valid(dropdown_ref[0]):
				dropdown_ref[0].queue_free()
				dropdown_ref[0] = null
				return
			# Only one choice (founding a City until other city kinds exist): start placing at once
			var opts := _district_options(cap_data, orbital_only, parent)
			if opts.size() == 1 and not orbital_only \
					and not (parent == null and _orbit_option_visible(cap_data)):
				if opts[0].is_system_anchor() and _found_city_block(cap_data) != "":
					AudioManager.play("error")
					TooltipManager.show_tip("Found City", _found_city_tip(cap_data))
					return
				_begin_district_placement(opts[0], parent)
				return
			var layer := CanvasLayer.new()
			layer.layer = 205
			add_child(layer)
			var shade := Control.new()
			shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shade.mouse_filter = Control.MOUSE_FILTER_STOP
			shade.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
					if is_instance_valid(layer):
						layer.queue_free()
					dropdown_ref[0] = null)
			layer.add_child(shade)
			var dd := _build_district_type_dropdown(cap_data, null, dropdown_ref, orbital_only, parent)
			layer.add_child(dd)
			dropdown_ref[0] = layer
			var r := cap_card.get_global_rect()
			dd.custom_minimum_size = Vector2(r.size.x, 0)
			dd.position = Vector2(r.position.x, r.end.y + 2.0)
			_notify_tutorial_district_type_dropdown(dd)
			# After layout: if it runs off the bottom, open upward instead
			await get_tree().process_frame
			if is_instance_valid(dd):
				var vp_h := get_viewport().get_visible_rect().size.y
				if dd.position.y + dd.size.y > vp_h - 8.0:
					dd.position.y = maxf(8.0, r.position.y - dd.size.y - 2.0))

	return wrapper

## Why a new City can't be founded right now ("" when it can).
func _found_city_block(data: PlanetData) -> String:
	var pp := GameState.get_planet(data.seed)
	if Leveling.cities_used(data, pp) >= pp.max_cities():
		return "No free City slot — Planet Lv %d supports %d. Level the planet up." % [pp.level, pp.max_cities()]
	var cost := DistrictDef.placement_cost(DistrictDef.find(DistrictDef.Type.CITY), data)
	if GameState.credits < cost:
		return "Not enough credits — need %s, have %s." % [HUDManager.fmt_credits(cost), HUDManager.fmt_credits(GameState.credits)]
	return ""

func _found_city_tip(data: PlanetData) -> String:
	var pp := GameState.get_planet(data.seed)
	var cost := DistrictDef.placement_cost(DistrictDef.find(DistrictDef.Type.CITY), data)
	var lines: Array[String] = ["Pick a site on the planet for a new City.",
		"",
		"Cost  " + _cost_bb(cost, 0, data, pp),
		"Cities  %d / %d  (planet Lv %d)" % [Leveling.cities_used(data, pp), pp.max_cities(), pp.level],
		_bb("Each City costs more than the last.", BB_DIM)]
	var block := _found_city_block(data)
	if block != "":
		lines.append("")
		lines.append(_bb("➡ " + block, BB_BAD))
	return "\n".join(lines)

## District types the add card offers: the planet overview founds Cities, a
## City's panel adds the other districts, the orbital tab stations.
func _district_options(data: PlanetData, orbital_only: bool, parent: POIData) -> Array[DistrictDef]:
	var out: Array[DistrictDef] = []
	for def: DistrictDef in DistrictDef.for_planet(data.planet_type):
		if def.is_orbital != orbital_only:
			continue
		if def.unlock_skill != "" and not get_node("/root/SkillTree").is_unlocked(def.unlock_skill):
			continue
		if not orbital_only and def.is_system_anchor() != (parent == null):
			continue
		out.append(def)
	return out

func _build_district_type_dropdown(data: PlanetData, _anchor: VBoxContainer,
		dropdown_ref: Array[Node], orbital_only: bool = false, parent: POIData = null) -> PanelContainer:
	var dd := PanelContainer.new()
	dd.add_theme_stylebox_override("panel", _make_hud_style(Color(0.06, 0.08, 0.16, 0.97), 6))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	dd.add_child(vbox)
	for def: DistrictDef in _district_options(data, orbital_only, parent):
		vbox.add_child(_build_district_type_row(data, def, dropdown_ref, parent))
	if parent == null and not orbital_only and _orbit_option_visible(data):
		vbox.add_child(_build_orbit_type_row(data, dropdown_ref))
	return dd

func _build_district_type_row(data: PlanetData, def: DistrictDef,
		dropdown_ref: Array[Node], parent: POIData = null) -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.text = "%s  %s" % [def.icon, def.display_name]
	btn.set_meta("district_def_id", int(def.id))
	_apply_orbitron(btn, 9)
	var parent_label := parent.label if parent != null else ""
	var cost: float = DistrictDef.placement_cost(def, data, parent_label)
	var pop_need := Economy.founding_pop(def, data, parent_label)
	var pop_free := Economy.free_population(data, GameState.get_planet(data.seed))
	var has_pop: bool = pop_free >= pop_need
	var full_cost := DistrictDef.placement_full_cost(def, data, parent_label)
	var can_afford: bool = Economy.can_pay(full_cost)   # population may go negative (slows work)
	if pop_need > 0:
		btn.text += "   ☺%s" % Economy.fmt(pop_need)
	var at_limit: bool
	if def.is_orbital:
		var pp2 := GameState.get_planet(data.seed)
		var orbital_count := data.custom_pois.filter(func(p: POIData) -> bool: return p.is_orbital()).size()
		at_limit = pp2 == null or orbital_count >= pp2.max_orbital_districts
	else:
		at_limit = def.max_per_planet > 0 and DistrictDef.count_on_planet(def, data) >= def.max_per_planet
		if def.is_system_anchor():
			at_limit = at_limit or Leveling.cities_used(data, GameState.get_planet(data.seed)) >= GameState.get_planet(data.seed).max_cities()

	var cap_limit := at_limit
	_live_enable(btn, func() -> bool: return Economy.can_pay(full_cost) and not cap_limit)
	if at_limit:
		btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.6))
	elif not can_afford:
		btn.add_theme_color_override("font_disabled_color", Color(0.9, 0.3, 0.3))
	else:
		btn.add_theme_color_override("font_color",       Color(0.75, 0.82, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0,  0.95, 0.55))

	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0, 0, 0, 0)
	norm.content_margin_left = 10; norm.content_margin_right  = 10
	norm.content_margin_top  = 6;  norm.content_margin_bottom = 6
	var hov := norm.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.12, 0.18, 0.35, 0.60)
	btn.add_theme_stylebox_override("normal",  norm)
	btn.add_theme_stylebox_override("hover",   hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_stylebox_override("disabled", norm)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	var cost_str := HUDManager.fmt_credits(cost)
	btn.mouse_entered.connect(func() -> void:
		AudioManager.play("district_hover")
		CursorManager.set_state(CursorManager.State.POINTER)
		var t_title = def.display_name
		var t_desc = def.description
		if at_limit:
			var _pp_lim := GameState.get_planet(data.seed)
			var _lim: int = (_pp_lim.max_orbital_districts if _pp_lim != null else 1) if def.is_orbital else def.max_per_planet
			if def.is_system_anchor():
				t_desc += "\n\n[color=orange]Planet Lv %d supports %d cit%s — level the planet up to found more.[/color]" % [
					_pp_lim.level, _pp_lim.max_cities(), "y" if _pp_lim.max_cities() == 1 else "ies"]
			else:
				t_desc += "\n\n[color=gray]Already built (limit: %d)[/color]" % _lim
		elif not can_afford:
			t_desc += "\n\n[color=red]%s[/color]" % Economy.cost_block(full_cost)
		t_desc += "\n\nCost  " + _cost_bb(cost, pop_need, data, GameState.get_planet(data.seed))
		if full_cost.size() > 1:
			t_desc += "\n  + " + Economy.cost_text(DistrictDef.placement_materials(def, data))
		if pop_need > 0:
			t_desc += _bb("  (%s free)" % Economy.fmt(pop_free), BB_DIM)
			if not has_pop:
				t_desc += "\n[color=orange]Population will exceed housing — output drops until you build more homes.[/color]"
		TooltipManager.show_tip(t_title, t_desc, cost_str))
	btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())

	var cap_def  := def
	var cap_data := data
	btn.pressed.connect(func() -> void:
		if dropdown_ref[0] != null and is_instance_valid(dropdown_ref[0]):
			dropdown_ref[0].queue_free()
			dropdown_ref[0] = null
		TooltipManager.hide_tip()
		# Surface districts: the player picks the site; credits are spent on placement.
		if not cap_def.is_orbital:
			_begin_district_placement(cap_def, parent)
			return
		if not GameState.spend_credits(DistrictDef.placement_cost(cap_def, cap_data)):
			AudioManager.play("error")
			return
		_spawn_district(cap_data, cap_def.suggest_name(cap_data), cap_def))

	return btn

func _on_district_clicked(index: int, _data: Dictionary) -> void:
	if GameState.showcase_mode or index >= poi_layer._pois.size():
		return
	AudioManager.play("district_hover")
	if _orbital_layer != null and is_instance_valid(_orbital_layer):
		_orbital_layer.set_selected_station("")
	var poi_dict: Dictionary = poi_layer._pois[index]
	var poi_label: String    = poi_dict.get("label", "")
	if current_data == null:
		return
	# Find matching POIData
	var poi: POIData = null
	for pd: POIData in current_data.custom_pois:
		if pd.label == poi_label:
			poi = pd
			break
	if poi == null:
		return
	var now := Time.get_ticks_msec()
	var is_double := poi.label == _last_click_label and now - _last_click_ms <= DOUBLE_CLICK_MS
	_last_click_ms = 0 if is_double else now
	_last_click_label = poi.label
	if is_double and not poi.is_orbital():
		_focus_city(_city_of(poi))
		return   # the first click already chose the panel
	if poi.constructing:
		TooltipManager.show_tip("Constructing", "This District is not fully operational yet.\n%d%% built · %.0fs total" % [
			int(poi.construct_progress * 100.0), poi.construct_duration])
		_hide_tip_when_mouse_leaves(get_viewport().get_mouse_position())
		return
	_reveal_panel()   # selecting a district brings the side panel back
	# zoomed out a City icon is the whole City; zoomed in it's its Capital District.
	# Clicking it again toggles City <-> Capital District.
	var shown := $SidePanel/PanelContent.get_node_or_null("DistrictBuildPanel")
	var showing_capital: bool = shown != null and not shown.is_queued_for_deletion() \
			and shown.get_meta("district", "") == poi.label
	if poi.is_city() and _city_panel_poi == poi:
		_build_district_panel(poi, current_data)
	elif poi.is_city() and (showing_capital or _zoom < ZOOM_DETAIL_FULL):
		_build_city_panel(poi, current_data)
	else:
		_build_district_panel(poi, current_data)

## Hides a click tooltip once the mouse moves away from where it was shown
## (or after a few seconds) — map clicks have no mouse_exited to do it.
func _hide_tip_when_mouse_leaves(at: Vector2) -> void:
	var t0 := Time.get_ticks_msec()
	while is_inside_tree():
		await get_tree().process_frame
		if get_viewport().get_mouse_position().distance_to(at) > 24.0 or Time.get_ticks_msec() - t0 > 3000:
			TooltipManager.hide_tip()
			return

## The City a district belongs to (itself for a City).
func _city_of(poi: POIData) -> POIData:
	if poi.is_city() or poi.parent_city == "" or current_data == null:
		return poi
	var c := _find_poi(current_data, poi.parent_city)
	return c if c != null else poi

## Spins the globe to the middle of a City and its districts and zooms in so
## their icons show (CITY_FOCUS_ZOOM; never zooms back out if already closer).
func _focus_city(city: POIData) -> void:
	if city == null or current_data == null:
		return
	var sum := Vector3.ZERO
	for p: POIData in current_data.custom_pois:
		if p == city or (p.parent_city == city.label and not p.is_orbital()):
			var lon := deg_to_rad(p.lon_deg)
			var lat := deg_to_rad(p.lat_deg)
			sum += Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
	if sum.length_squared() < 1e-6:
		return
	var n := sum.normalized()
	var lon_c := rad_to_deg(atan2(n.z, n.x))
	var lat_c := rad_to_deg(asin(clampf(n.y, -1.0, 1.0)))
	AudioManager.play("click")
	_focus_on_site(lon_c, lat_c, 0.5)
	# Anchor on the globe's centre so the zoom doesn't fight the spin.
	_set_zoom_target(maxf(_zoom_target, CITY_FOCUS_ZOOM),
		planet_renderer.global_position + planet_renderer.size * 0.5)

## pm_key -> { "fill": Control, "prog": Array[float] }
var _bar_meta: Dictionary = {}
var _active_slot_dropdown: Control = null
var _dd_layer: CanvasLayer = null  # CanvasLayer overlay for slot dropdown (always on top)

func _is_at_edge() -> bool:
	var mouse := get_viewport().get_mouse_position()
	var vp    := get_viewport().get_visible_rect().size
	const EDGE := 40.0
	return mouse.x < EDGE or mouse.y < EDGE or mouse.x > vp.x - EDGE or mouse.y > vp.y - EDGE

## "+146 cr" rises from the district that made it and follows the globe as it
## turns (hidden while that side faces away). Nothing shows for output without a district.
func _on_resource_produced(planet_seed: int, poi_label: String, text: String, color: Color, icon: Texture2D) -> void:
	if current_data == null or current_data.seed != planet_seed:
		return
	var poi := _find_poi(current_data, poi_label)
	if poi != null and not poi.is_orbital():
		poi_layer.spawn_floating_text(poi.lon_deg, poi.lat_deg, text, color, 14, icon)
	if _active_district_poi != null:
		_refresh_district_energy_lbl()

func _on_production_update(_planet_seed: int, key: String, progress: float) -> void:
	if _district_pbars.has(key):
		var pbar: ProgressBar = _district_pbars[key]
		if is_instance_valid(pbar):

			pbar.value = progress * 100.0
		else:
			print("[UI Debug] pbar is invalid for ", key)
	else:
		if " " in key: # naive check for district names to see if we missed it
			pass

	if not _bar_meta.has(key):
		return
	var m: Dictionary = _bar_meta[key]
	if m.has("prog"):
		(m["prog"] as Array)[0] = progress
	var fc: Control = m.get("fill", null)
	if is_instance_valid(fc):
		fc.queue_redraw()
	# Update percent label on construction bars only — status label updates via building_ticked
	if m.get("construction", false) and m.has("pct"):
		var pct: Label = m["pct"]
		if is_instance_valid(pct):
			pct.text = "%d%%" % int(progress * 100)

func _on_building_ticked_night(planet_seed: int, key: String) -> void:
	if current_data != null and current_data.seed == planet_seed:
		_update_poi_night_sizes(current_data)
		_refresh_poi_lights(current_data)
	if _bar_meta.has(key):
		var fc: Control = _bar_meta[key]["fill"]
		if is_instance_valid(fc):
			fc.queue_redraw()
		_refresh_bar_label_status(key)
		
	# Energy ratio can change when any building starts/stops.
	# Refresh all slowed_lbl visibilities for the whole planet to ensure UI consistency.
	var er := ProductionManager.get_energy_ratio(planet_seed)
	for k: String in _bar_meta:
		var m: Dictionary = _bar_meta[k]
		if m.get("planet_seed", -1) == planet_seed:
			var sl: Label = m.get("slowed_lbl", null)
			if is_instance_valid(sl):
				var paused      := ProductionManager.is_paused(k)
				var user_paused := ProductionManager.is_user_paused(k)
				sl.text    = "⚡ Slowed %d%% — Energy Crisis" % [int((1.0 - er) * 100)]
				sl.visible = not paused and not user_paused and er < 0.999
			_refresh_bar_label_status(k)

	_refresh_district_energy_lbl()

var _active_district_energy_lbl: Label = null

func _fmt_energy(val: float) -> String:
	var s := "+" if val >= 0.0 else ""
	if absf(val - roundf(val)) > 0.01:
		return s + "%.1f ⚡" % val
	return s + "%.0f ⚡" % val

func _refresh_district_energy_lbl() -> void:
	if not is_instance_valid(_active_district_energy_lbl):
		return
	if current_data == null or _active_district_poi == null:
		return
	var pp := GameState.get_planet(current_data.seed)
	var breakdown := _planet_energy_breakdown(pp, current_data)
	var d_energy: float = breakdown.get(_active_district_poi.label, 0.0)
	_active_district_energy_lbl.text = _fmt_energy(d_energy)
	_active_district_energy_lbl.add_theme_color_override("font_color",
		Color(0.85, 0.78, 0.22) if d_energy >= 0.0 else Color(0.85, 0.38, 0.25))

func _on_building_toggled(key: String, _paused: bool) -> void:
	if not _bar_meta.has(key):
		return
	var fc: Control = _bar_meta[key].get("fill", null)
	if fc != null and is_instance_valid(fc):
		fc.queue_redraw()
	_refresh_bar_label_status(key)

func _refresh_bar_label_status(key: String) -> void:
	if not _bar_meta.has(key):
		return
	var m: Dictionary = _bar_meta[key]
	if m.get("construction", false):
		return
	# Spaceport stub — no live labels to refresh
	if not m.has("out_lbl"):
		return
	var out_lbl: Label = m.get("out_lbl", null)
	var def: BuildingDef = m.get("def", null)
	var fc: Color = m.get("fc", Color.WHITE)
	if is_instance_valid(out_lbl) and def != null:
		var paused := ProductionManager.is_paused(key)
		var out_text := "⏸ waiting"
		if ProductionManager.is_storage_full(key):
			out_text = "▣ storage full"
		elif not paused:
			var r_pp: PlanetProgress = GameState.get_planet(m.get("planet_seed", -1))
			if r_pp != null:
				out_text = _entry_output_text(r_pp, m.get("entry", {}), def)
		out_lbl.text = out_text
		out_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.48, 0.60) if paused else fc)

		var slowed_lbl: Label = m.get("slowed_lbl", null)
		if is_instance_valid(slowed_lbl):
			var er := ProductionManager.get_energy_ratio(m.get("planet_seed", -1))
			slowed_lbl.text    = "⚡ Slowed %d%% — Energy Crisis" % [int((1.0 - er) * 100)]
			var is_user_paused := ProductionManager.is_user_paused(key)
			slowed_lbl.visible = not paused and not is_user_paused and er < 0.999

func _on_building_constructed(planet_seed: int, key: String, _building_id: String = "") -> void:
	if current_data == null or current_data.seed != planet_seed:
		return
	AudioManager.play("building_done")

	# Parse key format: "{seed}:{poi_label}:{idx}"
	var last_col  := key.rfind(":")
	var first_col := key.find(":")
	var building_name := ""
	var poi_label     := ""
	if last_col > first_col and first_col >= 0:
		var uid       := key.substr(last_col + 1)
		poi_label      = key.substr(first_col + 1, last_col - first_col - 1)
		var pp := GameState.get_planet(planet_seed)
		if pp != null:
			var entry: Dictionary = {}
			for b in pp.buildings:
				if b.get("uid", "-1") == uid:
					entry = b
					break
			if not entry.is_empty():
				var def   := BuildingDef.find(entry.get("building_id", ""))
				if def != null:
					building_name = def.display_name

	# Always show a toast — never auto-select / reopen the district.
	_show_construction_toast(
		building_name if building_name != "" else "Building",
		poi_label)

	# If a spaceport just finished construction, mark planet and refresh ships
	var pp_check := GameState.get_planet(planet_seed)
	if pp_check != null and not pp_check.has_spaceport:
		var pp_buildings: Array = pp_check.buildings
		for eb: Dictionary in pp_buildings:
			if eb.get("building_id", "") == "spaceport" and not eb.get("constructing", false):
				pp_check.has_spaceport = true
				break

	_refresh_overview_energy()

	# Keep station ship.buildings in sync when construction completes
	_sync_station_buildings()

	# Refresh panel only if the player is actively viewing that specific district.
	if _active_district_poi == null:
		return
	if poi_label != "" and _active_district_poi.label != poi_label:
		return   # completed in a different district — don’t switch view
	_build_district_panel(_active_district_poi, current_data)

func _refresh_overview_energy() -> void:
	if not is_instance_valid(_overview_energy_val) or current_data == null:
		return
	var pp := GameState.get_planet(current_data.seed)
	if pp == null:
		return
	var e_breakdown := _planet_energy_breakdown(pp, current_data)
	var bal: float   = e_breakdown.get("total", 0.0)
	var sign := "+" if bal >= 0.0 else ""
	_overview_energy_val.text = sign + "%.0f ⚡" % bal
	_overview_energy_val.add_theme_color_override("font_color",
		Color(0.9, 0.82, 0.25) if bal >= 0.0 else Color(0.9, 0.40, 0.28))

## Starts a rocket launch animation. Multiple can run concurrently.
func _play_rocket_animation(planet_seed: int, poi: POIData, on_complete: Callable,
		sp_pm_key: String = "", ship_name: String = "Pioneer", ship_type: String = "shuttle",
		ship_cargo: Dictionary = {}, destination_ship_id: String = "",
		transfer_dir: String = "", transfer_resource: String = "", transfer_amount: int = 0,
		auto_land: bool = false, mission_tasks: Array = [],
		station_district_poi: POIData = null) -> void:
	var container: Control = planet_renderer.get_parent()
	var planet_r:  float   = planet_renderer._planet_radius_px
	const ORBIT_FRAC:       float = 1.06
	const BASE_LAUNCH_DUR:  float = 22.0   # seconds at reference planet radius
	const REF_RADIUS:       float = 200.0
	const LAUNCH_TIME_SCALE: float = 1.0   # hook here for upgrade (lower = faster)
	# zoom-independent: the globe's on-screen size grows with zoom, the flight doesn't
	var launch_dur: float = (planet_r / maxf(_zoom, 0.01) / REF_RADIUS) * BASE_LAUNCH_DUR * LAUNCH_TIME_SCALE

	# For orbital district POIs, sync construct_duration to the exact animation time
	const _DEPLOY_ANIM_DUR: float = 2.2
	if station_district_poi != null:
		station_district_poi.construct_duration = launch_dur + _DEPLOY_ANIM_DUR

	# Planet center — same reference as POILayer (_planet.global_position + size*0.5)
	var planet_center_global: Vector2 = planet_renderer.global_position + planet_renderer.size * 0.5
	var center_local:         Vector2 = planet_center_global - container.get_global_rect().position

	# POI lon/lat for positioning (POILayer formula: x=sin(lon-rot)*cos(lat), y=-sin(lat))
	var poi_lon:   float = 0.0
	var poi_lat:   float = 0.0
	var start_r:   float = planet_r
	if poi != null and poi_layer != null and is_instance_valid(poi_layer):
		var ll: Vector2 = poi_layer.get_poi_lon_lat(poi.label)
		poi_lon = ll.x
		poi_lat = ll.y
		var p: Dictionary = poi_layer._get_planet_params()
		if not p.is_empty():
			start_r = p.get("r_px", planet_r)

	# Orbit insertion point: random by default, intercepted to destination if set.
	var sweep_target: float = randf_range(PI * 0.15, PI * 0.75) * (1.0 if randf() > 0.5 else -1.0)
	var sweep_sign:   float = sign(sweep_target)
	var lat_target:   float = randf_range(-PI * 0.35, PI * 0.35)

	# Predictive intercept — aim for where the station will be when we arrive.
	if destination_ship_id != "":
		var dest: ShipData = null
		for s: ShipData in ShipManager.ships_for(planet_seed):
			if s.ship_id == destination_ship_id:
				dest = s; break
		if dest != null:
			var rot_at_launch: float = planet_renderer.get_rotation_offset()
			var pred_a: float = dest.orbit_angle + dest.orbit_speed * launch_dur
			var inc: float    = dest.orbit_inclination
			var rot: float    = rot_at_launch + dest.orbit_node
			# Project predicted station position (unit-radius normalized)
			var px: float = cos(pred_a)
			var py: float = sin(pred_a) * sin(inc)
			var pz: float = sin(pred_a) * cos(inc)
			var nx: float = px * cos(rot) + pz * sin(rot)
			var ny: float = py
			# Reverse the launch math:  ty = -sin(lat_final), tx = sin(lon_final)*cos(lat_final)
			lat_target   = -asin(clampf(ny, -1.0, 1.0))
			var cos_lat: float = cos(lat_target)
			if abs(cos_lat) > 0.01:
				var sin_lon: float = clampf(nx / cos_lat, -1.0, 1.0)
				var lon1: float = asin(sin_lon)
				var lon2: float = PI - lon1
				var sw1: float  = wrapf(lon1 - poi_lon + rot_at_launch, -PI, PI)
				var sw2: float  = wrapf(lon2 - poi_lon + rot_at_launch, -PI, PI)
				sweep_target = sw1 if absf(sw1) < absf(sw2) else sw2
				sweep_sign   = sign(sweep_target)
			print("[INTERCEPT] pred_a=%.2f° target sweep=%.1f° lat=%.1f°" % [
				rad_to_deg(pred_a), rad_to_deg(sweep_target), rad_to_deg(lat_target)])

	# ── Rocket node ──────────────────────────────────────────────────────────────
	var rocket := Control.new()
	rocket.mouse_filter = Control.MOUSE_FILTER_STOP
	rocket.z_index      = 12
	rocket.custom_minimum_size = Vector2(16, 16)
	container.add_child(rocket)

	# Set initial position directly from POI screen pos — no formula conversion needed
	if poi != null and poi_layer != null and is_instance_valid(poi_layer):
		var poi_global: Vector2 = poi_layer.get_poi_screen_pos(poi.label)
		if poi_global != Vector2.ZERO:
			rocket.position = poi_global - container.get_global_rect().position

	# anim_d will be set after dict creation below; use Array wrapper for closure capture
	var anim_ref: Array[Dictionary] = []
	rocket.draw.connect(func() -> void:
		if anim_ref.is_empty():
			return
		var ad: Dictionary = anim_ref[0]
		var flame_a:      float = ad.get("flame_alpha", 1.0)
		var boosters_gone: bool = ad.get("boosters_spawned", false)
		var travel: Vector2 = ad.get("travel_dir", Vector2.UP)
		var exhaust_dir: Vector2 = -travel
		if flame_a > 0.01 and not boosters_gone:
			var e := exhaust_dir
			var b1 := (e * 4.0).floor()
			var b2 := (e * 7.0).floor()
			var b3 := (e * 10.0).floor()
			var hue: float = 0.45 + randf() * 0.25
			rocket.draw_rect(Rect2(b1, Vector2(2, 2)), Color(1.0, hue, 0.05, flame_a * 0.95))
			rocket.draw_rect(Rect2(b2, Vector2(2, 2)), Color(1.0, hue * 0.6, 0.02, flame_a * 0.55))
			rocket.draw_rect(Rect2(b3, Vector2(1, 1)), Color(1.0, 0.3, 0.0,  flame_a * 0.25))
		var col  := Color(1, 1, 1, 0.95)
		var p    := Vector2.ZERO
		var stype: String = ad.get("ship_type", "shuttle")
		if stype == "station":
			# Station: 3×3 core + solar panel wings (hidden until boosters gone)
			var core_col   := Color(0.85, 0.90, 1.0, 0.95)
			var panel_col  := Color(0.30, 0.60, 1.0, 0.90)
			rocket.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(6, 6)), core_col)
			if boosters_gone:
				# Solar panels extend once boosters are dropped
				rocket.draw_rect(Rect2(p + Vector2(-8, 0), Vector2(6, 2)), panel_col)
				rocket.draw_rect(Rect2(p + Vector2( 4, 0), Vector2(6, 2)), panel_col)
		else:
			# Shuttle: slightly larger cross sprite
			if boosters_gone:
				rocket.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p + Vector2( 2, -2), Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p,                   Vector2(2, 2)), col)
			else:
				rocket.draw_rect(Rect2(p,                   Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p + Vector2(-2,  0), Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p + Vector2( 2,  0), Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p + Vector2( 0, -2), Vector2(2, 2)), col)
				rocket.draw_rect(Rect2(p + Vector2( 0,  2), Vector2(2, 2)), col)
				# Extra pixel to make it feel slightly bigger than before
				rocket.draw_rect(Rect2(p + Vector2(-2, -2), Vector2(2, 2)), Color(col, 0.55))
				rocket.draw_rect(Rect2(p + Vector2( 2, -2), Vector2(2, 2)), Color(col, 0.55)))

	var lbl := Label.new()
	var eta_secs: int = int(ceil(launch_dur))
	lbl.text = "eta %02d:%02d" % [eta_secs / 60, eta_secs % 60]
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(lbl, 7)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0, 0.80))
	lbl.position = Vector2(6, -5)
	rocket.add_child(lbl)

	var anim_d: Dictionary = {
		"rocket":          rocket,
		"container":       container,
		"center_local":    center_local,
		"planet_r_frac":   start_r / maxf(planet_r, 1.0),
		"anim_r":          start_r,
		"poi_lon":      poi_lon,
		"poi_lat":      poi_lat,
		"lon_sweep":    0.0,
		"lat_sweep":    0.0,
		"sweep_target": sweep_target,
		"lat_target":   lat_target,
		"sweep_sign":   sweep_sign,
		"flame_alpha":     1.0,
		"phase":           0,
		"phase_t":         0.0,
		"planet_seed":     planet_seed,
		"launch_dur":      launch_dur,
		"eta_lbl":         lbl,
		"hover_active":    false,
		"on_complete":     on_complete,
		"sp_pm_key":       sp_pm_key,
		"ship_name":            ship_name,
		"ship_type":            ship_type,
		"ship_cargo":           ship_cargo,
		"destination_ship_id":  destination_ship_id,
		"transfer_dir":         transfer_dir,
		"transfer_resource":    transfer_resource,
		"transfer_amount":      transfer_amount,
		"auto_land":            auto_land,
		"mission_tasks":        mission_tasks,
		"station_district_poi": station_district_poi,
	}
	anim_ref.append(anim_d)
	_rocket_anims.append(anim_d)
	AudioManager.play("rocket", -4.0)

	# Make rocket clickable — show a lightweight launch info panel
	rocket.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	rocket.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	rocket.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_show_launch_info_panel(anim_ref[0], container))

## Launch / deploy animations project with the tilt: the globe stays free to tilt.
const TILT_FOLLOWS_LAUNCHES := true
## A launch older than this no longer holds the camera tilt.
const TILT_LOCK_MAX_SEC := 45.0

func _tilt_lock_needed() -> bool:
	# launches and deploys now project with the camera tilt — nothing to lock
	if TILT_FOLLOWS_LAUNCHES:
		return false
	for d: Dictionary in _rocket_anims:
		if float(d.get("_age", 0.0)) < TILT_LOCK_MAX_SEC and is_instance_valid(d.get("rocket", null)) \
				and (d["rocket"] as Control).visible:
			return true
	for da: Dictionary in _deploy_anims:
		if float(da.get("t", 0.0)) < float(da.get("duration", 0.0)) and is_instance_valid(da.get("ctrl", null)):
			return true
	return false

## Called every _process frame while any rocket animations are active.
func _tick_rocket_anim(delta: float) -> void:
	var done: Array[Dictionary] = []
	for d: Dictionary in _rocket_anims:
		d["_age"] = float(d.get("_age", 0.0)) + delta
		if not is_instance_valid(d.get("rocket")):
			done.append(d)
			continue
		_tick_one_rocket(d, delta)
		if d.get("_finished", false):
			done.append(d)
	for d: Dictionary in done:
		_rocket_anims.erase(d)

func _tick_one_rocket(d: Dictionary, delta: float) -> void:
	if not is_instance_valid(d.get("rocket")):
		return
	var rocket: Control = d["rocket"]

	var phase: int   = d["phase"]
	var t:     float = d["phase_t"]

	# Planet radius fresh each tick (handles window resize)
	var planet_r: float = planet_renderer._planet_radius_px
	var orbit_r:  float = planet_r * 1.06
	var start_r:  float = d["planet_r_frac"] * planet_r

	# Two sub-phases within phase 0, each 0→1:
	# Sub-phase A (t < 0.5): radial rise using POILayer formula (starts at exact district pos)
	# Sub-phase B (t ≥ 0.5): circularise — lerp from rise-end to orbital insert point
	# Both endpoints re-computed each tick so planet drag rotates everything correctly.

	var LAUNCH_DUR: float = d["launch_dur"]

	# Speed profile: sin curve — accelerates to peak at t=0.5, then decelerates to 0.
	# lon_sweep uses integral of sin: 0.5*(1-cos(t*PI)) → smooth S from 0 to sweep_target.
	# radius uses same curve (ease in+out together).
	var finished := false
	match phase:
		0:
			t += delta / LAUNCH_DUR
			if t >= 1.0:
				t = 1.0
				finished = true
			d["phase_t"] = t
			# Drive orbital district progress bar from rocket t (launch takes ~91% of total)
			const _DEPLOY_DUR: float = 2.2
			var _st_poi: POIData = d.get("station_district_poi", null)
			if _st_poi != null and _st_poi.constructing:
				var _launch_frac: float = LAUNCH_DUR / (LAUNCH_DUR + _DEPLOY_DUR)
				_st_poi.construct_progress = t * _launch_frac
			var _eta_sec: int = int(ceil((1.0 - t) * LAUNCH_DUR))
			if is_instance_valid(d.get("eta_lbl")):
				(d["eta_lbl"] as Label).text = "eta %02d:%02d" % [_eta_sec / 60, _eta_sec % 60]

			# Speed profile: ease-in [0→0.5], then linear decel to CRUISE_FRAC of peak [0.5→1].
			# Normalized so curve reaches exactly 1.0 at t=1 (no stopping short).
			# CRUISE_FRAC = velocity at orbit entry as fraction of peak.
			const CRUISE_FRAC: float = 0.10
			const D: float = (1.0 + CRUISE_FRAC) * 0.5
			var curve: float
			if t <= 0.5:
				# Quadratic ease-in: slow initial ramp, constant acceleration feel.
				# Lower initial jerk than sine (28% of sine's initial acceleration).
				curve = 2.0 * t * t
			else:
				var u: float     = (t - 0.5) / 0.5
				var integ: float = u - u * u * (1.0 - CRUISE_FRAC) * 0.5
				curve = 0.5 + (integ / D) * 0.5
			d["anim_r"]      = lerpf(start_r, orbit_r, curve)
			d["lon_sweep"]   = d["sweep_target"] * curve
			d["lat_sweep"]   = (d["lat_target"] - d["poi_lat"]) * curve
			d["flame_alpha"] = clampf(1.0 - t / 0.5, 0.0, 1.0) if t < 0.5 else 0.0

			# Booster separation particles at peak speed (t crosses 0.5)
			if not d.get("boosters_spawned", false) and t >= 0.5:
				d["boosters_spawned"] = true
				var lon_deg_bp := rad_to_deg(d["poi_lon"] + d["lon_sweep"])
				var lat_deg_bp := rad_to_deg(d["poi_lat"] + d["lat_sweep"])
				poi_layer.spawn_floating_text(lon_deg_bp, lat_deg_bp, "Booster dropped!", Color(0.95, 0.45, 0.15), 11)
				
				d["booster_particles"] = []
				var rot_bp:  float   = planet_renderer.get_rotation_offset()
				var lon_bp:  float   = d["poi_lon"] + d["lon_sweep"] - rot_bp
				var lat_bp:  float   = d["poi_lat"] + d["lat_sweep"]
				# abs_lon = planet-fixed longitude (no rot offset), so particle co-rotates with planet.
				var abs_lon_bp: float = d["poi_lon"] + d["lon_sweep"]
				var r_bp:       float = d["anim_r"]
				var vel_dir: Vector2 = Vector2(
					cos(lon_bp)*cos(lat_bp)*d["sweep_target"],
					-cos(lat_bp)*(d["lat_target"]-d["poi_lat"])
				).normalized()
				var perp: Vector2 = Vector2(-vel_dir.y, vel_dir.x)
				var is_station: bool = d.get("ship_type", "shuttle") == "station"
				var booster_signs: Array = [1.0, -1.0, 0.0, 0.3] if is_station else [1.0, -1.0]
				for sp: float in booster_signs:
					# Backward + lateral spread so both boosters separate visibly
					var vel_px: Vector2 = (-vel_dir * 0.7 + perp * sp * 0.7).normalized() * 10.0
					var bp_angle: float = atan2(-vel_dir.y, -vel_dir.x)
					var bp_data: Dictionary = {
						"abs_lon": abs_lon_bp,
						"lat":     lat_bp,
						"vel_lon": vel_px.x / r_bp,
						"vel_lat": -vel_px.y / r_bp,
						"r":       r_bp,
						"angle":   bp_angle,
						"alpha":   1.0
					}
					var bp_node := Control.new()
					bp_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
					bp_node.z_index = 11
					bp_node.size    = Vector2(4, 4)
					d["container"].add_child(bp_node)
					bp_data["node"] = bp_node
					var bp_ref: Dictionary = bp_data
					bp_node.draw.connect(func() -> void:
						if bp_ref["alpha"] > 0.0:
							var a: float = bp_ref["angle"]
							bp_node.draw_set_transform(Vector2.ZERO, a, Vector2.ONE)
							bp_node.draw_rect(Rect2(Vector2(-3, -1), Vector2(6, 2)),
								Color(1.0, 1.0, 1.0, bp_ref["alpha"]))
							bp_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
					d["booster_particles"].append(bp_data)

	# ── Tick booster particles ────────────────────────────────────────────────────
	if d.get("booster_particles") != null:
		var alive: Array = []
		var bp_center: Vector2 = planet_renderer.global_position + planet_renderer.size * 0.5 \
			- d["container"].get_global_rect().position
		var decay: float = pow(0.85, delta * 60.0)
		for bp: Dictionary in d["booster_particles"]:
			bp["abs_lon"] += bp["vel_lon"] * delta
			bp["lat"]     += bp["vel_lat"] * delta
			bp["vel_lon"] *= decay
			bp["vel_lat"] *= decay
			bp["alpha"]   -= delta * 0.55
			if bp["alpha"] > 0.0:
				var bv: Vector3 = planet_renderer.lonlat_to_view(bp["abs_lon"], bp["lat"])
				var r_bp:       float = bp["r"]
				if bp.get("node") != null and is_instance_valid(bp["node"]):
					bp["node"].position = bp_center + Vector2(bv.x, bv.y) * r_bp
					bp["node"].queue_redraw()
				alive.append(bp)
			else:
				if bp.get("node") != null and is_instance_valid(bp["node"]):
					bp["node"].queue_free()
		d["booster_particles"] = alive

	# Same projection as POILayer (spin and camera tilt), so the rocket stays on
	# its pad and its path while the globe is turned or tilted
	var lat:     float   = d["poi_lat"] + d["lat_sweep"]
	var r:       float   = d["anim_r"]
	var view:    Vector3 = planet_renderer.lonlat_to_view(d["poi_lon"] + d["lon_sweep"], lat)
	# its last two surface points: the lander's orbit carries on from them
	var abs_now := Vector2(float(d["poi_lon"]) + float(d["lon_sweep"]), lat)
	if d.has("last_abs") and (d["last_abs"] as Vector2).distance_to(abs_now) > 1e-5:
		d["prev_abs"] = d["last_abs"]
	d["last_abs"] = abs_now
	# Re-derive center each frame so it stays in sync with OrbitalLayer._planet_center.
	var center:  Vector2 = planet_renderer.global_position + planet_renderer.size * 0.5 \
		- d["container"].get_global_rect().position
	d["center_local"] = center
	var offset:  Vector2 = Vector2(view.x, view.y) * r
	var prev_rpos: Vector2 = d.get("prev_rocket_pos", center + offset)
	rocket.position = center + offset
	# Travel direction: from previous position to current (velocity vector)
	var travel_delta: Vector2 = rocket.position - prev_rpos
	if travel_delta.length() > 0.1:
		d["travel_dir"] = travel_delta.normalized()
	d["prev_rocket_pos"] = rocket.position

	# ── Occlusion: hide when behind planet ────────────────────────────────────────
	var depth: float = view.z
	rocket.visible = not (depth < -0.05 and offset.length() < planet_r * 0.99)

	rocket.queue_redraw()

	# ── Hover tooltip ────────────────────────────────────────────────────────────
	var ctr2: Control = d["container"]
	var mp:   Vector2 = get_viewport().get_mouse_position()
	var rp:   Vector2 = ctr2.get_global_rect().position + rocket.position
	var near: bool    = mp.distance_to(rp) < 12.0
	if near and not d["hover_active"]:
		d["hover_active"] = true
		CursorManager.set_state(CursorManager.State.POINTER)
		if String(d.get("ship_type", "")) == "lander":
			TooltipManager.show_tip("Colony Lander", "· lifting off from the Spaceport\nDouble-click to follow it")
		else:
			TooltipManager.show_tip("Shuttle", "· launching to orbit")
	elif not near and d["hover_active"]:
		d["hover_active"] = false
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip()

	if finished:
		_finish_rocket_anim(d)
		return

## Same projection formula as OrbitalLayer._project, returns 2D screen offset from center.
func _orbital_project_2d(angle: float, inc: float, r: float, rot: float) -> Vector2:
	var px: float = r * cos(angle)
	var py: float = r * sin(angle) * sin(inc)
	var pz: float = r * sin(angle) * cos(inc)
	var rx: float = px * cos(rot) + pz * sin(rot)
	return Vector2(rx, py)

## Finds the orbit_angle whose screen projection is closest to the given offset.
## Numerical search: 720 coarse samples + 100 fine refinement steps.
func _find_orbit_angle_for_pos(target: Vector2, inc: float, r: float, rot: float) -> float:
	const COARSE: int = 720
	var best_a: float = 0.0
	var best_d: float = INF
	for i in COARSE:
		var a: float   = i * TAU / COARSE
		var d: float   = (_orbital_project_2d(a, inc, r, rot) - target).length_squared()
		if d < best_d:
			best_d = d
			best_a = a
	# Refine around best_a
	var step: float = TAU / COARSE
	for i in 100:
		var a: float = best_a + (i - 50) * step * 0.02
		var d: float = (_orbital_project_2d(a, inc, r, rot) - target).length_squared()
		if d < best_d:
			best_d = d
			best_a = a
	return best_a

## Called when fade phase ends — spawns ship and clears animation state.
func _finish_rocket_anim(d: Dictionary) -> void:
	var rocket: Control = d["rocket"] if is_instance_valid(d.get("rocket")) else null
	var container: Control = d["container"]

	var rocket_screen_pos: Vector2 = Vector2.ZERO
	if rocket != null and is_instance_valid(rocket):
		rocket_screen_pos = rocket.position   # position relative to container
		rocket.queue_free()
	TooltipManager.hide_tip()
	CursorManager.set_state(CursorManager.State.NORMAL)

	var rot_now: float = planet_renderer.get_rotation_offset()
	var orbit_r: float = planet_renderer._planet_radius_px * 1.06

	# Compute insertion point analytically at t=1 — avoids reading rocket.position
	# from the previous frame (t<1) which caused a visible teleport on spawn.
	var lon_final: float = d["poi_lon"] + d["sweep_target"] - rot_now
	var lat_final: float = d["lat_target"]
	
	var lon_deg := rad_to_deg(d["poi_lon"] + d["sweep_target"])
	var lat_deg := rad_to_deg(lat_final)
	if d.get("destination_ship_id", "") == "":
		poi_layer.spawn_floating_text(lon_deg, lat_deg, "Orbit reached!", Color(0.15, 0.95, 0.45), 11)
	var tx: float = sin(lon_final) * cos(lat_final)   # normalised
	var ty: float = -sin(lat_final)

	# Analytical 3-DOF solution: orbit_angle + orbit_inc + orbit_node
	# gives EXACT position AND correct tangent direction simultaneously.
	#
	# Fix a = ±π/2 (tangent is purely horizontal at these points):
	#   a = -π/2 → tangent = (+cos(R), 0), matches sweep going right
	#   a = +π/2 → tangent = (-cos(R), 0), matches sweep going left
	# where R = rot_now + node.
	#
	# Then solve inc and node from position equations at the chosen a.
	var sweep_s: float = d["sweep_sign"]

	# a = ±π/2 → tangent is purely horizontal, matches rocket's sweep direction.
	# a = -π/2: tangent = (+cos(R), 0) → sweep right
	# a = +π/2: tangent = (-cos(R), 0) → sweep left
	var orbit_angle: float
	var orbit_inc:   float
	var orbit_node:  float

	# Full 3-DOF insertion that places the ship EXACTLY at the rocket's screen endpoint:
	#
	#   orbit_angle a = atan2(-ty, tx)
	#   orbit_inc  i  such that sin(a)*sin(i) = ty  →  i = arcsin(ty/sin(a))
	#   orbit_node n  such that cos(a)*cos(rot)+ty*sin(rot) = tx  →  solve for rot = rot_now+n
	#
	# _project uses rot = _planet_rotation + orbit_node, so at spawn (planet_rotation=rot_now)
	# we need rot_eff = rot_now + orbit_node → orbit_node = rot_eff - rot_now.
	orbit_angle = atan2(-ty, tx)

	var sin_a: float = sin(orbit_angle)
	if abs(sin_a) > 0.001:
		orbit_inc = asin(clampf(ty / sin_a, -1.0, 1.0))
	else:
		orbit_inc = 0.0

	# Solve: cos(a)*cos(rot) + sin(a)*cos(inc)*sin(rot) = tx
	# Two solutions exist; pick the one where rz < 0 (ship on front/visible side of planet).
	# rz = -cos(a)*sin(rot) + sin(a)*cos(inc)*cos(rot)
	var ca: float  = cos(orbit_angle)
	var sc: float  = sin(orbit_angle) * cos(orbit_inc)
	var mag: float = sqrt(ca * ca + sc * sc)
	if mag > 0.001:
		var phi: float  = atan2(sc, ca)
		var arc: float  = acos(clampf(tx / mag, -1.0, 1.0))
		var re1: float  = rot_now + wrapf(phi + arc - rot_now, -PI, PI)
		var re2: float  = rot_now + wrapf(phi - arc - rot_now, -PI, PI)
		var rz1: float  = -ca * sin(re1) + sc * cos(re1)
		var rz2: float  = -ca * sin(re2) + sc * cos(re2)
		# Prefer the solution that puts ship on front side (rz < 0)
		var use_re: float
		if rz1 < 0.0 and rz2 >= 0.0:
			use_re = re1
		elif rz2 < 0.0 and rz1 >= 0.0:
			use_re = re2
		else:
			# Both same side — pick smallest orbit_node deviation
			var n1: float = wrapf(re1 - rot_now, -PI, PI)
			var n2: float = wrapf(re2 - rot_now, -PI, PI)
			use_re = re1 if absf(n1) < absf(n2) else re2
		orbit_node = wrapf(use_re - rot_now, -PI, PI)
	else:
		orbit_node = 0.0

	var rdx_raw: float   = d["sweep_sign"] * cos(lat_final)
	var eff_rot2: float  = rot_now + orbit_node
	var p1: Vector2      = _orbital_project_2d(orbit_angle,         orbit_inc, orbit_r, eff_rot2)
	var p2: Vector2      = _orbital_project_2d(orbit_angle + 0.002, orbit_inc, orbit_r, eff_rot2)
	var speed_sign: float = 1.0 if (p2 - p1).x * rdx_raw >= 0.0 else -1.0
	const _CF: float = 0.10
	const _D:  float = (1.0 + _CF) * 0.5
	var _LD: float = d["launch_dur"]
	var exit_rate: float = (_CF / _D) * (2.0 / _LD)

	var st_poi: POIData = d.get("station_district_poi", null)
	if st_poi != null:
		# Orbital district — update POI with analytically computed orbit params
		st_poi.orbit_angle       = orbit_angle
		st_poi.orbit_inclination = orbit_inc
		st_poi.orbit_node        = orbit_node
		st_poi.orbit_speed       = speed_sign * exit_rate
		st_poi.orbit_radius      = 1.06
		if _orbital_layer != null and is_instance_valid(_orbital_layer):
			_spawn_station_deploy_poi(st_poi, d["container"], d["on_complete"])
			_orbital_layer.queue_redraw()
		d["_finished"] = true
		return  # on_complete called by _spawn_station_deploy_poi when anim ends
	else:
		var ship := ShipManager.launch(d["planet_seed"], d.get("ship_name", "Pioneer"))
		ship.ship_type         = d.get("ship_type", "shuttle")
		ship.cargo             = d.get("ship_cargo", {})
		ship.orbit_angle       = orbit_angle
		ship.orbit_inclination = orbit_inc
		ship.orbit_node        = orbit_node
		ship.orbit_speed       = speed_sign * exit_rate
		if ship.ship_type == "lander":
			_fit_lander_orbit(ship, d)
		if _orbital_layer != null and is_instance_valid(_orbital_layer):
			_orbital_layer.queue_redraw()
		var tasks: Array = d.get("mission_tasks", [])
		ship.mission_tasks      = tasks.duplicate(true)
		ship.mission_task_index = 0
		var _skip_types: Array = ["move_orbit", "pick_planet"]
		while ship.mission_task_index < ship.mission_tasks.size() \
				and _skip_types.has((ship.mission_tasks[ship.mission_task_index] as Dictionary).get("type", "")):
			ship.mission_task_index += 1
		_advance_mission(ship)
		if ship.ship_type == "station" and _orbital_layer != null:
			_spawn_station_deploy(ship, d["container"])

	var cb: Callable = d["on_complete"]
	d["_finished"] = true
	cb.call()

# ── Station deploy animation ──────────────────────────────────────────────────

## Spawns a short solar-panel deploy animation at the ship's initial orbit position.
func _spawn_station_deploy(ship: ShipData, container: Control) -> void:
	if _orbital_layer == null or not is_instance_valid(_orbital_layer):
		return
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.z_index = 10
	container.add_child(ctrl)
	var da: Dictionary = {
		"ship":     ship,
		"ctrl":     ctrl,
		"t":        0.0,
		"duration": 2.2,
	}
	ctrl.draw.connect(func() -> void:
		var sv2 := _orbital_layer._project(ship, ship.orbit_angle)
		if _orbital_layer._is_occluded(sv2):
			return
		var origin: Vector2 = _orbital_layer._planet_center + Vector2(sv2.x, sv2.y)
		var p2 := ctrl.get_global_transform().affine_inverse() * origin
		var t2: float = da.get("t", 0.0)
		var progress: float = clampf(t2 / da["duration"], 0.0, 1.0)
		var ease_p: float   = ease(progress, -2.0)  # ease-out
		var alpha: float    = 1.0 - clampf((progress - 0.7) / 0.3, 0.0, 1.0)

		# Core remains visible throughout
		var core_col := Color(0.85, 0.90, 1.0, alpha)
		ctrl.draw_rect(Rect2(p2 + Vector2(-2,-2), Vector2(6,6)), core_col)

		# Panels extend outward as progress increases
		var panel_ext: float = ease_p * 10.0
		var panel_col2 := Color(0.30, 0.60, 1.0, alpha * 0.85)
		if panel_ext > 1.0:
			ctrl.draw_rect(Rect2(p2 + Vector2(-4.0 - panel_ext, 0), Vector2(panel_ext, 2)), panel_col2)
			ctrl.draw_rect(Rect2(p2 + Vector2( 4.0,             0), Vector2(panel_ext, 2)), panel_col2)

		# Deploy sparks: 4 pixels scatter outward then fade
		if progress < 0.5:
			var spark_alpha: float = 1.0 - (progress / 0.5)
			var spark_col := Color(0.70, 0.88, 1.0, spark_alpha * alpha)
			var spread: float = ease_p * 14.0
			for i in 4:
				var angle: float = (i / 4.0) * TAU + progress * PI
				var sp: Vector2  = p2 + Vector2(cos(angle), sin(angle)) * spread
				ctrl.draw_rect(Rect2(sp, Vector2(2, 2)), spark_col)
		)

	_deploy_anims.append(da)

func _spawn_station_deploy_poi(poi: POIData, container: Control, on_complete: Callable = Callable()) -> void:
	if _orbital_layer == null or not is_instance_valid(_orbital_layer):
		if on_complete.is_valid(): on_complete.call()
		return
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.z_index = 10
	container.add_child(ctrl)
	var da: Dictionary = {
		"poi":          poi,
		"ctrl":         ctrl,
		"t":            0.0,
		"duration":     2.2,
		"launch_frac":  poi.construct_progress,
		"on_complete":  on_complete,
	}
	ctrl.draw.connect(func() -> void:
		var sv2 := _orbital_layer._project_poi(poi, poi.orbit_angle)
		if _orbital_layer._is_occluded_r(sv2):
			return
		var origin_local: Vector2 = _orbital_layer._planet_center + Vector2(sv2.x, sv2.y)
		var origin_global: Vector2 = _orbital_layer.get_global_transform() * origin_local
		var p2 := ctrl.get_global_transform().affine_inverse() * origin_global
		var t2: float = da.get("t", 0.0)
		var progress: float = clampf(t2 / da["duration"], 0.0, 1.0)
		var ease_p: float   = ease(progress, -2.0)
		var alpha: float    = 1.0 - clampf((progress - 0.7) / 0.3, 0.0, 1.0)
		var core_col := Color(0.85, 0.90, 1.0, alpha)
		ctrl.draw_rect(Rect2(p2 + Vector2(-2,-2), Vector2(6,6)), core_col)
		var panel_ext: float = ease_p * 10.0
		var panel_col2 := Color(0.30, 0.60, 1.0, alpha * 0.85)
		if panel_ext > 1.0:
			ctrl.draw_rect(Rect2(p2 + Vector2(-4.0 - panel_ext, 0), Vector2(panel_ext, 2)), panel_col2)
			ctrl.draw_rect(Rect2(p2 + Vector2( 4.0,             0), Vector2(panel_ext, 2)), panel_col2)
		if progress < 0.5:
			var spark_alpha: float = 1.0 - (progress / 0.5)
			var spark_col := Color(0.70, 0.88, 1.0, spark_alpha * alpha)
			var spread: float = ease_p * 14.0
			for i in 4:
				var angle: float = (i / 4.0) * TAU + progress * PI
				var sp: Vector2  = p2 + Vector2(cos(angle), sin(angle)) * spread
				ctrl.draw_rect(Rect2(sp, Vector2(2, 2)), spark_col)
		)
	_deploy_anims.append(da)

func _tick_deploy_anims(delta: float) -> void:
	var done: Array[Dictionary] = []
	for da: Dictionary in _deploy_anims:
		da["t"] = da["t"] + delta
		if not is_instance_valid(da.get("ctrl")):
			done.append(da)
			continue
		var ctrl2: Control = da["ctrl"]
		# Drive orbital district progress bar through deploy phase (launch_frac → 1.0)
		var dp_poi: POIData = da.get("poi", null)
		if dp_poi != null and dp_poi.constructing:
			const _DEP: float = 2.2
			var _lf: float = da.get("launch_frac", 1.0 - _DEP / (_DEP + 1.0))
			dp_poi.construct_progress = lerpf(_lf, 1.0, minf(da["t"] / da["duration"], 1.0))
		if da["t"] >= da["duration"]:
			ctrl2.queue_free()
			done.append(da)
			var cb: Callable = da.get("on_complete", Callable())
			if cb.is_valid(): cb.call()
		else:
			ctrl2.queue_redraw()
	for da: Dictionary in done:
		_deploy_anims.erase(da)

# ── Toast / build-log notification ───────────────────────────────────────────

func _get_toast_container() -> VBoxContainer:
	if _toast_container != null and is_instance_valid(_toast_container):
		return _toast_container
	var tc := VBoxContainer.new()
	tc.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tc.grow_vertical   = Control.GROW_DIRECTION_BEGIN   # stack upward
	tc.grow_horizontal = Control.GROW_DIRECTION_END
	tc.custom_minimum_size = Vector2(260, 0)
	tc.offset_left = PANEL_FRACTION * _panel_t * get_viewport_rect().size.x + 14.0   # follows the panel
	tc.add_theme_constant_override("separation", 5)
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tc)
	_toast_container = tc
	return tc

## Keeps the toast stack at the bottom-left of the planet area (right of the
## side panel), above the marker (eye) button. Safe to call every time.
func _reanchor_toast_above_credits() -> void:
	var tc := _get_toast_container()
	tc.offset_left = PANEL_FRACTION * _panel_t * get_viewport_rect().size.x + 14.0
	tc.offset_bottom = -(12.0 + 36.0 + 10.0)

## Shows a brief construction-complete notification at the bottom-left of the planet area,
## then fades it out after a few seconds.
func _show_construction_toast(building_name: String, district_label: String) -> void:
	# Re-measure credits panel height each time in case it changed after layout
	_reanchor_toast_above_credits()
	var tc := _get_toast_container()

	# ── Outer panel ─────────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.07, 0.10, 0.15, 0.90)
	ps.border_color = Color(0.28, 0.78, 0.48, 0.55)
	ps.set_border_width_all(1)
	ps.corner_radius_top_left     = 6
	ps.corner_radius_top_right    = 6
	ps.corner_radius_bottom_left  = 6
	ps.corner_radius_bottom_right = 6
	ps.content_margin_left   = 10.0
	ps.content_margin_right  = 12.0
	ps.content_margin_top    = 7.0
	ps.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", ps)

	# ── Content row ─────────────────────────────────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	# Checkmark icon
	var icon := Label.new()
	icon.text = "✓"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_theme_font_size_override("font_size", 13)
	icon.add_theme_color_override("font_color", Color(0.28, 0.90, 0.52))
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Text column
	var tvbox := VBoxContainer.new()
	tvbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tvbox.add_theme_constant_override("separation", 1)
	hbox.add_child(tvbox)

	var name_lbl := Label.new()
	name_lbl.text = building_name
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(name_lbl, 9)
	name_lbl.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
	tvbox.add_child(name_lbl)

	if district_label != "":
		var sub := Label.new()
		sub.text = "Built in " + district_label
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(sub, 7)
		sub.add_theme_color_override("font_color", Color(0.45, 0.58, 0.72))
		tvbox.add_child(sub)

	tc.add_child(panel)
	AudioManager.play("building_done", 2.0)

	# ── Tween: fade-in → hold → fade-out → free ─────────────────────────────
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.75)
	tw.tween_callback(panel.queue_free)

func _card_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color           = Color(0.07, 0.09, 0.16, 0.92)
	s.border_width_left  = 1; s.border_width_right  = 1
	s.border_width_top   = 1; s.border_width_bottom = 1
	s.border_color       = Color(0.22, 0.28, 0.50, 0.45)
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	return s

## Orb-of-Creation style: card whose background fills left→right as production ticks.
## count = number of this building type in this POI (for ×N badge)
## poi/planet/pp needed for "+" stacking button
func _build_construction_bar(def: BuildingDef, pm_key: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_panel_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true

	var body := MarginContainer.new()
	body.custom_minimum_size   = Vector2(0, 50)
	card.add_child(body)

	var fill_ctrl := Control.new()
	fill_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prog_ref: Array = [ProductionManager.get_construct_progress(pm_key)]
	fill_ctrl.draw.connect(func() -> void: _paint_hazard(fill_ctrl, float((prog_ref as Array)[0])))
	body.add_child(fill_ctrl)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    7)
	margin.add_theme_constant_override("margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	_apply_orbitron(name_lbl, 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var status_lbl := Label.new()
	status_lbl.text = "CONSTRUCTING..."
	_apply_orbitron(status_lbl, 8)
	status_lbl.add_theme_color_override("font_color", Color(0.65, 0.50, 0.20))
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	name_col.add_child(name_lbl)
	name_col.add_child(status_lbl)
	hbox.add_child(name_col)

	# Percent label on right
	var pct_lbl := Label.new()
	pct_lbl.text = "0%"
	_apply_orbitron(pct_lbl, 9)
	pct_lbl.add_theme_color_override("font_color", Color(0.70, 0.58, 0.25))
	pct_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(pct_lbl)

	# Wire live updates via _bar_meta
	_bar_meta[pm_key] = {"fill": fill_ctrl, "prog": prog_ref, "pct": pct_lbl, "construction": true}

	return card

## Output line of a building entry, from the production engine's own numbers.
func _entry_output_text(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> String:
	var eff := ProductionManager.output_efficiency(pp, def)   # population / energy deficit
	var parts: Array[String] = []
	for id: String in def.outputs:
		var v := ProductionManager.output_per_cycle(pp, entry, def, id)
		if id != Economy.ENERGY and id != Economy.POPULATION:
			v *= eff
		match id:
			Economy.ENERGY:     parts.append("+%s ⚡/s" % BuildingDef._num(snappedf(v, 0.1)))
			Economy.POPULATION: parts.append("+%s pop" % Economy.fmt(v))
			Economy.RAW:        parts.append("+%s raw" % BuildingDef._num(snappedf(v, 0.1)))
			_: parts.append("+%s %s" % [BuildingDef._num(snappedf(v, 0.1)),
				Economy.INFO.get(id, {}).get("short", id)])
	var n := float(entry.get("amount", 1))
	for id: String in def.storage:
		parts.append("+%s %s storage" % [Economy.fmt(float(def.storage[id]) * n),
			Economy.INFO.get(id, {}).get("short", id)])
	for id: String in def.planet_bonus:
		parts.append("+%d%% %s" % [int(round(float(def.planet_bonus[id]) * n * 100.0)),
			Economy.INFO.get(id, {}).get("short", id)])
	return " · ".join(parts)

## Upkeep line of a building entry, e.g. "−4 Ferrite" or "−2 goods".
func _entry_input_text(entry: Dictionary, def: BuildingDef) -> String:
	var n := float(entry.get("amount", 1))
	var parts: Array[String] = []
	for id: String in def.inputs:
		var name: String = Economy.INFO.get(id, {}).get("short", Economy.display_name(id))
		parts.append("−%s %s" % [BuildingDef._num(float(def.inputs[id]) * n), name])
	return " · ".join(parts)

# ── Coloured tooltip text (BBCode) ──────────────────────────────────────────
const BB_BAD  := "#ff6a5c"
const BB_WARN := "#ffb04a"
const BB_DIM  := "#8a93b0"

static func _bb(text: String, col: Variant) -> String:
	var hex: String = col if col is String else (col as Color).to_html(false)
	return "[color=#%s]%s[/color]" % [hex.trim_prefix("#"), text]

## "+4.2 cr" in the resource's colour (energy per second, population compact).
static func _res_bb(id: String, v: float, sign := "+") -> String:
	var num := Economy.fmt(absf(v)) if absf(v) >= 1000.0 else BuildingDef._num(snappedf(absf(v), 0.1))
	var unit: String
	match id:
		Economy.ENERGY:     unit = "⚡/s"
		Economy.POPULATION: unit = "pop"
		Economy.RAW:        unit = "raw"
		_:                  unit = Economy.INFO.get(id, {}).get("short", id)
	var col := Economy.color_of(id) if id != Economy.RAW else Color(0.85, 0.78, 0.70)
	return _bb("%s%s %s" % [sign, num, unit], col)

## Cost line: credits (red when short) and workers (orange when housing runs out).
func _cost_bb(credits: float, pop: int, pd: PlanetData, pp: PlanetProgress) -> String:
	var parts: Array[String] = []
	if credits > 0.0:
		parts.append(_bb("%s" % HUDManager.fmt_credits(credits),
			Economy.color_of(Economy.CREDITS) if GameState.credits >= credits else Color.html(BB_BAD)))
	if pop > 0 and pd != null and pp != null:
		var ok := Economy.free_population(pd, pp) >= pop
		parts.append(_bb("☺ %s workers" % Economy.fmt(pop),
			Economy.color_of(Economy.POPULATION) if ok else Color.html(BB_WARN)))
	return "  ·  ".join(parts)

## Tooltip text for a full cost ({credits, materials…}) plus workers; short
## parts in red.
func _full_cost_bb(cost: Dictionary, pop: int, pd: PlanetData, pp: PlanetProgress) -> String:
	var txt := _cost_bb(float(cost.get(Economy.CREDITS, 0.0)), pop, pd, pp)
	var mats: Array[String] = []
	for id: String in cost:
		if id == Economy.CREDITS:
			continue
		var need: float = float(cost[id])
		mats.append(_bb("%s %s" % [Economy.fmt(need), Economy.display_name(id)],
			Economy.color_of(id) if Economy.payable_amount(id) >= need else Color.html(BB_BAD)))
	if not mats.is_empty():
		txt += ("  ·  " if txt != "" else "") + "  ·  ".join(mats)
	return txt

## How many a click buys: Shift ×5, Ctrl/Cmd as many as possible, else one.
static func _bulk_count() -> int:
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
		return 999
	if Input.is_key_pressed(KEY_SHIFT):
		return 5
	return 1

const BULK_HINT := "Shift-click ×5  ·  Ctrl/Cmd-click as many as possible"

## Buys up to `want` of a model in a district with one payment (bulk buy) —
## never more than slots, limits and every part of the cost allow. Returns how
## many were queued (0 = nothing bought, error sound played).
func _buy_buildings(poi: POIData, planet: PlanetData, def: BuildingDef, want: int) -> int:
	var pp := GameState.get_planet(planet.seed)
	var n := Economy.max_buildable(pp, def, poi, want)
	if n <= 0 or not Economy.pay(Economy.building_full_cost(pp, def, poi.label, n)):
		AudioManager.play("error")
		return 0
	for _i in n:   # each building's own repeat price goes to the refund ledger
		var each := Economy.building_full_cost(pp, def, poi.label, 1)
		pp.build_in_district(poi, def.building_id, "", float(each.get(Economy.CREDITS, 0.0)))
	AudioManager.play("construct")
	AchievementManager.notify_trigger(AchievementDef.Trigger.FIRST_BUILDING)
	ProductionManager.building_queued.emit(planet.seed, def.building_id)
	GameState.planet_progress_changed.emit(planet.seed)
	_refresh_overview_energy()
	return n

## "+4 cr · +0.5 ⚡" for an income dictionary (neighbour gains).
func _income_text(inc: Dictionary) -> String:
	var parts: Array[String] = []
	for id: String in inc:
		var v := float(inc[id])
		match id:
			Economy.ENERGY:     parts.append("+%s ⚡/s" % BuildingDef._num(v))
			Economy.POPULATION: parts.append("+%s pop" % Economy.fmt(v))
			_: parts.append("+%s %s" % [BuildingDef._num(v), Economy.INFO.get(id, {}).get("short", id)])
	return " · ".join(parts)

## Thin bar that fills over a district's base-income cycle (redraws itself).
## "+12 cr /30s · +2 ⚡/s" — what a district makes on its own (ProductionManager.district_base).
func _district_base_text(pp: PlanetProgress, poi: POIData) -> String:
	var ddef := ProductionManager.district_def(poi)
	if ddef == null:
		return ""
	var parts: Array[String] = []
	var inc := ProductionManager.district_income(pp, poi) if not poi.constructing and poi.label != "" \
		else ProductionManager.district_income_raw(current_data, poi)
	for id: String in inc:
		var v: float = inc[id]
		match id:
			Economy.ENERGY:     parts.append("+%s ⚡/s" % BuildingDef._num(snappedf(v, 0.1)))
			Economy.POPULATION: parts.append("+%s pop" % Economy.fmt(v))
			Economy.RAW:        parts.append("+%s raw /%ds" % [BuildingDef._num(snappedf(v, 0.1)), int(ddef.base_tick)])
			_: parts.append("+%s %s /%ds" % [BuildingDef._num(snappedf(v, 0.1)),
				Economy.INFO.get(id, {}).get("short", id), int(ddef.base_tick)])
	return "  ·  ".join(parts)

## District panel row: base income, the site multiplier (tooltip breaks it down)
## and the site-only buildings this spot unlocks.
func _build_district_base_row(poi: POIData, planet: PlanetData, pp: PlanetProgress) -> Control:
	var ddef := ProductionManager.district_def(poi)
	if ddef == null or ddef.base_outputs.is_empty():
		return null
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var k := Label.new()
	k.text = "Base Income"
	_apply_orbitron(k, 8)
	k.add_theme_color_override("font_color", Color(0.45, 0.50, 0.65))
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Label.new()
	var tb := _terrain_bonus_text(poi, ddef.base_outputs)
	v.text = _district_base_text(pp, poi) + ("   terrain %s" % tb if tb != "" else "")
	# wraps instead of widening the side panel
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.custom_minimum_size = Vector2(60, 0)
	_apply_orbitron(v, 8)
	v.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(k); row.add_child(v)
	box.add_child(row)
	var lv: int = pp.district_levels.get(poi.label, 1)
	var tip_lines: Array[String] = ["What this district makes before any buildings.",
		"Its location bonus applies to this and to every building in it."]
	tip_lines.append("")
	tip_lines.append("Terrain — visible features here (full on them, half within %d km), the City's included:" % int(Balance.cfg.terrain_near_km))
	var feat_lines := _feature_lines(FeatureMap.merged_site(planet, poi))
	for ln: Array in feat_lines:
		tip_lines.append(String(ln[0]))
	if feat_lines.is_empty():
		tip_lines.append("No terrain features here.")
	tip_lines.append("")
	tip_lines.append_array(_location_lines(Location.breakdown(planet, poi), true))
	if lv > 1:
		tip_lines.append("")
		tip_lines.append("×%.1f  District Lv %d" % [DistrictDef.level_mult(lv), lv])
	var wants: Array[String] = []
	var table: Dictionary = Balance.cfg.terrain_bonuses
	for fid: String in FeatureMap.IDS:
		for id: String in ddef.base_outputs:
			var fam := FeatureMap.family_of(id)
			var bonus_row: Dictionary = table.get(fid, {})
			if bonus_row.has(fam) or (fam == "energy" and bonus_row.keys().any(func(k: String) -> bool: return k.begins_with("energy_"))):
				wants.append(FeatureMap.feature_name(fid))
				break
	if not wants.is_empty():
		tip_lines.append("")
		tip_lines.append("Thrives on: " + ", ".join(wants))
	row.mouse_entered.connect(func() -> void: TooltipManager.show_tip("Base Income", "\n".join(tip_lines)))
	row.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	# Site-only buildings this spot unlocks
	var unlocked: Array[String] = []
	for b: BuildingDef in BuildingDef.for_poi_and_planet(poi.poi_type, planet.planet_type):
		if (b.required_tag != "" or b.requires_coastal or not b.required_terrain.is_empty()) \
				and b.site_block_reason(poi) == "":
			unlocked.append(b.display_name)
	if not unlocked.is_empty():
		var u := Label.new()
		u.text = "Site unlocks: " + ", ".join(unlocked)
		u.autowrap_mode = TextServer.AUTOWRAP_WORD
		_apply_orbitron(u, 8)
		u.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55, 0.85))
		u.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(u)
	return box

## "LEVEL UP" row of the district panel: population pays for each new level.
func _build_district_level_row(poi: POIData, planet: PlanetData, pp: PlanetProgress, lv: int) -> Control:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(btn, 9)
	var need := Economy.level_up_pop_for(poi, lv)
	var credits := Leveling.district_level_credits(lv)
	var free := Economy.free_population(planet, pp)
	var slots_now := pp.district_slots(poi)
	var block := Leveling.district_level_block(planet, pp, poi)
	var tip := ""
	if pp.is_district_upgrading(poi.label):
		btn.text = "Lv %d  →  Lv %d  ·  UPGRADING…" % [lv, lv + 1]
		btn.disabled = true
		btn.add_child(_hazard_fill(func() -> float: return float(pp.district_upgrading.get(poi.label, 1.0))))
		btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.92, 0.60))
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		btn.add_theme_constant_override("outline_size", 5)
	elif lv >= Balance.cfg.max_district_level:
		btn.text = "Lv %d  ·  MAX LEVEL" % lv
		btn.disabled = true
	else:
		btn.text = "Lv %d  ·  LEVEL UP  ◈ %s" % [lv, HUDManager.fmt_credits(credits)] \
			+ ("  ☺ %s" % Economy.fmt(need) if need > 0 else "")
		_live_enable(btn, func() -> bool:
			return Leveling.district_level_block(planet, pp, poi) == "" and GameState.credits >= credits)
		var add_slots := PlanetProgress.slots_per_level(poi)
		tip = "Raise to Lv %d:\n%s  ·  +%d building slot%s (%d → %d)\n\nCost  %s" % [
			lv + 1, _bb("more base income", Economy.color_of(Economy.CREDITS)), add_slots,
			"" if add_slots == 1 else "s", slots_now, slots_now + add_slots,
			_cost_bb(credits, need, planet, pp)]
		if block != "":
			tip += "\n\n" + _bb("➡ " + block, BB_BAD)
		elif free < need:
			tip += "\n\n" + _bb("Population will exceed housing — output drops until you build more homes.", BB_WARN)
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.10, 0.16, 0.30, 0.85)
	norm.border_color = Color(0.35, 0.55, 0.95, 0.6)
	norm.set_border_width_all(1)
	norm.set_corner_radius_all(4)
	norm.content_margin_top = 6; norm.content_margin_bottom = 6
	var hov := norm.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.16, 0.24, 0.45, 0.95)
	var dis := norm.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.08, 0.09, 0.14, 0.7)
	dis.border_color = Color(0.25, 0.28, 0.40, 0.5)
	if pp.is_district_upgrading(poi.label):
		dis.bg_color = Color(0, 0, 0, 0)   # let the hazard fill behind it show
		dis.border_color = Color(1.0, 0.82, 0.15, 0.6)
	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	if not pp.is_district_upgrading(poi.label):
		btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.60))
	if tip != "":
		btn.mouse_entered.connect(func() -> void:
			# a City's own district is its Capital District — not the City (that
			# levels from the City panel)
			TooltipManager.show_tip("Level up Capital District" if poi.is_city() else "Level up %s" % poi.shown_name(), tip))
		btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	btn.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if _district_level_up(poi, planet):
			_build_district_panel(poi, planet))
	return btn

func _build_production_bar(def: BuildingDef, pm_key: String, _planet_seed: int,
		count: int, poi: POIData, planet: PlanetData, pp: PlanetProgress,
		entry: Dictionary = {}) -> PanelContainer:
	var paused := ProductionManager.is_paused(pm_key)
	var prog   := ProductionManager.get_progress(pm_key)
	var fc     := def.output_color()

	# ── Spaceport: custom launch card ────────────────────────────────────────────
	if def.building_id == "spaceport":
		return _build_spaceport_card(def, pm_key, pp, poi, entry)

	# Outer card
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_panel_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true

	# Inner layer control — fill draws here, content sits on top
	var body := MarginContainer.new()
	body.custom_minimum_size   = Vector2(0, 54)
	card.add_child(body)

	# Fill control — redraws each production tick
	var fill_ctrl := Control.new()
	fill_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prog_ref: Array = [prog]
	var cap_fill_key := pm_key
	fill_ctrl.draw.connect(func() -> void:
		var p: float = (prog_ref as Array)[0]
		var user_off: bool  = ProductionManager.is_user_paused(cap_fill_key)
		var auto_off: bool  = ProductionManager.is_paused(cap_fill_key)
		var w: float = fill_ctrl.size.x * p
		if user_off:
			fill_ctrl.draw_rect(Rect2(0, 0, fill_ctrl.size.x, fill_ctrl.size.y),
				Color(0.08, 0.08, 0.14, 0.72))
			# Diagonal hatch
			for xi: int in range(0, int(fill_ctrl.size.x) + int(fill_ctrl.size.y), 14):
				var x0: float = float(xi)
				fill_ctrl.draw_line(Vector2(x0, 0),
					Vector2(x0 - fill_ctrl.size.y, fill_ctrl.size.y),
					Color(0.25, 0.28, 0.42, 0.30), 1.0)
		elif auto_off:
			fill_ctrl.draw_rect(Rect2(0, 0, w, fill_ctrl.size.y),
				Color(0.35, 0.38, 0.55, 0.22))
		else:
			_paint_cycle(fill_ctrl, p, fc))
	body.add_child(fill_ctrl)

	# Content layout on top of fill
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",   8)
	margin.add_theme_constant_override("margin_top",     7)
	margin.add_theme_constant_override("margin_bottom",  7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	# Left: name column
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	# Name row: "Hab Block" + "×2" count badge
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 5)
	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(name_lbl, 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	name_row.add_child(name_lbl)
	if def.slot_cost > 1:   # large model: one card, one count, two slots each
		var slot_tag := Label.new()
		slot_tag.text = "%d SLOTS" % def.slot_cost
		slot_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(slot_tag, 7)
		slot_tag.add_theme_color_override("font_color", Color(0.65, 0.72, 0.95, 0.8))
		name_row.add_child(slot_tag)
	var b_lv: int = entry.get("level", 1)
	if count > 1 or b_lv > 1:
		var cnt_lbl := Label.new()
		var txt := ""
		if count > 1: txt += "×%d" % count
		if b_lv > 1: txt += (" " if txt != "" else "") + "Lv%d" % b_lv
		cnt_lbl.text = txt
		cnt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(cnt_lbl, 8)
		cnt_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 1.0, 0.8))
		name_row.add_child(cnt_lbl)
	vbox.add_child(name_row)

	# Energy + output info row
	var info_row := HBoxContainer.new()
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_theme_constant_override("separation", 8)
	
	var out_text := "⏸ waiting" if paused else _entry_output_text(pp, entry, def)
	if ProductionManager.is_storage_full(pm_key):
		out_text = "▣ storage full"

	var out_lbl := Label.new()
	out_lbl.text = out_text
	out_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out_lbl.custom_minimum_size = Vector2(60, 0)
	_apply_orbitron(out_lbl, 8)
	out_lbl.add_theme_color_override("font_color",
		Color(0.45, 0.48, 0.60) if paused else fc)
	info_row.add_child(out_lbl)
	
	if def.energy_per_tick < 0.0:
		var etick := def.energy_per_tick * float(count) \
			* float(get_node("/root/SkillTree").get_energy_consume_mult())
		var e_lbl := Label.new()
		var sign := "+" if etick > 0.0 else ""
		e_lbl.text = sign + "%.0f ⚡" % etick
		e_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(e_lbl, 8)
		e_lbl.add_theme_color_override("font_color",
			Color(0.9, 0.82, 0.25, 0.55) if etick > 0 else Color(0.75, 0.48, 0.28, 0.55))
		info_row.add_child(e_lbl)

	# Upkeep paid each cycle; raw inputs show the resource being burned.
	if not def.inputs.is_empty():
		var in_lbl := Label.new()
		in_lbl.text = _entry_input_text(entry, def)
		in_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(in_lbl, 8)
		in_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45, 0.8))
		info_row.add_child(in_lbl)
	vbox.add_child(info_row)

	var tip_str := def.description + "\n\n"
	if not paused:
		var made: Array[String] = []
		for oid: String in def.outputs:
			made.append(_res_bb(oid, ProductionManager.output_per_cycle(pp, entry, def, oid)))
		if not made.is_empty():
			tip_str += "Makes     " + "  ".join(made) + _bb("  /%.0fs" % def.tick_duration, BB_DIM) + "\n"
	var upk: Array[String] = []
	if def.energy_per_tick < 0.0:
		upk.append(_res_bb(Economy.ENERGY, def.energy_per_tick * float(count)
			* float(get_node("/root/SkillTree").get_energy_consume_mult()), "−"))
	for iid: String in def.inputs:
		upk.append(_res_bb(iid, float(def.inputs[iid]) * float(count), "−"))
	if not upk.is_empty():
		tip_str += "Upkeep    " + "  ".join(upk) + "\n"
	if def.pop_use() > 0:
		tip_str += "Workers   " + _bb("☺ %s" % Economy.fmt(def.pop_use() * count), Economy.color_of(Economy.POPULATION)) + "\n"

	card.mouse_entered.connect(func() -> void:
		AudioManager.play("poi_hover")
		TooltipManager.show_tip(def.display_name, tip_str.strip_edges()))
	card.mouse_exited.connect(func() -> void:
		TooltipManager.hide_tip())
	# Energy-crisis "Slowed" label — shown below info row for energy consumers
	var slowed_lbl: Label = null
	if def.energy_per_tick < 0.0:
		slowed_lbl = Label.new()
		slowed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(slowed_lbl, 7)
		slowed_lbl.add_theme_color_override("font_color", Color(0.90, 0.55, 0.20))
		var er := ProductionManager.get_energy_ratio(pp.planet_seed)
		slowed_lbl.text    = "⚡ Slowed %d%% — Energy Crisis" % [int((1.0 - er) * 100)]
		slowed_lbl.visible = er < 0.999
		vbox.add_child(slowed_lbl)

	# Right: "+" stacking and "−" demolish buttons
	var cap_poi    := poi
	var cap_def    := def
	var cap_planet := planet
	var cap_entry  := entry  # dict reference for demolish

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 2)
	btn_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var add_btn := Button.new()
	add_btn.text     = "+"
	add_btn.flat     = false
	_apply_orbitron(add_btn, 10)
	add_btn.custom_minimum_size = Vector2(30, 22)
	add_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Re-checked live: credits / slots / workers change while the panel is open
	var stack_state := func() -> Dictionary:
		var free_slots: int = pp.district_slots(cap_poi) - pp.slots_used_in_district(cap_poi.label)
		var cost := Economy.building_full_cost(pp, cap_def, cap_poi.label)
		return {"slots": free_slots >= cap_def.slot_cost, "credits": Economy.can_pay(cost), "cost": cost,
			"block": Economy.cost_block(cost), "pop": Economy.free_population(cap_planet, pp) >= cap_def.pop_use()}
	var restyle := func() -> void:
		var st: Dictionary = stack_state.call()
		var ok: bool = st["slots"] and st["credits"]
		if add_btn.has_meta("ok") and bool(add_btn.get_meta("ok")) == ok:
			return
		add_btn.set_meta("ok", ok)
		add_btn.disabled = not ok
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(0.12, 0.30, 0.15, 1.0) if ok else Color(0.10, 0.10, 0.16, 1.0)
		sb.border_color = Color(0.35, 0.75, 0.40, 1.0) if ok else Color(0.22, 0.25, 0.38, 1.0)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 3; sb.content_margin_right = 3
		add_btn.add_theme_stylebox_override("normal",   sb)
		add_btn.add_theme_stylebox_override("disabled", sb)
		add_btn.add_theme_color_override("font_color", Color(0.60, 0.95, 0.65) if ok else Color(0.30, 0.33, 0.45))
	restyle.call()
	var poll := Timer.new()
	poll.wait_time = 0.25
	poll.autostart = true
	poll.timeout.connect(restyle)
	add_btn.add_child(poll)
	add_btn.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		var st: Dictionary = stack_state.call()
		var stack_tip := "Stack one more %s\n\nCost  %s" % [cap_def.display_name,
			_full_cost_bb(st["cost"], cap_def.pop_use(), cap_planet, pp)]
		stack_tip += "  ·  " + _bb("%d slot" % cap_def.slot_cost, Color(0.75, 0.82, 1.0) if st["slots"] else Color.html(BB_BAD))
		if not st["slots"]:
			stack_tip += "\n\n" + _bb("➡ No free slots — level the district up", BB_BAD)
		elif not st["credits"]:
			stack_tip += "\n\n" + _bb("➡ " + String(st["block"]), BB_BAD)
		elif not st["pop"]:
			stack_tip += "\n\n" + _bb("Population will exceed housing — output drops until you build more homes.", BB_WARN)
		stack_tip += "\n\n" + _bb(BULK_HINT, BB_DIM)
		TooltipManager.show_tip("+ " + cap_def.display_name, stack_tip))
	add_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	add_btn.pressed.connect(func() -> void:
		if _buy_buildings(cap_poi, cap_planet, cap_def, _bulk_count()) > 0:
			_build_district_panel(cap_poi, cap_planet))

	var rem_btn := Button.new()
	rem_btn.text = "-"
	rem_btn.flat = false
	_apply_orbitron(rem_btn, 10)
	rem_btn.custom_minimum_size = Vector2(30, 22)
	var rem_s := StyleBoxFlat.new()
	rem_s.bg_color     = Color(0.28, 0.10, 0.10, 1.0)
	rem_s.border_color  = Color(0.65, 0.28, 0.28, 1.0)
	rem_s.border_width_left = 1; rem_s.border_width_right  = 1
	rem_s.border_width_top  = 1; rem_s.border_width_bottom = 1
	rem_s.corner_radius_top_left     = 3; rem_s.corner_radius_top_right    = 3
	rem_s.corner_radius_bottom_left  = 3; rem_s.corner_radius_bottom_right = 3
	rem_s.content_margin_left = 3; rem_s.content_margin_right = 3
	rem_btn.add_theme_stylebox_override("normal", rem_s)
	rem_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	rem_btn.add_theme_color_override("font_color", Color(0.90, 0.45, 0.45))
	var tip_rem_title := "Remove one %s" % def.display_name if count > 1 else "Demolish %s" % def.display_name
	var _cap_pp := pp
	var _cap_planet2 := planet
	rem_btn.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		if def.output_type == BuildingDef.OutputType.RAW_MINERAL or def.output_type == BuildingDef.OutputType.REFINED_MINERAL:
			var pd2: PlanetData = GameState.get_planet_data(_cap_planet2.seed)
			var tag2 := ResourceData.Tag.RAW_MINERAL if def.output_type == BuildingDef.OutputType.RAW_MINERAL else ResourceData.Tag.REFINED_MINERAL
			var res_list2 := GameState.get_body_resources_for(pd2).get_by_tag(tag2)
			var body_arr: Array = []
			for rd2 in res_list2:
				var rdd := rd2 as ResourceData
				body_arr.append(MineralIcon.make(rdd.tier, rdd.display_color))
				body_arr.append(" %s\n" % rdd.unique_name)
			TooltipManager.show_tip(tip_rem_title, body_arr)
		else:
			TooltipManager.show_tip(tip_rem_title, ""))
	rem_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	rem_btn.pressed.connect(func() -> void:
		var amt: int = cap_entry.get("amount", 1)
		if amt <= 1:
			pp.buildings.erase(cap_entry)
		else:
			cap_entry["amount"] = amt - 1
		GameState.planet_progress_changed.emit(cap_planet.seed)
		_build_district_panel(cap_poi, cap_planet))

	btn_vbox.add_child(add_btn)
	btn_vbox.add_child(rem_btn)
	
	var st = null
	if Engine.has_singleton("SceneTree") and Engine.get_main_loop():
		st = Engine.get_main_loop().root.get_node_or_null("SkillTree")
	var max_b_lv = 1
	if st and st.has_method("get_building_max_level"):
		max_b_lv = st.get_building_max_level(def.building_id)
		
	var cur_lv = entry.get("level", 1)
	# Buildings work as upgrades with a count only — no per-building levels.
	if BUILDING_LEVELS_ENABLED and cur_lv < max_b_lv:
		var b_upg_cost = def.get_upgrade_cost(cur_lv, cap_entry.get("amount", 1))
		var can_afford_b_upg = GameState.credits >= b_upg_cost
		var b_upg_btn := Button.new()
		b_upg_btn.text = "^"
		b_upg_btn.flat = false
		_apply_orbitron(b_upg_btn, 10)
		b_upg_btn.custom_minimum_size = Vector2(30, 22)
		var up_s := StyleBoxFlat.new()
		up_s.bg_color = Color(0.2, 0.4, 0.8, 1.0) if can_afford_b_upg else Color(0.1, 0.15, 0.25, 1.0)
		up_s.border_color = Color(0.4, 0.7, 1.0, 1.0) if can_afford_b_upg else Color(0.2, 0.3, 0.4, 1.0)
		up_s.border_width_all = 1
		up_s.corner_radius_top_left = 3; up_s.corner_radius_top_right = 3
		up_s.corner_radius_bottom_left = 3; up_s.corner_radius_bottom_right = 3
		up_s.content_margin_left = 3; up_s.content_margin_right = 3
		b_upg_btn.add_theme_stylebox_override("normal", up_s)
		b_upg_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		b_upg_btn.disabled = not can_afford_b_upg
		
		b_upg_btn.mouse_entered.connect(func():
			CursorManager.set_state(CursorManager.State.POINTER)
			var cost_str = "%.0f cr" % b_upg_cost
			TooltipManager.show_tip("Upgrade Building", "Upgrade to Level %d.\nIncreases output and consumption." % (cur_lv + 1), cost_str))
		b_upg_btn.mouse_exited.connect(func():
			CursorManager.set_state(CursorManager.State.NORMAL)
			TooltipManager.hide_tip())
			
		b_upg_btn.pressed.connect(func():
			TooltipManager.hide_tip()
			if pp.upgrade_building(cap_entry):
				AudioManager.play("building_done")
				GameState.planet_progress_changed.emit(cap_planet.seed)
				if _active_district_poi != null and _active_district_poi.label == cap_poi.label:
					_build_district_panel(cap_poi, cap_planet)
		)
		btn_vbox.add_child(b_upg_btn)

	hbox.add_child(btn_vbox)

	# Click card body (not the "+" button) to toggle building on/off
	var cap_toggle_key := pm_key
	body.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				ProductionManager.toggle_user_pause(cap_toggle_key))

	_bar_meta[pm_key] = {
		"fill":        fill_ctrl,
		"prog":        prog_ref,
		"out_lbl":     out_lbl,
		"slowed_lbl":  slowed_lbl,
		"planet_seed": pp.planet_seed,
		"def":         def,
		"fc":          fc,
		"entry":       entry
	}
	return card

## Spaceport card — phase-driven: idle → configuring → preparing → launch_ready → cooldown.
func _build_spaceport_card(def: BuildingDef, pm_key: String,
		pp: PlanetProgress, poi: POIData, entry: Dictionary = {}) -> PanelContainer:

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_panel_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    7)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 2)
	margin.add_child(left_vbox)

	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	_apply_orbitron(name_lbl, 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(name_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "Operational"
	_apply_orbitron(status_lbl, 8)
	status_lbl.add_theme_color_override("font_color", Color(0.50, 0.65, 0.90, 0.70))
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(status_lbl)

	# the Moon lander is built here: show its construction (GDD §20.4)
	if pp.planet_seed == GameState.home_planet_seed:
		var prep_bar := ProgressBar.new()
		prep_bar.show_percentage = false
		prep_bar.custom_minimum_size = Vector2(0, 6)
		prep_bar.max_value = 1.0
		prep_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_vbox.add_child(prep_bar)
		var sp_refresh := func() -> void:
			if not is_instance_valid(status_lbl):
				return
			var ex := GameState.expedition("lander")
			match String(ex.get("state", "")):
				"preparing":
					var left: float = float(ex.get("prep_left", 0.0))
					status_lbl.text = "Building the Moon lander — %ds" % int(ceil(left))
					prep_bar.visible = true
					prep_bar.value = 1.0 - left / GameState.LANDER_PREP_SEC
				"launching":
					status_lbl.text = "Lander lifting off"
					prep_bar.visible = false
				"orbiting":
					status_lbl.text = "Lander circling the planet"
					prep_bar.visible = false
				_:
					status_lbl.text = "Operational"
					prep_bar.visible = false
		sp_refresh.call()
		var sp_timer := Timer.new()
		sp_timer.wait_time = 0.25
		sp_timer.autostart = true
		sp_timer.timeout.connect(sp_refresh)
		card.add_child(sp_timer)

	_bar_meta[pm_key] = {
		"planet_seed": pp.planet_seed,
	}

	return card

## Register all built-in mission task types into MissionTaskRegistry.
func _register_mission_tasks() -> void:
	# ── Move to Orbit ────────────────────────────────────────────────────────
	var move_orbit := MissionTaskDef.new()
	move_orbit.task_type       = "move_orbit"
	move_orbit.display_name    = "Move to Orbit"
	move_orbit.required_status = ["on_pad"]
	move_orbit.produced_status = "in_orbit"
	move_orbit.build_params_ui = func(_c: Control, _e: Dictionary, _oc: Callable, _ctx: Dictionary) -> void: pass
	move_orbit.estimate_cost   = func(_e: Dictionary, _ctx: Dictionary) -> float: return 80.0
	MissionTaskRegistry.register(move_orbit)

	# ── Move to Station ──────────────────────────────────────────────────────
	var move_station := MissionTaskDef.new()
	move_station.task_type       = "move_station"
	move_station.display_name    = "Move to Station"
	move_station.required_status = ["on_pad", "in_orbit"]
	move_station.produced_status = "at_station:{target_id}"
	move_station.build_params_ui = func(cont: Control, e: Dictionary, on_change: Callable, ctx: Dictionary) -> void:
		for ch in cont.get_children(): ch.queue_free()

		var rebuild_ms := func() -> void:
			move_station.build_params_ui.call(cont, e, on_change, ctx)

		var ms_vbox := VBoxContainer.new()
		ms_vbox.add_theme_constant_override("separation", 3)
		ms_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ms_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(ms_vbox)

		# ── Station selector ──────────────────────────────────────────────────────
		var stations: Array = (ctx.get("ships", []) as Array).filter(
			func(s: ShipData) -> bool: return s.ship_type == "station")
		var st_row := HBoxContainer.new()
		st_row.add_theme_constant_override("separation", 6)
		ms_vbox.add_child(st_row)

		if stations.is_empty():
			var lbl := Label.new()
			lbl.text = "No stations in orbit"
			lbl.add_theme_font_size_override("font_size", 7)
			lbl.add_theme_color_override("font_color", Color(0.70, 0.35, 0.35, 0.75))
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			st_row.add_child(lbl)
		else:
			if not e.has("target_id") or not stations.any(func(s: ShipData) -> bool: return s.ship_id == e["target_id"]):
				e["target_id"] = (stations[0] as ShipData).ship_id
				on_change.call()
			for st: ShipData in stations:
				var cap_st: ShipData = st
				var btn := Button.new()
				btn.text = st.ship_name
				btn.add_theme_font_size_override("font_size", 7)
				var is_sel: bool = e.get("target_id", "") == st.ship_id
				var bs := StyleBoxFlat.new()
				bs.bg_color     = Color(0.06, 0.24, 0.18, 0.95) if is_sel else Color(0.05, 0.07, 0.15, 0.75)
				bs.border_color = Color(0.20, 0.78, 0.52, 0.75) if is_sel else Color(0.28, 0.42, 0.35, 0.35)
				bs.set_border_width_all(1); bs.set_corner_radius_all(3)
				bs.content_margin_left = 6; bs.content_margin_right = 6
				bs.content_margin_top = 3; bs.content_margin_bottom = 3
				btn.add_theme_stylebox_override("normal", bs)
				btn.add_theme_stylebox_override("hover",  bs)
				btn.add_theme_color_override("font_color",
					Color(0.35, 0.95, 0.65) if is_sel else Color(0.45, 0.62, 0.55))
				btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
				btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
				btn.pressed.connect(func() -> void:
					e["target_id"] = cap_st.ship_id
					on_change.call()
					rebuild_ms.call())
				st_row.add_child(btn)

		# ── Rendezvous actions ────────────────────────────────────────────────────
		if not e.has("rendezvous_tasks"):
			e["rendezvous_tasks"] = []
		var rdv_tasks: Array = e["rendezvous_tasks"]

		# Simulate cargo through rdv tasks in order so each task sees correct remaining capacity.
		var rdv_base: Dictionary = ctx.get("state_before", {"status": "on_pad", "cargo": {}})
		var rdv_running_cargo: Dictionary = (rdv_base.get("cargo", {}) as Dictionary).duplicate()

		for i: int in rdv_tasks.size():
			var rt: Dictionary = rdv_tasks[i]
			var rdef: MissionTaskDef = MissionTaskRegistry.get_def(rt.get("type", ""))
			var rt_row := HBoxContainer.new()
			rt_row.add_theme_constant_override("separation", 4)
			ms_vbox.add_child(rt_row)
			var rt_lbl := Label.new()
			rt_lbl.text = rdef.display_name if rdef != null else rt.get("type", "?")
			rt_lbl.add_theme_font_size_override("font_size", 7)
			rt_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
			rt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rt_lbl.custom_minimum_size = Vector2(44, 0)
			rt_row.add_child(rt_lbl)
			var rt_params := HBoxContainer.new()
			rt_params.add_theme_constant_override("separation", 3)
			rt_params.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if rdef != null and rdef.build_params_ui.is_valid():
				var rdv_ctx: Dictionary = ctx.duplicate()
				rdv_ctx["rdv_station_id"] = e.get("target_id", "")
				rdv_ctx["state_before"] = {"status": rdv_base.get("status", "on_pad"), "cargo": rdv_running_cargo.duplicate()}
				rdef.build_params_ui.call(rt_params, rt, func() -> void: on_change.call(), rdv_ctx)
			rt_row.add_child(rt_params)
			# Advance running cargo for the next rdv task
			match rt.get("type", ""):
				"deliver":
					for k: String in (rt.get("cargo", {}) as Dictionary).keys():
						rdv_running_cargo[k] = maxi(0, rdv_running_cargo.get(k, 0) - int((rt["cargo"] as Dictionary)[k]))
				"pickup":
					var res: String = rt.get("transfer_resource", "")
					if res != "": rdv_running_cargo[res] = rdv_running_cargo.get(res, 0) + int(rt.get("transfer_amount", 0))
			var cap_i: int = i
			var del_btn := Button.new()
			del_btn.text = "×"
			del_btn.add_theme_font_size_override("font_size", 9)
			var dbs := StyleBoxFlat.new()
			dbs.bg_color = Color(0,0,0,0); dbs.set_border_width_all(0)
			dbs.content_margin_left = 4; dbs.content_margin_right = 4
			del_btn.add_theme_stylebox_override("normal", dbs)
			del_btn.add_theme_stylebox_override("hover",  dbs)
			del_btn.add_theme_color_override("font_color", Color(0.70, 0.35, 0.35, 0.80))
			del_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
			del_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
			del_btn.pressed.connect(func() -> void:
				rdv_tasks.remove_at(cap_i)
				on_change.call()
				rebuild_ms.call())
			rt_row.add_child(del_btn)

		# "+" Add — driven by the registry, same DI pattern as the main chain.
		# Any task registered with required_status containing "__nested__" shows up here.
		var add_btn := _make_mission_add_btn("+ Add")
		var cap_pv      := self   # explicit capture — nested lambdas can lose implicit self
		var cap_rdv     := rdv_tasks
		var cap_ctx     := ctx
		var cap_btn     := add_btn
		var cap_overlay := ctx.get("_overlay", null) as Control
		add_btn.pressed.connect(func() -> void:
			var stype: String = (cap_ctx.get("entry", {}) as Dictionary).get("ship_type", "shuttle")
			cap_pv._show_rdv_add_popup(cap_btn, cap_rdv, stype, cap_overlay, func() -> void:
				on_change.call()
				rebuild_ms.call()))
		ms_vbox.add_child(add_btn)
	move_station.estimate_cost = func(_e: Dictionary, _ctx: Dictionary) -> float: return 40.0
	MissionTaskRegistry.register(move_station)

	# ── Pick Up (nested inside Move to Station only — not shown in main chain) ──
	var pickup := MissionTaskDef.new()
	pickup.task_type       = "pickup"
	pickup.display_name    = "Take"
	pickup.required_status = ["__nested__"]
	pickup.produced_status = ""  # stays at same station
	pickup.build_params_ui = func(cont: Control, e: Dictionary, on_change: Callable, ctx: Dictionary) -> void:
		var res_id: String = e.get("transfer_resource", "")
		var rdv_id: String = ctx.get("rdv_station_id", "")
		var pp_ref: PlanetProgress = ctx.get("pp", null)
		var state_before: Dictionary = ctx.get("state_before", {"cargo": {}})
		var ship_cap: int = _sp_cargo_capacity((ctx.get("entry", {}) as Dictionary).get("ship_type", "shuttle"))
		var cargo_weight: int = 0
		for v in (state_before.get("cargo", {}) as Dictionary).values(): cargo_weight += int(v)
		var remaining_cap: int = maxi(0, ship_cap - cargo_weight)
		var station_has: int = remaining_cap
		if rdv_id != "" and pp_ref != null:
			for s: ShipData in ShipManager.ships_for(pp_ref.planet_seed):
				if s.ship_id == rdv_id:
					station_has = int(s.cargo.get(res_id, 0))
					break
		var max_amt: int = mini(station_has, remaining_cap)
		_build_res_icon_ui(cont, e, "transfer_resource", res_id,
			e.get("transfer_amount", 10), max_amt, on_change, ctx, null, rdv_id, {})
	pickup.estimate_cost = func(_e: Dictionary, _ctx: Dictionary) -> float: return 0.0
	MissionTaskRegistry.register(pickup)

	# ── Deliver (nested inside Move to Station only) ─────────────────────────
	var deliver := MissionTaskDef.new()
	deliver.task_type       = "deliver"
	deliver.display_name    = "Drop"
	deliver.required_status = ["__nested__"]
	deliver.produced_status = ""  # stays at same station
	deliver.build_params_ui = func(cont: Control, e: Dictionary, on_change: Callable, ctx: Dictionary) -> void:
		var cargo: Dictionary = e.get("cargo", {})
		var res_id: String = cargo.keys()[0] if not cargo.is_empty() else ""
		# state_before = what the ship carries at rendezvous = valid resources to drop
		var state_before: Dictionary = ctx.get("state_before", {"cargo": {}})
		var cargo_at_rdv: Dictionary = state_before.get("cargo", {})
		var max_amt: int = int(cargo_at_rdv.get(res_id, 0)) if res_id != "" else 0
		_build_res_icon_ui(cont, e, "_deliver_res", res_id,
			cargo.get(res_id, 10), max_amt, on_change, ctx, ctx.get("pp", null), "", cargo_at_rdv)
	deliver.estimate_cost = func(_e: Dictionary, _ctx: Dictionary) -> float: return 0.0
	MissionTaskRegistry.register(deliver)

	# ── Take from Planet Storage (top-level, loads resource at launch) ───────
	var pick_planet := MissionTaskDef.new()
	pick_planet.task_type       = "pick_planet"
	pick_planet.display_name    = "Take"
	pick_planet.required_status = ["on_pad"]
	pick_planet.produced_status = "on_pad"  # stays on pad, cargo loaded at launch
	pick_planet.build_params_ui = func(cont: Control, e: Dictionary, on_change: Callable, ctx: Dictionary) -> void:
		var pp_ref: PlanetProgress = ctx.get("pp", null)
		var cargo: Dictionary = e.get("cargo", {})
		var res_id: String = cargo.keys()[0] if not cargo.is_empty() else ""
		# state_before = cargo already loaded by prior pick_planet tasks
		var state_before: Dictionary = ctx.get("state_before", {"cargo": {}})
		var ship_cap: int = _sp_cargo_capacity((ctx.get("entry", {}) as Dictionary).get("ship_type", "shuttle"))
		var cargo_weight: int = 0
		for v in (state_before.get("cargo", {}) as Dictionary).values(): cargo_weight += int(v)
		var remaining_cap: int = maxi(0, ship_cap - cargo_weight)
		var stored_amt: int = int(GameState.global_resources.get(res_id, 0)) if res_id != "" else remaining_cap
		var max_amt: int = mini(stored_amt, remaining_cap)
		_build_res_icon_ui(cont, e, "_pick_planet_res", res_id,
			cargo.get(res_id, 10), max_amt, on_change, ctx, pp_ref)
	pick_planet.estimate_cost = func(_e: Dictionary, _ctx: Dictionary) -> float: return 0.0
	MissionTaskRegistry.register(pick_planet)

	# ── Land ─────────────────────────────────────────────────────────────────
	var land := MissionTaskDef.new()
	land.task_type       = "land"
	land.display_name    = "Land"
	land.required_status = ["in_orbit", "at_station:*"]
	land.produced_status = "on_pad"
	land.build_params_ui = func(_c: Control, _e: Dictionary, _oc: Callable, _ctx: Dictionary) -> void: pass
	land.estimate_cost   = func(_e: Dictionary, _ctx: Dictionary) -> float: return 30.0
	MissionTaskRegistry.register(land)

	# ── Deploy (Station only) ─────────────────────────────────────────────────
	var deploy := MissionTaskDef.new()
	deploy.task_type            = "deploy"
	deploy.display_name         = "Deploy Station"
	deploy.required_status      = ["in_orbit"]
	deploy.required_ship_types  = ["station"]
	deploy.produced_status      = "on_pad"  # mission ends — station stays in orbit
	deploy.build_params_ui = func(_c: Control, _e: Dictionary, _oc: Callable, _ctx: Dictionary) -> void: pass
	deploy.estimate_cost   = func(_e: Dictionary, _ctx: Dictionary) -> float: return 0.0
	MissionTaskRegistry.register(deploy)

## Builds the icon + slider row used by Take/Drop task params.
## cont       — parent HBox to add widgets into
## e          — task entry dict (mutated on change)
## res_key    — which popup key to use ("transfer_resource"|"_deliver_res"|"_pick_planet_res")
## amt_getter — Callable() → int   : reads current amount from e
## amt_setter — Callable(int)      : writes amount back to e
## max_amt    — upper bound for slider (0 = use ship capacity)
## on_change  — rebuild signal
## ctx        — task context (pp, _overlay, etc.)
## popup_pp   — PlanetProgress for popup filtering (planet storage)
## rdv_station_id, pending_cargo — forwarded to resource popup
func _build_res_icon_ui(cont: Control, e: Dictionary,
		res_key: String, res_id: String, amount: int, max_amt: int,
		on_change: Callable, ctx: Dictionary, popup_pp: PlanetProgress,
		rdv_station_id: String = "", pending_cargo: Dictionary = {}) -> void:
	var rd: ResourceData = GameState.known_resources.get(res_id, null) if res_id != "" else null
	var ph: Control = ctx.get("_overlay", null) as Control
	# For station-cargo filtering (pickup task), rdv_pp is the planet pp from ctx
	var rdv_pp: PlanetProgress = ctx.get("pp", null) if rdv_station_id != "" else null

	if rd == null:
		# No resource selected yet — show a plain "Pick…" button
		var pick_btn := _make_mission_add_btn("Pick resource…")
		pick_btn.pressed.connect(func() -> void:
			_mission_show_resource_popup(cont, e, res_key, on_change,
				popup_pp, ph, rdv_station_id, rdv_pp, pending_cargo, ctx))
		cont.add_child(pick_btn)
		return

	# ── Icon chip (clickable to reopen picker) ─────────────────────
	var icon_card := _mineral_grid_card(rd, 0.0, false)
	icon_card.custom_minimum_size = Vector2(30, 30)
	icon_card.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	icon_card.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	icon_card.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton): return
		var mev := ev as InputEventMouseButton
		if not (mev.pressed and mev.button_index == MOUSE_BUTTON_LEFT): return
		_mission_show_resource_popup(cont, e, res_key, on_change,
			popup_pp, ph, rdv_station_id, rdv_pp, pending_cargo, ctx))
	cont.add_child(icon_card)

	# ── Slider ─────────────────────────────────────────────────────
	var real_max: int = maxi(1, max_amt)
	var slider := HSlider.new()
	slider.min_value  = 1
	slider.max_value  = real_max
	slider.step       = 1
	slider.value      = clamp(amount, 1, real_max)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(70, 0)
	slider.add_theme_constant_override("grabber_offset", 0)
	cont.add_child(slider)

	# ── Amount label ───────────────────────────────────────────────
	var val_lbl := Label.new()
	val_lbl.text = str(int(slider.value))
	val_lbl.custom_minimum_size = Vector2(22, 0)
	val_lbl.add_theme_font_size_override("font_size", 7)
	val_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = str(int(v))
		# Write back via res_key convention
		if res_key == "transfer_resource":
			e["transfer_amount"] = int(v)
		else:  # _deliver_res or _pick_planet_res → cargo dict
			e["cargo"] = {res_id: int(v)}
		on_change.call())

## Show a resource picker popup for mission task params.
## Small styled "+" button used to add nested (DI) mission sub-tasks.
func _make_mission_add_btn(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 7)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.05, 0.10, 0.22, 0.80)
	bs.border_color = Color(0.20, 0.38, 0.65, 0.40)
	bs.set_border_width_all(1); bs.set_corner_radius_all(3)
	bs.content_margin_left = 5; bs.content_margin_right = 5
	bs.content_margin_top = 2; bs.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_stylebox_override("hover",  bs)
	btn.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	return btn

## Dependency-injected dropdown for "On Rendezvous" sub-tasks — lists whatever
## is registered in MissionTaskRegistry under the "__nested__" status, same as
## the top-level chain's "+ Add Step" dropdown.
func _show_rdv_add_popup(anchor: Control, rdv_tasks: Array, ship_type: String,
		popup_host: Control, on_added: Callable) -> void:
	var available: Array = MissionTaskRegistry.get_available("__nested__", ship_type)
	if available.is_empty():
		return
	var popup := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.09, 0.18, 0.97)
	ps.border_color = Color(0.25, 0.45, 0.80, 0.55)
	ps.set_border_width_all(1); ps.set_corner_radius_all(5)
	ps.content_margin_left = 6; ps.content_margin_right = 6
	ps.content_margin_top = 6; ps.content_margin_bottom = 6
	popup.add_theme_stylebox_override("panel", ps)
	popup.z_index = 215

	var pvbox := VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 3)
	popup.add_child(pvbox)

	var rdv_backdrop: Control = null

	for def: MissionTaskDef in available:
		var cap_def: MissionTaskDef = def
		var btn := Button.new()
		btn.text = cap_def.display_name
		btn.add_theme_font_size_override("font_size", 7)
		var ibs := StyleBoxFlat.new()
		ibs.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		ibs.set_border_width_all(0)
		ibs.content_margin_left = 6; ibs.content_margin_right = 6
		ibs.content_margin_top = 3; ibs.content_margin_bottom = 3
		btn.add_theme_stylebox_override("normal", ibs)
		var ibs_h := ibs.duplicate()
		(ibs_h as StyleBoxFlat).bg_color = Color(0.12, 0.22, 0.45, 0.80)
		btn.add_theme_stylebox_override("hover", ibs_h)
		btn.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		btn.pressed.connect(func() -> void:
			rdv_tasks.append({"type": cap_def.task_type})
			if is_instance_valid(rdv_backdrop): rdv_backdrop.queue_free()
			popup.queue_free()
			on_added.call())
		pvbox.add_child(btn)

	# Add popup inside the Mission Builder overlay so mouse_filter doesn't block it.
	# Fall back to viewport if overlay not available (e.g. called outside builder).
	var anchor_global: Vector2 = anchor.get_global_rect().position + Vector2(0, anchor.size.y + 2)
	if popup_host != null and is_instance_valid(popup_host):
		var backdrop := ColorRect.new()
		backdrop.color = Color(0, 0, 0, 0)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		backdrop.z_index = 214
		backdrop.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				if is_instance_valid(backdrop): backdrop.queue_free()
				if is_instance_valid(popup): popup.queue_free())
		popup_host.add_child(backdrop)
		rdv_backdrop = backdrop
		popup.position = anchor_global - popup_host.get_global_rect().position
		popup_host.add_child(popup)
	else:
		popup.global_position = anchor_global
		anchor.get_viewport().add_child(popup)

func _mission_show_resource_popup(anchor: Control, entry: Dictionary,
		key: String, on_change: Callable, pp_ref: PlanetProgress = null,
		popup_host: Control = null, rdv_station_id: String = "",
		rdv_pp: PlanetProgress = null, pending_cargo: Dictionary = {},
		orig_ctx: Dictionary = {}) -> void:
	var popup := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.09, 0.18, 0.97)
	ps.border_color = Color(0.25, 0.45, 0.80, 0.55)
	ps.set_border_width_all(1); ps.set_corner_radius_all(5)
	ps.content_margin_left = 8; ps.content_margin_right = 8
	ps.content_margin_top = 8; ps.content_margin_bottom = 8
	popup.add_theme_stylebox_override("panel", ps)
	popup.z_index = 220
	popup.custom_minimum_size = Vector2(220, 0)

	var pvbox := VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 6)
	popup.add_child(pvbox)

	# Resolve resource list — priority: pending_cargo > station filter > pp storage > all known
	var resources: Array = []
	if not pending_cargo.is_empty():
		resources = pending_cargo.keys()
	elif rdv_station_id != "" and rdv_pp != null:
		for s: ShipData in ShipManager.ships_for(rdv_pp.planet_seed):
			if s.ship_id == rdv_station_id:
				resources = s.cargo.keys()
				break
		if resources.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "Station has no cargo"
			empty_lbl.add_theme_font_size_override("font_size", 7)
			empty_lbl.add_theme_color_override("font_color", Color(0.70, 0.40, 0.40, 0.75))
			pvbox.add_child(empty_lbl)
	elif pp_ref != null:
		resources = GameState.global_resources.keys()
		resources = resources.filter(func(r: String) -> bool: return GameState.global_resources.get(r, 0.0) >= 1.0)
	else:
		resources = GameState.known_resources.keys()

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 5)
	flow.add_theme_constant_override("v_separation", 5)
	pvbox.add_child(flow)

	for res_id: String in resources:
		var cap_id: String = res_id
		var rd: ResourceData = GameState.known_resources.get(res_id, null)
		if rd == null: continue

		var card := _mineral_grid_card(rd, 0.0, false)
		card.custom_minimum_size = Vector2(44, 44)
		# mouse_filter is STOP from _mineral_grid_card; gui_input gives us click detection.
		card.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		card.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		card.gui_input.connect(func(ev: InputEvent) -> void:
			if not (ev is InputEventMouseButton): return
			var mev := ev as InputEventMouseButton
			if not (mev.pressed and mev.button_index == MOUSE_BUTTON_LEFT): return
			if key == "_deliver_res" or key == "_pick_planet_res":
				var old_cargo: Dictionary = entry.get("cargo", {})
				var old_amt: int = old_cargo.values()[0] if not old_cargo.is_empty() else 10
				entry["cargo"] = {cap_id: old_amt}
			else:
				entry[key] = cap_id
			on_change.call()
			popup.queue_free()
			if not is_instance_valid(anchor): return
			for ch in anchor.get_children(): ch.queue_free()
			var def: MissionTaskDef = MissionTaskRegistry.get_def(entry.get("type", ""))
			if def != null and def.build_params_ui.is_valid():
				# Preserve full orig_ctx (includes state_before) so capacity limits survive rebuild
				var rebuild_ctx: Dictionary = orig_ctx.duplicate() if not orig_ctx.is_empty() \
					else ({} if popup_host == null else {"_overlay": popup_host})
				if popup_host != null and not rebuild_ctx.has("_overlay"):
					rebuild_ctx["_overlay"] = popup_host
				def.build_params_ui.call(anchor, entry, on_change, rebuild_ctx))
		flow.add_child(card)

	# Host popup inside the builder overlay so it's above the mouse_filter=STOP overlay.
	var anchor_global: Vector2 = anchor.get_global_rect().position + Vector2(0, 18)
	if popup_host != null and is_instance_valid(popup_host):
		popup.position = anchor_global - popup_host.get_global_rect().position
		popup_host.add_child(popup)
	else:
		popup.global_position = anchor_global
		anchor.get_viewport().add_child(popup)

## Convert a task chain into legacy entry fields for the launch system.
func _sp_apply_mission_to_entry(entry: Dictionary, tasks: Array) -> void:
	entry.erase("destination_ship_id")
	entry.erase("transfer_dir")
	entry.erase("transfer_resource")
	entry.erase("transfer_amount")
	entry.erase("cargo")
	for t: Dictionary in tasks:
		match t.get("type", ""):
			"pick_planet":
				# Merge into cargo so multiple take tasks stack
				var cur: Dictionary = entry.get("cargo", {})
				for k: String in (t.get("cargo", {}) as Dictionary).keys():
					cur[k] = (t["cargo"] as Dictionary)[k]
				entry["cargo"] = cur
			"move_station":
				entry["destination_ship_id"] = t.get("target_id", "")
				# Apply first pickup/deliver from rendezvous_tasks as legacy fields
				for rt: Dictionary in t.get("rendezvous_tasks", []):
					match rt.get("type", ""):
						"pickup":
							entry["transfer_dir"]      = "pickup"
							entry["transfer_resource"] = rt.get("transfer_resource", "")
							entry["transfer_amount"]   = rt.get("transfer_amount", 0)
						"deliver":
							entry["transfer_dir"] = "deliver"
							entry["cargo"]        = rt.get("cargo", {}).duplicate()
			"deploy":
				pass
			"land":
				entry["auto_land"] = true

## Execute the current task in ship.mission_tasks at mission_task_index.
func _advance_mission(ship: ShipData) -> void:
	if _orbital_layer == null or not is_instance_valid(_orbital_layer):
		return
	if ship.mission_task_index >= ship.mission_tasks.size():
		return
	var task: Dictionary = ship.mission_tasks[ship.mission_task_index]
	var ttype: String = task.get("type", "")
	match ttype:
		"move_station":
			var dest_id: String = task.get("target_id", "")
			if dest_id != "":
				ship.rendezvous_base_speed = ship.orbit_speed
				ship.rendezvous_target_id  = dest_id
				_orbital_layer._reveal[ship.ship_id] = {"progress": 1.0, "spawn_angle": ship.orbit_angle}
		"land":
			_orbital_layer._reveal[ship.ship_id] = {"progress": 1.0, "spawn_angle": ship.orbit_angle}
			_orbital_layer.start_landing(ship)
		"deploy":
			pass

## Helper: generate next ship name (Pioneer I, II, …) based on how many ships exist.
func _sp_next_ship_name(planet_seed: int) -> String:
	var n := ShipManager.ships_for(planet_seed).size() + 1
	return "Pioneer " + _roman_numeral(n)

func _roman_numeral(n: int) -> String:
	const NUMS := [1000,900,500,400,100,90,50,40,10,9,5,4,1]
	const SYMS := ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"]
	var r := ""
	for i in NUMS.size():
		while n >= NUMS[i]:
			r += SYMS[i]
			n -= NUMS[i]
	return r

## Shared button style for spaceport actions.
func _sp_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 4
	s.content_margin_bottom = 4
	return s

## Idle phase: "Prep Launch" button.
func _sp_build_idle(left_vbox: VBoxContainer, hbox: HBoxContainer,
		_def: BuildingDef, pm_key: String, pp: PlanetProgress,
		_poi: POIData, entry: Dictionary, rebuild_sp: Callable) -> void:
	# Auto-dequeue: if missions are queued, start the next one immediately
	var queue: Array = entry.get("mission_queue", [])
	if not queue.is_empty():
		var item: Dictionary = queue.pop_front()
		entry["mission_queue"] = queue
		entry["ship_name"]     = item.get("ship_name", _sp_next_ship_name(pp.planet_seed))
		entry["ship_type"]     = item.get("ship_type", "shuttle")
		entry["mission_tasks"] = item.get("mission_tasks", [])
		entry["repeat_cycle"]  = item.get("repeat_cycle", 0.0)
		_sp_apply_mission_to_entry(entry, entry["mission_tasks"])
		var used_q: int = _sp_cargo_used(entry)
		var cost_q: int = _sp_launch_cost(entry.get("ship_type", "shuttle"), used_q)
		if GameState.spend_credits(float(cost_q)):
			var src_pq := GameState.get_planet(pp.planet_seed)
			if src_pq != null:
				for res_q: String in entry.get("cargo", {}):
					GameState.global_resources[res_q] = maxf(0.0,
						GameState.global_resources.get(res_q, 0.0) - float(entry["cargo"][res_q]))
			entry["phase"] = "preparing"
			entry["effective_duration"] = 20.0
			entry.erase("cooldown_only")
			_bar_meta.erase(pm_key)
			if ProductionManager.is_user_paused(pm_key):
				ProductionManager.toggle_user_pause(pm_key)
			rebuild_sp.call()
		return

	var status := Label.new()
	status.text = "Ready"
	_apply_orbitron(status, 8)
	status.add_theme_color_override("font_color", Color(0.35, 0.90, 0.55, 0.80))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(status)

	var btn := Button.new()
	btn.text = "Prepare Mission"
	_apply_orbitron(btn, 9)
	var bs := _sp_btn_style(Color(0.10, 0.22, 0.42, 0.90), Color(0.30, 0.60, 1.0, 0.75))
	btn.add_theme_stylebox_override("normal",  bs)
	btn.add_theme_stylebox_override("hover",   bs)
	btn.add_theme_stylebox_override("pressed", bs)
	btn.add_theme_color_override("font_color", Color(0.60, 0.88, 1.0))
	btn.custom_minimum_size = Vector2(100, 0)
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	btn.pressed.connect(func() -> void:
		# Toggle: if already open, close it
		if _mission_builder_overlay != null and is_instance_valid(_mission_builder_overlay):
			_mission_builder_overlay.queue_free()
			_mission_builder_overlay = null
			return
		if not entry.has("ship_name"):
			entry["ship_name"] = _sp_next_ship_name(pp.planet_seed)
		entry["ship_type"] = "shuttle"
		var planet_cont: Control = planet_renderer.get_parent()
		var ctx := {
			"planet_seed":   pp.planet_seed,
			"pp":            pp,
			"font":          _orbitron,
			"entry":         entry,
			"ships":         ShipManager.ships_for(pp.planet_seed),
			"default_name":  entry.get("ship_name", _sp_next_ship_name(pp.planet_seed)),
			"initial_tasks": entry.get("mission_tasks", []),
			"on_close":      func() -> void: _mission_builder_overlay = null,
		}
		_mission_builder_overlay = MissionBuilderPanel.open(planet_cont, ctx, func(tasks: Array, repeat: float) -> void:
			_mission_builder_overlay = null

			entry["mission_tasks"] = tasks
			entry["repeat_cycle"]  = repeat
			_sp_apply_mission_to_entry(entry, tasks)
			# Go straight to preparing
			var used: int = _sp_cargo_used(entry)
			var launch_cost: int = _sp_launch_cost(entry.get("ship_type", "shuttle"), used)
			if not GameState.spend_credits(float(launch_cost)):
				return
			var src_pp := GameState.get_planet(pp.planet_seed)
			if src_pp != null:
				for res_id2: String in entry.get("cargo", {}):
					GameState.global_resources[res_id2] = maxf(0.0, GameState.global_resources.get(res_id2, 0.0) - float(entry["cargo"][res_id2]))
			entry["phase"] = "preparing"
			entry["effective_duration"] = 20.0
			entry.erase("cooldown_only")
			_bar_meta.erase(pm_key)
			if ProductionManager.is_user_paused(pm_key):
				ProductionManager.toggle_user_pause(pm_key)
			rebuild_sp.call()))
	hbox.add_child(btn)

## Config phase: ship name + type selection.
func _sp_cargo_capacity(ship_type: String) -> int:
	match ship_type:
		"station":      return 60
		"heavy_hauler": return 60
		"hauler":       return 20
		_:              return 5   # shuttle

func _sp_cargo_used(entry: Dictionary) -> int:
	var total := 0
	for res_id: String in entry.get("cargo", {}):
		var rd: ResourceData = GameState.known_resources.get(res_id, null)
		if rd != null:
			total += (rd.rarity + rd.tier - 1) * int(entry["cargo"][res_id])
	return total

func _sp_launch_cost(ship_type: String, cargo_weight: int) -> int:
	match ship_type:
		"station":      return 5000
		"heavy_hauler": return 2500 + cargo_weight * 5
		"hauler":       return 800 + cargo_weight * 8
		_:              return 200 + cargo_weight * 12  # shuttle

func _sp_build_config(_card: PanelContainer, stack: Control, left_vbox: VBoxContainer,
		_hbox: HBoxContainer, _def: BuildingDef, pm_key: String, pp: PlanetProgress,
		_poi: POIData, entry: Dictionary, rebuild_sp: Callable) -> void:

	# Station limit — one per planet level (PlanetProgress.max_orbital_districts)
	var station_count: int = 0
	for s: ShipData in ShipManager.ships_for(pp.planet_seed):
		if s.ship_type == "station":
			station_count += 1
	var station_locked: bool = station_count >= pp.max_orbital_districts
	if station_locked and entry.get("ship_type", "shuttle") == "station":
		entry["ship_type"] = "shuttle"

	# Config height: title + name + type + cargo header + one grid row (56px) + bottom row
	stack.custom_minimum_size = Vector2(0, 230)
	left_vbox.add_theme_constant_override("separation", 4)

	var sub := Label.new()
	sub.text = "Mission Configuration"
	_apply_orbitron(sub, 7)
	sub.add_theme_color_override("font_color", Color(0.50, 0.70, 1.0, 0.60))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(sub)

	# ── Name row ────────────────────────────────────────────────────────────
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	left_vbox.add_child(name_row)

	var name_hint := Label.new()
	name_hint.text = "Name"
	_apply_orbitron(name_hint, 7)
	name_hint.add_theme_color_override("font_color", Color(0.50, 0.62, 0.82, 0.70))
	name_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_hint.custom_minimum_size = Vector2(32, 0)
	name_row.add_child(name_hint)

	var name_edit := LineEdit.new()
	name_edit.text = entry.get("ship_name", _sp_next_ship_name(pp.planet_seed))
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.add_theme_font_size_override("font_size", 9)
	name_edit.add_theme_color_override("font_color", Color(0.90, 0.92, 1.0))
	var le_style := StyleBoxFlat.new()
	le_style.bg_color = Color(0.07, 0.09, 0.18, 0.90)
	le_style.border_color = Color(0.22, 0.42, 0.75, 0.55)
	le_style.set_border_width_all(1); le_style.set_corner_radius_all(3)
	le_style.content_margin_left = 5; le_style.content_margin_right = 5
	le_style.content_margin_top = 3; le_style.content_margin_bottom = 3
	name_edit.add_theme_stylebox_override("normal", le_style)
	name_edit.add_theme_stylebox_override("focus",  le_style)
	name_edit.text_changed.connect(func(t: String) -> void: entry["ship_name"] = t)
	name_row.add_child(name_edit)

	# ── Type row ─────────────────────────────────────────────────────────────
	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 5)
	left_vbox.add_child(type_row)

	var type_hint := Label.new()
	type_hint.text = "Type"
	_apply_orbitron(type_hint, 7)
	type_hint.add_theme_color_override("font_color", Color(0.50, 0.62, 0.82, 0.70))
	type_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_hint.custom_minimum_size = Vector2(32, 0)
	type_row.add_child(type_hint)

	const SP_SHIP_LABELS: Dictionary = {
		"shuttle": "Shuttle", "hauler": "Hauler",
		"heavy_hauler": "Heavy", "station": "Station",
	}
	for ttype in ["shuttle", "hauler", "heavy_hauler", "station"]:
		var tb := Button.new()
		tb.text = SP_SHIP_LABELS.get(ttype, ttype.capitalize())
		_apply_orbitron(tb, 7)
		var is_sel: bool = (entry.get("ship_type", "shuttle") == ttype)
		var is_locked: bool = (ttype == "station" and station_locked)
		var tbg := Color(0.10, 0.28, 0.50, 0.95) if is_sel else Color(0.05, 0.07, 0.15, 0.75)
		if is_locked:
			tbg = Color(0.08, 0.08, 0.12, 0.60)
		var tbs := _sp_btn_style(tbg, Color(0.35, 0.65, 1.0, 0.65 if is_sel else (0.15 if is_locked else 0.28)))
		tb.add_theme_stylebox_override("normal", tbs)
		tb.add_theme_stylebox_override("hover",  tbs)
		tb.add_theme_color_override("font_color",
			Color(0.75, 0.92, 1.0) if is_sel else (Color(0.35, 0.38, 0.45) if is_locked else Color(0.45, 0.60, 0.80)))
		tb.custom_minimum_size = Vector2(54, 0)
		tb.disabled = is_locked
		if not is_locked:
			tb.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
			tb.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		var cap_t: String = ttype
		tb.pressed.connect(func() -> void:
			entry["ship_type"] = cap_t
			entry.erase("cargo")  # reset cargo when type changes (capacity differs)
			rebuild_sp.call())
		type_row.add_child(tb)

	if station_locked:
		var lock_lbl := Label.new()
		lock_lbl.text = " (limit 1)"
		_apply_orbitron(lock_lbl, 6)
		lock_lbl.add_theme_color_override("font_color", Color(0.55, 0.35, 0.35, 0.70))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		type_row.add_child(lock_lbl)

	# ── Station vs Shuttle split ──────────────────────────────────────────────
	var is_station_type: bool = entry.get("ship_type", "shuttle") == "station"

	var sep := HSeparator.new()
	left_vbox.add_child(sep)

	if is_station_type:
		var no_cargo_lbl := Label.new()
		no_cargo_lbl.text = "No cargo — station is too heavy"
		_apply_orbitron(no_cargo_lbl, 6)
		no_cargo_lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.70, 0.55))
		no_cargo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_vbox.add_child(no_cargo_lbl)

	# ── Shuttle: mission summary + Plan Mission button ────────────────────────
	if not is_station_type:
		var orbit_stations: Array[ShipData] = []
		for s: ShipData in ShipManager.ships_for(pp.planet_seed):
			if s.ship_type == "station":
				orbit_stations.append(s)

		# Show current mission summary if tasks were already planned
		var mission_tasks: Array = entry.get("mission_tasks", [])
		if not mission_tasks.is_empty():
			var sum_lbl := Label.new()
			sum_lbl.text = "%d step mission planned" % mission_tasks.size()
			_apply_orbitron(sum_lbl, 7)
			sum_lbl.add_theme_color_override("font_color", Color(0.50, 0.88, 0.65))
			sum_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			left_vbox.add_child(sum_lbl)
		else:
			var hint_lbl := Label.new()
			hint_lbl.text = "No mission — plan one below"
			_apply_orbitron(hint_lbl, 6)
			hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.45, 0.45, 0.70))
			hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			left_vbox.add_child(hint_lbl)

		var plan_btn := Button.new()
		plan_btn.text = "Plan Mission" if mission_tasks.is_empty() else "Edit Mission"
		_apply_orbitron(plan_btn, 7)
		var pbs := _sp_btn_style(Color(0.06, 0.14, 0.30, 0.90), Color(0.28, 0.52, 0.90, 0.55))
		plan_btn.add_theme_stylebox_override("normal", pbs)
		plan_btn.add_theme_stylebox_override("hover",  pbs)
		plan_btn.add_theme_color_override("font_color", Color(0.60, 0.82, 1.0))
		plan_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		plan_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		plan_btn.pressed.connect(func() -> void:
			var planet_cont: Control = planet_renderer.get_parent()
			var ctx := {
				"planet_seed": pp.planet_seed,
				"pp": pp,
				"font": _orbitron,
				"entry": entry,
				"ships": ShipManager.ships_for(pp.planet_seed),
			}
			if not mission_tasks.is_empty():
				ctx["initial_tasks"] = mission_tasks.duplicate(true)
			MissionBuilderPanel.open(planet_cont, ctx, func(tasks: Array, repeat: float) -> void:
				entry["mission_tasks"] = tasks
				entry["repeat_cycle"]  = repeat
				_sp_apply_mission_to_entry(entry, tasks)
				rebuild_sp.call()))
		left_vbox.add_child(plan_btn)

	# ── Bottom row: cost / Cancel / Start Prep ──────────────────────────────
	var used: int   = _sp_cargo_used(entry)
	var launch_cost: int = _sp_launch_cost(entry.get("ship_type", "shuttle"), used)
	var has_mission: bool = is_station_type or not entry.get("mission_tasks", []).is_empty()
	var can_afford: bool  = GameState.credits >= launch_cost and has_mission

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 6)
	left_vbox.add_child(bottom_row)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d cr" % launch_cost
	_apply_orbitron(cost_lbl, 7)
	cost_lbl.add_theme_color_override("font_color",
		Color(0.90, 0.75, 0.20) if can_afford else Color(0.90, 0.35, 0.25))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(cost_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	_apply_orbitron(cancel_btn, 7)
	var cbs := _sp_btn_style(Color(0.10, 0.07, 0.12, 0.80), Color(0.48, 0.28, 0.32, 0.55))
	cancel_btn.add_theme_stylebox_override("normal", cbs)
	cancel_btn.add_theme_stylebox_override("hover",  cbs)
	cancel_btn.add_theme_color_override("font_color", Color(0.80, 0.50, 0.52))
	cancel_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	cancel_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	cancel_btn.pressed.connect(func() -> void:
		entry["phase"] = "idle"
		entry.erase("cargo")
		entry.erase("mission_tasks")
		_bar_meta.erase(pm_key)
		rebuild_sp.call())
	bottom_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Start Prep"
	_apply_orbitron(confirm_btn, 7)
	var fbs_col := Color(0.07, 0.28, 0.16, 0.92) if can_afford else Color(0.18, 0.12, 0.12, 0.85)
	var fbs_brd := Color(0.22, 0.78, 0.42, 0.75) if can_afford else Color(0.48, 0.28, 0.28, 0.55)
	var fbs := _sp_btn_style(fbs_col, fbs_brd)
	confirm_btn.add_theme_stylebox_override("normal", fbs)
	confirm_btn.add_theme_stylebox_override("hover",  fbs)
	confirm_btn.add_theme_color_override("font_color",
		Color(0.35, 0.95, 0.58) if can_afford else Color(0.55, 0.40, 0.40))
	confirm_btn.disabled = not can_afford
	confirm_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	confirm_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	confirm_btn.pressed.connect(func() -> void:
		if not GameState.spend_credits(float(launch_cost)):
			return
		# Deduct cargo from planet storage upfront
		var src_pp2 := GameState.get_planet(pp.planet_seed)
		if src_pp2 != null:
			for res_id2: String in entry.get("cargo", {}):
				GameState.global_resources[res_id2] = maxf(0.0,
					GameState.global_resources.get(res_id2, 0.0) - float(entry["cargo"][res_id2]))
		entry["phase"] = "preparing"
		entry["effective_duration"] = 20.0
		entry.erase("cooldown_only")
		_bar_meta.erase(pm_key)
		if ProductionManager.is_user_paused(pm_key):
			ProductionManager.toggle_user_pause(pm_key)
		rebuild_sp.call())
	bottom_row.add_child(confirm_btn)

## Progress bar view — used for both "preparing" and "cooldown" phases.
func _sp_build_progress(left_vbox: VBoxContainer, hbox: HBoxContainer,
		pm_key: String, pp: PlanetProgress, entry: Dictionary,
		label_text: String, lbl_color: Color, rebuild_sp: Callable) -> void:
	var ship_desc: String = entry.get("ship_name", "")
	if ship_desc == "":
		ship_desc = label_text
	else:
		ship_desc = label_text + "  " + ship_desc

	var status := Label.new()
	status.text = ship_desc
	_apply_orbitron(status, 8)
	status.add_theme_color_override("font_color", lbl_color)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(status)

	# Queue display
	var queue: Array = entry.get("mission_queue", [])
	if not queue.is_empty():
		var q_lbl := Label.new()
		q_lbl.text = "Queue: %d" % queue.size()
		_apply_orbitron(q_lbl, 7)
		q_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 1.0, 0.75))
		q_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_vbox.add_child(q_lbl)
		for i: int in mini(queue.size(), 2):
			var qi: Dictionary = queue[i]
			var qi_lbl := Label.new()
			qi_lbl.text = "  %d. %s" % [i + 1, qi.get("ship_name", "–")]
			_apply_orbitron(qi_lbl, 6)
			qi_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85, 0.60))
			qi_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			left_vbox.add_child(qi_lbl)

	# Queue Mission button
	var q_btn := Button.new()
	q_btn.text = "Queue Mission"
	_apply_orbitron(q_btn, 7)
	var qbs := _sp_btn_style(Color(0.08, 0.16, 0.32, 0.85), Color(0.25, 0.45, 0.80, 0.55))
	q_btn.add_theme_stylebox_override("normal", qbs)
	q_btn.add_theme_stylebox_override("hover",  qbs)
	q_btn.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
	q_btn.custom_minimum_size = Vector2(100, 0)
	q_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	q_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	var cap_pm := pm_key; var cap_pp := pp; var cap_entry := entry; var cap_rebuild := rebuild_sp
	q_btn.pressed.connect(func() -> void:
		if _mission_builder_overlay != null and is_instance_valid(_mission_builder_overlay):
			_mission_builder_overlay.queue_free()
			_mission_builder_overlay = null
			return
		var qe: Dictionary = {"ship_name": _sp_next_ship_name(cap_pp.planet_seed), "ship_type": "shuttle"}
		var planet_cont: Control = planet_renderer.get_parent()
		var qctx := {
			"planet_seed": cap_pp.planet_seed, "pp": cap_pp, "font": _orbitron,
			"entry": qe, "ships": ShipManager.ships_for(cap_pp.planet_seed),
			"default_name": qe["ship_name"],
			"on_close": func() -> void: _mission_builder_overlay = null,
		}
		_mission_builder_overlay = MissionBuilderPanel.open(planet_cont, qctx, func(tasks: Array, repeat: float) -> void:
			_mission_builder_overlay = null
			var mq: Array = cap_entry.get("mission_queue", [])
			mq.append({
				"ship_name": qe.get("ship_name", ""),
				"ship_type": qe.get("ship_type", "shuttle"),
				"mission_tasks": tasks,
				"repeat_cycle": repeat,
			})
			cap_entry["mission_queue"] = mq
			cap_rebuild.call()))
	hbox.add_child(q_btn)

## Launch-ready phase: prominent Launch button.
func _sp_build_launch_ready(left_vbox: VBoxContainer, hbox: HBoxContainer,
		_def: BuildingDef, pm_key: String, pp: PlanetProgress,
		poi: POIData, entry: Dictionary, rebuild_sp: Callable) -> void:
	var ship_name: String = entry.get("ship_name", "Shuttle")
	var status := Label.new()
	status.text = ship_name + " — ready"
	_apply_orbitron(status, 8)
	status.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55, 0.90))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(status)

	var btn := Button.new()
	btn.text = "Launch ▶"
	_apply_orbitron(btn, 9)
	var bs := _sp_btn_style(Color(0.08, 0.30, 0.15, 0.92), Color(0.20, 0.85, 0.40, 0.80))
	btn.add_theme_stylebox_override("normal",  bs)
	btn.add_theme_stylebox_override("hover",   bs)
	btn.add_theme_stylebox_override("pressed", bs)
	btn.add_theme_color_override("font_color", Color(0.35, 0.98, 0.55))
	btn.custom_minimum_size = Vector2(90, 0)
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))

	var cap_pp := pp; var cap_poi := poi; var cap_entry := entry
	btn.pressed.connect(func() -> void:
		btn.text     = "Launching…"
		btn.disabled = true
		cap_pp.has_spaceport = true
		cap_entry["cooldown_only"] = true
		cap_entry["phase"] = "cooldown"
		cap_entry.erase("effective_duration")
		_bar_meta.erase(pm_key)  # erase before toggle so signal handler ignores this key
		if ProductionManager.is_user_paused(pm_key):
			ProductionManager.toggle_user_pause(pm_key)
		rebuild_sp.call()
		_play_rocket_animation(cap_pp.planet_seed, cap_poi, func() -> void: pass,
			pm_key,
			cap_entry.get("ship_name", "Pioneer"),
			cap_entry.get("ship_type", "shuttle"),
			cap_entry.get("cargo", {}),
			cap_entry.get("destination_ship_id", ""),
			cap_entry.get("transfer_dir", ""),
			cap_entry.get("transfer_resource", ""),
			cap_entry.get("transfer_amount", 0),
			cap_entry.get("auto_land", false),
			cap_entry.get("mission_tasks", [])))

	hbox.add_child(btn)

## Cargo resource selector popup — floating panel over the container.
func _sp_show_cargo_popup(entry: Dictionary, pp: PlanetProgress,
		capacity: int, rebuild_sp: Callable) -> void:
	var container: Control = planet_renderer.get_parent()

	# Full-screen overlay
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 60
	container.add_child(overlay)

	var close_popup := func() -> void:
		overlay.queue_free()
		rebuild_sp.call()

	# Dim backdrop
	var dim := Control.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.draw.connect(func() -> void:
		dim.draw_rect(Rect2(Vector2.ZERO, dim.size), Color(0, 0, 0, 0.55)))
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close_popup.call())
	overlay.add_child(dim)

	# Popup panel
	var panel := PanelContainer.new()
	panel.z_index = 1
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.08, 0.16, 0.97)
	ps.border_color = Color(0.28, 0.48, 0.80, 0.70)
	ps.set_border_width_all(1); ps.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", ps)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# Center in overlay
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(260, 0)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	# Header
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	vbox.add_child(hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "Add Cargo"
	_apply_orbitron(hdr_lbl, 9)
	hdr_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(hdr_lbl)

	var used_now := _sp_cargo_used(entry)
	var cap_lbl2 := Label.new()
	cap_lbl2.text = "%d/%d" % [used_now, capacity]
	_apply_orbitron(cap_lbl2, 7)
	cap_lbl2.add_theme_color_override("font_color",
		Color(0.40, 0.88, 0.55) if used_now <= capacity else Color(0.95, 0.38, 0.28))
	cap_lbl2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(cap_lbl2)

	vbox.add_child(HSeparator.new())

	# ── Build resource list ───────────────────────────────────────────────────
	var available_res2: Array[String] = []
	for res_id: String in GameState.global_resources:
		if GameState.global_resources.get(res_id, 0.0) >= 1.0 and GameState.known_resources.has(res_id):
			available_res2.append(res_id)
	available_res2.sort()

	if available_res2.is_empty():
		var no_res := Label.new()
		no_res.text = "No resources in storage"
		_apply_orbitron(no_res, 7)
		no_res.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60, 0.65))
		no_res.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(no_res)
	else:
		# ── Dropdown ─────────────────────────────────────────────────────────
		var dropdown := OptionButton.new()
		_apply_orbitron(dropdown, 8)
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(dropdown)

		for res_id: String in available_res2:
			var rd: ResourceData = GameState.known_resources[res_id]
			var avail_amt: int = int(GameState.global_resources.get(res_id, 0.0))
			var wt: int = rd.rarity + rd.tier - 1
			dropdown.add_item("%s  (stk:%d  %dw)" % [rd.unique_name, avail_amt, wt])

		# ── Slider row ───────────────────────────────────────────────────────
		var slider_row := HBoxContainer.new()
		slider_row.add_theme_constant_override("separation", 8)
		vbox.add_child(slider_row)

		var slider := HSlider.new()
		slider.min_value = 1
		slider.max_value = 1
		slider.step      = 1
		slider.value     = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider_row.add_child(slider)

		var amt_lbl3 := Label.new()
		amt_lbl3.text = "1"
		_apply_orbitron(amt_lbl3, 9)
		amt_lbl3.custom_minimum_size = Vector2(28, 0)
		amt_lbl3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt_lbl3.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
		amt_lbl3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slider_row.add_child(amt_lbl3)

		# Info label: stock + weight per unit
		var info_lbl := Label.new()
		info_lbl.text = ""
		_apply_orbitron(info_lbl, 6)
		info_lbl.add_theme_color_override("font_color", Color(0.42, 0.55, 0.75, 0.65))
		info_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(info_lbl)

		# Shared state for callbacks
		var sel_res_id: Array[String] = [available_res2[0]]

		var update_slider := func() -> void:
			var rid: String = sel_res_id[0]
			var rd2: ResourceData = GameState.known_resources.get(rid, null)
			if rd2 == null: return
			var avail2: int  = int(GameState.global_resources.get(rid, 0.0))
			var wt2: int     = rd2.rarity + rd2.tier - 1
			var cur_used2: int = _sp_cargo_used(entry)
			var free_weight: int = capacity - cur_used2
			var max_by_weight: int = free_weight / max(wt2, 1)
			var max_amt: int = min(avail2, max_by_weight)
			slider.max_value = max(max_amt, 1)
			slider.value     = clamp(slider.value, 1, slider.max_value)
			amt_lbl3.text = str(int(slider.value))
			info_lbl.text = "stock: %d  |  %dw/unit  |  fits: %d" % [avail2, wt2, max_amt]
			slider.editable = max_amt >= 1

		dropdown.item_selected.connect(func(idx: int) -> void:
			sel_res_id[0] = available_res2[idx]
			update_slider.call())

		slider.value_changed.connect(func(_v: float) -> void:
			amt_lbl3.text = str(int(slider.value)))

		update_slider.call()

		vbox.add_child(HSeparator.new())

		# ── Add button ────────────────────────────────────────────────────────
		var add_btn2 := Button.new()
		add_btn2.text = "Add to Cargo"
		_apply_orbitron(add_btn2, 8)
		var abs3 := _sp_btn_style(Color(0.07, 0.22, 0.12, 0.92), Color(0.22, 0.72, 0.38, 0.75))
		add_btn2.add_theme_stylebox_override("normal", abs3)
		add_btn2.add_theme_stylebox_override("hover",  abs3)
		add_btn2.add_theme_color_override("font_color", Color(0.38, 0.95, 0.55))
		add_btn2.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		add_btn2.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		add_btn2.pressed.connect(func() -> void:
			var rid2: String = sel_res_id[0]
			var amt2: int    = int(slider.value)
			if not entry.has("cargo"): entry["cargo"] = {}
			entry["cargo"][rid2] = entry["cargo"].get(rid2, 0) + amt2
			close_popup.call())
		vbox.add_child(add_btn2)

## Pick-up resource selector popup — picks what the shuttle should collect from the station.
func _sp_show_pickup_popup(entry: Dictionary, pp: PlanetProgress, rebuild_sp: Callable) -> void:
	var container: Control = planet_renderer.get_parent()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 60
	container.add_child(overlay)
	var close_popup := func() -> void:
		overlay.queue_free()
		rebuild_sp.call()
	var dim := Control.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.draw.connect(func() -> void:
		dim.draw_rect(Rect2(Vector2.ZERO, dim.size), Color(0, 0, 0, 0.55)))
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close_popup.call())
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.z_index = 1
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.10, 0.08, 0.97)
	ps.border_color = Color(0.22, 0.70, 0.38, 0.70)
	ps.set_border_width_all(1); ps.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", ps)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(240, 0)
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var hdr_lbl := Label.new()
	hdr_lbl.text = "Pick Up From Station"
	_apply_orbitron(hdr_lbl, 9)
	hdr_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.70))
	hdr_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr_lbl)
	vbox.add_child(HSeparator.new())
	# Resource list — show all known resources
	var all_res: Array[String] = []
	for res_id: String in GameState.known_resources:
		all_res.append(res_id)
	all_res.sort()
	if all_res.is_empty():
		var no_lbl := Label.new()
		no_lbl.text = "No known resources"
		_apply_orbitron(no_lbl, 7)
		no_lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.45, 0.65))
		no_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(no_lbl)
	else:
		var dropdown := OptionButton.new()
		_apply_orbitron(dropdown, 8)
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(dropdown)
		for res_id: String in all_res:
			var rd: ResourceData = GameState.known_resources[res_id]
			dropdown.add_item(rd.unique_name)
		var sel_res: Array[String] = [all_res[0]]
		var cur_res: String = entry.get("transfer_resource", "")
		if cur_res != "" and cur_res in all_res:
			dropdown.selected = all_res.find(cur_res)
			sel_res[0] = cur_res
		var slider_row := HBoxContainer.new()
		slider_row.add_theme_constant_override("separation", 8)
		vbox.add_child(slider_row)
		var slider := HSlider.new()
		slider.min_value = 1
		slider.max_value = _sp_cargo_capacity("shuttle")
		slider.step = 1
		slider.value = entry.get("transfer_amount", _sp_cargo_capacity("shuttle"))
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider_row.add_child(slider)
		var amt_lbl := Label.new()
		amt_lbl.text = str(int(slider.value))
		_apply_orbitron(amt_lbl, 9)
		amt_lbl.custom_minimum_size = Vector2(28, 0)
		amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
		amt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slider_row.add_child(amt_lbl)
		slider.value_changed.connect(func(v: float) -> void: amt_lbl.text = str(int(v)))
		dropdown.item_selected.connect(func(idx: int) -> void: sel_res[0] = all_res[idx])
		var confirm_btn := Button.new()
		confirm_btn.text = "Set Pick-up"
		_apply_orbitron(confirm_btn, 8)
		var cbs2 := _sp_btn_style(Color(0.07, 0.22, 0.12, 0.92), Color(0.22, 0.72, 0.38, 0.75))
		confirm_btn.add_theme_stylebox_override("normal", cbs2)
		confirm_btn.add_theme_stylebox_override("hover",  cbs2)
		confirm_btn.add_theme_color_override("font_color", Color(0.38, 0.95, 0.55))
		confirm_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		confirm_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		confirm_btn.pressed.connect(func() -> void:
			entry["transfer_resource"] = sel_res[0]
			entry["transfer_amount"]   = int(slider.value)
			close_popup.call())
		vbox.add_child(confirm_btn)

## Empty slot card — shows "+" and opens a build dropdown on click.
func _build_slot_card(poi: POIData, planet: PlanetData, pp: PlanetProgress,
		root: VBoxContainer, slot_idx: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.set_meta("is_slot_card", true)
	var s := StyleBoxFlat.new()
	s.bg_color      = Color(0.06, 0.08, 0.14, 0.70)
	s.border_width_left  = 1; s.border_width_right  = 1
	s.border_width_top   = 1; s.border_width_bottom = 1
	s.border_color  = Color(0.28, 0.35, 0.60, 0.35)
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	card.add_theme_stylebox_override("panel", s)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 38)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24)
	card.add_child(margin)

	var plus := Label.new()
	plus.text = "+ Empty Slot"
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_orbitron(plus, 10)
	plus.add_theme_color_override("font_color", Color(0.30, 0.38, 0.65, 0.70))
	margin.add_child(plus)

	card.mouse_entered.connect(func() -> void:
		AudioManager.play("poi_hover")
		CursorManager.set_state(CursorManager.State.POINTER)
		plus.add_theme_color_override("font_color", Color(0.55, 0.65, 1.0, 0.9)))
	card.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		plus.add_theme_color_override("font_color", Color(0.30, 0.38, 0.65, 0.70)))
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			_toggle_slot_dropdown(card, poi, planet, pp, root, slot_idx))
	return card

## Open building picker: its arguments and what made its rows enabled, so it
## can rebuild itself when resources arrive (no close / reopen needed).
var _slot_dd_args: Array = []
var _slot_dd_sig: String = ""
var _slot_dd_poll: float = 0.0

## Which picker rows are affordable right now (credits + free population).
func _slot_dd_signature() -> String:
	if _slot_dd_args.size() < 4:
		return ""
	var poi: POIData = _slot_dd_args[1]
	var planet: PlanetData = _slot_dd_args[2]
	var pp: PlanetProgress = _slot_dd_args[3]
	var free_pop := Economy.free_population(planet, pp)
	var sig := ""
	for def: BuildingDef in BuildingDef.for_poi_and_planet(poi.poi_type, planet.planet_type):
		sig += "1" if Economy.can_pay(Economy.building_full_cost(pp, def, poi.label)) and free_pop >= def.pop_use() else "0"
	return sig

## Called from _process: rebuilds an open picker when a row's state changed.
func _poll_slot_dropdown(delta: float) -> void:
	if _active_slot_dropdown == null or not is_instance_valid(_active_slot_dropdown):
		return
	_slot_dd_poll += delta
	if _slot_dd_poll < 0.25:
		return
	_slot_dd_poll = 0.0
	var sig := _slot_dd_signature()
	if sig == _slot_dd_sig:
		return
	var args := _slot_dd_args.duplicate()
	if not is_instance_valid(args[0]):
		return
	if is_instance_valid(_dd_layer):
		_dd_layer.queue_free()
	_dd_layer = null
	_active_slot_dropdown = null
	_toggle_slot_dropdown(args[0], args[1], args[2], args[3], args[4], args[5])

func _toggle_slot_dropdown(card: PanelContainer, poi: POIData, planet: PlanetData,
		pp: PlanetProgress, root: VBoxContainer, _slot_idx: int) -> void:
	# Toggle off if already open for this slot
	if _active_slot_dropdown != null and is_instance_valid(_active_slot_dropdown):
		var prev_card = _active_slot_dropdown.get_meta("slot_card", null)
		_active_slot_dropdown.queue_free()
		_active_slot_dropdown = null
		if prev_card == card:
			# Tutorial: restore slot card highlight when dropdown is closed
			var tut_bid := TutorialManager.get_action_building_target()
			if tut_bid != "" and is_instance_valid(card):
				_tut_highlight_node = card as Control
				_start_tut_node_pulse(_tut_highlight_node)
			return

	var buildable := BuildingDef.for_poi_and_planet(poi.poi_type, current_data.planet_type)
	if buildable.is_empty():
		return
	_slot_dd_args = [card, poi, planet, pp, root, _slot_idx]
	_slot_dd_sig = _slot_dd_signature()

	var slots_free: int = pp.district_slots(poi) - pp.slots_used_in_district(poi.label)

	# ── CanvasLayer overlay — always renders above game UI ───────────
	if _dd_layer == null or not is_instance_valid(_dd_layer):
		_dd_layer = CanvasLayer.new()
		_dd_layer.layer = 120   # above HUD (100) but below tooltip (150)
		add_child(_dd_layer)

	var outer := PanelContainer.new()
	outer.set_meta("slot_card", card)
	outer.add_theme_stylebox_override("panel",
		_make_hud_style(Color(0.05, 0.07, 0.14, 0.97), 6))

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	outer.add_child(list)

	for def: BuildingDef in buildable:
		if def.min_planet_lv > pp.level:
			continue
		if def.planet_limit_reached(pp):
			continue   # unique on the planet (Spaceport …) and already built
		var full_cost := Economy.building_full_cost(pp, def, poi.label)
		var can_afford: bool = Economy.can_pay(full_cost)
		var has_slots:  bool = slots_free >= def.slot_cost
		
		var at_limit: bool = false
		if def.max_per_district > 0:
			var count_in_dist := 0
			for e in pp.buildings:
				if e.get("district_id", "") == poi.label and e.get("building_id", "") == def.building_id:
					count_in_dist += 1
			if count_in_dist >= def.max_per_district:
				at_limit = true
				
		var site_reason := def.site_block_reason(poi)
		if site_reason != "":
			continue   # site-only buildings show up only where the site allows them
		var pop_need := def.pop_use()
		var has_pop: bool = Economy.free_population(planet, pp) >= pop_need
		var enabled: bool    = can_afford and has_slots and not at_limit and site_reason == ""

		var row_panel := PanelContainer.new()
		var norm_s := StyleBoxFlat.new()
		norm_s.bg_color = Color(0, 0, 0, 0)
		norm_s.content_margin_left = 10; norm_s.content_margin_right  = 10
		norm_s.content_margin_top  = 7;  norm_s.content_margin_bottom = 7
		var hov_s := norm_s.duplicate() as StyleBoxFlat
		hov_s.bg_color = Color(0.12, 0.18, 0.35, 0.60)
		row_panel.add_theme_stylebox_override("panel", norm_s)
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var n_lbl := Label.new()
		n_lbl.text = def.display_name
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_orbitron(n_lbl, 10)
		n_lbl.add_theme_color_override("font_color",
			Color(0.80, 0.88, 1.0) if enabled else Color(0.38, 0.40, 0.55))

		var reason := ""
		if site_reason != "": reason = site_reason
		elif at_limit: reason = "Limit reached"
		elif not has_slots: reason = "No free slots"
		elif not can_afford: reason = Economy.cost_block(full_cost)
		elif not has_pop: reason = "Population will exceed housing — output drops until you build more homes."

		# Compact sub-line: RichTextLabel so we can embed inline mineral icon
		var row_color := Color(0.45, 0.72, 0.40) if enabled else Color(0.60, 0.30, 0.28)

		var c_lbl := RichTextLabel.new()
		c_lbl.bbcode_enabled  = true
		c_lbl.fit_content     = true
		c_lbl.scroll_active   = false
		c_lbl.mouse_filter    = Control.MOUSE_FILTER_IGNORE
		c_lbl.add_theme_font_size_override("normal_font_size", 8)
		c_lbl.add_theme_color_override("default_color", row_color)
		if _orbitron: c_lbl.add_theme_font_override("normal_font", _orbitron)
		c_lbl.custom_minimum_size = Vector2(0, 14)

		# What one more of these would add here (same numbers the engine uses)
		var preview_entry := {"amount": 1, "district_id": poi.label, "building_id": def.building_id}
		var out_preview := _entry_output_text(pp, preview_entry, def)
		var in_preview := def.input_label()
		c_lbl.append_text(Economy.cost_text(full_cost))
		if pop_need > 0:
			c_lbl.append_text(" · ☺%s" % Economy.fmt(pop_need))
		if out_preview != "":
			c_lbl.append_text(" · " + out_preview)
		if def.energy_per_tick < 0.0:
			c_lbl.append_text(" · %.0f ⚡" % def.energy_per_tick)
		if in_preview != "":
			c_lbl.append_text(" · " + in_preview)

		vbox.add_child(n_lbl); vbox.add_child(c_lbl)
		row_panel.set_meta("building_id", def.building_id)
		row_panel.add_child(vbox)
		list.add_child(row_panel)

		var cap_poi    := poi
		var cap_def    := def
		var cap_planet := planet
		var cap_row    := row_panel
		var cap_norm   := norm_s
		var cap_hov    := hov_s
		var tip_title := def.display_name

		# ── Dynamic stat calculation ────────────────────────────────
		var sk := get_node("/root/SkillTree")
		var spd_mult: float = sk.get_global_speed_mult()
		if def.outputs.has(Economy.RAW):
			spd_mult *= sk.get_mine_speed_mult()
		var cycle_s := def.tick_duration
		if cycle_s > 0.0 and spd_mult > 0.0:
			cycle_s = cycle_s / spd_mult

		# ── Body: description + stat rows ───────────────────────────
		# Order: Cycle, then production (+), then upkeep (−).
		var tip_body_parts: Array = [def.description, "\n\n"]
		tip_body_parts.append("Cost      " + _full_cost_bb(full_cost, pop_need, planet, pp) + "\n")
		var gains: Array[String] = []
		for oid: String in def.outputs:
			gains.append(_res_bb(oid, ProductionManager.output_per_cycle(pp, preview_entry, def, oid)))
		for bid_: String in def.planet_bonus:
			gains.append(_bb("+%d%% %s %s" % [int(round(float(def.planet_bonus[bid_]) * 100.0)),
				Economy.INFO.get(bid_, {}).get("short", bid_), "planet-wide" if def.planet_wide else "in this city"],
				Economy.color_of(bid_)))
		for sid: String in def.storage:
			gains.append(_bb("+%s %s storage" % [Economy.fmt(float(def.storage[sid])),
				Economy.INFO.get(sid, {}).get("short", sid)], Economy.color_of(sid) if sid != Economy.RAW else Color(0.85, 0.78, 0.70)))
		if not gains.is_empty():
			tip_body_parts.append("Makes     " + "  ".join(gains) + _bb("  /%.0fs" % cycle_s, BB_DIM) + "\n")
		var costs: Array[String] = []
		if def.energy_per_tick < 0.0:
			costs.append(_res_bb(Economy.ENERGY, def.energy_per_tick * float(sk.get_energy_consume_mult()), "−"))
		for iid: String in def.inputs:
			costs.append(_res_bb(iid, float(def.inputs[iid]), "−"))
		if not costs.is_empty():
			tip_body_parts.append("Upkeep    " + "  ".join(costs) + "\n")
		var b_time: float = def.construct_duration if def.construct_duration > 0.0 else def.tick_duration
		tip_body_parts.append(_bb("Build %.0fs%s" % [b_time, "  ·  %d slots" % def.slot_cost if def.slot_cost > 1 else ""], BB_DIM))
		if reason != "":
			tip_body_parts.append("\n\n" + _bb("➡ " + reason, BB_BAD if not enabled else BB_WARN))
		var tip_cost := Economy.cost_text(full_cost)
		tip_body_parts.append("\n" + _bb(BULK_HINT, BB_DIM))

		row_panel.mouse_entered.connect(func() -> void:
			AudioManager.play("poi_hover")
			cap_row.add_theme_stylebox_override("panel", cap_hov)
			if enabled and not _is_at_edge():
				CursorManager.set_state(CursorManager.State.POINTER)
			TooltipManager.show_tip(tip_title, tip_body_parts, tip_cost))
		row_panel.mouse_exited.connect(func() -> void:
			cap_row.add_theme_stylebox_override("panel", cap_norm)
			CursorManager.set_state(CursorManager.State.NORMAL)
			TooltipManager.hide_tip())

		var cap_overlay := outer
		if enabled:
			row_panel.gui_input.connect(func(e: InputEvent) -> void:
				if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
						and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
					if _buy_buildings(cap_poi, cap_planet, cap_def, _bulk_count()) > 0:
						if is_instance_valid(cap_overlay):
							cap_overlay.queue_free()
						_active_slot_dropdown = null
						_build_district_panel(cap_poi, cap_planet))

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			if is_instance_valid(_dd_layer):
				_dd_layer.queue_free()
				_dd_layer = null
			_active_slot_dropdown = null
			# Tutorial: restore slot card highlight when dropdown is closed
			var tut_bid := TutorialManager.get_action_building_target()
			if tut_bid != "" and is_instance_valid(card):
				_tut_highlight_node = card as Control
				_start_tut_node_pulse(_tut_highlight_node)
	)
	_dd_layer.add_child(bg)
	_dd_layer.add_child(outer)
	# CanvasLayer children use screen-space coordinates directly
	await get_tree().process_frame
	if not is_instance_valid(outer):
		return
	var card_rect := card.get_global_rect()
	outer.position            = Vector2(card_rect.position.x, card_rect.end.y)
	outer.custom_minimum_size = Vector2(card_rect.size.x, 0)
	_active_slot_dropdown = outer
	# Tutorial: highlight target building row and disable all others
	var tut_bid := TutorialManager.get_action_building_target()
	if tut_bid != "":
		for row in list.get_children():
			if not row.has_meta("building_id"): continue
			if row.get_meta("building_id") == tut_bid:
				_tut_highlight_node = row as Control
				_start_tut_node_pulse(_tut_highlight_node)
			else:
				row.set_meta("tut_disabled", true)
				row.modulate = Color(0.35, 0.35, 0.45, 0.5)

func _toggle_mineral_dropdown(btn: Control, raw_list: Array, target_key: String, current_tgt: String, poi: POIData, planet: PlanetData, entry: Dictionary) -> void:
	if _active_slot_dropdown != null and is_instance_valid(_active_slot_dropdown):
		var prev_btn = _active_slot_dropdown.get_meta("trigger_btn", null)
		_active_slot_dropdown.queue_free()
		_active_slot_dropdown = null
		if prev_btn == btn:
			return

	if _dd_layer == null or not is_instance_valid(_dd_layer):
		_dd_layer = CanvasLayer.new()
		_dd_layer.layer = 120
		add_child(_dd_layer)

	var outer := PanelContainer.new()
	outer.set_meta("trigger_btn", btn)
	var tray_style := StyleBoxFlat.new()
	tray_style.bg_color = Color(0.05, 0.07, 0.12, 0.95)
	tray_style.border_color = Color(0.2, 0.25, 0.4, 0.7)
	tray_style.set_border_width_all(1)
	tray_style.corner_radius_top_left = 4
	tray_style.corner_radius_top_right = 4
	tray_style.corner_radius_bottom_left = 4
	tray_style.corner_radius_bottom_right = 4
	tray_style.content_margin_left = 6
	tray_style.content_margin_right = 6
	tray_style.content_margin_top = 4
	tray_style.content_margin_bottom = 4
	outer.add_theme_stylebox_override("panel", tray_style)

	var tray_h := HBoxContainer.new()
	tray_h.add_theme_constant_override("separation", 6)
	outer.add_child(tray_h)

	for alternative: ResourceData in raw_list:
		var is_current := alternative.resource_id() == current_tgt
		var alt_btn := Button.new()
		alt_btn.flat = true
		alt_btn.focus_mode = Control.FOCUS_NONE
		alt_btn.custom_minimum_size = Vector2(28, 28)
		
		var alt_icon := TextureRect.new()
		alt_icon.texture = MineralIcon.make(alternative.tier, alternative.display_color)
		alt_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		alt_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		alt_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alt_btn.add_child(alt_icon)
		alt_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

		var alt_style := StyleBoxFlat.new()
		alt_style.bg_color = Color(0.1, 0.12, 0.2, 0.8)
		alt_style.border_color = alternative.display_color.darkened(0.3)
		if is_current:
			alt_style.bg_color = Color(0.15, 0.25, 0.15, 0.9)
			alt_style.border_color = Color(0.4, 0.8, 0.4, 0.8)
		alt_style.set_border_width_all(1)
		alt_style.corner_radius_top_left = 3
		alt_style.corner_radius_top_right = 3
		alt_style.corner_radius_bottom_left = 3
		alt_style.corner_radius_bottom_right = 3
		alt_btn.add_theme_stylebox_override("normal", alt_style)

		var alt_hover := alt_style.duplicate() as StyleBoxFlat
		alt_hover.bg_color = Color(0.15, 0.18, 0.3, 0.95)
		alt_hover.border_color = alternative.display_color
		alt_btn.add_theme_stylebox_override("hover", alt_hover)
		
		if is_current:
			alt_btn.disabled = true
			alt_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			alt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var cap_target_key := target_key
		var cap_alternative := alternative
		var cap_poi := poi
		var cap_planet := planet
		var cap_entry := entry
		var cap_outer := outer
		alt_btn.pressed.connect(func() -> void:
			cap_entry[cap_target_key] = cap_alternative.resource_id()
			if is_instance_valid(cap_outer):
				cap_outer.queue_free()
			_active_slot_dropdown = null
			_build_district_panel(cap_poi, cap_planet))
		
		alt_btn.mouse_entered.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.POINTER)
			TooltipManager.show_tip("Switch to:", cap_alternative.unique_name))
		alt_btn.mouse_exited.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.NORMAL)
			TooltipManager.hide_tip())

		tray_h.add_child(alt_btn)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			if is_instance_valid(_dd_layer):
				_dd_layer.queue_free()
				_dd_layer = null
			_active_slot_dropdown = null
	)
	_dd_layer.add_child(bg)
	_dd_layer.add_child(outer)
	await get_tree().process_frame
	if not is_instance_valid(outer):
		return
	var btn_rect := btn.get_global_rect()
	outer.position = Vector2(btn_rect.position.x, btn_rect.end.y)
	_active_slot_dropdown = outer

## The City as a whole: its Capital District + districts, founding new ones and
## the City level. Opened from a City icon zoomed out or a City card.
var _city_scroll: ScrollContainer = null
var _city_scroll_label := ""

# ── Orbit (a unique City-like hub of Space Stations) ────────────────────────

## Older saves had stations but no Orbit — give them one big enough.
func _migrate_orbit(data: PlanetData) -> void:
	var pp := GameState.get_planet(data.seed)
	var n := Leveling.orbit_stations(data).size()
	if pp.orbit_level < n:
		pp.orbit_level = clampi(n, 1, Leveling.max_orbit_level())
		pp.recalculate_limits()

func _orbit_card_shell(enabled: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := _card_panel_style()
	sb.bg_color = Color(0.06, 0.08, 0.18, 0.85) if enabled else Color(0.05, 0.06, 0.10, 0.45)
	sb.border_color = Color(0.55, 0.50, 1.0, 0.55) if enabled else Color(0.25, 0.25, 0.38, 0.4)
	card.add_theme_stylebox_override("panel", sb)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 48)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card

## The Orbit in the Cities list — opens its panel.
func _build_orbit_card(data: PlanetData, pp: PlanetProgress) -> PanelContainer:
	var card := _orbit_card_shell(true)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 8 if side != "left" else 10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	h.add_child(_level_badge(pp.orbit_level, true))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(info)
	var n := Label.new()
	n.text = "Orbit"
	_apply_orbitron(n, 10)
	n.add_theme_color_override("font_color", Color(0.82, 0.80, 1.0))
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(n)
	var t := Label.new()
	t.text = "Space Stations  %d / %d" % [Leveling.orbit_stations(data).size(), pp.orbit_level]
	_apply_orbitron(t, 7)
	t.add_theme_color_override("font_color", Color(0.50, 0.55, 0.80))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(t)
	card.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	card.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			_build_orbit_panel(data))
	return card

## The Orbit is offered as a second City type in FOUND CITY — one per planet,
## and only beside a surface City. It shows before it can be founded (greyed,
## with the reason) so players can find it.
func _orbit_option_visible(data: PlanetData) -> bool:
	var pp := GameState.get_planet(data.seed)
	var def := DistrictDef.find(DistrictDef.Type.SPACE_STATION)
	if def == null or not (def.allowed_planet_types.is_empty() or data.planet_type in def.allowed_planet_types):
		return false
	# offered only once Orbital Assembly is researched: before that the card
	# founds a City straight away (its only option)
	return pp.orbit_level == 0 and _city_count(data) > 0 \
		and get_node("/root/SkillTree").is_unlocked("orbital_assembly")

## Why the Orbit can't be founded right now ("" when it can).
func _orbit_found_block(data: PlanetData) -> String:
	var pp := GameState.get_planet(data.seed)
	if not get_node("/root/SkillTree").is_unlocked("orbital_assembly"):
		return "Research Orbital Assembly"
	if not _has_finished_building(pp, "spaceport"):
		return "Build a Spaceport to launch stations"
	if GameState.credits < DistrictDef.placement_cost(DistrictDef.find(DistrictDef.Type.CITY), data):
		return "Not enough credits"
	return ""

## "◈ Orbit" row in the FOUND CITY dropdown.
func _build_orbit_type_row(data: PlanetData, dropdown_ref: Array[Node]) -> Control:
	var cost := DistrictDef.placement_cost(DistrictDef.find(DistrictDef.Type.CITY), data)
	var block := _orbit_found_block(data)
	var btn := Button.new()
	btn.flat = true
	btn.text = "◈  Orbit"
	_apply_orbitron(btn, 9)
	btn.disabled = block != ""
	btn.add_theme_color_override("font_color", Color(0.78, 0.74, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.6) if block != "Not enough credits" else Color(0.9, 0.3, 0.3))
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0, 0, 0, 0)
	norm.content_margin_left = 10; norm.content_margin_right = 10
	norm.content_margin_top = 6; norm.content_margin_bottom = 6
	var hov := norm.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.16, 0.14, 0.35, 0.60)
	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_stylebox_override("disabled", norm)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var pp := GameState.get_planet(data.seed)
	var tip := "The world's Central Orbit — one per planet, it takes no City slot. Its first station is the hub of your trade network; every district you add launches a smaller satellite station (one module each); level the Orbit for more.\n\nCost  " \
		+ _cost_bb(cost, 0, data, pp) + ("" if block == "" else "\n\n" + _bb("➡ " + block, BB_BAD))
	btn.mouse_entered.connect(func() -> void:
		AudioManager.play("district_hover")
		TooltipManager.show_tip("Orbit", tip, HUDManager.fmt_credits(cost)))
	btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	btn.pressed.connect(func() -> void:
		if dropdown_ref[0] != null and is_instance_valid(dropdown_ref[0]):
			dropdown_ref[0].queue_free()
			dropdown_ref[0] = null
		TooltipManager.hide_tip()
		if _orbit_found_block(data) != "" or not GameState.spend_credits(cost):
			AudioManager.play("error")
			return
		pp.orbit_level = 1
		pp.recalculate_limits()
		GameState.planet_progress_changed.emit(data.seed)
		_orbit_panel_open = true   # stay in the new Orbit while its first station flies
		_launch_station(data, true))
	return btn

func _has_finished_building(pp: PlanetProgress, building_id: String) -> bool:
	for b: Dictionary in pp.buildings:
		if b.get("building_id", "") == building_id and not b.get("constructing", false):
			return true
	return false

## Launches one Space Station (free when `free` — the Orbit's first).
func _launch_station(data: PlanetData, free := false) -> void:
	var pp := GameState.get_planet(data.seed)
	var def := DistrictDef.find(DistrictDef.Type.SPACE_STATION)
	if def == null or Leveling.orbit_stations(data).size() >= pp.orbit_level:
		AudioManager.play("error")
		return
	if not free and not GameState.spend_credits(DistrictDef.placement_cost(def, data)):
		AudioManager.play("error")
		return
	_spawn_district(data, def.suggest_name(data), def)

func _build_orbit_panel(planet: PlanetData) -> void:
	_active_district_poi = null
	_city_panel_poi = null
	_orbit_panel_open = true
	_nav_visit(planet, {"orbit": true}, "Orbit")
	var panel_content := $SidePanel/PanelContent
	var old := panel_content.get_node_or_null("DistrictBuildPanel")
	if old:
		old.name = "__freeing_district__"
		old.queue_free()
		_bar_meta.clear()
	var pp := GameState.get_planet(planet.seed)
	var lv := pp.orbit_level
	var stations := Leveling.orbit_stations(planet)
	var root := VBoxContainer.new()
	root.name = "DistrictBuildPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	root.add_child(HSeparator.new())
	var back := Button.new()
	back.text = "‹  " + planet.planet_name
	back.flat = true
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.focus_mode = Control.FOCUS_NONE
	_apply_orbitron(back, 9)
	back.add_theme_color_override("font_color", Color(0.55, 0.70, 1.0))
	back.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_build_planet_overview(planet))
	root.add_child(back)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Orbit"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(title, 12)
	title.add_theme_color_override("font_color", Color(0.80, 0.76, 1.0))
	header.add_child(title)
	header.add_child(_level_badge(lv, true))
	root.add_child(header)
	var info := Label.new()
	info.text = "Stations  %d / %d   ·   one module each" % [stations.size(), lv]
	_apply_orbitron(info, 8)
	info.add_theme_color_override("font_color", Color(0.55, 0.60, 0.85))
	root.add_child(info)

	var body_scroll := ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_scroll(body_scroll)
	root.add_child(body_scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)
	_poi_overview_cards.clear()
	for st: POIData in stations:
		body.add_child(_build_district_overview_card(st, planet, pp, panel_content, body))
	# each district added here launches one more Space Station
	var d_hdr := Label.new()
	d_hdr.text = "DISTRICTS"
	_apply_orbitron(d_hdr, 9)
	d_hdr.add_theme_color_override("font_color", Color(0.50, 0.58, 0.80))
	body.add_child(d_hdr)
	if stations.size() < lv:
		body.add_child(_build_add_district_card(planet, true, true))
	else:
		var full := Label.new()
		full.text = "ORBIT FULL — LEVEL UP THE ORBIT"
		full.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_orbitron(full, 8)
		full.add_theme_color_override("font_color", Color(0.45, 0.48, 0.62))
		body.add_child(full)
	body.move_child(d_hdr, 0)

	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new(); sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	sep.add_theme_stylebox_override("separator", sep_s)
	root.add_child(sep)
	root.add_child(_build_orbit_level_row(planet, pp))
	panel_content.add_child(root)

func _build_orbit_level_row(planet: PlanetData, pp: PlanetProgress) -> Button:
	var lv := pp.orbit_level
	var next := lv + 1
	var credits := Leveling.orbit_level_credits(next)
	var block := Leveling.orbit_level_block(planet, pp)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(btn, 9)
	btn.text = "ORBIT  Lv %d → Lv %d  ◈ %s" % [lv, next, HUDManager.fmt_credits(credits)] if lv < Leveling.max_orbit_level() else "ORBIT  MAX LEVEL"
	_live_enable(btn, func() -> bool:
		return Leveling.orbit_level_block(planet, pp) == "" and GameState.credits >= credits)
	var tip := "Raise the Orbit to Lv %d:\n%s\n\nCost  %s\n%s" % [next,
		_bb("+1 Space Station slot (%d → %d)" % [lv, next], Color(0.75, 0.70, 1.0)),
		_cost_bb(credits, 0, planet, pp),
		_bb("Needs every station launched with its module built.", BB_DIM)]
	if block != "":
		tip += "\n\n" + _bb("➡ " + block, BB_BAD)
	btn.mouse_entered.connect(func() -> void: TooltipManager.show_tip("Orbit level up", tip))
	btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	btn.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if Leveling.orbit_level_block(planet, pp) != "" or not GameState.spend_credits(credits):
			AudioManager.play("error")
			return
		AudioManager.play("construct")
		pp.orbit_level = next
		pp.recalculate_limits()
		GameState.planet_progress_changed.emit(planet.seed)
		_build_orbit_panel(planet))
	return btn

func _build_city_panel(city: POIData, planet: PlanetData) -> void:
	_orbit_panel_open = false
	var keep_scroll := 0
	if _city_scroll != null and is_instance_valid(_city_scroll) and _city_scroll_label == city.label:
		keep_scroll = _city_scroll.scroll_vertical
	_active_district_poi = null
	_city_panel_poi = city
	_nav_visit(planet, {"city": city.label}, city.display_name)
	var panel_content := $SidePanel/PanelContent
	var old := panel_content.get_node_or_null("DistrictBuildPanel")
	if old:
		old.name = "__freeing_district__"
		old.queue_free()
		_bar_meta.clear()
	var pp := GameState.get_planet(planet.seed)
	var lv := Leveling.city_level(pp, city)
	var root := VBoxContainer.new()
	root.name = "DistrictBuildPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	root.add_child(HSeparator.new())

	if GameState.planet_view_unlocked:
		var back := Button.new()
		back.text = "‹  " + planet.planet_name
		back.flat = true
		back.alignment = HORIZONTAL_ALIGNMENT_LEFT
		back.focus_mode = Control.FOCUS_NONE
		_apply_orbitron(back, 9)
		back.add_theme_color_override("font_color", Color(0.55, 0.70, 1.0))
		back.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
		back.pressed.connect(func() -> void:
			AudioManager.play("click")
			_city_panel_poi = null
			_build_planet_overview(planet))
		root.add_child(back)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = city.shown_name() + "  ·  City"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(title, 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	header.add_child(title)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv %d" % lv
	_apply_orbitron(lv_lbl, 11)
	lv_lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 1.0))
	header.add_child(lv_lbl)
	root.add_child(header)

	# City stats
	var count := Leveling.city_district_count(planet, city)
	var max_d := Leveling.city_max_districts(lv)
	var have := Leveling.city_district_levels(planet, pp, city)
	var need := Leveling.city_level_req(lv + 1)
	for row: Array in [
		["Districts", "%d / %d" % [count, max_d], Color(1.0, 0.45, 0.35) if count >= max_d else Color(0.80, 0.85, 1.0)],
		["District levels", "%d / %d for Lv %d" % [have, need, lv + 1], Color(0.55, 0.95, 0.60) if have >= need else Color(0.80, 0.85, 1.0)],
	]:
		var r := HBoxContainer.new()
		var k := Label.new()
		k.text = row[0]
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_orbitron(k, 8)
		k.add_theme_color_override("font_color", Color(0.45, 0.50, 0.65))
		var v := Label.new()
		v.text = row[1]
		_apply_orbitron(v, 8)
		v.add_theme_color_override("font_color", row[2])
		r.add_child(k); r.add_child(v)
		root.add_child(r)

	# Districts
	var body_scroll := ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_scroll(body_scroll)
	root.add_child(body_scroll)
	_city_scroll = body_scroll
	_city_scroll_label = city.label
	body_scroll.call_deferred("set", "scroll_vertical", keep_scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)
	var d_hdr := Label.new()
	d_hdr.text = "DISTRICTS"
	_apply_orbitron(d_hdr, 9)
	d_hdr.add_theme_color_override("font_color", Color(0.50, 0.58, 0.80))
	body.add_child(d_hdr)
	var add_card := _build_add_district_card(planet, count < max_d, false, city)
	if count >= max_d and add_card.get_child_count() > 0:
		var full_lbl := add_card.find_children("*", "Label", true, false)
		for l in full_lbl:
			if (l as Label).text == "SLOTS FULL":
				(l as Label).text = "CITY FULL — LEVEL UP THE CITY"
	body.add_child(add_card)
	_poi_overview_cards.clear()
	body.add_child(_build_district_overview_card(city, planet, pp, panel_content, body, true))
	for child: POIData in planet.custom_pois:
		if child.parent_city == city.label and not child.is_orbital():
			body.add_child(_build_district_overview_card(child, planet, pp, panel_content, body))
	if TutorialManager.get_action_step_type() == "district" and add_card.get_child_count() > 0:
		_tut_highlight_node = add_card.get_child(0) as Control
		_start_tut_node_pulse(_tut_highlight_node)

	# City level up
	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new(); sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	sep.add_theme_stylebox_override("separator", sep_s)
	root.add_child(sep)
	root.add_child(_build_city_level_row(city, planet, pp))
	panel_content.add_child(root)

## Construction-style fill (black/yellow hazard stripes, crawling) drawn behind
## its parent control; `progress` returns 0..1 and is polled while visible.
func _hazard_fill(progress: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.show_behind_parent = true
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(func() -> void: _paint_hazard(c, float(progress.call())))
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(c.queue_redraw)
	c.add_child(t)
	return c

## The one look for anything being built or levelled (buildings, districts,
## Cities): crawling black/yellow stripes filling left → right.
static func _paint_hazard(c: Control, progress: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.10, 0.09, 0.05, 0.9))
	var w := c.size.x * clampf(progress, 0.0, 1.0)
	const STRIPE := 8.0
	var shift := fmod(float(Time.get_ticks_msec()) / 40.0, STRIPE * 2.0)
	var y := 0.0
	while y < c.size.y:   # diagonal stripes, built row by row from rects
		var x := -STRIPE * 2.0 + fmod(shift + y, STRIPE * 2.0)
		while x < w:
			var x0 := maxf(x, 0.0)
			var x1 := minf(x + STRIPE, w)
			if x1 > x0:
				c.draw_rect(Rect2(x0, y, x1 - x0, 2.0), Color(1.0, 0.82, 0.15, 0.32))
			x += STRIPE * 2.0
		y += 2.0
	if w > 1.0:
		c.draw_rect(Rect2(w - 2.0, 0, 2.0, c.size.y), Color(1.0, 0.82, 0.15, 0.7))

## The one look for anything producing on a cycle (buildings, districts,
## Cities): the card fills in its resource's colour, bright leading edge.
static func _paint_cycle(c: Control, progress: float, col: Color) -> void:
	var w := c.size.x * clampf(progress, 0.0, 1.0)
	if w > 0.5:
		c.draw_rect(Rect2(0, 0, w, c.size.y), Color(col.r, col.g, col.b, 0.20))
		c.draw_rect(Rect2(w - 2.0, 0, 2.0, c.size.y), Color(col.r, col.g, col.b, 0.55))

## Card-sized production fill behind a card's content (see _paint_cycle).
func _cycle_fill(progress: Callable, col: Color) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.show_behind_parent = true
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(func() -> void: _paint_cycle(c, float(progress.call()), col))
	var t := Timer.new()
	t.wait_time = 0.1
	t.autostart = true
	t.timeout.connect(c.queue_redraw)
	c.add_child(t)
	return c

## "CITY LEVEL UP" — needs enough district levels in the City; costs credits +
## population; each level lets the City hold more districts.
func _build_city_level_row(city: POIData, planet: PlanetData, pp: PlanetProgress) -> Button:
	var lv := Leveling.city_level(pp, city)
	var next := lv + 1
	var credits := Leveling.city_level_credits(next)
	var pop := Leveling.city_level_pop(next)
	var block := Leveling.city_level_block(planet, pp, city)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(btn, 9)
	var upgrading := pp.city_upgrading.has(city.label)
	btn.text = "CITY  Lv %d → Lv %d  ◈ %s  ☺ %s" % [lv, next, HUDManager.fmt_credits(credits), Economy.fmt(pop)]
	if upgrading:
		btn.text = "CITY  Lv %d → Lv %d  ·  LEVELLING UP…" % [lv, next]
		btn.add_child(_hazard_fill(func() -> float: return float(pp.city_upgrading.get(city.label, 1.0))))
	_live_enable(btn, func() -> bool:
		return Leveling.city_level_block(planet, pp, city) == "" and GameState.credits >= credits)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.20, 0.12, 0.85)
	st.border_color = Color(0.35, 0.80, 0.45, 0.6)
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.content_margin_top = 6; st.content_margin_bottom = 6
	var hov := st.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.12, 0.30, 0.18, 0.95)
	var dis := st.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.08, 0.09, 0.14, 0.7)
	dis.border_color = Color(0.25, 0.28, 0.40, 0.5)
	if upgrading:
		dis.bg_color = Color(0, 0, 0, 0)   # let the hazard fill behind it show
		dis.border_color = Color(1.0, 0.82, 0.15, 0.6)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_color", Color(0.70, 1.0, 0.75))
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.9, 0.6) if upgrading else Color(0.45, 0.48, 0.60))
	var tip := "Raise %s to Lv %d:\n%s\n\nCost  %s\n%s" % [city.shown_name(), next,
		_bb("+%d districts allowed (%d → %d)" % [Leveling.city_max_districts(next) - Leveling.city_max_districts(lv),
			Leveling.city_max_districts(lv), Leveling.city_max_districts(next)], Economy.color_of(Economy.POPULATION)),
		_cost_bb(credits, pop, planet, pp),
		_bb("Needs %d total district levels in the City." % Leveling.city_level_req(next), BB_DIM)]
	if block != "":
		tip += "\n\n" + _bb("➡ " + block, BB_BAD)
	btn.mouse_entered.connect(func() -> void: TooltipManager.show_tip("City level up", tip))
	btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	btn.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if _city_level_up(city, planet):
			_build_city_panel(city, planet))
	_notify_tutorial_city_level_btn(btn)
	return btn

## A City's level-up timer ran out.
func _on_city_leveled(planet_seed: int, _city_label: String, _level: int, unlocked_planet_view: bool) -> void:
	if current_data == null or current_data.seed != planet_seed:
		return
	AudioManager.play("building_done")
	if unlocked_planet_view:
		_show_unlock_toast("PLANET VIEW UNLOCKED", "Found more cities and level up the planet.")
	_refresh_active_panel()

func _notify_tutorial_city_level_btn(btn: Button) -> void:
	if TutorialManager.get_action_step_type() != "city_level_up":
		return
	_tut_highlight_node = btn
	_start_tut_node_pulse(btn)

## Short banner in the middle of the view (milestones like a new view opening).
func _on_minerals_discovered(body_seed: int, ids: Array) -> void:
	if current_data == null or current_data.seed != body_seed:
		return
	var names: Array[String] = []
	for id in ids:
		names.append(Economy.display_name(String(id)))
	_show_unlock_toast("MINERAL DISCOVERED", ", ".join(names) + " — extracted anywhere on this world.")
	_build_details_panel(current_data)

func _show_unlock_toast(title_txt: String, body_txt: String) -> void:
	var cont := planet_renderer.get_parent() as Control
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _make_hud_style(Color(0.06, 0.10, 0.08, 0.95), 8))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.z_index = 60
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	var t := Label.new()
	t.text = title_txt
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(t, 13)
	t.add_theme_color_override("font_color", Color(0.65, 1.0, 0.70))
	v.add_child(t)
	var b := Label.new()
	b.text = body_txt
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_orbitron(b, 8)
	b.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	v.add_child(b)
	cont.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 140)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(box, "modulate:a", 0.0, 0.6)
	tw.tween_callback(box.queue_free)

func _build_district_panel(poi: POIData, planet: PlanetData) -> void:
	_orbit_panel_open = false
	# keep the body's scroll position when the same district is rebuilt in place
	var saved_scroll := 0
	if _district_body_scroll != null and is_instance_valid(_district_body_scroll) \
			and _district_scroll_label == poi.label:
		saved_scroll = _district_body_scroll.scroll_vertical
	_active_district_poi = poi   # remember for _on_building_constructed
	_city_panel_poi = null
	_nav_visit(planet, {"district": poi.label}, poi.display_name)
	var panel_content := $SidePanel/PanelContent
	var old := panel_content.get_node_or_null("DistrictBuildPanel")
	if old:
		# Save scroll position before destroying
		for child in old.get_children():
			if child is ScrollContainer and (child as ScrollContainer).visible:
				_panel_scroll_pos = (child as ScrollContainer).scroll_vertical
				break
		old.name = "__freeing_district__"   # free name slot before queue_free
		old.queue_free()
		_bar_meta.clear()
		if _active_slot_dropdown != null and is_instance_valid(_active_slot_dropdown):
			_active_slot_dropdown.queue_free()
		_active_slot_dropdown = null

	var pp   := GameState.get_planet(planet.seed)
	var root := VBoxContainer.new()
	root.name = "DistrictBuildPanel"
	root.set_meta("district", poi.label)   # lets a re-click toggle to the City
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	root.add_child(HSeparator.new())

	# Districts (and the Capital District) live in a City: offer the way back up.
	var parent_city := _find_poi(planet, poi.parent_city) if not poi.is_city() else poi
	if poi.is_orbital():
		var oback := Button.new()
		oback.text = "‹  Orbit"
		oback.flat = true
		oback.alignment = HORIZONTAL_ALIGNMENT_LEFT
		oback.focus_mode = Control.FOCUS_NONE
		_apply_orbitron(oback, 9)
		oback.add_theme_color_override("font_color",       Color(0.55, 0.70, 1.0))
		oback.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
		oback.pressed.connect(func() -> void:
			AudioManager.play("click")
			_build_orbit_panel(planet))
		root.add_child(oback)
	if parent_city != null:
		var back := Button.new()
		back.text = "‹  " + parent_city.shown_name()
		back.flat = true
		back.alignment = HORIZONTAL_ALIGNMENT_LEFT
		back.focus_mode = Control.FOCUS_NONE
		_apply_orbitron(back, 9)
		back.add_theme_color_override("font_color",       Color(0.55, 0.70, 1.0))
		back.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.55))
		back.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		back.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		var cap_parent := parent_city
		back.pressed.connect(func() -> void:
			AudioManager.play("click")
			_select_district_on_planet(cap_parent.label)
			_focus_on_site(cap_parent.lon_deg, cap_parent.lat_deg)
			_build_city_panel(cap_parent, planet))
		root.add_child(back)

	var header := HBoxContainer.new()

	# Inline rename: click label → LineEdit appears
	var title_stack := Control.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.custom_minimum_size    = Vector2(0, 22)
	header.add_child(title_stack)

	var poi_title := Label.new()
	poi_title.text = poi.shown_name() + ("  ·  Capital District" if poi.is_city() else "  ·  " + poi.type_label())
	_apply_orbitron(poi_title, 11)
	poi_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	poi_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	poi_title.mouse_filter = Control.MOUSE_FILTER_STOP
	title_stack.add_child(poi_title)

	var cap_poi_rename  := poi
	var cap_planet_ren  := planet
	poi_title.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton): return
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			poi_title.visible = false
			var edit := LineEdit.new()
			edit.text = cap_poi_rename.shown_name()
			_apply_orbitron(edit, 10)
			edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			title_stack.add_child(edit)
			edit.grab_focus()
			edit.select_all()
			var _commit := func(new_name: String) -> void:
				if not is_instance_valid(edit):
					return
				var trimmed := new_name.strip_edges()
				if not trimmed.is_empty():
					cap_poi_rename.display_name = trimmed   # names may repeat; the id stays
				edit.queue_free()
				poi_title.text = cap_poi_rename.shown_name() + ("  ·  Capital District" if cap_poi_rename.is_city() else "  ·  " + cap_poi_rename.type_label())
				poi_title.visible = true
				GameState.planet_progress_changed.emit(cap_planet_ren.seed)
			edit.text_submitted.connect(_commit)
			edit.focus_exited.connect(func() -> void: _commit.call(edit.text)))

	var slots_used  := pp.slots_used_in_district(poi.label)
	var slots_total := pp.district_slots(poi)
	var dist_lv: int = pp.district_levels.get(poi.label, 1)
	var slots_lbl := Label.new()
	slots_lbl.text = "%d/%d  Lv%d" % [slots_used, slots_total, dist_lv]
	_apply_orbitron(slots_lbl, 9)
	slots_lbl.add_theme_color_override("font_color",
		Color(0.85, 0.55, 0.35) if slots_used >= slots_total else Color(0.5, 0.6, 0.8))
	header.add_child(slots_lbl)

	root.add_child(header)

	# Natural resources at this district's site
	if not poi.resource_tags.is_empty() or poi.coastal:
		var tags_lbl := Label.new()
		tags_lbl.text = _tags_text(poi.resource_tags, poi.coastal)
		var mins_txt := _minerals_text(poi.resource_tags)
		if mins_txt != "":
			tags_lbl.text += "\n" + mins_txt
		tags_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_apply_orbitron(tags_lbl, 8)
		tags_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.52))
		tags_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tags_lbl)

	# District energy balance row
	var de_row := HBoxContainer.new()
	var de_lbl := Label.new()
	de_lbl.text = "District Energy"
	de_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(de_lbl, 8)
	de_lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.65))
	var de_val := Label.new()
	_active_district_energy_lbl = de_val
	_refresh_district_energy_lbl()
	_apply_orbitron(de_val, 8)
	de_row.add_child(de_lbl); de_row.add_child(de_val)
	root.add_child(de_row)

	# Population: workers allocated here, and housing provided
	var pop_row := HBoxContainer.new()
	var pk := Label.new()
	pk.text = "Population"
	pk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_orbitron(pk, 8)
	pk.add_theme_color_override("font_color", Color(0.45, 0.50, 0.65))
	var pv_lbl := RichTextLabel.new()
	pv_lbl.bbcode_enabled = true
	pv_lbl.fit_content = true
	pv_lbl.scroll_active = false
	pv_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv_lbl.add_theme_font_size_override("normal_font_size", 8)
	if _orbitron: pv_lbl.add_theme_font_override("normal_font", _orbitron)
	var pop_parts: Array[String] = []
	var used_here := Economy.district_pop_used(pp, poi)
	var housed_here := Economy.district_housing(planet, pp, poi)
	if used_here > 0:
		pop_parts.append(_bb("☺ %s working" % Economy.fmt(used_here), Color(0.85, 0.88, 1.0)))
	if housed_here > 0:
		pop_parts.append(_bb("+%s housed" % Economy.fmt(housed_here), Economy.color_of(Economy.POPULATION)))
	pv_lbl.text = "[right]%s[/right]" % ("  ·  ".join(pop_parts) if not pop_parts.is_empty() else _bb("—", BB_DIM))
	pv_lbl.custom_minimum_size = Vector2(170, 0)
	pop_row.add_child(pk); pop_row.add_child(pv_lbl)
	root.add_child(pop_row)

	var base_row := _build_district_base_row(poi, planet, pp)
	if base_row != null:
		root.add_child(base_row)

	# Connect production updates to refresh bar fills live
	if not ProductionManager.building_progress_changed.is_connected(_on_production_update):
		ProductionManager.building_progress_changed.connect(_on_production_update)
	if not ProductionManager.building_constructed.is_connected(_on_building_constructed):
		ProductionManager.building_constructed.connect(_on_building_constructed)
	if not ProductionManager.building_toggled.is_connected(_on_building_toggled):
		ProductionManager.building_toggled.connect(_on_building_toggled)
	if not ProductionManager.building_ticked.is_connected(_on_building_ticked_night):
		ProductionManager.building_ticked.connect(_on_building_ticked_night)

	# ── Scrollable body: buildings, empty slots and (for a City) its districts ─
	# Wrapped in a plain container so the panel-switch code (which looks for a
	# direct ScrollContainer child) doesn't mix this scroll with the overview's.
	var body_wrap := MarginContainer.new()
	body_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body_wrap)
	var body_scroll := ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_scroll(body_scroll)
	body_wrap.add_child(body_scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)
	_district_body_scroll = body_scroll
	_district_scroll_label = poi.label
	body_scroll.call_deferred("set", "scroll_vertical", saved_scroll)

	# ── Installed buildings as full-bleed production cards ────────────────────
	# One card per building entry; amount field drives ×N display and output scaling
	var installed := pp.buildings_in_district(poi.label)
	for entry: Dictionary in installed:
		var bid: String = entry.get("building_id", "")
		var def := BuildingDef.find(bid)
		if def == null:
			continue
		var idx: int       = pp.building_real_index(entry)
		var pm_key: String = "%d:%s:%s" % [planet.seed, poi.label, entry.get("uid", "-1")]
		var amount: int    = entry.get("amount", 1)
		if entry.get("constructing", false):
			body.add_child(_build_construction_bar(def, pm_key))
		else:
			body.add_child(_build_production_bar(def, pm_key, planet.seed, amount, poi, planet, pp, entry))

	# ── Empty slot "+" cards ──────────────────────────────────────────────────
	var total_slots := pp.district_slots(poi)
	var used_slots  := pp.slots_used_in_district(poi.label)
	var free_slots := total_slots - used_slots
	for si in free_slots:
		body.add_child(_build_slot_card(poi, planet, pp, body, si))

	# ── Level info (bottom, below the scrolling body) ────────────────────────

	var upg_sep := HSeparator.new()
	var upg_sep_s := StyleBoxFlat.new(); upg_sep_s.bg_color = Color(0.2, 0.25, 0.4, 0.35)
	upg_sep.add_theme_stylebox_override("separator", upg_sep_s)
	root.add_child(upg_sep)

	# Level up: costs population, raises the district's building slots.
	var lv_btn := _build_district_level_row(poi, planet, pp, dist_lv) as Button
	root.add_child(lv_btn)
	if not lv_btn.disabled:
		_notify_tutorial_district_upgrade_btn(lv_btn)

	panel_content.add_child(root)
	_notify_tutorial_district_opened(poi, root)

## Opens a district-style build panel for an orbiting station.
func _open_station_district(ship: ShipData, _planet_cont: Control) -> void:
	if current_data == null: return
	# Build a synthetic POI that represents the station
	var poi := POIData.new()
	poi.label    = ship.ship_name
	poi.poi_type = POIData.POIType.STATION
	poi.level    = 1

	# Ensure ship buildings are mirrored into pp.buildings under this district id
	var pp := GameState.get_planet(ship.orbit_seed)
	if pp == null: return

	# Remove any stale entries for this station district, then re-add from ship.buildings
	var kept: Array[Dictionary] = []
	for b2: Dictionary in pp.buildings:
		if b2.get("district_id", "") != ship.ship_name:
			kept.append(b2)
	pp.buildings = kept
	for b in ship.buildings:
		if b is Dictionary:
			var entry: Dictionary = (b as Dictionary).duplicate()
			entry["district_id"] = ship.ship_name
			pp.buildings.append(entry)

	# Hook: keep ship.buildings in sync when the district panel modifies pp.buildings
	# (handled by storing ship ref in _active_station_ship and syncing in _on_building_constructed)
	_active_station_ship = ship

	_build_district_panel(poi, current_data)

var _active_station_ship: ShipData = null

## Rendezvous picker — full-screen overlay listing other ships in orbit.
func _show_rendezvous_picker(ship: ShipData, layer: OrbitalLayer) -> void:
	if current_data == null:
		return
	var others: Array[ShipData] = []
	for s: ShipData in ShipManager.ships_for(current_data.seed):
		if s.ship_id != ship.ship_id and s.rendezvous_target_id == "":
			others.append(s)
	if others.is_empty():
		return

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	planet_renderer.get_parent().add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.08, 0.16, 0.96)
	ps.border_color = Color(0.28, 0.55, 1.0, 0.60)
	ps.set_border_width_all(1); ps.set_corner_radius_all(8)
	ps.content_margin_left = 16; ps.content_margin_right = 16
	ps.content_margin_top = 14; ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(220, 0)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Select Rendezvous Target"
	_apply_orbitron(title, 8)
	title.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for tgt: ShipData in others:
		var btn := Button.new()
		var type_icon: String = "◈" if tgt.ship_type == "station" else "▶"
		btn.text = "%s  %s" % [type_icon, tgt.ship_name]
		_apply_orbitron(btn, 8)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.08, 0.12, 0.24, 0.90)
		bs.border_color = Color(0.30, 0.55, 0.90, 0.50)
		bs.set_border_width_all(1); bs.set_corner_radius_all(5)
		bs.content_margin_left = 10; bs.content_margin_right = 10
		bs.content_margin_top = 6; bs.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_stylebox_override("hover",  bs)
		btn.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
		btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		var cap_tgt := tgt
		btn.pressed.connect(func() -> void:
			overlay.queue_free()
			ship.rendezvous_base_speed = ship.orbit_speed
			ship.rendezvous_target_id  = cap_tgt.ship_id
			layer.deselect())
		vbox.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	_apply_orbitron(cancel_btn, 7)
	var cbs := StyleBoxFlat.new()
	cbs.bg_color = Color(0.10, 0.06, 0.10, 0.80)
	cbs.border_color = Color(0.45, 0.25, 0.30, 0.50)
	cbs.set_border_width_all(1); cbs.set_corner_radius_all(5)
	cbs.content_margin_left = 10; cbs.content_margin_right = 10
	cbs.content_margin_top = 6; cbs.content_margin_bottom = 6
	cancel_btn.add_theme_stylebox_override("normal", cbs)
	cancel_btn.add_theme_stylebox_override("hover",  cbs)
	cancel_btn.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
	cancel_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	cancel_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())
	vbox.add_child(cancel_btn)

## Transfer panel — shown when rendezvous is complete. Floating panel next to the ships.
func _show_transfer_panel(ship: ShipData, target: ShipData, layer: OrbitalLayer) -> void:
	# Re-select the shuttle so the user can see the panel
	layer.select_ship(ship)

	var cont: Control = planet_renderer.get_parent()

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.07, 0.14, 0.96)
	ps.border_color = Color(0.30, 0.82, 1.0, 0.65)
	ps.set_border_width_all(1); ps.set_corner_radius_all(8)
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top = 12; ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	cont.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(280, 0)
	panel.add_child(vbox)

	# Header
	var hdr := Label.new()
	hdr.text = "⟐  %s  ↔  %s" % [ship.ship_name, target.ship_name]
	_apply_orbitron(hdr, 7)
	hdr.add_theme_color_override("font_color", Color(0.40, 0.85, 1.0))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hdr)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Two-column layout: shuttle | station
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	vbox.add_child(cols)

	# Array wrapper so the lambda can reference itself after assignment
	var rebuild_ref: Array[Callable] = []

	var _build_transfer_cols := func() -> void:
		for c: Node in cols.get_children():
			c.queue_free()
		await get_tree().process_frame

		for side: int in 2:
			var src: ShipData = ship if side == 0 else target
			var dst: ShipData = target if side == 0 else ship
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 4)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cols.add_child(col)

			var col_lbl := Label.new()
			col_lbl.text = src.ship_name
			_apply_orbitron(col_lbl, 7)
			col_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0))
			col_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(col_lbl)

			if src.cargo.is_empty():
				var empty_lbl := Label.new()
				empty_lbl.text = "(empty)"
				_apply_orbitron(empty_lbl, 6)
				empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.60, 0.60))
				empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				col.add_child(empty_lbl)
			else:
				for res_id: String in src.cargo.keys():
					var rd: ResourceData = GameState.known_resources.get(res_id, null)
					if rd == null: continue
					var amt: int = int(src.cargo[res_id])

					var row := HBoxContainer.new()
					row.add_theme_constant_override("separation", 6)
					col.add_child(row)

					var sq := _mineral_grid_card(rd, float(amt), false)
					sq.custom_minimum_size = Vector2(36, 36)
					row.add_child(sq)

					var info := VBoxContainer.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					info.mouse_filter = Control.MOUSE_FILTER_IGNORE
					row.add_child(info)

					var res_lbl := Label.new()
					res_lbl.text = rd.unique_name
					_apply_orbitron(res_lbl, 6)
					res_lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 1.0))
					res_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					info.add_child(res_lbl)

					var amt_lbl := Label.new()
					amt_lbl.text = "x%d" % amt
					_apply_orbitron(amt_lbl, 6)
					amt_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85, 0.70))
					amt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					info.add_child(amt_lbl)

					var xfer_btn := Button.new()
					var arrow: String = "→" if side == 0 else "←"
					xfer_btn.text = "%s Transfer" % arrow
					_apply_orbitron(xfer_btn, 6)
					var xbs := StyleBoxFlat.new()
					xbs.bg_color = Color(0.06, 0.14, 0.26, 0.90)
					xbs.border_color = Color(0.25, 0.55, 0.85, 0.50)
					xbs.set_border_width_all(1); xbs.set_corner_radius_all(4)
					xbs.content_margin_left = 6; xbs.content_margin_right = 6
					xbs.content_margin_top = 3; xbs.content_margin_bottom = 3
					xfer_btn.add_theme_stylebox_override("normal", xbs)
					xfer_btn.add_theme_stylebox_override("hover",  xbs)
					xfer_btn.add_theme_color_override("font_color", Color(0.45, 0.78, 1.0))
					xfer_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
					xfer_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
					var cap_rid := res_id; var cap_src := src; var cap_dst := dst
					xfer_btn.pressed.connect(func() -> void:
						var move_amt: int = int(cap_src.cargo.get(cap_rid, 0))
						if move_amt <= 0: return
						cap_src.cargo.erase(cap_rid)
						cap_dst.cargo[cap_rid] = cap_dst.cargo.get(cap_rid, 0) + move_amt
						if not rebuild_ref.is_empty(): rebuild_ref[0].call())
					col.add_child(xfer_btn)

	rebuild_ref.append(_build_transfer_cols)
	_build_transfer_cols.call()

	var close_row := HBoxContainer.new()
	vbox.add_child(close_row)
	var close_sp := Control.new()
	close_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_row.add_child(close_sp)
	var close_btn := Button.new()
	close_btn.text = "Done"
	_apply_orbitron(close_btn, 7)
	var dbs := StyleBoxFlat.new()
	dbs.bg_color = Color(0.06, 0.18, 0.08, 0.90)
	dbs.border_color = Color(0.22, 0.68, 0.35, 0.60)
	dbs.set_border_width_all(1); dbs.set_corner_radius_all(5)
	dbs.content_margin_left = 12; dbs.content_margin_right = 12
	dbs.content_margin_top = 5; dbs.content_margin_bottom = 5
	close_btn.add_theme_stylebox_override("normal", dbs)
	close_btn.add_theme_stylebox_override("hover",  dbs)
	close_btn.add_theme_color_override("font_color", Color(0.40, 0.92, 0.55))
	close_btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	close_btn.mouse_exited.connect( func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	close_btn.pressed.connect(func() -> void: panel.queue_free())
	close_row.add_child(close_btn)

func _sync_station_buildings() -> void:
	if _active_station_ship == null or not is_instance_valid(_active_station_ship):
		return
	var pp := GameState.get_planet(_active_station_ship.orbit_seed)
	if pp == null: return
	var dist_id: String = _active_station_ship.ship_name
	_active_station_ship.buildings.clear()
	for b: Dictionary in pp.buildings:
		if b.get("district_id", "") == dist_id:
			_active_station_ship.buildings.append(b)

func _spawn_terrain_hit(screen_pos: Vector2, ptype: int) -> void:
	# Map planet type → sound key and particle color
	var sound_key: String
	var particle_color: Color
	match ptype:
		PlanetData.Type.TERRAN:
			sound_key      = "terrain_earth"
			particle_color = Color(0.18, 0.40, 0.15)   # grass green
		PlanetData.Type.ARID:
			sound_key      = "terrain_sand"
			particle_color = Color(0.68, 0.52, 0.22)   # sand ochre
		PlanetData.Type.ICE:
			sound_key      = "terrain_ice"
			particle_color = Color(0.82, 0.92, 1.00)   # ice blue-white
		PlanetData.Type.VOLCANIC:
			sound_key      = "terrain_fire"
			particle_color = Color(1.00, 0.32, 0.05)   # lava orange
		PlanetData.Type.GAS_GIANT:
			sound_key      = "terrain_gas"
			particle_color = Color(0.72, 0.58, 0.38)   # gas amber
		PlanetData.Type.MOON, PlanetData.Type.ASTEROID:
			sound_key      = "terrain_dust"
			particle_color = Color(0.55, 0.53, 0.49)   # grey dust
		_:
			sound_key      = "terrain_earth"
			particle_color = Color(0.40, 0.36, 0.28)

	# TERRAN: deeper inside the circle, bias toward water vs land by longitude (simple heuristic)
	if ptype == PlanetData.Type.TERRAN:
		var local_pos := screen_pos - planet_renderer.global_position - planet_renderer.size * 0.5
		if local_pos.x < 0:
			sound_key      = "terrain_water"
			particle_color = Color(0.08, 0.42, 0.72)

	AudioManager.play(sound_key, -3.0)
	_burst_particles(screen_pos, particle_color)

func _burst_particles(pos: Vector2, col: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 3
	particles.lifetime = 0.55
	particles.speed_scale = 1.0

	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 280)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color = col

	# Slight color variation
	var gradient := Gradient.new()
	gradient.set_color(0, col)
	gradient.set_color(1, Color(col.r, col.g, col.b, 0.0))
	particles.color_ramp = gradient

	add_child(particles)
	particles.emitting = true
	# Auto-free after particles finish
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free())

func _on_seed_clicked(event: InputEvent, s: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		DisplayServer.clipboard_set(str(s))

func _build_rings(data: PlanetData) -> void:
	if _ring_back  and is_instance_valid(_ring_back):  _ring_back.queue_free()
	if _ring_front and is_instance_valid(_ring_front): _ring_front.queue_free()
	_ring_back  = null
	_ring_front = null
	_ring_particles.clear()
	_ring_angle = 0.0
	if not data.has_rings:
		return

	# generate a few particles with seed-based positions
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed ^ 0x52494E47
	var ptc_count: int = rng.randi_range(2, 4)
	for _p in ptc_count:
		_ring_particles.append({
			"angle":  rng.randf_range(0.0, TAU),
			"dist_t": rng.randf_range(0.15, 0.85),   # lerp between inner/outer
			"size":   rng.randf_range(3.0, 6.0),
			"speed":  rng.randf_range(0.04, 0.10),
		})

	# both ring nodes live inside PlanetContainer so z_index is comparable to planet_renderer
	var container: Control = planet_renderer.get_parent()
	planet_renderer.z_index = 5   # explicit so ring nodes can go above/below

	_ring_back = Node2D.new()
	_ring_back.z_as_relative = false
	_ring_back.z_index = 4
	container.add_child(_ring_back)
	_ring_back.draw.connect(func() -> void: _draw_planet_rings(_ring_back, PI, TAU, true))

	_ring_front = Node2D.new()
	_ring_front.z_as_relative = false
	_ring_front.z_index = 6
	container.add_child(_ring_front)
	_ring_front.draw.connect(func() -> void: _draw_planet_rings(_ring_front, 0.0, PI, false))

	# POILayer must stay above ring_front so labels are never covered
	poi_layer.z_as_relative = false
	poi_layer.z_index = 10

func _draw_planet_rings(target: Node2D, from_a: float, to_a: float, is_back: bool) -> void:
	if current_data == null or not current_data.has_rings:
		return
	var r:    Rect2 = planet_renderer.get_rect()
	var cx:   float = r.position.x + r.size.x * 0.5
	var cy:   float = r.position.y + r.size.y * 0.5
	var half: float = _planet_r_px() * RING_SCALE
	# Rings sit ~15° off edge-on; camera tilt opens/closes them. Negative = seen
	# from below, which flips which half is in front — the same draw split still holds.
	var yr:   float = sin(RING_VIEW_ANGLE + planet_renderer.tilt)
	var ir:   float = half * current_data.ring_inner
	var or_:  float = half * current_data.ring_outer
	var col:  Color = current_data.ring_color
	var bands: int  = 11
	for k in bands:
		var t:   float = float(k) / float(bands - 1)
		# Cassini-like gap near the middle
		var gap_alpha: float = 1.0 - smoothstep(0.0, 1.0, 1.0 - abs(t - 0.52) * 6.0)
		var rx:  float = lerp(ir, or_, t)
		var base_alp: float = 0.72 if is_back else 0.85
		var alp: float = col.a * lerp(base_alp * 0.55, base_alp, 1.0 - abs(t - 0.5) * 2.0) * gap_alpha
		var pts := PackedVector2Array()
		var steps := 80
		for s in steps + 1:
			var a := from_a + (to_a - from_a) * float(s) / float(steps)
			pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * rx * yr))
		target.draw_polyline(pts, Color(col.r, col.g, col.b, alp), 2.0, true)

	# ring POIs — same depth-faking trick as particles, only in front node
	if not is_back and current_data != null:
		for pd: POIData in current_data.custom_pois:
			if pd.type_tag != "ring":
				continue
			var pa: float  = fposmod(deg_to_rad(pd.lon_deg) + _ring_angle, TAU)
			var dt: float  = pd.lat_deg   # dist_t stored in lat_deg
			var rx: float  = lerp(ir, or_, dt)
			var px: float  = cx + cos(pa) * rx
			var py: float  = cy + sin(pa) * rx * yr
			var depth: float = (sin(pa) + 1.0) * 0.5
			var a: float   = lerp(0.20, 1.0, depth)
			var fc: Color  = Color(1.0, 0.92, 0.55, a)
			target.draw_circle(Vector2(px, py), 5.0, Color(0.0, 0.0, 0.0, a * 0.6))
			target.draw_circle(Vector2(px, py), 3.5, fc)
			if depth > 0.35:   # only show label when near front
				if _orbitron:
					target.draw_string(_orbitron, Vector2(px + 7, py + 4),
						pd.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
						Color(1.0, 0.92, 0.55, a * 0.9))

	# particles: only draw in _ring_front (is_back=false) to avoid node-switch jump.
	if is_back:
		return
	for ptc: Dictionary in _ring_particles:
		var pa:    float = fposmod(ptc["angle"] + _ring_angle, TAU)
		var rx:    float = lerp(ir, or_, float(ptc["dist_t"]))
		var px:    float = cx + cos(pa) * rx
		var py:    float = cy + sin(pa) * rx * yr
		var ps:    float = float(ptc["size"])
		# depth: sin(pa) ranges -1 (top/back) to +1 (bottom/front)
		var depth: float = (sin(pa) + 1.0) * 0.5
		var palp:  float = col.a * lerp(0.22, 0.95, depth)   # dim when behind
		var psize: float = ps * lerp(0.5, 1.0, depth)         # smaller when behind
		target.draw_circle(Vector2(px, py), psize,
			Color(col.r * 1.1, col.g * 1.05, col.b, palp))
		target.draw_circle(Vector2(px, py), psize * 0.45,
			Color(1.0, 0.96, 0.88, palp * 0.9))
