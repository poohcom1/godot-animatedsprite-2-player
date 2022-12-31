@tool
extends EditorProperty
## @desc Inspector property for selecting the animation node,
##			and handles the animation import process.
##

var anim_player: AnimationPlayer
var drop_down := OptionButton.new()

var replace = false

signal animation_updated()

func set_override(_replace):
	replace = _replace

func get_animatedsprite() -> AnimatedSprite2D:
	var root = get_tree().edited_scene_root
	return _get_animated_sprites(root)[drop_down.selected]

func _get_animated_sprites(root: Node) -> Array:
	var asNodes := []

	for child in root.get_children():
		asNodes += _get_animated_sprites(child)

	if root is AnimatedSprite2D:
		asNodes.append(root)

	return asNodes

func _init(_anim_player):
	anim_player = _anim_player

	drop_down.clip_text = true
	# Add the control as a direct child of EditorProperty node.
	add_child(drop_down)
	# Make sure the control is able to retain the focus.
	add_focusable(drop_down)

	drop_down.clear()

func _ready():
	get_items()


func get_items():
	drop_down.clear()

	var root = get_tree().edited_scene_root
	var anim_sprites := _get_animated_sprites(root)

	for i in range(len(anim_sprites)):
		var anim_sprite = anim_sprites[i]

		drop_down.add_item(anim_player.get_path_to(anim_sprite), i)

func convert_sprites():
	var animated_sprite: AnimatedSprite2D = get_node(get_animatedsprite().get_path())

	var count = 0

	var sprite_frames := animated_sprite.frames

	if not sprite_frames:
		print("[AS2P] Selected AnimatedSprite2D has no frames!")

	for anim in sprite_frames.get_animation_names():
		if anim.is_empty():
			printerr("[AS2P] SpriteFrames on AnimatedSprite2D '%s' has an \
animation named empty string '', it will be ignored" % animated_sprite.name)
			continue

		var frame_count = sprite_frames.get_frame_count(anim)
		var fps = sprite_frames.get_animation_speed(anim)
		var looping = sprite_frames.get_animation_loop(anim)

		if add_animation(
			anim_player.get_node(anim_player.root_node).get_path_to(animated_sprite),
			anim,
			frame_count,
			fps,
			looping):

			count += 1

	print("[AS2P] %s %d animations!" % ["Replaced" if replace else "Added", count])

	emit_signal("animation_updated")

func add_animation(anim_sprite: NodePath, anim: String, count: int, fps: float, looping: bool):
	# We add the converted animation to the [Global] animation library,
	# which corresponding to the empty string "" key
	var global_animation_library: AnimationLibrary
	if anim_player.has_animation_library(&""):
		# The [Global] animation library already exists, so get it
		# The only reason we check has_animation_library then call
		# get_animation_library instead of just checking if get_animation_library
		# returns null, is that get_animation_library causes an error when no
		# library is found.
		global_animation_library = anim_player.get_animation_library(&"")
	else:
		# The [Global] animation library does not exist yet, so create it
		global_animation_library = AnimationLibrary.new()
		anim_player.add_animation_library(&"", global_animation_library)

	# SpriteFrames allow characters ":" and "[" in animation names, but not
	# Animation Player library, so sanitize the name
	var sanitized_anim_name = anim.replace(":", "_")
	sanitized_anim_name = sanitized_anim_name.replace("[", "_")

	if global_animation_library.has_animation(sanitized_anim_name):
		if not replace:
			return false
		else:
			global_animation_library.remove_animation(sanitized_anim_name)

	var animation := Animation.new()

	var spf = 1/fps
	animation.length = spf * count

	# SpriteFrames only supports linear looping (not ping-pong),
	# so set loop mode to either None or Linear
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE

	var frame_track = animation.add_track(Animation.TYPE_VALUE, 0)
	var anim_track = animation.add_track(Animation.TYPE_VALUE, 1)

	animation.track_set_path(anim_track, "%s:animation" % anim_sprite)

	# Use the original animation name from SpriteFrames here,
	# since the track expects a SpriteFrames animation key for the AnimatedSprite2D
	animation.track_insert_key(anim_track, 0, anim)

	animation.track_set_path(frame_track, "%s:frame" % anim_sprite)

	animation.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
	animation.value_track_set_update_mode(anim_track, Animation.UPDATE_DISCRETE)

	for i in range(count):
		animation.track_insert_key(frame_track, i * spf, i)

	global_animation_library.add_animation(sanitized_anim_name, animation)

	return true

func get_tooltip_text():
	return "AnimationSprite node to import frames from."
