extends Node
class_name InputDetection_Component
# Script made by Furokawa ;)
# Purpose : Get Keyboard or Gamepad input signals & translate them into vectors


@export_group("Settings")
@export var detectX : bool = true
@export var detectY : bool = true
@export_range(0.01, 1.0, 0.01) var normalizeEdge_Time : float = 0.15

@export_group("Components")
@export var collisionCheck_Head : ShapeCast2D = null
@export var collisionCheck_Body : ShapeCast2D = null
@export var collisionCheck_Foot : RayCast2D = null
@export var grabTimer : Timer = null


var targetEntity : CharacterBody2D = null

var jumpValue : float = 125.0
var gravityValue : float = 9.80
var speedValue : float = 75.0

var coyoteValue : float = 0.3
var canFall : bool = true
var canGrab : bool = true
var movementVector : Vector2 = Vector2.ZERO

func _ready() -> void:
	targetEntity = get_parent()
	
func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		pass

func get_horizontal() -> float:
	# Only returns x Axis on keyboard
	if !detectX :
		return movementVector.x
	movementVector.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	return movementVector.x * speedValue

func get_vertical() -> float:
	# Manages gravity, coyote time and ceiling collisions
	if targetEntity == null || !detectY:
		return movementVector.y

	if is_OnFloor():
		canFall = false; canGrab = true; detectX = true
		grabTimer.stop()
		movementVector.y = 0

	if (is_OnFloor() || !canFall) && Input.is_action_pressed("ui_up"):
		canFall = true
		movementVector.y = 0; movementVector.y -= jumpValue
	
	elif Input.is_action_just_released("ui_up") && targetEntity.velocity.y < 0 :
		canFall = true; movementVector.y /= jumpValue
	
	elif !is_OnFloor():
		movementVector.y += gravityValue
		if targetEntity.is_on_ceiling() : movementVector.y = gravityValue; movementVector.y += gravityValue
		if !canFall : get_tree().create_timer(coyoteValue).timeout.connect(func lambda() : canFall = true)

	if is_OnEdge() && canGrab:
		movementVector.y = 0; normalize_EdgeGrab()
		if grabTimer.is_stopped() : grabTimer.start()

	if (is_OnEdge() && canGrab) && Input.is_action_just_pressed("ui_up"):
		canFall = true; canGrab = false
		movementVector.y = 0; movementVector.y -= jumpValue
		
		if movementVector.x == 0:
			detectX = false
			movementVector.x -= (jumpValue / 2) * targetEntity.get_wall_normal().x
	
	if (targetEntity.is_on_wall_only() && ( (!is_OnEdge() && canGrab) && !is_OnFloor() ) ) && Input.is_action_just_pressed("ui_up"):
		canGrab = false; detectX = false
		movementVector.y = 0; movementVector.y -= jumpValue
		movementVector.x = 0; movementVector.x += (jumpValue / 2) * targetEntity.get_wall_normal().x

	elif targetEntity.is_on_wall_only() && ( (!is_OnEdge() && canGrab) && !is_OnFloor() ):
		detectX = false
		movementVector.y = 0
		movementVector.y = lerp(movementVector.y, movementVector.y + gravityValue, 0.5)

	return movementVector.y
	
func get_axis() -> Vector2: 
	# returns whole axis as a vector2D
	return Vector2(get_horizontal(), get_vertical())

func is_OnEdge() -> bool:
	# Edge check
	if collisionCheck_Head == null || collisionCheck_Body == null:
		return false

	return (collisionCheck_Body.is_colliding() && !collisionCheck_Head.is_colliding() && !targetEntity.is_on_floor_only())

func is_OnFloor() -> bool:
	# True floor check
	if collisionCheck_Foot == null:
		return false
	
	return (collisionCheck_Foot.is_colliding() || targetEntity.is_on_floor())

func normalize_EdgeGrab() -> void:
	if collisionCheck_Head == null || collisionCheck_Body == null:
		return
	
	targetEntity.position.y = lerp(
		targetEntity.position.y,
		collisionCheck_Body.get_collision_point(collisionCheck_Body.get_collision_count() - 1).y,
		normalizeEdge_Time
	)

func on_GrabTimeOut() -> void:
	if grabTimer == null : 
		return
		
	canGrab = false
