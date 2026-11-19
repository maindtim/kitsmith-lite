extends Control
## Kitsmith Lite demo: one colour in, a skinned interface out. Press a swatch or pick a colour.

const SWATCHES := ["4a5a8c", "8c4a4a", "4f7a4a", "c9a66b", "5b3a8c", "5a5f6b", "e76fa3", "1f2b24"]

var base := Color("4a5a8c")
var _window: PanelContainer
var _hex: Label
var _picker: ColorPickerButton


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("171a2b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 40
	column.offset_top = 28
	column.offset_right = -40
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 16)
	add_child(column)

	# Colour choices: these keep Godot's default look on purpose, to show the difference.
	var picks := HBoxContainer.new()
	picks.add_theme_constant_override("separation", 8)
	column.add_child(picks)
	for hex: String in SWATCHES:
		var swatch := ColorRect.new()
		swatch.color = Color(hex)
		swatch.custom_minimum_size = Vector2(44, 44)
		swatch.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				set_base(Color(hex)))
		picks.add_child(swatch)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(120, 44)
	picker.color = base
	picker.edit_alpha = false
	picker.color_changed.connect(set_base)
	picks.add_child(picker)
	_picker = picker
	_hex = Label.new()
	picks.add_child(_hex)

	# Everything under _window uses the generated theme.
	_window = PanelContainer.new()
	_window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_window.add_child(box)
	var title := Label.new()
	title.text = "Blacksmith"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var line := Label.new()
	line.text = "That blade has seen better days. Leave it with me until sundown and it will cut like new. Fifty gold, not a coin less."
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(line)
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Name your blade"
	box.add_child(name_edit)
	var inner := PanelContainer.new()
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(inner)
	var note := Label.new()
	note.text = "Panels nest. Every pixel here was drawn by KitsmithLite.build_theme(colour): no image files."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	for item in [["Pay 50 gold", false], ["Haggle", false], ["Steal it back", true]]:
		var b := Button.new()
		b.text = item[0]
		b.disabled = item[1]
		b.custom_minimum_size = Vector2(150, 0)
		buttons.add_child(b)

	var more := Label.new()
	more.text = "Kitsmith Lite: one look, panels, slots and buttons. The full Kitsmith adds 8 borders, 55 pieces, a pixel font and a complete Godot Theme."
	more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	more.add_theme_color_override("font_color", Color("aab4d6"))
	column.add_child(more)
	set_base(base)


func set_base(color: Color) -> void:
	base = color
	_window.theme = KitsmithLite.build_theme(base, 3)
	_hex.text = "#" + base.to_html(false)
	if _picker.color != base:
		_picker.color = base
