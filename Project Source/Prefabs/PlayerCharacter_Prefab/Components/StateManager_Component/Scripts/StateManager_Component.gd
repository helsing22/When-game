extends Node
class_name PlayerStateManager_Component
# Script made by Furokawa ;)
# Purpose : Handle state machine & manage states & animations
# Functions listed :
# switch_State
# handle_State
# IMPORTANT : DO NOT REUSE THIS SCRIPT THIS IS DEDICATED NOT GENERIC
# Don't fuck with this ok? 

enum playerStates {IDLE, RUN, HURT, DEAD, ATTACK}

@export_group("Settings")
@export var currentState : playerStates = playerStates.IDLE

@export var animationPrefix : String = "Anim_"

@export_group("Components")
@export var targetEntity : CharacterBody2D = null
@export var inputDetection_Component : InputDetection_Component = null
@export var targetAnimation_Tree : AnimationTree = null
var targetStateMachine_Playback : AnimationNodeStateMachinePlayback = null

signal stateChanged(newState : playerStates)

func _ready() -> void:
	targetEntity = get_parent()
	targetStateMachine_Playback = targetAnimation_Tree.get("parameters/playback")

func _process(_delta : float) -> void:
	if targetEntity == null:
		return
	handle_State()

func switch_State(newState : playerStates) -> void:
	#Switch d states like a bullet case on a gun, new in, old out & emits a signal when changed
	if newState == null || currentState == newState:
		return
	
	currentState = newState
	stateChanged.emit(currentState)

func handle_State() -> void:
	if targetStateMachine_Playback == null:
		return
	
	# Easy on this, get mov axis and then check wheter it's 0 r not, dawg
	# then flips the sprite according to velocity if moving
	if inputDetection_Component.get_axis() != Vector2.ZERO :
		
		if inputDetection_Component.get_horizontal() != 0:
			switch_State(playerStates.RUN)
	
	elif inputDetection_Component.get_axis() == Vector2.ZERO :
		switch_State(playerStates.IDLE)
	
	# this only checks the current state of the target
	match currentState:
		playerStates.IDLE:
			targetStateMachine_Playback.travel(animationPrefix + "Idle")

		playerStates.RUN:
			targetStateMachine_Playback.travel(animationPrefix + "Run")
			pass

		playerStates.HURT:
			pass

		playerStates.DEAD:
			pass

		playerStates.ATTACK:
			pass
