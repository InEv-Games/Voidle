class_name Excavations
extends RefCounted

## Excavations and the companions they bring (replaces the Relics of
## playtest 31.10). Every world has a chain of excavations (ExcavationWorldDef),
## done in order, grouped into ruins (ExcavationSiteDef.ruin_id): the next one
## shows as a mark on the map once the world is scanned. Clicking it plays its
## opening (StoryDialog, a VSM graph), the player pays and the crews dig for a
## while; when they're done the mark calls the player back for the rest of the
## story. It turns credits into Science and materials (ExcavationSiteDef.reward); the exits
## add to that (StoryGrant), set what later stories remember (StorySetFlag /
## StoryHasFlag) and, on the last excavation of a ruin, say who joins
## (StoryJoinCompanion). A companion gives a bonus everywhere.
##
## State lives in GameState: excavations_done { site id: unix time },
## excavations_digging { site id: { ready_at (play seconds), told } },
## excavation_sites { place key: [lon, lat] } (ExcavationSiteDef.place_key),
## story_flags { flag: true } and companions_joined { companion id: unix time }.

enum Stage { IDLE, DIGGING, READY, DONE }

## What a running story collected, in the VSM blackboard. Nothing of it counts
## until finish(): a story that is left halfway gives nothing.
const BB_GRANTS := "_grants"
const BB_JOIN := "_join"
const BB_FLAGS := "_flags"
## How far (radians) a new mark stays from what's built on the world.
const SITE_CLEARANCE := 0.2
## How far (radians) a new ruin stays from the world's other ruins.
const RUIN_SPREAD := 0.35

# ── Queries ──────────────────────────────────────────────────────────────────

static func is_done(site_id: String) -> bool:
	return GameState.excavations_done.has(site_id)

static func has_joined(companion_id: String) -> bool:
	return GameState.companions_joined.has(companion_id)

static func joined_count() -> int:
	return GameState.companions_joined.size()

static func find_site(site_id: String) -> ExcavationSiteDef:
	for w: ExcavationWorldDef in ExcavationWorldDef.all():
		for s: ExcavationSiteDef in w.sites:
			if s.site_id == site_id:
				return s
	return null

static func world_of_site(site_id: String) -> ExcavationWorldDef:
	for w: ExcavationWorldDef in ExcavationWorldDef.all():
		for s: ExcavationSiteDef in w.sites:
			if s.site_id == site_id:
				return w
	return null

## The world's excavation to do now, or null when its chain is done.
static func next_site(w: ExcavationWorldDef) -> ExcavationSiteDef:
	for s: ExcavationSiteDef in w.sites:
		if not is_done(s.site_id):
			return s
	return null

static func stage(s: ExcavationSiteDef) -> Stage:
	if is_done(s.site_id):
		return Stage.DONE
	if not GameState.excavations_digging.has(s.site_id):
		return Stage.IDLE
	return Stage.READY if time_left(s) <= 0.0 else Stage.DIGGING

## Seconds of play time until the crews are done (0 if not digging).
static func time_left(s: ExcavationSiteDef) -> float:
	var dig: Dictionary = GameState.excavations_digging.get(s.site_id, {})
	return maxf(0.0, float(dig.get("ready_at", 0.0)) - GameState.play_seconds) if not dig.is_empty() else 0.0

## "5:00".
static func time_text(sec: float) -> String:
	var t := ceili(sec)
	@warning_ignore("integer_division")
	return "%d:%02d" % [t / 60, t % 60]

## Global multiplier from the active advisor for resource `id` (1 = none).
## One advisor at a time gives their bonus (docs/design/narrative/ADVISORS.md):
## Production ("raw") covers raw output and Goods, Fuel, Rare Elements.
static func global_mult(id: String) -> float:
	var key := Economy.RAW if id in [Economy.RAW, Economy.GOODS, Economy.FUEL, Economy.RARE] else id
	var c := CompanionDef.find(GameState.active_advisor)
	if c != null and c.bonus == CompanionDef.Bonus.RESOURCE and c.bonus_resource == key:
		return 1.0 + c.bonus_value
	return 1.0

