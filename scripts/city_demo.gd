extends Node3D

const GRID_COLUMNS := 2
const GRID_ROWS := 5
const CELL_SIZE := 2.35
const GRID_OFFSET := Vector3(1.35, 0.0, 0.0)
const ECONOMY_SECONDS_PER_HOUR := 1.0
const MENU_WIDTH := 178.0
const KENNEY_CITY := "res://assets/kenney_selected/city/"
const KENNEY_ROADS := "res://assets/kenney_selected/roads/"
const KENNEY_CARS := "res://assets/kenney_selected/cars/"
const KENNEY_PEOPLE := "res://assets/kenney_selected/people/"
const KENNEY_BOATS := "res://assets/kenney_selected/boats/"
const KENNEY_PETS := "res://assets/kenney_selected/pets/"
const SIDE_STONE_ALBEDO := "res://assets/user_textures/medieval_wall/medieval_wall_01_diff_2k.jpg"
const SIDE_STONE_ROUGHNESS := "res://assets/user_textures/medieval_wall/medieval_wall_01_rough_2k.jpg"
const SIDE_STONE_HEIGHT := "res://assets/user_textures/medieval_wall/medieval_wall_01_disp_2k.jpg"
const SIDE_STONE_NORMAL := "res://assets/user_textures/medieval_wall/medieval_wall_01_normal_1k.png"

var coins := 50000000.0
var selected_building := 0
var plots := []
var placed := {}
var building_buttons := []
var coin_label: Label
var income_label: Label
var status_label: Label
var selected_label: Label
var city_root: Node3D
var effects_root: Node3D
var materials := {}
var asset_scene_cache := {}

var building_data := [
	{"name": "Капсула", "cost": 60, "income": 1, "color": Color(0.48, 0.86, 1.0)},
	{"name": "Солнечный", "cost": 240, "income": 10, "color": Color(1.0, 0.78, 0.22)},
	{"name": "Неон", "cost": 950, "income": 100, "color": Color(1.0, 0.28, 0.85)},
	{"name": "Дата", "cost": 4200, "income": 1000, "color": Color(0.32, 0.58, 1.0)},
	{"name": "Биокупол", "cost": 18000, "income": 10000, "color": Color(0.25, 1.0, 0.54)},
	{"name": "Транспорт", "cost": 82000, "income": 100000, "color": Color(1.0, 0.43, 0.24)},
	{"name": "Кристалл", "cost": 370000, "income": 1000000, "color": Color(0.58, 0.42, 1.0)},
	{"name": "Сад", "cost": 1600000, "income": 10000000, "color": Color(0.5, 0.95, 0.72)},
	{"name": "Квант", "cost": 7200000, "income": 100000000, "color": Color(0.18, 1.0, 0.92)},
	{"name": "Мегаядро", "cost": 32000000, "income": 1000000000, "color": Color(1.0, 0.95, 0.62)}
]


func _ready() -> void:
	randomize()
	_prepare_materials()
	_create_environment()
	_create_city()
	_create_camera()
	_create_ui()
	_select_building(0)
	_fill_showcase_city()
	_set_status("Витрина: 10 зданий уже на карте")
	_refresh_hud()

	var economy_timer := Timer.new()
	economy_timer.wait_time = ECONOMY_SECONDS_PER_HOUR
	economy_timer.autostart = true
	economy_timer.timeout.connect(_on_economy_tick)
	add_child(economy_timer)


func _prepare_materials() -> void:
	materials.tile = _make_material(Color(0.034, 0.038, 0.048), Color(0.02, 0.07, 0.08), 0.14)
	materials.tile_alt = _make_material(Color(0.042, 0.044, 0.055), Color(0.02, 0.065, 0.08), 0.12)
	materials.edge = _make_material(Color(0.055, 0.07, 0.078), Color(0.04, 0.16, 0.18), 0.28)
	materials.ground = _make_material(Color(0.012, 0.016, 0.028), Color(0.0, 0.025, 0.05), 0.28)
	materials.side_stone = _textured_city_stone_material()
	materials.road = _make_material(Color(0.025, 0.03, 0.045), Color(0.0, 0.16, 0.2), 0.55)
	materials.window = _make_material(Color(0.12, 0.42, 0.78), Color(0.14, 0.65, 1.0), 0.72)
	materials.dark_metal = _make_material(Color(0.05, 0.055, 0.07), Color(0.01, 0.02, 0.035), 0.06, 0.62, 0.18)
	materials.obsidian = _procedural_texture_material("obsidian", Color(0.012, 0.01, 0.022), Color(0.2, 0.12, 0.32), 0.42, 0.045, 0.48)
	materials.carbon = _procedural_texture_material("carbon", Color(0.008, 0.009, 0.011), Color(0.34, 0.37, 0.4), 0.86, 0.12, 0.62)
	materials.soft_white = _make_material(Color(0.84, 0.88, 0.84), Color(0.08, 0.12, 0.13), 0.08, 0.0, 0.42)
	materials.concrete = _procedural_texture_material("stone", Color(0.52, 0.54, 0.52), Color(0.86, 0.84, 0.74), 0.0, 0.84, 0.38)
	materials.porcelain = _make_material(Color(0.9, 0.97, 1.0), Color(0.1, 0.28, 0.36), 0.05, 0.02, 0.08)
	materials.pearl = _procedural_texture_material("pearl", Color(0.9, 0.84, 0.66), Color(1.0, 0.96, 0.84), 0.08, 0.16, 0.22)
	materials.brick = _procedural_texture_material("brick", Color(0.62, 0.18, 0.11), Color(0.13, 0.055, 0.04), 0.0, 0.82, 0.58)
	materials.solar_panel = _procedural_texture_material("solar", Color(0.005, 0.055, 0.16), Color(0.08, 0.72, 1.0), 0.0, 0.06, 0.42, Color(0.08, 0.72, 1.0), 0.08)
	materials.neon_glass = _make_material(Color(0.28, 0.015, 0.2, 0.22), Color(1.0, 0.08, 0.65), 0.35, 0.0, 0.04, 0.22)
	materials.data_glass = _pattern_material(Color(0.008, 0.04, 0.095), Color(0.12, 0.64, 1.0), 7, 0.42, 0.06, 0.14)
	materials.bio_glass = _make_material(Color(0.045, 0.34, 0.22, 0.32), Color(0.12, 0.95, 0.42), 0.52, 0.0, 0.05, 0.32)
	materials.leaf = _pattern_material(Color(0.075, 0.42, 0.19), Color(0.55, 0.86, 0.34), 8, 0.0, 0.0, 0.72)
	materials.moss = _pattern_material(Color(0.28, 0.47, 0.25), Color(0.76, 0.78, 0.36), 8, 0.0, 0.0, 0.76)
	materials.copper = _procedural_texture_material("brushed", Color(0.63, 0.22, 0.07), Color(1.0, 0.55, 0.24), 0.88, 0.14, 0.32)
	materials.crystal = _make_material(Color(0.42, 0.25, 0.9, 0.72), Color(0.62, 0.42, 1.0), 2.6, 0.0, 0.04, 0.72)
	materials.quantum = _make_material(Color(0.015, 0.32, 0.36, 0.42), Color(0.0, 1.0, 0.88), 0.9, 0.0, 0.035, 0.42)
	materials.mega_gold = _procedural_texture_material("brushed", Color(0.9, 0.58, 0.11), Color(1.0, 0.92, 0.36), 0.92, 0.1, 0.3)
	materials.marble = _procedural_texture_material("marble", Color(0.86, 0.85, 0.79), Color(0.28, 0.25, 0.21), 0.0, 0.22, 0.44)
	materials.granite = _procedural_texture_material("stone", Color(0.24, 0.255, 0.275), Color(0.6, 0.57, 0.5), 0.0, 0.5, 0.46)
	materials.patina = _procedural_texture_material("brushed", Color(0.06, 0.26, 0.24), Color(0.33, 0.82, 0.68), 0.38, 0.26, 0.28)
	materials.fountain_water = _glass_material(Color(0.03, 0.24, 0.34), Color(0.42, 0.9, 1.0), 0.42, 0.44)
	materials.water = _make_material(Color(0.05, 0.24, 0.32, 0.5), Color(0.0, 0.55, 0.75), 0.9, 0.0, 0.1, 0.5)
	materials.river = _river_material(Color(0.015, 0.095, 0.16), Color(0.18, 0.86, 1.0))
	materials.asphalt = _make_material(Color(0.018, 0.02, 0.024), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.78)
	materials.sidewalk = _make_material(Color(0.095, 0.105, 0.115), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.66)
	materials.glass_peacock = _glass_material(Color(0.01, 0.16, 0.21), Color(0.18, 0.88, 0.95), 0.58, 0.72)
	materials.glass_champagne = _glass_material(Color(0.42, 0.31, 0.12), Color(1.0, 0.78, 0.34), 0.46, 0.56)
	materials.glass_garnet = _glass_material(Color(0.2, 0.02, 0.075), Color(1.0, 0.23, 0.42), 0.52, 0.64)
	materials.glass_sapphire = _glass_material(Color(0.015, 0.08, 0.24), Color(0.28, 0.62, 1.0), 0.5, 0.68)
	materials.glass_jade = _glass_material(Color(0.02, 0.18, 0.12), Color(0.34, 1.0, 0.62), 0.48, 0.58)
	materials.glass_violet = _glass_material(Color(0.13, 0.05, 0.27), Color(0.72, 0.44, 1.0), 0.54, 0.74)
	materials.glass_ice = _glass_material(Color(0.38, 0.58, 0.66), Color(0.86, 1.0, 1.0), 0.38, 0.38)
	materials.bronze = _procedural_texture_material("brushed", Color(0.45, 0.22, 0.085), Color(0.95, 0.58, 0.26), 0.9, 0.12, 0.34)
	materials.rose_gold = _procedural_texture_material("brushed", Color(0.76, 0.37, 0.28), Color(1.0, 0.74, 0.62), 0.86, 0.13, 0.28)
	materials.black_glass = _glass_material(Color(0.012, 0.014, 0.02), Color(0.46, 0.58, 0.72), 0.62, 0.8)
	materials.moon = _make_material(Color(0.78, 0.84, 0.92), Color(0.55, 0.68, 1.0), 0.55, 0.0, 0.22)
	materials.lit_warm = _make_material(Color(1.0, 0.76, 0.34), Color(1.0, 0.58, 0.18), 0.58, 0.0, 0.2)
	materials.lit_cool = _make_material(Color(0.36, 0.78, 1.0), Color(0.16, 0.7, 1.0), 0.5, 0.0, 0.18)
	materials.lit_rose = _make_material(Color(1.0, 0.38, 0.58), Color(1.0, 0.12, 0.34), 0.48, 0.0, 0.2)
	materials.lit_green = _make_material(Color(0.32, 0.96, 0.48), Color(0.12, 0.78, 0.28), 0.42, 0.0, 0.28)
	materials.curbstone = _make_material(Color(0.42, 0.43, 0.4), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.7)
	materials.trash_dark = _make_material(Color(0.045, 0.05, 0.05), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.62)
	materials.paper = _make_material(Color(0.75, 0.72, 0.58), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.86)
	materials.headlight_beam = _make_material(Color(1.0, 0.92, 0.58, 0.24), Color(1.0, 0.78, 0.28), 0.12, 0.0, 0.08, 0.24)
	materials.awning = _make_material(Color(0.86, 0.16, 0.24), Color(0.7, 0.04, 0.12), 0.06, 0.0, 0.46)


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.01, 0.018)
	environment.ambient_light_color = Color(0.24, 0.25, 0.28)
	environment.ambient_light_energy = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.24
	environment.glow_strength = 0.42
	environment.glow_bloom = 0.035
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Soft angled sun"
	sun.light_energy = 3.35
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.rotation_degrees = Vector3(-54.0, -38.0, 0.0)
	add_child(sun)

	var rim := OmniLight3D.new()
	rim.name = "City rim glow"
	rim.position = Vector3(0.0, 5.0, -3.8)
	rim.light_color = Color(0.32, 0.78, 1.0)
	rim.light_energy = 0.7
	rim.omni_range = 12.0
	add_child(rim)

	var warm_fill := OmniLight3D.new()
	warm_fill.name = "Warm premium fill"
	warm_fill.position = GRID_OFFSET + Vector3(2.4, 2.6, 3.8)
	warm_fill.light_color = Color(1.0, 0.55, 0.26)
	warm_fill.light_energy = 1.7
	warm_fill.omni_range = 8.0
	add_child(warm_fill)

	var moon_light := DirectionalLight3D.new()
	moon_light.name = "Blue moon key light"
	moon_light.light_energy = 0.72
	moon_light.light_color = Color(0.56, 0.68, 1.0)
	moon_light.rotation_degrees = Vector3(-38.0, 42.0, 0.0)
	add_child(moon_light)

	var moon := _add_sphere(self, GRID_OFFSET + Vector3(-4.05, 2.65, 3.9), 0.24, materials.moon, 32, "Visible moon disk")
	_add_light(self, moon.position, Color(0.52, 0.66, 1.0), 0.26, 4.8)
	_create_reflection_probe()


func _create_reflection_probe() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var probe := ReflectionProbe.new()
	probe.name = "Downtown reflection probe"
	probe.position = GRID_OFFSET + Vector3(0.0, 1.45, 0.0)
	probe.size = Vector3(11.2, 5.2, 16.2)
	probe.intensity = 0.95
	probe.box_projection = true
	probe.max_distance = 22.0
	add_child(probe)


