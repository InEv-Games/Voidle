## SkillTreeView — Graph representation of the Skill/Upgrade Tree.
## Renders nodes, draws connections procedurally, and allows credits purchase.
class_name SkillTreeView
extends Control

signal tree_opened
signal tree_closed

static var is_open: bool = false
static var _saved_position: Vector2 = Vector2.ZERO
static var _saved_zoom:     float   = 1.0
## Which civilization's tree is shown (fractal: each tree's centre opens the one before).
static var _view_civ: int = -1

var _font: Font
var _nodes_container: Control
var _connections_draw: Control
var _close_btn: Button

# Keep track of active nodes for drawing connections
var _ui_nodes: Dictionary = {} # id -> PanelContainer

# Drag state variables
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _center_ctrl: Control
var _bg: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	SkillTreeView.is_open = true
	tree_opened.emit()
	
	# Put it on top of other HUD layers
	z_as_relative = false
	z_index = 200

	# Dark fully opaque fullscreen background with blueprint dots
	_bg = ColorRect.new()
	_bg.color = Color(0.04, 0.05, 0.09, 1.0) # Tam opak (arkayı göstermez)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Blueprint Grid Effect (moves with the camera and scales with zoom)
	_bg.draw.connect(func() -> void:
		var dot_color := Color(0.2, 0.25, 0.35, 0.5)
		var grid_size: int = maxi(10, int(40.0 * self._zoom))
		var dot_size: float = maxf(1.0, 2.0 * self._zoom)
		
		var w := int(_bg.size.x)
		var h := int(_bg.size.y)
		
		var offset_x = int(self._center_ctrl.position.x) % grid_size
		var offset_y = int(self._center_ctrl.position.y) % grid_size
		if offset_x < 0: offset_x += grid_size
		if offset_y < 0: offset_y += grid_size
		
		for x in range(offset_x - grid_size, w + grid_size, grid_size):
			for y in range(offset_y - grid_size, h + grid_size, grid_size):
				_bg.draw_rect(Rect2(x, y, dot_size, dot_size), dot_color)
	)
	
	# Background captures click so we can drag the whole canvas by clicking on empty space
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_font = load("res://Fonts/Orbitron-VariableFont_wght.ttf")

	# Graph container centered in screen
	_center_ctrl = Control.new()
	_center_ctrl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_center_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center_ctrl)

	# Drawing layer for connecting lines (underneath nodes)
	_connections_draw = Control.new()
	_connections_draw.custom_minimum_size = Vector2(20000, 20000)
	_connections_draw.position = Vector2(-10000, -10000)
	_connections_draw.draw.connect(_draw_connections)
	_connections_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_ctrl.add_child(_connections_draw)

	# Node buttons container
	_nodes_container = Control.new()
	_nodes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_ctrl.add_child(_nodes_container)

	# Restore last pan/zoom position from this session
	if _saved_position != Vector2.ZERO or _saved_zoom != 1.0:
		_center_ctrl.position = _saved_position
		_zoom = _saved_zoom
		_center_ctrl.scale = Vector2(_zoom, _zoom)

	# Build all nodes and position them
	if SkillTreeView._view_civ < 0:
		SkillTreeView._view_civ = GameState.civilization_type
	_build_tree_graph()

	# Title at the top center
	var title := Label.new()
	_title = title
	title.text = _title_text()
	if _font: title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 24.0
	add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "Spend Science to research new technology · double-click a centre node to move between civilizations"
	if _font: sub.add_theme_font_override("font", _font)
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.4, 0.48, 0.65))
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sub.offset_top = 48.0
	add_child(sub)

	# Close button at the bottom center
	_close_btn = Button.new()
	_close_btn.text = "CLOSE"
	if _font: _close_btn.add_theme_font_override("font", _font)
	_close_btn.add_theme_font_size_override("font_size", 10)
	_close_btn.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	_close_btn.custom_minimum_size = Vector2(100, 30)
	_close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_close_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_close_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_close_btn.offset_bottom = -20.0
	
	var btn_s := StyleBoxFlat.new()
	btn_s.bg_color = Color(0.12, 0.16, 0.28, 0.9)
	btn_s.border_color = Color(0.28, 0.42, 0.72, 0.55)
	btn_s.set_border_width_all(1)
	btn_s.corner_radius_top_left = 4
	btn_s.corner_radius_top_right = 4
	btn_s.corner_radius_bottom_left = 4
	btn_s.corner_radius_bottom_right = 4
	_close_btn.add_theme_stylebox_override("normal", btn_s)
	
	var btn_h := btn_s.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color(0.18, 0.24, 0.42, 1.0)
	btn_h.border_color = Color(0.42, 0.62, 1.0, 0.85)
	_close_btn.add_theme_stylebox_override("hover", btn_h)
	_close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	_close_btn.pressed.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		SkillTreeView._saved_position = _center_ctrl.position
		SkillTreeView._saved_zoom     = _zoom
		SkillTreeView.is_open = false
		tree_closed.emit()
		queue_free())
	_close_btn.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER))
	_close_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL))
	add_child(_close_btn)

	# Listen to skill unlocks to redraw connections & button states
	get_node("/root/SkillTree").skill_unlocked.connect(_on_skill_unlocked)

