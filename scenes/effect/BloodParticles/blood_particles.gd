extends GPUParticles3D

func _ready():
	# Bắt đầu bắn máu
	emitting = true
	# Đợi hiệu ứng diễn xong (Lifetime + một chút thời gian trừ hao)
	await get_tree().create_timer(lifetime + 0.1).timeout
	# Tự xóa scene để giải phóng bộ nhớ
	queue_free()
