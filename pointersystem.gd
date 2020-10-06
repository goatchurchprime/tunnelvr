extends Node

onready var sketchsystem = get_node("/root/Spatial/SketchSystem")
onready var planviewsystem = get_node("/root/Spatial/PlanViewSystem")
onready var materialsystem = get_node("/root/Spatial/MaterialSystem")
onready var gripmenu = get_node("/root/Spatial/GuiSystem/GripMenu")

onready var playerMe = get_parent()
onready var headcam = playerMe.get_node('HeadCam')
onready var handright = playerMe.get_node("HandRight")
onready var handrightcontroller = playerMe.get_node("HandRightController")
onready var guipanel3d = get_node("/root/Spatial/GuiSystem/GUIPanel3D")

onready var LaserOrient = get_node("/root/Spatial/BodyObjects/LaserOrient") 
onready var LaserSelectLine = get_node("/root/Spatial/BodyObjects/LaserSelectLine") 

var viewport_point = null




onready var activelaserroot = LaserOrient
var pointerplanviewtarget = null
var pointertarget = null
var pointertargettype = "none"
var pointertargetwall = null
var pointertargetpoint = Vector3(0, 0, 0)
var gripbuttonpressused = false

var activetargetnode = null
var activetargetnodewall = null
var activetargetwall = null
var activetargettube = null
var activetargettubesectorindex = -1

var activetargetwallgrabbed = null
var activetargetwallgrabbedtransform = null
var activetargetwallgrabbedorgtransform = null
var activetargetwallgrabbeddispvector = null
var activetargetwallgrabbedpoint = null
var activetargetwallgrabbedpointoffset = null
var activetargetwallgrabbedlocalpoint = null
var activetargetwallgrabbedlaserroottrans = null


func clearpointertargetmaterial():
	if pointertargettype == "XCnode":  
		pointertarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("selected" if pointertarget == activetargetnode else ("nodepthtest" if pointertargetwall == activetargetwall else "normal")))
	if (pointertargettype == "XCdrawing" or pointertargettype == "XCnode") and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		if pointertargetwall == activetargetwall:
			pointertargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, materialsystem.xcdrawingmaterial("active"))
			pointertargetwall.updateformetresquaresscaletexture()
		else:
			pointertargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, materialsystem.xcdrawingmaterial("normal"))
	if pointertargettype == "GripMenuItem":
		gripmenu.cleargripmenupointer(pointertarget)

			
func setpointertargetmaterial():
	if pointertargettype == "XCnode":
		pointertarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("selected_highlight" if pointertarget == activetargetnode else "highlight"))
	if (pointertargettype == "XCdrawing" or pointertargettype == "XCnode") and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		pointertargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, materialsystem.xcdrawingmaterial("highlight"))
		pointertargetwall.updateformetresquaresscaletexture()
	if pointertargettype == "GripMenuItem":
		gripmenu.setgripmenupointer(pointertarget)

func clearactivetargetnode():
	if activetargetnode != null:
		activetargetnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("nodepthtest" if activetargetnodewall == activetargetwall else "normal"))
	activetargetnode = null
	activetargetnodewall = null
	activelaserroot.get_node("LaserSpot").set_surface_material(0, materialsystem.lasermaterial("spot"))
	
func setactivetargetnode(newactivetargetnode):
	clearactivetargetnode()
	activetargetnode = newactivetargetnode
	assert (targettype(activetargetnode) == "XCnode")
	activetargetnodewall = targetwall(activetargetnode, "XCnode")
	if activetargetnode != pointertarget:
		activetargetnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("selected"))
	activelaserroot.get_node("LaserSpot").set_surface_material(0, materialsystem.lasermaterial("spotselected"))
	setpointertargetmaterial()

func setactivetargetwall(newactivetargetwall):
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, materialsystem.xcdrawingmaterial("normal"))
		activetargetwall.get_node("PathLines").set_surface_material(0, materialsystem.pathlinematerial("normal"))
		for xcnode in activetargetwall.get_node("XCnodes").get_children():
			xcnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("selected" if xcnode == activetargetnode else "normal"))
		#for xctube in activetargetwall.xctubesconn:
		#	if not xctube.positioningtube:
		#		xctube.updatetubeshell(sketchsystem.get_node("XCdrawings"), Tglobal.tubeshellsvisible)
		#activetargetwall.updatexctubeshell(sketchsystem.get_node("XCdrawings"), Tglobal.tubeshellsvisible)
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").get_surface_material(0).albedo_color = Color("#FEF4D5")
	
	activetargetwall = newactivetargetwall
	activetargetwallgrabbedtransform = null
	
	LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor | CollisionLayer.CL_CaveWall | CollisionLayer.CL_CaveWallTrans
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		if not activetargetwall.get_node("XCdrawingplane").visible:
			sketchsystem.actsketchchange([{"xcvizstates":{activetargetwall.get_name():3}}])
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, materialsystem.xcdrawingmaterial("active"))
		activetargetwall.get_node("PathLines").set_surface_material(0, materialsystem.pathlinematerial("nodepthtest"))
		for xcnode in activetargetwall.get_node("XCnodes").get_children():
			if xcnode != activetargetnode:
				xcnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, materialsystem.nodematerial("nodepthtest"))
		if len(activetargetwall.nodepoints) != 0:
			LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor 

	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").get_surface_material(0).albedo_color = Color("#DDFFCC")

func _ready():
	handrightcontroller.connect("button_pressed", self, "_on_button_pressed")
	handrightcontroller.connect("button_release", self, "_on_button_release")

