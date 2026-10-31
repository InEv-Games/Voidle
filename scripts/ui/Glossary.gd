class_name Glossary
extends RefCounted

## Terms a tooltip can explain in a nested tip (playtest 31.10): the text
## carries [url=id]Label[/url] (drawn underlined); once the tip is locked,
## hovering the term opens its own small tip beside it (TooltipManager).
##   "Earned by %s." % Glossary.t("commercial", "Commercial districts")

## Entries made on the fly by a tooltip (grouped breakdowns): id → [title, text].
static var _dyn: Dictionary = {}

static func put(id: String, title: String, text: String) -> void:
	_dyn[id] = [title, text]

static func t(id: String, label: String) -> String:
	return "[url=%s]%s[/url]" % [id, label]

## [title, BBCode text] of a term, [] when unknown. Besides the fixed terms:
## "b:<building id>" a building, "d:<district key>" a district type,
## "src:<resource>|<line>" the units behind a top-bar income line.
static func entry(id: String) -> Array:
	if _dyn.has(id):
		return _dyn[id]
	if id.begins_with("b:"):
		return _building_entry(id.substr(2))
	if id.begins_with("d:"):
		return _district_entry(id.substr(2))
	if id.begins_with("src:"):
		var p := id.substr(4).split("|", true, 1)
		return _source_entry(p[0], p[1] if p.size() > 1 else "")
	var c: BalanceConfig = Balance.cfg
	match id:
		"commercial":
			return ["Commercial District", "Built under a City. Makes Credits every cycle; markets there add more."]
		"science_d":
			return ["Science District", "Built under a City. Makes Science every cycle; labs there add more."]
		"industrial":
			return ["Production District", "Mines this world's minerals; its processing buildings turn them into Consumer Goods, Fuel Rods and Rare Elements."]
		"upgrade_tree":
			return ["Upgrade Tree", "Research: Science buys nodes that open buildings and raise output. Open it from the bottom bar."]
		"grid":
			return ["Energy grid", "All your worlds share one energy balance: what every generator makes minus what every building uses."]
		"deficit":
			return ["Deficit", "More used than made.\nEnergy: buildings that use energy make less (down to %d%%).\nPopulation: every finished cycle makes less (down to %d%%)." % [
				int(round((1.0 - c.energy_max_slowdown) * 100.0)), int(round((1.0 - c.pop_max_slowdown) * 100.0))]]
		"housing":
			return ["Housing", "Room for people. Cities house %s each; Residential districts and housing buildings add more. Max population is all of it together." % Economy.fmt(c.city_base_pop)]
		"workers":
			return ["Workers", "People put to work by districts, district levels and buildings. They need housing."]
		"cycle":
			return ["Cycle", "Output comes in at the end of each cycle. Research shortens it."]
		"storage":
			return ["Storage", "Most goods have a cap shared by every world. Storage buildings raise it; what doesn't fit is lost unless Trade automation sells it."]
		"trade":
			return ["Trade", "Buy and sell stocked goods for Credits. Prices move with your trades and drift back over time."]
		"idle":
			return ["Idle population", "Housed people nobody employs. Some research turns them into Credits, Science or extra output."]
		"kardashev":
			return ["Kardashev scale", "How much power a civilization uses: Type I uses a whole planet's (about 10¹⁶ W), Type II a star's, Type III a galaxy's. K = (log₁₀ W − 6) / 10, counting 1 energy as 1 MW."]
	return []

## "[icon] +10" in the resource's colour (a malus red); a mineral by name.
static func _res(id: String, v: float, sign := "+") -> String:
	var col := Economy.color_of(id) if id != Economy.RAW else Color(0.85, 0.78, 0.70)
	if sign == "−":
		col = Color(0.89, 0.42, 0.42)
	var num := Economy.fmt(absf(v)) if absf(v) >= 1000.0 else BuildingDef._num(snappedf(absf(v), 0.1))
	if UIIcons.has_icon(id):
		return "%s [color=#%s]%s%s[/color]" % [UIIcons.bb(id, 11, col), col.to_html(false), sign, num]
	return "[color=#%s]%s%s %s[/color]" % [col.to_html(false), sign, num, Economy.display_name(id)]