func _create_city() -> void:
	city_root = Node3D.new()
	city_root.name = "Procedural City"
	add_child(city_root)

	effects_root = Node3D.new()
	effects_root.name = "Effects"
	add_child(effects_root)

	_add_box(city_root, GRID_OFFSET + Vector3(0.0, -0.205, 0.0), Vector3(17.8, 0.09, 21.5), materials.side_stone, "Textured stone surroundings")
	_add_box(city_root, GRID_OFFSET + Vector3(0.0, -0.11, 0.0), Vector3(9.8, 0.12, 15.0), materials.ground, "Night city island")
	_add_box(city_root, GRID_OFFSET + Vector3(0.0, -0.035, 0.0), Vector3(5.55, 0.035, 12.65), materials.sidewalk, "Stone downtown slab")
	_add_box(city_root, GRID_OFFSET + Vector3(-1.36, -0.01, 0.0), Vector3(0.28, 0.036, 12.9), materials.asphalt, "West avenue")
	_add_box(city_root, GRID_OFFSET + Vector3(1.36, -0.01, 0.0), Vector3(0.28, 0.036, 12.9), materials.asphalt, "East avenue")
	_add_box(city_root, GRID_OFFSET + Vector3(0.0, -0.008, -5.85), Vector3(5.5, 0.034, 0.24), materials.asphalt, "Cross street south")
	_add_box(city_root, GRID_OFFSET + Vector3(0.0, -0.008, 5.85), Vector3(5.5, 0.034, 0.24), materials.asphalt, "Cross street north")
	_add_box(city_root, GRID_OFFSET + Vector3(-1.36, 0.022, 0.0), Vector3(0.028, 0.018, 12.15), _accent_material(Color(0.16, 0.75, 1.0), 0.45), "Avenue light reflection")
	_add_box(city_root, GRID_OFFSET + Vector3(1.36, 0.022, 0.0), Vector3(0.028, 0.018, 12.15), _accent_material(Color(1.0, 0.64, 0.34), 0.4), "Avenue warm reflection")
	_create_waterfront()
	_create_background_skyline()
	_create_plots()
	_create_street_details()
	_create_civic_details()
	_create_city_life()


func _create_waterfront() -> void:
	for x in [-3.85, 5.2]:
		_add_box(city_root, GRID_OFFSET + Vector3(x, -0.052, 0.0), Vector3(1.05, 0.045, 14.55), materials.river, "Animated river channel")
		_add_box(city_root, GRID_OFFSET + Vector3(x * 0.78, 0.015, 0.0), Vector3(0.08, 0.075, 14.3), materials.dark_metal, "Stone quay wall")
		for i in range(8):
			var z := -6.1 + float(i) * 1.75
			_add_box(city_root, GRID_OFFSET + Vector3(x * 0.78, 0.08, z), Vector3(0.12, 0.08, 0.32), _make_material(Color(0.16, 0.17, 0.18), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.58), "Quay stone cap")
	for z in [-6.1, 6.1]:
		_add_box(city_root, GRID_OFFSET + Vector3(0.66, 0.045, z), Vector3(8.15, 0.055, 0.18), materials.asphalt, "Low river crossing")
		for x in [-2.35, -0.55, 1.85, 3.65]:
			for side in [-1.0, 1.0]:
				_add_cylinder(city_root, GRID_OFFSET + Vector3(x, 0.13, z + side * 0.13), 0.028, 0.16, materials.dark_metal, 8, "Bridge bollard")
				_add_sphere(city_root, GRID_OFFSET + Vector3(x, 0.24, z + side * 0.13), 0.035, _accent_material(Color(1.0, 0.72, 0.38), 0.58), 10, "Bridge lamp glow")


func _create_background_skyline() -> void:
	var skyline := Node3D.new()
	skyline.name = "Reflective background skyline"
	city_root.add_child(skyline)

	var skyline_mats: Array = [materials.dark_metal, materials.black_glass, materials.carbon, materials.obsidian]
	var specs := [
		[Vector3(-4.58, 0.0, -5.45), Vector3(0.34, 0.88, 0.42)],
		[Vector3(-4.64, 0.0, -3.8), Vector3(0.42, 1.22, 0.36)],
		[Vector3(-4.52, 0.0, -1.95), Vector3(0.3, 0.72, 0.48)],
		[Vector3(-4.62, 0.0, 0.15), Vector3(0.46, 1.02, 0.46)],
		[Vector3(-4.55, 0.0, 2.3), Vector3(0.32, 1.3, 0.34)],
		[Vector3(-4.66, 0.0, 4.85), Vector3(0.5, 0.86, 0.52)],
		[Vector3(6.08, 0.0, -4.9), Vector3(0.46, 1.14, 0.5)],
		[Vector3(6.18, 0.0, -2.65), Vector3(0.32, 0.76, 0.4)],
		[Vector3(6.08, 0.0, -0.55), Vector3(0.52, 1.32, 0.42)],
		[Vector3(6.2, 0.0, 1.75), Vector3(0.34, 0.92, 0.5)],
		[Vector3(6.1, 0.0, 3.8), Vector3(0.42, 1.18, 0.36)],
		[Vector3(6.22, 0.0, 5.55), Vector3(0.3, 0.68, 0.44)],
	]
	for i in range(specs.size()):
		var base: Vector3 = specs[i][0]
		var size: Vector3 = specs[i][1]
		var mat: Material = skyline_mats[i % skyline_mats.size()]
		var pos := GRID_OFFSET + Vector3(base.x, size.y * 0.5 - 0.035, base.z)
		_add_box(skyline, pos, size, mat, "Orderly waterfront skyline tower")
		var crown_color := Color(0.22, 0.86, 1.0) if i % 2 == 0 else Color(1.0, 0.62, 0.36)
		_add_box(skyline, pos + Vector3(0.0, size.y * 0.5 + 0.028, 0.0), Vector3(size.x * 0.68, 0.04, size.z * 0.68), _accent_material(crown_color, 0.42), "Clean skyline crown light")
		_add_lit_windows(skyline, pos + Vector3(0.0, 0.0, size.z * 0.51), size.x * 0.64, size.y * 0.62, 2, 5, materials.lit_warm if i % 2 == 0 else materials.lit_cool, 0.42, "Tiny distant skyline windows")


func _create_street_details() -> void:
	var warm := Color(1.0, 0.72, 0.38)
	var cyan := Color(0.18, 0.92, 1.0)
	for x in [-1.98, -1.62, -1.1, -0.74, 0.74, 1.1, 1.62, 1.98]:
		_add_box(city_root, GRID_OFFSET + Vector3(x, 0.04, 0.0), Vector3(0.045, 0.08, 12.65), materials.curbstone, "Raised curb line")
	for z in [-5.98, -5.72, 5.72, 5.98]:
		_add_box(city_root, GRID_OFFSET + Vector3(0.0, 0.04, z), Vector3(5.5, 0.08, 0.045), materials.curbstone, "Raised cross curb")
	for i in range(12):
		var z := -5.75 + float(i) * 1.05
		var color := warm if i % 2 == 0 else cyan
		for x in [-1.74, -0.98, 0.98, 1.74]:
			var yaw := 180.0 if x < 0.0 else 0.0
			var lamp_root := _add_asset_scene(city_root, KENNEY_ROADS + "light-curved.glb", GRID_OFFSET + Vector3(x, 0.025, z), 0.58, yaw, "Kenney curved street lamp")
			_add_sphere(lamp_root, Vector3(0.0, 0.39, -0.11), 0.036, _accent_material(color, 0.8), 10, "Imported lamp bulb glow")
			_add_light(lamp_root, Vector3(0.0, 0.38, -0.12), color, 0.12, 1.05)
	for i in range(18):
		var z := -6.0 + float(i) * 0.7
		_add_box(city_root, GRID_OFFSET + Vector3(-1.36, 0.024, z), Vector3(0.038, 0.016, 0.27), _make_material(Color(0.82, 0.78, 0.62), Color(1.0, 0.82, 0.34), 0.08, 0.0, 0.35), "West lane dash")
		_add_box(city_root, GRID_OFFSET + Vector3(1.36, 0.024, z), Vector3(0.038, 0.016, 0.27), _make_material(Color(0.68, 0.8, 0.86), Color(0.18, 0.76, 1.0), 0.06, 0.0, 0.35), "East lane dash")
	_add_shopfront(GRID_OFFSET + Vector3(-2.35, 0.08, -3.95), "CAFE", Color(1.0, 0.44, 0.28), Color(0.18, 0.12, 0.08))
	_add_shopfront(GRID_OFFSET + Vector3(2.35, 0.08, -2.45), "TECH", Color(0.2, 0.82, 1.0), Color(0.04, 0.08, 0.14))
	_add_shopfront(GRID_OFFSET + Vector3(-2.35, 0.08, 2.35), "DELI", Color(0.9, 0.78, 0.36), Color(0.1, 0.08, 0.04))
	_add_shopfront(GRID_OFFSET + Vector3(2.35, 0.08, 3.85), "MODA", Color(1.0, 0.38, 0.62), Color(0.16, 0.04, 0.1))
	for pos in [
		Vector3(-2.08, 0.06, -5.12),
		Vector3(2.06, 0.06, -4.2),
		Vector3(-2.04, 0.06, 0.9),
		Vector3(2.08, 0.06, 5.1),
		Vector3(-0.74, 0.06, -5.72),
		Vector3(0.74, 0.06, 5.72),
	]:
		_add_city_furniture(GRID_OFFSET + pos)
	_add_spot_light(city_root, GRID_OFFSET + Vector3(-2.85, 1.1, -5.45), GRID_OFFSET + Vector3(-1.15, 0.0, -3.85), Color(0.6, 0.75, 1.0), 1.2, 4.8, 30.0, "Cool waterfront spotlight")
	_add_spot_light(city_root, GRID_OFFSET + Vector3(3.15, 1.2, 5.3), GRID_OFFSET + Vector3(1.05, 0.0, 3.85), Color(1.0, 0.66, 0.34), 1.1, 4.5, 28.0, "Warm plaza spotlight")


func _create_civic_details() -> void:
	_add_plaza_fountain(GRID_OFFSET + Vector3(-2.55, 0.055, -1.28), Color(0.35, 0.84, 1.0), "West promenade fountain")
	_add_plaza_fountain(GRID_OFFSET + Vector3(2.55, 0.055, 1.42), Color(1.0, 0.68, 0.42), "East promenade fountain")
	_add_civic_statue(GRID_OFFSET + Vector3(-2.56, 0.07, 2.68), materials.marble, Color(0.82, 0.9, 1.0), "Marble waterfront statue")
	_add_civic_statue(GRID_OFFSET + Vector3(2.56, 0.07, -2.78), materials.patina, Color(0.35, 0.92, 0.76), "Patina bronze statue")
	for z in [-4.9, -0.18, 4.62]:
		_add_planter_tree(GRID_OFFSET + Vector3(-2.56, 0.06, z), Color(0.26, 0.72, 0.36))
		_add_planter_tree(GRID_OFFSET + Vector3(2.56, 0.06, -z), Color(0.42, 0.8, 0.48))
	_add_perched_bird(GRID_OFFSET + Vector3(-2.56, 0.53, 2.68), Color(0.78, 0.82, 0.76), "Bird on marble statue")
	_add_perched_bird(GRID_OFFSET + Vector3(2.55, 0.31, 1.42), Color(0.18, 0.2, 0.24), "Bird by warm fountain")
	_add_street_animal(GRID_OFFSET + Vector3(-2.45, 0.07, 3.65), GRID_OFFSET + Vector3(-2.45, 0.07, 4.35), Color(0.5, 0.36, 0.2), 5.2, "Small plaza dog")
	_add_street_animal(GRID_OFFSET + Vector3(2.42, 0.07, -3.65), GRID_OFFSET + Vector3(2.46, 0.07, -4.38), Color(0.72, 0.72, 0.66), 4.6, "Small shop animal")


func _create_city_life() -> void:
	var car_colors: Array[Color] = [
		Color(0.92, 0.22, 0.18),
		Color(0.12, 0.58, 0.95),
		Color(1.0, 0.78, 0.28),
		Color(0.84, 0.88, 0.78),
		Color(0.2, 0.86, 0.62),
	]
	for i in range(9):
		var lane_x := -1.49 if i % 2 == 0 else 1.49
		var z_a := -6.05 + float(i % 3) * 0.32
		var z_b := 6.05 - float(i % 4) * 0.24
		_add_moving_car(GRID_OFFSET + Vector3(lane_x, 0.07, z_a), GRID_OFFSET + Vector3(lane_x, 0.07, z_b), car_colors[i % car_colors.size()], 4.8 + float(i) * 0.65)
	for i in range(6):
		var z := -5.55 + float(i) * 2.1
		_add_moving_car(GRID_OFFSET + Vector3(-2.3, 0.075, z), GRID_OFFSET + Vector3(4.95, 0.075, z), car_colors[(i + 2) % car_colors.size()], 5.4 + float(i) * 0.5, true)
	for i in range(26):
		var side_x := -2.05 if i % 2 == 0 else 2.05
		var z_start := -5.8 + float(i % 8) * 1.42
		var z_end := z_start + randf_range(0.55, 1.45)
		_add_pedestrian(GRID_OFFSET + Vector3(side_x + randf_range(-0.08, 0.08), 0.06, z_start), GRID_OFFSET + Vector3(side_x + randf_range(-0.08, 0.08), 0.06, z_end), Color.from_hsv(randf(), 0.45, 0.95), 2.2 + randf() * 2.0)
	for i in range(8):
		var x := -3.85 if i % 2 == 0 else 5.2
		var z0 := -6.2 + float(i) * 1.7
		_add_boat(GRID_OFFSET + Vector3(x, 0.02, z0), GRID_OFFSET + Vector3(x, 0.02, -z0), 8.5 + float(i) * 0.7)
	for z in [-4.15, -1.92, 1.98, 4.15]:
		_add_crosswalk(GRID_OFFSET + Vector3(-1.36, 0.035, z))
		_add_crosswalk(GRID_OFFSET + Vector3(1.36, 0.035, z))
	_add_bird_flock(GRID_OFFSET + Vector3(-3.8, 2.35, -5.2), GRID_OFFSET + Vector3(5.4, 2.15, 5.7), 9.5)
	_add_bird_flock(GRID_OFFSET + Vector3(5.25, 2.6, -4.4), GRID_OFFSET + Vector3(-3.7, 2.25, 4.8), 11.0)
	_add_street_animal(GRID_OFFSET + Vector3(-2.06, 0.07, -2.1), GRID_OFFSET + Vector3(-2.06, 0.07, -0.6), Color(0.24, 0.18, 0.12), 4.8, "Small sidewalk dog")
	_add_street_animal(GRID_OFFSET + Vector3(2.04, 0.07, 1.2), GRID_OFFSET + Vector3(2.02, 0.07, 2.35), Color(0.08, 0.08, 0.09), 5.6, "Small shop cat")


