class_name Polynets

class sd0class:
	static func sd0(a, b):
		return a[0] < b[0]

static func isinnerpoly(poly, nodepoints):
	var jbl = 0
	var ptbl = nodepoints[poly[jbl]]
	for j in range(1, len(poly)):
		var pt = nodepoints[poly[j]]
		if pt.y < ptbl.y or (pt.y == ptbl.y and pt.x < ptbl.x):
			jbl = j
			ptbl = pt
	var ptblFore = nodepoints[poly[(jbl+1)%len(poly)]]
	var ptblBack = nodepoints[poly[(jbl+len(poly)-1)%len(poly)]]
	var angFore = Vector2(ptblFore.x-ptbl.x, ptblFore.y-ptbl.y).angle()
	var angBack = Vector2(ptblBack.x-ptbl.x, ptblBack.y-ptbl.y).angle()
	return (angBack < angFore)

static func makexcdpolys(nodepoints, onepathpairs):
	var Lpathvectorseq = { } 
	for i in nodepoints.keys():
		Lpathvectorseq[i] = [ ]  # [ (arg, pathindex) ]
	var Npaths = len(onepathpairs)/2
	var opvisits2 = [ ]
	for i in range(Npaths):
		var i0 = onepathpairs[i*2]
		var i1 = onepathpairs[i*2+1]
		if i0 != i1:
			var vec3 = nodepoints[i1] - nodepoints[i0]
			var vec = Vector2(vec3.x, vec3.y)
			Lpathvectorseq[i0].append([vec.angle(), i])
			Lpathvectorseq[i1].append([(-vec).angle(), i])
			opvisits2.append(0)
			opvisits2.append(0)
		else:
			print("Suppressing loop edge in onepathpairs (how did it get here?) polynet function would fail as it relies on orientation")
			opvisits2.append(-1)
			opvisits2.append(-1)
		
	for pathvectorseq in Lpathvectorseq.values():
		pathvectorseq.sort_custom(sd0class, "sd0")
		
	var polys = [ ]
	var linearpaths = [ ]
	var outerpoly = null
	assert (len(opvisits2) == len(onepathpairs))
	for i in range(len(opvisits2)):
		if opvisits2[i] != 0:
			continue
		var ne = int(i/2)
		var np = onepathpairs[ne*2 + (0 if ((i%2)==0) else 1)]
		var poly = [ ]
		var singlenodeindexes = [ ]
		var hasnondoublenodes = false
		while (opvisits2[ne*2 + (0 if onepathpairs[ne*2] == np else 1)]) == 0:
			opvisits2[ne*2 + (0 if onepathpairs[ne*2] == np else 1)] = len(polys)+1
			poly.append(np)
			np = onepathpairs[ne*2 + (1  if onepathpairs[ne*2] == np  else 0)]
			if len(Lpathvectorseq[np]) == 1:
				singlenodeindexes.append(len(poly))
			elif len(Lpathvectorseq[np]) != 2:
				hasnondoublenodes = true
			for j in range(len(Lpathvectorseq[np])):
				if Lpathvectorseq[np][j][1] == ne:
					ne = Lpathvectorseq[np][(j+1)%len(Lpathvectorseq[np])][1]
					break
		
		# find and record the orientation of the polygon by looking at the bottom left
		if len(poly) == 0:
			print("bad poly size 0")
			continue
			
		if len(singlenodeindexes) == 0:
			if not isinnerpoly(poly, nodepoints):
				if outerpoly != null:
					print(" *** extra outer poly ", outerpoly, poly)
					polys.append(outerpoly) 
				outerpoly = poly
			else:
				polys.append(poly)
		if len(singlenodeindexes) == 2 and not hasnondoublenodes:
			var linearpath
			if singlenodeindexes[1] != len(poly):
				linearpath = poly.slice(singlenodeindexes[0], singlenodeindexes[1])
			else:	
				linearpath = poly.slice(0, singlenodeindexes[0])
			if isinnerpoly(linearpath, nodepoints):
				linearpath.invert()
			linearpaths.append(linearpath)
			
	if len(polys) != 0:
		polys.append(outerpoly if outerpoly != null else [])
		return polys
	if len(linearpaths) == 1:
		return linearpaths
	return [ ]


