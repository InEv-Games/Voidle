## Cyberpunk entrance for a freshly opened panel menu: its blocks (hero, cards,
## buttons, tags…) blink in top to bottom with a cyan flash while their text
## decodes — random glyphs settling into the real characters, a few flicking
## wrong once more on the way.
##   CyberReveal.play(root)   # restarts if one is already running on root
## A script that changes a label's text or a block's modulate meanwhile wins:
## that one stops animating and is left as the script set it.
class_name CyberReveal
extends Node

const GLYPHS := "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#$%&*+=<>/\\[]{}?!_-"
const STEP_SEC := 0.045       # delay between one block and the next
const STAGGER_SEC := 0.5      # the last block starts no later than this
const BLINK_SEC := 0.32
const DECODE_SEC := 0.5       # per label: first wrong → all settled
const SCRAMBLE_SHARE := 0.3   # share of a label's chars that start wrong; the rest show right away
const GLYPH_SEC := 0.09       # how often an unsettled glyph changes
const GLITCH_CHANCE := 0.03   # a settled char flicking wrong again (fades out)
const FLASH := Color(0.9, 1.08, 1.12)   # faint cyan on the first blink frames
## Alpha per blink step (BLINK_SEC split evenly): a short flicker, never fully off.
const BLINK := [0.4, 0.1, 0.75, 0.3, 0.9, 0.55, 1.0]   # slow, analog: a weak tape signal

var _root: Control
var _t := 0.0
var _blocks: Array = []   # {node, orig, last, start, done}
var _labels: Array = []   # {node, text, last, start, settle, done}
var _rng := RandomNumberGenerator.new()

static func play(root: Control) -> void:
	if root == null or not root.is_inside_tree():
		return
	for c in root.get_children(true):
		if c is CyberReveal:
			(c as CyberReveal)._finish()
	var r := CyberReveal.new()
	r._root = root
	root.add_child(r, false, Node.INTERNAL_MODE_BACK)   # unseen by get_children()

## Outermost of these animates as one unit.
static func _is_block(c: Control) -> bool:
	return c is HeroHeader or c is HeroTag or c is ListItem or c is Button \
		or c is SectionHeader or c is InfoRow or c is PanelContainer \
		or c is Label or c is TextureRect or c is Separator

func _ready() -> void:
	_rng.randomize()
	_collect(_root, -1.0)
	_process(0.0)   # hidden before the first frame draws

func _collect(n: Node, block_start: float) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).is_visible_in_tree():
			continue
		var ctl := c as Control
		var start := block_start
		if start < 0.0 and _is_block(ctl):
			start = minf(_blocks.size() * STEP_SEC, STAGGER_SEC)
			_blocks.append({"node": ctl, "orig": ctl.modulate, "last": ctl.modulate,
				"start": start, "done": false})
		if ctl is Label and (ctl as Label).text.strip_edges() != "":
			var text := (ctl as Label).text
			# where each char settles (0..1 of DECODE_SEC): left to right, jittered;
			# only SCRAMBLE_SHARE of them start wrong (-1: right from the start)
			var settle := PackedFloat32Array()
			for i in text.length():
				var at := clampf(float(i) / text.length() * 0.7 + _rng.randf() * 0.3, 0.0, 1.0)
				settle.append(at if _rng.randf() < SCRAMBLE_SHARE else -1.0)
			_labels.append({"node": ctl, "text": text, "last": text,
				"start": maxf(start, 0.0), "settle": settle, "done": false})
		_collect(ctl, start)

func _process(delta: float) -> void:
	_t += delta
	var busy := false
	for b: Dictionary in _blocks:
		if not b["done"]:
			busy = _step_block(b) or busy
	for l: Dictionary in _labels:
		if not l["done"]:
			busy = _step_label(l) or busy
	if not busy:
		_finish()

func _step_block(b: Dictionary) -> bool:
	if not is_instance_valid(b["node"]):   # check before casting: freed by a rebuild
		b["done"] = true
		return false
	var node := b["node"] as Control
	if node.modulate != b["last"]:
		b["done"] = true   # someone else drives its modulate now
		return false
	var k := (_t - float(b["start"])) / BLINK_SEC
	if k >= 1.0:
		node.modulate = b["orig"]
		b["done"] = true
		return false
	var a := 0.0
	var tint := FLASH
	if k >= 0.0:
		a = BLINK[mini(int(k * BLINK.size()), BLINK.size() - 1)]
		tint = FLASH.lerp(Color.WHITE, k)
	var m: Color = (b["orig"] as Color) * Color(tint.r, tint.g, tint.b, a)
	node.modulate = m
	b["last"] = m
	return true

func _step_label(l: Dictionary) -> bool:
	if not is_instance_valid(l["node"]):   # check before casting: freed by a rebuild
		l["done"] = true
		return false
	var node := l["node"] as Label
	if node.text != l["last"]:
		l["done"] = true   # the game wrote new text into it
		return false
	var text: String = l["text"]
	var p := (_t - float(l["start"])) / DECODE_SEC
	if p >= 1.0:
		node.text = text
		l["done"] = true
		return false
	var settle: PackedFloat32Array = l["settle"]
	var bucket := int(_t / GLYPH_SEC)
	var out := ""
	for i in text.length():
		var ch := text[i]
		var wrong := p < settle[i] or _rng.randf() < GLITCH_CHANCE * (1.0 - p)
		if ch.strip_edges() == "" or not wrong:
			out += ch
			continue
		# same glyph for a few frames, so it reads as flicker, not noise
		var g := GLYPHS[absi(hash(Vector3i(i, bucket, node.get_instance_id() & 0xffff))) % GLYPHS.length()]
		out += g.to_lower() if ch != ch.to_upper() else g
	node.text = out
	l["last"] = out
	return true

## Puts back whatever is still mid-effect and leaves.
func _finish() -> void:
	_restore()
	if is_inside_tree():
		get_parent().remove_child(self)
	queue_free()

func _restore() -> void:
	set_process(false)
	for l: Dictionary in _labels:
		var node = l["node"]
		if not l["done"] and is_instance_valid(node) and (node as Label).text == l["last"]:
			(node as Label).text = l["text"]
	for b: Dictionary in _blocks:
		var node = b["node"]
		if not b["done"] and is_instance_valid(node) and (node as Control).modulate == b["last"]:
			(node as Control).modulate = b["orig"]
	_labels.clear()
	_blocks.clear()

func _exit_tree() -> void:
	_restore()   # the panel went away mid-effect
