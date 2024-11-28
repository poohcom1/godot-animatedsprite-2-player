@tool
extends EditorInspectorPlugin

const NodeSelectorProperty = preload("./NodeSelectorProperty.gd")
const AnimationSelectorProperty = preload("./AnimationSelectorProperty.gd")

var node_selector: NodeSelectorProperty
var animation_selector: AnimationSelectorProperty

# Properties
var anim_player: AnimationPlayer

# Signals
signal animation_updated(animation_player: AnimationPlayer)

func _can_handle(object):
	if object is AnimationPlayer:
		anim_player = object

		return true
	return false

## Create UI here
func _parse_end(object: Object):
	var header = CustomEditorInspectorCategory.new("Import AnimatedSprite2D/3D")

	# AnimatedSprite2D Node selector
	node_selector = NodeSelectorProperty.new(anim_player)
	node_selector.label = "AnimatedSprite2D/3D Node"

	node_selector.animation_updated.connect(
		_on_animation_updated,
		CONNECT_DEFERRED
		)
	node_selector.animated_sprite_updated.connect(
		_on_animated_sprite_updated,
		CONNECT_DEFERRED
		)

	animation_selector = AnimationSelectorProperty.new(anim_player)
	animation_selector.label = "Animations"

	# Import button
	var button := Button.new()
	button.text = "Import"
	button.get_minimum_size().y = 26
	button.button_down.connect(_on_import_button_down)

	var buttonstyle = StyleBoxFlat.new()
	buttonstyle.bg_color = Color8(32, 37, 49)
	button.set("custom_styles/normal", buttonstyle)

	var container = VBoxContainer.new()
	container.add_spacer(true)

	container.add_child(header)
	container.add_child(node_selector)
	container.add_child(animation_selector)
	container.add_spacer(false)
	container.add_child(button)

	add_custom_control(container)


func _on_animation_updated():
	emit_signal("animation_updated", anim_player)

func _on_animated_sprite_updated(animated_sprite: AnimatedSprite2D):
	animation_selector.get_items(animated_sprite)

func _on_import_button_down():
	node_selector.convert_sprites(animation_selector.animations_selected)

# Child class
class CustomEditorInspectorCategory extends Control:
	var title: String = ""
	var icon: Texture2D = null

	func _init(p_title: String, p_icon: Texture2D = null):
		title = p_title
		icon = p_icon

		tooltip_text = "AnimatedSprite to AnimationPlayer Plugin"

	func _get_minimum_size() -> Vector2:
		var font := get_theme_font(&"bold", &"EditorFonts");
		var font_size := get_theme_font_size(&"bold_size", &"EditorFonts");

		var ms: Vector2
		ms.y = font.get_height(font_size);
		if icon:
			ms.y = max(icon.get_height(), ms.y);

		ms.y += get_theme_constant(&"v_separation", &"Tree");

		return ms;

	func _draw() -> void:
		var sb := get_theme_stylebox(&"bg", &"EditorInspectorCategory")
		draw_style_box(sb, Rect2(Vector2.ZERO, size))

		var font := get_theme_font(&"bold", &"EditorFonts")
		var font_size := get_theme_font_size(&"bold_size", &"EditorFonts")

		var hs := get_theme_constant(&"h_separation", &"Tree")

		var w: int = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x;
		if icon:
			w += hs + icon.get_width();


		var ofs := (get_size().x - w) / 2;

		if icon:
			draw_texture(icon, Vector2(ofs, (get_size().y - icon.get_height()) / 2).floor())
			ofs += hs + icon.get_width()

		var color := get_theme_color(&"font_color", &"Tree")
		draw_string(font, Vector2(ofs, font.get_ascent(font_size) + (get_size().y - font.get_height(font_size)) / 2).floor(), title, HORIZONTAL_ALIGNMENT_LEFT, get_size().x, font_size, color);
