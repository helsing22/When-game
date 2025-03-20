extends CharacterBody2D

	#no se en que cambia esto de la fincion get_gravity use un tutorial para "mejorar" la gravedad
#	(la veo igual)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var movement_speed: float = 60.0
@export var run_speed: float = 120 
@export var acceleration: float = 400.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -350.0
@export var air_resistance: float = 150.0
@export var air_acceleration: float = 275.0

enum states {
	IDLE,
	RUN,
	WALCK,
	JUMP,
	FALL,
	LEDGE_GRAB,
}


#se me paso poner el State de Walck cambialo esta Walck y Run cuando presiona Shift


const state_names := [
	"IDLE",
	"RUN",
	"WALCK",
	"JUMP",
	"FALL",
	"LEDGE_GRAB"
]

var state = states.IDLE

func _ready() -> void:
	pass

#jump buffer
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		$JumpBuffer.start()

func _physics_process(delta: float) -> void:
	
	# Directional input
	var input_axis = Input.get_axis("move_left", "move_right")

	# Revisa si esta en el piso
	var was_on_floor = is_on_floor()

	# girar el sprite si lp necesita
	if input_axis != 0 and state != states.LEDGE_GRAB:
		anim.flip_h = (input_axis < 0)

	# Desabilitar el LedgeGrab colider si no se usa
	$LedgeGrab.disabled = state in [states.RUN, states.IDLE] or velocity.y < 0 or (state != states.LEDGE_GRAB and $TopCheck.is_colliding())

	# Comprobar el Ledge Grab en el aire
	if state in [states.JUMP, states.FALL]:
		check_ledge_grab()

	# Comprobar si esta aterrizando y cambiar estado
	if is_on_floor() and state != states.LEDGE_GRAB:
		if velocity.x != 0 and Input.is_action_pressed("sprint"):
			state = states.RUN
		if velocity.x != 0:
			state = states.WALCK
		if velocity.x == 0:
			state = states.IDLE

	# comprobar si esta cayendo
	if !is_on_floor() and state in [states.IDLE, states.RUN, states.WALCK]:
		state = states.FALL

	# Movimientos en el aire
	if state in [states.JUMP, states.FALL]:
		handle_jump_input()
		apply_gravity(delta)
		handle_air_acceleration(input_axis, delta)
		apply_air_resistance(input_axis, delta)

	# Movimientos de estado en la tierra
	
	if state in [states.IDLE, states.WALCK, states.RUN]:
		handle_jump_input()
		handle_acceleration(input_axis, delta)
		apply_friction(input_axis, delta)
		

	# Animaciones en los distintos estados
	match state:
		states.IDLE:
			anim.play("idle")
		states.WALCK:
			anim.play("walck")
		states.RUN:
			anim.play("run")
		states.JUMP:
			pass
		states.FALL:
			anim.play("fall")
		states.LEDGE_GRAB:
			if $FloorCheck.is_colliding():
				state = states.IDLE
			velocity.x = 0
			var collider = $WallCheck.get_collision_normal(0)
			if collider.x == -1:
				anim.flip_h = false
				if not is_on_wall():
					velocity.x = 25
			else:
				anim.flip_h = true
				if not is_on_wall():
					velocity.x = -25
			anim.play("ledge_grab")
			if $TopCheck.is_colliding():
				velocity.y = 80
			handle_jump_input()

	# Applica movimiento
	move_and_slide()

	# Iniciar el coyote time si se salio del Ledge Grab
	if !is_on_floor() and was_on_floor:
		$CoyoteTimer.start()


func apply_gravity(delta: float) -> void:
	if not is_on_floor() and velocity.y < 700:
		velocity.y += gravity * delta

func handle_acceleration(input_axis, delta) -> void:
	# condicion de sprint usando la aceleracion
	if input_axis == 1 and Input.is_action_pressed("sprint"):
		state = states.RUN
		velocity.x = move_toward(velocity.x, run_speed * input_axis, acceleration * delta * 4)
	elif input_axis == -1 and Input.is_action_pressed("sprint"):
		state = states.RUN
		velocity.x = move_toward(velocity.x, run_speed * input_axis, acceleration * delta * 4)
	
	# movimiento utilizando la aceleracion
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, acceleration * delta)

func apply_friction(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_air_acceleration(input_axis, delta) -> void:
	#mismo caso de la aceleracion : la aceleracion es mas veloz cuando te das vuelta
	if input_axis == 1 and Input.is_action_pressed("sprint"):
		velocity.x = move_toward(velocity.x, run_speed * input_axis, air_acceleration * delta * 4)
	elif input_axis == -1 and Input.is_action_pressed("sprint"):
		velocity.x = move_toward(velocity.x, run_speed * input_axis, air_acceleration * delta * 4)
	
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis,air_acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, air_acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, movement_speed * input_axis, air_acceleration * delta)

#recistencia al aire
func apply_air_resistance(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, air_resistance * delta)

# saltar
func handle_jump_input() -> void:
	if is_on_floor() or $CoyoteTimer.time_left > 0:
		if $JumpBuffer.time_left > 0:
			velocity.y = jump_velocity
			anim.play("jump")
			state = states.JUMP
			$JumpBuffer.stop()

#comprobar ledge grab
func check_ledge_grab() -> void:
	if $WallCheck.is_colliding() and not $FloorCheck.is_colliding() and velocity.y == 0:
		state = states.LEDGE_GRAB
