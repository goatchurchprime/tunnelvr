extends Node

onready var sketchsystem = get_node("/root/Spatial/SketchSystem")
onready var planviewsystem = get_node("/root/Spatial/PlanViewSystem")

onready var playernode = get_parent()
onready var headcam = playernode.get_node('HeadCam')
onready var handleft = playernode.get_node("HandLeft")
onready var handright = playernode.get_node("HandRight")
onready var guipanel3d = playernode.get_node("GUIPanel3D")

onready var LaserOrient = handright.get_node("LaserOrient") 
onready var DLaserLength = handright.get_node("LaserOrient/Length") 
onready var DLaserRayCast = handright.get_node("LaserOrient/RayCast") 
onready var DLaserSpot = handright.get_node("LaserOrient/LaserSpot") 
onready var LaserShadow = handright.get_node("LaserShadow") 
onready var LaserSelectLine = handright.get_node("LaserSelectLine") 

var viewport_point = null

var distance = 50

const XCdrawing = preload("res://nodescenes/XCdrawing.tscn")
const XCnode = preload("res://nodescenes/XCnode.tscn")
				
var pointinghighlightmaterial = preload("res://guimaterials/XCnode_highlight.material")
var selectedhighlightmaterial = preload("res://guimaterials/XCnode_selected.material")
var selectedpointerhighlightmaterial = preload("res://guimaterials/XCnode_selectedhighlight.material")

var laserspothighlightmaterial = preload("res://guimaterials/laserspot_selected.material"); 


#var laser_y = -0.05

onready var ARVRworld_scale = ARVRServer.world_scale
var mousecontrollervec = Vector3(0.2, -0.1, -0.5)

onready var activelaserroot = handright.get_node("LaserOrient")
var pointerplanviewtarget = null
var pointertarget = null
var pointertargettype = "none"
var pointertargetwall = null
var pointertargetpoint = Vector3(0, 0, 0)
var selectedtarget = null
var selectedtargettype = "none"
var selectedtargetwall = null
var gripbuttonpressused = false

var activetargetwall = null
var activetargetwallgrabbedtransform = null
var activetargetwallgrabbedpoint = null
var activetargetwallgrabbedpointoffset = null
var activetargetwallgrabbedlocalpoint = null

var activetargettube = null
var activetargettubesector = 0

var xcdrawingactivematerial = preload("res://guimaterials/XCdrawing_active.material")
var xcdrawingmaterial = preload("res://guimaterials/XCdrawing.material")
var xcdrawinghighlightmaterial = preload("res://guimaterials/XCdrawing_highlight.material")

func clearpointertargetmaterial():
	if pointertargettype == "XCnode":
		pointertarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, selectedhighlightmaterial if pointertarget == selectedtarget else (preload("res://guimaterials/XCnode_nodepthtest.material") if pointertargetwall == activetargetwall else preload("res://guimaterials/XCnode.material")))
	if (pointertargettype == "XCdrawing" or pointertargettype == "XCnode") and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		if pointertargetwall == activetargetwall:
			xcdrawingactivematerial.uv1_scale = pointertargetwall.get_node("XCdrawingplane").get_scale()
			xcdrawingactivematerial.uv1_offset = -xcdrawingactivematerial.uv1_scale/2
		pointertargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, xcdrawingactivematerial if pointertargetwall == activetargetwall else xcdrawingmaterial)
	handright.get_node("csghandright").setpartcolor(2, "#FFFFFF")
			
func setpointertargetmaterial():
	if pointertargettype == "XCnode":
		pointertarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, selectedpointerhighlightmaterial if pointertarget == selectedtarget else pointinghighlightmaterial)
		handright.get_node("csghandright").setpartcolor(2, "#FFFF60")
	if (pointertargettype == "XCdrawing" or pointertargettype == "XCnode") and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		xcdrawinghighlightmaterial.uv1_scale = pointertargetwall.get_node("XCdrawingplane").get_scale()
		xcdrawinghighlightmaterial.uv1_offset = -xcdrawinghighlightmaterial.uv1_scale/2
		pointertargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, xcdrawinghighlightmaterial)
		handright.get_node("csghandright").setpartcolor(2, "#FFFF60")
	