## A building as the build list shows it (playtest 31.10): its district type
## in the top-right corner; one row led by the cycle icon with everything that
## flows each cycle (made +, used −); one right-aligned row with what it takes
## once (credits, materials, workers).
static func _building_entry(bid: String) -> Array:
	var b := BuildingDef.find(bid)
	if b == null:
		return []
	var lines: Array[String] = []
	if b.description != "":
		lines.append(b.description)
	var bonus: Array[String] = []
	for id: String in b.planet_bonus:
		bonus.append("%s [color=#%s]+%d%%[/color]" % [UIIcons.bb(id, 11, Economy.color_of(id)),
			Economy.color_of(id).to_html(false), roundi(float(b.planet_bonus[id]) * 100.0)])
	if not bonus.is_empty():
		lines.append("   ".join(bonus))
	var flow: Array[String] = []
	var stock := false
	for id: String in b.outputs:
		flow.append(_res(id, float(b.outputs[id])))
		stock = stock or (id != Economy.ENERGY and id != Economy.POPULATION)
	if b.energy_per_tick < 0.0:
		flow.append(_res(Economy.ENERGY, b.energy_per_tick, "−"))
	for id: String in b.inputs:
		flow.append(_res(id, float(b.inputs[id]), "−"))
	if not flow.is_empty():
		var lead := ("%s [color=#8a93b0]%s[/color]   " % [UIIcons.bb("cycle", 11, Color(0.54, 0.58, 0.69)),
			ProductionManager.cycle_text(ProductionManager.building_cycle_sec(b))]) if stock else ""
		lines.append("")
		lines.append(lead + "   ".join(flow))
	var once: Array[String] = []
	var home := GameState.get_planet(GameState.home_planet_seed)
	if home != null:
		var cost := Economy.building_full_cost(home, b, "")
		for id: String in cost:
			once.append(_res(id, float(cost[id]), ""))
	if b.pop_use() > 0:
		once.append("%s [color=#d9e0ff]%s[/color]" % [UIIcons.bb("worker", 11, Color(0.85, 0.88, 1.0)), Economy.fmt(b.pop_use())])
	if not once.is_empty():
		lines.append("[right]%s[/right]" % "   ".join(once))
	var types: Array[String] = []
	for t in b.allowed_poi_types:
		types.append(POIData.TYPE_LABELS[int(t)])
	var corner := "%s [color=#8a93b0]%s[/color]" % [UIIcons.bb("district", 11, Color(0.54, 0.58, 0.69)), ", ".join(types)]
	return [b.display_name, "\n".join(lines), corner]

static func _district_entry(key: String) -> Array:
	var d := DistrictDef.find_by_key(key)
	if d == null:
		return []
	var lines: Array[String] = [d.description]
	if not d.base_outputs.is_empty():
		var parts: Array[String] = []
		for id: String in d.base_outputs:
			parts.append("+%s %s" % [BuildingDef._num(float(d.base_outputs[id])), Economy.display_name(id)])
		lines.append("[color=#8fe39a]Makes[/color]  %s per cycle (before bonuses)" % ", ".join(parts))
	return [d.display_name, "\n".join(lines)]

static func _source_entry(rid: String, label: String) -> Array:
	var units: Dictionary = ProductionManager.resource_units(rid, label)
	if units.is_empty():
		return []
	var keys: Array = units.keys()
	keys.sort_custom(func(a, b) -> bool: return absf(float(units[a])) > absf(float(units[b])))
	var lines: Array[String] = []
	for k in keys.slice(0, 12):
		var v := float(units[k])
		lines.append("[color=#%s]%s%s /s[/color]  %s" % ["8fe39a" if v >= 0.0 else "e36a6a", "+" if v >= 0.0 else "−",
			BuildingDef._num(snappedf(absf(v), 0.01)), k])
	if keys.size() > 12:
		lines.append("[color=#8a93b0]… and %d more[/color]" % (keys.size() - 12))
	return [label, "\n".join(lines)]

## Wraps known names in a plain text — buildings, district types — in nested
## tip links (research tooltips, playtest 31.10). Longest names first, each
## name once; text already inside a tag is left alone.
static func link(text: String) -> String:
	var names: Array = []   # [name, url id]
	for b: BuildingDef in BuildingDef.all():
		if not b.retired and b.display_name != "":
			names.append([b.display_name, "b:" + b.building_id])
	for d: DistrictDef in DistrictDef.all():
		if d.display_name != "":
			names.append([d.display_name + "s", "d:" + d.type_key()])
			names.append([d.display_name, "d:" + d.type_key()])
	names.sort_custom(func(a, b) -> bool: return String(a[0]).length() > String(b[0]).length())
	var tokens: Array[String] = []
	var out := text
	for n: Array in names:
		var nm := String(n[0])
		var at := out.find(nm)
		if at < 0:
			continue
		var tok := "\u0001%d\u0002" % tokens.size()
		tokens.append(t(String(n[1]), nm))
		out = out.substr(0, at) + tok + out.substr(at + nm.length())
	for i in tokens.size():
		out = out.replace("\u0001%d\u0002" % i, tokens[i])
	return out
