extends SceneTree


const OUTPUT_PCK := "C:/GODOT TEST/godot-test-/build/web/index.pck"
const BASE_FILES := [
	"project.godot",
	"icon.svg",
	"icon.svg.import",
	".godot/global_script_class_cache.cfg",
	".godot/uid_cache.bin",
	"scenes/Main.tscn",
	"scripts/city_demo.gd"
]
const ASSET_ROOTS := [
	"assets/kenney_selected",
	"assets/user_textures"
]


func _init() -> void:
	var packer := PCKPacker.new()
	var added := {}
	var err := packer.pck_start(OUTPUT_PCK)
	if err != OK:
		push_error("pck_start failed: %s" % err)
		quit(1)
		return

	var files := BASE_FILES.duplicate()
	for asset_root in ASSET_ROOTS:
		_collect_project_files("res://" + asset_root, files)
	for relative_path in files:
		if relative_path.ends_with(".import"):
			continue
		err = _add_project_file(packer, added, relative_path)
		if err != OK:
			quit(1)
			return
		var import_path: String = String(relative_path) + ".import"
		if FileAccess.file_exists("res://" + import_path):
			err = _add_project_file(packer, added, import_path)
			if err != OK:
				quit(1)
				return
			err = _add_import_destinations(packer, added, import_path)
			if err != OK:
				quit(1)
				return

	err = packer.flush()
	if err != OK:
		push_error("pck flush failed: %s" % err)
		quit(1)
		return

	print("PCK_OK " + OUTPUT_PCK)
	quit(0)


func _collect_project_files(dir_path: String, out_files: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var item := dir.get_next()
		if item == "":
			break
		if item.begins_with("."):
			continue
		var full_path := dir_path + "/" + item
		if dir.current_is_dir():
			_collect_project_files(full_path, out_files)
		else:
			out_files.append(full_path.trim_prefix("res://"))
	dir.list_dir_end()


func _add_project_file(packer: PCKPacker, added: Dictionary, relative_path: String) -> int:
	var virtual_path := "res://" + relative_path
	if added.has(virtual_path):
		return OK
	var source := ProjectSettings.globalize_path(virtual_path)
	if relative_path == "project.godot":
		var web_project := FileAccess.get_file_as_string("res://project.godot")
		web_project = web_project.replace('renderer/rendering_method="mobile"', 'renderer/rendering_method="gl_compatibility"')
		source = ProjectSettings.globalize_path("user://web_project.godot")
		var temp_file := FileAccess.open(source, FileAccess.WRITE)
		temp_file.store_string(web_project)
		temp_file.close()
	var err := packer.add_file(virtual_path, source)
	if err != OK:
		push_error("add_file failed for %s: %s" % [relative_path, err])
		return err
	added[virtual_path] = true
	return OK


func _add_import_destinations(packer: PCKPacker, added: Dictionary, import_relative_path: String) -> int:
	var text := FileAccess.get_file_as_string("res://" + import_relative_path)
	for line in text.split("\n"):
		if not line.begins_with("dest_files="):
			continue
		var start := line.find("[")
		var end := line.rfind("]")
		if start < 0 or end < 0:
			continue
		var contents := line.substr(start + 1, end - start - 1)
		for raw_part in contents.split(","):
			var destination := raw_part.strip_edges().trim_prefix('"').trim_suffix('"')
			if destination == "":
				continue
			if added.has(destination):
				continue
			var source := ProjectSettings.globalize_path(destination)
			var err := packer.add_file(destination, source)
			if err != OK:
				push_error("add_file failed for imported destination %s: %s" % [destination, err])
				return err
			added[destination] = true
	return OK