func setselectedtarget(newselectedtarget):
	setbillboardlabel(null, null)
	if selectedtargettype == "XCnode":
		selectedtarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, preload("res://guimaterials/XCnode_nodepthtest.material") if selectedtargetwall == activetargetwall else preload("res://guimaterials/XCnode.material"))
		
	selectedtarget = newselectedtarget
	selectedtargettype = targettype(newselectedtarget)
	selectedtargetwall = targetwall(selectedtarget, selectedtargettype)
	if selectedtargetwall != null and selectedtargetwall.drawingtype == DRAWING_TYPE.DT_CENTRELINE:
		setbillboardlabel(selectedtarget.get_name(), selectedtarget.global_transform.origin)
	if selectedtarget != pointertarget and selectedtargettype == "XCnode":
		selectedtarget.get_node("CollisionShape/MeshInstance").set_surface_material(0, selectedhighlightmaterial)
	activelaserroot.get_node("LaserSpot").material_override = preload("res://guimaterials/laserspot_selected.material") if selectedtarget != null else null
	setpointertargetmaterial()

func setactivetargetwall(newactivetargetwall):
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, preload("res://guimaterials/XCdrawing.material"))
		activetargetwall.get_node("PathLines").set_surface_material(0, preload("res://guimaterials/XCdrawingPathlines.material"))
		for xcnode in activetargetwall.get_node("XCnodes").get_children():
			xcnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, preload("res://guimaterials/XCnode_selected.material") if xcnode == selectedtarget else preload("res://guimaterials/XCnode.material"))
		for xctube in activetargetwall.xctubesconn:
			if not xctube.positioningtube:
				xctube.updatetubeshell(sketchsystem.get_node("XCdrawings"), sketchsystem.tubeshellsvisible)
		activetargetwall.updatexctubeshell(sketchsystem.get_node("XCdrawings"), sketchsystem.tubeshellsvisible)
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").get_surface_material(0).albedo_color = Color("#FEF4D5")
	
	activetargetwall = newactivetargetwall
	
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").set_surface_material(0, preload("res://guimaterials/XCdrawing_active.material"))
		activetargetwall.get_node("PathLines").set_surface_material(0, preload("res://guimaterials/XCdrawingPathlines_nodepthtest.material"))
		for xcnode in activetargetwall.get_node("XCnodes").get_children():
			if xcnode != selectedtarget:
				xcnode.get_node("CollisionShape/MeshInstance").set_surface_material(0, preload("res://guimaterials/XCnode_nodepthtest.material"))
		LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor 
	else:
		LaserOrient.get_node("RayCast").collision_mask = CollisionLayer.CL_Pointer | CollisionLayer.CL_PointerFloor | CollisionLayer.CL_CaveWall
	if activetargetwall != null and activetargetwall.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
		activetargetwall.get_node("XCdrawingplane/CollisionShape/MeshInstance").get_surface_material(0).albedo_color = Color("#DDFFCC")

func setactivetargettubesector(newactivetargettubesector):
	if activetargettubesector != -1 and activetargettube != null:
		activetargettube.get_node("XCtubeshell/MeshInstance").set_surface_material(activetargettubesector, sketchsystem.materials[activetargettube.xcsectormaterials[activetargettubesector]])
	activetargettubesector = newactivetargettubesector
	if activetargettubesector != -1:
		activetargettube.get_node("XCtubeshell/MeshInstance").set_surface_material(activetargettubesector, sketchsystem.materialhighlight)

func setactivetargettube(newactivetargettube):
	setactivetargetwall(null)
	if activetargettube != null:
		setactivetargettubesector(-1)
	activetargettube = newactivetargettube
	activetargettubesector = -1
	if activetargettube != null:
		setactivetargettubesector(0)

func setbillboardlabel(ltext, pos):
	var textpanel = sketchsystem.get_node("BillboardLabel")
	if ltext != null:
		textpanel.get_node("Viewport/Label").text = ltext
		textpanel.global_transform.origin = pos + Vector3(0, 0.3, 0)
		textpanel.visible = true
	else:
		textpanel.visible = false


func _ready():
	handright.connect("button_pressed", self, "_on_button_pressed")
	handright.connect("button_release", self, "_on_button_release")
	print("in the pointer onready")

func targettype(target):
	if not is_instance_valid(target):
		return "none"
	var targetname = target.get_name()
	if targetname == "GUIPanel3D":
		return "GUIPanel3D"
	if targetname == "PlanView":
		return "PlanView"
	if targetname == "XCtubeshell":
		return "XCtube"
	if targetname == "XCflatshell":
		return "XCflatshell"
	var targetparent = target.get_parent()
	if targetname == "XCdrawingplane":
		assert (targetparent.drawingtype != DRAWING_TYPE.DT_CENTRELINE)
		if targetparent.drawingtype == DRAWING_TYPE.DT_PAPERTEXTURE:
			return "Papersheet"
		return "XCdrawing"
	if targetparent.get_name() == "XCnodes":
		return "XCnode"
	return "unknown"
		
