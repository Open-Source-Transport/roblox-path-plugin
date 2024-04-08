-- Credit to Stravant for ResizeAlign
--[[
Copyright 2023 Mark Langen (@stravant)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local ResizeAlign = {}
ResizeAlign.Mode = "OuterTouch"

local function otherNormals(dir)
	if math.abs(dir.X) > 0 then
		return Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)
	elseif math.abs(dir.Y) > 0 then
		return Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	else
		return Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)
	end
end

local function getFacePoints(face)
	local hsize = face.Object.Size / 2
	local faceDir = Vector3.FromNormalId(face.Normal)
	local faceA, faceB = otherNormals(faceDir)
	faceDir, faceA, faceB = faceDir*hsize, faceA*hsize, faceB*hsize
	--
	local function sp(offset)
		return (face.Object.CFrame * CFrame.new(offset)).p
	end
	--
	return {
		sp(faceDir + faceA + faceB);
		sp(faceDir + faceA - faceB);
		sp(faceDir - faceA - faceB);
		sp(faceDir - faceA + faceB);
	}
end

local function getPoints(part)
	local hsize = part.Size / 2
	local cf = part.CFrame
	local points = {}
	for i = -1, 1, 2 do
		for j = -1, 1, 2 do
			for k = -1, 1, 2 do
				table.insert(points, cf:pointToWorldSpace(Vector3.new(i, j, k) * hsize))
			end
		end
	end
	return points
end

local function getNormal(face)
	return face.Object.CFrame:vectorToWorldSpace(Vector3.FromNormalId(face.Normal))
end

local function getDimension(face)
	local dir = Vector3.FromNormalId(face.Normal)
	return Vector3.new(math.abs(dir.X), math.abs(dir.Y), math.abs(dir.Z))
end

function cl0(n)
	return (n > 0) and n or 0
end
function RealDistanceFrom(point, part)
	local p = part.CFrame:pointToObjectSpace(part.Position)
	local hz = part.Size/2
	local sep = Vector3.new(cl0(math.abs(p.x)-hz.x), cl0(math.abs(p.y)-hz.y), cl0(math.abs(p.z)-hz.z))
	return sep.magnitude
end

function getClosestPointTo(part, points)
	local closestDistance = math.huge
	local closestPoint = nil
	for _, point in pairs(points) do
		local dist = RealDistanceFrom(point, part)
		if dist < closestDistance then
			closestDistance = dist
			closestPoint = point
		end
	end
	return closestPoint
end

function getFurthestPointTo(part, points)
	local furthestDistance = -math.huge
	local furthestPoint = nil
	for _, point in pairs(points) do
		local dist = RealDistanceFrom(point, part)
		if dist > furthestDistance then
			furthestDistance = dist
			furthestPoint = point
		end
	end
	return furthestPoint
end

-- Get the point in the list most "out" of the face
function getPositivePointToFace(face, points)
	local hsize = face.Object.Size / 2
	local faceDir = Vector3.FromNormalId(face.Normal)
	local faceNormal = face.Object.CFrame:vectorToWorldSpace(faceDir)
	local facePoint = face.Object.CFrame:pointToWorldSpace(faceDir * hsize)
	--
	local maxDist = -math.huge
	local maxPoint = nil
	for _, point in pairs(points) do
		local dist = (point - facePoint):Dot(faceNormal)
		if dist > maxDist then
			maxDist = dist
			maxPoint = point
		end
	end
	return maxPoint
end

function getNegativePointToFace(face, points)
	local hsize = face.Object.Size / 2
	local faceDir = Vector3.FromNormalId(face.Normal)
	local faceNormal = face.Object.CFrame:vectorToWorldSpace(faceDir)
	local facePoint = face.Object.CFrame:pointToWorldSpace(faceDir * hsize)
	--
	local minDist = math.huge
	local minPoint = nil
	for _, point in pairs(points) do
		local dist = (point - facePoint):Dot(faceNormal)
		if dist < minDist then
			minDist = dist
			minPoint = point
		end
	end
	return minPoint
end

function resizePart(part, normal, delta)
	local axis = Vector3.FromNormalId(normal)
	local cf = part.CFrame
	local targetSize = part.Size + Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z))*delta
	
	part:BreakJoints()
	part.Size = targetSize
	part:BreakJoints()
	part.CFrame = cf * CFrame.new(axis * (delta/2))
end

