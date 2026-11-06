## The objectives card: a small card at the bottom-right, above the news bar,
## opened / closed by the flag button in that bar (NewsFeed.toggle_objectives,
## or O). Its owner fills `content` (the objective's name as a small hero, then
## its details) and sets `active` while it has something to show.
class_name ObjectivesCard
extends PanelContainer

const WIDTH := 300.0
## An objective's name as a hero: smaller than a world's name.
const HERO_SIZE := 22
const MARGIN_RIGHT := 12.0
const GAP_ABOVE_NEWS := 8.0
const FADE_SEC := 0.15

var content: VBoxContainer = null
## The owner has an objective to show (the card still waits for the button).
var active := true:
	set(v):
		if active == v:
			return
		active = v
		_sync(false)
## The objective's name for the button's tooltip.
var tip_title := ""

func _init() -> void:
	theme_type_variation = &"PopupCard"
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

func _ready() -> void:
	NewsFeed.objectives_changed.connect(func(_open: bool) -> void: _sync(true))
	_sync(false)
	_place()

func _exit_tree() -> void:
	NewsFeed.set_objectives_source(get_instance_id(), false)

func _process(_delta: float) -> void:
	NewsFeed.set_objectives_source(get_instance_id(), active, tip_title)
	_place()

func _shown() -> bool:
	return active and NewsFeed.objectives_open

## Opening plays the side panels' cyber entrance; closing fades out quickly.
func _sync(animate: bool) -> void:
	if not is_inside_tree():
		return
	var want := _shown()
	if want == visible and modulate.a > 0.99:
		return
	if want:
		visible = true
		modulate.a = 1.0
		if animate:
			reveal()
	elif animate and visible:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, FADE_SEC)
		tw.tween_callback(func() -> void:
			if not _shown():
				visible = false
			modulate.a = 1.0)
	else:
		visible = false

## Plays the entrance again, e.g. when the objective changes.
func reveal() -> void:
	if visible:
		CyberReveal.play(self)

## Bottom-right corner, just above the news bar (or the screen's bottom).
func _place() -> void:
	var vp := get_viewport_rect().size
	var bottom := vp.y
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y
	reset_size()
	global_position = Vector2(vp.x - size.x - MARGIN_RIGHT, bottom - size.y - GAP_ABOVE_NEWS)