func targetwall(target, targettype):
	if targettype == "XCdrawing" or targettype == "Papersheet":
		return target.get_parent()
	if targettype == "XCnode":
		return target.get_parent().get_parent()
	if targettype == "XCtube":
		return target.get_parent()
	return null
	
func setopnpos(opn, p):
	opn.global_transform.origin = p
		
func onpointing(laserroot):
	var newpointertarget = laserroot.get_node("RayCast").get_collider() if laserroot.get_node("RayCast").is_colliding() and not laserroot.get_node("RayCast").get_collider().is_queued_for_deletion() else null
	var newpointertargetpoint = laserroot.get_node("RayCast").get_collision_point() if newpointertarget != null else null
	if newpointertarget != pointertarget:
		if pointertarget == guipanel3d:
			guipanel3d.guipanelreleasemouse()
		
		clearpointertargetmaterial()
		pointertarget = newpointertarget
		pointertargettype = targettype(pointertarget)
		pointertargetwall = targetwall(pointertarget, pointertargettype)
		setpointertargetmaterial()
		
		print("ppp  ", selectedtargettype, " ", pointertargettype)
		if pointertargettype == "XCnode":
			laserroot.get_node("LaserSpot").visible = false
			LaserShadow.visible = true
		elif pointertargettype == "GUIPanel3D" or pointertargettype == "Papersheet":
			laserroot.get_node("LaserSpot").visible = false
			LaserShadow.visible = false
		elif pointertargettype == "XCdrawing":
			laserroot.get_node("LaserSpot").visible = true
			LaserShadow.visible = (pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING)
		elif pointertargettype == "XCtube":
			laserroot.get_node("LaserSpot").visible = true
			LaserShadow.visible = false
		else:
			laserroot.get_node("LaserSpot").visible = false
			LaserShadow.visible = false
			
		# work out the logic for the LaserSelectLine here
		if handright.is_button_pressed(BUTTONS.VR_GRIP):
			pass
		elif pointertargettype == "XCdrawing":
			LaserSelectLine.visible = (selectedtargettype == "XCnode")
		elif pointertargettype == "XCnode":
			LaserSelectLine.visible = (selectedtargettype == "XCnode")
		else:
			LaserSelectLine.visible = false
			
	pointertargetpoint = newpointertargetpoint
	if is_instance_valid(pointertarget) and pointertarget == guipanel3d:
		guipanel3d.guipanelsendmousemotion(pointertargetpoint, handright.global_transform, handright.is_button_pressed(BUTTONS.VR_TRIGGER))

	if pointertargetpoint != null:
		laserroot.get_node("LaserSpot").global_transform.origin = pointertargetpoint
		laserroot.get_node("Length").scale.z = -laserroot.get_node("LaserSpot").translation.z
	else:
		laserroot.get_node("Length").scale.z = -laserroot.get_node("RayCast").cast_to.z
		
	if LaserSelectLine.visible:
		if pointertarget != null and selectedtarget != null:
			LaserSelectLine.global_transform.origin = pointertargetpoint
			LaserSelectLine.get_node("Scale").scale.z = LaserSelectLine.global_transform.origin.distance_to(selectedtarget.global_transform.origin)
			LaserSelectLine.global_transform = laserroot.get_node("LaserSpot").global_transform.looking_at(selectedtarget.global_transform.origin, Vector3(0,1,0))
		else:
			LaserSelectLine.visible = false
		
	if LaserShadow.visible and pointertargetpoint != null:
		LaserShadow.global_transform = Transform(Basis(), Vector3(pointertargetpoint.x, sketchsystem.getactivefloordrawing().global_transform.origin.y, pointertargetpoint.z))

