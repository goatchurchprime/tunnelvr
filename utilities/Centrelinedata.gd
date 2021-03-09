class_name Centrelinedata


# "C:\Program Files (x86)\Survex\aven.exe" Ireby\Ireby2\Ireby2.svx
# python surveyscans\convertdmptojson.py Ireby\Ireby2\Ireby2.3d
static func xcdatalistfromcentreline(centrelinefile):
	print("Opening centreline file ", centrelinefile)
	var centrelinedatafile = File.new()
	centrelinedatafile.open(centrelinefile, File.READ)
	var centrelinedata = parse_json(centrelinedatafile.get_line())

	var stationpointscoords = centrelinedata.stationpointscoords
	var stationpointsnamesorg = centrelinedata.stationpointsnames
	var legsconnections = centrelinedata.legsconnections
	var legsstyles = centrelinedata.legsstyles

	var bb = [ stationpointscoords[0], stationpointscoords[1], stationpointscoords[2], 
			   stationpointscoords[0], stationpointscoords[1], stationpointscoords[2] ]
	for i in range(len(stationpointsnamesorg)):
		for j in range(3):
			bb[j] = min(bb[j], stationpointscoords[i*3+j])
			bb[j+3] = max(bb[j+3], stationpointscoords[i*3+j])
	print("svx bounding box", bb)
	var bbcenvec = Vector3((bb[0]+bb[3])/2, (bb[2] - 1), (bb[1]+bb[4])/2)

	var stationpointsnames = [ ]
	var stationpoints = [ ]
	var stationnodepoints = { }
	for i in range(len(stationpointsnamesorg)):
		var stationpointname = stationpointsnamesorg[i].replace(".", ",")   # dots not allowed in node name, but commas are
		stationpointsnames.push_back(stationpointname)
		#nodepoints[k] = Vector3(stationpointscoords[i*3], 8.1+stationpointscoords[i*3+2], -stationpointscoords[i*3+1])
		var stationpoint = Vector3(stationpointscoords[i*3] - bbcenvec.x, 
								   stationpointscoords[i*3+2] - bbcenvec.y, 
								   -(stationpointscoords[i*3+1] - bbcenvec.z))
		stationpoints.push_back(stationpoint)
		if stationpointname != "":
			stationnodepoints[stationpointname] = stationpoint

	var centrelinelegs = [ ]
	for i in range(len(legsstyles)):
		if stationpointsnames[legsconnections[i*2]] != "" and stationpointsnames[legsconnections[i*2+1]] != "":
			centrelinelegs.push_back(stationpointsnames[legsconnections[i*2]])
			centrelinelegs.push_back(stationpointsnames[legsconnections[i*2+1]])

	var xcdrawingcentreline = { "name":"centreline", 
								"xcresource":"centrelinedata", 
								"drawingtype":DRAWING_TYPE.DT_CENTRELINE, 
								"transformpos":Transform(), 
								"prevnodepoints":{ },
								"nextnodepoints":stationnodepoints,
								"prevonepathpairs":[ ],
								"newonepathpairs":centrelinelegs, 
							  }
	var xcdrawinglist = [ xcdrawingcentreline ]
	#var xcvizstates = { xcdrawingcentreline["name"]:DRAWING_TYPE.VIZ_XCD_NODES_VISIBLE }
	var xcvizstates = { xcdrawingcentreline["name"]:DRAWING_TYPE.VIZ_XCD_HIDE }
	var updatetubeshells = [ ]

	var xsectgps = centrelinedata.xsectgps
	var hexonepathpairs = [ "hl","hu", "hu","hv", "hv","hr", "hr","he", "he","hd", "hd","hl"]
	var hextubepairs = ["hl", "hl", "mediumrock", null,  "hr", "hr", "partialrock", null]
	for j in range(len(xsectgps)):
		var xsectgp = xsectgps[j]
		var xsectindexes = xsectgp.xsectindexes
		var xsectrightvecs = xsectgp.xsectrightvecs
		var xsectlruds = xsectgp.xsectlruds

		var prevsname = null
		for i in range(len(xsectindexes)):
			var sname = stationpointsnames[xsectindexes[i]]+"s"+String(j)
			var hexnodepoints = { }
			var xl = max(0.1, xsectlruds[i*4+0])
			var xr = max(0.1, xsectlruds[i*4+1])
			var xu = max(0.1, xsectlruds[i*4+2])
			var xd = max(0.1, xsectlruds[i*4+3])
			hexnodepoints["hl"] = Vector3(-xl, 0, 0)
			hexnodepoints["hr"] = Vector3(xr, 0, 0)
			hexnodepoints["hu"] = Vector3(-xl/2, xu, 0)
			hexnodepoints["hv"] = Vector3(+xr/2, xu, 0)
			hexnodepoints["hd"] = Vector3(-xl/2, -xd, 0)
			hexnodepoints["he"] = Vector3(+xr/2, -xd, 0)
			var p = stationpoints[xsectindexes[i]]
			var ang = Vector2(xsectrightvecs[i*2], -xsectrightvecs[i*2+1]).angle()
			var xcdata = { "name":sname, 
						   "xcresource":"station_"+sname, 
						   "drawingtype":DRAWING_TYPE.DT_XCDRAWING, 
						   "transformpos":Transform(Basis().rotated(Vector3(0,-1,0), ang), p), 
						   "prevnodepoints":{ },
						   "nextnodepoints":hexnodepoints,
						   "prevonepathpairs":[ ],
						   "newonepathpairs":hexonepathpairs.duplicate(),
						 }
			xcdrawinglist.push_back(xcdata)
			xcvizstates[sname] = DRAWING_TYPE.VIZ_XCD_HIDE

			if prevsname != null:
				var xctdata = { "tubename":"**notset", 
								"xcname0":prevsname, 
								"xcname1":sname,
								"prevdrawinglinks":[ ],
								"newdrawinglinks":hextubepairs.duplicate()
							  }
				xcdrawinglist.push_back(xctdata)
				updatetubeshells.push_back({ "tubename":xctdata["tubename"], "xcname0":xctdata["xcname0"], "xcname1":xctdata["xcname1"] })
			prevsname = sname

	xcdrawinglist.push_back({ "xcvizstates":xcvizstates, "updatetubeshells":updatetubeshells })
	return xcdrawinglist
	