## Build speed from the active advisor (1 = none).
static func build_speed() -> float:
	var c := CompanionDef.find(GameState.active_advisor)
	if c != null and c.bonus == CompanionDef.Bonus.BUILD_SPEED:
		return 1.0 + c.bonus_value
	return 1.0

# ── Sites ────────────────────────────────────────────────────────────────────

## The marks to draw on `pd` now: [{ id, name, lon, lat, done, total, site }] (lon
## and lat in radians; done of total: the excavations of its ruin). Only the next
## excavation of each chain on it, once the world is scanned.
static func sites_on(pd: PlanetData) -> Array:
	var out: Array = []
	if pd == null or not GameState.is_scanned(pd.seed):
		return out
	for w: ExcavationWorldDef in ExcavationWorldDef.all():
		var world := w.planet()
		if world == null or world.seed != pd.seed:
			continue
		var s := next_site(w)
		if s == null:
			continue
		var at := site_of(s, pd, w)
		if at.is_finite():
			var done := 0
			var total := 0
			for other: ExcavationSiteDef in w.sites:
				if other.place_key() == s.place_key():
					total += 1
					done += 1 if is_done(other.site_id) else 0
			out.append({"id": s.site_id, "name": s.display_name, "lon": at.x, "lat": at.y, "done": done, "total": total,
				"site": s})
	return out

## Where an excavation lies on its world (fixed once chosen, shared with the rest
## of its ruin): a cell of its terrain, else of the next kinds, else a spot on
## land. Vector2.INF until the world's map exists.
static func site_of(s: ExcavationSiteDef, pd: PlanetData, w: ExcavationWorldDef) -> Vector2:
	var key := s.place_key()
	if GameState.excavation_sites.has(key):
		var v = GameState.excavation_sites[key]
		return v if v is Vector2 else Vector2(float(v[0]), float(v[1]))
	if not FeatureMap.has_map(pd.seed):
		return Vector2.INF
	var order: Array[int] = [FeatureMap.F.RUINS, FeatureMap.F.CRATER, FeatureMap.F.PLAIN]
	if s.terrain == ExcavationSiteDef.Terrain.CRATER:
		order = [FeatureMap.F.CRATER, FeatureMap.F.RUINS, FeatureMap.F.PLAIN]
	elif s.terrain == ExcavationSiteDef.Terrain.ANY:
		order = [FeatureMap.F.PLAIN, FeatureMap.F.RUINS, FeatureMap.F.CRATER]
	var cells: Array = []
	for f: int in order:
		cells = FeatureMap.cells_with(pd.seed, f)
		if not cells.is_empty():
			break
	if cells.is_empty():
		return Vector2.INF
	# unseeded: another game, another place; the save keeps this one
	var free := _free_cells(cells, pd, w)
	var at: Vector2 = free[randi() % free.size()]
	GameState.excavation_sites[key] = [at.x, at.y]
	return at

## The cells away from what's built on the world (a City's marker would crowd
## the mark) and from the world's other ruins, so each dig is a new place; if
## none is, the one farthest from both.
static func _free_cells(cells: Array, pd: PlanetData, w: ExcavationWorldDef) -> Array:
	var built: Array[Vector2] = []
	for poi: POIData in pd.custom_pois:
		if not poi.is_orbital():
			built.append(Vector2(deg_to_rad(poi.lon_deg), deg_to_rad(poi.lat_deg)))
	var ruins: Array[Vector2] = []
	for other: ExcavationSiteDef in w.sites:
		var v = GameState.excavation_sites.get(other.place_key(), null)
		if v != null:
			ruins.append(v if v is Vector2 else Vector2(float(v[0]), float(v[1])))
	var clear: Array = []
	var best: Vector2 = cells[0]
	var best_room := -1.0
	for c: Vector2 in cells:
		var room := minf(_nearest(c, built) / SITE_CLEARANCE, _nearest(c, ruins) / RUIN_SPREAD)
		if room >= 1.0:
			clear.append(c)
		if room > best_room:
			best_room = room
			best = c
	return clear if not clear.is_empty() else [best]