func targettype(target):
	if not is_instance_valid(target):
		return "none"
	var targetname = target.get_name()
	if targetname == "GUIPanel3D":
		return "GUIPanel3D"
	if targetname == "PlanView":
		return "PlanView"
	if targetname == "XCflatshell":
		return "XCflatshell"
	var targetparent = target.get_parent()
	if targetname == "XCdrawingplane":
		assert (targetparent.drawingtype != DRAWING_TYPE.DT_CENTRELINE)
		if targetparent.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
			return "Papersheet"
		return "XCdrawing"
	if targetparent.get_name() == "XCtubesectors":
		return "XCtubesector"
	if targetparent.get_name() == "XCnodes":
		return "XCnode"
	if targetparent.get_parent().get_name() == "GripMenu":
		return "GripMenuItem"
	return "unknown"
		
func targetwall(target, targettype):
	if targettype == "XCdrawing" or targettype == "Papersheet":
		return target.get_parent()
	if targettype == "XCnode":
		return target.get_parent().get_parent()
	if targettype == "XCtubesector":
		return target.get_parent().get_parent()
	if targettype == "PlanView":
		return target.get_parent()
	return null
	
func setopnpos(opn, p):
	opn.global_transform.origin = p

		
func clearpointertarget():
	if pointertarget == guipanel3d:
		guipanel3d.guipanelreleasemouse()
	clearpointertargetmaterial()
	pointertarget = null
	pointertargettype = "none"
	pointertargetwall = null

func setpointertarget(laserroot):
	var newpointertarget = laserroot.get_node("RayCast").get_collider()
	if newpointertarget != null:
		if newpointertarget.is_queued_for_deletion():
			newpointertarget = null
		elif newpointertarget.get_parent().is_queued_for_deletion():
			newpointertarget = null
		elif newpointertarget.get_parent().get_parent().is_queued_for_deletion():
			newpointertarget = null
	var newpointertargetpoint = laserroot.get_node("RayCast").get_collision_point() if newpointertarget != null else null
	if newpointertarget != pointertarget:
		if pointertarget == guipanel3d:
			guipanel3d.guipanelreleasemouse()
		
		clearpointertargetmaterial()
		pointertarget = newpointertarget
		pointertargettype = targettype(pointertarget)
		pointertargetwall = targetwall(pointertarget, pointertargettype)
		setpointertargetmaterial()
		
		#print("ppp  ", activetargetnode, " ", pointertargettype)
		laserroot.get_node("LaserSpot").visible = ((pointertargettype == "XCdrawing") or (pointertargettype == "XCtubesector"))
		LaserSelectLine.visible = (activetargetnode != null) and not handright.gripbuttonheld and ((pointertargettype == "XCdrawing") or (activetargetnode != null))
			
	pointertargetpoint = newpointertargetpoint
	if is_instance_valid(pointertarget) and pointertarget == guipanel3d:
		guipanel3d.guipanelsendmousemotion(pointertargetpoint, LaserOrient.global_transform, (handrightcontroller.is_button_pressed(BUTTONS.HT_PINCH_INDEX_FINGER) if Tglobal.questhandtracking else handrightcontroller.is_button_pressed(BUTTONS.VR_TRIGGER)) or Input.is_mouse_button_pressed(BUTTON_LEFT))

	if pointertargetpoint != null:
		laserroot.get_node("LaserSpot").global_transform.origin = pointertargetpoint
		laserroot.get_node("Length").scale.z = -laserroot.get_node("LaserSpot").translation.z
	else:
		laserroot.get_node("Length").scale.z = -laserroot.get_node("RayCast").cast_to.z
		
	if LaserSelectLine.visible:
		if pointertarget != null and activetargetnode != null:
			LaserSelectLine.global_transform.origin = pointertargetpoint
			LaserSelectLine.get_node("Scale").scale.z = LaserSelectLine.global_transform.origin.distance_to(activetargetnode.global_transform.origin)
			LaserSelectLine.global_transform = laserroot.get_node("LaserSpot").global_transform.looking_at(activetargetnode.global_transform.origin, Vector3(0,1,0))
		else:
			LaserSelectLine.visible = false

func _on_button_pressed(p_button):
	var gripbuttonheld = handright.gripbuttonheld
	print("pppp ", pointertargetpoint, " ", [activetargetnode, pointertargettype, " pbutton", p_button])
	if Tglobal.questhandtracking:
		gripbuttonheld = handrightcontroller.is_button_pressed(BUTTONS.HT_PINCH_MIDDLE_FINGER)
		if p_button == BUTTONS.HT_PINCH_RING_FINGER:
			if handrightcontroller.is_button_pressed(BUTTONS.HT_PINCH_PINKY):
				buttonpressed_vrby(false)
		elif p_button == BUTTONS.HT_PINCH_PINKY:
			if handrightcontroller.is_button_pressed(BUTTONS.HT_PINCH_RING_FINGER):
				buttonpressed_vrby(false)
		elif Tglobal.controlslocked:
			print("Controls locked")	
		elif p_button == BUTTONS.HT_PINCH_INDEX_FINGER:
			buttonpressed_vrtrigger(gripbuttonheld)
		elif p_button == BUTTONS.HT_PINCH_MIDDLE_FINGER:
			buttonpressed_vrgrip()
		#elif p_button == BUTTONS.HT_PINCH_RING_FINGER:
		#	guipanel3d.clickbuttonheadtorch()
		#elif p_button == BUTTONS.HT_PINCH_PINKY:
		#	buttonpressed_vrby(gripbuttonheld)
	else:
		if p_button == BUTTONS.VR_BUTTON_BY:
			buttonpressed_vrby(gripbuttonheld)
		elif Tglobal.controlslocked:
			print("Controls locked")	
		elif p_button == BUTTONS.VR_GRIP:
			buttonpressed_vrgrip()
		elif p_button == BUTTONS.VR_TRIGGER:
			buttonpressed_vrtrigger(gripbuttonheld)
		elif p_button == BUTTONS.VR_PAD:
			buttonpressed_vrpad(gripbuttonheld, handright.joypos)
	
