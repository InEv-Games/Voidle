## Trade (docs/design/VOIDLE_GDD.md §18, KARARLAR §10): prices move with trade.
##
##   access      Trade Access research opens manual buying and selling of every
##               product the player can reach, Science included; automation needs
##               Trade Automation. A raw resource must have been discovered first
##               (its name and price never show before); Fuel needs Fuel
##               Processing, Rare needs Rare Processing. Trade never opens access.
##   prices      one market price, reference × m (unit_price; sell / buy ratios
##               are 1 since 31.10, so both ways trade at it), where m = 1 + the product's price
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
##   orders      (playtest 31.10) one target and a mode per product: off, sell
##               until (sell what's above the target), buy until (buy up to it),
##               keep at (both, around it). Every 20 s cycle, sales first; an
##               automatic trade moves the price at most AUTO_MAX_MOVE per cycle
##               and gets a worse price than a manual one (trade_auto_penalty).
##               Storage overflow is only sold for products set to sell / keep.
##   history     the price multiplier of every product every HISTORY_STEP s
##               (HISTORY_SIZE samples) for the panel's chart; a big move posts news.
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
## Automation modes (order "mode").
const MODE_OFF := "off"
const MODE_SELL := "sell"
const MODE_BUY := "buy"
const MODE_KEEP := "keep"
const MODES: Array[String] = [MODE_OFF, MODE_SELL, MODE_BUY, MODE_KEEP]
## Keep at: no trade while the stock is within this share of the target.
const KEEP_BAND := 0.05
## Most an automatic order may move a price in one cycle (share of the reference).
const AUTO_MAX_MOVE := 0.05
## Price history for the chart: a sample every HISTORY_STEP s, HISTORY_SIZE kept.
const HISTORY_STEP := 5.0
const HISTORY_SIZE := 72
## News when a price is this far from its reference (and again once it's back).
const NEWS_HIGH := 1.5
const NEWS_LOW := 0.6
## …and when a price moves this much within about a minute (a big buy or sale).
const NEWS_FAST_MOVE := 0.10
## Seconds between two fast-move items of one product.
const NEWS_COOLDOWN := 90.0

static func reference_price(id: String) -> float:
	if REFERENCE.has(id):
		return float(REFERENCE[id])
	var r := Economy.raw_info(id)
	if not r.is_empty():
		return 2.0 * Economy.yield_mult(int(r["rarity"]))
	return 0.0

## The one price the player sees: what a unit trades at now, either way.
static func unit_price(id: String) -> float:
	return reference_price(id) * price_mult(id)

## Current sell / buy price of one unit (the next one).
static func sell_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_sell_ratio * price_mult(id)

static func buy_price(id: String) -> float:
	return reference_price(id) * Balance.cfg.trade_buy_ratio * price_mult(id)

# ── Dynamic prices ───────────────────────────────────────────────────────────

## The market's own drift (playtest 31.10: prices should move a little by
## themselves): per product a small wander that keeps pulling back to 0, about
## ±NOISE_SIZE. It shifts prices like pressure does, but trades never store it.
const NOISE_SIZE := 0.01   # calm: real trades must stand out (playtest 31.10)
const NOISE_PULL := 0.03   # per second, back toward 0 (slow, smooth swings)
static var _noise: Dictionary = {}

static func _tick_noise(delta: float) -> void:
	for id: String in _market_ids():
		var n := float(_noise.get(id, 0.0))
		n += (-n * NOISE_PULL) * delta + randfn(0.0, NOISE_SIZE * sqrt(2.0 * NOISE_PULL * delta))
		_noise[id] = clampf(n, -NOISE_SIZE * 3.0, NOISE_SIZE * 3.0)

## Price pressure from trades plus the market's drift.
static func pressure(id: String) -> float:
	return _stored_pressure(id) + float(_noise.get(id, 0.0))

## Pressure from trades only (what trades move and the save keeps).
static func _stored_pressure(id: String) -> float:
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
	GameState.trade_pressure[id] = clampf(_stored_pressure(id) + units / depth(id),
		c.trade_price_min - 1.0, c.trade_price_max - 1.0)

