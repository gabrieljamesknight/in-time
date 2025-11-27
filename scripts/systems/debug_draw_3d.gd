class_name DebugDraw3D
extends Node

# Simple static helper to draw debug lines in 3D
static func draw_line(start: Vector3, end: Vector3, color: Color, duration: float = 0.5) -> void:
	var mesh_instance = MeshInstance3D.new()
	var final_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	final_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	final_mesh.surface_add_vertex(start)
	final_mesh.surface_add_vertex(end)
	final_mesh.surface_end()
	
	mesh_instance.mesh = final_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add to the scene root
	var root = ((Engine.get_main_loop() as SceneTree).current_scene)
	root.add_child(mesh_instance)
	
	# Timer to delete the line
	var timer = root.get_tree().create_timer(duration)
	timer.timeout.connect(mesh_instance.queue_free)