func buttonpressed_vrby(gripbuttonheld):
	if Tglobal.controlslocked:
		if not guipanel3d.visible:
			guipanel3d.toggleguipanelvisibility(LaserOrient.global_transform)
		else:
			print("controls locked")
	elif pointerplanviewtarget != null:
		pointerplanviewtarget.toggleplanviewactive()
	else:
		guipanel3d.toggleguipanelvisibility(LaserOrient.global_transform)

func buttonpressed_vrgrip():
	gripbuttonpressused = false
	if pointertargettype == "XCtubesector":
		activetargettube = pointertargetwall
		activetargettubesectorindex = pointertarget.get_index()
		if activetargettubesectorindex < len(activetargettube.xcsectormaterials):
			var tubesectormaterialname = activetargettube.xcsectormaterials[activetargettubesectorindex]
			materialsystem.updatetubesectormaterial(activetargettube.get_node("XCtubesectors").get_child(activetargettubesectorindex), tubesectormaterialname, true)
			if activetargettube.get_node("PathLines").mesh == null:
				activetargettube.updatetubelinkpaths(sketchsystem)
			activetargettube.get_node("PathLines").visible = true
			activetargettube.get_node("PathLines").set_surface_material(0, materialsystem.pathlinematerial("nodepthtest"))
		else:
			print("Wrong: sector index not match sectors in tubedata")
	gripmenu.gripmenuon(LaserOrient.global_transform, pointertargetpoint, pointertargetwall, pointertargettype, activetargettube, activetargettubesectorindex, activetargetwall, activetargetnode)
	