function ResizeAlign.DoExtend(faceA, faceB)
	--
	local pointsA = getFacePoints(faceA)
	local pointsB = getFacePoints(faceB)
	--
	local extendPointA, extendPointB;
	if ResizeAlign.Mode == 'ExtendInto' or ResizeAlign.Mode == 'OuterTouch' or ResizeAlign.Mode == 'ButtJoint' then
		extendPointA = getPositivePointToFace(faceB, pointsA)
		extendPointB = getPositivePointToFace(faceA, pointsB)
	elseif ResizeAlign.Mode == 'ExtendUpto' or ResizeAlign.Mode == 'InnerTouch' then
		extendPointA = getNegativePointToFace(faceB, pointsA)
		extendPointB = getNegativePointToFace(faceA, pointsB)
	elseif ResizeAlign.Mode == 'HalfTouch' then
		extendPointA = (getPositivePointToFace(faceB, pointsA) + getNegativePointToFace(faceB, pointsA))/2
		extendPointB = (getPositivePointToFace(faceA, pointsB) + getNegativePointToFace(faceA, pointsB))/2
	else
		assert(false, "unreachable")		
	end
	local startSep = extendPointB - extendPointA
	--
	local localDimensionA = getDimension(faceA)
	local localDimensionB = getDimension(faceB)
	local dirA = getNormal(faceA)
	local dirB = getNormal(faceB)
	--
	-- Find the closest distance between the rays (extendPointA, dirA) and (extendPointB, dirB):
	-- See: http://geomalgorithms.com/a07-_distance.html#dist3D_Segment_to_Segment
	local a, b, c, d, e = dirA:Dot(dirA), dirA:Dot(dirB), dirB:Dot(dirB), dirA:Dot(startSep), dirB:Dot(startSep)
	local denom = a*c - b*b

	-- Is this a degenerate case?
	if math.abs(denom) < 0.001 then
		-- Parts are parallel, extend faceA to faceB
		local lenA = (extendPointA - extendPointB):Dot(getNormal(faceB))
		local extendableA = (localDimensionA * faceA.Object.Size).magnitude
		if getNormal(faceA):Dot(getNormal(faceB)) > 0 then
			lenA = -lenA
		end
		if lenA < -extendableA then
			return
		end
		resizePart(faceA.Object, faceA.Normal, lenA)
		return
	end

	-- Get the distances to extend by
	local lenA = -(b*e - c*d) / denom
	local lenB = -(a*e - b*d) / denom

	if ResizeAlign.Mode == 'ExtendInto' or ResizeAlign.Mode == 'ExtendUpto' then
		-- We need to find a different lenA, which is the intersection of
		-- extendPointA to the plane faceB:
		-- dist to plane (point, normal) = - (ray_dir . normal) / ((ray_origin - point) . normal)
		local denom2 = dirA:Dot(dirB)
		if math.abs(denom2) > 0.0001 then
			lenA = - (extendPointA - extendPointB):Dot(dirB) / denom2
			lenB = 0
		else
			-- Perpendicular
			-- Project all points of faceB onto faceA and extend by that much
			local points = getPoints(faceB.Object)
			if ResizeAlign.Mode == 'ExtendUpto' then
				local smallestLen = math.huge
				for _, v in pairs(points) do
					local dist = (v - extendPointA):Dot(getNormal(faceA))
					if dist < smallestLen then
						smallestLen = dist
					end
				end
				lenA = smallestLen
			elseif ResizeAlign.Mode == 'ExtendInto' then
				local largestLen = -math.huge
				for _, v in pairs(points) do
					local dist = (v - extendPointA):Dot(getNormal(faceA))
					if dist > largestLen then
						largestLen = dist
					end
				end
				lenA = largestLen
			end
			lenB = 0
		end
	end

	-- Are both extents doable?
	-- Note: Negative amounts to extend by *are* allowed, but only
	-- up to the size of the part on the dimension being extended on.
	local extendableA = (localDimensionA * faceA.Object.Size).magnitude
	local extendableB = (localDimensionB * faceB.Object.Size).magnitude
	if lenA < -extendableA then
		return
	end
	if lenB < -extendableB then
		return
	end

	-- Both are doable, execute:
	resizePart(faceA.Object, faceA.Normal, lenA)
	resizePart(faceB.Object, faceB.Normal, lenB)

	-- For a butt joint, we want to resize back one of the parts by the thickness 
	-- of the other part on that axis. Renize the first part (A), such that it
	-- "butts up against" the second part (B).
	if ResizeAlign.Mode == 'ButtJoint' then
		-- Find the width of B on the axis A, which is the amount to resize by
		local points = getPoints(faceB.Object)
		local minV =  math.huge
		local maxV = -math.huge
		for _, v in pairs(points) do
			local proj = (v - extendPointA):Dot(dirA)
			if proj < minV then minV = proj end
			if proj > maxV then maxV = proj end
		end
		resizePart(faceA.Object, faceA.Normal, -(maxV - minV))
	end
end

local mState = "FaceA"
function GetTarget(part, ray)
	local ignorelist = {}
	local hit, at
	repeat
		hit, at = workspace:FindPartOnRayWithIgnoreList(ray, ignorelist)
		if hit then
			if hit.Name ~= part.Name or hit.Parent.Parent ~= part.Parent.Parent then
				table.insert(ignorelist, hit)
			end
		else
			break
		end
	until hit.Name == part.Name
	local targetSurface;
	if hit then
		local localDisp = hit.CFrame:vectorToObjectSpace(at - hit.Position)
		local halfSize = hit.Size / 2
		local smallest = math.huge
		if math.abs(localDisp.x - halfSize.x) < smallest then
			targetSurface = Enum.NormalId.Right
			smallest = math.abs(localDisp.x - halfSize.x)
		end
		if math.abs(localDisp.x + halfSize.x) < smallest then
			targetSurface = Enum.NormalId.Left
			smallest = math.abs(localDisp.x + halfSize.x)
		end
		if math.abs(localDisp.y - halfSize.y) < smallest then
			targetSurface = Enum.NormalId.Top
			smallest = math.abs(localDisp.y - halfSize.y)
		end
		if math.abs(localDisp.y + halfSize.y) < smallest then
			targetSurface = Enum.NormalId.Bottom
			smallest = math.abs(localDisp.y + halfSize.y)
		end
		if math.abs(localDisp.z - halfSize.z) < smallest then
			targetSurface = Enum.NormalId.Back
			smallest = math.abs(localDisp.z - halfSize.z)
		end
		if math.abs(localDisp.z + halfSize.z) < smallest then
			targetSurface = Enum.NormalId.Front
			smallest = math.abs(localDisp.z + halfSize.z)
		end
	end
	return hit, targetSurface
end

return ResizeAlign
