/datum/buildmode_mode/area_edit
	key = "areaedit"
	var/area/storedarea
	var/image/areaimage

/datum/buildmode_mode/area_edit/New()
	areaimage = image('icons/turf/areas.dmi', null, "yellow")
	//BLEND_MULTIPLY области на пустой AREA_PLANE ничего не рисует
	areaimage.blend_mode = BLEND_OVERLAY
	areaimage.plane = AREA_PLANE
	..()

/datum/buildmode_mode/area_edit/proc/highlight_stored_area(turf/floor)
	areaimage.loc = storedarea
	if(floor)
		SET_PLANE(areaimage, AREA_PLANE, floor)

/datum/buildmode_mode/area_edit/enter_mode(datum/buildmode/BM)
	BM.holder.images += areaimage

/datum/buildmode_mode/area_edit/exit_mode(datum/buildmode/BM)
	areaimage.loc = null // de-color the area
	BM.holder.images -= areaimage
	return ..()

/datum/buildmode_mode/area_edit/Destroy()
	QDEL_NULL(areaimage)
	storedarea = null
	return ..()

/datum/buildmode_mode/area_edit/show_help(client/c)
	to_chat(c, "<span class='notice'>***********************************************************</span>")
	to_chat(c, "<span class='notice'>Left Mouse Button on obj/turf/mob  = Paint area</span>")
	to_chat(c, "<span class='notice'>Right Mouse Button on obj/turf/mob = Select area to paint</span>")
	to_chat(c, "<span class='notice'>Right Mouse Button on buildmode button = Create new area</span>")
	to_chat(c, "<span class='notice'>***********************************************************</span>")

/datum/buildmode_mode/area_edit/change_settings(client/c)
	var/target_path = input(c, "Enter typepath:", "Typepath", "/area")
	var/areatype = text2path(target_path)
	if(ispath(areatype,/area))
		var/areaname = input(c, "Enter area name:", "Area name", "Area")
		if(!areaname || !length(areaname))
			return
		storedarea = new areatype
		storedarea.power_equip = 0
		storedarea.power_light = 0
		storedarea.power_environ = 0
		storedarea.always_unpowered = 0
		storedarea.name = areaname
		highlight_stored_area(get_turf(c.mob))

/datum/buildmode_mode/area_edit/handle_click(client/c, params, object)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")
	var/right_click = pa.Find("right")

	if(left_click)
		if(!storedarea)
			to_chat(c, "<span class='warning'>Configure or select the area you want to paint first!</span>")
			return
		var/turf/T = get_turf(object)
		if(istype(storedarea, /area) && islist(storedarea.contents) && get_area(T) != storedarea)
			log_admin("Build Mode: [key_name(c)] added [AREACOORD(T)] to [storedarea]")
			storedarea.contents.Add(T)
		highlight_stored_area(T)
	else if(right_click)
		var/turf/T = get_turf(object)
		storedarea = get_area(T)
		highlight_stored_area(T)