var initialsequencenodename = null
var initialsequencenodenameP = null
func buttonpressed_vrtrigger(gripbuttonheld):
	initialsequencenodenameP = initialsequencenodename
	initialsequencenodename = null
	if not is_instance_valid(pointertarget):
		pass
		
	elif pointertarget == guipanel3d:
		pass  # done in _process()

	elif pointertarget.has_method("jump_up"):
		pointertarget.jump_up()

	# grip click moves node on xcwall
	elif gripbuttonheld and activetargetnode != null and pointertargettype == "XCdrawing" and pointertargetwall == activetargetnodewall:
		var movetopoint = activetargetnodewall.global_transform.xform_inv(pointertargetpoint)
		movetopoint.z = 0.0
		sketchsystem.actsketchchange([{
					"name":activetargetnodewall.get_name(), 
					"prevnodepoints":{ activetargetnode.get_name():activetargetnode.translation }, 
					"nextnodepoints":{ activetargetnode.get_name():movetopoint } 
				}])
		if activetargetnodewall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			activetargetnodewall.expandxcdrawingscale(pointertargetpoint)
		clearactivetargetnode()
		
	# reselection when selected on grip deletes the node		
	elif gripbuttonheld and activetargetnode != null and pointertarget == activetargetnode and (activetargetnodewall.drawingtype != DRAWING_TYPE.DT_CENTRELINE):
		if len(activetargetnodewall.nodepoints) == 1:
			LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor | CollisionLayer.CL_CaveWall | CollisionLayer.CL_CaveWallTrans
		var xcname = activetargetnodewall.get_name()
		var nodename = activetargetnode.get_name()
		var xcdata = { "name":xcname, 
					   "prevnodepoints":{ nodename:activetargetnode.translation }, 
					   "nextnodepoints":{ } 
					 }
		var prevonepathpairs = [ ]
		for j in range(0, len(activetargetnodewall.onepathpairs), 2):
			if (activetargetnodewall.onepathpairs[j] == nodename) or (activetargetnodewall.onepathpairs[j+1] == nodename):
				prevonepathpairs.push_back(activetargetnodewall.onepathpairs[j])
				prevonepathpairs.push_back(activetargetnodewall.onepathpairs[j+1])
		if len(prevonepathpairs) != 0:
			xcdata["prevonepathpairs"] = prevonepathpairs
			xcdata["nextonepathpairs"] = [ ]
		var xcdatalist = [ xcdata ]
		
		for xctube in activetargetnodewall.xctubesconn:
			var prevdrawinglinks = [ ]
			var m = 0 if xcname == xctube.xcname0 else 1
			for j in range(0, len(xctube.xcdrawinglink), 2):
				if xctube.xcdrawinglink[j+m] == nodename:
					prevdrawinglinks.push_back(xctube.xcdrawinglink[j])
					prevdrawinglinks.push_back(xctube.xcdrawinglink[j+1])
					prevdrawinglinks.push_back(xctube.xcsectormaterials[j/2])
			if len(prevdrawinglinks) != 0:
				var xctdata = { "tubename":xctube.get_name(), 
								"xcname0":xctube.xcname0, 
								"xcname1":xctube.xcname1,
								"prevdrawinglinks":prevdrawinglinks,
								"newdrawinglinks":[ ] 
							  }
				xcdatalist.push_back(xctdata)

		clearactivetargetnode()
		clearpointertarget()
		activelaserroot.get_node("LaserSpot").visible = false
		sketchsystem.actsketchchange(xcdatalist)
		Tglobal.soundsystem.quicksound("BlipSound", pointertargetpoint)

	
	elif pointertargettype == "Papersheet" or pointertargettype == "PlanView":
		clearactivetargetnode()
		var alaserspot = activelaserroot.get_node("LaserSpot")
		alaserspot.global_transform.origin = pointertargetpoint
		setactivetargetwall(pointertargetwall)
		activetargetwallgrabbed = activetargetwall if pointertargettype == "Papersheet" else activetargetwall.get_node("PlanView")
		if gripbuttonheld:
			activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * activetargetwallgrabbed.global_transform
			activetargetwallgrabbedpoint = alaserspot.global_transform.origin
			activetargetwallgrabbedlocalpoint = activetargetwallgrabbed.global_transform.affine_inverse() * alaserspot.global_transform.origin
			activetargetwallgrabbedpointoffset = alaserspot.global_transform.origin - activetargetwallgrabbed.global_transform.origin
		else:
			activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * activetargetwallgrabbed.global_transform
			activetargetwallgrabbedpoint = null

			
	elif pointertargettype == "XCdrawing":
		if pointertargetwall != activetargetwall:
			setactivetargetwall(pointertargetwall)
			
		if gripbuttonheld and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			pointertargetwall.expandxcdrawingscale(pointertargetpoint)
			if len(pointertargetwall.nodepoints) == 0:
				clearactivetargetnode()
				var alaserspot = activelaserroot.get_node("LaserSpot")
				alaserspot.global_transform.origin = pointertargetpoint
				activetargetwallgrabbed = activetargetwall
				activetargetwallgrabbedlaserroottrans = activelaserroot.global_transform
				activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * activetargetwallgrabbed.global_transform
				activetargetwallgrabbedorgtransform = activetargetwallgrabbed.global_transform
				activetargetwallgrabbeddispvector = alaserspot.global_transform.origin - activelaserroot.global_transform.origin
				activetargetwallgrabbedpoint = alaserspot.global_transform.origin
				activetargetwallgrabbedlocalpoint = activetargetwallgrabbed.global_transform.affine_inverse() * alaserspot.global_transform.origin
				activetargetwallgrabbedpointoffset = alaserspot.global_transform.origin - activetargetwallgrabbed.global_transform.origin

		elif (activetargetnode != null and activetargetnodewall == pointertargetwall) or pointertargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE or len(pointertargetwall.nodepoints) == 0:
			if len(pointertargetwall.nodepoints) == 0:
				LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor 
				
			#var newpointertarget = pointertargetwall.newxcnode()
			#pointertargetwall.setxcnpoint(newpointertarget, pointertargetpoint, true)
			var newnodename = pointertargetwall.newuniquexcnodename()
			var newnodepoint = pointertargetwall.global_transform.xform_inv(pointertargetpoint)
			newnodepoint.z = 0.0
			var xcdata = { "name":pointertargetwall.get_name(), 
						   "prevnodepoints":{ }, 
						   "nextnodepoints":{ newnodename:newnodepoint } 
						 }
			if activetargetnode != null and activetargetnodewall == pointertargetwall:
				xcdata["prevonepathpairs"] = [ ]
				xcdata["newonepathpairs"] = [ activetargetnode.get_name(), newnodename]
			sketchsystem.actsketchchange([xcdata])
			setactivetargetnode(pointertargetwall.get_node("XCnodes").get_node(newnodename))
			if pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
				pointertargetwall.expandxcdrawingscale(pointertargetpoint)
			Tglobal.soundsystem.quicksound("ClickSound", pointertargetpoint)
			initialsequencenodename = initialsequencenodenameP
	
		elif pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			pointertargetwall.expandxcdrawingscale(pointertargetpoint)

									
	# reselection clears selection
	elif activetargetnode != null and pointertarget == activetargetnode:
		clearactivetargetnode()

	# connecting lines between xctype nodes
	elif activetargetnode != null and pointertargettype == "XCnode":
		if not ((activetargetnodewall.drawingtype == DRAWING_TYPE.DT_CENTRELINE and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING) or (activetargetnodewall.drawingtype == DRAWING_TYPE.DT_XCDRAWING and pointertargetwall.drawingtype == DRAWING_TYPE.DT_CENTRELINE)):
			if activetargetnodewall == pointertargetwall:
				var xcdata = { "name":pointertargetwall.get_name() }
				var i0 = activetargetnode.get_name()
				var i1 = pointertarget.get_name()
				if pointertargetwall.pairpresentindex(i0, i1) != -1:
					xcdata["prevonepathpairs"] = [i0, i1]
					xcdata["newonepathpairs"] = [ ]
				else:
					xcdata["newonepathpairs"] = [i0, i1]
					if initialsequencenodenameP != null and initialsequencenodenameP != activetargetnode.get_name() and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
						xcdata["prevonepathpairs"] = [ initialsequencenodenameP, pointertarget.get_name() ]
					else:
						xcdata["prevonepathpairs"] = [ ]
				sketchsystem.actsketchchange([xcdata])

			else:
				var xcname0 = activetargetnodewall.get_name()
				var nodename0 = activetargetnode.get_name()
				var xcname1 = pointertargetwall.get_name()
				var nodename1 = pointertarget.get_name()
				var xctube = sketchsystem.findxctube(xcname0, xcname1)
				var xctdata = { "xcname0": xcname0, "xcname1":xcname1 }
				if xctube == null:
					xctdata["tubename"] = "**notset"
					xctdata["prevdrawinglinks"] = [ ]
					xctdata["newdrawinglinks"] = [ nodename0, nodename1, "simpledirt" ]
				else:
					xctdata["tubename"] = xctube.get_name()
					var j = xctube.linkspresentindex(nodename0, nodename1) if xctube.xcname0 == xcname0 else xctube.linkspresentindex(nodename1, nodename0)
					if j == -1:
						xctdata["prevdrawinglinks"] = [ ]
						xctdata["newdrawinglinks"] = [ nodename0, nodename1, "simpledirt" ]
					else:
						xctdata["prevdrawinglinks"] = [ nodename0, nodename1, xctube.xcsectormaterials[j] ]
						xctdata["newdrawinglinks"] = [ ]
				var xcvdata = { "xcvizstates":{ pointertargetwall.get_name():3 } }
				sketchsystem.actsketchchange([xctdata, xcvdata])
			Tglobal.soundsystem.quicksound("ClickSound", pointertargetpoint)
			clearactivetargetnode()
											
	elif activetargetnode == null and pointertargettype == "XCnode":
		if pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			if pointertargetwall != activetargetwall:
				setactivetargetwall(pointertargetwall)
		setactivetargetnode(pointertarget)
		initialsequencenodename = pointertarget.get_name()
		
	if gripbuttonheld:
		gripbuttonpressused = true
		gripmenu.disableallgripmenus()

				