func _on_button_pressed(p_button):
	var gripbuttonheld = handright.is_button_pressed(BUTTONS.VR_GRIP)
	print("pppp ", pointertargetpoint, " ", [selectedtargettype, pointertargettype])
	if p_button == BUTTONS.VR_BUTTON_BY:
		buttonpressed_vrby(gripbuttonheld)
	elif p_button == BUTTONS.VR_GRIP:
		buttonpressed_vrgrip()
	elif p_button == BUTTONS.VR_TRIGGER:
		buttonpressed_vrtrigger(gripbuttonheld)
	elif p_button == BUTTONS.VR_PAD:
		buttonpressed_vrpad(gripbuttonheld, handright.get_joystick_axis(0), handright.get_joystick_axis(1))
		
	
func buttonpressed_vrby(gripbuttonheld):
	var cameracontrollervec = handright.global_transform.origin - headcam.global_transform.origin
	var ccaxvec = headcam.global_transform.basis.x.dot(handright.global_transform.basis.z)
	var pswitchpos = headcam.global_transform.origin + headcam.global_transform.basis.x*0.15 + headcam.global_transform.basis.y*0.1
	var pswitchdist = handright.global_transform.origin.distance_to(pswitchpos)
	if pointerplanviewtarget != null:
		pointerplanviewtarget.toggleplanviewactive()
	elif ccaxvec > 0.85 and pswitchdist < 0.1:
		guipanel3d.clickbuttonheadtorch()
	else:
		guipanel3d.togglevisibility(handright.get_node("LaserOrient").global_transform)

func buttonpressed_vrgrip():
	gripbuttonpressused = false
	handright.get_node("csghandright").setpartcolor(4, "#00CC00")
				
