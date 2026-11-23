## RoverLayer — draws and commands the rovers of the world on screen (TEST).
##
## Controls (mouse):
##   Left click a rover ............ select it (Shift: add / remove)
##   Double-click a rover .......... select every rover on this world
##   Shift + left drag ............. box select
##   Left click elsewhere .......... deselect (the click still works as before)
##   Right click the ground ........ drive there (several rovers fan out)
##   Shift + right click ........... add a waypoint after the current ones
##   Right click a selected rover .. stop
##   Right drag .................... turns the globe, as always
##   Esc ........................... deselect (or call a landing pick off)
##   Landing pick (from the panel) . left click the spot, right click / Esc cancels
##
## PlanetaryView forwards input first (handle_input / handle_right_click); what
## this layer doesn't use falls through to the old behaviour. State lives in
## RoverManager; only the selection is kept here.
extends Node2D

## The selection changed (ids, click order). PlanetaryView opens the rover panel.
signal selection_changed(ids: Array)

const HIT_PX := 14.0
const CLICK_PX := 8.0
## Rover look: one colour with the dark outline, like the other map icons
## (POILayer._ICONS). Cyan, which no district or site icon uses. Faces the way
## it drives.
const BODY_COL := Color(0.40, 0.88, 0.95)
const SEL_COL := Color(0.55, 0.95, 1.0)
const PATH_COL := Color(0.55, 0.95, 1.0, 0.85)
const ROAD_PATH_COL := Color(1.0, 0.85, 0.4, 0.95)   # legs on a City road
const BAD_COL := Color(1.0, 0.35, 0.3)
## Drawn facing right: camera mast, body, wheels.
const SPRITE := [
	"....##.",
	".....#.",
	"#######",
	"#######",
	".#.#.#.",
]

var _planet: ColorRect = null
var _view: Node = null
var _font: Font = null

## Selected rover ids (order = click order).
var _selected: Array[String] = []
var _hover_id := ""
## Left press bookkeeping.
var _press_pos := Vector2.INF
var _box_from := Vector2.INF
var _box_to := Vector2.INF
## Order feedback: [{ pos: Vector3, t: float, ok: bool }]
var _pings: Array[Dictionary] = []
## Picking a landing spot for this rover (in orbit): the next click on the globe.
var _landing_id := ""
var _mouse := Vector2.ZERO


func setup(renderer: ColorRect, view: Node, font: Font) -> void:
	_planet = renderer
	_view = view
	_font = font if font != null else ThemeDB.fallback_font
	RoverManager.rovers_changed.connect(func(_s: int) -> void: _prune())


func _seed() -> int:
	var pd: PlanetData = _view.get("current_data") if _view != null else null
	return pd.seed if pd != null else -1


func _planet_data() -> PlanetData:
	return _view.get("current_data") if _view != null else null


func _active() -> bool:
	if not RoverManager.ENABLED or _planet == null or GameState.showcase_mode:
		return false
	if _view.get("_placing_def") != null:
		return false
	return not RoverManager.rovers_on(_seed()).is_empty()


func has_selection() -> bool:
	return not _selected.is_empty()


func clear_selection() -> void:
	_selected.clear()
	_landing_id = ""
	queue_redraw()


## Starts picking a landing spot for `id` (it must be in orbit).
func begin_landing(id: String) -> void:
	_landing_id = id
	queue_redraw()


func is_landing() -> bool:
	return _landing_id != ""


func is_selected(id: String) -> bool:
	return id in _selected


## Selects rovers by id (the side panel list). add = keep the current selection.
func select_ids(ids: Array, add := false) -> void:
	if not add:
		_selected.clear()
	for id in ids:
		if not (String(id) in _selected):
			_selected.append(String(id))
	queue_redraw()


func _prune() -> void:
	var keep: Array[String] = []
	for id: String in _selected:
		var r = RoverManager.get_rover(id)
		if r != null and r.planet_seed == _seed():
			keep.append(id)
	_selected = keep
	queue_redraw()


# ── Projection ───────────────────────────────────────────────────────────────

func _r_px() -> float:
	if _planet.material == null:
		return 0.0
	return _planet.size.y * float((_planet.material as ShaderMaterial).get_shader_parameter("planet_radius"))