func buttonpressed_vrpad(gripbuttonheld, joypos):
	if pointertargettype == "XCdrawing" and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		if abs(joypos.y) < 0.5 and abs(joypos.x) > 0.1:
			var dy = (1 if joypos.x > 0 else -1)*(1.0 if abs(joypos.x) < 0.8 else 0.1)
			pointertargetwall.get_node("XCdrawingplane").scale.x = max(1, pointertargetwall.get_node("XCdrawingplane").scale.x + dy)
			pointertargetwall.get_node("XCdrawingplane").scale.y = max(1, pointertargetwall.get_node("XCdrawingplane").scale.y + dy)
			pointertargetwall.updateformetresquaresscaletexture()
				
	elif pointertargettype == "Papersheet":
		if abs(joypos.y) > 0.5:
			var dd = (1 if joypos.x > 0 else -1)*(0.2 if activelaserroot.get_node("Length").scale.z < 1.5 else 1.0)
			if activelaserroot.get_node("Length").scale.z + dd > 0.1:
				pointertargetwall.global_transform.origin += -dd*LaserOrient.global_transform.basis.z
		elif abs(joypos.x) > 0.1:
			var fs = (0.5 if abs(joypos.x) < 0.8 else 0.9)
			if joypos.x > 0:
				fs = 1/fs
			pointertargetwall.get_node("XCdrawingplane").scale.x *= fs
			pointertargetwall.get_node("XCdrawingplane").scale.y *= fs
			
	#elif pointertargettype == "PlanView":
	elif pointerplanviewtarget != null and not pointerplanviewtarget.planviewactive:
		if abs(joypos.x) > 0.65:
			pointerplanviewtarget.camerascalechange(1.5 if joypos.x < 0 else 0.6667)
		elif abs(joypos.x) < 0.2 and abs(joypos.y) < 0.2:
			pointerplanviewtarget.cameraresetcentre(headcam)
		
func _on_button_release(p_button):
	if Tglobal.controlslocked:
		print("Controls locked")
	elif Tglobal.questhandtracking:
		if p_button == BUTTONS.HT_PINCH_MIDDLE_FINGER:
			buttonreleased_vrgrip()
		elif p_button == BUTTONS.HT_PINCH_INDEX_FINGER:
			buttonreleased_vrtrigger()
	else:
		if p_button == BUTTONS.VR_GRIP:
			buttonreleased_vrgrip()
		elif p_button == BUTTONS.VR_TRIGGER:
			buttonreleased_vrtrigger()

