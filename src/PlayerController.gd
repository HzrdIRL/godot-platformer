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
var _wall_grab_timer: float = 0.0
var _wall_grab_limit: int = 1
var _wall_slide_gravity: float = 100.0
var _is_wall_grabbing: bool = false

func _ready() -> void:
	_jump_cancel_threshold = jump_height / 4
	
func _input(event) -> void:
	if event.is_action_pressed("jump"):
			_jump()
	elif event.is_action_released("jump"):
		_cancel_jump()

func _jump() -> void:
	_is_sprint_jumping = true if _is_sprinting else false
	if is_on_floor():
		velocity.y = jump_height

func _cancel_jump():
	if velocity.y < _jump_cancel_threshold:
		velocity.y = _jump_cancel_threshold

func _physics_process(delta: float) -> void:
	var horizontal_input_direction = Input.get_axis("ui_left", "ui_right")
	_handle_aerial_states(horizontal_input_direction, delta)
	
	_handle_movement(horizontal_input_direction, delta)
	
	move_and_slide()
	
func _handle_aerial_states(direction, delta):
	if is_on_floor():
		_set_landing_states()
	elif is_on_wall_only() and direction != 0:
		_handle_wall_sliding(delta)
	else:
		_handle_falling(delta)
		
func _handle_falling(delta):
	if _is_wall_grabbing:
		_wall_grab_timer = _wall_grab_limit
	_apply_gravity(delta, gravity)
 
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
		_wall_grab_timer = 0.0
		
func _handle_wall_sliding(delta):
	_is_sprint_jumping = false
	if _wall_grab_timer < _wall_grab_limit and velocity.y >= 0.0:
		_is_wall_grabbing = true
		_wall_grab_timer += delta
		velocity.y = 0.0
	elif _is_wall_grabbing:
		_is_wall_grabbing = false
		_apply_gravity(delta, _wall_slide_gravity)
	else:
		_is_wall_grabbing = false
		_apply_gravity(delta, gravity)
	
func _apply_gravity(delta: float, gravity: float) -> void:
	velocity.y += gravity * delta
	_has_landed = false
	
func _set_sprint_state():
	_is_sprinting = true if Input.is_action_pressed("sprint") and is_on_floor() else false
	
func _move(direction: float):
	var sprint_modifier: float = sprint_speed if _is_sprinting or _is_sprint_jumping else 0
	velocity.x = direction * (speed + sprint_modifier)

func _apply_ground_drag(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * delta * 8)
	
func _apply_air_drag(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * delta * 2)
