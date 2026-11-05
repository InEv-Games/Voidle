## A quick entrance for a block of UI (tooltips): the left panel's opening
## (LeftPanel, "Open / close") in short. Each row (a line of the block — found
## by opening the plain VBox / Scroll / Margin containers it is stacked in)
## comes in at its own random moment within STAGGER, over DUR, blinking like
## a weak tape signal; inside a row its items come left to right, labels
## scrambling into their text and rich text typing in.
##   RowReveal.play(root)   # restarts if one is already running on root
## A script that changes a label's text or an item's modulate meanwhile wins:
## that one stops animating and is left as the script set it.
class_name RowReveal
extends Node

const DUR := 0.12             # one row, start to settled
const STAGGER := 0.1          # the last row starts no later than this
const ITEM_FADE := 0.5        # share of a row's time each item takes
const SCRAMBLE_SHARE := 0.6   # share of a label's chars that start wrong
const GLYPH_SEC := 0.04
const BLINK_SEC := 0.03
const BLINK_CHANCE := 0.3
const BLINK_DIP := Vector2(0.2, 0.6)

var _root: Control
var _t := 0.0
var _rows: Array = []   # {node, orig, last, start, seed, items, labels, texts}
var _rng := RandomNumberGenerator.new()

static func play(root: Control) -> void:
	if root == null or not root.is_inside_tree():
		return
	for c in root.get_children(true):
		if c is RowReveal:
			(c as RowReveal)._finish()
	var r := RowReveal.new()
	r._root = root
	root.add_child(r, false, Node.INTERNAL_MODE_BACK)   # unseen by get_children()

func _ready() -> void:
	_rng.randomize()
	_collect_rows(_root)
	_process(0.0)   # hidden before the first frame draws

func _collect_rows(n: Node) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).visible:
			continue
		var ctl := c as Control
		if (ctl is VBoxContainer or ctl is ScrollContainer or ctl is MarginContainer) \
				and not CyberReveal._is_block(ctl):
			_collect_rows(ctl)   # a stack of rows, not a row
			continue
		var row := {"node": ctl, "orig": ctl.modulate, "last": ctl.modulate,
			"start": _rng.randf_range(0.0, STAGGER), "seed": _rng.randi(),
			"items": [], "labels": [], "texts": []}
		var leaves: Array[Control] = []
		_leaves(ctl, leaves)
		if leaves.is_empty():
			leaves.append(ctl)   # a single label / text: the row is its own item
		var k := leaves.size()
		for i in k:
			var it := leaves[i]
			var o := (float(i) / float(k - 1)) * (1.0 - ITEM_FADE) if k > 1 else 0.0
			(row["items"] as Array).append({"node": it, "orig": it.modulate, "last": it.modulate, "o": o})
			if it is Label and (it as Label).text.strip_edges() != "":
				var text := (it as Label).text
				var h := PackedFloat32Array()
				for j in text.length():
					h.append(_rng.randf_range(0.2, 1.0) if _rng.randf() < SCRAMBLE_SHARE else -1.0)
				(row["labels"] as Array).append({"node": it, "text": text, "last": text, "h": h, "o": o})
			elif it is RichTextLabel:
				(row["texts"] as Array).append({"node": it, "last": (it as RichTextLabel).visible_ratio, "o": o})
		_rows.append(row)

## A row's items in reading order (tree order); a row with none is its own item.
func _leaves(n: Control, out: Array[Control]) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).visible:
			continue
		var ctl := c as Control
		var has_kids := ctl.get_children().any(func(k: Node) -> bool: return k is Control)
		if ctl is Label or ctl is RichTextLabel or ctl is TextureRect or ctl is BaseButton \
				or ctl is Separator or not has_kids:
			out.append(ctl)
		else:
			_leaves(ctl, out)

func _process(delta: float) -> void:
	_t += delta
	if not is_instance_valid(_root):
		_finish()
		return
	var busy := false
	var bb := int(_t / BLINK_SEC)
	var gb := int(_t / GLYPH_SEC)
	for r: Dictionary in _rows:
		var p := clampf((_t - float(r["start"])) / DUR, 0.0, 1.0)
		if p < 1.0:
			busy = true
		_set_row(r, p, bb, gb)
	if not busy:
		_finish()

func _blink(bucket: int, seed: int) -> float:
	var x := float(hash(Vector2i(bucket, seed)) & 0xffff) / 65535.0
	return lerpf(BLINK_DIP.x, BLINK_DIP.y, x / BLINK_CHANCE) if x < BLINK_CHANCE else 1.0

func _set_row(r: Dictionary, p: float, bb: int, gb: int) -> void:
	var node = r["node"]
	if is_instance_valid(node) and (node as Control).modulate == r["last"]:
		var o: Color = r["orig"]
		var a := p * (_blink(bb, r["seed"]) if p > 0.0 and p < 1.0 else 1.0)
		var m := Color(o.r, o.g, o.b, o.a * a)
		(node as Control).modulate = m
		r["last"] = m
	for it: Dictionary in r["items"]:
		var n = it["node"]
		if not is_instance_valid(n) or (n as Control).modulate != it["last"] or n == node:
			continue
		var io: Color = it["orig"]
		var ip := smoothstep(float(it["o"]), float(it["o"]) + ITEM_FADE, p)
		var im := Color(io.r, io.g, io.b, io.a * ip)
		(n as Control).modulate = im
		it["last"] = im
	for l: Dictionary in r["labels"]:
		var lab = l["node"]
		if not is_instance_valid(lab) or (lab as Label).text != l["last"]:
			continue   # freed, or the game wrote new text into it
		var lp := smoothstep(float(l["o"]), float(l["o"]) + ITEM_FADE, p)
		var text: String = l["text"]
		var h: PackedFloat32Array = l["h"]
		var out := ""
		for i in text.length():
			var ch := text[i]
			if ch.strip_edges() == "" or lp >= h[i]:
				out += ch
				continue
			var g := CyberReveal.GLYPHS[absi(hash(Vector3i(i, gb, (lab as Object).get_instance_id() & 0xffff))) % CyberReveal.GLYPHS.length()]
			out += g.to_lower() if ch != ch.to_upper() else g
		(lab as Label).text = out
		l["last"] = out
	for tx: Dictionary in r["texts"]:
		var rt = tx["node"]
		if not is_instance_valid(rt) or not is_equal_approx((rt as RichTextLabel).visible_ratio, float(tx["last"])):
			continue
		var tp := smoothstep(float(tx["o"]), float(tx["o"]) + ITEM_FADE, p)
		(rt as RichTextLabel).visible_ratio = tp
		tx["last"] = tp

## Puts back whatever is still mid-effect and leaves.
func _finish() -> void:
	_restore()
	if is_inside_tree():
		get_parent().remove_child(self)
	queue_free()

func _restore() -> void:
	set_process(false)
	for r: Dictionary in _rows:
		_set_row(r, 1.0, 0, 0)
	_rows.clear()

func _exit_tree() -> void:
	_restore()