## Unit vector → Vector3(screen x, screen y, depth); depth <= 0 = far side.
func _project(v: Vector3) -> Vector3:
	var r := _r_px()
	if r <= 0.0:
		return Vector3(0, 0, -1)
	var center := _planet.global_position + _planet.size * 0.5
	var view_v: Vector3 = _planet.lonlat_to_view(atan2(v.x, v.z), asin(clampf(v.y, -1.0, 1.0)))
	return Vector3(center.x + view_v.x * r, center.y + view_v.y * r, view_v.z)


func _clip_rect() -> Rect2:
	var parent := _planet.get_parent() as Control
	return parent.get_global_rect() if parent else _planet.get_global_rect()


func _block() -> float:
	var pc := 200.0
	if _planet.material != null:
		pc = float((_planet.material as ShaderMaterial).get_shader_parameter("pixel_count"))
	return maxf(2.0, roundf(_planet.size.y / maxf(pc, 1.0) * 0.5))


func rover_at(global_pos: Vector2) -> RoverData:
	var best: RoverData = null
	var best_d := HIT_PX
	for r: RoverData in RoverManager.rovers_on(_seed()):
		if r.in_orbit():
			continue
		var p := _project(r.pos)
		if p.z <= 0.05:
			continue
		var d := Vector2(p.x, p.y).distance_to(global_pos)
		if d < best_d:
			best_d = d
			best = r
	return best


# ── Input ────────────────────────────────────────────────────────────────────

## Called from PlanetaryView._input before anything else. True = consumed.
func handle_input(event: InputEvent) -> bool:
	if not _active():
		_box_from = Vector2.INF
		return false
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_mouse = mm.global_position
		if _landing_id != "":
			queue_redraw()
		var h := rover_at(mm.global_position)
		var hid := h.id if h != null else ""
		if hid != _hover_id:
			_hover_id = hid
			queue_redraw()
		if _box_from.is_finite():
			_box_to = mm.global_position
			queue_redraw()
			return true
		return false
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE and _landing_id != "":
			_landing_id = ""
			queue_redraw()
			return true
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE and has_selection():
			clear_selection()
			return true
		return false
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if not _over_planet(mb.global_position):
				_press_pos = Vector2.INF
				return false   # a panel / button above the globe has it
			if _landing_id != "":
				_pick_landing(mb.global_position)
				return true
			var hit := rover_at(mb.global_position)
			if hit != null:
				_press_pos = Vector2.INF
				if mb.double_click:
					_selected.clear()
					for r: RoverData in RoverManager.rovers_on(_seed()):
						_selected.append(r.id)
				elif mb.shift_pressed:
					if hit.id in _selected:
						_selected.erase(hit.id)
					else:
						_selected.append(hit.id)
				else:
					_selected.clear()
					_selected.append(hit.id)
				AudioManager.play("poi_select")
				queue_redraw()
				return true
			if mb.shift_pressed:
				_box_from = mb.global_position
				_box_to = mb.global_position
				return true
			_press_pos = mb.global_position
			return false
		# release
		if _box_from.is_finite():
			_finish_box()
			return true
		if _press_pos.is_finite() and mb.global_position.distance_to(_press_pos) < CLICK_PX \
				and has_selection():
			clear_selection()   # not consumed: the click still picks a district etc.
		_press_pos = Vector2.INF
	return false


## A right click without drag (from PlanetaryView). True = used as an order.
func handle_right_click(global_pos: Vector2, queue: bool) -> bool:
	if not _active() or not has_selection() or not _over_planet(global_pos):
		return false
	if _landing_id != "":   # right click calls the landing pick off
		_landing_id = ""
		queue_redraw()
		return true
	var hit := rover_at(global_pos)
	if hit != null and hit.id in _selected:
		for id: String in _selected:
			var r = RoverManager.get_rover(id)
			if r != null:
				RoverManager.stop(r)
		AudioManager.play("click")
		queue_redraw()
		return true
	var ll: Dictionary = _view.call("_screen_to_lonlat", global_pos)
	if not ll.get("hit", false):
		return true   # off the globe: swallow, nothing to do
	var pd := _planet_data()
	var lon: float = ll["lon"]
	var lat: float = ll["lat"]
	var target := RoverManager.dir_of(lon, lat)
	var any_ok := false
	var n := _selected.size()
	for i in n:
		var r = RoverManager.get_rover(_selected[i])
		if r == null:
			continue
		var spot := _fan_spot(pd, lon, lat, i, n)
		if RoverManager.order_move(r, pd, spot.x, spot.y, queue):
			any_ok = true
	_pings.append({"pos": target, "t": 0.0, "ok": any_ok})
	AudioManager.play("click" if any_ok else "error")
	queue_redraw()
	return true


