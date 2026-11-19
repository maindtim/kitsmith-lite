extends SceneTree
## Takes the README screenshots from the running demo.
##   godot --path . --resolution 960x540 --script res://tools/screenshot.gd -- color=c9a66b out=screenshots/parchment.png

func _initialize() -> void:
	var color := "4a5a8c"
	var out := "screenshots/demo.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("color="):
			color = a.substr(6)
		elif a.begins_with("out="):
			out = a.substr(4)
	await process_frame
	var demo: Control = load("res://demo/demo.tscn").instantiate()
	root.add_child(demo)
	demo.set_base(Color(color))
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("saved ", out)
	quit()
