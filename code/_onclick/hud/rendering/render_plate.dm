/// Плита - plane master, принимающий картинку других плоскостей через реле: так этаж и его свет сходятся внутри плиты.

/// Экранный объект, а не голое движимое: client.register_map_obj() читает assigned_map, которого у /atom/movable нет.
/atom/movable/screen/render_plane_relay
	screen_loc = "CENTER"
	layer = -1
	plane = 0
	vis_flags = NONE
	appearance_flags = PASS_MOUSE | NO_CLIENT_COLOR | KEEP_TOGETHER
	//Реле принадлежат мастеру, а не карте: clear_map() их удалять не должен.
	del_on_map_removal = FALSE

/atom/movable/screen/plane_master/rendering_plate
	name = "rendering plate"
	multiz_scaled = FALSE
	appearance_flags = PLANE_MASTER

/atom/movable/screen/plane_master/rendering_plate/transparent
	name = "transparent plate"
	plane = RENDER_PLANE_TRANSPARENT
	//Приехавшая снизу картинка - содержимое мира нашего этажа: вне плиты её закроет наша же темнота.
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	color = list(0.9,0,0,0, 0,0.9,0,0, 0,0,0.9,0, 0,0,0,1, 0,0,0,0)

/atom/movable/screen/plane_master/rendering_plate/game_world
	name = "game world plate"
	plane = RENDER_PLANE_GAME_WORLD
	blend_mode = BLEND_OVERLAY
	render_relay_planes = list(RENDER_PLANE_MASTER)

/atom/movable/screen/plane_master/rendering_plate/master
	name = "master plate"
	plane = RENDER_PLANE_MASTER
	render_relay_planes = list()

/atom/movable/screen/plane_master/rendering_plate/master/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	sync_to_viewer(0)

/// Плита либо рисуется игроку, либо уезжает наверх, но не одновременно. Смещение растёт вниз, поэтому этаж выше - это offset - 1.
/atom/movable/screen/plane_master/rendering_plate/master/sync_to_viewer(viewer_offset)
	. = ..()
	var/upward_plane = offset ? GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, offset - 1) : null
	if(offset == viewer_offset)
		if(upward_plane)
			remove_relay_from(upward_plane)
		add_relay_to(RENDER_PLANE_SCREEN)
		return
	remove_relay_from(RENDER_PLANE_SCREEN)
	if(upward_plane)
		add_relay_to(upward_plane)

/atom/movable/screen/plane_master/rendering_plate/screen
	name = "screen plate"
	plane = RENDER_PLANE_SCREEN
	offsetting_flags = BLOCKS_PLANE_OFFSETTING
	render_relay_planes = list()
