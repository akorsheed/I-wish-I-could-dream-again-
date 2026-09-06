extends Node3D

enum ActState {
	NORMAL,
	BOOKCASE_HESITATING,
	DESK_SEATED,
	DESK_REST_HEAD,
	DESK_TRY_DREAM,
	ACT_COMPLETED
}

@onready var _dialogue_drawer = $HUD/DialogueDrawer
@onready var _player = get_node_or_null("scene/Player")
@onready var _prompt_ui = get_node_or_null("HUD/InteractionPrompt")
@onready var _fade_overlay = get_node_or_null("HUD/FadeOverlay")
@onready var _act_end_container = get_node_or_null("HUD/ActEndContainer")

var is_dialogue_running: bool = false
var _act_state: ActState = ActState.NORMAL
var _current_dialogue: String = ""

var _rustle_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer
var _lpf_effect: AudioEffectLowPassFilter = null
var _lpf_index: int = -1

func _ready() -> void:
	_dialogue_drawer.hide()
	_setup_audio()
	_connect_interaction_areas()

func _exit_tree() -> void:
	_cleanup_low_pass_filter()

func _setup_audio() -> void:
	_rustle_player = AudioStreamPlayer.new()
	_rustle_player.name = "RustlePlayer"
	_rustle_player.stream = _create_book_rustle_sound()
	_rustle_player.volume_db = -4.0
	add_child(_rustle_player)

	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.name = "HeartbeatPlayer"
	_heartbeat_player.stream = _create_heartbeat_sound()
	_heartbeat_player.volume_db = -2.0
	add_child(_heartbeat_player)

func _connect_interaction_areas() -> void:
	var desk_area = get_node_or_null("scene/DeskInteractionArea")
	if desk_area and not desk_area.interacted.is_connected(_on_desk_interacted):
		desk_area.interacted.connect(_on_desk_interacted)

	var bookcase_area = get_node_or_null("scene/BookcaseInteractionArea")
	if bookcase_area and not bookcase_area.interacted.is_connected(_on_bookcase_interacted):
		bookcase_area.interacted.connect(_on_bookcase_interacted)

	var window_area = get_node_or_null("scene/WindowInteractionArea")
	if window_area and not window_area.interacted.is_connected(_on_window_interacted):
		window_area.interacted.connect(_on_window_interacted)

func _input(event: InputEvent) -> void:
	if not is_dialogue_running:
		return

	if event.is_action_pressed("ui_accept"):
		_dialogue_drawer.next()
	elif event.is_action_pressed("ui_down"):
		_dialogue_drawer.next_option()
	elif event.is_action_pressed("ui_up"):
		_dialogue_drawer.previous_option()

func _unhandled_input(event: InputEvent) -> void:
	if is_dialogue_running:
		return

	var is_interact_pressed = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E) or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not is_interact_pressed:
		return

	if _act_state == ActState.DESK_REST_HEAD:
		get_viewport().set_input_as_handled()
		_advance_desk_rest_head()
	elif _act_state == ActState.DESK_TRY_DREAM:
		get_viewport().set_input_as_handled()
		_advance_desk_try_dream()

# -------------------------------------------------------------
# Interaction 1: Bookcase
# -------------------------------------------------------------
func _on_bookcase_interacted() -> void:
	if is_dialogue_running or _act_state != ActState.NORMAL:
		return

	_act_state = ActState.BOOKCASE_HESITATING
	if _player:
		_player.can_move = false

	_hide_prompt()
	var bookcase_area = get_node_or_null("scene/BookcaseInteractionArea")
	if bookcase_area and bookcase_area.has_method("hide_prompt"):
		bookcase_area.hide_prompt()

	# Play faint book rustle sound
	if _rustle_player:
		_rustle_player.play()

	# Lock player input for 2.0 seconds (simulating heavy, trembling hesitation)
	await get_tree().create_timer(2.0).timeout

	if _act_state == ActState.BOOKCASE_HESITATING:
		_act_state = ActState.NORMAL
		_current_dialogue = "act1_bookcase"
		_start_dialogue("act1_bookcase")

# -------------------------------------------------------------
# Interaction 2: Window
# -------------------------------------------------------------
func _on_window_interacted() -> void:
	if is_dialogue_running or _act_state != ActState.NORMAL:
		return

	if _player:
		_player.can_move = false

	_hide_prompt()
	var window_area = get_node_or_null("scene/WindowInteractionArea")
	if window_area and window_area.has_method("hide_prompt"):
		window_area.hide_prompt()

	_current_dialogue = "act1_window"
	_start_dialogue("act1_window")

