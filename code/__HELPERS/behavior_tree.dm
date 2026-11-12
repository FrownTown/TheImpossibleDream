/proc/get_nearby_entities(mob/living/source, range)
	var/list/entities = SSspatial_grid.living_mobs_in_square(get_turf(source), range)
	entities -= source
	return entities
/proc/__blocked(x, y, z, checkforcover = FALSE)
	var/turf/T = locate(x, y, z)
	if(!T)
		return TRUE

	if((checkforcover || T.density) && T.opacity)
		return TRUE

	for(var/atom/A in T.contents)
		if((checkforcover || A.density) && A.opacity)
			return TRUE
	return FALSE

/proc/los_blocked(atom/M, atom/N, checkforcover = FALSE)
	if(!M || !N || M.z != N.z)
		return TRUE

	var/px = M.x, py = M.y
	var/dx = N.x - px,  dy = N.y - py
	var/dxabs = abs(dx), dyabs = abs(dy)
	var/sdx = SIGN(dx), sdy = SIGN(dy)
	var/xerr = dxabs >> 1, yerr = dyabs >> 1

	// skip the starting turf (M's own tile) then begin stepping
	if(dxabs >= dyabs)
		for(var/i = dxabs; i > 0; --i)
			yerr += dyabs
			if(yerr >= dxabs)
				yerr -= dxabs
				py += sdy
			px += sdx
			if(__blocked(px, py, M.z, checkforcover))
				return TRUE
	else
		for(var/i = dyabs; i > 0; --i)
			xerr += dxabs
			if(xerr >= dyabs)
				xerr -= dyabs
				px += sdx
			py += sdy
			if(__blocked(px, py, M.z, checkforcover))
				return TRUE

	return FALSE