var _title: Label

func _title_text() -> String:
	var t := "✦ CIVILIZATION %d RESEARCH ✦" % SkillTreeView._view_civ
	if SkillTreeView._view_civ > GameState.playable_content_type:
		t += "  (preview)"
	return t

## Shows another civilization's tree (fractal descent / ascent).
func _show_civ(civ: int) -> void:
	SkillTreeView._view_civ = clampi(civ, 0, 1)
	TooltipManager.hide_tip()
	AudioManager.play("click")
	_center_ctrl.position = get_viewport_rect().size * 0.5
	if _title != null:
		_title.text = _title_text()
	_build_tree_graph()
	_connections_draw.queue_redraw()
	_bg.queue_redraw()

## Nodes of the tree on screen. Later trees show whole (as previews).
func _in_view(st: Node, id: String) -> bool:
	var node = st.get("nodes")[id]
	if int(node.civilization) != SkillTreeView._view_civ:
		return false
	if SkillTreeView._view_civ > 0:
		return true
	return st.call("is_visible", id)

func _build_tree_graph() -> void:
	for c in _nodes_container.get_children():
		c.queue_free()
	_ui_nodes.clear()

	var st: Node = get_node("/root/SkillTree")
	for id in st.get("nodes").keys():
		var node = st.get("nodes")[id]
		
		# Kilitli ve görünmezse hiç oluşturma (açıldıkça etrafı görünür)
		if not _in_view(st, id):
			continue

		var cur_lv: int = st.call("get_skill_level", id)
		var max_lv: int = node.max_level
		var is_max_level := cur_lv >= max_lv
		var unlocked: bool = cur_lv > 0
		var purchasable: bool = st.call("can_purchase", id)

		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var shape_type: int = node.get("shape") if "shape" in node else 0
		var card_size := 48.0
		if shape_type == 2:
			card_size = 72.0
			
		card.custom_minimum_size = Vector2(card_size, card_size)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Style based on status (Cyberpunk Theme)
		var bg_color := Color(0.08, 0.09, 0.12, 0.9)
		var border_color := Color(0.5, 0.6, 0.7, 0.8) # <--- Brighter border for locked nodes
		var shadow_color := Color(0.0, 0.0, 0.0, 0.0)
		var border_width := 1.0
		
		if is_max_level:
			bg_color = Color(0.02, 0.1, 0.05, 0.95)
			border_color = Color(0.25, 0.95, 0.45, 1.0)
			shadow_color = Color(0.25, 0.95, 0.45, 0.3)
			border_width = 2.0
		elif cur_lv > 0:
			bg_color = Color(0.1, 0.08, 0.02, 0.95)
			border_color = Color(0.95, 0.65, 0.25, 0.9)
			shadow_color = Color(0.95, 0.65, 0.25, 0.2)
			border_width = 2.0
		elif purchasable:
			bg_color = Color(0.04, 0.08, 0.15, 0.95)
			border_color = Color(0.15, 0.85, 0.95, 0.85)
			shadow_color = Color(0.15, 0.85, 0.95, 0.2)
			border_width = 2.0

		if node.act2 if "act2" in node else false:
			bg_color = Color(0.06, 0.05, 0.1, 0.85)
			border_color = Color(0.45, 0.38, 0.7, 0.6)
			border_width = 1.0
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		# Add a wrapper Control inside the PanelContainer to escape Container alignment rules
		var wrapper := Control.new()
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Fill the PanelContainer space completely
		wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(wrapper)

		# Custom Shape Drawing Layer
		var bg_shape := Control.new()
		bg_shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_shape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_shape.draw.connect(func() -> void:
			var c := Vector2(card_size * 0.5, card_size * 0.5)
			var r := 22.0
			
			var pts := PackedVector2Array()
			var glow_pts := PackedVector2Array()
			
			if shape_type == 2: # CIRCLE (Large)
				r = 30.0
				for i in range(13):
					var angle = i * PI * 2.0 / 12.0
					pts.append(c + Vector2(cos(angle), sin(angle)) * r)
					glow_pts.append(c + Vector2(cos(angle), sin(angle)) * (r + 2.0))
			elif shape_type == 1: # DIAMOND (Small)
				r = 16.0
				for i in range(5):
					var angle = i * PI / 2.0
					pts.append(c + Vector2(cos(angle), sin(angle)) * r)
					glow_pts.append(c + Vector2(cos(angle), sin(angle)) * (r + 2.0))
			else: # HEXAGON
				for i in range(7):
					var angle = i * PI / 3.0 + PI / 6.0
					pts.append(c + Vector2(cos(angle), sin(angle)) * r)
					glow_pts.append(c + Vector2(cos(angle), sin(angle)) * (r + 2.0))
			
			# Draw Glow (Shadow)
			if shadow_color.a > 0:
				bg_shape.draw_polyline(glow_pts, shadow_color, 4.0, true)
			
			# Draw Fill & Outline
			bg_shape.draw_colored_polygon(pts, bg_color)
			bg_shape.draw_polyline(pts, border_color, border_width, true)
		)
		wrapper.add_child(bg_shape)

		# Add procedural icon in center of the wrapper
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrapper.add_child(center)

		var texture_rect := TextureRect.new()
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		
		# Generate custom color & tier icons based on tech type
		var icon_col := Color(0.5, 0.5, 0.5)
		var icon_tier := 1
		
		# Colour and glyph per branch
		var branch: String = node.branch if "branch" in node else "common"
		match branch:
			"common":     icon_col = Color(0.75, 0.7, 1.0);  icon_tier = 5
			"orbital":    icon_col = Color(0.6, 0.75, 0.95); icon_tier = 5
			"energy":     icon_col = Color(1.0, 0.75, 0.25); icon_tier = 3
			"production": icon_col = Color(0.95, 0.5, 0.3);  icon_tier = 2
			"processing": icon_col = Color(0.95, 0.62, 0.45); icon_tier = 2
			"science":    icon_col = Color(0.35, 0.7, 1.0);  icon_tier = 1
			"population": icon_col = Color(0.45, 0.95, 0.55); icon_tier = 1
			"trade":      icon_col = Color(1.0, 0.88, 0.3);  icon_tier = 4
			"public":     icon_col = Color(0.8, 0.8, 0.85);  icon_tier = 5
			"proximity", "distance": icon_col = Color(0.55, 0.9, 0.9); icon_tier = 4
			"geography":  icon_col = Color(0.65, 0.85, 0.5); icon_tier = 4
		if id == "root":
			icon_col = Color(0.9, 0.8, 0.4)
		if shape_type == 1:
			icon_tier = 4   # bonus diamonds share the grid glyph
		var teaser: bool = node.act2 if "act2" in node else false
		if teaser:
			icon_col = Color(0.5, 0.45, 0.65)

		# De-saturate color slightly if locked/unpurchasable
		if not unlocked and not purchasable:
			icon_col = icon_col.lerp(Color(0.25, 0.27, 0.32), 0.4)
		elif purchasable:
			icon_col = icon_col.lightened(0.1)

		texture_rect.texture = TechIcon.make(icon_tier, icon_col)
		center.add_child(texture_rect)

		# Display level badge at the bottom-center of the wrapper
		if max_lv > 1 and cur_lv > 0:
			var lv_badge := Label.new()
			if cur_lv >= max_lv:
				lv_badge.text = "MAX"
				lv_badge.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55)) # Green
			else:
				lv_badge.text = "%d" % cur_lv
				lv_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3)) # Bright Gold/Amber
				
			if _font: lv_badge.add_theme_font_override("font", _font)
			lv_badge.add_theme_font_size_override("font_size", 12) # Enlarged Level Text (12 pt)
			lv_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			lv_badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
			lv_badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
			# Sit nicely at the bottom edge, bold
			lv_badge.offset_top = -15
			lv_badge.offset_bottom = 2
			lv_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrapper.add_child(lv_badge)

		# Buyout under the previous tree's centre node (KARARLAR §8)
		if id == "civilization_0_tree":
			var bo := Button.new()
			var bo_cost: float = st.call("buyout_cost", 0)
			var bo_block: String = st.call("buyout_block", 0)
			bo.text = "Buyout  %s Science" % Economy.fmt(bo_cost)
			if bo_block != "":
				bo.text += "\n" + bo_block
			bo.disabled = bo_block != ""
			bo.focus_mode = Control.FOCUS_NONE
			if _font: bo.add_theme_font_override("font", _font)
			bo.add_theme_font_size_override("font_size", 9)
			bo.position = Vector2(-80, card_size + 4)
			bo.custom_minimum_size = Vector2(card_size + 160, 0)
			bo.pressed.connect(func() -> void:
				if st.call("buyout", 0):
					AudioManager.play("skill_buy")
				else:
					AudioManager.play("error"))
			wrapper.add_child(bo)

		# Position absolute coordinate
		card.position = node.pos - Vector2(card_size * 0.5, card_size * 0.5)
		_nodes_container.add_child(card)
		_ui_nodes[id] = card

		# Tooltip definitions
		cur_lv = st.call("get_skill_level", id)
		max_lv = node.max_level
		
		# Show title. If it is leveled, we will put the level info at the top right inside body
		var tip_title: String = node.name
		var tip_body: Array = []
		var sub_body: Array = []
		var tip_cost := ""
		
		# Root is a dummy central core - format clean
		if id == "root":
			tip_body.append(node.description)
		elif node.act2:
			tip_body.append(node.description + "\n\n[color=#9d8cff]✦ Later civilization ✦[/color]")
		else:
			var body_str := ""
			# Format level information to show at the right top of the tooltip body
			if max_lv > 1:
				if cur_lv >= max_lv:
					body_str += "[right][color=#55f58c]MAX LEVEL[/color][/right]\n"
				else:
					body_str += "[right][color=#e5c24b]Level %d/%d[/color][/right]\n" % [cur_lv, max_lv]
				
			# Normal nodes
			body_str += node.description
			
			var effect_text: String = st.call("effect_text", id)
			for bid: String in node.grants:
				var def: BuildingDef = BuildingDef.find(bid)
				if def:
					effect_text = effect_text.replace(def.display_name, "[color=#fce205]" + def.display_name + "[/color]")
					var cycle := " / %ds" % def.tick_duration
					sub_body.append("[color=#fce205]" + def.display_name + " Blueprint[/color]\n\n")
					
					if def.description != "":
						sub_body.append("[color=#c0c0c0]" + def.description + "[/color]\n\n")
					
					if def.output_label() != "":
						sub_body.append("[color=#99aab5]Produces %s%s[/color]\n" % [def.output_label(),
							"" if def.planet_bonus.size() > 0 and def.outputs.is_empty() else cycle])
					if def.input_label() != "":
						sub_body.append("[color=#99aab5]Consumes %s%s[/color]\n" % [def.input_label(), cycle])

			if max_lv > 1:
				# Leveled Upgrades
				if cur_lv > 0:
					body_str += "\n\n[color=#55f58c]Current Level: %d/%d[/color]" % [cur_lv, max_lv]
				if cur_lv < max_lv:
					body_str += "\n[color=#55aaff]Effect: %s[/color]" % effect_text
				else:
					body_str += "\n\n[color=#55f58c]✦ MAX LEVEL ✦[/color]"
			else:
				# Single purchase upgrades
				body_str += "\n\n[color=#55aaff]Effect: " + effect_text + "[/color]"
				if unlocked:
					body_str += "\n\n[color=#55f58c]✦ UNLOCKED ✦[/color]"
			
			# a granted building whose cost names an undiscovered mineral stays hidden
			for gb: String in node.grants:
				var gdef := BuildingDef.find(gb)
				if gdef != null and not gdef.minerals_known():
					body_str += "\n[color=#ffaa44]%s shows up once a Production district has found the mineral it needs.[/color]" % gdef.display_name
					break

			# Cost handling: base × target level × cross-branch factor
			if cur_lv < max_lv:
				var next_cost: float = st.call("get_next_cost", id)
				tip_cost = "%s Science" % Economy.fmt(next_cost)
				var cross: int = st.call("cross_branch_count", id)
				if cross > 0:
					body_str += "\n[color=#8899bb]Price +%d%%: you own %d research%s in other branches[/color]" % [
						int(round(float(st.call("cross_branch_mult", id)) * 100.0 - 100.0)), cross, "" if cross == 1 else "es"]
			if node.common and id != "root":
				body_str += "\n[color=#b9a8ff]Main path — research in other branches never raises its price[/color]"

			# Requirements checking (ANY parent; every extra condition)
			if cur_lv == 0:
				if not st.call("parent_ok", id):
					var names: Array[String] = []
					for p in node.parents:
						if st.get("nodes").has(p):
							names.append(st.get("nodes")[p].name)
					body_str += "\n\n[color=#ff5544]Requires one of: " + ", ".join(names) + "[/color]"
				var gate_txt: String = st.call("gate_block", id)
				if gate_txt != "":
					body_str += "\n\n[color=#ffaa44]" + gate_txt + "[/color]"
			
			tip_body.append(body_str)

		# Pivot offset at center for clean scaling
		card.pivot_offset = Vector2(24, 24)

		var cap_cost := tip_cost
		var cap_sub := sub_body.duplicate()
		card.mouse_entered.connect(func() -> void:
			AudioManager.play("hover")
			if unlocked or purchasable:
				CursorManager.set_state(CursorManager.State.POINTER)
			else:
				CursorManager.set_state(CursorManager.State.NORMAL)

			# Smooth scale up animation (Juicy Hover)
			var tween := create_tween()
			tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

			TooltipManager.show_tip(tip_title, tip_body, cap_cost, cap_sub))
			
		card.mouse_exited.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.NORMAL)
			
			# Smooth scale down animation
			var tween := create_tween()
			tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			
			TooltipManager.hide_tip())

		# Input logic for purchase click
		var cap_id: String = id
		card.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				card.accept_event() # Stop propagation to canvas drag
				# fractal doors: the next tree's root, or this tree's centre (the tree before)
				if (e as InputEventMouseButton).double_click:
					if cap_id == "civilization_1_root":
						_show_civ(1)
						return
					if cap_id == "civilization_0_tree":
						_show_civ(0)
						return
				if cap_id == "civilization_0_tree" or cap_id == "civilization_1_root":
					return   # single click on a door does nothing; buyout has its own button
				# During tutorial skill step, only unlock_mining is allowed
				var tm := get_node_or_null("/root/TutorialManager")
				if tm != null and tm._active and not tm._tutorial_done \
						and tm.get_action_step_type() == "skill" and cap_id != "start_production":
					AudioManager.play("error")
					return
				var cmd: GameCommand = st.call("research_command", cap_id)
				if cmd.can_execute() == "":
					TooltipManager.hide_tip()
					AudioManager.play("skill_buy")
					cmd.execute()
				else:
					AudioManager.play("error"))

	_apply_tutorial_skill_overlay()

