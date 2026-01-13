extends Sprite2D
var current_device_id = 0
var wish_opacity = 0.0
const mouse1_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/Keyboard & Mouse/Dark/Mouse_Left_Key_Dark.png"
)
const x_key_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/Keyboard & Mouse/Dark/X_Key_Dark.png"
)
const xbox_west_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/Xbox Series/XboxSeriesX_X.png"
)
const playstation_west_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/PS5/PS5_Square.png"
)
const nintendo_west_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/Switch/Switch_X.png"
)
const steamdeck_west_sprite := preload(
	"res://Xelu_Free_Controller&Key_Prompts/Steam Deck/SteamDeck_X.png"
)

func _ready():
	modulate.a = 0.0
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	await get_tree().create_timer(8.0).timeout
	wish_opacity = 1.0

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		current_device_id = device_id
	else:
		current_device_id = 0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("control_scheme_wasd"):
		self.texture = mouse1_sprite
	elif Input.is_action_just_pressed("control_scheme_arrowkeys"):
		self.texture = x_key_sprite
	elif Input.is_action_just_pressed("control_scheme_controller"):
		var namehas = func(s): return Input.get_joy_name(current_device_id).contains(s)
		if (namehas.call("PlayStation") or namehas.call("PS") or namehas.call("DualShock")
				or namehas.call("DualSense")):
			self.texture = playstation_west_sprite
		elif (namehas.call("Switch") or namehas.call("Nintendo")):
			self.texture = nintendo_west_sprite
		elif (namehas.call("Xbox")):
			self.texture = xbox_west_sprite
		else:
			self.texture = steamdeck_west_sprite

func _process(delta: float) -> void:
	modulate.a = move_toward(modulate.a, wish_opacity, delta)
	if modulate.a == 1.0: wish_opacity = 0.5
	elif modulate.a == 0.5: wish_opacity = 1.0