# -------------------------------------------------------------
# Interaction 3: Desk & Dream Transition
# -------------------------------------------------------------
func _on_desk_interacted() -> void:
	if is_dialogue_running or _act_state != ActState.NORMAL:
		return

	_act_state = ActState.DESK_SEATED
	if _player:
		_player.can_move = false
		# Position character at the chair and face the desk surface/typewriter
		_player.global_position = Vector3(3.6, 0.0, -4.8)
		if _player.visuals:
			_player.visuals.rotation.y = atan2(-1.0, -0.2)
		var anim = _player.get_animation_player()
		if anim and anim.has_animation("idle"):
			anim.play("idle")

	_hide_prompt()
	var desk_area = get_node_or_null("scene/DeskInteractionArea")
	if desk_area and desk_area.has_method("hide_prompt"):
		desk_area.hide_prompt()

	_current_dialogue = "act1_desk"
	_start_dialogue("act1_desk")

func _on_dialogue_drawer_dialogue_ended() -> void:
	_dialogue_drawer.hide()
	is_dialogue_running = false

	if _current_dialogue == "act1_desk":
		# Prompt [E] Rest head on desk
		_act_state = ActState.DESK_REST_HEAD
		_show_custom_prompt("[E] Rest head on desk")
	else:
		_current_dialogue = ""
		if _player and _act_state == ActState.NORMAL:
			_player.can_move = true

func _advance_desk_rest_head() -> void:
	_act_state = ActState.DESK_TRY_DREAM
	# Engage audio low-pass filter and begin muffled heartbeat
	_enable_low_pass_filter(true)
	if _heartbeat_player:
		_heartbeat_player.play()
	# Update prompt
	_show_custom_prompt("[E] Try to dream")

func _advance_desk_try_dream() -> void:
	_act_state = ActState.ACT_COMPLETED
	_hide_prompt()

	# Smoothly fade screen to black
	if _fade_overlay:
		var fade_tween = create_tween().set_parallel(true)
		fade_tween.tween_property(_fade_overlay, "color:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if _heartbeat_player:
			fade_tween.tween_property(_heartbeat_player, "volume_db", -36.0, 4.0)

		await fade_tween.finished

	# Reveal conclusion typography
	if _act_end_container:
		var vbox = _act_end_container.get_node_or_null("VBoxContainer")
		if vbox:
			var text_tween = create_tween()
			text_tween.tween_property(vbox, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# -------------------------------------------------------------
# HUD & UI Helpers
# -------------------------------------------------------------
func _start_dialogue(dialogue: String) -> void:
	_dialogue_drawer.show()
	_dialogue_drawer.start(dialogue)
	is_dialogue_running = true
	if _player:
		_player.can_move = false

func _show_custom_prompt(text: String) -> void:
	if _prompt_ui:
		var label = _prompt_ui.find_child("Label", true, false) as Label
		if label:
			label.text = text
		_prompt_ui.visible = true
		var vp_size = get_viewport().get_visible_rect().size
		_prompt_ui.position = Vector2((vp_size.x - _prompt_ui.size.x) * 0.5, vp_size.y * 0.72)

func _hide_prompt() -> void:
	if _prompt_ui:
		_prompt_ui.visible = false

func _on_restart_scene_button_pressed() -> void:
	_cleanup_low_pass_filter()
	get_tree().reload_current_scene()

# -------------------------------------------------------------
# Procedural Audio & DSP
# -------------------------------------------------------------
func _enable_low_pass_filter(enabled: bool) -> void:
	if enabled:
		if _lpf_effect == null:
			_lpf_effect = AudioEffectLowPassFilter.new()
			_lpf_effect.cutoff_hz = 20000.0
			_lpf_index = AudioServer.get_bus_effect_count(0)
			AudioServer.add_bus_effect(0, _lpf_effect, _lpf_index)
		var tween = create_tween()
		tween.tween_property(_lpf_effect, "cutoff_hz", 380.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_cleanup_low_pass_filter()

func _cleanup_low_pass_filter() -> void:
	if _lpf_effect != null and _lpf_index >= 0 and _lpf_index < AudioServer.get_bus_effect_count(0):
		AudioServer.remove_bus_effect(0, _lpf_index)
		_lpf_effect = null
		_lpf_index = -1

func _create_book_rustle_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count = int(22050 * 0.75)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	var prev_noise: float = 0.0
	for i in range(sample_count):
		var t = float(i) / float(sample_count)
		var envelope = sin(t * PI) * exp(-t * 1.8)
		var white = randf_range(-1.0, 1.0)
		prev_noise = prev_noise * 0.72 + white * 0.28
		var sample_val = int(clamp(prev_noise * envelope * 0.5, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
	stream.data = data
	return stream

func _create_heartbeat_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(22050 * 1.25)
	var sample_count = stream.loop_end
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var sec = float(i) / 22050.0
		var val: float = 0.0
		# First beat ("lub")
		if sec >= 0.0 and sec < 0.22:
			var s = sec / 0.22
			var env = sin(s * PI) * exp(-s * 4.5)
			val += sin(s * 2.0 * PI * 46.0) * env * 0.85
		# Second beat ("dub")
		if sec >= 0.28 and sec < 0.48:
			var s = (sec - 0.28) / 0.20
			var env = sin(s * PI) * exp(-s * 4.5)
			val += sin(s * 2.0 * PI * 56.0) * env * 0.65

		var sample_val = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
	stream.data = data
	return stream
