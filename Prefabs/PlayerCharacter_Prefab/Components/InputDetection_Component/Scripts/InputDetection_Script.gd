extends Node
class_name InputDetection_Component

# Script made by Furokawa ;)
# Purpose : Handle player inputs
# WARNING : THIS IS A DEDICATED SCRIPT AND MAY NOT WORK ON OTHER NODES
# Don't fuck with this other either

@export_group("Settings")
@export var detect_X_Axis : bool = true
@export var detect_Y_Axis : bool = true

@export_range(1.0, 10.0, 0.01) var wallSlide_Multiplier : float = 1.0
@export_range(0.01, 1.0, 0.01) var normalizeGrab_Time : float = 0.15

@export var totalStamina_Value : float = 30.0
@export var staminaValue : float = self.totalStamina_Value


@export_group("Components")
@export var targetNode : PlayerCharacter_Prefab = null

@export var collitionShape_Head : ShapeCast2D = null
@export var collitionShape_Body : ShapeCast2D = null

@export var grabTimer_Component : Timer = null

var controlVector : Vector2 = Vector2.ZERO

var speedValue : float = 75
var jumpValue : float = 300
var gravityValue : float = 9.80
var coyoteTime : float = 3.0

var canFall : bool = true
var canGrab : bool = false
var canSlide : bool = true

func _ready() -> void:
	# Safe way to use this component 
	if targetNode == null:
		targetNode = get_parent()
		
	speedValue = targetNode.movementSpeed
	jumpValue = targetNode.jumpForce
	gravityValue = targetNode.gravityValue
	coyoteTime = targetNode.coyoteTime

func get_Horizontal() -> float:
	
	if !detect_X_Axis:
		return controlVector.x
		
	controlVector.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	
	if Input.is_key_pressed(KEY_SHIFT) && controlVector.x != 0:
		return controlVector.x * speedValue / 3
		
	
	return controlVector.x * speedValue

func get_Vertical() -> float:
	
	if targetNode.is_on_floor() :
		canFall = false; canGrab = true; 
		canSlide = true; detect_X_Axis = true
		controlVector.y = 0; grabTimer_Component.stop()
	
	if (targetNode.is_on_floor() || !canFall) && Input.is_action_pressed("ui_up") :
		canFall = true; controlVector.y = 0
		controlVector.y -= jumpValue
	
	elif (!targetNode.is_on_floor() && controlVector.y < 0)  && Input.is_action_just_released("ui_up") :
		controlVector.y /= 4
	
	elif !targetNode.is_on_floor() :
		controlVector.y += gravityValue
		if targetNode.is_on_ceiling() : controlVector.y = gravityValue
		elif !canFall : get_tree().create_timer(coyoteTime).timeout.connect( func lambda() : canFall = true )
	
	if (targetNode.is_on_wall_only() && !is_OnEdge()) && (canSlide && clamp(get_Horizontal(), -1, 1) == -targetNode.get_wall_normal().x) :
		canFall = true; canGrab = false; controlVector.y = 0
		controlVector.y += gravityValue * wallSlide_Multiplier
	
	if (targetNode.is_on_wall_only() && !is_OnEdge()) && (Input.is_action_just_pressed("ui_up") && clamp(get_Horizontal(), -1, 1) == -targetNode.get_wall_normal().x) :
		canFall = true; canSlide = false
		detect_X_Axis = false; canGrab = true
		
		controlVector.x = 0; controlVector.y = 0
		get_tree().create_timer(0.3).timeout.connect( func lambda() : canSlide = true; detect_X_Axis = true )
		
		controlVector.x += (jumpValue / 2) * targetNode.get_wall_normal().x
		controlVector.y -= jumpValue
	
	if (is_OnEdge() && canGrab) && staminaValue > 0 :
		canFall = false; canSlide = false; detect_X_Axis = false
		controlVector.y = 0; edgeGrab_Normalize()
		if grabTimer_Component.is_stopped() : grabTimer_Component.start()
	
	elif (is_OnEdge() && canGrab) && staminaValue <= 0 :
		canFall = false; canSlide = true
		canGrab = false; detect_X_Axis = true
		if grabTimer_Component.is_stopped() : grabTimer_Component.start()
	
	if (is_OnEdge() && canGrab) && Input.is_action_just_pressed("ui_down") :
		canFall = true; canSlide = true; canGrab = false
	
	elif (is_OnEdge() && canGrab) && Input.is_action_just_pressed("ui_up") :
		canFall = true; canSlide = false
		canGrab = false; detect_X_Axis = false
		controlVector.x = 0; controlVector.y = 0
		controlVector.y -= jumpValue 
		controlVector.x -= (jumpValue / 4) * targetNode.get_wall_normal().x 
		
	return controlVector.y

func get_Axis() -> Vector2:
	return Vector2(
		clamp(get_Horizontal(), -1, 1),
		clamp(get_Vertical(), -1, 1)
	)

func is_OnEdge() -> bool:
	return ( collitionShape_Body.is_colliding() && !collitionShape_Head.is_colliding() && !targetNode.is_on_floor() )

func edgeGrab_Normalize() -> void:
	targetNode.position.y = lerp(
		targetNode.position.y,
		collitionShape_Body.get_collision_point( collitionShape_Body.get_collision_count() - 1 ).y,
		normalizeGrab_Time
	)

func stamina_Charge() -> void:
	staminaValue = lerp(staminaValue, staminaValue + 0.5, 0.15); staminaValue = clamp(staminaValue, 0, 30)

func stamina_Timer() -> void:
	staminaValue -= 1 