static func makeropenodesequences(nodepoints, onepathpairs, oddropeverts):
	var Lpathvectorseq = { } 
	for ii in nodepoints.keys():
		Lpathvectorseq[ii] = [ ]
	var Npaths = len(onepathpairs)/2
	var opvisits = [ ]
	for j in range(Npaths):
		var i0 = onepathpairs[j*2]
		var i1 = onepathpairs[j*2+1]
		Lpathvectorseq[i0].append(j)
		Lpathvectorseq[i1].append(j)
		opvisits.append(0)

	if oddropeverts != null:
		oddropeverts.clear()
		for ii in nodepoints.keys():
			if (len(Lpathvectorseq[ii])%2) == 1:
				oddropeverts.push_back(ii)
	
	var ropesequences = [ ]
	for j in range(Npaths):
		if opvisits[j] != 0:
			continue
		opvisits[j] = len(ropesequences)+1
		var ropeseq = [ onepathpairs[j*2], onepathpairs[j*2+1] ]
		var j1 = j
		while true:
			var i1 = ropeseq[-1]
			if len(Lpathvectorseq[i1]) != 2:
				break
			if i1[0] == "a":
				break
			assert (Lpathvectorseq[i1].has(j1))
			j1 = Lpathvectorseq[i1][1] if Lpathvectorseq[i1][0] == j1 else Lpathvectorseq[i1][0]
			if opvisits[j1] != 0:
				assert (opvisits[j1] == len(ropesequences)+1)
				break
			opvisits[j1] = len(ropesequences)+1
			assert ((i1 == onepathpairs[j1*2]) or (i1 == onepathpairs[j1*2+1]))
			ropeseq.append(onepathpairs[j1*2+1] if (i1 == onepathpairs[j1*2]) else onepathpairs[j1*2])
		ropeseq.invert()
		j1 = j
		while true:
			var i1 = ropeseq[-1]
			if len(Lpathvectorseq[i1]) != 2:
				break
			if i1[0] == "a":
				break
			assert (Lpathvectorseq[i1].has(j1))
			j1 = Lpathvectorseq[i1][1] if Lpathvectorseq[i1][0] == j1 else Lpathvectorseq[i1][0]
			if opvisits[j1] != 0:
				assert (opvisits[j1] == len(ropesequences)+1)
				assert (false)
				break
			opvisits[j1] = len(ropesequences)+1
			assert ((i1 == onepathpairs[j1*2]) or (i1 == onepathpairs[j1*2+1]))
			ropeseq.append(onepathpairs[j1*2+1] if (i1 == onepathpairs[j1*2]) else onepathpairs[j1*2])
		if len(ropeseq) >= 2:
			if ropeseq[-1][0] == "a":
				ropeseq.invert()
			elif len(Lpathvectorseq[ropeseq[0]]) == 1:
				ropeseq.invert()
			ropesequences.append(ropeseq)
	return ropesequences

static func triangulatepolygon(poly):
	var surfaceTool = SurfaceTool.new()
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pv = PoolVector2Array()
	for p in poly:
		pv.append(Vector2(p.x, p.y))
	var pi = Geometry.triangulate_polygon(pv)
	for u in pi:
		surfaceTool.add_uv(Vector2(poly[u].x, poly[u].z))
		surfaceTool.add_vertex(poly[u])
	surfaceTool.generate_normals()
	return surfaceTool.commit()



