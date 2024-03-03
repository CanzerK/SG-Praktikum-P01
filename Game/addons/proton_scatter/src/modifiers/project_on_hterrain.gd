# This script is an addon for HungryProton's Scatter https://github.com/HungryProton/scatter
# It allows Scatter to detect the terrain height from Terrain3D
# Copy this file into /addons/proton_scatter/src/modifiers
# Then uncomment everything below
# In the editor, add this modifier, then set your Terrain3D node

@tool
extends "base_modifier.gd"


signal projection_completed


@export var terrain_node : NodePath

const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
var _terrain: HTerrain


func _init() -> void:
	display_name = "Project On HTerrain"
	category = "Edit"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_global_space_by_default()

	documentation.add_paragraph(
		"This is a duplicate of `Project on Colliders` that queries the terrain system
		for height and sets the transform height appropriately.

		This modifier must have terrain_node set to a Terrain3D node.")

	var p := documentation.add_parameter("Terrain Node")
	p.set_type("NodePath")
	p.set_description("Set your HTerrain node.")


func _process_transforms(transforms, domain, _seed) -> void:
	if transforms.is_empty():
		return

	if terrain_node:
		_terrain = domain.get_root().get_node_or_null(terrain_node)

	if not _terrain:
		warning += """No HTerrain node found"""
		return

	if not _terrain.get_data():
		warning += """HTerrain data is not initialized"""
		return

	# Get global transform
	var gt: Transform3D = domain.get_global_transform()
	var gt_inverse: Transform3D = gt.affine_inverse()
	for i in transforms.list.size():
		var location: Vector3 = (gt * transforms.list[i]).origin
		var height: float = _terrain.get_data().get_height_at(location.x, location.z)

		transforms.list[i].origin.y = height - gt.origin.y

	if transforms.is_empty():
		warning += """Every point has been removed. Possible reasons include: \n
		+ No collider is close enough to the shapes.
		+ Ray length is too short.
		+ Ray direction is incorrect.
		+ Collision mask is not set properly.
		+ Max slope is too low.
		"""