## Every frame (ProductionManager): pressure fades back toward the reference.
static func tick_prices(delta: float) -> void:
	_tick_noise(delta)
	_record_history(delta)
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
	if source == "auto":
		credits *= 1.0 - Balance.cfg.trade_auto_penalty   # automation sells for less
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
	if source == "auto":
		credits *= 1.0 + Balance.cfg.trade_auto_penalty   # automation pays more
		while n > 0.01 and credits > GameState.credits - credit_floor:
			n *= 0.9
			credits = buy_cost(id, n) * (1.0 + Balance.cfg.trade_auto_penalty)
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
	var mode := String(order(id)["mode"])
	if mode != MODE_SELL and mode != MODE_KEEP:
		return   # only what the player set to sell (playtest 30.10); the rest is lost
	var credits := sell_value(id, overflow) * (1.0 - Balance.cfg.trade_auto_penalty)
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

## A product's order: { mode, target }.
static func order(id: String) -> Dictionary:
	var o: Dictionary = GameState.trade_orders.get(id, {})
	var mode := String(o.get("mode", MODE_OFF))
	return {"mode": mode if mode in MODES else MODE_OFF, "target": maxf(float(o.get("target", 0.0)), 0.0)}

## Why an order can't be set ("" when it can).
static func order_block(id: String, mode: String, target: float) -> String:
	if not has_automation():
		return "Research Trade Automation"
	if not can_trade(id):
		return product_block(id)
	if mode != MODE_OFF and mode != MODE_SELL and target > Economy.cap(id):
		return "Target is above the storage limit (%s)" % Economy.fmt(Economy.cap(id))
	return ""

static func set_order(id: String, mode: String, target: float) -> String:
	var why := order_block(id, mode, target)
	if why != "":
		return why
	if mode == MODE_OFF and target <= 0.0:
		GameState.trade_orders.erase(id)
	else:
		GameState.trade_orders[id] = {"mode": mode, "target": target}
	GameState.trade_changed.emit()
	return ""

## Units an automatic order may trade this cycle (AUTO_MAX_MOVE of the price).
static func auto_cap(id: String) -> float:
	return maxf(depth(id) * AUTO_MAX_MOVE, 1.0)

## One automation pass (every 20 s cycle): every sale first, then every purchase.
static func run_orders() -> void:
	if not has_automation() or GameState.trade_orders.is_empty():
		return
	var ids: Array = GameState.trade_orders.keys()
	ids.sort()
	for id: String in ids:
		var o := order(id)
		if not can_trade(id):
			continue
		var t: float = o["target"]
		var over := stock(id) - t
		if (o["mode"] == MODE_SELL and over > 0.0) or (o["mode"] == MODE_KEEP and over > maxf(t * KEEP_BAND, 1.0)):
			sell(id, minf(over, auto_cap(id)), "auto")
	for id: String in ids:
		var o := order(id)
		if not can_trade(id):
			continue
		var t: float = o["target"]
		var short := t - stock(id)
		if (o["mode"] == MODE_BUY and short > 0.0) or (o["mode"] == MODE_KEEP and short > maxf(t * KEEP_BAND, 1.0)):
			buy(id, minf(short, auto_cap(id)), "auto")

## Short sentence that says what an order does.
static func order_text(id: String) -> String:
	var o := order(id)
	var n := Economy.fmt(float(o["target"]))
	match String(o["mode"]):
		MODE_SELL: return "Sells what's above %s (and storage overflow), at %d%% less than by hand." % [n, roundi(Balance.cfg.trade_auto_penalty * 100.0)]
		MODE_BUY:  return "Buys up to %s, paying %d%% more than by hand." % [n, roundi(Balance.cfg.trade_auto_penalty * 100.0)]
		MODE_KEEP: return "Buys and sells to keep about %s (±%d%%), %d%% worse than by hand." % [n, roundi(KEEP_BAND * 100.0), roundi(Balance.cfg.trade_auto_penalty * 100.0)]
	return "No automatic trading."

static func mode_label(mode: String) -> String:
	match mode:
		MODE_SELL: return "Sell until"
		MODE_BUY:  return "Buy until"
		MODE_KEEP: return "Keep it at"
	return "Off"

# ── Price history & news ─────────────────────────────────────────────────────

static var _hist_t := 0.0
static var _news_band: Dictionary = {}   # id -> -1 / 0 / 1
static var _news_last: Dictionary = {}   # id -> msec of its last fast-move item

## Every product the market knows (the chart records them all).
static func _market_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in REFERENCE:
		out.append(id)
	for r: Dictionary in Economy.RAW_TABLE:
		if not out.has(String(r["id"])) and Economy.is_mineral_discovered(String(r["id"])):
			out.append(String(r["id"]))
	return out

