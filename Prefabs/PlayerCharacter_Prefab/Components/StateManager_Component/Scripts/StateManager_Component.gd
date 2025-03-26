extends Node
class_name PlayerStateManager_Component
# Script made by Furokawa ;)
# Purpose : Handle state machine & manage states & animations
# WARNING : DO NOT REUSE THIS SCRIPT THIS IS DEDICATED NOT GENERIC
# Don't fuck with this ok? 

@export_group("Settings")

@export_group("Components")
@export var targetNode : PlayerCharacter_Prefab = null
@export var targetNode_Sprite : Sprite2D = null

@export var targetAnimation_Tree : AnimationTree = null
@export var inputDetection_Component : InputDetection_Component = null

@export var animationsPrefix : String = "Player"
@export var currentState : playerStates = playerStates.IDLE

enum playerStates {
	IDLE,
	JUMP,
	FALL,
	WALK,
	RUN,
	ATTACK,
	EDGE
}

var targetAimation_Playback : AnimationNodeStateMachinePlayback = null
signal stateChanged(currentState : playerStates)

func _ready() -> void:
	
	if targetNode == null:
		targetNode = get_parent()
	
	if targetAnimation_Tree != null:
		targetAimation_Playback = targetAnimation_Tree.get("parameters/playback")

func _process(_delta : float) -> void:
	determinate_State(); handle_State()

func switch_State(newState : playerStates) -> void:
	if newState == currentState:
		return
	
	currentState = newState
	stateChanged.emit(currentState)

func determinate_State() -> void:
	
	if inputDetection_Component.get_Axis() != Vector2.ZERO || (inputDetection_Component.is_OnEdge() || targetNode.is_on_wall_only()):
		
		if inputDetection_Component.is_OnEdge() || targetNode.is_on_wall_only():
			targetNode_Sprite.flip_h = targetNode.get_wall_normal().x > 0
			switch_State(playerStates.EDGE); return
		
		if inputDetection_Component.get_Vertical() < 0:
			switch_State(playerStates.JUMP); return
		
		elif inputDetection_Component.get_Vertical() > 0:
			switch_State(playerStates.FALL); return
		
		if inputDetection_Component.get_Horizontal() != 0 && !targetNode.is_on_wall():
			targetNode_Sprite.flip_h = inputDetection_Component.get_Horizontal() < 0
			switch_State(playerStates.RUN); return
	
	if inputDetection_Component.get_Axis() == Vector2.ZERO && !(inputDetection_Component.is_OnEdge() || targetNode.is_on_wall_only()):
		switch_State(playerStates.IDLE)

func handle_State() -> void:
	
	match (currentState):
		
		playerStates.IDLE:
			targetAimation_Playback.travel(animationsPrefix + "_Idle")
		
		playerStates.RUN:
			targetAimation_Playback.travel(animationsPrefix + "_Run")
		
		playerStates.JUMP:
			targetAimation_Playback.travel(animationsPrefix + "_Jump")
		
		playerStates.FALL:
			targetAimation_Playback.travel(animationsPrefix + "_Fall")
		
		playerStates.EDGE:
			targetAimation_Playback.travel(animationsPrefix + "_EdgeGrab")
