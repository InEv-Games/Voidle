## A clipping strip that never asks for width (playtest 30.10: the left panel
## must not grow with its contents). Its one child — a Label, a row of stat
## chips … — keeps its natural width; when that is wider than the strip, it
## glides back and forth (pausing at each end) so all of it can be read.
##   MarqueeLabel.create("long text", colour)   # a Label inside
##   MarqueeLabel.wrap(existing_control)          # put any control inside
class_name MarqueeLabel
extends Control

## Glide speed, px per second, and the pause at each end.
const SPEED := 24.0
const PAUSE := 1.4

## Where the content sits while it fits: 0 left, 1 right.
var align := 0.0
var _t := 0.0
var _dir := 1.0
var _wait := PAUSE

static func create(txt: String, col: Color = Color(0, 0, 0, 0), variation: StringName = &"CounterLabel") -> MarqueeLabel:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = variation
	if col.a > 0.0:
		l.add_theme_color_override("font_color", col)
	var m := MarqueeLabel.new()
	m.align = 1.0
	m._adopt(l)
	return m

## Moves `c` into a new marquee that takes its place (same parent, index and
## size flags) and returns the marquee.
static func wrap(c: Control) -> MarqueeLabel:
	var m := MarqueeLabel.new()
	m.size_flags_horizontal = c.size_flags_horizontal | Control.SIZE_EXPAND
	m.size_flags_vertical = c.size_flags_vertical
	var parent := c.get_parent()
	if parent != null:
		var at := c.get_index()
		parent.remove_child(c)
		parent.add_child(m)
		parent.move_child(m, at)
	m._adopt(c)
	return m

## The label inside (create()), or null.
func label() -> Label:
	return get_child(0) as Label if get_child_count() > 0 else null

func set_text(txt: String) -> void:
	var l := label()
	if l != null:
		l.text = txt

func _adopt(c: Control) -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(c)
	c.minimum_size_changed.connect(update_minimum_size)
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	var c := get_child(0) as Control if get_child_count() > 0 else null
	return Vector2(0.0, c.get_combined_minimum_size().y if c != null else 0.0)

func _process(delta: float) -> void:
	var c := get_child(0) as Control if get_child_count() > 0 else null
	if c == null:
		return
	var want := c.get_combined_minimum_size()
	c.size = Vector2(want.x, size.y)
	var over := want.x - size.x
	if over <= 0.5:
		c.position = Vector2((size.x - want.x) * align, 0.0)
		_t = 0.0
		_wait = PAUSE
		return
	if _wait > 0.0:
		_wait -= delta
	else:
		_t += _dir * SPEED * delta / over
		if _t >= 1.0 or _t <= 0.0:
			_t = clampf(_t, 0.0, 1.0)
			_dir = -_dir
			_wait = PAUSE
	c.position = Vector2(-over * _t, 0.0)
