extends Node
class_name InputDetection_Component
# Script made by Furokawa ;)
# Purpose : Get Keyboard or Gamepad input signals & translate them into vectors
# Functions listed :
# get_horizontal
# get_vertical
# get_axis

var targetEntity : CharacterBody2D = null
var jumpValue : float = 125.0
var gravityValue : float = 9.80
var speedValue : float = 75.0

var coyoteValue : float = 0.3
var canFall : bool = true
var movementVector : Vector2 = Vector2.ZERO

func _ready() -> void:
	targetEntity = get_parent()
	
func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		pass

func get_horizontal() -> float:
	# Only returns x Axis on keyboard
	movementVector.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	return movementVector.x * speedValue

func get_vertical() -> float:
	# Manages gravity, coyote time and ceiling collisions
	if targetEntity == null:
		return 0
	
	if (targetEntity.is_on_floor() || !canFall) && Input.is_action_just_pressed("ui_up"):
		canFall = false ; movementVector.y -= jumpValue
		return  movementVector.y
		
	elif targetEntity.is_on_floor() :
		canFall = false ; movementVector.y = 0
		return movementVector.y
	
	if Input.is_action_just_released("ui_up") && targetEntity.velocity.y < 0 :
		canFall = true ; movementVector.y /= jumpValue
		return movementVector.y
		
	
	if !targetEntity.is_on_floor() :
		if targetEntity.is_on_ceiling() : movementVector.y = gravityValue; movementVector.y += gravityValue
		if canFall : movementVector.y += gravityValue
		elif !canFall : get_tree().create_timer(coyoteValue).timeout.connect(func lambda() : canFall = true)
		return movementVector.y
	
	return 0
	
func get_axis() -> Vector2: 
	# returns whole axis as a vector2D
	return Vector2(get_horizontal(), get_vertical())
