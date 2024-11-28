@tool
extends EditorProperty
## @desc Inspector property for selecting the animations to import.
##

const ID_SELECT_ALL := 0
const ID_SELECT_NONE := 1
const ID_SEPARATOR := 2
const RESERVED_ID_COUNT := 3

var anim_player: AnimationPlayer
var menu_button := MenuButton.new()

var animations: Array[AnimationState] = []
var animations_selected: Array[String]:
	get:
		var result: Array[String] = []
		for animation in animations:
			if animation.selected:
				result.append(animation.name)
		return result

signal animations_updated()

func _init(_anim_player):
	anim_player = _anim_player

	menu_button.clip_text = true
	# Add the control as a direct child of EditorProperty node.
	add_child(menu_button)
	# Make sure the control is able to retain the focus.
	add_focusable(menu_button)

	_configure_popup()
	_update_button_label()

func _ready():
	get_items(null)

func _configure_popup():
	var popup = menu_button.get_popup()

	popup.clear()
	popup.hide_on_checkable_item_selection = false
	popup.hide_on_item_selection = false
	popup.id_pressed.connect(_on_popup_id_pressed)

func _update_button_label():
	var selected_count = 0
	for i in range(len(animations)):
		var animation = animations[i]
		if animation.selected:
			selected_count += 1

	menu_button.text = "%d of %d Selected" % [selected_count, len(animations)]

func get_items(animated_sprite: AnimatedSprite2D):
	if animated_sprite == null:
		menu_button.get_popup().clear()
		return

	_populate_animations(animated_sprite)
	_populate_menu()
	_update_button_label()

func _populate_animations(animated_sprite: AnimatedSprite2D):
	animations.clear()

	var animation_names = animated_sprite.sprite_frames.get_animation_names()

	print("[AS2P] %s" % [animation_names])

	for i in range(len(animation_names)):
		var name = animation_names[i]

		var animation := AnimationState.new(
			i + RESERVED_ID_COUNT,
			name
			)

		animations.append(animation)

func _populate_menu():
	var popup = menu_button.get_popup()
	popup.clear()

	popup.add_item("Select All", ID_SELECT_ALL)
	popup.add_item("Select None", ID_SELECT_NONE)
	popup.add_separator("", ID_SEPARATOR)

	for i in range(len(animations)):
		var animation = animations[i]

		popup.add_check_item(animation.name, animation.id)
		popup.set_item_checked(animation.id, animation.selected)

func _on_popup_id_pressed(id: int):
	var popup = menu_button.get_popup()

	if id == ID_SELECT_ALL:
		for animation in animations:
			animation.selected = true

			popup.set_item_checked(animation.id, animation.selected)

		_update_button_label()
	elif id == ID_SELECT_NONE:
		for animation in animations:
			animation.selected = false

			popup.set_item_checked(animation.id, animation.selected)

		_update_button_label()
	elif id >= RESERVED_ID_COUNT:
		# Animation selection
		var animation = animations[_menu_id_to_animation_index(id)]

		animation.selected = !animation.selected

		popup.set_item_checked(id, animation.selected)

		_update_button_label()

func _menu_id_to_animation_index(id: int):
	for i in range(len(animations)):
		if animations[i].id == id:
			return i

	return -1

func get_tooltip_text():
	return "Animations to import."

class AnimationState:
	var id: int
	var name: String
	var selected: bool

	func _init(id: int, name: String, selected: bool = true) -> void:
		self.id = id
		self.name = name
		self.selected = selected
