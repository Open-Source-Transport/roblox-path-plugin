-- Written by Sublivion
-- 25/7/19

-- A class for creating paths, which are the 'physical' extensions of a Curve
-- Currently, a Path is composed of a Curve

--[[ Docs
	
	Constructors
	
		Path.new()
		
	Methods
	
		Path:draw()
		
	Properties (all must be set before draw is called)
		
		Path.segment = BasePart or Model
		Path.controlPoints = {...}
		Path.length = number length
		Path.controlPoints = table of parts

	Note - this is ugly and I should add setters and getters!
--]]

-- Modules
local modules = script.Parent
local Curve = require(modules.Curve)
local ResizeAlign = require(modules.ResizeAlign)

-- Functions

-- Moves a model to a CFrame
local function moveModel(model, cframe)
	local center = model:GetBoundingBox()
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local offset = center:toObjectSpace(part.CFrame)
			local newCFrame = cframe:toWorldSpace(offset)
			part.CFrame = newCFrame
		end
	end
end

-- Returns all the parts within a container
local function getParts(container)
	local parts = {}
	for i, v in pairs(container:GetDescendants()) do
		if v:IsA("BasePart") then
			table.insert(parts, v)
		end
	end
	return parts
end

-- Make a clone and return matching parts
local function makeClone(template)
	-- Clone descendants
	local model = Instance.new("Model")
	model.Name = template.Name
	local copies = {}
	for i, v in pairs(template:GetChildren()) do
		if v:IsA("BasePart") then
			copies[v] = v:Clone()
			copies[v].Parent = model
		else
			local clone = v:Clone()
			if #v:GetChildren() > 0 then
				clone:ClearAllChildren()
				local container, cCopies = makeClone(v)
				for i, v in pairs(cCopies) do
					copies[i] = v
					v.Parent = clone
				end
				container:Destroy()
			end
			clone.Parent = model
		end
	end
	return model, copies
end

-- Class Path
local Path = {}
Path.__index = Path