static func stalfromropenodesequences(nodepoints, ropeseqs):  # stalactites, stalagmites and columns
	if len(ropeseqs) == 1:
		var ropeseq = ropeseqs[0]
		if ropeseq[0] == ropeseq[-1]:
			return null
		if ropeseq[0][0] != "a" or ropeseq[-1][0] != "a":
			return null
		if len(ropeseq) <= 3:
			return null
		var ylo = min(nodepoints[ropeseq[0]].y, nodepoints[ropeseq[-1]].y)
		var yhi = max(nodepoints[ropeseq[0]].y, nodepoints[ropeseq[-1]].y)
		var iext = -1
		for i in range(1, len(ropeseq)-1):
			if nodepoints[ropeseq[i]].y < ylo:
				ylo = nodepoints[ropeseq[i]].y
				iext = i
			if nodepoints[ropeseq[i]].y > yhi:
				yhi = nodepoints[ropeseq[i]].y
				iext = i
		if iext != 1 and iext != len(ropeseq) - 2:
			return null
		ropeseqs.pop_back()
		ropeseqs.push_back(ropeseq.slice(0, iext))
		ropeseqs.push_back(ropeseq.slice(iext, len(ropeseq)-1))
	elif len(ropeseqs) != 2:
		return null
		
	if len(ropeseqs[1]) != 2:
		ropeseqs.invert()
	if len(ropeseqs[1]) != 2:
		return null
	if ropeseqs[0][-1][0] == "a":
		ropeseqs[0].invert()
	if ropeseqs[1][-1][0] == "a":
		ropeseqs[1].invert()
	if ropeseqs[1][0][0] != "a":
		return null
	if ropeseqs[0][0][0] != "a":
		return null
		
	var stalseq = [ ]
	for r in ropeseqs[0]:
		stalseq.push_back(nodepoints[r])
	var ax0 = nodepoints[ropeseqs[1][0]]
	var ax1 = nodepoints[ropeseqs[1][1]]
	var vec = ax0 - ax1
	if vec.dot(stalseq[-1] - stalseq[0]) > 0:
		vec = -vec
	var nohideaxisnodes = [ ropeseqs[1][0] ]
	if ropeseqs[1][1][0] == "a":
		nohideaxisnodes.push_back(ropeseqs[1][1])
	return [stalseq, ax1, vec, nohideaxisnodes]
	
	
static func makestalshellmesh(revseq, p0, vec):
	var Nsides = max(8, int(300/(len(revseq) + 10)))
	var arraymesh = ArrayMesh.new()
	var surfaceTool = SurfaceTool.new()
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prevrevring = null
	var prevringrad = 1
	var v = 0
	for j in range(len(revseq)):
		var rp = revseq[j]
		var lam = vec.dot(rp - p0)/vec.dot(vec)
		var a = p0 + vec*lam
		var rv = rp - a
		var ringrad = rv.length()
		var rvperp = rv.cross(vec.normalized())
		var revring = [ ]
		for i in range(Nsides):
			var theta = deg2rad(i*360.0/Nsides)
			var pt = a + cos(theta)*rv + sin(theta)*rvperp
			var u = theta*(prevringrad + ringrad)*0.5
			revring.push_back(pt)
			revring.push_back(Vector2(u, v))
		if prevrevring != null:
			for i in range(Nsides):
				var i1 = (i+1)%Nsides
				surfaceTool.add_uv(prevrevring[i*2+1])
				surfaceTool.add_uv2(prevrevring[i*2+1])
				surfaceTool.add_vertex(prevrevring[i*2])
				surfaceTool.add_uv(revring[i*2+1])
				surfaceTool.add_uv2(revring[i*2+1])
				surfaceTool.add_vertex(revring[i*2])
				surfaceTool.add_uv(revring[i1*2+1])
				surfaceTool.add_uv2(revring[i1*2+1])
				surfaceTool.add_vertex(revring[i1*2])

				surfaceTool.add_uv(prevrevring[i*2+1])
				surfaceTool.add_uv2(prevrevring[i*2+1])
				surfaceTool.add_vertex(prevrevring[i*2])
				surfaceTool.add_uv(revring[i1*2+1])
				surfaceTool.add_uv2(revring[i1*2+1])
				surfaceTool.add_vertex(revring[i1*2])
				surfaceTool.add_uv(prevrevring[i1*2+1])
				surfaceTool.add_uv2(prevrevring[i1*2+1])
				surfaceTool.add_vertex(prevrevring[i1*2])
		prevrevring = revring
		prevringrad = ringrad
		v += vec.length()
	surfaceTool.generate_normals()
	surfaceTool.generate_tangents()
	surfaceTool.commit(arraymesh)
	return arraymesh