## The recorded price multipliers of a product, oldest first.
static func history(id: String) -> Array:
	return GameState.trade_history.get(id, [])

static func _record_history(delta: float) -> void:
	_hist_t += delta
	if _hist_t < HISTORY_STEP:
		return
	_hist_t = 0.0
	for id: String in _market_ids():
		var h: Array = GameState.trade_history.get(id, [])
		var m := price_mult(id)
		h.append(snappedf(m, 0.001))
		while h.size() > HISTORY_SIZE:
			h.pop_front()
		GameState.trade_history[id] = h
		_price_news(id, m)

## A news item when a price breaks far from its reference, once per swing.
static func _price_news(id: String, m: float) -> void:
	if not _known(id) or not has_access():
		return
	var band := 1 if m >= NEWS_HIGH else (-1 if m <= NEWS_LOW else 0)
	var was := int(_news_band.get(id, 0))
	_news_band[id] = band
	var pname := Economy.display_name(id)
	if band == was or band == 0:
		_fast_move_news(id, m, pname)
		return
	var name := pname
	var pct := roundi(absf(m - 1.0) * 100.0)
	if band > 0:
		NewsFeed.post("%s prices soar %d%% on the interplanetary market." % [name, pct], NewsFeed.Kind.EVENT,
			"Buying pushes prices up; they drift back over a few minutes. A good moment to sell %s, a bad one to buy." % name,
			"%s +%d%%" % [name, pct])
	else:
		NewsFeed.post("%s floods the market: price down %d%%." % [name, pct], NewsFeed.Kind.EVENT,
			"Selling pushes prices down; they recover over a few minutes. A good moment to buy %s, a bad one to sell." % name,
			"%s −%d%%" % [name, pct])

## A news item for a sharp move within about a minute (a big trade), once per
## NEWS_COOLDOWN per product.
static func _fast_move_news(id: String, m: float, pname: String) -> void:
	var h := history(id)
	var back := int(60.0 / HISTORY_STEP)
	if h.size() < 2:
		return
	var then := float(h[maxi(h.size() - 1 - back, 0)])
	var mv := m / maxf(then, 0.0001) - 1.0
	if absf(mv) < NEWS_FAST_MOVE:
		return
	var now := Time.get_ticks_msec()
	if now - int(_news_last.get(id, -1000000)) < int(NEWS_COOLDOWN * 1000.0):
		return
	_news_last[id] = now
	var pct := roundi(absf(mv) * 100.0)
	if mv > 0.0:
		NewsFeed.post("%s jumps %d%% in a minute on heavy buying." % [pname, pct], NewsFeed.Kind.EVENT,
			"A big purchase pushed the price up; it drifts back over a few minutes.", "%s +%d%%" % [pname, pct])
	else:
		NewsFeed.post("%s drops %d%% in a minute as sellers pile in." % [pname, pct], NewsFeed.Kind.EVENT,
			"A big sale pushed the price down; it recovers over a few minutes.", "%s −%d%%" % [pname, pct])

# ── Force Buy (research) ─────────────────────────────────────────────────────

static func has_force_buy() -> bool:
	return SkillTree.is_unlocked("force_buy")

## Credits a cost needs with every missing tradeable resource bought first:
## its credits + what buying the shortfall costs now (INF when something short
## can't be bought — not tradeable, no access, no room).
static func force_buy_cost(cost: Dictionary) -> float:
	var total := float(cost.get(Economy.CREDITS, 0.0))
	for id: String in cost:
		if id == Economy.CREDITS:
			continue
		var short := float(cost[id]) - Economy.payable_amount(id)
		if short <= 0.0:
			continue
		if not can_trade(id) or room(id) < short:
			return INF
		total += buy_cost(id, ceilf(short))
	return total

## Buys every missing resource of `cost` (as if traded by hand) when the
## credits cover it all; true when the cost can be paid afterwards.
static func force_buy(cost: Dictionary) -> bool:
	if not has_force_buy() or force_buy_cost(cost) > GameState.credits:
		return false
	for id: String in cost:
		if id == Economy.CREDITS:
			continue
		var short := float(cost[id]) - Economy.payable_amount(id)
		if short > 0.0 and buy(id, ceilf(short), "force") + 0.0001 < ceilf(short):
			return false
	return Economy.can_pay(cost)
