return function(info)
	local old = {}
	local base = info.__base or love
	info.__base = nil
	for k,v in pairs(info) do
		old[k]  = base[k]
		base[k] = function(...)
			return v(old[k], ...)
		end
	end

	return function()
		for k,v in pairs(info) do
			base[k] = old[k]
		end
	end
end
