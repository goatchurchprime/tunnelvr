extends Spatial

var gripmenupointertargetpoint = Vector3(0,0,0)
var gripmenulaservector = Vector3(0,0,1)
var gripmenupointertargetwall = null
var gripmenupointertargettype = ""
var gripmenuactivetargettubesectorindex = 0
var gripmenuactivetargetnode = null

var previewtubematerials = { }
var tubenamematerials = { }

func _ready():
	var tubematerials = get_node("/root/Spatial/MaterialSystem/tubematerials")
	var MaterialButton = load("res://nodescenes/MaterialButton.tscn")
	for i in range(tubematerials.get_child_count()):
		var tubematerial = tubematerials.get_child(i)
		var materialbutton = MaterialButton.instance()
		var materialname = tubematerial.get_name()
		if materialname == "flatgrey":
			continue
		materialbutton.set_name(materialname)
		var material = tubematerial.get_surface_material(0).duplicate()
		material.flags_unshaded = true
		material.uv1_triplanar = false
		previewtubematerials[materialname] = material
		tubenamematerials[materialname] = tubematerial.get_node("name").get_surface_material(0)
		materialbutton.get_node("MeshInstance").set_surface_material(0, material)
		$MaterialButtons.add_child(materialbutton)
		materialbutton.transform.origin = Vector3(0.25, 0.15 - i*0.11, 0)
	call_deferred("disableallgripmenus")
	
func disableallgripmenus():
	get_node("/root/Spatial/BodyObjects/GripLaserSpot").visible = false
	for s in $WordButtons.get_children():
		s.get_node("MeshInstance").visible = false
		s.get_node("CollisionShape").disabled = true
	gripmenupointertargetwall = null
	gripmenupointertargettype = ""
	for s in $MaterialButtons.get_children():
		s.get_node("MeshInstance").visible = false
		s.get_node("CollisionShape").disabled = true

	var playerMe = get_node("/root/Spatial").playerMe
	if playerMe != null:
		if Tglobal.connectiontoserveractive:
			assert(playerMe.networkID != 0)
			playerMe.rpc("puppetenablegripmenus", null, null)
		if is_instance_valid(playerMe.doppelganger):
			playerMe.doppelganger.puppetenablegripmenus(null, null)


func cleargripmenupointer(pointertarget):
	if pointertarget.get_parent().get_name() == "MaterialButtons":
		pointertarget.get_node("MeshInstance").set_surface_material(0, previewtubematerials[pointertarget.get_name()])
	else:
		pointertarget.get_node("MeshInstance").get_surface_material(0).albedo_color = Color("#E8D619")

func setgripmenupointer(pointertarget):
	if pointertarget.get_parent().get_name() == "MaterialButtons":
		pointertarget.get_node("MeshInstance").set_surface_material(0, tubenamematerials[pointertarget.get_name()])
	else:
		pointertarget.get_node("MeshInstance").get_surface_material(0).albedo_color = Color("#FFCCCC")


func gripmenuon(controllertrans, pointertargetpoint, pointertargetwall, pointertargettype, activetargettube, activetargettubesectorindex, activetargetwall, activetargetnode):
	gripmenupointertargetpoint = pointertargetpoint if pointertargetpoint != null else controllertrans.origin
	gripmenupointertargetwall = pointertargetwall
	gripmenulaservector = -controllertrans.basis.z
	gripmenupointertargettype = pointertargettype
	gripmenuactivetargettubesectorindex = activetargettubesectorindex
	gripmenuactivetargetnode = activetargetnode
	get_node("/root/Spatial/BodyObjects/GripLaserSpot").translation = gripmenupointertargetpoint
	get_node("/root/Spatial/BodyObjects/GripLaserSpot").visible = get_node("/root/Spatial/BodyObjects/LaserOrient/LaserSpot").visible
	
	var paneltrans = global_transform
	paneltrans.origin = controllertrans.origin - 0.8*ARVRServer.world_scale*(controllertrans.basis.z)
	var lookatpos = controllertrans.origin - 1.6*ARVRServer.world_scale*(controllertrans.basis.z)
	paneltrans = paneltrans.looking_at(lookatpos, Vector3(0, 1, 0))
	paneltrans = Transform(paneltrans.basis.scaled(Vector3(ARVRServer.world_scale, ARVRServer.world_scale, ARVRServer.world_scale)), paneltrans.origin)
	global_transform = paneltrans

	var gmlist = [ ]
	if gripmenupointertargettype == "XCdrawing" and gripmenupointertargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE:
		gmlist = ["NewXC"]
		if get_node("/root/Spatial/PlanViewSystem").visible and pointertargetwall.notubeconnections_so_delxcable():
			gmlist.push_back("HideFloor")
			
	elif gripmenupointertargettype == "XCdrawing" and gripmenupointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		var draggable = (gripmenuactivetargetnode != null) and (activetargetwall == pointertargetwall)
		gmlist = ["DragXC" if draggable else "", "DelXC" if pointertargetwall.notubeconnections_so_delxcable() else ""]

	elif gripmenupointertargettype == "Papersheet":
		gmlist = [ ]

	elif gripmenupointertargettype == "IntermediatePointView":
		gmlist = [ ]
		
	elif gripmenupointertargettype == "XCtubesector":
		var tubesectormaterialname = gripmenupointertargetwall.xcsectormaterials[gripmenuactivetargettubesectorindex]
		if activetargetwall == get_node("/root/Spatial/PlanViewSystem"):
			pass
		elif is_instance_valid(activetargetwall) and len(activetargetwall.nodepoints) == 0:
			gmlist = ["DoSlice", "SelectXC", "HideXC", "materials"]
		elif tubesectormaterialname == "hole":
			gmlist = ["HoleXC", "SelectXC", "HideXC", "materials"]
		else:
			gmlist = ["DelTube", "NewXC", "SelectXC", "HideXC", "materials"]

	elif gripmenupointertargettype == "XCflatshell":
		if activetargetwall == get_node("/root/Spatial/PlanViewSystem"):
			pass
		else:
			gmlist = ["SelectXC", "NewXC", "HideXC", "materials"]

	elif gripmenupointertargettype == "XCnode":
		gmlist = ["NewXC", "HideXC", "DelXC" if pointertargetwall.notubeconnections_so_delxcable() else ""]

	else:
		gmlist = ["NewXC", "Undo"]
				
	for g in gmlist:
		if g == "materials":
			for s in $MaterialButtons.get_children():
				s.get_node("MeshInstance").visible = true
				s.get_node("CollisionShape").disabled = false
		elif g != "":
			$WordButtons.get_node(g).get_node("MeshInstance").visible = true
			$WordButtons.get_node(g).get_node("CollisionShape").disabled = false
	var playerMe = get_node("/root/Spatial").playerMe
	if Tglobal.connectiontoserveractive:
		assert(playerMe.networkID != 0)
		playerMe.rpc("puppetenablegripmenus", gmlist, transform)
	if is_instance_valid(playerMe.doppelganger):
		playerMe.doppelganger.puppetenablegripmenus(gmlist, transform)

# Calibri Fontsize 20: height 664 width 159
var grip_commands_text = """
Z+5
Z-5
to Paper
to Solid
to Gas
to Floor
to Big
new Slice
do Slice
deleteXC
SelectXC
floorTex
ghost
Cut
NewXC
Record
Replay
HoleXC
f19
f20"""