func _apply_tutorial_skill_overlay() -> void:
	var tm := get_node_or_null("/root/TutorialManager")
	if tm == null or not tm._active or tm._tutorial_done or tm.get_action_step_type() != "skill":
		return
	var target_id := "start_production"
	for nid in _ui_nodes:
		var card: PanelContainer = _ui_nodes[nid]
		if not is_instance_valid(card): continue
		if nid == target_id:
			var tw := create_tween().set_loops()
			tw.tween_property(card, "modulate", Color(1.6, 1.55, 0.7, 1.0), 0.55)
			tw.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)
		elif nid != "root":
			card.modulate = Color(0.35, 0.35, 0.35, 0.6)

func _draw_connections() -> void:
	# Draw all connection lines between parent/child nodes
	var st: Node = get_node("/root/SkillTree")
	var draw_offset := Vector2(10000, 10000)
	
	for id in st.get("nodes").keys():
		var node = st.get("nodes")[id]
		# Only draw if child node is visible
		if not _in_view(st, id):
			continue
			
		var parent_idx := -1
		for parent_id in node.parents:
			parent_idx += 1
			if not st.get("nodes").has(parent_id) or not _in_view(st, parent_id):
				continue
			# lines stay apart: a link to another line's node (an ANY alternative)
			# isn't drawn — the tooltip still lists it
			var p_line: String = st.get("nodes")[parent_id].line
			var is_bridge: bool = node.line == "bridge"   # joins two lines: both links drawn
			if not is_bridge and parent_id != "root" and parent_id != "civilization_0_tree" \
					and p_line != node.line and p_line != "exploration":   # Orbit / Moon hang off Exploration
				continue

			# Offset drawing coordinates to account for _connections_draw's -10000 position shift
			var start_pos: Vector2 = st.get("nodes")[parent_id].pos + draw_offset
			var end_pos: Vector2 = node.pos + draw_offset

			# Determine line color
			var is_active: bool = st.call("is_unlocked", parent_id) and st.call("is_unlocked", id)
			var fam: Color = LINE_COLORS.get(p_line if is_bridge else node.line, Color(0.15, 0.85, 0.95))
			var line_col := Color(fam, 0.95) if is_active else Color(fam.darkened(0.55), 0.55)
			if parent_idx > 0 and not is_bridge:   # alternative (ANY) parent: a thinner, fainter trace
				line_col.a *= 0.45
			
			var p_shape: int = st.get("nodes")[parent_id].get("shape") if "shape" in st.get("nodes")[parent_id] else 0
			var c_shape: int = node.get("shape") if "shape" in node else 0
			var is_main_path: bool = p_shape != 1 and c_shape != 1 # 1 is DIAMOND

			var line_width := (8.0 if is_main_path else 4.0) if is_active else (4.0 if is_main_path else 2.0)
			if node.line == "exploration" and node.get("common"):
				line_width += 2.0   # the road to the next world stands out
			if parent_idx > 0 and not is_bridge:
				line_width *= 0.5

			# straight links: lines fork at any angle (PoE-style), no grid routing.
			# Bridge links follow the outer ring: an arc around the centre.
			var pts := PackedVector2Array([start_pos, end_pos])
			if is_bridge:
				pts = _ring_arc(start_pos - draw_offset, end_pos - draw_offset, draw_offset)
			_connections_draw.draw_polyline(pts, line_col, line_width, true)

