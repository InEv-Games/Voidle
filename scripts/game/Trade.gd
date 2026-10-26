## Trade (docs/design/VOIDLE_GDD.md §18, KARARLAR §10): prices move with trade.
##
##   access      Trade Access research opens manual buying and selling of every
##               product the player can reach, Science included; automation needs
##               Trade Automation. A raw resource must have been discovered first
##               (its name and price never show before); Fuel needs Fuel
##               Processing, Rare needs Rare Processing. Trade never opens access.
##   prices      sell = reference × trade_sell_ratio (90%) × m, buy = reference ×
##               trade_buy_ratio (110%) × m, where m = 1 + the product's price
##               pressure (clamped to trade_price_min…max). Buying raises the
##               pressure, selling lowers it: trade_depth_credits worth of trade
##               moves m by 1. A trade pays the exact area under that slope, so
##               splitting it into small trades gains nothing. Pressure fades to 0
##               with a half-life of trade_recovery_half_life seconds. A future
##               raw's reference is 2 × its rarity yield.
##   overflow    with Trade Automation, new production that doesn't fit in storage
##               is sold (it lowers the price like any sale); without it the
##               overflow is lost. Old stock above a lowered cap is never sold.
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

## Current sell / buy price of one unit (the next one).
static func sell_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_sell_ratio * price_mult(id)

static func buy_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_buy_ratio * price_mult(id)

# ── Dynamic prices ───────────────────────────────────────────────────────────

static func pressure(id: String) -> float:
	return float(GameState.trade_pressure.get(id, 0.0))

## Price multiplier now (1 = reference).
static func price_mult(id: String) -> float:
	return clampf(1.0 + pressure(id), Balance.cfg.trade_price_min, Balance.cfg.trade_price_max)

## Units of a product that move its price by 100%.
static func depth(id: String) -> float:
	var r := reference_price(id)
	return Balance.cfg.trade_depth_credits / r if r > 0.0 else INF

## ∫ clamp(1 + p) dp from a to b (a ≤ b): the multiplier's area over a pressure span.
static func _area(a: float, b: float) -> float:
	var c: BalanceConfig = Balance.cfg
	var lo := c.trade_price_min - 1.0
	var hi := c.trade_price_max - 1.0
	var total := 0.0
	var x := a
	if x < lo:
		var x1 := minf(b, lo)
		total += (x1 - x) * c.trade_price_min
		x = x1
	if x < b and x < hi:
		var x2 := minf(b, hi)
		total += (x2 - x) * (1.0 + (x + x2) * 0.5)
		x = x2
	if x < b:
		total += (b - x) * c.trade_price_max
	return total

## Credits buying `n` units costs now (the price rises along the way).
static func buy_cost(id: String, n: float) -> float:
	var d := depth(id)
	var p0 := pressure(id)
	return reference_price(id) * Balance.cfg.trade_buy_ratio * d * _area(p0, p0 + n / d)

## Credits selling `n` units brings now (the price falls along the way).
static func sell_value(id: String, n: float) -> float:
	var d := depth(id)
	var p0 := pressure(id)
	return reference_price(id) * Balance.cfg.trade_sell_ratio * d * _area(p0 - n / d, p0)

static func _push(id: String, units: float) -> void:
	var c: BalanceConfig = Balance.cfg
	GameState.trade_pressure[id] = clampf(pressure(id) + units / depth(id),
		c.trade_price_min - 1.0, c.trade_price_max - 1.0)

## Every frame (ProductionManager): pressure fades back toward the reference.
static func tick_prices(delta: float) -> void:
	if GameState.trade_pressure.is_empty():
		return
	var k := pow(0.5, delta / maxf(Balance.cfg.trade_recovery_half_life, 1.0))
	for id: String in GameState.trade_pressure.keys():
		var v := float(GameState.trade_pressure[id]) * k
		if absf(v) < 0.001:
			GameState.trade_pressure.erase(id)
		else:
			GameState.trade_pressure[id] = v

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

## Largest purchase possible now (credits, storage, optional credit floor);
## the price climbs as it buys, so it searches for the largest affordable amount.
static func max_buy(id: String, credit_floor: float = 0.0) -> float:
	var p := buy_price(id)
	if p <= 0.0:
		return 0.0
	var money := maxf(GameState.credits - credit_floor, 0.0)
	var hi_n := minf(money / (reference_price(id) * Balance.cfg.trade_buy_ratio * Balance.cfg.trade_price_min), room(id))
	if hi_n <= 0.0:
		return 0.0
	var lo_n := 0.0
	for _i in 40:
		var mid := (lo_n + hi_n) * 0.5
		if buy_cost(id, mid) <= money:
			lo_n = mid
		else:
			hi_n = mid
	return maxf(floorf(lo_n * 100.0) / 100.0, 0.0)

# ── Transactions ─────────────────────────────────────────────────────────────

## Sells up to `qty` (less if the sellable stock is short). Returns the amount sold.
static func sell(id: String, qty: float, source: String = "manual", extra_reserve: float = 0.0) -> float:
	if not can_trade(id) or qty <= 0.0:
		return 0.0
	var n := minf(qty, sellable(id, extra_reserve))
	if n <= 0.0:
		return 0.0
	var credits := sell_value(id, n)
	_take(id, n)
	_push(id, -n)
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
	var credits := buy_cost(id, n)
	if not GameState.spend_credits(credits):
		return 0.0
	_push(id, n)
	Economy.add(id, n)
	_log("buy", id, n, -credits, source)
	return n

static func _take(id: String, n: float) -> void:
	match id:
		Economy.SCIENCE: GameState.spend_science(n)
		_:               GameState.consume_resource(id, n)

## New production that didn't fit in storage (GameState.add_resource). Sold
## once Trade Automation is researched (playtest 23.10: it should be earned);
## otherwise it's lost. It lowers the price like any sale.
static func sell_overflow(id: String, overflow: float) -> void:
	if overflow <= 0.0 or not can_trade(id) or not has_automation():
		return
	var credits := sell_value(id, overflow)
	_push(id, -overflow)
	GameState.overflow_sold[id] = float(GameState.overflow_sold.get(id, 0.0)) + credits   # credits earned
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
