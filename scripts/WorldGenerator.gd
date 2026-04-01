@tool
extends Node3D

@export var generate_floor_now: bool = false:
	set(value):
		# We act as a button: When you click this checkbox in the inspector, it runs!
		_generate_ground()

func _generate_ground():
	print("Generating 10x10 blocks in viewport!")
	
	# Clear existing blocks first so we don't accidentally double-stack them
	for child in get_children():
		if child is CSGBox3D and child.name.begins_with("GrassBlock_"):
			child.free()
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.7, 0.3) # Grass
	
	var idx = 0
	for x in range(-5, 5):
		for z in range(-5, 5):
			var block = CSGBox3D.new()
			block.name = "GrassBlock_%d" % idx
			block.size = Vector3(1, 1, 1)
			block.position = Vector3(x + 0.5, -0.5, z + 0.5)
			block.material = mat
			add_child(block)
			
			if Engine.is_editor_hint():
				# Must assign the owner to the current edited root so Godot saves it into the scene!
				block.owner = get_tree().edited_scene_root
			idx += 1