func buttonpressed_vrtrigger(gripbuttonheld):
	if gripbuttonheld:
		gripbuttonpressused = true
					
	if not is_instance_valid(pointertarget):
		pass
		
	elif pointertarget == guipanel3d:
		pass  #this is processed elsewhere

	elif pointertarget.has_method("jump_up"):
		pointertarget.jump_up()

	# grip click moves node on xcwall
	elif gripbuttonheld and selectedtargettype == "XCnode" and pointertargettype == "XCdrawing" and pointertargetwall == selectedtargetwall:
		selectedtargetwall.movexcnode(selectedtarget, pointertargetpoint, sketchsystem)

	# reselection when selected on grip deletes the node		
	elif gripbuttonheld and selectedtargettype == "XCnode" and pointertarget == selectedtarget and (selectedtargetwall.drawingtype != DRAWING_TYPE.DT_CENTRELINE):
		var recselectedtarget = selectedtarget
		var recselectedtargetwall = selectedtargetwall
		setselectedtarget(null)
		pointertarget = null
		pointertargettype = "none"
		pointertargetwall = null
		activelaserroot.get_node("LaserSpot").visible = false
		LaserShadow.visible = false
		recselectedtargetwall.removexcnode(recselectedtarget, false, sketchsystem)
		sketchsystem.get_node("SoundPos2").global_transform.origin = pointertargetpoint
		sketchsystem.get_node("SoundPos2").play()

	# duplication of XCdrawing (in special cases)
	elif gripbuttonheld and selectedtargetwall != null and selectedtargettype == "XCnode" and selectedtargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE and pointertargettype == "XCnode" and selectedtargetwall == pointertargetwall:
		var xcdrawingtocopy = null
		var xcdrawingtocopynodelink = null
		var btargetclear = true
		for xctube in selectedtargetwall.xctubesconn:
			if sketchsystem.get_node("XCdrawings").get_node(xctube.xcname1).drawingtype == DRAWING_TYPE.DT_XCDRAWING:
				if xctube.xcdrawinglink.slice(0, len(xctube.xcdrawinglink), 2).has(pointertarget.get_name()):
					btargetclear = false
				for i in range(0, len(xctube.xcdrawinglink), 2):
					#if xctube.xcdrawinglink.slice(1, len(xctube.xcdrawinglink), 2).has(selectedtarget.get_name()):
					if xctube.xcdrawinglink[i] == selectedtarget.get_name():
						xcdrawingtocopy = sketchsystem.get_node("XCdrawings").get_node(xctube.xcname1)
						xcdrawingtocopynodelink = xctube.xcdrawinglink[i+1]
						break
		if btargetclear and xcdrawingtocopy != null:
			print("making new copied drawing¬!!!!")
			var xcdrawing = xcdrawingtocopy.duplicatexcdrawing(sketchsystem)
			var vline = pointertargetpoint - selectedtarget.global_transform.origin
			var drawingwallangle = Vector2(vline.z, -vline.x).angle()
			if vline.dot(xcdrawing.global_transform.basis.z) < 0:
				drawingwallangle = Vector2(-vline.z, vline.x).angle()
			xcdrawing.setxcpositionangle(drawingwallangle)
			xcdrawing.setxcpositionorigin(pointertargetpoint)
			sketchsystem.rpc("xcdrawingfromdata", xcdrawing.exportxcrpcdata())
			sketchsystem.xcapplyonepath(xcdrawing.get_node("XCnodes").get_node(xcdrawingtocopynodelink), pointertarget)
			sketchsystem.xcapplyonepath(xcdrawingtocopy.get_node("XCnodes").get_node(xcdrawingtocopynodelink), xcdrawing.get_node("XCnodes").get_node(xcdrawingtocopynodelink))
			setactivetargetwall(xcdrawing)
		setselectedtarget(pointertarget)
	
	# new XCintersecting in tube case
	elif gripbuttonheld and selectedtargettype == "XCnode" and pointertargettype == "XCtube" and (selectedtargetwall.get_name() == pointertargetwall.xcname0 or selectedtargetwall.get_name() == pointertargetwall.xcname1):
		var xcdrawing0 = sketchsystem.get_node("XCdrawings").get_node(pointertargetwall.xcname0)
		var xcdrawing1 = sketchsystem.get_node("XCdrawings").get_node(pointertargetwall.xcname1)
		var v0c = pointertargetpoint - xcdrawing0.global_transform.origin
		var v1c = pointertargetpoint - xcdrawing1.global_transform.origin
		v0c.y = 0
		v1c.y = 0
		var h0c = abs(xcdrawing0.global_transform.basis.z.dot(v0c))
		var h1c = abs(xcdrawing1.global_transform.basis.z.dot(v1c))
		var lam = h0c/(h0c+h1c)
		print(" dd ", v0c, h0c, v1c, h1c, "  ", lam)
		if 0.1 < lam and lam < 0.9:
			var va0c = Vector2(xcdrawing0.global_transform.basis.x.x, xcdrawing0.global_transform.basis.x.z)
			var va1c = Vector2(xcdrawing1.global_transform.basis.x.x, xcdrawing1.global_transform.basis.x.z)
			if va1c.dot(va0c) < 0:
				va1c = -va1c
			var vang = lerp_angle(va0c.angle(), va1c.angle(), lam)				
			var vwallmid = lerp(xcdrawing0.global_transform.origin, xcdrawing1.global_transform.origin, lam)
			
			var xcdrawing = sketchsystem.newXCuniquedrawing(DRAWING_TYPE.DT_XCDRAWING, sketchsystem.uniqueXCname())
			xcdrawing.setxcpositionangle(vang)
			xcdrawing.setxcpositionorigin(vwallmid)
			var xcdrawinglink0 = [ ]
			var xcdrawinglink1 = [ ]
			pointertargetwall.slicetubetoxcdrawing(xcdrawing, xcdrawinglink0, xcdrawinglink1, lam)
			xcdrawing.updatexcpaths()
			sketchsystem.rpc("xcdrawingfromdata", xcdrawing.exportxcrpcdata())
			setactivetargetwall(xcdrawing)
			setselectedtarget(null)
			xcdrawing0.xctubesconn.remove(xcdrawing0.xctubesconn.find(pointertargetwall))
			xcdrawing1.xctubesconn.remove(xcdrawing1.xctubesconn.find(pointertargetwall))

			var xctube0 = sketchsystem.newXCtube(xcdrawing0, xcdrawing)
			xctube0.xcdrawinglink = xcdrawinglink0
			xctube0.updatetubelinkpaths(sketchsystem)
			sketchsystem.rpc("xctubefromdata", xctube0.exportxctrpcdata())
			xctube0.updatetubeshell(sketchsystem.get_node("XCdrawings"), sketchsystem.tubeshellsvisible)
			
			var xctube1 = sketchsystem.newXCtube(xcdrawing1, xcdrawing)
			xctube1.xcdrawinglink = xcdrawinglink1
			xctube1.updatetubelinkpaths(sketchsystem)
			sketchsystem.rpc("xctubefromdata", xctube0.exportxctrpcdata())
			xctube1.updatetubeshell(sketchsystem.get_node("XCdrawings"), sketchsystem.tubeshellsvisible)

			xcdrawing.updatexctubeshell(sketchsystem.get_node("XCdrawings"), sketchsystem.tubeshellsvisible)  # not strictly necessary as there won't be any shells in a sliced tube xc

			pointertargettype = "none"
			pointertarget = null
			pointertargetwall.queue_free()
			pointertargetwall = null
			activelaserroot.get_node("LaserSpot").visible = false
			LaserShadow.visible = false
			
	elif pointertargettype == "XCtube":
		setactivetargettube(pointertargetwall)

	elif pointertargettype == "Papersheet":
		setselectedtarget(null)
		var alaserspot = activelaserroot.get_node("LaserSpot")
		alaserspot.global_transform.origin = pointertargetpoint
		setactivetargetwall(pointertargetwall)
		if gripbuttonheld:
			activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * pointertargetwall.global_transform
			activetargetwallgrabbedpoint = alaserspot.global_transform.origin
			activetargetwallgrabbedlocalpoint = pointertargetwall.global_transform.affine_inverse() * alaserspot.global_transform.origin
			activetargetwallgrabbedpointoffset = alaserspot.global_transform.origin - pointertargetwall.global_transform.origin
		else:
			activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * pointertargetwall.global_transform
			activetargetwallgrabbedpoint = null
			
	# grab and rotate XCdrawing in place (if empty)
	elif pointertargettype == "XCdrawing" and gripbuttonheld and selectedtargettype == "none" and len(pointertargetwall.nodepoints) == 0:
		var alaserspot = activelaserroot.get_node("LaserSpot")
		activetargetwallgrabbedtransform = alaserspot.global_transform.affine_inverse() * pointertargetwall.global_transform
		activetargetwallgrabbedpoint = alaserspot.global_transform.origin
		activetargetwallgrabbedlocalpoint = pointertargetwall.global_transform.affine_inverse() * alaserspot.global_transform.origin
		activetargetwallgrabbedpointoffset = alaserspot.global_transform.origin - pointertargetwall.global_transform.origin

	# grip condition is ignored (assumed off) her on
	#elif gripbuttonheld:
	#	pass
		
	# make new point onto wall, connected if necessary
	elif pointertargettype == "XCdrawing":
		var newpointertarget = pointertargetwall.newxcnode()
		newpointertarget.global_transform.origin = pointertargetpoint
		pointertargetwall.copyxcntootnode(newpointertarget)
		sketchsystem.get_node("SoundPos1").global_transform.origin = pointertargetpoint
		sketchsystem.get_node("SoundPos1").play()
		if selectedtargettype == "XCnode":
			if selectedtargetwall == pointertargetwall:
				sketchsystem.xcapplyonepath(selectedtarget, newpointertarget)
		sketchsystem.rpc("xcdrawingfromdata", pointertargetwall.exportxcrpcdata())
		setselectedtarget(newpointertarget)
	
									
	# reselection clears selection
	elif selectedtargettype == "XCnode" and pointertarget == selectedtarget:
		setselectedtarget(null)

	# connecting lines between xctype nodes
	elif selectedtargettype == "XCnode" and pointertargettype == "XCnode":
		if not ((selectedtargetwall.drawingtype == DRAWING_TYPE.DT_CENTRELINE and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING) or (selectedtargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING and pointertargetwall.drawingtype == DRAWING_TYPE.DT_CENTRELINE)):
			sketchsystem.xcapplyonepath(selectedtarget, pointertarget)
			if selectedtargetwall == pointertargetwall:
				sketchsystem.rpc("xcdrawingfromdata", selectedtargetwall.exportxcrpcdata())
			sketchsystem.get_node("SoundPos1").global_transform.origin = pointertargetpoint
			sketchsystem.get_node("SoundPos1").play()
			setselectedtarget(null)  # setselectedtarget(pointertarget)
											
	elif pointertargettype == "XCnode":
		if pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
			pointertargetwall.rpc("setxcdrawingvisibility", true)
			if pointertargetwall != activetargetwall:
				setactivetargetwall(pointertargetwall)
		setselectedtarget(pointertarget)

				
