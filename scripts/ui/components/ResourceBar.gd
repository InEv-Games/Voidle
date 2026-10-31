## The top resource bar (design: Resource Panels):
##   Credits │ Science │ Energy │ Population │ Raw ▾ │ Goods │ Fuel │ Rare
## Layout: scenes/ui/components/ResourceBar.tscn — one ResourceChip per
## resource, its resource_id and value_width set in the scene. Look: ResourceBar.
## Values show the stock only (red at the cap, see Economy.cap) with the steady
## income per second as a small superscript; refreshed four times a second.
## HUDManager puts it on its top layer (HUDManager.credits_panel).
class_name ResourceBar
extends Panel

const SCENE_PATH := "res://scenes/ui/components/ResourceBar.tscn"
const FLOAT_FONT := preload("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")
## Plain descriptions (fallback); _show_cell_tip builds every tip live.
const TIPS := {
	"credits": "Earned by Commercial districts. Spent on districts and buildings.",
	"science": "Produced by Science districts. Spent in the Upgrade Tree.",
	"goods": "Consumer Goods — made from raw resources in Industrial districts.\nUsed by luxury housing and trade.",
	"fuel": "Fuel Rods — made from raw resources in Industrial districts.\nUsed by advanced power plants.",
	"rare_elements": "Rare Elements — made from raw resources in Industrial districts.\nUsed by advanced science.",
}

## id -> value Label
var _res_lbls: Dictionary = {}
## id -> the cell
var _res_slots: Dictionary = {}
## id -> ResourceChip
var _res_chips: Dictionary = {}
## Small superscript income labels next to each value: id -> Label
var _rate_lbls: Dictionary = {}
## Raw resources dropdown under the "Raw ▾" cell (null when closed)
var _raw_dd: PanelContainer = null
var _raw_dd_list: VBoxContainer = null
var _raw_cell: Control = null
var _poll := 0.0

static func create() -> ResourceBar:
	return (load(SCENE_PATH) as PackedScene).instantiate() as ResourceBar

func _ready() -> void:
	for c in $Row.get_children():
		if c is ResourceChip:
			_bind_chip(c)
	_refresh_resource_cells()

func _process(delta: float) -> void:
	_poll += delta
	if _poll >= 0.25:
		_poll = 0.0
		_refresh_resource_cells()

## Largest value size is the theme's ValueLabel font size (voidle_theme.tres).
const VALUE_FONT_MIN := 7

## Sets a value label's text, shrinking its font until it fits its fixed width.
func _set_value(lbl: Label, text: String) -> void:
	if lbl.text == text:
		return
	lbl.text = text
	var font: Font = lbl.get_theme_font("font")
	var w := lbl.custom_minimum_size.x
	var size := UIStyle.font_size(&"ValueLabel")
	while size > VALUE_FONT_MIN and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w:
		size -= 1
	lbl.add_theme_font_size_override("font_size", size)

## ── Incoming resources ──────────────────────────────────────────────────────
## A gain shows as "+x" under its cell, floats up into the bar, and the value
## then ticks up to the new amount. Spending updates at once.
var _shown: Dictionary = {}     # id -> value currently displayed
var _target: Dictionary = {}    # id -> value the display is heading to
var _gain_tw: Dictionary = {}   # id -> Tween

func _stock_amount(id: String) -> float:
	return Economy.raw_total() if id == Economy.RAW else Economy.amount(id)

func _stock_text(id: String, v: float) -> String:
	match id:
		Economy.CREDITS: return HUDManager.fmt_credits(v)
		Economy.RAW:     return "%s %s" % [Economy.fmt(v), "▴" if _raw_dd != null else "▾"]
	return Economy.fmt(v)