func _create_plots() -> void:
	var start_x := -((GRID_COLUMNS - 1) * CELL_SIZE) * 0.5
	var start_z := -((GRID_ROWS - 1) * CELL_SIZE) * 0.5
	var plot_index := 0
	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			var pos := GRID_OFFSET + Vector3(start_x + column * CELL_SIZE, 0.0, start_z + row * CELL_SIZE)
			_create_plot(plot_index, pos, (row + column) % 2 == 0)
			plot_index += 1


func _create_plot(index: int, pos: Vector3, alternate: bool) -> void:
	var root := Node3D.new()
	root.name = "Plot %02d" % [index + 1]
	root.position = pos
	city_root.add_child(root)

	var base_mat = materials.tile_alt if alternate else materials.tile
	_add_box(root, Vector3(0.0, 0.01, 0.0), Vector3(CELL_SIZE * 0.88, 0.08, CELL_SIZE * 0.88), base_mat, "Buildable pad")
	_add_box(root, Vector3(0.0, 0.075, -CELL_SIZE * 0.43), Vector3(CELL_SIZE * 0.86, 0.035, 0.035), materials.edge, "North edge")
	_add_box(root, Vector3(0.0, 0.075, CELL_SIZE * 0.43), Vector3(CELL_SIZE * 0.86, 0.035, 0.035), materials.edge, "South edge")
	_add_box(root, Vector3(-CELL_SIZE * 0.43, 0.075, 0.0), Vector3(0.035, 0.035, CELL_SIZE * 0.86), materials.edge, "West edge")
	_add_box(root, Vector3(CELL_SIZE * 0.43, 0.075, 0.0), Vector3(0.035, 0.035, CELL_SIZE * 0.86), materials.edge, "East edge")

	var area := Area3D.new()
	area.name = "Touch area"
	area.position = Vector3(0.0, 0.36, 0.0)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(CELL_SIZE * 0.9, 0.72, CELL_SIZE * 0.9)
	shape.shape = box_shape
	area.add_child(shape)
	area.input_event.connect(_on_plot_input.bind(index))
	root.add_child(area)

	var label := Label3D.new()
	label.name = "Plot label"
	label.text = "Пусто"
	label.font_size = 28
	label.pixel_size = 0.016
	label.modulate = Color(0.68, 0.82, 0.95, 0.72)
	label.outline_size = 8
	label.position = Vector3(0.0, 0.13, CELL_SIZE * 0.29)
	label.rotation_degrees = Vector3(-68.0, 0.0, 0.0)
	root.add_child(label)

	plots.append({"root": root, "position": pos, "label": label, "building": null})


func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Mobile isometric camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.75
	camera.position = Vector3(5.05, 8.6, 7.85)
	camera.current = true
	add_child(camera)
	camera.look_at(GRID_OFFSET + Vector3(-1.05, 0.0, 0.0), Vector3.UP)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Mobile UI"
	add_child(canvas)

	var root := Control.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	canvas.add_child(root)

	var side_panel := PanelContainer.new()
	side_panel.name = "Build menu"
	side_panel.anchor_bottom = 1.0
	side_panel.offset_left = 10.0
	side_panel.offset_top = 18.0
	side_panel.offset_right = MENU_WIDTH
	side_panel.offset_bottom = -18.0
	side_panel.add_theme_stylebox_override("panel", _style_box(Color(0.045, 0.055, 0.078, 0.88), Color(0.26, 0.7, 1.0, 0.34), 8))
	root.add_child(side_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 9)
	menu_margin.add_theme_constant_override("margin_top", 12)
	menu_margin.add_theme_constant_override("margin_right", 9)
	menu_margin.add_theme_constant_override("margin_bottom", 12)
	side_panel.add_child(menu_margin)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	menu_margin.add_child(menu)

	var title := Label.new()
	title.text = "Aurum City"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	menu.add_child(title)

	coin_label = Label.new()
	coin_label.add_theme_font_size_override("font_size", 15)
	coin_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	menu.add_child(coin_label)

	income_label = Label.new()
	income_label.add_theme_font_size_override("font_size", 13)
	income_label.add_theme_color_override("font_color", Color(0.62, 0.95, 0.8))
	menu.add_child(income_label)

	selected_label = Label.new()
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.add_theme_font_size_override("font_size", 12)
	selected_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	menu.add_child(selected_label)

	var bonus_row := HBoxContainer.new()
	bonus_row.add_theme_constant_override("separation", 6)
	menu.add_child(bonus_row)

	var speed_button := Button.new()
	speed_button.text = "TEST +50M"
	speed_button.focus_mode = Control.FOCUS_NONE
	speed_button.custom_minimum_size = Vector2(0.0, 36.0)
	speed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_button.add_theme_font_size_override("font_size", 12)
	speed_button.pressed.connect(_add_test_money)
	bonus_row.add_child(speed_button)

	var clear_button := Button.new()
	clear_button.text = "CLEAR"
	clear_button.focus_mode = Control.FOCUS_NONE
	clear_button.custom_minimum_size = Vector2(0.0, 36.0)
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.add_theme_font_size_override("font_size", 12)
	clear_button.pressed.connect(_clear_city)
	bonus_row.add_child(clear_button)

	var scroll := ScrollContainer.new()
	scroll.name = "Building list"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 7)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for i in range(building_data.size()):
		var button := Button.new()
		button.name = "Building %02d" % [i + 1]
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(136.0, 54.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_select_building.bind(i))
		list.add_child(button)
		building_buttons.append(button)

	status_label = Label.new()
	status_label.text = "Тапни клетку"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.86, 0.93, 1.0))
	menu.add_child(status_label)

	var build_badge := PanelContainer.new()
	build_badge.name = "Income toast"
	build_badge.anchor_left = 1.0
	build_badge.anchor_top = 0.0
	build_badge.anchor_right = 1.0
	build_badge.anchor_bottom = 0.0
	build_badge.offset_left = -220.0
	build_badge.offset_top = 22.0
	build_badge.offset_right = -16.0
	build_badge.offset_bottom = 92.0
	build_badge.add_theme_stylebox_override("panel", _style_box(Color(0.04, 0.055, 0.075, 0.72), Color(0.88, 0.95, 1.0, 0.18), 8))
	root.add_child(build_badge)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", 12)
	badge_margin.add_theme_constant_override("margin_top", 9)
	badge_margin.add_theme_constant_override("margin_right", 12)
	badge_margin.add_theme_constant_override("margin_bottom", 9)
	build_badge.add_child(badge_margin)

	var badge_text := Label.new()
	badge_text.name = "Badge text"
	badge_text.text = "1 сек = 1 час\nдоход идет сам"
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.add_theme_font_size_override("font_size", 13)
	badge_text.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	badge_margin.add_child(badge_text)


func _on_plot_input(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int, plot_index: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_try_build(plot_index)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_try_build(plot_index)


func _try_build(plot_index: int) -> void:
	var data = building_data[selected_building]
	var cost := float(data.cost)
	if coins < cost:
		_set_status("Нужно " + _format_amount(cost) + " монет")
		_pulse_label(coin_label, Color(1.0, 0.38, 0.38))
		return

	coins -= cost
	_place_building(plot_index, selected_building)
	_set_status("Построено: " + str(data.name))
	_refresh_hud()


func _fill_showcase_city() -> void:
	for i in range(min(plots.size(), building_data.size())):
		_place_building(i, i)
	coins = max(coins, 50000000.0)
	_refresh_hud()


func _place_building(plot_index: int, building_index: int) -> void:
	var plot = plots[plot_index]
	var data = building_data[building_index]
	if plot.building != null and is_instance_valid(plot.building):
		plot.building.queue_free()

	var holder := Node3D.new()
	holder.name = "Built " + str(building_data[building_index].name)
	holder.position = plot.position + Vector3(0.0, 0.12, 0.0)
	city_root.add_child(holder)
	_add_box(holder, Vector3(0.0, -0.005, 0.0), Vector3(CELL_SIZE * 0.68, 0.018, CELL_SIZE * 0.68), _make_material(Color(0.0, 0.0, 0.0, 0.3), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.55, 0.3), "Soft contact shadow")
	var edge_mat := _make_material(Color(0.12, 0.13, 0.14), data.color, 0.1, 0.0, 0.34)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(holder, Vector3(sx * CELL_SIZE * 0.34, 0.045, sz * CELL_SIZE * 0.34), Vector3(0.18, 0.024, 0.18), edge_mat, "Subtle plot corner pin")

	match building_index:
		0:
			_build_capsule(holder, building_index)
		1:
			_build_solar_loft(holder, building_index)
		2:
			_build_neon_market(holder, building_index)
		3:
			_build_data_tower(holder, building_index)
		4:
			_build_biodome(holder, building_index)
		5:
			_build_transit_hub(holder, building_index)
		6:
			_build_crystal_reactor(holder, building_index)
		7:
			_build_sky_garden(holder, building_index)
		8:
			_build_quantum_spire(holder, building_index)
		_:
			_build_mega_core(holder, building_index)

	var income_tag := Label3D.new()
	income_tag.text = "+" + _format_amount(data.income) + "/h"
	income_tag.font_size = 18
	income_tag.pixel_size = 0.0065
	income_tag.outline_size = 4
	income_tag.modulate = Color(1.0, 0.9, 0.55, 0.62)
	income_tag.position = Vector3(0.0, 0.12, CELL_SIZE * 0.46)
	income_tag.rotation_degrees = Vector3(-66.0, 0.0, 0.0)
	holder.add_child(income_tag)

	plot.building = holder
	plot.label.text = ""
	placed[plot_index] = building_index
	_spawn_build_fx(holder.global_position, data.color)
	_pop_in(holder)


func _build_imported_landmark(parent: Node3D, index: int, path: String, scale_value: float, sign_text: String, height: float, accent_mat: Material, yaw_degrees := 0.0) -> void:
	var accent: Color = building_data[index].color
	_add_cylinder(parent, Vector3(0.0, 0.045, 0.0), 0.82, 0.06, materials.dark_metal, 48, "Imported landmark base ring")
	_add_asset_scene(parent, path, Vector3(0.0, 0.035, 0.0), scale_value, yaw_degrees, "Kenney city model " + sign_text)
	_add_restored_pbr_skin(parent, index, height, accent_mat)
	_add_box(parent, Vector3(0.0, 0.08, 0.64), Vector3(1.08, 0.06, 0.045), accent_mat, sign_text + " reflective lobby strip")
	_add_rooftop_sign(parent, sign_text, Vector3(0.0, height + 0.14, 0.45), accent)
	_add_light(parent, Vector3(0.0, min(height * 0.7, 1.9), 0.28), accent, 0.26, 2.1)


func _add_restored_pbr_skin(parent: Node3D, index: int, height: float, accent_mat: Material) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var accent: Color = building_data[index].color
	var skins := [
		{"panel": materials.porcelain, "trim": materials.bronze, "glass": materials.glass_peacock, "light": materials.lit_cool},
		{"panel": materials.mega_gold, "trim": materials.solar_panel, "glass": materials.glass_champagne, "light": materials.lit_warm},
		{"panel": materials.brick, "trim": materials.rose_gold, "glass": materials.glass_garnet, "light": materials.lit_rose},
		{"panel": materials.carbon, "trim": materials.black_glass, "glass": materials.glass_sapphire, "light": materials.lit_cool},
		{"panel": materials.moss, "trim": materials.patina, "glass": materials.glass_jade, "light": materials.lit_green},
		{"panel": materials.copper, "trim": materials.bronze, "glass": materials.glass_champagne, "light": materials.lit_warm},
		{"panel": materials.granite, "trim": materials.crystal, "glass": materials.glass_violet, "light": materials.lit_cool},
		{"panel": materials.marble, "trim": materials.pearl, "glass": materials.glass_ice, "light": materials.lit_green},
		{"panel": materials.obsidian, "trim": materials.quantum, "glass": materials.black_glass, "light": materials.lit_cool},
		{"panel": materials.mega_gold, "trim": materials.rose_gold, "glass": materials.glass_champagne, "light": materials.lit_warm},
	]
	var skin: Dictionary = skins[index % skins.size()]
	var panel_mat: Material = skin["panel"]
	var trim_mat: Material = skin["trim"]
	var glass_mat: Material = skin["glass"]
	var light_mat: Material = skin["light"]
	var facade_height: float = clampf(height * 0.5, 0.72, 1.5)
	var facade_y: float = 0.34 + facade_height * 0.5
	var front_z: float = 0.69
	var mullion_rows: int = maxi(5, int(facade_height * 7.0))
	var window_rows: int = maxi(4, int(facade_height * 6.0))
	var restored_light_y: float = clampf(height * 0.72, 0.75, 2.1)

	_add_box(parent, Vector3(-0.38, facade_y, front_z), Vector3(0.16, facade_height, 0.032), glass_mat, "Restored reflective glass facade")
	_add_box(parent, Vector3(0.38, facade_y, front_z), Vector3(0.16, facade_height * 0.92, 0.032), panel_mat, "Restored textured material facade")
	_add_box(parent, Vector3(0.0, 0.155, front_z + 0.008), Vector3(0.98, 0.08, 0.038), trim_mat, "Restored premium metal lobby trim")
	_add_box(parent, Vector3(0.0, height + 0.035, -0.02), Vector3(0.72, 0.07, 0.58), trim_mat, "Restored reflective roof cap")
	_add_facade_grid(parent, Vector3(0.0, facade_y, front_z + 0.035), 0.82, facade_height * 0.82, 4, mullion_rows, accent_mat, "Restored material mullions")
	_add_lit_windows(parent, Vector3(0.0, facade_y, front_z + 0.062), 0.72, facade_height * 0.72, 4, window_rows, light_mat, 0.46, "Restored individual window light")
	_add_glass_sheen(parent, Vector3(-0.16, facade_y + 0.04, front_z + 0.07), 0.16, facade_height * 0.82, accent, -18.0 + float(index % 4) * 12.0)
	_add_light(parent, Vector3(0.0, restored_light_y, 0.74), accent, 0.28, 2.3)

	match index:
		1:
			_add_tilted_solar_panel(parent, Vector3(-0.28, height + 0.16, -0.05), 0.36, 0.5, -18.0, accent)
			_add_tilted_solar_panel(parent, Vector3(0.28, height + 0.16, -0.05), 0.36, 0.5, -18.0, accent)
		4:
			var dome := _add_sphere(parent, Vector3(0.0, height + 0.18, 0.0), 0.3, materials.bio_glass, 32, "Restored bioglass roof dome")
			dome.scale.y = 0.38
		6:
			var crystal := _add_cylinder(parent, Vector3(0.0, height + 0.26, 0.0), 0.12, 0.44, materials.crystal, 6, "Restored crystal prism")
			crystal.rotation_degrees.y = 30.0
			_add_light(parent, Vector3(0.0, height + 0.38, 0.0), accent, 0.4, 2.0)
		8:
			var ring := _add_torus(parent, Vector3(0.0, height + 0.2, 0.0), 0.38, 0.018, materials.quantum, "Restored quantum reflection ring")
			ring.rotation_degrees.x = 90.0
			_spin_node(ring, 5.5)
		9:
			_add_sphere(parent, Vector3(0.0, height + 0.24, 0.0), 0.16, materials.mega_gold, 32, "Restored gold beacon")
			_add_light(parent, Vector3(0.0, height + 0.36, 0.0), Color(1.0, 0.74, 0.32), 0.46, 2.4)


func _build_capsule(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-a.glb", 1.02, "ATLAS", 1.36, materials.glass_peacock)
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.1, 0.0), Vector3(1.25, 0.2, 1.02), materials.bronze, "Bronze deco podium")
	_add_box(parent, Vector3(0.0, 0.45, 0.0), Vector3(1.02, 0.48, 0.82), materials.concrete, "Limestone lobby block")
	_add_box(parent, Vector3(0.0, 1.25, 0.0), Vector3(0.82, 1.18, 0.64), materials.glass_peacock, "Peacock reflective tower shaft")
	_add_box(parent, Vector3(0.0, 2.03, 0.0), Vector3(0.58, 0.38, 0.48), materials.glass_ice, "Icy crown setback")
	_add_box(parent, Vector3(0.0, 2.3, 0.0), Vector3(0.38, 0.18, 0.34), materials.bronze, "Bronze art deco cap")
	_add_facade_grid(parent, Vector3(0.0, 1.25, 0.335), 0.72, 1.05, 5, 10, _accent_material(Color(0.72, 0.95, 1.0), 0.32), "Deco glass mullions")
	_add_lit_windows(parent, Vector3(0.0, 1.25, 0.365), 0.66, 0.98, 4, 9, materials.lit_cool, 0.42, "Atlas office window")
	_add_glass_sheen(parent, Vector3(-0.08, 1.34, 0.35), 0.18, 1.15, accent, -17.0)
	_add_roof_equipment(parent, Vector3(0.0, 2.43, -0.04), accent)
	_add_rooftop_sign(parent, "ATLAS", Vector3(0.0, 2.49, 0.31), accent)
	_add_light(parent, Vector3(0.0, 2.15, 0.0), accent, 0.22, 1.9)