-- .new Constructor
function Path.new()
	local self = setmetatable({}, Path)
	local curve = Curve.new()

	-- :draw - draws the path in a modeland returns the model
	function Path:draw(cf0, cf1, fillGaps)
		-- Check if path is valid, if not pass error message
		if not self.template or not self.length or not self.canting then
			return nil
		end
		self.canting = tonumber(self.canting)
		self.length = tonumber(self.length)
		self.primaryAxis = self.primaryAxis or "Z"

		-- Create path model
		local path = Instance.new("Folder")
		path.Name = "Path"
		path.Parent = self.template.Parent.Parent:IsDescendantOf(workspace) and self.template.Parent.Parent or workspace

		-- Convert two CFrames into 4 positions
		local cf2 = cf1
		cf1 = cf1 * CFrame.new(0, 0, self.length)
		local dist = (cf1.p - cf0.p).Magnitude
		local cosa = math.cos(math.acos(cf0.LookVector:Dot(cf1.LookVector)) / 2)
		if math.abs((cf0.LookVector - cf1.LookVector).Magnitude) < 0.05 then
			cosa = 1
		end
		local d = dist / (2 * cosa + 1)
		curve:setControlPoints({ cf0.p, cf0.p + cf0.LookVector * d, cf1.p - cf1.LookVector * d, cf1.p })
		local points: {Vector3}
		local relOffset = cf0:PointToObjectSpace(cf2.Position)
		if self.optimiseStraights and (cosa == 1) and (math.abs(relOffset.X) < 0.1) and (math.abs(relOffset.Y) < 0.1) then
			points = {cf0.p, cf2.p}
		else
			points = curve:getPointsFromSegmentLength(self.length)
			table.insert(points, cf2.p)
		end

		-- Create segments
		local lastSegment
		local minRadius
		local maxIterations = #points - 1
		local copiesTable = {}

		local rotOffset = 0
		if self.primaryAxis == "X" then
			rotOffset = (if self.swapEnd then -math.pi else math.pi) / 2
		end

		local normalA = if self.primaryAxis == "Z" then Enum.NormalId.Front elseif self.swapEnd then Enum.NormalId.Left else Enum.NormalId.Right
		local normalB = if self.primaryAxis == "Z" then Enum.NormalId.Back elseif self.swapEnd then Enum.NormalId.Right else Enum.NormalId.Left

		for i = 1, maxIterations do
			-- Create segment
			local segment, copies
			local template = lastSegment or self.template
			if template then
				if template:IsA("Model") then
					segment, copies = makeClone(template)
					table.insert(copiesTable, copies)
				else
					segment = template:Clone()
				end
			end
			segment.Parent = path

			-- Calculate length
			local P0, P1 = points[i], points[i + 1]
			local length = (P0 - P1).Magnitude

			-- Scale parts and models separately
			if segment:IsA("BasePart") then
				if self.primaryAxis == "Z" then
					segment.Size = Vector3.new(segment.Size.X, segment.Size.Y, length)
				else
					segment.Size = Vector3.new(length, segment.Size.Y, segment.Size.Z)
				end
				segment.CFrame = CFrame.new(P0, P1) * CFrame.new(0, 0, -length / 2) * CFrame.Angles(0, rotOffset, 0)
				local _, angle = template.CFrame:ToObjectSpace(segment.CFrame):ToOrientation()
				if angle ~= 0 and length ~= 0 then
					local radius = math.abs(2 * math.pi / angle * length)
					if not minRadius then
						minRadius = radius
					end
					minRadius = radius < minRadius and radius or minRadius
				end
			elseif segment:IsA("Model") then
				-- Move the model to the correct CFrame
				moveModel(segment, CFrame.new(P0, P1) * CFrame.new(0, 0, -length / 2) * CFrame.Angles(0, rotOffset, 0))

				-- Set length of segments
				for i, v in pairs(copies) do
					if self.primaryAxis == "Z" then
						v.Size = Vector3.new(v.Size.X, v.Size.Y, length)
					else
						v.Size = Vector3.new(length, v.Size.Y, v.Size.Z)
					end
				end

				local cf, length = segment:GetBoundingBox()
				length = length[self.primaryAxis]

				-- Calculate minimum radius
				do
					local cf0 = template:GetBoundingBox()
					local _, angle = cf0:ToObjectSpace(cf):ToOrientation()
					if angle ~= 0 and length ~= 0 then
						local radius = math.abs(2 * math.pi / angle * length)
						if not minRadius then
							minRadius = radius
						end
						minRadius = radius < minRadius and radius or minRadius
					end
				end

				-- Align all parts in the last segment
				if i == maxIterations and fillGaps then
					local point = workspace.CurrentCamera:FindFirstChild("ControlPoint")
					point.CFrame = point.CFrame * CFrame.new(0, 0, 0.5 * point.Size.Z)
					point = point:Clone()
					for i, v in pairs(segment:GetDescendants()) do
						if v:IsA("BasePart") then
							ResizeAlign.DoExtend(
								{ Object = v, Normal = normalA },
								{ Object = point, Normal = Enum.NormalId.Front }
							)
						end
					end
				end
			end

			-- Prepare for next segment
			lastSegment = segment
		end

		local segments = path:GetChildren()

		-- Apply canting
		if minRadius and self.canting ~= 0 then
			for i, v in ipairs(segments) do
				local radius
				local length
				local cf0
				local template = i > 1 and segments[i - 1] or self.template
				if v:IsA("BasePart") then
					length = v.Size[self.primaryAxis]
				else
					cf0, length = v:GetBoundingBox()
					length = length[self.primaryAxis]
				end
				local _, angle
				if length then
					if v:IsA("BasePart") then
						_, angle = template.CFrame:ToObjectSpace(v.CFrame):ToOrientation()
					elseif v:IsA("Model") then
						local cf = template:GetBoundingBox()
						_, angle = cf:ToObjectSpace(cf0):ToOrientation()
					end
					if angle ~= 0 and length ~= 0 then
						radius = 2 * math.pi / angle * length
					end
					if radius then
						local bankAngle = math.rad(self.canting * minRadius / radius)
						--[[if v:IsA("BasePart") then
							v.Orientation = Vector3.new(v.Orientation.X, v.Orientation.Y, bankAngle)
						elseif v:IsA("Model") then
							moveModel(v, cf0 * CFrame.Angles(0, 0, math.rad(bankAngle)))
						end]]
						local xAngle = self.primaryAxis == "X" and bankAngle or 0
						local zAngle = self.primaryAxis == "Z" and bankAngle or 0
						v:PivotTo(v:GetPivot() * CFrame.Angles(xAngle, 0, zAngle))
					end
				end
			end
		end

		-- Fill gaps
		if fillGaps then
			for copyIndex, v in pairs(copiesTable) do
				for i, v in pairs(v) do
					if fillGaps then
						ResizeAlign.DoExtend(
							{ Object = i, Normal = normalA },
							{ Object = v, Normal = normalB }
						)
					end
				end
			end
			for i, segment in pairs(path:GetChildren()) do
				local template = i > 1 and segments[i - 1] or self.template
				if segment:IsA("BasePart") then
					ResizeAlign.DoExtend(
						{ Object = template, Normal = normalA },
						{ Object = segment, Normal = normalB }
					)
				end
			end
		end

		return path
	end

	return self
end

return Path
