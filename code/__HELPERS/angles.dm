/// Returns a finite angle in degrees. matrix.Turn() and trig on NaN/inf can hard-crash BYOND.
/proc/sanitize_angle(angle, fallback = 0)
	if(!isfinite(angle))
		return SIMPLIFY_DEGREES(fallback)
	return SIMPLIFY_DEGREES(angle)

/proc/get_projectile_angle(atom/source, atom/target)
	if(!source || !target)
		return 0
	var/sx = source.x * world.icon_size
	var/sy = source.y * world.icon_size
	var/tx = target.x * world.icon_size
	var/ty = target.y * world.icon_size
	var/atom/movable/AM
	if(ismovable(source))
		AM = source
		sx += AM.step_x
		sy += AM.step_y
	if(ismovable(target))
		AM = target
		tx += AM.step_x
		ty += AM.step_y
	var/dx = tx - sx
	var/dy = ty - sy
	if(!dx && !dy)
		return 0
	return sanitize_angle(arctan(dy, dx))

/proc/Get_Angle(atom/movable/start,atom/movable/end)//For beams.
	if(!start || !end)
		return FALSE
	var/dy
	var/dx
	dy=(32*end.y+end.pixel_y)-(32*start.y+start.pixel_y)
	dx=(32*end.x+end.pixel_x)-(32*start.x+start.pixel_x)
	if(!dy)
		return (dx>=0)?90:270
	.=arctan(dx/dy)
	if(dy<0)
		.+=180
	else if(dx<0)
		.+=360

/proc/Get_Pixel_Angle(var/y, var/x)//for getting the angle when animating something's pixel_x and pixel_y
	if(!y)
		return (x>=0)?90:270
	.=arctan(x/y)
	if(y<0)
		.+=180
	else if(x<0)
		.+=360
