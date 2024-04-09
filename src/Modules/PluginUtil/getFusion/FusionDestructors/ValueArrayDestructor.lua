return function(v0, m)
	if typeof(v0) == "table" then
		for _, v in ipairs(v0) do
			if typeof(v) == "Instance" then
				v:Destroy()
			end
		end
	end
end
