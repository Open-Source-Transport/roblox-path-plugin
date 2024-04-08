-- Cunic bezier curve module
-- Written by Sublivion
-- 25/7/19

-- Constants
local LENGTH_STEP = 0.1

-- Class Curve
local Curve = {}
Curve.__index = Curve

-- .new Constructor
function Curve.new()
	local self = setmetatable({}, Curve)
	local p0
	local p1
	local p2
	local p3
	local length = 0

	function Curve:setControlPoints(cp)
		p0 = cp[1]
		p1 = cp[2]
		p2 = cp[3]
		p3 = cp[4]
		length = self:getLength()
	end

	function Curve:getPoint(r)
		return (1 - r) * (1 - r) * (1 - r) * p0
			+ 3 * (1 - r) * (1 - r) * r * p1
			+ 3 * (1 - r) * r * r * p2
			+ r * r * r * p3
	end

	function Curve:getPoints(increment)
		local points = {}
		local lastI = 0
		for i = 0, 1, increment do
			lastI = i
			points[#points + 1] = self:getPoint(i)
		end
		-- Override last point if whole curve not covered by increment
		if lastI < 1 then
			local overrideLast = ((1 - lastI) < (increment * 0.5))
			points[#points + (overrideLast and 0 or 1)] = self:getPoint(1)
		end
		return points
	end

	function Curve:getPointsFromSegmentCount(segments)
		return self:getPoints(1 / segments)
	end

	function Curve:getPointsFromSegmentLength(segmentLength)
		return self:getPointsFromSegmentCount(math.floor(length / segmentLength + 0.5))
	end

	function Curve:getLength()
		local points = self:getPoints(LENGTH_STEP)
		local l = 0
		for i = 2, #points do
			local dist = (points[i - 1] - points[i]).Magnitude
			l = (l + dist)
		end
		return l
	end

	return self
end

return Curve
