extends MeshInstance3D

@onready var viewport: SubViewport = $SubViewport

# Çarpışma kutumuzu koda dahil ediyoruz ki boyutunu (size) ölçebilelim
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		var local_pos: Vector3 = to_local(event_position)
		
		# 1. Çarpışma kutusunun GERÇEK X ve Y boyutlarını alıyoruz (Örn: 2'ye 2 metre)
		var kutu_boyutu: Vector3 = collision_shape.shape.size 
		
		# 2. Sabit 0.5 yerine, tıklanan yeri kutunun gerçek genişliğine bölüp % oranını buluyoruz
		var oran_x: float = (local_pos.x / kutu_boyutu.x) + 0.5
		var oran_y: float = 0.5 - (local_pos.y / kutu_boyutu.y)
		
		# 3. Bulduğumuz bu %'lik oranı, oyunun kendi piksel çözünürlüğüyle çarpıyoruz
		var viewport_size: Vector2 = viewport.size
		var pixel_pos := Vector2(oran_x * viewport_size.x, oran_y * viewport_size.y)
		
		var event_2d = event.duplicate()
		event_2d.position = pixel_pos
		viewport.push_input(event_2d)
