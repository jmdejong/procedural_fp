

class_name Blueprint

export var area: Rect2 = Rect2(Vector2(-128, -128), Vector2(512, 512))
export var granularity: float = 4
export var default_height: float = 0.0

var grid = PoolRealArray()
var grid_origin: Vector2
var grid_size: Vector2

var _nearby = [Vector2(0,0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]

func _init(area: Rect2, granularity: float, default_height=0.0):
	self.area = area
	self.granularity = granularity
	self.default_height = default_height
	grid_origin = area.position - Vector2(granularity, granularity)
	grid_size = area.size / granularity + Vector2(3, 3)
	grid.resize(grid_size.x * grid_size.y)

func _hash(n1: int, n2: int =0):
	var a = n1*287117 + 350377 + 224737 *( n2*n2*n1) % 7919
	var p = 104729
	return float(a*a % p) / p

func world_to_grid(p):
	return Vector2(float(p.x - grid_origin.x) / granularity, float(p.y - grid_origin.y) / granularity)

func grid_to_world(p):
	return Vector2(p.x * granularity + grid_origin.x , p.y * granularity + grid_origin.y)

func get_grid_height(p):
	assert(p == p.floor())
	if p.x < 0 or p.x >= grid_size.x or p.y < 0 or p.y >= grid_size.y:
		return default_height
	return grid[p.x + p.y * grid_size.x]

func set_grid_height(p, val):
	assert(p == p.floor())
	if p.x < 0 or p.x >= grid_size.x or p.y < 0 or p.y >= grid_size.y:
		return
	grid[p.x + p.y * grid_size.x] = val

func get_height(p):
	# height interpolated from the 4 corner points of the quad these coordinates are in
	var pg = world_to_grid(p)
	var h = 0
	for n in _nearby:
		var pp = (pg + n).floor()
		h += get_grid_height(pp) * (1 - abs(pp.x - pg.x)) * (1 - abs(pp.y - pg.y))
	return h


func to_collision(heightmap):
	var shape = heightmap.shape
	shape.map_width = grid_size.x
	shape.map_depth = grid_size.y
	shape.map_data = PoolRealArray(grid)
	heightmap.scale.x = granularity
	heightmap.scale.z = granularity
	heightmap.translation.x = grid_origin.x + float(grid_size.y - 1) / 2 * granularity
	heightmap.translation.z = grid_origin.y + float(grid_size.x - 1) / 2 * granularity

func to_mesh(mesh, max_offset=0.5):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_color(Color(0.5, 1, 0.5))
	for x in range(0, grid_size.x - 1):
		for z in range(0, grid_size.y - 1):
			var corners = []
			for c in _nearby:
				var b = Vector2(x, z) + c
				var h = _hash(b.x, b.y)
				var hh = _hash(h*1000001)
				var offset = Vector2((h -0.5)*max_offset, (hh-0.5)*max_offset)
				var p = grid_to_world(b + offset)
				corners.append(Vector3(p.x, get_height(p), p.y))
			_add_quad(st, corners[0], corners[1], corners[2], corners[3])
	st.generate_normals()
	st.generate_tangents()
	st.commit(mesh.mesh)

func _add_quad(st, c1, c2, c3, c4):
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