var _zoom: float = 1.0

## Points of an arc from `a` to `b` around the tree's centre (node space),
## blending radius and angle — how bridge links run along the outer ring.
static func _ring_arc(a: Vector2, b: Vector2, offset: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r0 := a.length()
	var r1 := b.length()
	var a0 := a.angle()
	var da := wrapf(b.angle() - a0, -PI, PI)
	const STEPS := 24
	for k in STEPS + 1:
		var t := float(k) / float(STEPS)
		pts.append(Vector2.from_angle(a0 + da * t) * lerpf(r0, r1, t) + offset)
	return pts

## Colour of each research line (SkillTree.LINE_DIRS).
const LINE_COLORS := {
	"exploration": Color(0.75, 0.70, 1.0),
	"planning":    Color(0.55, 0.90, 0.90),
	"energy":      Color(1.0, 0.75, 0.25),
	"population":  Color(0.45, 0.95, 0.55),
	"trade":       Color(1.0, 0.88, 0.30),
	"science":     Color(0.35, 0.70, 1.0),
	"industry":    Color(0.95, 0.50, 0.30),
	"admin":       Color(0.80, 0.80, 0.85),
	"orbital":     Color(0.55, 0.72, 1.0),
	"lunar":       Color(0.85, 0.85, 0.72),
}

func _on_skill_unlocked(_id: String) -> void:
	# Rebuild tree to show newly unlocked nodes & connections
	_build_tree_graph()
	_connections_draw.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_offset = _center_ctrl.position - mb.global_position
				CursorManager.set_state(CursorManager.State.GRAB)
			else:
				_is_dragging = false
				CursorManager.set_state(CursorManager.State.NORMAL)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var old_zoom = _zoom
			_zoom *= 1.15
			_zoom = clampf(_zoom, 0.25, 2.0)
			# Mouse bazlı zoom için offset düzeltmesi (center_ctrl.scale)
			var mouse_pos = mb.global_position
			_center_ctrl.position = mouse_pos + (_center_ctrl.position - mouse_pos) * (_zoom / old_zoom)
			_center_ctrl.scale = Vector2(_zoom, _zoom)
			_bg.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			var old_zoom = _zoom
			_zoom /= 1.15
			_zoom = clampf(_zoom, 0.25, 2.0)
			var mouse_pos = mb.global_position
			_center_ctrl.position = mouse_pos + (_center_ctrl.position - mouse_pos) * (_zoom / old_zoom)
			_center_ctrl.scale = Vector2(_zoom, _zoom)
			_bg.queue_redraw()
			
	elif event is InputEventMagnifyGesture:
		# Trackpad Pinch to Zoom
		var mag := event as InputEventMagnifyGesture
		var old_zoom = _zoom
		_zoom *= mag.factor
		_zoom = clampf(_zoom, 0.25, 2.0)
		var mouse_pos = mag.position
		_center_ctrl.position = mouse_pos + (_center_ctrl.position - mouse_pos) * (_zoom / old_zoom)
		_center_ctrl.scale = Vector2(_zoom, _zoom)
		_bg.queue_redraw()

	elif event is InputEventPanGesture:
		# Trackpad Two Finger Scroll (Panning)
		var pan := event as InputEventPanGesture
		# Pan delta is usually very small, needs a multiplier
		_center_ctrl.position -= pan.delta * 25.0
		_connections_draw.queue_redraw()
		_bg.queue_redraw()
		
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		_center_ctrl.position = mm.global_position + _drag_offset
		_connections_draw.queue_redraw()