## Angle (radians) from `c` to the nearest of `points`.
static func _nearest(c: Vector2, points: Array[Vector2]) -> float:
	var near := PI
	for p: Vector2 in points:
		near = minf(near, _arc(c, p))
	return near

## Angle between two (lon, lat) points, in radians.
static func _arc(a: Vector2, b: Vector2) -> float:
	var d := sin(a.y) * sin(b.y) + cos(a.y) * cos(b.y) * cos(a.x - b.x)
	return acos(clampf(d, -1.0, 1.0))

## Where an excavation lies, for the news ({ seed, lon, lat } or {}).
static func _site_loc(site_id: String) -> Dictionary:
	var w := world_of_site(site_id)
	var pd := w.planet() if w != null else null
	var s := find_site(site_id)
	var v = GameState.excavation_sites.get(s.place_key(), null) if s != null else null
	if pd == null or v == null:
		return {}
	var at: Vector2 = v if v is Vector2 else Vector2(float(v[0]), float(v[1]))
	return {"seed": pd.seed, "lon": at.x, "lat": at.y}

# ── Playing one ──────────────────────────────────────────────────────────────

## A dig inside a City's reach (the circle its districts may be placed in) goes
## faster and costs less: the crews and supplies are close (playtest 07.11).
const CITY_TIME_MULT := 0.5
const CITY_COST_MULT := 0.75

## The City whose reach holds the site's mark (measured from the City or any of
## its finished districts, as placement does), or null.
static func city_near(s: ExcavationSiteDef) -> POIData:
	var loc := _site_loc(s.site_id)
	if loc.is_empty():
		return null
	var pd := GameState.get_planet_data(int(loc["seed"]))
	if pd == null:
		return null
	var pp := GameState.get_planet(pd.seed)
	var at := Vector2(float(loc["lon"]), float(loc["lat"]))
	for poi: POIData in pd.custom_pois:
		if poi.is_orbital() or poi.constructing:
			continue
		var city_label := poi.label if poi.is_city() else poi.parent_city
		if city_label == "":
			continue
		var lv := int(pp.district_levels.get(city_label, 1)) if pp != null else 1
		var reach := deg_to_rad(TerrainSampler.city_reach_deg(pd, lv))
		if _arc(at, Vector2(deg_to_rad(poi.lon_deg), deg_to_rad(poi.lat_deg))) <= reach:
			for c: POIData in pd.custom_pois:
				if c.label == city_label:
					return c
	return null

## What starting the dig costs now (less inside a City's reach).
static func cost_of(s: ExcavationSiteDef) -> Dictionary:
	if city_near(s) == null:
		return s.cost
	var out := {}
	for id: String in s.cost:
		out[id] = roundf(float(s.cost[id]) * CITY_COST_MULT)
	return out

## How long the dig takes if started now (shorter inside a City's reach).
static func duration_of(s: ExcavationSiteDef) -> float:
	return s.duration_sec * (CITY_TIME_MULT if city_near(s) != null else 1.0)

## The length of the dig under way (what it was started with), for progress bars.
static func dig_length(s: ExcavationSiteDef) -> float:
	var dig: Dictionary = GameState.excavations_digging.get(s.site_id, {})
	return float(dig.get("dur", s.duration_sec))

## Why digging can't start now ("" when it can).
static func start_block(s: ExcavationSiteDef) -> String:
	if stage(s) != Stage.IDLE:
		return "Already started"
	var w := world_of_site(s.site_id)
	if w == null or next_site(w) != s:
		return "Finish the excavation before it first"
	return Economy.cost_block(cost_of(s))

