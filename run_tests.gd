extends SceneTree
## godot --headless --path . --script res://run_tests.gd

const Lite := preload("res://addons/kitsmith_lite/kitsmith_lite.gd")

var _passed := 0
var _failed := 0


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: ", label)


func _same(a: Image, b: Image) -> bool:
	return a.get_size() == b.get_size() and a.get_data() == b.get_data()


func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01


func _init() -> void:
	for hex in ["4a5a8c", "c9a66b", "1f2b24", "f4d9df", "ff0000"]:
		var base := Color(hex)
		var panel := Lite.make_panel(base)
		_check(panel.get_size() == Vector2i(16, 16), hex + ": panel is 16 x 16")
		_check(panel.get_pixel(0, 0).a == 0.0 and panel.get_pixel(2, 0).a > 0.0 and panel.get_pixel(1, 1).a > 0.0, hex + ": corners are rounded")
		_check(_near(panel.get_pixel(8, 0), Lite.shade(base, -0.8)), hex + ": outline on the edge")
		_check(_near(panel.get_pixel(8, 8), base), hex + ": centre is the base colour")
		_check(panel.get_pixel(8, 1).get_luminance() > panel.get_pixel(8, 14).get_luminance(), hex + ": light on top, dark below")
		var symmetric := true
		var flat := true
		for y in 16:
			for x in 16:
				if (panel.get_pixel(x, y).a > 0.0) != (panel.get_pixel(15 - x, y).a > 0.0) or (panel.get_pixel(x, y).a > 0.0) != (panel.get_pixel(x, 15 - y).a > 0.0):
					symmetric = false
				if x >= Lite.MARGIN and x < 16 - Lite.MARGIN and y >= Lite.MARGIN and y < 16 - Lite.MARGIN and panel.get_pixel(x, y) != panel.get_pixel(8, 8):
					flat = false
		_check(symmetric, hex + ": silhouette is symmetric")
		_check(flat, hex + ": the centre is flat, safe to stretch")
		_check(_same(panel, Lite.make_panel(base)), hex + ": same colour, same pixels")
		var slot := Lite.make_slot(base)
		_check(slot.get_pixel(8, 1).get_luminance() < slot.get_pixel(8, 14).get_luminance(), hex + ": slot is sunken")
		_check(slot.get_pixel(8, 8).get_luminance() < panel.get_pixel(8, 8).get_luminance() or base.v < 0.05, hex + ": slot is darker than the panel")

		var buttons: Array[Image] = []
		for state in Lite.State.size():
			buttons.append(Lite.make_button(base, state))
		for i in buttons.size():
			_check(buttons[i].get_size() == Vector2i(16, 16), "%s: button %d is 16 x 16" % [hex, i])
			for j in range(i + 1, buttons.size()):
				_check(not _same(buttons[i], buttons[j]), "%s: button %d differs from %d" % [hex, i, j])
		_check(buttons[Lite.State.NORMAL].get_pixel(8, 0).a > 0.0 and buttons[Lite.State.PRESSED].get_pixel(8, 0).a == 0.0, hex + ": the pressed button sits one pixel lower")
		_check(buttons[Lite.State.NORMAL].get_pixel(8, 15).a > 0.0 and buttons[Lite.State.PRESSED].get_pixel(8, 15).a > 0.0, hex + ": both reach the bottom row")
		_check(buttons[Lite.State.DISABLED].get_pixel(8, 8).s <= buttons[Lite.State.NORMAL].get_pixel(8, 8).s, hex + ": disabled is desaturated")
		_check(absf(Lite.text_color(base).get_luminance() - base.get_luminance()) > 0.3, hex + ": text contrasts with the fill")

		var theme := Lite.build_theme(base, 2)
		for sb in ["normal", "hover", "pressed", "disabled"]:
			_check(theme.has_stylebox(sb, "Button"), hex + ": theme has Button/" + sb)
		_check(theme.has_stylebox("panel", "PanelContainer") and theme.has_stylebox("panel", "Panel") and theme.has_stylebox("normal", "LineEdit"), hex + ": theme skins panels and line edits")
		var box := theme.get_stylebox("normal", "Button") as StyleBoxTexture
		_check(box.texture.get_width() == 32 and box.get_texture_margin(SIDE_LEFT) == 8.0 and box.get_texture_margin(SIDE_BOTTOM) == 10.0, hex + ": button stylebox is at 2x with the lip in its bottom margin")
	var big := Lite.scaled(Lite.make_panel(Color("4a5a8c")), 3)
	_check(big.get_size() == Vector2i(48, 48) and big.get_pixel(4, 4) == Lite.make_panel(Color("4a5a8c")).get_pixel(1, 1), "scaling is nearest-neighbour")
	_check(Lite.shade(Color.RED, 0.0).is_equal_approx(Color.RED), "shade 0 keeps the colour")
	print("%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
