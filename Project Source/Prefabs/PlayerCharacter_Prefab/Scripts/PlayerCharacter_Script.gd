extends CharacterBody2D
class_name PlayerCharacter_Prefab
# Script made by Furokawa ;)
# Purpose : Handle some player actions (4 d moment)

@export_group("Settings")
@export var deltaMultiplier : float = 100.0

@export var movementSpeed : float = 75.0
@export var jumpForce : float = 200.0
@export var gravityValue : float = 9.80
@export_range(0.0, 5.0) var coyoteTime : float = 0.3

@export_exp_easing('attenuation') var movementWeight : float = 0.3
@export_exp_easing('attenuation') var airResistance : float = 0.5

@export_group("Components")
@export var PlayerCharacter_Sprite : Sprite2D = null

@export var inputDetection_Component : InputDetection_Component = null
@export var stateManager_Component : PlayerStateManager_Component = null

func _ready() -> void:
	if inputDetection_Component == null:
		return

	inputDetection_Component.jumpValue = jumpForce
	inputDetection_Component.gravityValue = gravityValue
	inputDetection_Component.speedValue = movementSpeed
	inputDetection_Component.coyoteValue = coyoteTime

func _physics_process(delta : float) -> void:
	if inputDetection_Component == null:
		printerr("The InputDetection Component is NULL!!!")
		return
	
	if PlayerCharacter_Sprite != null && inputDetection_Component.get_horizontal() != 0:
		PlayerCharacter_Sprite.flip_h = inputDetection_Component.get_horizontal() < 0
		
	
	velocity.x = lerp(
		velocity.x,
		inputDetection_Component.get_horizontal() * (delta * deltaMultiplier),
		movementWeight
	)
	velocity.y = lerp(
		velocity.y,
		inputDetection_Component.get_vertical() * (delta * (deltaMultiplier * 2)),
		airResistance
	)
	move_and_slide()