## Pays and sets the crews digging. False when it can't.
static func start(s: ExcavationSiteDef) -> bool:
	if start_block(s) != "" or not Economy.pay(cost_of(s)):
		return false
	var dur := duration_of(s)
	GameState.excavations_digging[s.site_id] = {"ready_at": GameState.play_seconds + dur, "dur": dur, "told": false}
	GameState.excavations_changed.emit()
	return true

## Tells the player once when a dig is ready (GameState, each frame of play).
static func tick() -> void:
	for id: String in GameState.excavations_digging:
		var dig: Dictionary = GameState.excavations_digging[id]
		if dig.get("told", false) or float(dig.get("ready_at", 0.0)) > GameState.play_seconds:
			continue
		dig["told"] = true
		var s := find_site(id)
		if s != null:
			NewsFeed.post("Excavation ready: %s. Your crews are waiting." % s.display_name, NewsFeed.Kind.EVENT,
				s.teaser, s.display_name, _site_loc(id))
			# and where it can't be missed (playtest 07.11): the message card with a
			# button to what they found, and the "ready" sound
			var site_id := id
			NewsFeed.show_message("excavation_ready_" + id, "Excavation", "%s IS READY" % s.display_name.to_upper(),
				"Your crews are waiting. Click its mark on the map, or here, to see what they found.",
				{"sec": 15.0, "action": "SEE THE FINDS", "action_icon": "explore",
				"on_action": func() -> void:
					var host := (Engine.get_main_loop() as SceneTree).current_scene
					if host != null:
						StoryDialog.open(host, site_id)})
			VAM.play(&"sfx/ready")
		GameState.excavations_changed.emit()

## The story reached its end: pays the site's reward plus what its exits collected
## and closes the site. Returns { "grants": { id: amount }, "companion": CompanionDef or null }.
static func finish(s: ExcavationSiteDef, blackboard: Dictionary) -> Dictionary:
	var grants: Dictionary = s.reward.duplicate()
	var extra: Dictionary = blackboard.get(BB_GRANTS, {})
	for id: String in extra:
		grants[id] = float(grants.get(id, 0.0)) + float(extra[id])
	for id: String in grants:
		Economy.add(id, float(grants[id]))
	for flag in blackboard.get(BB_FLAGS, []):
		GameState.story_flags[String(flag)] = true
	GameState.excavations_digging.erase(s.site_id)
	GameState.excavations_done[s.site_id] = int(Time.get_unix_time_from_system())
	var who := CompanionDef.find(String(blackboard.get(BB_JOIN, "")))
	if who != null:
		GameState.companions_joined[who.companion_id] = int(Time.get_unix_time_from_system())
		Economy.invalidate_bonus_cache()
		NewsFeed.post("%s joins you." % who.display_name, NewsFeed.Kind.EVENT,
			"%s\n\n%s" % [who.bonus_bb(13), who.bio], who.display_name, _site_loc(s.site_id))
	else:
		NewsFeed.post("Excavation finished: %s." % s.display_name, NewsFeed.Kind.EVENT, s.teaser, s.display_name, _site_loc(s.site_id))
	GameState.excavations_changed.emit()
	_after_story(s)
	return {"grants": grants, "companion": who}

# ── What the narrative adds after a dig (docs/design/narrative, slice 2) ─────
const BOLO_GRAPH := "res://resources/narrative/bolo.tres"
const FIRST_RUIN := "vesyn_toppled_stones"