static func signpostfromropenodesequences(nodepoints, ropeseqs):
	if len(ropeseqs) <= 1:
		return null
	var signpostseqj = -1
	for j in range(len(ropeseqs)):
		var ropeseq = ropeseqs[j]
		if ropeseq[0][0] == "a" or ropeseq[-1][0] == "a":
			if len(ropeseq) != 2 or signpostseqj != -1:
				return null
			if ropeseq[-1][0] == "a":
				if ropeseq[0][0] == "a":
					return null
				ropeseq.invert()
			signpostseqj = j
	if signpostseqj == -1:
		return null

	var signpostseq = ropeseqs[signpostseqj]
	var vss = nodepoints[signpostseq[1]] - nodepoints[signpostseq[0]]
	var vssa = rad2deg(Vector2(vss.y, Vector2(vss.x, vss.z).length()).angle())
	var signdownwards = (vssa > 90)
	if (180-vssa if signdownwards else vssa) > 45:
		return null
	
	var ptsignroot = nodepoints[signpostseq[0]]
	var ptsigntopy = nodepoints[signpostseq[1]].y
	var flagpolys = [ ]
	if len(ropeseqs) == 2:
		var flagseq = ropeseqs[1-signpostseqj]
		if len(flagseq) < 4:
			return null
		if flagseq[0] != flagseq[-1]:
			return null
		var vs0 = nodepoints[flagseq[1]] - nodepoints[flagseq[0]]
		var vs1 = nodepoints[flagseq[-2]] - nodepoints[flagseq[-1]]
		var vs0a = rad2deg(Vector2(vs0.y, Vector2(vs0.x, vs0.z).length()).angle())
		var vs1a = rad2deg(Vector2(vs1.y, Vector2(vs1.x, vs1.z).length()).angle())
		if signdownwards:
			vs0a = 180-vs0a
			vs1a = 180-vs1a
		if vs1a < vs0a:
			flagseq.invert()
			vs0a = vs1a
		if vs0a > 45:
			return null
			
		ptsigntopy = nodepoints[flagseq[1]].y
		flagpolys.append(flagseq)
	else:
		return null
		
	var ptsigntop = Vector3(ptsignroot.x, ptsigntopy, ptsignroot.z)
	var flagsigns = [ ]
	for j in range(len(flagpolys)):
		var ppoly = [ ]
		var flagmsg = "@"
		for d in flagpolys[j]:
			ppoly.append(nodepoints[d])
			if d > flagmsg:
				flagmsg = d
		var vecfurthest = ppoly[0] - ptsigntop
		for i in range(1, len(ppoly)):
			var veci = ppoly[i] - ptsigntop
			if veci.length_squared() > vecfurthest.length_squared():
				vecfurthest = veci
		var veciang = rad2deg(Vector2(Vector2(vecfurthest.x, vecfurthest.z).length(), vecfurthest.y).angle())
		if abs(veciang) < 30:
			vecfurthest.y = 0
		var vecletters = vecfurthest.normalized()
		var veclettersup = Vector3(0, 1, 0)
		if vecletters.y != 0:
			var vecletters2d = Vector2(vecletters.x, vecletters.z).length()
			if vecletters2d != 0.0:
				veclettersup = Vector3(-vecletters.x/vecletters2d*vecletters2d.y, vecletters2d, -vecletters.z/vecletters2d*vecletters2d.y)
			else:
				veclettersup = Vector3(1, 0, 0)
		flagsigns.append([ flagmsg, vecletters, veclettersup ])

	return [ptsignroot, ptsigntopy, flagsigns]