func _build_solar_loft(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-a.glb", 0.62, "SOLAR", 1.82, materials.mega_gold)
	return
	_add_tilted_solar_panel(parent, Vector3(-0.27, 1.96, -0.08), 0.42, 0.58, -18.0, building_data[index].color)
	_add_tilted_solar_panel(parent, Vector3(0.27, 1.96, -0.08), 0.42, 0.58, -18.0, building_data[index].color)
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.13, 0.0), Vector3(1.22, 0.26, 0.96), materials.pearl, "Pearl ceramic podium")
	_add_box(parent, Vector3(0.0, 0.92, 0.0), Vector3(0.9, 1.38, 0.72), materials.glass_champagne, "Champagne glass solar tower")
	_add_box(parent, Vector3(0.0, 1.7, 0.0), Vector3(0.74, 0.12, 0.64), materials.mega_gold, "Gold mechanical crown tray")
	_add_tilted_solar_panel(parent, Vector3(-0.28, 1.92, -0.03), 0.5, 0.82, -18.0, accent)
	_add_tilted_solar_panel(parent, Vector3(0.28, 1.92, -0.03), 0.5, 0.82, -18.0, accent)
	_add_facade_grid(parent, Vector3(0.0, 0.92, 0.375), 0.78, 1.2, 4, 11, _accent_material(Color(1.0, 0.78, 0.34), 0.25), "Champagne facade seams")
	_add_lit_windows(parent, Vector3(0.0, 0.92, 0.405), 0.7, 1.1, 4, 10, materials.lit_warm, 0.5, "Solar tower warm apartments")
	_add_glass_sheen(parent, Vector3(0.1, 1.0, 0.39), 0.16, 1.1, Color(1.0, 0.88, 0.46), 18.0)
	_add_roof_equipment(parent, Vector3(0.0, 1.76, 0.27), accent)
	var orb := _add_sphere(parent, Vector3(0.0, 2.36, 0.0), 0.14, _accent_material(accent, 1.1), 28, "Quiet solar beacon")
	_pulse_node(orb, 2.8, 1.08)
	_add_light(parent, Vector3(0.0, 1.8, 0.0), accent, 0.3, 2.1)


func _build_neon_market(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-f.glb", 0.96, "VELVET", 1.66, materials.rose_gold)
	return
	for y in [0.42, 0.62, 0.82]:
		_add_box(parent, Vector3(0.0, y, 0.67), Vector3(0.82, 0.028, 0.035), _accent_material(building_data[index].color, 0.65), "Imported theater neon strip")
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.18, 0.0), Vector3(1.28, 0.36, 0.98), materials.brick, "Brick landmark podium")
	_add_brick_relief(parent, Vector3(0.0, 0.2, 0.505), 1.1, 0.28, 6, 4)
	_add_box(parent, Vector3(0.0, 0.98, 0.0), Vector3(0.74, 1.42, 0.58), materials.glass_garnet, "Garnet glass hotel shaft")
	_add_box(parent, Vector3(0.0, 1.78, 0.0), Vector3(0.5, 0.28, 0.44), materials.rose_gold, "Rose gold crown")
	_add_facade_grid(parent, Vector3(0.0, 0.98, 0.305), 0.64, 1.25, 4, 12, _accent_material(Color(1.0, 0.38, 0.62), 0.35), "Garnet window mullions")
	_add_lit_windows(parent, Vector3(0.0, 0.98, 0.335), 0.58, 1.12, 4, 11, materials.lit_rose, 0.54, "Hotel rose room light")
	_add_rooftop_sign(parent, "VELVET", Vector3(0.0, 1.98, 0.29), accent)
	for y in [0.42, 0.64, 0.86]:
		_add_box(parent, Vector3(0.0, y, 0.49), Vector3(1.0, 0.035, 0.04), _accent_material(accent, 0.85), "Animated theater strip")
	_add_glass_sheen(parent, Vector3(-0.07, 1.04, 0.32), 0.15, 1.15, accent, -24.0)
	_add_particles(parent, Vector3(0.0, 1.85, 0.0), accent, 18)
	_add_light(parent, Vector3(0.0, 1.35, 0.0), accent, 0.3, 2.0)


func _build_data_tower(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-b.glb", 0.52, "NODE", 2.38, materials.glass_sapphire)
	return
	_add_facade_grid(parent, Vector3(0.0, 1.24, 0.69), 0.58, 1.64, 4, 13, _accent_material(building_data[index].color, 0.32), "Imported data light ribs")
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.13, 0.0), Vector3(1.02, 0.26, 0.9), materials.black_glass, "Black glass server podium")
	_add_box(parent, Vector3(-0.18, 1.0, 0.0), Vector3(0.52, 1.48, 0.56), materials.glass_sapphire, "Sapphire data tower A")
	_add_box(parent, Vector3(0.25, 1.24, 0.0), Vector3(0.42, 1.9, 0.48), materials.data_glass, "Circuit data tower B")
	_add_facade_grid(parent, Vector3(-0.18, 1.0, 0.29), 0.44, 1.32, 4, 13, _accent_material(accent, 0.44), "Sapphire physical window grid")
	_add_facade_grid(parent, Vector3(0.25, 1.24, 0.25), 0.36, 1.72, 3, 16, _accent_material(Color(0.18, 0.86, 1.0), 0.58), "Circuit physical window grid")
	_add_box(parent, Vector3(0.25, 2.27, 0.0), Vector3(0.28, 0.16, 0.3), _accent_material(accent, 0.8), "Data crown beacon")
	_add_lit_windows(parent, Vector3(-0.18, 1.0, 0.318), 0.38, 1.2, 3, 12, materials.lit_cool, 0.48, "Data cool server windows")
	_add_lit_windows(parent, Vector3(0.25, 1.24, 0.28), 0.3, 1.58, 3, 14, materials.lit_cool, 0.6, "Data vertical server lights")
	_add_roof_equipment(parent, Vector3(-0.02, 2.34, -0.03), accent)
	_add_rooftop_sign(parent, "NODE", Vector3(0.0, 2.45, 0.25), accent)
	_add_glass_sheen(parent, Vector3(0.2, 1.32, 0.27), 0.14, 1.5, Color(0.5, 0.84, 1.0), 16.0)
	_add_particles(parent, Vector3(0.0, 2.0, 0.0), accent, 28)
	_add_light(parent, Vector3(0.0, 1.6, 0.0), accent, 0.42, 2.6)