## After The Toppled Stones: the woman at the foot of the stairs (meet_bolo),
## or, met already at the Spaceport, her one line about this room. Plays once
## the excavation card is closed (Narrative waits for it).
static func _after_story(s: ExcavationSiteDef) -> void:
	if bolo_invitation_ready() and not GameState.story_flags.has("bolo_invitation_told"):
		GameState.story_flags["bolo_invitation_told"] = true
		NewsFeed.show_message("bolo_invitation", "Companions", "BOLO HAS NEWS",
			"All five surveys are done. Bolo is waiting to talk to you about her people.",
			{"sec": 20.0, "action": "COMPANIONS", "action_icon": "population",
			"on_action": func() -> void:
				var host := (Engine.get_main_loop() as SceneTree).current_scene
				if host != null:
					CompanionGallery.open(host)})
	if s.site_id != FIRST_RUIN:
		return
	if GameState.bolo_intro_route == "":
		Narrative.play(BOLO_GRAPH, "meet_bolo", {"id": "meet_bolo", "on_done": func(_exit: String) -> void:
			met_bolo("excavation")})
	else:
		Narrative.play(BOLO_GRAPH, "bolo_at_toppled_stones", {"id": "bolo_at_toppled_stones"})

## Bolo is met (at the dig or at the Spaceport): she joins the Companions and
## the Moon's signal is known.
static func met_bolo(route: String) -> void:
	if GameState.bolo_intro_route == "":
		GameState.bolo_intro_route = route
	GameState.story_flags["bolo_lunar_signal"] = true
	GameState.unlock_advisor("bolo")

## Plays Bolo's people's offer (from Companions). Accepted: they come up and
## the home world houses GameState.BOLO_PEOPLE more; "later" leaves it open.
static func hear_bolo_invitation() -> void:
	Narrative.play(BOLO_GRAPH, "bolo_surface_invitation", {"id": "bolo_surface_invitation", "once": false, "now": true,
		"on_done": func(exit_name: String) -> void:
			if exit_name != "accepted" or GameState.bolo_people_joined:
				return
			GameState.bolo_people_joined = true
			Economy.invalidate_bonus_cache()
			NewsFeed.post("Bolo's people come up from below: the first carts reach the survey camp.",
				NewsFeed.Kind.EVENT)})

## All five of the home world's digs are done and Bolo is met: her people's
## offer waits in Companions (bolo_surface_invitation) until it is accepted.
static func bolo_invitation_ready() -> bool:
	if GameState.bolo_intro_route == "" or GameState.bolo_people_joined:
		return false
	var w := world_of_site(FIRST_RUIN)
	if w == null:
		return false
	for site: ExcavationSiteDef in w.sites:
		if not is_done(site.site_id):
			return false
	return true

## Developer console: every excavation starts over, marks move to new places, no
## one has joined. What the digs paid or cost stays spent.
static func reset_all() -> void:
	GameState.excavations_done.clear()
	GameState.excavations_digging.clear()
	GameState.excavation_sites.clear()
	GameState.story_flags.clear()
	GameState.companions_joined.clear()
	Economy.invalidate_bonus_cache()
	GameState.excavations_changed.emit()

## Older saves found relics: their companion has joined and that world's chain
## counts as done (no story to replay, no second payout).
static func migrate_relics(found: Dictionary) -> void:
	for c: CompanionDef in CompanionDef.all():
		if c.legacy_relic_id == "" or not found.has(c.legacy_relic_id):
			continue
		var at := int(found[c.legacy_relic_id])
		GameState.companions_joined[c.companion_id] = at
		for w: ExcavationWorldDef in ExcavationWorldDef.all():
			if _world_gives(w, c):
				for s: ExcavationSiteDef in w.sites:
					GameState.excavations_done[s.site_id] = at

## True if a story of this world can bring `c` (any exit's StoryJoinCompanion).
static func _world_gives(w: ExcavationWorldDef, c: CompanionDef) -> bool:
	for s: ExcavationSiteDef in w.sites:
		if s.story == null:
			continue
		for n: VSMNodeData in s.story.nodes:
			var exits = n.get("exits")
			if exits == null:
				continue
			for e: VSMExitLink in exits:
				for a in e.actions:
					if a is StoryJoinCompanion and (a as StoryJoinCompanion).companion == c:
						return true
	return false