static func makesignpostshellmesh(ptsignroot, ptsigntopy, flagsigns):
	var Nsides = 8
	var arraymesh = ArrayMesh.new()
	var surfaceTool = SurfaceTool.new()
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var postrad = 0.05
	var vheight = ptsigntopy - ptsignroot.y
	var ptpr = ptsignroot + Vector3(postrad, 0, 0)
	var ptpt = ptsignroot + Vector3(postrad, vheight, 0)
	var up = 0.0
	for i in range(Nsides):
		var theta = deg2rad((i+1)*360.0/Nsides)
		var vp = Vector3(cos(theta)*postrad, 0, sin(theta)*postrad) if i < Nsides-1 else Vector3(postrad, 0, 0)
		var ptnr = ptsignroot + vp
		var ptnt = ptnr + Vector3(0, vheight, 0)
		var un = theta*postrad
		
		surfaceTool.add_uv(Vector2(up, 0))
		surfaceTool.add_uv2(Vector2(up, 0))
		surfaceTool.add_vertex(ptpr)
		surfaceTool.add_uv(Vector2(un, 0))
		surfaceTool.add_uv2(Vector2(un, 0))
		surfaceTool.add_vertex(ptnr)
		surfaceTool.add_uv(Vector2(un, vheight))
		surfaceTool.add_uv2(Vector2(un, vheight))
		surfaceTool.add_vertex(ptnt)

		surfaceTool.add_uv(Vector2(up, 0))
		surfaceTool.add_uv2(Vector2(up, 0))
		surfaceTool.add_vertex(ptpr)
		surfaceTool.add_uv(Vector2(un, vheight))
		surfaceTool.add_uv2(Vector2(un, vheight))
		surfaceTool.add_vertex(ptnt)
		surfaceTool.add_uv(Vector2(up, vheight))
		surfaceTool.add_uv2(Vector2(up, vheight))
		surfaceTool.add_vertex(ptpt)

		ptpr = ptnr
		ptpt = ptnt
		up = un

	surfaceTool.generate_normals()
	surfaceTool.generate_tangents()
	surfaceTool.commit(arraymesh)
	return arraymesh


	
static func oppositenode(nodename, ropeseq):
	return ropeseq[-1 if (ropeseq[0] == nodename) else 0]
static func swaparrindexes(arr, i, j):
	var b = arr[i]
	arr[i] = arr[j]
	arr[j] = b
static func cuboidfacseq(nodename, ropeseqs, ropeseqqs):
	var cseq = [ ]
	for re in ropeseqqs:
		var ropeseq = ropeseqs[re]
		if ropeseq[0] == nodename:
			cseq += ropeseq.slice(0, len(ropeseq)-2)
			nodename = ropeseq[-1]
		else:
			assert (ropeseq[-1] == nodename)
			cseq += ropeseq.slice(len(ropeseq)-1, 1, -1)
			nodename = ropeseq[0]
	return cseq

static func cuboidfromropenodesequences(nodepoints, ropeseqs): # cube shape detection
	if len(ropeseqs) != 12:
		return null
	var ropeseqends = { } 
	for j in range(len(ropeseqs)):
		var e0 = ropeseqs[j][0]
		var e1 = ropeseqs[j][-1]
		if ropeseqends.has(e0):
			ropeseqends[e0].push_back(j)
		else:
			ropeseqends[e0] = [ j ]
		if ropeseqends.has(e1):
			ropeseqends[e1].push_back(j)
		else:
			ropeseqends[e1] = [ j ]
	if len(ropeseqends) != 8:
		return null
		
	var topnode = null
	for nodename in ropeseqends.keys():
		if len(ropeseqends[nodename]) != 3:
			return null
		if topnode == null or (nodepoints[nodename].y > nodepoints[topnode].y):
			topnode = nodename

	var secondseqq = [ ]
	for j in ropeseqends[topnode]:
		var secondseqqj = [ j ]
		var jo = oppositenode(topnode, ropeseqs[j])
		secondseqqj.push_back(jo)
		for je in ropeseqends[jo]:
			var jeo = oppositenode(jo, ropeseqs[je])
			if jeo != topnode:
				secondseqqj.push_back(je)
				secondseqqj.push_back(jeo)
		assert (len(secondseqqj) == 6)
		secondseqq.push_back(secondseqqj)
		
	if secondseqq[1][5] == secondseqq[0][3] or secondseqq[1][5] == secondseqq[0][5]:
		swaparrindexes(secondseqq[1], 2, 4)
		swaparrindexes(secondseqq[1], 3, 5)
	if secondseqq[0][3] == secondseqq[1][3]:
		swaparrindexes(secondseqq[0], 2, 4)
		swaparrindexes(secondseqq[0], 3, 5)
	if secondseqq[1][5] == secondseqq[2][5]:
		swaparrindexes(secondseqq[2], 2, 4)
		swaparrindexes(secondseqq[2], 3, 5)
	for k in range(3):
		var sn = secondseqq[k][5]
		if sn != secondseqq[(k+1)%3][3]:
			return null
		var sne = secondseqq[k][4]
		var sne1 = secondseqq[(k+1)%3][2]
		for je in range(3):
			if ropeseqends[sn][je] != sne and ropeseqends[sn][je] != sne1:
				secondseqq[k].push_back(ropeseqends[sn][je])
				secondseqq[k].push_back(oppositenode(sn, ropeseqs[ropeseqends[sn][je]]))
		assert (len(secondseqq[k]) == 8)
		assert (k == 0 or secondseqq[k][-1] == secondseqq[k-1][-1])

	var cuboidfacs = [ ]
	for k in range(3):
		cuboidfacs.push_back(cuboidfacseq(topnode, ropeseqs, [secondseqq[k][0], secondseqq[k][4], secondseqq[(k+1)%3][2], secondseqq[(k+1)%3][0]]))
		cuboidfacs.push_back(cuboidfacseq(secondseqq[k][1], ropeseqs, [secondseqq[k][2], secondseqq[(k+2)%3][6], secondseqq[k][6], secondseqq[k][4]]))
	return cuboidfacs
	