func buttonpressed_vrpad(gripbuttonheld, left_right, up_down):
	if pointertargettype == "XCdrawing" and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		if abs(up_down) < 0.5 and abs(left_right) > 0.1:
			var dy = (1 if left_right > 0 else -1)*(1.0 if abs(left_right) < 0.8 else 0.1)
			pointertargetwall.get_node("XCdrawingplane").scale.x = max(1, pointertargetwall.get_node("XCdrawingplane").scale.x + dy)
			pointertargetwall.get_node("XCdrawingplane").scale.y = max(1, pointertargetwall.get_node("XCdrawingplane").scale.y + dy)
			xcdrawinghighlightmaterial.uv1_scale = pointertargetwall.get_node("XCdrawingplane").get_scale()
			xcdrawinghighlightmaterial.uv1_offset = -xcdrawinghighlightmaterial.uv1_scale/2
				
	elif pointertargettype == "Papersheet":
		if abs(up_down) > 0.5:
			var dd = (1 if up_down > 0 else -1)*(0.2 if activelaserroot.get_node("Length").scale.z < 1.5 else 1.0)
			if activelaserroot.get_node("Length").scale.z + dd > 0.1:
				pointertargetwall.global_transform.origin += -dd*LaserOrient.global_transform.basis.z
		elif abs(left_right) > 0.1:
			var fs = (0.5 if abs(left_right) < 0.8 else 0.9)
			if left_right > 0:
				fs = 1/fs
			pointertargetwall.get_node("XCdrawingplane").scale.x *= fs
			pointertargetwall.get_node("XCdrawingplane").scale.y *= fs

	elif pointertargettype == "XCtube" and activetargettube != null and pointertargetwall == activetargettube:
		if abs(left_right) > 0.65:
			var nsectors = activetargettube.get_node("XCtubeshell/MeshInstance").get_surface_material_count()
			setactivetargettubesector((activetargettubesector + (1 if left_right > 0 else nsectors-1))%nsectors)
		elif abs(up_down) > 0.70:
			activetargettube.xcsectormaterials[activetargettubesector] = int(activetargettube.xcsectormaterials[activetargettubesector] + (1 if up_down > 0 else len(sketchsystem.materials) - 1))%len(sketchsystem.materials)

	#elif pointertargettype == "PlanView":
	elif pointerplanviewtarget != null and not pointerplanviewtarget.planviewactive:
		var plancamera = pointerplanviewtarget.get_node("PlanView/Viewport/Camera")
		if abs(left_right) > 0.65:
			plancamera.size *= (1.5 if left_right < 0 else 0.6667)
			pointerplanviewtarget.get_node("RealPlanCamera/RealCameraBox").scale = Vector3(plancamera.size, 1, plancamera.size)
		if abs(left_right) < 0.2 and abs(up_down) < 0.2:
			plancamera.translation = Vector3(headcam.global_transform.origin.x, plancamera.translation.y, headcam.global_transform.origin.z)
		