func _build_biodome(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-m.glb", 0.72, "BIOME", 2.32, materials.glass_jade)
	return
	var imported_dome := _add_sphere(parent, Vector3(0.0, 2.42, 0.0), 0.34, materials.bio_glass, 32, "Imported rooftop greenhouse dome")
	imported_dome.scale.y = 0.42
	return
	var accent: Color = building_data[index].color
	_add_cylinder(parent, Vector3(0.0, 0.14, 0.0), 0.74, 0.24, materials.obsidian, 48, "Obsidian eco podium")
	_add_box(parent, Vector3(0.0, 0.86, 0.0), Vector3(0.72, 1.2, 0.58), materials.glass_jade, "Jade glass living tower")
	for level in range(5):
		var y := 0.38 + float(level) * 0.28
		var scale := 1.0 - float(level) * 0.06
		_add_cylinder(parent, Vector3(0.0, y, 0.0), 0.5 * scale, 0.05, materials.moss, 36, "Hanging garden ring")
		for i in range(4):
			var angle := TAU * float(i) / 4.0 + float(level) * 0.42
			_add_sphere(parent, Vector3(cos(angle) * 0.42 * scale, y + 0.055, sin(angle) * 0.42 * scale), 0.07, materials.leaf, 10, "Sky shrub")
	var dome := _add_sphere(parent, Vector3(0.0, 1.62, 0.0), 0.46, materials.bio_glass, 42, "Jade rooftop greenhouse")
	dome.scale.y = 0.42
	_add_facade_grid(parent, Vector3(0.0, 0.9, 0.305), 0.62, 1.08, 4, 10, _accent_material(accent, 0.32), "Eco glass ribs")
	_add_lit_windows(parent, Vector3(0.0, 0.9, 0.334), 0.5, 0.94, 3, 8, materials.lit_green, 0.38, "Eco biolab glow")
	var scan := _add_torus(parent, Vector3(0.0, 1.62, 0.0), 0.48, 0.01, _hologram_material(accent), "Slow greenhouse scan")
	scan.rotation_degrees.x = 90.0
	_spin_node(scan, 6.2)
	_add_light(parent, Vector3(0.0, 1.35, 0.0), accent, 0.32, 2.4)


func _build_transit_hub(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-c.glb", 0.58, "LOOP", 2.42, materials.bronze)
	return
	var imported_track := _add_torus(parent, Vector3(0.0, 2.56, 0.0), 0.44, 0.022, _make_material(Color(0.9, 0.42, 0.18), building_data[index].color, 0.12, 0.78, 0.18), "Imported station sky rail")
	imported_track.rotation_degrees.x = 90.0
	return
	var accent: Color = building_data[index].color
	_add_cylinder(parent, Vector3(0.0, 0.13, 0.0), 0.78, 0.22, materials.copper, 64, "Polished copper station base")
	_add_box(parent, Vector3(0.0, 0.82, 0.0), Vector3(0.7, 1.18, 0.6), materials.bronze, "Bronze transit tower")
	_add_box(parent, Vector3(0.0, 1.48, 0.0), Vector3(0.52, 0.34, 0.48), materials.glass_champagne, "Glass observation crown")
	_add_facade_grid(parent, Vector3(0.0, 0.82, 0.31), 0.58, 1.04, 4, 9, _accent_material(Color(1.0, 0.56, 0.28), 0.28), "Bronze station fins")
	_add_lit_windows(parent, Vector3(0.0, 0.82, 0.34), 0.46, 0.9, 3, 8, materials.lit_warm, 0.46, "Transit warm office windows")
	var track := _add_torus(parent, Vector3(0.0, 1.86, 0.0), 0.58, 0.026, _make_material(Color(0.9, 0.42, 0.18), accent, 0.18, 0.78, 0.12), "Elevated transit ring")
	track.rotation_degrees.x = 90.0
	var shuttle_pivot := Node3D.new()
	shuttle_pivot.name = "Animated shuttle pivot"
	shuttle_pivot.position = Vector3(0.0, 1.86, 0.0)
	parent.add_child(shuttle_pivot)
	_add_box(shuttle_pivot, Vector3(0.58, 0.0, 0.0), Vector3(0.3, 0.1, 0.16), materials.pearl, "Aerial shuttle pod")
	_add_rooftop_sign(parent, "LOOP", Vector3(0.0, 1.72, 0.34), accent)
	_spin_node(shuttle_pivot, 2.4)
	_add_light(parent, Vector3(0.0, 1.4, 0.0), accent, 0.36, 2.4)


func _build_crystal_reactor(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-e.glb", 0.62, "CRYSTL", 2.58, materials.glass_violet)
	return
	_add_cylinder(parent, Vector3(0.0, 2.78, 0.0), 0.16, 0.2, materials.crystal, 6, "Imported crystal roof prism")
	return
	var accent: Color = building_data[index].color
	_add_cylinder(parent, Vector3(0.0, 0.14, 0.0), 0.68, 0.24, materials.obsidian, 6, "Obsidian hex foundation")
	_add_cylinder(parent, Vector3(0.0, 0.38, 0.0), 0.48, 0.2, materials.carbon, 6, "Carbon crystal seat")
	var crystal := _add_cylinder(parent, Vector3(0.0, 1.18, 0.0), 0.34, 1.76, materials.crystal, 6, "Amethyst crystal skyscraper")
	crystal.rotation_degrees.y = 30.0
	_add_cylinder(parent, Vector3(0.0, 2.08, 0.0), 0.08, 0.18, _accent_material(accent, 1.0), 6, "Crystal lit cap")
	for angle_i in range(6):
		var angle := TAU * float(angle_i) / 6.0
		_add_cylinder(parent, Vector3(cos(angle) * 0.55, 0.46, sin(angle) * 0.55), 0.05, 0.42, materials.glass_violet, 5, "Small crystal shard")
	for y in [0.78, 1.08, 1.38, 1.68]:
		_add_box(parent, Vector3(0.0, y, 0.305), Vector3(0.36, 0.035, 0.026), materials.lit_rose, "Crystal interior refraction band")
	var refraction_band := _add_torus(parent, Vector3(0.0, 1.18, 0.0), 0.46, 0.012, _hologram_material(accent), "Single crystal refraction band")
	refraction_band.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_spin_node(refraction_band, 5.0)
	_pulse_node(crystal, 2.4, 1.04)
	_add_particles(parent, Vector3(0.0, 1.6, 0.0), accent, 36)
	_add_light(parent, Vector3(0.0, 1.4, 0.0), accent, 0.58, 3.0)


func _build_sky_garden(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-k.glb", 0.86, "VERDE", 2.0, materials.marble)
	return
	for angle_i in range(5):
		var angle := TAU * float(angle_i) / 5.0
		_add_sphere(parent, Vector3(cos(angle) * 0.56, 1.18 + float(angle_i % 2) * 0.16, sin(angle) * 0.48), 0.1, materials.leaf, 12, "Imported balcony tree")
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.15, 0.0), Vector3(1.18, 0.3, 0.96), materials.marble, "Marble garden podium")
	_add_marble_veins(parent, Vector3(0.0, 0.18, 0.51), 1.04, 0.22)
	_add_box(parent, Vector3(0.0, 0.92, 0.0), Vector3(0.62, 1.32, 0.52), materials.glass_ice, "Opal glass garden tower core")
	_add_lit_windows(parent, Vector3(0.0, 0.92, 0.28), 0.44, 1.04, 3, 8, materials.lit_green, 0.36, "Garden greenhouse interior")
	for level in range(5):
		var y := 0.38 + level * 0.34
		var scale := 1.08 - level * 0.12
		var platform_mat: Material = materials.moss if level % 2 == 0 else materials.marble
		var platform := _add_cylinder(parent, Vector3(0.0, y, 0.0), 0.72 * scale, 0.12, platform_mat, 32, "Garden platform")
		platform.rotation_degrees.y = level * 16.0
		for i in range(4):
			var angle := TAU * (float(i) / 4.0) + level * 0.3
			_add_sphere(parent, Vector3(cos(angle) * 0.42 * scale, y + 0.13, sin(angle) * 0.42 * scale), 0.1, materials.leaf, 12, "Rounded shrub")
	_add_cylinder(parent, Vector3(0.0, 1.02, 0.0), 0.06, 1.64, materials.rose_gold, 12, "Rose gold garden spine")
	var cloud := _add_sphere(parent, Vector3(0.0, 2.12, 0.0), 0.24, _make_material(Color(0.72, 0.98, 0.85, 0.46), accent, 0.7, 0.0, 0.08, 0.46), 20, "Mist crown")
	_pulse_node(cloud, 2.7, 1.06)
	_add_rooftop_sign(parent, "VERDE", Vector3(0.0, 2.0, 0.32), accent)
	_add_particles(parent, Vector3(0.0, 1.7, 0.0), accent, 26)
	_add_light(parent, Vector3(0.0, 1.55, 0.0), accent, 0.36, 2.5)


func _build_quantum_spire(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-d.glb", 0.52, "QUANT", 2.92, materials.black_glass)
	return
	for i in range(2):
		var ring := _add_torus(parent, Vector3(0.0, 1.36 + i * 0.58, 0.0), 0.38 + i * 0.08, 0.012, _hologram_material(building_data[index].color), "Imported controlled quantum ring")
		ring.rotation_degrees = Vector3(82.0, i * 38.0, 0.0)
		_spin_node(ring, 4.4 + i * 0.6)
	return
	var accent: Color = building_data[index].color
	_add_cylinder(parent, Vector3(0.0, 0.13, 0.0), 0.62, 0.24, materials.carbon, 12, "Carbon turbine base")
	_add_box(parent, Vector3(0.0, 0.72, 0.0), Vector3(0.58, 1.02, 0.5), materials.black_glass, "Black glass lower spire")
	_add_lit_windows(parent, Vector3(0.0, 0.72, 0.265), 0.42, 0.84, 3, 8, materials.lit_cool, 0.42, "Carbon tower inset light")
	var stem := _add_cylinder(parent, Vector3(0.0, 1.42, 0.0), 0.18, 1.72, materials.quantum, 18, "Teal refractive spire")
	_pulse_node(stem, 2.8, 1.035)
	_add_cylinder(parent, Vector3(0.0, 1.42, 0.0), 0.095, 1.48, _accent_material(accent, 0.9), 18, "Thick quantum light core")
	for i in range(2):
		var ring := _add_torus(parent, Vector3(0.0, 1.0 + i * 0.42, 0.0), 0.34 + i * 0.08, 0.012, _hologram_material(accent), "Controlled quantum orbit")
		ring.rotation_degrees = Vector3(82.0, i * 38.0, 0.0)
		_spin_node(ring, 3.6 + i * 0.6)
	_add_sphere(parent, Vector3(0.0, 2.4, 0.0), 0.16, _accent_material(accent, 1.6), 24, "Quantum roof core")
	_add_glass_sheen(parent, Vector3(0.0, 0.78, 0.265), 0.14, 0.82, Color(0.46, 1.0, 0.9), -28.0)
	_add_particles(parent, Vector3(0.0, 1.8, 0.0), accent, 36)
	_add_light(parent, Vector3(0.0, 1.6, 0.0), accent, 0.48, 3.0)


func _build_mega_core(parent: Node3D, index: int) -> void:
	_build_imported_landmark(parent, index, KENNEY_CITY + "building-skyscraper-d.glb", 0.58, "AURUM", 3.22, materials.mega_gold)
	return
	_add_cylinder(parent, Vector3(0.0, 3.38, 0.0), 0.14, 0.22, materials.mega_gold, 32, "Imported gold lantern roof")
	_add_sphere(parent, Vector3(0.0, 3.55, 0.0), 0.13, _accent_material(building_data[index].color, 1.2), 24, "Imported aurum beacon")
	return
	var accent: Color = building_data[index].color
	_add_box(parent, Vector3(0.0, 0.17, 0.0), Vector3(1.34, 0.34, 1.06), materials.marble, "Grand marble base")
	_add_marble_veins(parent, Vector3(0.0, 0.18, 0.545), 1.2, 0.26)
	_add_box(parent, Vector3(0.0, 0.98, 0.0), Vector3(0.92, 1.48, 0.72), materials.glass_champagne, "Champagne supertower glass")
	_add_box(parent, Vector3(0.0, 1.86, 0.0), Vector3(0.64, 0.56, 0.56), materials.mega_gold, "Brushed gold upper setback")
	_add_box(parent, Vector3(0.0, 2.26, 0.0), Vector3(0.44, 0.28, 0.44), _make_material(Color(1.0, 0.88, 0.44), accent, 0.32, 0.88, 0.1), "Radiant gold crown")
	_add_facade_grid(parent, Vector3(0.0, 0.98, 0.375), 0.82, 1.32, 5, 12, _accent_material(Color(1.0, 0.82, 0.32), 0.25), "Supertower mullions")
	_add_lit_windows(parent, Vector3(0.0, 0.98, 0.405), 0.72, 1.18, 5, 11, materials.lit_warm, 0.52, "Aurum luxury suites")
	_add_front_stripes(parent, Vector3(0.0, 1.86, 0.295), 0.54, 0.42, 5, _make_material(Color(1.0, 0.86, 0.28), Color(1.0, 0.76, 0.22), 0.08, 0.95, 0.1), 0.0, "Gold brush relief")
	_add_roof_equipment(parent, Vector3(0.0, 2.44, -0.05), accent)
	_add_cylinder(parent, Vector3(0.0, 2.54, 0.0), 0.13, 0.2, materials.mega_gold, 32, "Gold rooftop lantern base")
	var beacon := _add_sphere(parent, Vector3(0.0, 2.72, 0.0), 0.14, _accent_material(accent, 1.3), 24, "Beacon core")
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		var p := Vector3(cos(angle) * 0.54, 2.1, sin(angle) * 0.44)
		_add_box(parent, p, Vector3(0.1, 0.12, 0.16), _accent_material(accent, 0.9), "Corner jewel light")
	_add_rooftop_sign(parent, "AURUM", Vector3(0.0, 2.42, 0.29), accent)
	_add_glass_sheen(parent, Vector3(0.08, 1.0, 0.39), 0.15, 1.3, Color(1.0, 0.88, 0.52), -14.0)
	_add_particles(parent, Vector3(0.0, 2.3, 0.0), accent, 42)
	_pulse_node(beacon, 3.0, 1.06)
	_add_light(parent, Vector3(0.0, 2.0, 0.0), accent, 0.58, 3.4)


func _add_material_wall(parent: Node3D, pos: Vector3, width: float, height: float, mat: Material, accent: Color, label_text: String) -> void:
	_add_box(parent, pos, Vector3(width, height, 0.06), mat, label_text + " surface")
	_add_box(parent, pos + Vector3(0.0, height * 0.5 + 0.025, 0.04), Vector3(width + 0.08, 0.035, 0.055), materials.dark_metal, label_text + " top frame")
	_add_box(parent, pos + Vector3(-width * 0.5 - 0.025, 0.0, 0.04), Vector3(0.035, height + 0.05, 0.055), materials.dark_metal, label_text + " left frame")
	_add_box(parent, pos + Vector3(width * 0.5 + 0.025, 0.0, 0.04), Vector3(0.035, height + 0.05, 0.055), materials.dark_metal, label_text + " right frame")
	_add_material_tag(parent, label_text, pos + Vector3(0.0, -height * 0.5 - 0.085, 0.08), accent)


func _add_material_tag(parent: Node3D, text: String, pos: Vector3, color: Color) -> void:
	var tag := Label3D.new()
	tag.name = "Material tag " + text
	tag.text = text
	tag.font_size = 18
	tag.pixel_size = 0.006
	tag.outline_size = 5
	tag.modulate = Color(color.r, color.g, color.b, 0.72)
	tag.position = pos
	tag.rotation_degrees = Vector3(-64.0, 0.0, 0.0)
	parent.add_child(tag)


func _add_facade_grid(parent: Node3D, center: Vector3, width: float, height: float, columns: int, rows: int, mat: Material, mesh_name := "Facade grid") -> void:
	for column in range(columns + 1):
		var x := center.x - width * 0.5 + width * float(column) / float(columns)
		_add_box(parent, Vector3(x, center.y, center.z), Vector3(0.018, height, 0.028), mat, mesh_name + " vertical")
	for row in range(rows + 1):
		var y := center.y - height * 0.5 + height * float(row) / float(rows)
		_add_box(parent, Vector3(center.x, y, center.z), Vector3(width, 0.018, 0.028), mat, mesh_name + " horizontal")


func _add_brick_relief(parent: Node3D, center: Vector3, width: float, height: float, columns: int, rows: int) -> void:
	var mortar := _make_material(Color(0.11, 0.055, 0.04), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.88)
	for row in range(rows + 1):
		var y := center.y - height * 0.5 + height * float(row) / float(rows)
		_add_box(parent, Vector3(center.x, y, center.z), Vector3(width, 0.016, 0.032), mortar, "Raised brick mortar")
	for row in range(rows):
		var y := center.y - height * 0.5 + height * (float(row) + 0.5) / float(rows)
		var offset := 0.0
		if row % 2 == 1:
			offset = width / float(columns) * 0.5
		for column in range(columns + 1):
			var x := center.x - width * 0.5 + width * float(column) / float(columns) + offset
			if x > center.x - width * 0.5 + 0.04 and x < center.x + width * 0.5 - 0.04:
				_add_box(parent, Vector3(x, y, center.z), Vector3(0.016, height / float(rows) * 0.72, 0.032), mortar, "Raised brick joint")


func _add_front_stripes(parent: Node3D, center: Vector3, width: float, height: float, count: int, mat: Material, angle: float, mesh_name := "Front stripe") -> void:
	for i in range(count):
		var x := center.x - width * 0.5 + width * (float(i) + 0.5) / float(count)
		var stripe := _add_box(parent, Vector3(x, center.y, center.z), Vector3(width * 0.72, 0.018, 0.03), mat, mesh_name)
		stripe.rotation_degrees.z = angle


func _add_tilted_solar_panel(parent: Node3D, pos: Vector3, width: float, depth: float, rot_x: float, accent: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Tilted solar panel module"
	root.position = pos
	root.rotation_degrees.x = rot_x
	parent.add_child(root)
	_add_box(root, Vector3.ZERO, Vector3(width, 0.045, depth), materials.solar_panel, "Large gridded solar panel")
	var line_mat := _accent_material(accent, 0.7)
	for column in range(1, 4):
		var x := -width * 0.5 + width * float(column) / 4.0
		_add_box(root, Vector3(x, 0.035, 0.0), Vector3(0.018, 0.018, depth * 0.96), line_mat, "Physical solar seam")
	for row in range(1, 5):
		var z := -depth * 0.5 + depth * float(row) / 5.0
		_add_box(root, Vector3(0.0, 0.036, z), Vector3(width * 0.96, 0.018, 0.016), line_mat, "Physical solar seam")
	return root


func _add_marble_veins(parent: Node3D, center: Vector3, width: float, height: float) -> void:
	var vein_mat := _make_material(Color(0.24, 0.22, 0.2), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.62)
	for i in range(5):
		var x := center.x - width * 0.42 + width * float(i) / 4.0
		var y := center.y - height * 0.36 + height * float((i * 3) % 5) / 6.0
		var vein := _add_box(parent, Vector3(x, y, center.z), Vector3(width * 0.44, 0.014, 0.028), vein_mat, "Raised marble vein")
		vein.rotation_degrees.z = -26.0 + float(i) * 12.0


func _add_moving_car(pos_a: Vector3, pos_b: Vector3, color: Color, duration: float, horizontal := false) -> void:
	var root := Node3D.new()
	root.name = "Animated traffic car"
	root.position = pos_a
	if horizontal:
		root.rotation_degrees.y = 90.0
	city_root.add_child(root)
	var vehicle_paths := [
		KENNEY_CARS + "vehicle-suv.glb",
		KENNEY_CARS + "vehicle-speedster.glb",
		KENNEY_CARS + "vehicle-racer-low.glb",
		KENNEY_CARS + "vehicle-vintage-racer.glb",
		KENNEY_CARS + "vehicle-truck.glb",
	]
	var model_path: String = vehicle_paths[int(abs(pos_a.z * 10.0 + pos_a.x * 7.0)) % vehicle_paths.size()]
	_add_asset_scene(root, model_path, Vector3(0.0, 0.0, 0.0), 0.36, 0.0, "Kenney vehicle model")
	_add_box(root, Vector3(0.0, 0.05, -0.35), Vector3(0.13, 0.012, 0.22), materials.headlight_beam, "Soft imported car headlight reflection")
	_add_light(root, Vector3(0.0, 0.1, -0.26), Color(1.0, 0.86, 0.52), 0.12, 0.72)
	var tween := root.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position", pos_b, duration)
	tween.tween_property(root, "position", pos_a, duration)


func _add_pedestrian(pos_a: Vector3, pos_b: Vector3, color: Color, duration: float) -> void:
	var root := Node3D.new()
	root.name = "Animated pedestrian"
	root.position = pos_a
	city_root.add_child(root)
	var person_index := int(abs(pos_a.z * 11.0 + pos_a.x * 17.0)) % 8
	var character_codes := ["a", "b", "c", "d", "e", "f", "g", "h"]
	var character_code: String = character_codes[person_index]
	var person := _add_asset_scene(root, KENNEY_PEOPLE + "character-" + character_code + ".glb", Vector3(0.0, 0.0, 0.0), 0.078, 180.0 if pos_b.z < pos_a.z else 0.0, "Kenney pedestrian model")
	var bob := person.create_tween().set_loops()
	bob.set_trans(Tween.TRANS_SINE)
	bob.set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(person, "position:y", 0.016, 0.28)
	bob.tween_property(person, "position:y", 0.0, 0.28)
	var tween := root.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position", pos_b, duration)
	tween.tween_property(root, "position", pos_a, duration)


func _add_boat(pos_a: Vector3, pos_b: Vector3, duration: float) -> void:
	var root := Node3D.new()
	root.name = "Animated river boat"
	root.position = pos_a
	city_root.add_child(root)
	var boat_paths := [
		KENNEY_BOATS + "boat-speed-a.glb",
		KENNEY_BOATS + "boat-speed-d.glb",
		KENNEY_BOATS + "boat-tug-a.glb",
		KENNEY_BOATS + "boat-fishing-small.glb",
		KENNEY_BOATS + "boat-row-small.glb",
	]
	var model_path: String = boat_paths[int(abs(pos_a.z * 5.0 + pos_a.x * 13.0)) % boat_paths.size()]
	_add_asset_scene(root, model_path, Vector3(0.0, 0.0, 0.0), 0.22, 0.0, "Kenney boat model")
	_add_box(root, Vector3(0.0, 0.025, 0.42), Vector3(0.32, 0.014, 0.2), _make_material(Color(0.8, 0.95, 1.0, 0.22), Color(0.16, 0.8, 1.0), 0.06, 0.0, 0.12, 0.22), "Soft imported boat wake")
	var tween := root.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position", pos_b, duration)
	tween.tween_property(root, "position", pos_a, duration)


func _add_crosswalk(center: Vector3) -> void:
	var stripe_mat := _make_material(Color(0.82, 0.86, 0.82, 0.72), Color(1.0, 0.95, 0.76), 0.04, 0.0, 0.48, 0.72)
	for i in range(5):
		_add_box(city_root, center + Vector3(-0.16 + float(i) * 0.08, 0.0, 0.0), Vector3(0.038, 0.012, 0.34), stripe_mat, "Crosswalk stripe")


func _add_shopfront(pos: Vector3, title: String, accent: Color, body_color: Color) -> void:
	var root := Node3D.new()
	root.name = "Street shop " + title
	root.position = pos
	city_root.add_child(root)
	_add_box(root, Vector3(0.0, 0.11, 0.0), Vector3(0.58, 0.22, 0.28), _make_material(body_color, Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.54), "Shop body")
	_add_box(root, Vector3(0.0, 0.26, 0.0), Vector3(0.64, 0.08, 0.32), materials.awning, "Striped shop awning")
	_add_box(root, Vector3(-0.14, 0.13, 0.15), Vector3(0.16, 0.12, 0.025), materials.glass_ice, "Shop window left")
	_add_box(root, Vector3(0.14, 0.13, 0.15), Vector3(0.16, 0.12, 0.025), materials.glass_ice, "Shop window right")
	_add_rooftop_sign(root, title, Vector3(0.0, 0.34, 0.18), accent)
	_add_light(root, Vector3(0.0, 0.2, 0.24), accent, 0.16, 1.1)


func _add_city_furniture(pos: Vector3) -> void:
	_add_box(city_root, pos + Vector3(-0.08, 0.05, 0.0), Vector3(0.08, 0.1, 0.1), materials.trash_dark, "Street trash bin")
	_add_cylinder(city_root, pos + Vector3(0.08, 0.08, -0.08), 0.032, 0.16, _make_material(Color(0.72, 0.08, 0.06), Color(0.2, 0.0, 0.0), 0.02, 0.0, 0.38), 10, "Tiny hydrant")
	_add_box(city_root, pos + Vector3(0.12, 0.025, 0.1), Vector3(0.11, 0.008, 0.06), materials.paper, "Flat street litter paper")
	_add_box(city_root, pos + Vector3(-0.17, 0.07, 0.18), Vector3(0.28, 0.055, 0.06), _make_material(Color(0.28, 0.18, 0.1), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.56), "Wood bench seat")
	_add_box(city_root, pos + Vector3(-0.17, 0.12, 0.21), Vector3(0.28, 0.06, 0.035), _make_material(Color(0.2, 0.13, 0.08), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.6), "Wood bench back")


func _add_plaza_fountain(pos: Vector3, accent: Color, fountain_name: String) -> void:
	var root := Node3D.new()
	root.name = fountain_name
	root.position = pos
	city_root.add_child(root)
	_add_cylinder(root, Vector3(0.0, 0.045, 0.0), 0.28, 0.075, materials.granite, 48, fountain_name + " granite basin")
	_add_cylinder(root, Vector3(0.0, 0.095, 0.0), 0.21, 0.035, materials.fountain_water, 48, fountain_name + " reflective water")
	var ring := _add_torus(root, Vector3(0.0, 0.12, 0.0), 0.19, 0.012, _make_material(Color(accent.r, accent.g, accent.b, 0.46), accent, 0.2, 0.0, 0.08, 0.46), fountain_name + " water lip")
	ring.rotation_degrees.x = 90.0
	_add_sphere(root, Vector3(0.0, 0.19, 0.0), 0.055, materials.fountain_water, 16, fountain_name + " bubbling center")
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		_add_sphere(root, Vector3(cos(angle) * 0.13, 0.155, sin(angle) * 0.13), 0.032, materials.fountain_water, 12, fountain_name + " small water bubble")
	_add_light(root, Vector3(0.0, 0.18, 0.0), accent, 0.18, 1.25)


func _add_civic_statue(pos: Vector3, statue_mat: Material, accent: Color, statue_name: String) -> void:
	var root := Node3D.new()
	root.name = statue_name
	root.position = pos
	city_root.add_child(root)
	_add_box(root, Vector3(0.0, 0.04, 0.0), Vector3(0.34, 0.08, 0.28), materials.granite, statue_name + " plinth")
	_add_cylinder(root, Vector3(0.0, 0.14, 0.0), 0.095, 0.13, statue_mat, 16, statue_name + " round pedestal")
	_add_cylinder(root, Vector3(0.0, 0.28, 0.0), 0.052, 0.22, statue_mat, 12, statue_name + " abstract figure")
	_add_sphere(root, Vector3(0.0, 0.43, 0.0), 0.065, statue_mat, 16, statue_name + " sculpture head")
	var sash := _add_box(root, Vector3(0.0, 0.31, 0.045), Vector3(0.18, 0.035, 0.035), _make_material(Color(accent.r * 0.62, accent.g * 0.62, accent.b * 0.62), accent, 0.18, 0.25, 0.22), statue_name + " metal sash")
	sash.rotation_degrees.z = -22.0
	_add_light(root, Vector3(0.0, 0.23, 0.18), accent, 0.08, 0.8)


func _add_planter_tree(pos: Vector3, leaf_color: Color) -> void:
	var root := Node3D.new()
	root.name = "Promenade planter tree"
	root.position = pos
	city_root.add_child(root)
	_add_box(root, Vector3(0.0, 0.035, 0.0), Vector3(0.24, 0.07, 0.18), materials.granite, "Rectangular stone planter")
	_add_cylinder(root, Vector3(0.0, 0.18, 0.0), 0.022, 0.24, _make_material(Color(0.28, 0.17, 0.08), Color(0.0, 0.0, 0.0), 0.0, 0.0, 0.66), 8, "Tiny tree trunk")
	var leaves := _make_material(leaf_color, Color(leaf_color.r * 0.35, leaf_color.g * 0.7, leaf_color.b * 0.35), 0.04, 0.0, 0.72)
	_add_sphere(root, Vector3(0.0, 0.34, 0.0), 0.13, leaves, 12, "Tiny tree crown")
	_add_sphere(root, Vector3(-0.065, 0.3, 0.03), 0.08, leaves, 10, "Tiny tree side crown")
	_add_sphere(root, Vector3(0.07, 0.3, -0.03), 0.08, leaves, 10, "Tiny tree side crown")


func _add_perched_bird(pos: Vector3, color: Color, bird_name: String) -> void:
	var root := Node3D.new()
	root.name = bird_name
	root.position = pos
	city_root.add_child(root)
	_add_asset_scene(root, KENNEY_PETS + "animal-parrot.glb", Vector3.ZERO, 0.052, -35.0, "Kenney perched parrot model")


func _add_bird_flock(pos_a: Vector3, pos_b: Vector3, duration: float) -> void:
	var flock := Node3D.new()
	flock.name = "Animated bird flock"
	flock.position = pos_a
	city_root.add_child(flock)
	for i in range(7):
		_add_bird(flock, Vector3(float(i % 3) * 0.18, randf_range(-0.04, 0.08), float(i) * 0.09))
	var tween := flock.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flock, "position", pos_b, duration)
	tween.tween_property(flock, "position", pos_a, duration)


func _add_bird(parent: Node3D, pos: Vector3) -> void:
	var bird := Node3D.new()
	bird.name = "Kenney flying bird"
	bird.position = pos
	parent.add_child(bird)
	var model := _add_asset_scene(bird, KENNEY_PETS + "animal-parrot.glb", Vector3.ZERO, 0.052, 90.0, "Kenney parrot model")
	var tween := bird.create_tween().set_loops()
	tween.tween_property(model, "position:y", 0.035, 0.22)
	tween.parallel().tween_property(model, "rotation_degrees:z", 8.0, 0.22)
	tween.tween_property(model, "position:y", -0.005, 0.22)
	tween.parallel().tween_property(model, "rotation_degrees:z", -8.0, 0.22)


func _add_street_animal(pos_a: Vector3, pos_b: Vector3, color: Color, duration: float, animal_name: String) -> void:
	var root := Node3D.new()
	root.name = animal_name
	root.position = pos_a
	city_root.add_child(root)
	var path := KENNEY_PETS + "animal-cat.glb"
	if animal_name.to_lower().contains("dog"):
		path = KENNEY_PETS + "animal-dog.glb"
	elif animal_name.to_lower().contains("bird"):
		path = KENNEY_PETS + "animal-parrot.glb"
	elif animal_name.to_lower().contains("fox"):
		path = KENNEY_PETS + "animal-fox.glb"
	var model := _add_asset_scene(root, path, Vector3.ZERO, 0.072, 180.0 if pos_b.z < pos_a.z else 0.0, "Kenney animal model")
	var bob := model.create_tween().set_loops()
	bob.set_trans(Tween.TRANS_SINE)
	bob.set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(model, "rotation_degrees:x", 4.0, 0.34)
	bob.tween_property(model, "rotation_degrees:x", -2.0, 0.34)
	var tween := root.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position", pos_b, duration)
	tween.tween_property(root, "position", pos_a, duration)


func _add_lit_windows(parent: Node3D, center: Vector3, width: float, height: float, columns: int, rows: int, mat: Material, density: float, mesh_name := "Lit apartment") -> void:
	for row in range(rows):
		for column in range(columns):
			var seed := float((column * 17 + row * 31 + columns * 7) % 100) / 100.0
			if seed > density:
				continue
			var x := center.x - width * 0.5 + width * (float(column) + 0.5) / float(columns)
			var y := center.y - height * 0.5 + height * (float(row) + 0.5) / float(rows)
			_add_box(parent, Vector3(x, y, center.z), Vector3(width / float(columns) * 0.52, height / float(rows) * 0.38, 0.024), mat, mesh_name)


func _add_roof_equipment(parent: Node3D, center: Vector3, accent: Color) -> void:
	_add_box(parent, center + Vector3(-0.18, 0.0, 0.0), Vector3(0.16, 0.08, 0.12), materials.dark_metal, "Roof HVAC unit")
	_add_box(parent, center + Vector3(0.1, 0.015, 0.04), Vector3(0.14, 0.055, 0.11), materials.bronze, "Low roof condenser")
	_add_sphere(parent, center + Vector3(0.16, 0.07, 0.04), 0.03, _accent_material(accent, 0.52), 10, "Low roof marker light")


func _add_spot_light(parent: Node3D, pos: Vector3, target: Vector3, color: Color, energy: float, range: float, angle: float, light_name := "Spot light") -> SpotLight3D:
	var spot := SpotLight3D.new()
	spot.name = light_name
	spot.position = pos
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = range
	spot.spot_angle = angle
	parent.add_child(spot)
	spot.look_at(target, Vector3.UP)
	return spot


func _add_rooftop_sign(parent: Node3D, text: String, pos: Vector3, color: Color) -> Label3D:
	var sign := Label3D.new()
	sign.name = "Rooftop sign " + text
	sign.text = text
	sign.font_size = 22
	sign.pixel_size = 0.006
	sign.outline_size = 4
	sign.modulate = Color(color.r, color.g, color.b, 0.88)
	sign.position = pos
	sign.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	parent.add_child(sign)
	var tween := sign.create_tween().set_loops()
	tween.tween_property(sign, "modulate", Color(color.r, color.g, color.b, 0.48), 0.7)
	tween.tween_property(sign, "modulate", Color(color.r, color.g, color.b, 0.88), 0.7)
	return sign


func _add_glass_sheen(parent: Node3D, center: Vector3, width: float, height: float, color: Color, angle := -20.0) -> void:
	var sheen := _add_box(parent, center, Vector3(width, height, 0.02), _make_material(Color(1.0, 0.96, 0.84, 0.28), color, 0.1, 0.0, 0.02, 0.28), "Moving glass reflection slash")
	sheen.rotation_degrees.z = angle
	var base_x := center.x
	var tween := sheen.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sheen, "position:x", base_x + 0.24, 1.4)
	tween.tween_property(sheen, "position:x", base_x - 0.24, 1.4)


func _on_economy_tick() -> void:
	var income := _get_income_per_hour()
	if income <= 0.0:
		return
	coins += income
	_refresh_hud()
	_set_status("+" + _format_amount(income) + " монет")


func _get_income_per_hour() -> float:
	var total := 0.0
	for plot_index in placed.keys():
		total += float(building_data[placed[plot_index]].income)
	return total


func _spawn_income_ticks() -> void:
	for plot_index in placed.keys():
		var building_index = placed[plot_index]
		var data = building_data[building_index]
		var position: Vector3 = plots[plot_index].position + Vector3(0.0, 0.55, 0.0)
		_spawn_build_fx(position, data.color, true)


func _select_building(index: int) -> void:
	selected_building = index
	var data = building_data[index]
	selected_label.text = str(index + 1).pad_zeros(2) + " " + str(data.name) + "  " + _format_amount(data.cost) + " монет"
	_set_status("Выбрано: " + str(data.name))
	_refresh_hud()


func _refresh_hud() -> void:
	if coin_label == null:
		return
	coin_label.text = "Монеты: " + _format_amount(coins)
	income_label.text = "Доход/ч: +" + _format_amount(_get_income_per_hour())

	for i in range(building_buttons.size()):
		var data = building_data[i]
		var button: Button = building_buttons[i]
		button.text = "%02d %s\n%s монет   +%s/ч" % [i + 1, str(data.name), _format_amount(data.cost), _format_amount(data.income)]
		button.button_pressed = i == selected_building
		var accent: Color = data.color
		var bg := Color(0.055, 0.07, 0.095, 0.84)
		var border := Color(accent.r, accent.g, accent.b, 0.34)
		if i == selected_building:
			bg = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.92)
			border = Color(accent.r, accent.g, accent.b, 0.88)
		elif coins < float(data.cost):
			bg = Color(0.04, 0.045, 0.06, 0.65)
			border = Color(0.18, 0.2, 0.24, 0.45)
		button.add_theme_stylebox_override("normal", _style_box(bg, border, 7))
		button.add_theme_stylebox_override("hover", _style_box(bg.lightened(0.08), border.lightened(0.1), 7))
		button.add_theme_stylebox_override("pressed", _style_box(bg.lightened(0.14), border.lightened(0.2), 7))
		button.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0) if coins >= float(data.cost) or i == selected_building else Color(0.52, 0.58, 0.66))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))


