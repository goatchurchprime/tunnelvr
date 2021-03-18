extends Node

var pymeshpid = -1
func finemeshpolygon(polypoints, leng, xcdrawing):
	if pymeshpid != -1:
		print("already busy")
		return null
	
	var pi = Geometry.triangulate_polygon(polypoints)
	var vertices = [ ]
	for p in polypoints:
		vertices.push_back([p.x, p.y])
	var faces = [ ]
	for i in range(0, len(pi), 3):
		faces.push_back([pi[i], pi[i+1], pi[i+2]])
	
	var dir = Directory.new()
	if not dir.dir_exists("user://executingfeatures"):
		dir.make_dir("user://executingfeatures")
	var fpolyname = "user://executingfeatures/polygon.txt"
	var fmeshname = "user://executingfeatures/mesh.txt"
	var fout = File.new()
	if fout.file_exists(fmeshname):
		dir.remove(fmeshname)
	
	fout.open(fpolyname, File.WRITE)
	fout.store_line(to_json([vertices, faces]))
	fout.close()
	var dc = "run -it --rm -v %s:/data -v %s:/code pymesh/pymesh /code/polytriangulator.py /data/polygon.txt %f /data/mesh.txt" % \
		[ ProjectSettings.globalize_path("user://executingfeatures"), ProjectSettings.globalize_path("res://executingfeatures"), leng ]
	print(dc)
	pymeshpid = OS.execute("docker", PoolStringArray(dc.split(" ")), false)
	print(pymeshpid)
	if pymeshpid == -1:
		print("fail")
		return null
	
	for i in range(20):
		yield(get_tree().create_timer(1.0), "timeout")
		if fout.file_exists(fmeshname):
			break
		print("waiting on fine triangulation ", i)
	if not fout.file_exists(fmeshname):
		print("no file after 20 seconds, kill")
		OS.kill(pymeshpid)
		pymeshpid = -1
		return null
	
	fout.open(fmeshname, File.READ)
	var x = parse_json(fout.get_line())
	fout.close()
	print("triangulation received with %d points and %d faces" % [len(x[0]), len(x[1])])

	#PoolVector3Array()
	
	var arraymesh = ArrayMesh.new()
	var surfaceTool = SurfaceTool.new()
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v = x[0]
	for i in len(x[1]):
		var t = x[1][i]
		for j in range(3):
			var p = Vector2(v[t[j]][0], v[t[j]][1])
			surfaceTool.add_uv(p)
			surfaceTool.add_uv2(p)
			surfaceTool.add_vertex(Vector3(p.x, p.y, (int(i)%50)*0.005+0.005))
	surfaceTool.generate_normals()
	surfaceTool.commit(arraymesh)
	xcdrawing.updatexcshellmesh(arraymesh)
	
	return null

