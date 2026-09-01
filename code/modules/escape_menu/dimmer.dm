/atom/movable/screen/fullscreen/dimmer
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "black"
	alpha = 200
	plane = ESCAPE_MENU_PLANE
	layer = ESCAPE_MENU_DIMMER_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	clear_with_screen = FALSE
	/// У диммера hud = null, так что базовый screen/Destroy не умеет снять его с
	/// экрана - уборка целиком зависела от живости holder.client в момент qdel.
	/// Держим владельца сами, чтобы qdel при любом порядке разбора не оставлял
	/// объект в client.screen (харддел-шторм диммеров с прода)
	var/client/owner_client

/atom/movable/screen/fullscreen/dimmer/Destroy()
	owner_client?.screen -= src
	owner_client = null
	return ..()


/atom/movable/screen/fullscreen/dimmer/right
	screen_loc = "hud:LEFT,TOP to LEFT,TOP-15"

/atom/movable/screen/fullscreen/dimmer/bottom
	screen_loc = "bottom:LEFT,TOP to LEFT+18,TOP"
