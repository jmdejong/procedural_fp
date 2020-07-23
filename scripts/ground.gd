extends StaticBody

export var area = Rect2(Vector2(-128, -128), Vector2(512, 512))
export var granularity = 4
export var rigged = 0.5
export var tile_size = 4
export var base_height = -5
export var max_hill = 80
export var shore_offset = 128
export var avg_height = 10


export (PackedScene) var Tree
export var tree_density = 0.01

export (PackedScene) var Rock
export var rock_density = 0.001

var noise
var bignoise
var slopenoise

export (Resource) var blue

const Blueprint = preload("res://scripts/blueprint.gd")

var _ground = PoolRealArray()

# Called when the node enters the scene tree for the first time.
func _ready():
	var bp = generate()
	bp.to_mesh($Mesh)
	bp.to_collision($Collision)

func generate():
	var bp = blue.new(area, granularity, base_height)
	initialize_noise()
	generate_ground(bp)
	make_trees(bp)
	make_rocks(bp)
	return bp

func initialize_noise():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	bignoise = OpenSimplexNoise.new()
	bignoise.seed = randi()
	slopenoise = OpenSimplexNoise.new()
	slopenoise.seed = randi()

func generate_ground(bp):
	for x in range(0, bp.grid_size.x):
		for z in range(0, bp.grid_size.y):
			var h = noise_height(bp.grid_to_world(Vector2(x, z)))
			bp.set_grid_height(Vector2(x, z), h)

func make_entities(typ, density, bp, min_height=0):
	var amount = bp.area.get_area() * density
	for _i in range(amount):
		var pos = bp.area.position + bp.area.size * Vector2(randf(), randf())
		var height = bp.get_height(Vector2(pos.x, pos.y))
		if height <= min_height:
			continue
		var entity = typ.instance()
		entity.translation = Vector3(pos.x, height, pos.y)
		entity.rotate_y(randf() * 2 * PI)
		add_child(entity)



func make_trees(bp):
	make_entities(Tree, tree_density, bp)

func make_rocks(bp):
	make_entities(Rock, rock_density, bp, -100)

func sqr(x):
	return x * x

func noise_height(p):
	var x = p.x
	var z = p.y
	if x < area.position.x or z < area.position.y or x >= area.end.x or z >= area.end.y:
		return base_height
	var hills = noise.get_noise_2d(x*rigged, z*rigged) * max_hill
	var elevation_rigged = 0.2
	var elevation = bignoise.get_noise_2d(x*elevation_rigged, z*elevation_rigged) * 50
	var slopes = sqr((slopenoise.get_noise_2d(x/10, z/10) + 1) / 2)
	var h = avg_height + elevation + hills*slopes
	var shore_distance = 1
	shore_distance = clamp([x - area.position.x, z - area.position.y, area.end.x - x, area.end.y - z].min() / shore_offset, 0, 1)
	return h * shore_distance + base_height * (1-shore_distance)


