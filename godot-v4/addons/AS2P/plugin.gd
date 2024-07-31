@tool
extends EditorPlugin

const Convertor = preload("res://addons/AS2P/InspectorConvertor.gd")

var plugin: Convertor

func _enter_tree():
	plugin = Convertor.new()
	plugin.connect("animation_updated", _refresh)
	add_inspector_plugin(plugin)

func _refresh(anim_player):
	var interface = get_editor_interface()

	# Hacky way to force the editor to deselect and reselect
	#	the animation panel, as the panel won't update until then
	interface.inspect_object(interface.get_edited_scene_root())
	interface.get_selection().clear()
	await get_tree().create_timer(0.05)
	interface.inspect_object(anim_player)

func _exit_tree():
	remove_inspector_plugin(plugin)