func buttonreleased_vrgrip():
	var wasactivetargettube = activetargettube
	if activetargettube != null:
		if pointertargettype == "GripMenuItem" and pointertarget.get_parent().get_name() == "MaterialButtons":
			assert (gripmenu.gripmenupointertargettype == "XCtubesector") 
			var sectormaterialname = pointertarget.get_name()
			if activetargettubesectorindex < len(activetargettube.xcsectormaterials):
				sketchsystem.actsketchchange([{ "tubename":activetargettube.get_name(), 
												"xcname0":activetargettube.xcname0, 
												"xcname1":activetargettube.xcname1,
												"prevdrawinglinks":[activetargettube.xcdrawinglink[activetargettubesectorindex*2], activetargettube.xcdrawinglink[activetargettubesectorindex*2+1], activetargettube.xcsectormaterials[activetargettubesectorindex]],
												"newdrawinglinks":[activetargettube.xcdrawinglink[activetargettubesectorindex*2], activetargettube.xcdrawinglink[activetargettubesectorindex*2+1], sectormaterialname]
											 }])
				gripmenu.disableallgripmenus()
				return
			else:
				materialsystem.updatetubesectormaterial(activetargettube.get_node("XCtubesectors").get_child(activetargettubesectorindex), activetargettube.xcsectormaterials[activetargettubesectorindex], false)
			return

		if activetargettubesectorindex < len(activetargettube.xcsectormaterials):
			materialsystem.updatetubesectormaterial(activetargettube.get_node("XCtubesectors").get_child(activetargettubesectorindex), activetargettube.xcsectormaterials[activetargettubesectorindex], false)
		else:
			print("Wrong: activetargettubesectorindex >= activetargettube.xcsectormaterials ")
		activetargettube.get_node("PathLines").set_surface_material(0, materialsystem.pathlinematerial("normal"))
		activetargettube = null
	
	if gripbuttonpressused:
		pass  # the trigger was pulled during the grip operation
	
	elif pointertargettype == "GripMenuItem":
		if pointertarget.get_name() == "NewXC":
			var pt0 = gripmenu.gripmenupointertargetpoint
			var eyept0vec = pt0 - headcam.global_transform.origin
			if gripmenu.gripmenupointertargettype == "XCtubesector":
				var xcdrawing0 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname0)
				var xcdrawing1 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname1)
				var tubevec = xcdrawing1.global_transform.origin - xcdrawing0.global_transform.origin
				eyept0vec = tubevec if eyept0vec.dot(tubevec) > 0 else -tubevec
			elif gripmenu.gripmenupointertargettype == "Papersheet":
				pass
			elif gripmenu.gripmenupointertargettype == "XCnode":
				if gripmenu.gripmenupointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
					pt0 += -eyept0vec/2
				eyept0vec = gripmenu.gripmenulaservector
			elif gripmenu.gripmenupointertargettype == "PlanView":
				pt0 = null
			elif gripmenu.gripmenupointertargettype == "XCdrawing" and gripmenu.gripmenupointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
				pt0 += -eyept0vec/2
			elif gripmenu.gripmenupointertargettype == "XCdrawing" and gripmenu.gripmenupointertargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE:
				pass
			elif gripmenu.gripmenupointertargettype == "XCflatshell":
				pt0 += -eyept0vec/2
			else:
				print(gripmenu.gripmenupointertargettype)
				assert (gripmenu.gripmenupointertargettype == "none" or gripmenu.gripmenupointertargettype == "unknown")
				eyept0vec = gripmenu.gripmenulaservector
				pt0 = headcam.global_transform.origin + eyept0vec.normalized()*2.9
			if pt0 != null:
				var drawingwallangle = Vector2(eyept0vec.x, eyept0vec.z).angle() + deg2rad(90)					
				var xcdata = { "name":sketchsystem.uniqueXCname(), 
							   "xcresource":"",
							   "drawingtype":DRAWING_TYPE.DT_XCDRAWING,
							   "transformpos":Transform(Basis().rotated(Vector3(0,-1,0), drawingwallangle), pt0) }
				var xcviz = { "xcvizstates": { xcdata["name"]:3 } }
				sketchsystem.actsketchchange([xcdata, xcviz])
				clearactivetargetnode()
				var xcdrawing = sketchsystem.get_node("XCdrawings").get_node(xcdata["name"])
				setactivetargetwall(xcdrawing)
				if gripmenu.gripmenupointertargettype == "XCtubesector":
					var xcdrawing0 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname0)
					var xcdrawing1 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname1)
					xcdrawing.expandxcdrawingfitxcdrawing(xcdrawing0)
					xcdrawing.expandxcdrawingfitxcdrawing(xcdrawing1)
				sketchsystem.sharexcdrawingovernetwork(xcdrawing)

		elif is_instance_valid(gripmenu.gripmenupointertargetwall):
			print("executing ", pointertarget.get_name(), " on ", gripmenu.gripmenupointertargetwall.get_name())
			if pointertarget.get_name() == "Up5":
				#gripmenu.gripmenupointertargetwall.global_transform.origin.y += 1
				#playerMe.global_transform.origin.y = max(playerMe.global_transform.origin.y, gripmenu.gripmenupointertargetwall.global_transform.origin.y)
				var floortween = gripmenu.get_node("FloorMoveTween")
				floortween.interpolate_property(gripmenu.gripmenupointertargetwall, "translation:y", gripmenu.gripmenupointertargetwall.translation.y, gripmenu.gripmenupointertargetwall.translation.y + 1, 0.5, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
				floortween.start()
			elif pointertarget.get_name() == "Down5":
				#gripmenu.gripmenupointertargetwall.global_transform.origin.y -= 1
				#gripmenu.gripmenupointertargetwall.global_transform.origin.y = max(gripmenu.gripmenupointertargetwall.global_transform.origin.y - 1, get_node("/root/Spatial/underfloor").global_transform.origin.y + 0.5)
				var floortween = gripmenu.get_node("FloorMoveTween")
				floortween.interpolate_property(gripmenu.gripmenupointertargetwall, "translation:y", gripmenu.gripmenupointertargetwall.translation.y, max(gripmenu.gripmenupointertargetwall.global_transform.origin.y - 1, get_node("/root/Spatial/underfloor").global_transform.origin.y + 0.5), 0.5, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
				floortween.start()
			elif pointertarget.get_name() == "toPaper":
				gripmenu.gripmenupointertargetwall.drawingtype = DRAWING_TYPE.DT_PAPERTEXTURE
				gripmenu.gripmenupointertargetwall.get_node("XCdrawingplane").collision_layer = CollisionLayer.CL_Pointer

			elif pointertarget.get_name() == "toFloor" or pointertarget.get_name() == "toBig":
				if pointertarget.get_name() == "toBig":
					var fs = max(1.1, 50/gripmenu.gripmenupointertargetwall.get_node("XCdrawingplane").scale.x)
					gripmenu.gripmenupointertargetwall.get_node("XCdrawingplane").scale.x *= fs
					gripmenu.gripmenupointertargetwall.get_node("XCdrawingplane").scale.y *= fs
				gripmenu.gripmenupointertargetwall.rotation_degrees.x = -90
				gripmenu.gripmenupointertargetwall.rotation_degrees.z = 0
				playerMe.global_transform.origin.y += 1
				gripmenu.gripmenupointertargetwall.global_transform.origin.y = playerMe.global_transform.origin.y
				gripmenu.gripmenupointertargetwall.drawingtype = DRAWING_TYPE.DT_FLOORTEXTURE
				gripmenu.gripmenupointertargetwall.get_node("XCdrawingplane").collision_layer = CollisionLayer.CL_Environment | CollisionLayer.CL_PointerFloor
		
			elif pointertarget.get_name() == "SelectXC":
				sketchsystem.actsketchchange([{"xcvizstates":{gripmenu.gripmenupointertargetwall.xcname0:3, gripmenu.gripmenupointertargetwall.xcname1:3}}])
				var xcdrawing0 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname0)
				var xcdrawing1 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname1)
				if xcdrawing0 != activetargetwall:
					setactivetargetwall(xcdrawing0)
				elif xcdrawing1 != activetargetwall:
					setactivetargetwall(xcdrawing1)
						
			elif pointertarget.get_name() == "HideXC":
				sketchsystem.actsketchchange([{"xcvizstates":{gripmenu.gripmenupointertargetwall.xcname0:0, gripmenu.gripmenupointertargetwall.xcname1:0}}])
				var xcdrawing0 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname0)
				var xcdrawing1 = sketchsystem.get_node("XCdrawings").get_node(gripmenu.gripmenupointertargetwall.xcname1)
				if xcdrawing0 == activetargetwall:
					setactivetargetwall(null)
				if xcdrawing1 == activetargetwall:
					setactivetargetwall(null)

			elif pointertarget.get_name() == "DelXC":
				print("Not implemented")

			elif pointertarget.get_name() == "DragXC" and is_instance_valid(activetargetnode):
				var dragvec = activetargetnodewall.global_transform.xform_inv(gripmenu.gripmenupointertargetpoint) - activetargetnode.translation
				dragvec.z = 0.0
				var prevnodepoints = { }
				var nextnodepoints = { }
				#activetargetnodewall.dragxcnodes(dragvec, sketchsystem)
				for nodename in activetargetnodewall.nodepoints:
					prevnodepoints[nodename] = activetargetnodewall.nodepoints[nodename]
					nextnodepoints[nodename] = activetargetnodewall.nodepoints[nodename] + dragvec
				sketchsystem.actsketchchange([{ "name":activetargetnodewall.get_name(), 
												"prevnodepoints":prevnodepoints,
												"nextnodepoints":nextnodepoints
											}])

			elif pointertarget.get_name() == "HoleXC":
				var xcdata = gripmenu.gripmenupointertargetwall.ConstructHoleXC(gripmenu.gripmenuactivetargettubesectorindex, sketchsystem)
				sketchsystem.actsketchchange([xcdata, 
						{"xcvizstates":{ gripmenu.gripmenupointertargetwall.xcname0:0, 
										 gripmenu.gripmenupointertargetwall.xcname1:0,
										 xcdata["name"]:2 }}])
				setactivetargetwall(sketchsystem.get_node("XCdrawings").get_node(xcdata["name"]))
													
			elif pointertarget.get_name() == "DoSlice" and is_instance_valid(wasactivetargettube) and is_instance_valid(activetargetwall) and len(activetargetwall.nodepoints) == 0:
				print(wasactivetargettube, " ", len(activetargetwall.nodepoints))
				var xcdrawing = activetargetwall
				var xcdata = { "name":xcdrawing.get_name(), "prevnodepoints":{}, "nextnodepoints":{}, "prevonepathpairs":[], "newonepathpairs":[] }
				var xctdatadel = { "tubename":wasactivetargettube.get_name(), 
								   "xcname0":wasactivetargettube.xcname0,
								   "xcname1":wasactivetargettube.xcname1,
								   "prevdrawinglinks":[], "newdrawinglinks":[] }
				var xctdata0 = { "tubename":"**notset", 
								 "xcname0":wasactivetargettube.xcname0,
								 "xcname1":xcdrawing.get_name(),
								 "prevdrawinglinks":[], "newdrawinglinks":[] }
				var xctdata1 = { "tubename":"**notset", 
								 "xcname0":xcdrawing.get_name(),
								 "xcname1":wasactivetargettube.xcname1,
								 "prevdrawinglinks":[], "newdrawinglinks":[] }
				if wasactivetargettube.slicetubetoxcdrawing(xcdrawing, xcdata, xctdatadel, xctdata0, xctdata1):
					clearactivetargetnode()
					clearpointertarget()
					var xctdataviz = {"xcvizstates":{ xcdrawing.get_name():3 }, 
						"updatetubeshells":[
							{ "tubename":xctdatadel["tubename"], "xcname0":xctdatadel["xcname0"], "xcname1":xctdatadel["xcname1"] },
							{ "tubename":xctdata0["tubename"], "xcname0":xctdata0["xcname0"], "xcname1":xctdata0["xcname1"] },
							{ "tubename":xctdata1["tubename"], "xcname0":xctdata1["xcname0"], "xcname1":xctdata1["xcname1"] } 
						]}
					sketchsystem.actsketchchange([xcdata, xctdatadel, xctdata0, xctdata1, xctdataviz])
					setactivetargetwall(xcdrawing)
					wasactivetargettube = null
					activelaserroot.get_node("LaserSpot").visible = false

		
	elif pointertargettype == "GUIPanel3D":
		if guipanel3d.visible:
			guipanel3d.toggleguipanelvisibility(null)

	elif pointertargettype == "XCdrawing" and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		clearpointertargetmaterial()
		var updatexcshells = [ pointertargetwall.get_name() ]
		var updatetubeshells = [ ]
		for xctube in pointertargetwall.xctubesconn:
			if not xctube.positioningtube:
				updatetubeshells.push_back({ "tubename":xctube.get_name(), "xcname0":xctube.xcname0, "xcname1":xctube.xcname1 })

		sketchsystem.actsketchchange([{"xcvizstates":{ pointertargetwall.get_name():2 }, "updatetubeshells":updatetubeshells, "updatexcshells":updatexcshells }])
		#sketchsystem.sharexcdrawingovernetwork(pointertargetwall)
		setactivetargetwall(null)
		clearpointertarget()
		activelaserroot.get_node("LaserSpot").visible = false
		# keep nodes visible???
		
	elif activetargetwall != null:
		sketchsystem.sharexcdrawingovernetwork(activetargetwall)
		setactivetargetwall(null)

	elif activetargetnode != null:
		clearactivetargetnode()

	gripmenu.disableallgripmenus()