func _track_stock(id: String) -> void:
	var lbl: Label = _res_lbls.get(id)
	if not is_instance_valid(lbl):
		return
	var actual := _stock_amount(id)
	if not _shown.has(id):
		_shown[id] = actual
		_target[id] = actual
	var target: float = _target[id]
	if actual > target + 0.05:
		_target[id] = actual
		_spawn_gain(id, actual - target, lbl)
		var tw: Tween = _gain_tw.get(id)
		if tw != null and tw.is_valid():
			tw.kill()
		tw = create_tween()
		_gain_tw[id] = tw
		tw.tween_interval(0.55)   # let the "+x" reach the bar first
		tw.tween_method(func(v: float) -> void:
			_shown[id] = v
			if is_instance_valid(lbl):
				_set_value(lbl, _stock_text(id, v)),
			float(_shown[id]), actual, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif actual < target - 0.0001:
		var tw2: Tween = _gain_tw.get(id)
		if tw2 != null and tw2.is_valid():
			tw2.kill()
		if target - actual >= 0.05:
			_spawn_loss(id, target - actual, lbl)
		_target[id] = actual
		_shown[id] = actual
	_set_value(lbl, _stock_text(id, _shown[id]))

func _spawn_gain(id: String, amount: float, lbl: Label) -> void:
	if get_parent() == null or amount < 0.05:
		return
	var chip := Label.new()
	chip.text = "+" + (HUDManager.fmt_credits(amount) if id == Economy.CREDITS else Economy.fmt(amount))
	chip.add_theme_font_override("font", FLOAT_FONT)
	chip.add_theme_font_size_override("font_size", 10)
	var col := Economy.color_of(id) if id != Economy.RAW else Color(0.85, 0.78, 0.70)
	chip.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.25))
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	chip.add_theme_constant_override("outline_size", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(chip)
	var start := lbl.global_position + Vector2(2.0, lbl.size.y + 14.0)
	chip.position = start
	chip.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(chip, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(chip, "position:y", start.y - 4.0, 0.12)
	tw.tween_interval(0.2)
	tw.tween_property(chip, "position:y", lbl.global_position.y + 2.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(chip, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tw.tween_callback(chip.queue_free)

## A spend shows as a red "−x" that drops out of the value and fades.
func _spawn_loss(id: String, amount: float, lbl: Label) -> void:
	if get_parent() == null:
		return
	var chip := Label.new()
	chip.text = "−" + (HUDManager.fmt_credits(amount) if id == Economy.CREDITS else Economy.fmt(amount))
	chip.add_theme_font_override("font", FLOAT_FONT)
	chip.add_theme_font_size_override("font_size", 10)
	chip.add_theme_color_override("font_color", UIStyle.color(&"bad"))
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	chip.add_theme_constant_override("outline_size", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(chip)
	var start := lbl.global_position + Vector2(2.0, lbl.size.y * 0.5)
	chip.position = start
	var tw := create_tween()
	tw.tween_property(chip, "position:y", start.y + 26.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(chip, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.tween_callback(chip.queue_free)

func _set_rate(id: String, per_s: float) -> void:
	var chip: ResourceChip = _res_chips.get(id)
	if not is_instance_valid(chip) or not _rate_lbls.has(id):
		return
	var v := snappedf(per_s, 0.1)
	chip.rate_text = ("+" if v >= 0.0 else "−") + Economy.fmt(absf(v))
	chip.rate_tone = ResourceChip.Tone.GOOD if v >= 0.0 else ResourceChip.Tone.BAD

## Hooks up one of the scene's chips: value / rate labels, tooltip, and the
## Raw chip's dropdown.
func _bind_chip(cell: ResourceChip) -> void:
	var id := cell.resource_id
	_res_slots[id] = cell
	_res_chips[id] = cell
	_res_lbls[id] = cell.value_label
	if id != Economy.ENERGY and id != Economy.POPULATION:
		# energy: net only; population: available / max — the rest is in the tooltip
		_rate_lbls[id] = cell.rate_label
	var title := Economy.display_name(id).to_upper() if id != Economy.RAW else "RAW RESOURCES"
	cell.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		if id == Economy.RAW:
			if _raw_dd == null:
				TooltipManager.show_tip(title, "Click to show every raw resource.")
				TooltipManager.set_title_icon(id)
			return
		_show_cell_tip(id, title))
	cell.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	if id == Economy.RAW:
		_raw_cell = cell
		cell.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
					and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				AudioManager.play("click")
				TooltipManager.hide_tip()
				_toggle_raw_dropdown()
				cell.accept_event())
	elif id != Economy.ENERGY and id != Economy.POPULATION:
		# a tradeable resource opens Trade (playtest 30.10)
		cell.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
					and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				AudioManager.play("click")
				TooltipManager.hide_tip()
				HUDManager.toggle_trade_panel()
				cell.accept_event())

const GOOD_HEX := "8fe39a"
const BAD_HEX := "e36a6a"
const DIM_HEX := "8a93b0"

## A cell's description, with its terms opening nested tips (Glossary).
static func _desc(id: String) -> String:
	match id:
		Economy.CREDITS:
			return "Earned by %s. Spent on districts and buildings." % Glossary.t("commercial", "Commercial districts")
		Economy.SCIENCE:
			return "Made by %s. Spent in the %s." % [Glossary.t("science_d", "Science districts"), Glossary.t("upgrade_tree", "Upgrade Tree")]
		Economy.GOODS:
			return "Consumer Goods — made from raw minerals in %s. Used by luxury housing and %s." % [
				Glossary.t("industrial", "Production districts"), Glossary.t("trade", "Trade")]
		Economy.FUEL:
			return "Fuel Rods — made from raw minerals in %s. Used by advanced power plants." % Glossary.t("industrial", "Production districts")
		Economy.RARE:
			return "Rare Elements — made from raw minerals in %s. Used by advanced science and planet traits." % Glossary.t("industrial", "Production districts")
	return String(TIPS.get(id, ""))

## An inline icon for the corner (UIIcons name, tint as hex).
static func _ic(icon: String, hex: String) -> String:
	return UIIcons.bb(icon, 11, Color.html(hex))

static func _c(txt: String, hex: String) -> String:
	return "[color=#%s]%s[/color]" % [hex, txt]

## Every top-bar tip in one shape (playtest 31.10): the description (terms open
## nested tips once it locks); stored / max — energy used / made, population
## working / max — in the top-right corner; coloured income lines and the net
## behind a separator; a deficit and what it does in red at the bottom; the
## least important line, "Click to open Trade", small at the very end.
func _show_cell_tip(id: String, title: String) -> void:
	var desc := _desc(id)
	var corner := ""
	var detail := ""
	var foot := ""
	match id:
		Economy.ENERGY:
			var pm: Node = get_node_or_null("/root/ProductionManager")
			var net: float = pm.get_global_energy() if pm != null else 0.0
			var sp: Vector2 = pm.get_global_energy_split() if pm != null else Vector2.ZERO
			desc = "Made by generators, used by buildings. All your worlds share one %s." % Glossary.t("grid", "grid")
			# icons, not words (playtest 31.10): generators make, buildings use
			corner = "%s %s   %s %s" % [_ic("bolt", GOOD_HEX), _c("+" + Economy.fmt(sp.x), GOOD_HEX),
				_ic("factory", BAD_HEX), _c("−" + Economy.fmt(sp.y), BAD_HEX)]
			detail = _energy_groups_text()
			# the civilization's type by the power it uses (1 energy = 1 MW)
			var k := (log(maxf(sp.y, 0.000001) * 1_000_000.0) / log(10.0) - 6.0) / 10.0
			detail += "\n\n%s  [b]Type %s[/b]" % [Glossary.t("kardashev", "Kardashev scale"), "%.3f" % maxf(k, 0.0)]
			if net < 0.0:
				detail += "\n\n" + _c("Energy %s: buildings that use energy make %d%% of their output." % [
					Glossary.t("deficit", "deficit"), int(round(pm.get_energy_ratio() * 100.0))], BAD_HEX)
		Economy.POPULATION:
			# one pool for every world: the home world answers for all of them
			var pd: PlanetData = GameState.get_planet_data(GameState.home_planet_seed)
			var pp: PlanetProgress = GameState.get_planet(pd.seed) if pd != null else null
			desc = "People live in %s and go to work as %s. One pool for every world." % [
				Glossary.t("housing", "housing"), Glossary.t("workers", "workers")]
			if pd != null and pp != null and pp.is_colonized:
				var used := Economy.used_population(pd, pp)
				var mx := Economy.max_population(pd, pp)
				corner = "%s %s   %s %s" % [_ic("worker", "d9e0ff"), Economy.fmt(used),
					_ic("population", Economy.color_of(Economy.POPULATION).to_html(false)), Economy.fmt(mx)]
				detail = _population_groups_text() + "\n[b]Free  %s[/b]" % _c(
					("+" if mx >= used else "−") + Economy.fmt(absi(mx - used)), GOOD_HEX if mx >= used else BAD_HEX) + _idle_pop_text()
				var spd := Economy.pop_speed(pd, pp)
				if spd < 0.999:
					detail += "\n\n" + _c("Overcrowded — a %s: every cycle on every world makes %d%% of its output." % [
						Glossary.t("deficit", "deficit"), int(round(spd * 100.0))], BAD_HEX)
		_:
			# a storage cap is worth the corner; a lone stock number is not
			var cap_id := id if id != Economy.RAW else "ferrite"
			if Economy.is_capped(id) or id == Economy.RAW:
				corner = "%s %s %s" % [Economy.fmt(_stock_amount(id)), _ic("warehouse", DIM_HEX), Economy.fmt(Economy.cap(cap_id))]
			detail = breakdown_text(id)
			foot = "Click to open Trade"
	TooltipManager.show_tip(title, desc)
	TooltipManager.set_title_icon(id)
	TooltipManager.set_corner(corner)
	TooltipManager.set_detail(detail)
	if foot != "":
		TooltipManager.set_footer("[font_size=10]%s[/font_size]" % _c(foot, DIM_HEX), "")

## "+1.2 /s  Market" lines of a resource, largest first, then the net (all worlds).
static func breakdown_text(id: String) -> String:
	var parts: Dictionary = ProductionManager.resource_breakdowns().get(id, {})
	var keys: Array = parts.keys()
	keys.sort_custom(func(a, b) -> bool: return absf(float(parts[a])) > absf(float(parts[b])))
	var lines: Array[String] = [_c("Per second, all worlds", DIM_HEX)]
	var net := 0.0
	for k in keys:
		var v := float(parts[k])
		net += v
		if lines.size() <= 10:
			# a line made of several units opens them in a nested tip
			var units: Dictionary = ProductionManager.resource_units(id, String(k))
			var nm := Glossary.t("src:%s|%s" % [id, k], String(k)) if units.size() > 1 else String(k)
			lines.append("%s  %s" % [_c(("+" if v >= 0.0 else "−") + Economy.fmt(absf(v)), GOOD_HEX if v >= 0.0 else BAD_HEX), nm])
	if keys.size() > 10:
		lines.append(_c("… and %d more" % (keys.size() - 10), DIM_HEX))
	if keys.is_empty():
		lines.append(_c("Nothing makes or uses it yet.", DIM_HEX))
	else:
		lines.append("[b]Net  %s[/b]" % _c(("+" if net >= 0.0 else "−") + Economy.fmt(absf(net)) + " /s", GOOD_HEX if net >= 0.0 else BAD_HEX))
	return "\n".join(lines)

## Group lines "+32 Solar Arrays" (largest first), each opening its units in a
## nested tip (Glossary.put), then the net. `groups`: { group: { unit: v } }.
func _group_lines(key: String, groups: Dictionary, fmt: Callable) -> Array[String]:
	var totals := {}
	for g: String in groups:
		var t := 0.0
		for u: String in groups[g]:
			t += float(groups[g][u])
		totals[g] = t
	var names: Array = totals.keys()
	names.sort_custom(func(a, b) -> bool: return float(totals[a]) > float(totals[b]))
	var lines: Array[String] = []
	for g: String in names:
		var v := float(totals[g])
		var units: Dictionary = groups[g]
		var ul: Array = units.keys()
		ul.sort_custom(func(a, b) -> bool: return absf(float(units[a])) > absf(float(units[b])))
		var sub: Array[String] = []
		for u in ul:
			var uv := float(units[u])
			sub.append("%s  %s" % [_c(("+" if uv >= 0.0 else "−") + String(fmt.call(absf(uv))), GOOD_HEX if uv >= 0.0 else BAD_HEX), u])
		var id := "grp:%s:%s" % [key, g]
		Glossary.put(id, g, "\n".join(sub))
		lines.append("%s  %s" % [_c(("+" if v >= 0.0 else "−") + String(fmt.call(absf(v))), GOOD_HEX if v >= 0.0 else BAD_HEX),
			Glossary.t(id, g) if ul.size() > 1 or String(ul[0]) != g else g])
	return lines

## Energy by source (generators, districts) and by user (buildings), grouped;
## the worlds behind the net in a nested tip when there are several.
func _energy_groups_text() -> String:
	var fmt := func(v: float) -> String: return BuildingDef._num(snappedf(v, 0.1))
	var groups: Dictionary = ProductionManager.energy_sources()
	if groups.is_empty():
		return _c("Nothing makes or uses energy yet.", DIM_HEX)
	var lines := _group_lines("energy", groups, fmt)
	var net := 0.0
	for g: String in groups:
		for u: String in groups[g]:
			net += float(groups[g][u])
	var worlds := _energy_breakdown_text()
	Glossary.put("grp:energy:worlds", "Worlds", worlds)
	lines.append("[b]%s  %s[/b]" % [Glossary.t("grp:energy:worlds", "Net"),
		_c(("+" if net >= 0.0 else "−") + String(fmt.call(absf(net))), GOOD_HEX if net >= 0.0 else BAD_HEX)])
	return "\n".join(lines)

## Housing by district type (+) and workers by district type (−), every world,
## each line opening its districts in a nested tip.
func _population_groups_text() -> String:
	var housing := {}
	var working := {}
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null:
			continue
		for poi: POIData in pd.custom_pois:
			var ddef := ProductionManager.district_def(poi)
			var g := "Capitals" if poi.is_city() else ("Orbit" if poi.is_orbital() else (ddef.display_name + "s" if ddef != null else "Districts"))
			var h := float(Economy.district_housing(pd, pp, poi))
			if h > 0.0:
				if not housing.has(g):
					housing[g] = {}
				housing[g][poi.shown_name()] = h
			var w := float(Economy.district_pop_used(pp, poi))
			if w > 0.0:
				if not working.has(g):
					working[g] = {}
				working[g][poi.shown_name()] = -w
	var fmt := func(v: float) -> String: return Economy.fmt(v)
	var lines: Array[String] = []
	if not housing.is_empty():
		lines.append(_ic("population", Economy.color_of(Economy.POPULATION).to_html(false)) + " " + _c(Glossary.t("housing", "Housing"), DIM_HEX))
		lines.append_array(_group_lines("housing", housing, fmt))
	if not working.is_empty():
		lines.append(_ic("worker", "d9e0ff") + " " + _c(Glossary.t("workers", "Working"), DIM_HEX))
		lines.append_array(_group_lines("working", working, fmt))
	return "\n".join(lines)

## Idle housing across the empire and what research turns it into.
func _idle_pop_text() -> String:
	var idle := ProductionManager.empire_idle()
	var out := "\n\n%s across all worlds  %s (%d%%)" % [Glossary.t("idle", "Idle"), Economy.fmt(idle.x),
		int(round(ProductionManager.idle_ratio() * 100.0))]
	var r := ProductionManager.idle_income_rates()
	if float(r[Economy.CREDITS]) > 0.0:
		out += "\n  +%s Credits / min  (Civic Enterprise)" % Economy.fmt(float(r[Economy.CREDITS]) * 60.0)
	if float(r[Economy.SCIENCE]) > 0.0:
		out += "\n  +%s Science / min  (Free Research)" % Economy.fmt(float(r[Economy.SCIENCE]) * 60.0)
	var reserve: float = SkillTree.reserve_mult(ProductionManager.idle_ratio())
	if reserve > 1.0:
		out += "\n  +%d%% Raw and processed output  (Production Reserve)" % int(round((reserve - 1.0) * 100.0))
	return out

## Every resource shows in the bar from the start, even before the player
## makes any (playtest 23.10) — what's ahead is part of the goal.
func _update_reveals(_rates: Dictionary) -> void:
	for id: String in _res_slots:
		(_res_slots[id] as Control).visible = true

## The world whose rates the bar shows: the one in view (null when none is colonized).
func _rate_planet() -> PlanetProgress:
	if GameState.active_planet_seed == -1:
		return null
	var pp: PlanetProgress = GameState.get_planet(GameState.active_planet_seed)
	return pp if pp != null and pp.is_colonized else null

func _rate_planet_name() -> String:
	var pd: PlanetData = GameState.get_planet_data(GameState.active_planet_seed)
	return pd.planet_name if pd != null else "this world"

func _refresh_resource_cells() -> void:
	if _res_lbls.is_empty():
		return
	# per-second rates of every world together, like the stocks (playtest 30.10:
	# the Moon's income isn't kept apart), raw minerals net of what buildings use
	var rates := {}
	for id: String in [Economy.CREDITS, Economy.SCIENCE, Economy.GOODS, Economy.FUEL, Economy.RARE, Economy.RAW]:
		rates[id] = ProductionManager.breakdown_total(id)
	_update_reveals(rates)
	_set_rate(Economy.CREDITS, rates.get(Economy.CREDITS, 0.0))
	_set_rate(Economy.SCIENCE, rates.get(Economy.SCIENCE, 0.0))
	_track_stock(Economy.CREDITS)
	_track_stock(Economy.SCIENCE)
	_set_chip_state(Economy.SCIENCE, false, GameState.science_points <= 0.0 and float(rates.get(Economy.SCIENCE, 0.0)) <= 0.0)
	var e_lbl: Label = _res_lbls.get(Economy.ENERGY)
	if is_instance_valid(e_lbl):
		# the balance (made − used) as a signed number; a deficit also shows as the chip's alert
		var esp: Vector2 = ProductionManager.get_global_energy_split()   # one grid for every world
		var bal := snappedf(esp.x - esp.y, 0.1)
		_set_value(e_lbl, "%s%s" % ["+" if bal > 0.0 else "", Economy.fmt(bal)])
		_set_chip_state(Economy.ENERGY, esp.y > esp.x, esp.x <= 0.0 and esp.y <= 0.0)

	var pop_lbl: Label = _res_lbls.get(Economy.POPULATION)
	if is_instance_valid(pop_lbl):
		# one pool for every world: the home world answers for all of them
		var pd: PlanetData = GameState.get_planet_data(GameState.home_planet_seed)
		var pp: PlanetProgress = GameState.get_planet(pd.seed) if pd != null else null
		if pd != null and pp != null and pp.is_colonized:
			var used := Economy.used_population(pd, pp)
			var mx := Economy.max_population(pd, pp)
			# available / max (used is in the tooltip)
			_set_value(pop_lbl, "%s/%s" % [Economy.fmt(mx - used), Economy.fmt(mx)])
			_set_chip_state(Economy.POPULATION, used >= mx, false)
		else:
			_set_value(pop_lbl, "—")
			_set_chip_state(Economy.POPULATION, false, true)
	for id: String in Economy.PROCESSED:
		var l: Label = _res_lbls.get(id)
		if is_instance_valid(l):
			_track_stock(id)
			_set_rate(id, rates.get(id, 0.0))
			_set_chip_state(id, Economy.is_full(id), Economy.amount(id) <= 0.0 and float(rates.get(id, 0.0)) == 0.0)
	var raw_lbl: Label = _res_lbls.get(Economy.RAW)
	if is_instance_valid(raw_lbl):
		_track_stock(Economy.RAW)
		var any_full := false
		for r: Dictionary in _listed_raws():
			if Economy.is_full(r["id"]): any_full = true
		_set_rate(Economy.RAW, rates.get(Economy.RAW, 0.0))
		_set_chip_state(Economy.RAW, any_full, Economy.raw_total() <= 0.0 and float(rates.get(Economy.RAW, 0.0)) == 0.0)
	if _raw_dd != null:
		_fill_raw_dropdown()

## Alert = value in the palette's "bad" colour (at the cap, deficit, overcrowded);
## inactive = nothing stored and nothing coming in (dimmed chip).
func _set_chip_state(id: String, alert: bool, inactive: bool) -> void:
	var chip: ResourceChip = _res_chips.get(id)
	if not is_instance_valid(chip):
		return
	if chip.alert != alert:
		chip.alert = alert
	if chip.inactive != inactive:
		chip.inactive = inactive

## Raw resources worth listing: discovered ones (or anything in stock).
## Undiscovered minerals never leak their name here.
func _listed_raws() -> Array:
	var out: Array = []
	for r: Dictionary in Economy.RAW_TABLE:
		if Economy.is_mineral_discovered(r["id"]) or Economy.amount(r["id"]) > 0.0:
			out.append(r)
	return out

func _toggle_raw_dropdown() -> void:
	if _raw_dd != null:
		_close_raw_dropdown()
		return
	if not is_instance_valid(_raw_cell) or get_parent() == null:
		return
	var dd := PanelContainer.new()
	dd.theme_type_variation = &"TooltipPanel"
	dd.mouse_filter = Control.MOUSE_FILTER_STOP
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	dd.add_child(list)
	get_parent().add_child(dd)
	dd.global_position = Vector2(_raw_cell.global_position.x - 6.0,
		global_position.y + size.y + 2.0)
	_raw_dd = dd
	_raw_dd_list = list
	_fill_raw_dropdown()
	_refresh_resource_cells()

func _close_raw_dropdown() -> void:
	if is_instance_valid(_raw_dd):
		_raw_dd.queue_free()
	_raw_dd = null
	_raw_dd_list = null
	_refresh_resource_cells()

## One ResourceChip per raw resource (mineral colour, stock; red at the cap,
## dim when empty). The name is in its tooltip.
func _fill_raw_dropdown() -> void:
	if not is_instance_valid(_raw_dd_list):
		return
	# every raw mineral has a row; undiscovered ones show unnamed (no spoiler)
	var raws: Array = Economy.RAW_TABLE
	var rows := _raw_dd_list.get_children()
	if rows.size() != raws.size() or raws.is_empty():
		for c in rows:
			c.queue_free()
		if raws.is_empty():
			var none := Label.new()
			none.text = "No raw resources yet"
			none.theme_type_variation = &"SubLabel"
			_raw_dd_list.add_child(none)
			return
		rows = []
		for r: Dictionary in raws:
			var chip := ResourceChip.create(UIIcons.RAW_PLACEHOLDER)
			chip.icon_color = r["color"]
			chip.value_width = 44.0
			var nm: String = r["name"]
			var rid: String = r["id"]
			chip.mouse_filter = Control.MOUSE_FILTER_STOP
			chip.mouse_entered.connect(func() -> void:
				if Economy.is_mineral_discovered(rid) or Economy.amount(rid) > 0.0:
					TooltipManager.show_tip(nm, "A raw mineral, mined by %s." % Glossary.t("industrial", "Production districts"))
					TooltipManager.set_corner("%s %s %s" % [Economy.fmt(Economy.amount(rid)), _ic("warehouse", DIM_HEX), Economy.fmt(Economy.cap(rid))])
					TooltipManager.set_detail(breakdown_text(rid))
				else:
					TooltipManager.show_tip("Undiscovered", "A mineral you haven't found yet."))
			chip.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
			_raw_dd_list.add_child(chip)
			rows.append(chip)
	for i in raws.size():
		var r: Dictionary = raws[i]
		var chip := rows[i] as ResourceChip
		var known: bool = Economy.is_mineral_discovered(r["id"]) or Economy.amount(r["id"]) > 0.0
		chip.icon_color = r["color"] if known else UIStyle.color(&"neutral_stroke")
		chip.value_text = Economy.fmt(Economy.amount(r["id"])) if known else "—"
		chip.alert = Economy.is_full(r["id"])
		chip.inactive = not known or Economy.amount(r["id"]) <= 0.0

## Closes the raw dropdown on any click outside it (and outside its cell).
func _input(event: InputEvent) -> void:
	if _raw_dd == null or not (event is InputEventMouseButton) or not (event as InputEventMouseButton).pressed:
		return
	var pos := (event as InputEventMouseButton).global_position
	if is_instance_valid(_raw_dd) and _raw_dd.get_global_rect().has_point(pos):
		return
	if is_instance_valid(_raw_cell) and _raw_cell.get_global_rect().has_point(pos):
		return
	_close_raw_dropdown()

func _energy_breakdown_text() -> String:
	var pm: Node = get_node_or_null("/root/ProductionManager")
	if pm == null:
		return "No data"
	# one line per world, + green / − red, then the net (playtest 31.10:
	# no separate Produced / Consumed blocks)
	var lines: Array[String] = []
	var total: float = 0.0
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		var net: float = pm.planet_energy_net(pp)
		if net == 0.0:
			continue
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		var name_str: String = pd.planet_name if pd != null else "Colony"
		lines.append("%s  %s" % [_c(("+" if net > 0.0 else "−") + BuildingDef._num(snappedf(absf(net), 0.1)),
			GOOD_HEX if net > 0.0 else BAD_HEX), name_str])
		total += net
	if lines.is_empty():
		return _c("No active colonies", DIM_HEX)
	lines.append("[b]Net  %s[/b]" % _c(("+" if total >= 0.0 else "−") + BuildingDef._num(snappedf(absf(total), 0.1)),
		GOOD_HEX if total >= 0.0 else BAD_HEX))
	return "\n".join(lines)
