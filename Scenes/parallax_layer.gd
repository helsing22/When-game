extends ParallaxLayer

var dir = Vector2(1,0)
var velocidad = 20

func _process(delta: float) -> void:
	motion_offset += dir * velocidad * delta
