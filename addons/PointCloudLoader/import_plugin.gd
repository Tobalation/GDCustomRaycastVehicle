tool
extends EditorImportPlugin

enum Presets {PRESET_DEFAULT}

func get_importer_name():
	    return "pointcloud importer"

func get_visible_name():
	return "Point Cloud"

func get_recognized_extensions():
	    return ["ply"]

func get_save_extension():
	    return "mesh"

func get_resource_type():
	    return "ArrayMesh"

func get_preset_count():
	    return Presets.size()

func get_preset_name(preset):
	match preset:
		Presets.PRESET_DEFAULT:
			return "Default"
		_:
			return "Unknown"

func get_import_options(preset):
	match preset:
		Presets.PRESET_DEFAULT:
			return [{
					"name": "point_scale",
					"default_value": 12,
					"hint_string": "Scale for shader point size."
					},
					{
					"name": "scale_factor",
					"default_value": 10,
					"hint_string": "Amount the coordinates in the file will be divided by."
					}]
		_:
			return []

func get_option_visibility(option, options):
    return true

func import(source_file, save_path, options, platform_variants, gen_files):
	var plyFile = File.new()
	var err = plyFile.open(source_file, File.READ)
	if err != OK:
		return err
	var line = ""
	var data = ""
	
	var meshBuilder = SurfaceTool.new()
	meshBuilder.begin(Mesh.PRIMITIVE_POINTS)
	
	while line != "end_header":
		line = plyFile.get_line()
		continue
	while not plyFile.eof_reached():
		line = plyFile.get_line()
		if line == "":
			break
		data = line.split(" ")
		if data.size() != 6:
			return ERR_PARSE_ERROR
		meshBuilder.add_color(Color8(int(data[3]),int(data[4]),int(data[5])))
		meshBuilder.add_vertex(Vector3(float(data[0])/options.scale_factor,
										float(data[2])/options.scale_factor,
										float(data[1])/options.scale_factor))
	var arrayMesh = meshBuilder.commit()
	var shaderProg = preload("./pointCloud.shader")
	var mat = ShaderMaterial.new()
	mat.shader = shaderProg
	mat.set_shader_param("point_scale",options.point_scale)
	arrayMesh.surface_set_material(0,mat)
	plyFile.close()
	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], arrayMesh)