func _add_test_money() -> void:
	coins += 50000000.0
	_set_status("+50M тестовых монет")
	_pulse_label(coin_label, Color(1.0, 0.94, 0.48))
	_refresh_hud()


func _clear_city() -> void:
	for plot in plots:
		if plot.building != null and is_instance_valid(plot.building):
			plot.building.queue_free()
		plot.building = null
		plot.label.text = "Пусто"
	placed.clear()
	_set_status("Город очищен")
	_refresh_hud()


func _set_status(text: String) -> void:
	if status_label == null:
		return
	status_label.text = text


func _pop_in(node: Node3D) -> void:
	node.scale = Vector3(0.18, 0.18, 0.18)
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector3.ONE, 0.44)


func _pulse_node(node: Node3D, duration: float, scale_to: float) -> void:
	var base_scale := node.scale
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", base_scale * scale_to, duration * 0.5)
	tween.tween_property(node, "scale", base_scale, duration * 0.5)


func _spin_node(node: Node3D, duration: float) -> void:
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "rotation:y", TAU, duration).as_relative()


func _pulse_label(label: Label, color: Color) -> void:
	var original := label.get_theme_color("font_color")
	label.add_theme_color_override("font_color", color)
	var tween := label.create_tween()
	tween.tween_interval(0.16)
	tween.tween_callback(func(): label.add_theme_color_override("font_color", original))


