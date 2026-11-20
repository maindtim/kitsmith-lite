class_name KitsmithLite
extends RefCounted
## Kitsmith Lite - pixel-art panels and buttons drawn by code from one colour.
##
## No image files: the 9-slice textures are generated when you ask for them, so a game can
## re-skin its interface at runtime (team colours, player-chosen themes, day and night).
##
##   $Menu.theme = KitsmithLite.build_theme(Color("4a5a8c"))        # panels + buttons, at 3x
##   KitsmithLite.make_panel(Color("8c4a4a")).save_png("user://panel.png")
##
## One look only (bevelled, rounded). The full Kitsmith has 8 borders, 80 pieces, palette lock,
## a pixel font, patterns and a complete Godot Theme: see the README.

enum State { NORMAL, HOVER, PRESSED, DISABLED }

## 9-slice margin of every piece, in 1x pixels.
const MARGIN := 4


## amount > 0 lightens, amount < 0 darkens. Range -1..1.
static func shade(c: Color, amount: float) -> Color:
	if amount >= 0.0:
		return Color.from_hsv(c.h, c.s * (1.0 - amount * 0.5), lerpf(c.v, 1.0, amount), c.a)
	return Color.from_hsv(c.h, minf(c.s - amount * 0.15, 1.0), c.v * (1.0 + amount), c.a)


## Readable text colour over a fill colour.
static func text_color(over: Color) -> Color:
	if over.get_luminance() > 0.5:
		return shade(over, -0.8)
	return shade(over, 0.85)


## A raised panel (16 x 16 at 1x). Stretch it as a 9-slice with MARGIN on every side.
static func make_panel(base: Color) -> Image:
	return _frame(16, 16, base, false)


## A sunken box (16 x 16 at 1x), for inventory slots and text fields.
static func make_slot(base: Color) -> Image:
	return _frame(16, 16, shade(base, -0.3), true)


## A button (16 x 16 at 1x): 15 rows of body and one row of dark lip under it. The pressed
## state sits one pixel lower and hides the lip. 9-slice margins: MARGIN, and MARGIN + 1 below.
static func make_button(base: Color, state: int = State.NORMAL) -> Image:
	var color := base
	if state == State.HOVER:
		color = shade(base, 0.16)
	elif state == State.DISABLED:
		color = Color.from_hsv(base.h, base.s * 0.2, base.v * 0.75, base.a)
	var body := _frame(16, 15, color, state == State.PRESSED)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if state == State.PRESSED:
		img.blit_rect(body, Rect2i(0, 0, 16, 15), Vector2i(0, 1))
		return img
	var lip := shade(color, -0.8)
	for y in 15:
		for x in 16:
			if body.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y + 1, lip)
	for y in 15:
		for x in 16:
			var c := body.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
	return img


## Nearest-neighbour upscale by a whole factor.
static func scaled(img: Image, factor: int) -> Image:
	var out := Image.new()
	out.copy_from(img)
	if factor > 1:
		out.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return out


## A StyleBoxTexture for a generated piece. bottom_extra adds 1x pixels to the bottom margin
## (buttons use 1 for their lip).
static func stylebox(img: Image, scale: int = 3, bottom_extra: int = 0, padding: int = 2) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(scaled(img, scale))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		var m := MARGIN + (bottom_extra if side == SIDE_BOTTOM else 0)
		box.set_texture_margin(side, m * scale)
		box.set_content_margin(side, (m + padding) * scale)
	return box


## A Theme that skins Panel, PanelContainer, Button, LineEdit and Label from one colour.
## Assign it to a root Control. Set the project's default texture filter to Nearest.
static func build_theme(base: Color, scale: int = 3) -> Theme:
	var theme := Theme.new()
	var text := text_color(base)
	for type in ["Panel", "PanelContainer"]:
		theme.set_stylebox("panel", type, stylebox(make_panel(base), scale))
	var names := ["normal", "hover", "pressed", "disabled"]
	for state in names.size():
		theme.set_stylebox(names[state], "Button", stylebox(make_button(base, state), scale, 1))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(c, "Button", text)
	theme.set_color("font_disabled_color", "Button", Color(text, 0.5))
	theme.set_color("font_color", "Label", text)
	theme.set_stylebox("normal", "LineEdit", stylebox(make_slot(base), scale))
	theme.set_stylebox("focus", "LineEdit", StyleBoxEmpty.new())
	theme.set_color("font_color", "LineEdit", text_color(shade(base, -0.3)))
	return theme


# ---------------------------------------------------------------------------------------------

static func _inside(x: int, y: int, w: int, h: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	# Corners cut by two pixels, rounded.
	return mini(x, w - 1 - x) + mini(y, h - 1 - y) >= 2


## Outline, a two-pixel bevel (light on top and left, dark below and right; swapped when
## sunken) and a flat centre.
static func _frame(w: int, h: int, base: Color, sunken: bool) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := shade(base, -0.8)
	var light := shade(base, 0.25)
	var dark := shade(base, -0.25)
	var fill := base if not sunken else base.lerp(dark, 0.35)
	var ring := PackedInt32Array()
	ring.resize(w * h)
	for y in h:
		for x in w:
			ring[y * w + x] = 9 if _inside(x, y, w, h) else -1
	for depth in 3:
		var hits := PackedInt32Array()
		for y in h:
			for x in w:
				if ring[y * w + x] != 9:
					continue
				for n: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var inside := _inside(x + n.x, y + n.y, w, h)
					var near := ring[(y + n.y) * w + x + n.x] if inside else -1
					if (depth == 0 and not inside) or (depth > 0 and near == depth - 1):
						hits.append(y * w + x)
						break
		for i in hits:
			ring[i] = depth
	for y in h:
		for x in w:
			var d := ring[y * w + x]
			if d < 0:
				continue
			var c := fill
			if d == 0:
				c = outline
			elif d <= 2:
				var top_left := mini(x, y) < mini(w - 1 - x, h - 1 - y)
				var bottom_right := mini(x, y) > mini(w - 1 - x, h - 1 - y)
				if top_left:
					c = light if not sunken else dark
				elif bottom_right:
					c = dark if not sunken else light
				else:
					c = base
			img.set_pixel(x, y, c)
	return img