func _on_button_release(p_button):
	if p_button == BUTTONS.VR_GRIP:
		buttonreleased_vrgrip()
	elif p_button == BUTTONS.VR_TRIGGER:
		buttonreleased_vrtrigger()

func buttonreleased_vrgrip():
	handright.get_node("csghandright").setpartcolor(4, "#FFFFFF")

	if gripbuttonpressused:
		pass  # the trigger was pulled during the grip operation
	
	elif pointertargettype == "GUIPanel3D":
		if guipanel3d.visible:
			guipanel3d.togglevisibility(handright.get_node("LaserOrient").global_transform)

	elif pointertargettype == "XCdrawing" and pointertargetwall.drawingtype == DRAWING_TYPE.DT_XCDRAWING:
		clearpointertargetmaterial()
		pointertargetwall.rpc("setxcdrawingvisibility", false)
		sketchsystem.rpc("xcdrawingfromdata", pointertargetwall.exportxcrpcdata())
		setactivetargetwall(null)
		pointertarget = null
		pointertargettype = "none"
		pointertargetwall = null
		activelaserroot.get_node("LaserSpot").visible = false
		LaserShadow.visible = false

	elif selectedtargettype == "XCnode":
		setselectedtarget(null)
		
	elif pointertargettype == "XCtube":
		setactivetargettube(null)
		
func buttonreleased_vrtrigger():
	if activetargetwallgrabbedtransform != null:
		setactivetargetwall(null)
		activetargetwallgrabbedtransform = null
	
	if (pointertargettype == "XCnode" and pointertargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE) and (selectedtargettype == "XCnode" and selectedtargetwall.drawingtype == DRAWING_TYPE.DT_FLOORTEXTURE) and pointertarget != selectedtarget:
		print("makingxcplane")
		var xcdrawing = sketchsystem.newXCuniquedrawing(DRAWING_TYPE.DT_XCDRAWING, sketchsystem.uniqueXCname())
		var vx = pointertarget.global_transform.origin - selectedtarget.global_transform.origin
		xcdrawing.setxcpositionangle(Vector2(vx.x, vx.z).angle())
		var vwallmid = (pointertarget.global_transform.origin + selectedtarget.global_transform.origin)/2
		xcdrawing.setxcpositionorigin(vwallmid)
		setselectedtarget(null)
		setactivetargetwall(xcdrawing)
		sketchsystem.rpc("xcdrawingfromdata", xcdrawing.exportxcrpcdata())
						