func _pick_landing(global_pos: Vector2) -> void:
	var r = RoverManager.get_rover(_landing_id)
	var ll: Dictionary = _view.call("_screen_to_lonlat", global_pos)
	if r == null or not ll.get("hit", false):
		return
	var ok: bool = RoverManager.start_action(r, "land", {"lon": ll["lon"], "lat": ll["lat"]})
	_pings.append({"pos": RoverManager.dir_of(ll["lon"], ll["lat"]), "t": 0.0, "ok": ok})
	AudioManager.play("click" if ok else "error")
	if ok:
		_landing_id = ""
	queue_redraw()


## Where rover i of n goes around (lon, lat): the first in the middle, the
## others on a small ring, so a group doesn't stack on one point.
func _fan_spot(pd: PlanetData, lon: float, lat: float, i: int, n: int) -> Vector2:
	if i == 0 or n <= 1:
		return Vector2(lon, lat)
	var ring := deg_to_rad(1.2)
	var a := TAU * float(i - 1) / float(maxi(n - 1, 1))
	var slon := lon + cos(a) * ring / maxf(cos(lat), 0.2)
	var slat := clampf(lat + sin(a) * ring, -PI * 0.5, PI * 0.5)
	if RoverManager.passable(pd, slon, slat):
		return Vector2(slon, slat)
	return Vector2(lon, lat)


## On the globe's screen area and not under a panel / button (PlanetaryView's test).
func _over_planet(global_pos: Vector2) -> bool:
	return bool(_view.call("_is_over_planet_area", global_pos))


func _finish_box() -> void:
	var rect := Rect2(_box_from, Vector2.ZERO).expand(_box_to)
	_box_from = Vector2.INF
	_box_to = Vector2.INF
	if rect.size.length() < CLICK_PX:
		queue_redraw()
		return
	for r: RoverData in RoverManager.rovers_on(_seed()):
		if r.in_orbit():
			continue
		var p := _project(r.pos)
		if p.z > 0.05 and rect.has_point(Vector2(p.x, p.y)) and not (r.id in _selected):
			_selected.append(r.id)
	if has_selection():
		AudioManager.play("poi_select")
	queue_redraw()


# ── Frame ────────────────────────────────────────────────────────────────────

var _last_sel: Array[String] = []

func _process(delta: float) -> void:
	if _planet == null or not RoverManager.ENABLED:
		return
	if _selected != _last_sel:
		_last_sel = _selected.duplicate()
		selection_changed.emit(_last_sel.duplicate())
	for p: Dictionary in _pings:
		p["t"] = float(p["t"]) + delta
	var live: Array[Dictionary] = []
	for p: Dictionary in _pings:
		if float(p["t"]) < 0.7:
			live.append(p)
	_pings = live
	if not RoverManager.rovers_on(_seed()).is_empty() or not _pings.is_empty() or _landing_id != "":
		queue_redraw()