func _spawn_build_fx(position: Vector3, color: Color, small := false) -> void:
	var ring := _add_torus(effects_root, position + Vector3(0.0, 0.08, 0.0), 0.22 if small else 0.52, 0.012, _hologram_material(color), "Placement ripple")
	ring.rotation_degrees.x = 90.0
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3.ONE * (1.75 if small else 1.28), 0.55)
	tween.tween_callback(ring.queue_free)


func _add_particles(parent: Node3D, pos: Vector3, color: Color, amount: int) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "GPU particles"
	particles.amount = min(amount, 10)
	particles.lifetime = 0.72
	particles.one_shot = true
	particles.randomness = 0.38
	particles.position = pos
	particles.emitting = true

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.065
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 24.0
	process.gravity = Vector3(0.0, 0.02, 0.0)
	process.initial_velocity_min = 0.01
	process.initial_velocity_max = 0.08
	process.scale_min = 0.008
	process.scale_max = 0.018
	process.color = color
	particles.process_material = process

	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.016
	particle_mesh.height = 0.032
	particles.draw_pass_1 = particle_mesh
	particles.material_override = _accent_material(color, 0.55)
	parent.add_child(particles)
	return particles


func _add_asset_scene(parent: Node3D, path: String, pos: Vector3, scale_value: float, yaw_degrees := 0.0, asset_name := "Imported asset") -> Node3D:
	var scene: PackedScene = _load_asset_scene(path)
	if scene == null:
		var fallback := Node3D.new()
		fallback.name = asset_name + " missing"
		fallback.position = pos
		parent.add_child(fallback)
		return fallback
	var instance := scene.instantiate() as Node3D
	if instance == null:
		var empty := Node3D.new()
		empty.name = asset_name + " empty"
		empty.position = pos
		parent.add_child(empty)
		return empty
	instance.name = asset_name
	instance.position = pos
	instance.rotation_degrees.y = yaw_degrees
	instance.scale = Vector3.ONE * scale_value
	parent.add_child(instance)
	_prepare_imported_asset(instance)
	return instance


func _load_asset_scene(path: String) -> PackedScene:
	if asset_scene_cache.has(path):
		return asset_scene_cache[path]
	var resource := ResourceLoader.load(path)
	var scene := resource as PackedScene
	asset_scene_cache[path] = scene
	if scene == null:
		push_warning("Asset scene failed to load: " + path)
	return scene


func _prepare_imported_asset(root: Node3D) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_child := child as MeshInstance3D
		mesh_child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if DisplayServer.get_name() == "headless":
			continue
		if mesh_child.mesh == null:
			continue
		for surface in range(mesh_child.mesh.get_surface_count()):
			var source_material := mesh_child.get_surface_override_material(surface)
			if source_material == null:
				source_material = mesh_child.mesh.surface_get_material(surface)
			var standard := source_material as StandardMaterial3D
			if standard == null:
				continue
			var tuned := standard.duplicate() as StandardMaterial3D
			tuned.roughness = clamp(tuned.roughness * 0.72, 0.18, 0.68)
			tuned.metallic = max(tuned.metallic, 0.035)
			tuned.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mesh_child.set_surface_override_material(surface, tuned)


func _add_light(parent: Node3D, pos: Vector3, color: Color, energy: float, range: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "Local glow"
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	parent.add_child(light)
	return light


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, mesh_name := "Box") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, segments: int, mesh_name := "Cylinder") -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material, segments: int, mesh_name := "Sphere") -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = max(4, int(segments * 0.5))
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	parent.add_child(instance)
	return instance


func _add_torus(parent: Node3D, pos: Vector3, radius: float, tube_radius: float, mat: Material, mesh_name := "Torus") -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = max(0.01, radius - tube_radius)
	mesh.outer_radius = radius + tube_radius
	mesh.ring_segments = 64
	mesh.rings = 10
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	parent.add_child(instance)
	return instance


func _textured_city_stone_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.47, 0.41, 0.33)
	mat.metallic = 0.0
	mat.roughness = 0.82
	mat.uv1_scale = Vector3(5.8, 5.8, 1.0)
	mat.texture_repeat = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if ResourceLoader.exists(SIDE_STONE_ALBEDO):
		mat.albedo_texture = load(SIDE_STONE_ALBEDO)
	if ResourceLoader.exists(SIDE_STONE_ROUGHNESS):
		mat.roughness_texture = load(SIDE_STONE_ROUGHNESS)
	if ResourceLoader.exists(SIDE_STONE_NORMAL):
		mat.normal_enabled = true
		mat.normal_scale = 0.42
		mat.normal_texture = load(SIDE_STONE_NORMAL)
	if ResourceLoader.exists(SIDE_STONE_HEIGHT):
		mat.heightmap_enabled = true
		mat.heightmap_scale = 0.032
		mat.heightmap_deep_parallax = true
		mat.heightmap_min_layers = 8
		mat.heightmap_max_layers = 22
		mat.heightmap_texture = load(SIDE_STONE_HEIGHT)
	return mat


