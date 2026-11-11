class_name CustomerRecolor
extends RefCounted

## The palette-swap material for a customer's sprite: each body part's base colour maps to
## the archetype's own colour or, when flagged, a random one (CustomerPalette).

const SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")


static func build_material(data: CustomerData) -> ShaderMaterial:
	var recolor_material : ShaderMaterial = ShaderMaterial.new()
	recolor_material.shader = SHADER
	recolor_material.set_shader_parameter("hue_tolerance", CustomerPalette.HUE_TOLERANCE)
	recolor_material.set_shader_parameter("saturation_tolerance", CustomerPalette.SATURATION_TOLERANCE)
	recolor_material.set_shader_parameter("frame_height", float(CustomerPalette.FRAME_HEIGHT))
	recolor_material.set_shader_parameter("feet_rows", float(CustomerPalette.FEET_ROWS))
	var palette : Dictionary = CustomerPalette.random(data)
	for region : String in palette:
		# A region left as painted still gets its base colour: the shader uses it to claim
		# the region's pixels so a later, randomized region can't take them.
		recolor_material.set_shader_parameter(region + "_base_color", palette[region]["base"])
		recolor_material.set_shader_parameter(region + "_recolor", palette[region]["recolor"])
		recolor_material.set_shader_parameter(region + "_target_color", palette[region]["target"])
	return recolor_material