func _draw() -> void:
	if _planet == null or not RoverManager.ENABLED:
		return
	var rovers := RoverManager.rovers_on(_seed())
	if rovers.is_empty() and _pings.is_empty():
		return
	var block := _block()
	var clip := _clip_rect()
	var radius_km := Location.radius_km(_planet_data()) if _planet_data() != null else Balance.cfg.planet_radius_km
	# selected first: scan ring and route under everything
	for r: RoverData in rovers:
		if r.id in _selected and not r.in_orbit():
			_draw_ring(r.pos, RoverManager.SCAN_RADIUS_KM / radius_km, Color(SEL_COL, 0.35), block, clip)
			_draw_route(r, block, clip)
	for r: RoverData in rovers:
		if r.in_orbit():
			continue
		var p := _project(r.pos)
		if p.z <= 0.0 or not clip.has_point(Vector2(p.x, p.y)):
			continue
		var sp := Vector2(p.x, p.y) - global_position
		var a := clampf(p.z * 4.0, 0.0, 1.0)   # fade at the limb
		var sel := r.id in _selected
		var body := Color(1.0, 1.0, 1.0) if sel else BODY_COL
		if RoverManager.in_storm(r):
			body = body.lerp(Color(0.75, 0.6, 1.0), 0.5)
		if r.is_busy():   # working: a slow brightness pulse
			body = body.lerp(Color.WHITE, 0.35 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)))
		_draw_sprite(sp, SPRITE, block, {"#": Color(body, a)}, a, _facing_left(r))
		if sel:
			_draw_brackets(sp, block * 5.5, block, Color(SEL_COL, a))
		if sel or r.id == _hover_id:
			_draw_label(r, sp + Vector2(0, -block * 6.0), a)
	for ping: Dictionary in _pings:
		_draw_ping(ping, block, clip)
	if _landing_id != "":
		_draw_landing_ghost(block, clip, radius_km)
	if _box_from.is_finite():
		var rect := Rect2(_box_from - global_position, Vector2.ZERO).expand(_box_to - global_position)
		draw_rect(rect, Color(SEL_COL, 0.08))
		draw_rect(rect, Color(SEL_COL, 0.8), false, 1.0)


func _draw_route(r: RoverData, block: float, clip: Rect2) -> void:
	if r.path.is_empty():
		return
	var pts: Array[Vector3] = [r.pos]
	pts.append_array(r.path)
	var road: Array[bool] = []
	for i in r.path.size():
		road.append(r.path_road[i] if i < r.path_road.size() else false)
	var step := deg_to_rad(0.4)
	var k := 0
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n := maxi(1, int(ceil(a.angle_to(b) / step)))
		for s in n:
			k += 1
			if k % 3 != 0:
				continue
			var p := _project(a.slerp(b, float(s) / float(n)).normalized())
			if p.z > 0.0 and clip.has_point(Vector2(p.x, p.y)):
				var lp := ((Vector2(p.x, p.y) - global_position) / block).floor() * block
				draw_rect(Rect2(lp, Vector2(block, block)), ROAD_PATH_COL if road[i] else PATH_COL)
	for gi in r.goals.size():
		var gp := _project(r.goals[gi])
		if gp.z <= 0.0 or not clip.has_point(Vector2(gp.x, gp.y)):
			continue
		var c := Vector2(gp.x, gp.y) - global_position
		var last := gi == r.goals.size() - 1
		var half := block * (2.0 if last else 1.0)
		draw_rect(Rect2((c - Vector2(half, half)).floor(), Vector2(half, half) * 2.0), Color(0, 0, 0, 0.7))
		draw_rect(Rect2((c - Vector2(half, half) * 0.5).floor(), Vector2(half, half)), SEL_COL)
		if last:   # arrival time at the destination only
			var eta := RoverManager.format_eta(RoverManager.eta_sec(r))
			_draw_tag("ETA " + eta, c + Vector2(half + block * 2.0, half), 1.0)


func _draw_ring(center: Vector3, rad: float, col: Color, block: float, clip: Rect2) -> void:
	var up := Vector3.UP if absf(center.y) < 0.95 else Vector3.RIGHT
	var u := center.cross(up).normalized()
	var v := center.cross(u).normalized()
	var segs := clampi(int(TAU * sin(rad) * _r_px() / (block * 3.0)), 24, 200)
	for i in segs:
		var a := TAU * float(i) / float(segs)
		var d := (center * cos(rad) + (u * cos(a) + v * sin(a)) * sin(rad)).normalized()
		var p := _project(d)
		if p.z > 0.0 and clip.has_point(Vector2(p.x, p.y)):
			var lp := ((Vector2(p.x, p.y) - global_position) / block).floor() * block
			draw_rect(Rect2(lp, Vector2(block, block)), col)


