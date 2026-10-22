## Trade (docs/design/VOIDLE_GDD.md §18): fixed prices, no market simulation.
##
##   access      Trade Access research opens manual buying and selling of every
##               product the player can reach, Science included; automation needs
##               Trade Automation. A raw resource must have been discovered first
##               (its name and price never show before); Fuel needs Fuel
##               Processing, Rare needs Rare Processing. Trade never opens access.
##   prices      sell = reference × trade_sell_ratio (90%), buy = reference ×
##               trade_buy_ratio (110%) from the balance profile. A future raw's
##               reference is 2 × its rarity yield.
##   overflow    with Trade Access, new production that doesn't fit in storage is
##               sold at the sell price; without it the overflow is lost. Old
##               stock above a lowered cap is never sold this way.
##   reserves    the player can hold stock back (e.g. for the rocket); no sale —
##               manual or automatic — dips into it.
##   orders      per product: sell what's above the reserve once the stock reaches
##               sell_start; buy up to buy_target while credits stay above
##               credit_reserve. At most max_per_cycle per 20 s cycle; sales run
##               before purchases (§18.19).
## Buying Moonstone never counts as Moonstone mined on the Moon (§18.22).
class_name Trade
extends RefCounted

## Reference credits per unit (§18.3).
const REFERENCE := {
	"ferrite": 2.0,
	"moonstone": 3.5,
	"science": 5.0,
	"goods": 22.0,
	"fuel": 34.0,
	"rare_elements": 92.0,
}

## Most recent trades kept for the panel.
const LOG_SIZE := 30

static func reference_price(id: String) -> float:
	if REFERENCE.has(id):
		return float(REFERENCE[id])
	var r := Economy.raw_info(id)
	if not r.is_empty():
		return 2.0 * Economy.yield_mult(int(r["rarity"]))
	return 0.0

static func sell_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_sell_ratio

static func buy_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_buy_ratio

static func has_access() -> bool:
	return SkillTree.is_unlocked("trade_access")

static func has_automation() -> bool:
	return SkillTree.is_unlocked("trade_automation")

## Products shown on the trade panel, in a fixed order (only reachable ones).
static func products() -> Array[String]:
	var out: Array[String] = [Economy.SCIENCE, Economy.GOODS, Economy.FUEL, Economy.RARE]
	for r: Dictionary in Economy.RAW_TABLE:
		out.append(String(r["id"]))
	var shown: Array[String] = []
	for id: String in out:
		if _known(id):
			shown.append(id)
	return shown

## A product the player knows about (its name may show).
static func _known(id: String) -> bool:
	if Economy.is_raw(id):
		return Economy.is_mineral_discovered(id)
	return true

## Why this product can't be traded ("" when it can). Never names an undiscovered mineral.
static func product_block(id: String) -> String:
	if not has_access():
		return "Research Trade Access"
	if reference_price(id) <= 0.0:
		return "Not tradeable"
	if Economy.is_raw(id):
		return "" if Economy.is_mineral_discovered(id) else "Not discovered yet"
	match id:
		Economy.FUEL:
			return "" if SkillTree.is_unlocked("fuel_processing") else "Research Fuel Processing"
		Economy.RARE:
			return "" if SkillTree.is_unlocked("rare_processing") else "Research Rare Processing"
	return ""

static func can_trade(id: String) -> bool:
	return product_block(id) == ""

# ── Stock ────────────────────────────────────────────────────────────────────

static func stock(id: String) -> float:
	return Economy.payable_amount(id)

## Player reserve of a product.
static func reserve(id: String) -> float:
	return float(GameState.trade_reserves.get(id, 0.0))

static func set_reserve(id: String, amount: float) -> void:
	if amount <= 0.0:
		GameState.trade_reserves.erase(id)
	else:
		GameState.trade_reserves[id] = amount
	GameState.trade_changed.emit()

## What may be sold: stock − player reserve (and the order's reserve when given).
static func sellable(id: String, extra_reserve: float = 0.0) -> float:
	return maxf(stock(id) - maxf(reserve(id), extra_reserve), 0.0)

## Room left in storage (INF for Credits / Science).
static func room(id: String) -> float:
	if not Economy.is_capped(id):
		return INF
	return maxf(Economy.cap(id) - stock(id), 0.0)

## Largest purchase possible now (credits, storage, optional credit floor).
static func max_buy(id: String, credit_floor: float = 0.0) -> float:
	var p := buy_price(id)
	if p <= 0.0:
		return 0.0
	var by_money := maxf(GameState.credits - credit_floor, 0.0) / p
	return maxf(floorf(minf(by_money, room(id)) * 100.0) / 100.0, 0.0)

# ── Transactions ─────────────────────────────────────────────────────────────

## Sells up to `qty` (less if the sellable stock is short). Returns the amount sold.
static func sell(id: String, qty: float, source: String = "manual", extra_reserve: float = 0.0) -> float:
	if not can_trade(id) or qty <= 0.0:
		return 0.0
	var n := minf(qty, sellable(id, extra_reserve))
	if n <= 0.0:
		return 0.0
	var credits := n * sell_price(id)
	_take(id, n)
	GameState.earn_credits(credits)
	_log("sell", id, n, credits, source)
	return n