func targetwalltransformpos():
	var laserrelvec = activelaserroot.global_transform.basis.inverse()*activetargetwallgrabbedlaserroottrans.basis.z
	var angy = -Vector2(laserrelvec.z, laserrelvec.x).angle()
	var angpush =-(activetargetwallgrabbedlaserroottrans.origin.y - activelaserroot.global_transform.origin.y)
	var transformpos = activetargetwallgrabbedorgtransform.rotated(Vector3(0,1,0), angy)
	var activetargetwallgrabbedpointmoved = activetargetwallgrabbedpoint + 20*angpush*activetargetwallgrabbeddispvector.normalized()
	transformpos.origin += activetargetwallgrabbedpointmoved - transformpos*activetargetwallgrabbedlocalpoint
	return { "name":activetargetwallgrabbed.get_name(), 
			 "prevtransformpos":activetargetwallgrabbed.global_transform,
			 "transformpos":transformpos }

		
func buttonreleased_vrtrigger():
	if activetargetwallgrabbedtransform != null:
		if Tglobal.connectiontoserveractive:
			activetargetwallgrabbed.rpc("setxcdrawingposition", activetargetwallgrabbed.global_transform)
		activetargetwallgrabbedtransform = null
						
var grabbedrpctimecount = 0
func _physics_process(delta):
	if LaserOrient.visible: 
		var firstlasertarget = LaserOrient.get_node("RayCast").get_collider() if LaserOrient.get_node("RayCast").is_colliding() and not LaserOrient.get_node("RayCast").get_collider().is_queued_for_deletion() else null
		pointerplanviewtarget = planviewsystem if firstlasertarget != null and firstlasertarget.get_name() == "PlanView" and planviewsystem.checkplanviewinfront(LaserOrient) else null
		if pointerplanviewtarget != null:
			pointerplanviewtarget.processplanviewsliding(handright.joypos, handright.gripbuttonheld, delta)
		if pointerplanviewtarget != null and pointerplanviewtarget.planviewactive:
			var planviewcontactpoint = LaserOrient.get_node("RayCast").get_collision_point()
			LaserOrient.get_node("LaserSpot").global_transform.origin = planviewcontactpoint
			LaserOrient.get_node("Length").scale.z = -LaserOrient.get_node("LaserSpot").translation.z
			LaserOrient.get_node("LaserSpot").visible = false
			pointerplanviewtarget.processplanviewpointing(planviewcontactpoint)
			activelaserroot = planviewsystem.get_node("RealPlanCamera/LaserScope/LaserOrient")
			activelaserroot.get_node("LaserSpot").global_transform.basis = LaserOrient.global_transform.basis
		else:
			planviewsystem.get_node("RealPlanCamera/LaserScope").visible = false
			activelaserroot = LaserOrient

		setpointertarget(activelaserroot)
		
	if activetargetwallgrabbedtransform != null:
		if activetargetwallgrabbed.get_name() != "PlanView" and activetargetwallgrabbed.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			var txcdata = targetwalltransformpos()
			grabbedrpctimecount += delta
			if grabbedrpctimecount > 0.25:
				txcdata["rpcoptional"] = 1
				grabbedrpctimecount = 0
			sketchsystem.actsketchchange([txcdata])

		elif activetargetwallgrabbedpoint != null:
			activetargetwallgrabbed.global_transform = activelaserroot.get_node("LaserSpot").global_transform * activetargetwallgrabbedtransform
			activetargetwallgrabbed.global_transform.origin += activetargetwallgrabbedpoint - activetargetwallgrabbed.global_transform * activetargetwallgrabbedlocalpoint
		else:
			activetargetwallgrabbed.global_transform = activelaserroot.get_node("LaserSpot").global_transform * activetargetwallgrabbedtransform
		#if Tglobal.connectiontoserveractive:
		#	activetargetwallgrabbed.rpc_unreliable("setxcdrawingposition", activetargetwallgrabbed.global_transform)


var rightmousebuttonheld = false
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	elif event is InputEventKey:
		if event.scancode == KEY_M:
			if not Tglobal.VRoperating:
				handright.vrbybuttonheld = event.pressed
			if event.pressed:
				buttonpressed_vrby(false)	

	elif Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		pass

	elif event is InputEventMouseMotion:
		if not Tglobal.VRoperating: # or playerMe.arvrinterface.get_tracking_status() == ARVRInterface.ARVR_NOT_TRACKING:
			handright.process_keyboardcontroltracking(headcam, event.relative*0.005)
			
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			rightmousebuttonheld = event.pressed
		
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				buttonpressed_vrtrigger(rightmousebuttonheld)
			else:
				buttonreleased_vrtrigger()
			if not Tglobal.VRoperating:
				handright.triggerbuttonheld = event.pressed
				handright.process_handgesturefromcontrol()
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				buttonpressed_vrgrip()
			else:
				buttonreleased_vrgrip()
			if not Tglobal.VRoperating:
				handright.gripbuttonheld = event.pressed
				handright.process_handgesturefromcontrol()
				
	