static func xcdatalistfromwinddata(wingdeffile):
	var f = File.new()
	f.open(wingdeffile, File.READ)
	var k = [ ]
	for j in range(70):
		k.append(f.get_csv_line())
	var sections = [ ]
	var zvals = [ ]
	for i in range(1, 60, 3):
		var pts = [ ]
		var z = float(k[2][i+1])
		for j in range(2, 70):
			assert (z == float(k[j][i+1]))
			pts.append(Vector3(float(k[j][i]), float(k[j][i+2]), 0))
		zvals.append(z)
		sections.append(pts)
	
	var nodepairs = [ ]
	for i in range(67):
		nodepairs.append("p%d"%i)
		nodepairs.append("p%d"%(i+1))
	var xcdrawinglist = [ ]
	var xcvizstates = { }
	var prevsname = null
	var updatetubeshells = [ ]
	var enddrawinglinks = ["p0", "p0", "graphpaper", null,  "p67", "p67", "graphpaper", null]
	for j in range(len(sections)):
		var pts = sections[j]
		var nodepoints = { }
		for i in range(68):
			nodepoints["p%d" % i] = pts[i]
		var sname = "ws%d"%j
		var xcdata = { "name":sname, 
					   "drawingtype":DRAWING_TYPE.DT_XCDRAWING, 
					   "transformpos":Transform(Basis(), Vector3(0, 1.2, zvals[j])), 
					   "prevnodepoints":{ },
					   "nextnodepoints":nodepoints,
					   "prevonepathpairs":[ ],
					   "newonepathpairs":nodepairs.duplicate(),
					 }
		xcdrawinglist.push_back(xcdata)
		xcvizstates[sname] = DRAWING_TYPE.VIZ_XCD_HIDE
		if j != 0:
			var xctdata = { "tubename":"**notset", 
							"xcname0":prevsname, 
							"xcname1":sname,
							"prevdrawinglinks":[ ],
							"newdrawinglinks":enddrawinglinks.duplicate()
						  }
			xcdrawinglist.push_back(xctdata)
			updatetubeshells.push_back({ "tubename":xctdata["tubename"], "xcname0":xctdata["xcname0"], "xcname1":xctdata["xcname1"] })
		prevsname = sname
	xcdrawinglist.push_back({ "xcvizstates":xcvizstates, "updatetubeshells":updatetubeshells })
	return xcdrawinglist
	