## Landing pick: a ring and brackets under the mouse, red where it can't land.
func _draw_landing_ghost(block: float, clip: Rect2, radius_km: float) -> void:
	var ll: Dictionary = _view.call("_screen_to_lonlat", _mouse)
	if not ll.get("hit", false):
		return
	var pd := _planet_data()
	var ok := pd != null and RoverManager.passable(pd, ll["lon"], ll["lat"])
	var col := SEL_COL if ok else BAD_COL
	var v := RoverManager.dir_of(ll["lon"], ll["lat"])
	_draw_ring(v, 120.0 / radius_km, Color(col, 0.8), block, clip)
	_draw_brackets(_mouse - global_position, block * 4.0, block, col)
	_draw_tag("Land here" if ok else "Can't land here", _mouse - global_position + Vector2(block * 6.0, -block * 4.0), 1.0)


func _draw_ping(ping: Dictionary, block: float, clip: Rect2) -> void:
	var p := _project(ping["pos"])
	if p.z <= 0.0 or not clip.has_point(Vector2(p.x, p.y)):
		return
	var t: float = float(ping["t"]) / 0.7
	var c := Vector2(p.x, p.y) - global_position
	var col := Color(SEL_COL if ping["ok"] else BAD_COL, 1.0 - t)
	if ping["ok"]:
		_draw_brackets(c, block * lerpf(6.0, 2.0, t), block, col)
	else:
		for i in range(-2, 3):
			draw_rect(Rect2((c + Vector2(i, i) * block).floor(), Vector2(block, block)), col)
			draw_rect(Rect2((c + Vector2(i, -i) * block).floor(), Vector2(block, block)), col)


func _draw_label(r: RoverData, at: Vector2, a: float) -> void:
	var sz := _font.get_string_size(r.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	_draw_tag(r.name, at - Vector2(sz.x * 0.5, 0), a)


## Small text on a dark plate; `pos` = left end of the baseline.
func _draw_tag(text: String, pos: Vector2, a: float) -> void:
	var fs := 13
	var sz := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	pos = pos.floor()
	draw_rect(Rect2(pos + Vector2(-4, -sz.y + 2), Vector2(sz.x + 8, sz.y + 2)), Color(0, 0, 0, 0.6 * a))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))


## Remembered facing per rover id (true = left), so it keeps its side when it stops.
var _face_left: Dictionary = {}

## Whether the rover's sprite should face left: its last movement, on screen.
func _facing_left(r: RoverData) -> bool:
	if r.is_moving() and r.heading != Vector3.ZERO:
		var a := _project(r.pos)
		var b := _project((r.pos + r.heading * 0.01).normalized())
		if absf(b.x - a.x) > 0.01:
			_face_left[r.id] = b.x < a.x
	return bool(_face_left.get(r.id, false))


## Multi-colour pixel sprite: each character of `rows` picks its colour from
## `colors` ("." = empty), with a 1-block dark outline under everything.
func _draw_sprite(center: Vector2, rows: Array, block: float, colors: Dictionary, alpha: float, flip := false) -> void:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var origin := (center - Vector2(w, h) * block * 0.5).floor()
	var outline := Color(0, 0, 0, alpha * 0.85)
	for pass_i in 2:
		for y in h:
			var row: String = rows[y]
			for x in w:
				var ch := row[w - 1 - x] if flip else row[x]
				if ch == "." or not colors.has(ch):
					continue
				var p := origin + Vector2(x, y) * block
				if pass_i == 0:
					draw_rect(Rect2(p - Vector2(block, block), Vector2(block, block) * 3.0), outline)
				else:
					draw_rect(Rect2(p, Vector2(block, block)), colors[ch])


func _draw_brackets(center: Vector2, half: float, block: float, col: Color) -> void:
	var arm := block * 2.0
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var corner := (center + Vector2(sx, sy) * half).floor()
			var hx := corner.x if sx < 0.0 else corner.x - arm + block
			var vy := corner.y if sy < 0.0 else corner.y - arm + block
			draw_rect(Rect2(Vector2(hx, corner.y), Vector2(arm, block)), col)
			draw_rect(Rect2(Vector2(corner.x, vy), Vector2(block, arm)), col)
