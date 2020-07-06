extends StaticBody

export var xzmin = Vector2(-128, -128)
export var area_size = Vector2(1024, 1024)
var xzmax = xzmin + area_size
export var granularity = 4
export var rigged = 1
export var tile_size = 4
export var base_height = -33
export var max_hill = 40
export var shore_offset = 128
export var shore_height = -5


export (PackedScene) var Tree
export var tree_density = 0.01

export (PackedScene) var Rock
export var rock_density = 0.001

var noise
var bignoise
var slopenoise

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	bignoise = OpenSimplexNoise.new()
	bignoise.seed = randi()
	slopenoise = OpenSimplexNoise.new()
	slopenoise.seed = randi()
	to_mesh()
	to_collision()
# 	make_trees()
# 	make_rocks()

func make_trees():
	var area = xzmax - xzmin
	var ntrees = area.x * area.y * tree_density
	for _i in range(ntrees):
		var pos = xzmin + area * Vector2(randf(), randf())
		var height = get_height(pos.x, pos.y)
		if height <= 0:
			continue
		var tree = Tree.instance()
		add_child(tree)
		tree.translation = get_point(pos.x, pos.y)
		tree.rotate_y(randf() * 2 * PI)

func make_rocks():
	var area = xzmax - xzmin
	var ntrees = area.x * area.y * rock_density
	for _i in range(ntrees):
		var pos = xzmin + area * Vector2(randf(), randf())
		var height = get_height(pos.x, pos.y)
		var rock = Rock.instance()
		add_child(rock)
		rock.translation = get_point(pos.x, pos.y)
		rock.rotate_y(randf() * 2 * PI)

func sqr(x):
	return x * x

func get_height(x, z):
	if x < xzmin.x or z < xzmin.y or x >= xzmax.x or z >= xzmax.y:
		return base_height
	var hills = (noise.get_noise_2d(x*rigged, z*rigged) + 1) / 2 * max_hill
	var elevation_rigged = 0.2
	var elevation = (bignoise.get_noise_2d(x*elevation_rigged, z*elevation_rigged) + 1) / 2 * 100
	var slopes = sqr((slopenoise.get_noise_2d(x/10, z/10) + 1) / 2)
	var h = base_height + elevation + hills*slopes
	var shore_distance = 1
	shore_distance = sqrt(clamp([x - xzmin.x, z - xzmin.y, xzmax.x - x, xzmax.y - z].min() / shore_offset, 0, 1))
	return h * shore_distance + shore_height * (1-shore_distance)


func get_point(x, z):
	return Vector3(x, get_height(x, z), z)

func to_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_color(Color(0.5, 1, 0.5))
	for x in range(xzmin.x - granularity, xzmax.x, granularity):
		for z in range(xzmin.y - granularity, xzmax.y, granularity):
# 			print(x, " ", z)
			add_quad(st,
				get_point(x, z),
				get_point(x + granularity, z),
				get_point(x, z + granularity),
				get_point(x + granularity, z + granularity)
			)
	st.generate_normals()
	st.generate_tangents()
	st.commit($Mesh.mesh)

func add_quad(st, c1, c2, c3, c4):
	if randf() > 0.5:
		st.add_uv(Vector2(0, 0))
		st.add_vertex(c1)
		st.add_uv(Vector2(1, 0))
		st.add_vertex(c2)
		st.add_uv(Vector2(0, 1))
		st.add_vertex(c3)
		st.add_uv(Vector2(0, 1))
		st.add_vertex(c3)
		st.add_uv(Vector2(1, 0))
		st.add_vertex(c2)
		st.add_uv(Vector2(1, 1))
		st.add_vertex(c4)
	else:
		st.add_uv(Vector2(0, 0))
		st.add_vertex(c1)
		st.add_uv(Vector2(1, 0))
		st.add_vertex(c2)
		st.add_uv(Vector2(1, 1))
		st.add_vertex(c4)
		st.add_uv(Vector2(0, 0))
		st.add_vertex(c1)
		st.add_uv(Vector2(1, 1))
		st.add_vertex(c4)
		st.add_uv(Vector2(0, 1))
		st.add_vertex(c3)
	


func to_collision():
	var size_x = int((xzmax.x - xzmin.x) / granularity + 3)
	var size_z = int((xzmax.y - xzmin.y) / granularity + 3)
	var xmin = xzmin.x - granularity
	var zmin = xzmin.y - granularity
	var ground = []
	ground.resize(size_x * size_z)
	for x in range(0, size_x):
		for z in range(0, size_z):
			var h = get_height(x * granularity + xmin , z * granularity + zmin)
			ground[x + z * size_x] = h
	var shape = $Collision.shape
	shape.map_width = size_x
	shape.map_depth = size_z
	shape.map_data = PoolRealArray(ground)
	$Collision.scale.x = granularity
	$Collision.scale.z = granularity
	$Collision.translation.x = xmin + float(size_x - 1) / 2 * granularity
	$Collision.translation.z = zmin + float(size_z - 1) / 2 * granularity
