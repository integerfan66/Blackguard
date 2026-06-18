extends MeshInstance3D

@onready var viewport: SubViewport = $"../SubViewport"
# Çarpışma kutumuzu koda dahil ediyoruz ki boyutunu (size) ölçebilelim
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton and not event.pressed:
		return

	# Convert 3D local position to a [0.0, 1.0] UV coordinate.
	# local_pos ranges from -half_size to +half_size, so normalize to [0, 1].
	var local_pos: Vector3 = to_local(event_position)
	var kutu_boyutu: Vector3 = collision_shape.shape.size

	var uv_x: float = (local_pos.x / kutu_boyutu.x) + 0.5
	var uv_y: float = 0.5 - (local_pos.y / kutu_boyutu.y)   # adjust axis if needed

	# Map UV to SubViewport pixel coordinates
	var viewport_size: Vector2 = viewport.size
	var pixel_pos := Vector2(uv_x * viewport_size.x, uv_y * viewport_size.y)

	# Duplicate and inject as a 2D event
	var event_2d: InputEvent = event.duplicate()
	if event_2d is InputEventMouseButton or event_2d is InputEventMouseMotion:
		event_2d.position = pixel_pos
		viewport.push_input(event_2d)