func _make_material(albedo: Color, emission := Color(0.0, 0.0, 0.0), emission_energy := 0.0, metallic := 0.0, roughness := 0.45, alpha := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(albedo.r, albedo.g, albedo.b, alpha)
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	return mat


func _accent_material(color: Color, energy: float) -> StandardMaterial3D:
	return _make_material(Color(color.r * 0.65, color.g * 0.65, color.b * 0.65), color, energy, 0.0, 0.2)


func _pattern_material(base: Color, accent: Color, pattern: int, emission_energy := 0.0, metallic := 0.0, roughness := 0.45) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform int pattern = 0;
uniform float emission_energy = 0.0;
uniform float metallic_value = 0.0;
uniform float roughness_value = 0.45;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float line(float value, float width) {
	float f = abs(fract(value) - 0.5);
	return 1.0 - smoothstep(width, width + 0.01, f);
}

void fragment() {
	vec2 uv = UV;
	vec3 base = base_color.rgb;
	vec3 accent = accent_color.rgb;
	vec3 color = base;
	float emit = 0.0;

	if (pattern == 1) {
		float n = hash(floor(uv * 80.0));
		float fine = hash(floor(uv * 220.0 + vec2(7.0, 3.0)));
		color = base * (0.82 + n * 0.22);
		color = mix(color, accent, step(0.965, fine) * 0.55);
	} else if (pattern == 2) {
		float weave_a = line(uv.x * 18.0 + uv.y * 0.7, 0.16);
		float weave_b = line(uv.y * 18.0 - uv.x * 0.55, 0.16);
		float weave = (weave_a + weave_b) * 0.5;
		color = mix(base * 0.72, accent, weave * 0.35);
	} else if (pattern == 3) {
		float stripe = 0.5 + 0.5 * sin((uv.x * 90.0) + (uv.y * 22.0));
		float broad = 0.5 + 0.5 * sin((uv.x + uv.y) * 10.0);
		color = mix(base, accent, stripe * 0.22 + broad * 0.18);
	} else if (pattern == 4) {
		vec2 cell = fract(uv * vec2(4.0, 6.0));
		float grid = 1.0 - smoothstep(0.025, 0.045, min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y)));
		float diagonal = line((uv.x + uv.y) * 8.0, 0.035);
		color = mix(base, accent, grid * 0.62 + diagonal * 0.14);
		emit = grid * 0.45 + diagonal * 0.15;
	} else if (pattern == 5) {
		float row = floor(uv.y * 7.0);
		vec2 brick_uv = vec2(uv.x * 5.0 + mod(row, 2.0) * 0.5, uv.y * 7.0);
		vec2 f = fract(brick_uv);
		float mortar = 1.0 - smoothstep(0.035, 0.055, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
		float n = hash(floor(brick_uv * 2.0));
		color = base * (0.78 + n * 0.28);
		color = mix(color, accent, mortar * 0.9);
	} else if (pattern == 6) {
		float n = hash(floor(uv * 26.0));
		float vein = pow(0.5 + 0.5 * sin((uv.x * 7.0 + sin(uv.y * 9.0) + n * 0.8) * 3.14159), 9.0);
		color = mix(base, accent, vein * 0.72);
	} else if (pattern == 7) {
		vec2 f = fract(uv * vec2(5.0, 8.0));
		float window = smoothstep(0.18, 0.24, f.x) * (1.0 - smoothstep(0.76, 0.82, f.x)) * smoothstep(0.18, 0.24, f.y) * (1.0 - smoothstep(0.76, 0.82, f.y));
		float circuit = line(uv.x * 6.0 + floor(uv.y * 8.0) * 0.21, 0.035);
		color = mix(base, accent, window * 0.75 + circuit * 0.22);
		emit = window * 0.65 + circuit * 0.28;
	} else if (pattern == 8) {
		float n = hash(floor(uv * 36.0));
		float blade = line(uv.x * 13.0 + sin(uv.y * 16.0), 0.09);
		color = mix(base * (0.75 + n * 0.26), accent, blade * 0.28 + step(0.9, n) * 0.2);
	}

	ALBEDO = color;
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
	EMISSION = accent * emission_energy * emit;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("pattern", pattern)
	material.set_shader_parameter("emission_energy", emission_energy)
	material.set_shader_parameter("metallic_value", metallic)
	material.set_shader_parameter("roughness_value", roughness)
	return material


func _procedural_texture_material(kind: String, base: Color, accent: Color, metallic := 0.0, roughness := 0.45, normal_scale := 0.0, emission := Color(0.0, 0.0, 0.0), emission_energy := 0.0) -> StandardMaterial3D:
	if DisplayServer.get_name() == "headless":
		return _make_material(base, emission, emission_energy, metallic, roughness)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = _make_procedural_texture(kind, base, accent)
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if normal_scale > 0.0:
		mat.normal_enabled = true
		mat.normal_texture = _make_normal_texture(kind, normal_scale)
		mat.normal_scale = normal_scale
	return mat


func _make_procedural_texture(kind: String, base: Color, accent: Color) -> Texture2D:
	var size := 48
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var uv := Vector2(float(x) / float(size - 1), float(y) / float(size - 1))
			image.set_pixel(x, y, _procedural_texture_color(kind, uv, base, accent))
	return ImageTexture.create_from_image(image)


func _make_normal_texture(kind: String, scale: float) -> Texture2D:
	var size := 48
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var step := 1.0 / float(size)
	for y in range(size):
		for x in range(size):
			var uv := Vector2(float(x) / float(size - 1), float(y) / float(size - 1))
			var h_l := _procedural_height(kind, uv + Vector2(-step, 0.0))
			var h_r := _procedural_height(kind, uv + Vector2(step, 0.0))
			var h_d := _procedural_height(kind, uv + Vector2(0.0, -step))
			var h_u := _procedural_height(kind, uv + Vector2(0.0, step))
			var normal := Vector3((h_l - h_r) * scale, (h_d - h_u) * scale, 1.0).normalized()
			image.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5))
	return ImageTexture.create_from_image(image)


func _procedural_texture_color(kind: String, uv: Vector2, base: Color, accent: Color) -> Color:
	var h := _procedural_height(kind, uv)
	var c := base.lerp(accent, h)
	if kind == "brick":
		var mortar := _brick_mortar(uv)
		c = base.darkened(0.12).lerp(base.lightened(0.18), _hash21(_floorv(uv * Vector2(6.0, 9.0))))
		c = c.lerp(accent, mortar)
	elif kind == "carbon":
		c = base.lerp(accent, h * 0.42)
	elif kind == "obsidian":
		c = base.lerp(accent, pow(h, 3.0) * 0.55)
	elif kind == "solar":
		c = base.lerp(accent, h * 0.72)
	elif kind == "brushed":
		c = base.lerp(accent, 0.18 + h * 0.36)
	elif kind == "marble":
		c = base.lerp(accent, pow(h, 2.2) * 0.82)
	elif kind == "stone":
		c = base.darkened(0.08).lerp(accent, h * 0.42)
	elif kind == "pearl":
		c = base.lerp(accent, 0.25 + h * 0.35)
	return Color(c.r, c.g, c.b, 1.0)


func _procedural_height(kind: String, uv: Vector2) -> float:
	uv = Vector2(wrapf(uv.x, 0.0, 1.0), wrapf(uv.y, 0.0, 1.0))
	if kind == "brick":
		return max(0.12, 1.0 - _brick_mortar(uv))
	if kind == "carbon":
		var weave_x := 0.5 + 0.5 * sin((uv.x * 28.0 + uv.y * 3.0) * TAU)
		var weave_y := 0.5 + 0.5 * sin((uv.y * 28.0 - uv.x * 3.0) * TAU)
		return max(weave_x, weave_y) * 0.7
	if kind == "solar":
		var grid := _grid_line(uv, Vector2(4.0, 6.0), 0.04)
		var diagonal := 0.5 + 0.5 * sin((uv.x + uv.y) * 16.0)
		return clamp(grid + diagonal * 0.18, 0.0, 1.0)
	if kind == "brushed":
		return 0.5 + 0.5 * sin((uv.x * 80.0 + uv.y * 9.0) * TAU)
	if kind == "marble":
		return pow(0.5 + 0.5 * sin((uv.x * 4.0 + sin(uv.y * 9.0) * 0.45 + _hash21(_floorv(uv * 9.0)) * 0.2) * TAU), 5.0)
	if kind == "obsidian":
		return pow(_hash21(_floorv(uv * 18.0)) * 0.7 + _grid_line(uv, Vector2(3.0, 5.0), 0.02) * 0.3, 1.8)
	if kind == "pearl":
		return 0.5 + 0.5 * sin((uv.x * 3.0 + uv.y * 2.0 + sin(uv.y * 11.0) * 0.2) * TAU)
	var noise := _hash21(_floorv(uv * 42.0))
	var chips := 1.0 if _hash21(_floorv(uv * 90.0 + Vector2(3.0, 9.0))) >= 0.88 else 0.0
	return noise * 0.55 + chips * 0.35


func _brick_mortar(uv: Vector2) -> float:
	var row: float = floor(uv.y * 9.0)
	var brick_uv := Vector2(uv.x * 6.0 + fmod(row, 2.0) * 0.5, uv.y * 9.0)
	var f := Vector2(_fractf(brick_uv.x), _fractf(brick_uv.y))
	var edge: float = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y))
	return 1.0 - smoothstep(0.035, 0.075, edge)


func _grid_line(uv: Vector2, repeats: Vector2, width: float) -> float:
	var f := Vector2(_fractf(uv.x * repeats.x), _fractf(uv.y * repeats.y))
	var edge: float = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y))
	return 1.0 - smoothstep(width, width + 0.02, edge)


func _hash21(p: Vector2) -> float:
	return _fractf(sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453123)


func _floorv(v: Vector2) -> Vector2:
	return Vector2(floor(v.x), floor(v.y))


func _fractf(value: float) -> float:
	return value - floor(value)


func _glass_material(base: Color, accent: Color, alpha := 0.5, reflection := 0.55) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform vec4 base_color : source_color = vec4(0.02, 0.12, 0.18, 0.5);
uniform vec4 accent_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float alpha_value = 0.5;
uniform float reflection_value = 0.55;

float line(float value, float width) {
	float f = abs(fract(value) - 0.5);
	return 1.0 - smoothstep(width, width + 0.018, f);
}

void fragment() {
	vec2 uv = UV;
	float vertical = smoothstep(0.0, 1.0, uv.y);
	float window_x = line(uv.x * 6.0, 0.05);
	float window_y = line(uv.y * 13.0, 0.035);
	float window_grid = max(window_x * 0.55, window_y);
	float moving_sheen = pow(0.5 + 0.5 * sin((uv.x * 4.2 + uv.y * 2.1 + TIME * 0.22) * 6.28318), 9.0);
	float hard_sky = smoothstep(0.08, 0.13, abs(fract(uv.y * 4.0 + 0.18) - 0.5));
	vec3 color = mix(base_color.rgb * 0.55, base_color.rgb * 1.35, vertical);
	color = mix(color, accent_color.rgb, window_grid * 0.25 + moving_sheen * reflection_value * 0.42);
	color += vec3(1.0, 0.94, 0.82) * moving_sheen * reflection_value * 0.36;
	color += accent_color.rgb * (1.0 - hard_sky) * 0.08;
	ALBEDO = color;
	METALLIC = 0.05;
	ROUGHNESS = 0.035;
	EMISSION = accent_color.rgb * (window_grid * 0.08 + moving_sheen * 0.06);
	ALPHA = alpha_value;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Color(base.r, base.g, base.b, alpha))
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("alpha_value", alpha)
	material.set_shader_parameter("reflection_value", reflection)
	return material


func _river_material(base: Color, accent: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform vec4 base_color : source_color = vec4(0.01, 0.08, 0.14, 0.62);
uniform vec4 accent_color : source_color = vec4(0.1, 0.8, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	float wave_a = 0.5 + 0.5 * sin((uv.x * 11.0 + TIME * 0.42) + sin(uv.y * 5.0) * 0.45);
	float wave_b = 0.5 + 0.5 * sin((uv.y * 15.0 - TIME * 0.36) + uv.x * 1.6);
	float wake = pow(max(wave_a, wave_b), 10.0);
	vec3 color = mix(base_color.rgb, accent_color.rgb, wake * 0.18);
	ALBEDO = color;
	ROUGHNESS = 0.045;
	METALLIC = 0.0;
	EMISSION = accent_color.rgb * wake * 0.055;
	ALPHA = 0.58;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Color(base.r, base.g, base.b, 0.58))
	material.set_shader_parameter("accent_color", accent)
	return material


func _hologram_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 tint : source_color = vec4(0.3, 0.9, 1.0, 0.55);

void fragment() {
	float bands = 0.5 + 0.5 * sin((UV.y * 32.0) + TIME * 4.0);
	float rim = pow(1.0 - abs(NORMAL.y), 1.6);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * (1.3 + bands * 1.7 + rim);
	ALPHA = tint.a * (0.32 + bands * 0.34 + rim * 0.26);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", Color(color.r, color.g, color.b, 0.56))
	return material


func _style_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _format_amount(value: float) -> String:
	var abs_value: float = abs(value)
	if abs_value >= 1000000000.0:
		return _trim_number(value / 1000000000.0) + "B"
	if abs_value >= 1000000.0:
		return _trim_number(value / 1000000.0) + "M"
	if abs_value >= 1000.0:
		return _trim_number(value / 1000.0) + "K"
	return str(int(round(value)))


func _trim_number(value: float) -> String:
	var text := "%.1f" % value
	if text.ends_with(".0"):
		text = text.substr(0, text.length() - 2)
	return text
