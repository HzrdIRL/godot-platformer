# src/PlayerController.gd
extends CharacterBody2D

@export var speed: float = 150.0
@export var sprint_speed: float = 75.0
@export var jump_height: float = -200.0 # Negative for upward movement
@export var gravity: float = 400.0


var _jump_cancel_threshold: float
var _is_sprint_jumping: bool = false
var _is_sprinting: bool = false
var _has_landed: bool = true

func _ready() -> void:
	_jump_cancel_threshold = jump_height / 4

func _input(event) -> void:
	if event.is_action_pressed("jump"):
			_jump()
	elif event.is_action_released("jump"):
		_cancel_jump()

func _jump() -> void:
	if is_on_floor():
		velocity.y = jump_height
		_is_sprint_jumping = true if _is_sprinting else false

func _cancel_jump():
	if velocity.y < _jump_cancel_threshold:
		velocity.y = _jump_cancel_threshold

func _physics_process(delta: float) -> void:
	_handle_aerial_states(delta)
	
	_handle_movement(Input.get_axis("ui_left", "ui_right"), delta)
	
	move_and_slide()
	
func _handle_aerial_states(delta):
	if is_on_floor():
		_set_landing_states()
	else:
		_apply_gravity(delta)
		_has_landed = false
		
func _handle_movement(direction: float, delta: float) -> void:
	if direction != 0:
		_set_sprint_state()
		_move(direction)
	elif is_on_floor():
		_apply_ground_drag(delta)
	else: 
		_apply_air_drag(delta)

func _set_landing_states():
	# do this to avoid setting landing states while player is 
	# still colliding with the floor, at the start of a jump
	if not _has_landed:
		_has_landed = true
		_is_sprint_jumping = false
	
func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	
func _set_sprint_state():
	_is_sprinting = true if Input.is_action_pressed("sprint") and is_on_floor() else false
	
func _move(direction: float):
	var sprint_modifier: float = sprint_speed if _is_sprinting or _is_sprint_jumping else 0
	velocity.x = direction * (speed + sprint_modifier)

func _apply_ground_drag(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * delta * 8)
	
func _apply_air_drag(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * delta * 2)