func _physics_process(_delta):
	if !is_inside_tree():
		return

	if playernode.arvrinterface == null:
		var mvec = headcam.global_transform.basis.xform(mousecontrollervec)
		handright.global_transform.origin = headcam.global_transform.origin + mvec
		handright.look_at(handright.global_transform.origin + 1.0*mvec + 0.0*headcam.global_transform.basis.z, Vector3(0,1,0))
		handright.global_transform.origin.y -= 0.3
		
	if activetargetwallgrabbedtransform != null:
		if activetargetwallgrabbedpoint != null:
			#activetargetwallgrabbedtransform = LaserSpot.global_transform.affine_inverse() * pointertargetwall.global_transform
			#activetargetwallgrabbedlocalpoint = pointertargetwall.global_transform.affine_inverse() * LaserSpot.global_transform.origin
			#activetargetwallgrabbedpoint = LaserSpot.global_transform.origin
			#activetargetwallgrabbedpointoffset = LaserSpot.global_transform.origin - pointertargetwall.global_transform.origin
			pointertargetwall.global_transform = activelaserroot.get_node("LaserSpot").global_transform * activetargetwallgrabbedtransform
			pointertargetwall.global_transform.origin += activetargetwallgrabbedpoint - pointertargetwall.global_transform * activetargetwallgrabbedlocalpoint
			#pointertargetwall.global_transform.origin = activetargetwallgrabbedpoint - activetargetwallgrabbedpointoffset + (pointertargetwall.global_transform.basis * activetargetwallgrabbedtransform.origin)
		else:
			pointertargetwall.global_transform = activelaserroot.get_node("LaserSpot").global_transform * activetargetwallgrabbedtransform
		pointertargetwall.rpc_unreliable("setxcdrawingposition", pointertargetwall.global_transform)
		
	var firstlasertarget = LaserOrient.get_node("RayCast").get_collider() if LaserOrient.get_node("RayCast").is_colliding() and not LaserOrient.get_node("RayCast").get_collider().is_queued_for_deletion() else null
	pointerplanviewtarget = planviewsystem if firstlasertarget != null and firstlasertarget.get_name() == "PlanView" and planviewsystem.checkplanviewinfront(handright) else null
	if pointerplanviewtarget != null and pointerplanviewtarget.planviewactive:
		pointerplanviewtarget.processplanviewpointing(LaserOrient.get_node("RayCast").get_collision_point())
		activelaserroot = planviewsystem.get_node("RealPlanCamera/LaserScope")
		LaserOrient.get_node("LaserSpot").visible = false
	else:
		if pointerplanviewtarget != null:
			pointerplanviewtarget.processplanviewsliding(handright, _delta)
		planviewsystem.get_node("RealPlanCamera/LaserScope").visible = false
		activelaserroot = LaserOrient
		
	onpointing(activelaserroot)


var rightmousebuttonheld = false
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if playernode.arvrinterface == null or playernode.arvrinterface.get_tracking_status() == ARVRInterface.ARVR_NOT_TRACKING:
			var rhvec = mousecontrollervec + Vector3(event.relative.x, -event.relative.y, 0)*0.002
			rhvec.x = clamp(rhvec.x, -0.4, 0.4)
			rhvec.y = clamp(rhvec.y, -0.3, 0.6)
			mousecontrollervec = rhvec.normalized()*0.8
			
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			rightmousebuttonheld = event.pressed
		
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				buttonpressed_vrtrigger(rightmousebuttonheld)
			else:
				buttonreleased_vrtrigger()
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				buttonpressed_vrgrip()
			else:
				buttonreleased_vrgrip()

	elif event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var gripbuttonheld = false
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				buttonpressed_vrtrigger(gripbuttonheld)
			else:
				buttonreleased_vrtrigger()

func _on_HeelHotspot_body_entered(body):
	print("_on_HeelHotspot_body_entered ", body)

func _on_HeelHotspot_body_exited(body):
	print("_on_HeelHotspot_body_exited ", body)