static func triangledistortionmeasure(p0, p1, p2, f0, f1, f2):
	var parea = 0.5*(p1 - p0).cross(p2 - p0).length()
	var farea = 0.5*(f1 - f0).cross(f2 - f0)
	var areachange = farea/parea
	var u = clamp((areachange - 0.5), 0.001, 0.999)
	#print(u, " ", parea, " ", farea)
	return Vector2(u, 0.001)

static func makecuboidshellmesh(nodepoints, cuboidfacs):
	var arraymesh = ArrayMesh.new()
	var surfaceTool = SurfaceTool.new()
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cuboidfac in cuboidfacs:
		var ppoly = [ ]
		for c in cuboidfac:
			ppoly.push_back(nodepoints[c])
		var polynormsum = Vector3(0, 0, 0)
		for i in range(len(ppoly)):
			polynormsum += (ppoly[i] - ppoly[i-1]).cross(ppoly[(i+1)%len(ppoly)] - ppoly[i])
		var polynorm = polynormsum.normalized()
		var polyax0 = polynormsum.cross(ppoly[1] - ppoly[0]).normalized()
		var polyax1 = polynorm.cross(polyax0)
		
		var pv = PoolVector2Array()
		pv.resize(len(ppoly))
		for i in range(len(ppoly)):
			var p = ppoly[i] - ppoly[0]
			pv[i] = Vector2(p.dot(polyax0), p.dot(polyax1))
		var pi = Geometry.triangulate_polygon(pv)
		for u in pi:
			surfaceTool.add_uv(pv[u])
			surfaceTool.add_uv2(pv[u])
			surfaceTool.add_vertex(ppoly[u])
			
	surfaceTool.generate_normals()
	surfaceTool.commit(arraymesh)
	return arraymesh

static func pickpolysindex(polys, xcdrawinglink, js):
	var pickpolyindex = -1
	for i in range(len(polys)):
		var meetsallnodes = true
		var j = js
		while j < len(xcdrawinglink):
			var meetnodename = xcdrawinglink[j]
			if not polys[i].has(meetnodename):
				meetsallnodes = false
				break
			j += 2
		if meetsallnodes:
			pickpolyindex = i
			break
	if len(polys) == 1 and pickpolyindex == 0:
		var meetnodenames = xcdrawinglink.slice(js, len(xcdrawinglink), 2)
		if (not meetnodenames.has(polys[0][0])) or (not meetnodenames.has(polys[0][-1])):
			pickpolyindex = -1
			
	return pickpolyindex