## Buys up to `qty` (less if credits or storage are short). Returns the amount bought.
static func buy(id: String, qty: float, source: String = "manual", credit_floor: float = 0.0) -> float:
	if not can_trade(id) or qty <= 0.0:
		return 0.0
	var n := minf(qty, max_buy(id, credit_floor))
	if n <= 0.0:
		return 0.0
	var credits := n * buy_price(id)
	if not GameState.spend_credits(credits):
		return 0.0
	Economy.add(id, n)
	_log("buy", id, n, -credits, source)
	return n

static func _take(id: String, n: float) -> void:
	match id:
		Economy.SCIENCE: GameState.spend_science(n)
		_:               GameState.consume_resource(id, n)

## New production that didn't fit in storage (GameState.add_resource). Sold at
## the sell price once Trade Access is researched; otherwise it's lost.
static func sell_overflow(id: String, overflow: float) -> void:
	if overflow <= 0.0 or not can_trade(id):
		return
	var credits := overflow * sell_price(id)
	GameState.overflow_sold[id] = float(GameState.overflow_sold.get(id, 0.0)) + overflow
	GameState.earn_credits(credits)

static func _log(kind: String, id: String, qty: float, credits: float, source: String) -> void:
	GameState.trade_seq += 1
	GameState.trade_log.push_front({"seq": GameState.trade_seq, "kind": kind, "id": id, "qty": qty,
		"credits": credits, "source": source, "time": Time.get_unix_time_from_system()})
	while GameState.trade_log.size() > LOG_SIZE:
		GameState.trade_log.pop_back()
	GameState.trade_changed.emit()

# ── Automation (Trade Automation) ────────────────────────────────────────────

## An order with every field filled in.
static func order(id: String) -> Dictionary:
	var o: Dictionary = GameState.trade_orders.get(id, {})
	return {
		"enabled": bool(o.get("enabled", false)),
		"buy_target": float(o.get("buy_target", 0.0)),
		"sell_start": float(o.get("sell_start", 0.0)),
		"reserve_min": float(o.get("reserve_min", 0.0)),
		"credit_reserve": float(o.get("credit_reserve", 0.0)),
		"max_per_cycle": float(o.get("max_per_cycle", 0.0)),   # 0 = no limit
	}

## Why an order can't be saved this way ("" when it can) (§18.16).
static func order_block(id: String, o: Dictionary) -> String:
	if not has_automation():
		return "Research Trade Automation"
	if not can_trade(id):
		return product_block(id)
	var sell_start := float(o.get("sell_start", 0.0))
	var buy_target := float(o.get("buy_target", 0.0))
	if sell_start > 0.0 and buy_target > sell_start:
		return "Buy target can't be above the sell start"
	if buy_target > Economy.cap(id):
		return "Buy target is above the storage limit"
	return ""

static func set_order(id: String, o: Dictionary) -> String:
	var why := order_block(id, o)
	if why != "":
		return why
	GameState.trade_orders[id] = order(id).merged(o, true)
	GameState.trade_changed.emit()
	return ""

## One automation pass (every 20 s cycle): every sale first, then every purchase.
static func run_orders() -> void:
	if not has_automation() or GameState.trade_orders.is_empty():
		return
	var ids: Array = GameState.trade_orders.keys()
	ids.sort()
	for id: String in ids:
		var o := order(id)
		if not o["enabled"] or not can_trade(id):
			continue
		var start: float = o["sell_start"]
		if start > 0.0 and stock(id) >= start:
			var n := sellable(id, o["reserve_min"])
			if float(o["max_per_cycle"]) > 0.0:
				n = minf(n, o["max_per_cycle"])
			sell(id, n, "auto", o["reserve_min"])
	for id: String in ids:
		var o := order(id)
		if not o["enabled"] or not can_trade(id):
			continue
		var target: float = o["buy_target"]
		if target > 0.0 and stock(id) < target:
			var n := target - stock(id)
			if float(o["max_per_cycle"]) > 0.0:
				n = minf(n, o["max_per_cycle"])
			buy(id, n, "auto", o["credit_reserve"])

## Short sentence that says what an order really does (§18.17).
static func order_text(id: String) -> String:
	var o := order(id)
	if not o["enabled"]:
		return "Off"
	var name := Economy.display_name(id)
	var parts: Array[String] = []
	if float(o["sell_start"]) > 0.0:
		parts.append("sells %s above %s once the stock reaches %s" % [name,
			Economy.fmt(maxf(o["reserve_min"], reserve(id))), Economy.fmt(o["sell_start"])])
	if float(o["buy_target"]) > 0.0:
		parts.append("buys %s up to %s while Credits stay above %s" % [name,
			Economy.fmt(o["buy_target"]), Economy.fmt(o["credit_reserve"])])
	if parts.is_empty():
		return "Does nothing — set a sell start or a buy target"
	return "Every 20 s: " + "; ".join(parts) + "."
