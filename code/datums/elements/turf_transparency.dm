/// Делает турф дыркой в полу: показывает через vis_contents турф уровнем ниже и переживает появление и выгрузку нижнего уровня.
/datum/element/turf_z_transparency
	//ELEMENT_DETACH обязателен: дыру закрывают через ChangeTurf с qdel старого турфа, иначе заказ на окрестность виснет навсегда.
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH
	id_arg_index = 2
	/// Рисовать ли базовый турф z-уровня подложкой, когда снизу вообще нет уровня.
	var/show_bottom_level = FALSE
	/// Дыра -> турф под ней, на окрестность которого сейчас взят заказ.
	var/list/shown_neighbourhood = list()
	/// Дыра -> подложка базового турфа, пока снизу нечего показывать.
	var/list/bottom_underlays = list()

///This proc sets up the signals to handle updating viscontents when turfs above/below update. Handle plane and layer here too so that they don't cover other obs/turfs in Dream Maker
/datum/element/turf_z_transparency/Attach(datum/target, show_bottom_level = TRUE)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE

	var/turf/our_turf = target

	src.show_bottom_level = show_bottom_level

	SET_PLANE_IMPLICIT(our_turf, OPENSPACE_PLANE)
	our_turf.layer = OPENSPACE_LAYER

	RegisterSignal(target, COMSIG_TURF_MULTIZ_DEL, PROC_REF(on_multiz_turf_del))
	RegisterSignal(target, COMSIG_TURF_MULTIZ_NEW, PROC_REF(on_multiz_turf_new))

	ADD_TRAIT(our_turf, TURF_Z_TRANSPARENT_TRAIT, TURF_TRAIT)

	add_static_underlays(our_turf)
	update_multiz(our_turf, TRUE)

/datum/element/turf_z_transparency/Detach(datum/source, force)
	. = ..()
	var/turf/our_turf = source
	UnregisterSignal(our_turf, list(COMSIG_TURF_MULTIZ_DEL, COMSIG_TURF_MULTIZ_NEW))
	clear_shown_turfs(our_turf)
	hide_neighbours_below(our_turf, shown_neighbourhood[our_turf])
	shown_neighbourhood -= our_turf
	hide_bottom_level(our_turf)
	REMOVE_TRAIT(our_turf, TURF_Z_TRANSPARENT_TRAIT, TURF_TRAIT)
	//ChangeTurf зовёт Detach из qdel старого турфа, новый встанет в ту же клетку следующим шагом - отсюда таймер.
	if(GET_TURF_BELOW(our_turf))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(restore_z_pillars_over), our_turf), 0)

/// Убирает из vis_contents только показанные снизу турфы: там же живёт lighting_object, и очистка списка целиком выбила бы свет.
/datum/element/turf_z_transparency/proc/clear_shown_turfs(turf/our_turf)
	var/list/shown
	for(var/atom/thing as anything in our_turf.vis_contents)
		if(isturf(thing))
			LAZYADD(shown, thing)
	if(shown)
		our_turf.vis_contents -= shown

/datum/element/turf_z_transparency/proc/show_turf_below(turf/our_turf, turf/below_turf)
	if(below_turf in our_turf.vis_contents)
		return
	clear_shown_turfs(our_turf)
	our_turf.vis_contents += below_turf
	//Соседняя дыра могла заказать этот же турф держателем на нас: показанный дважды, он перемножает свет снизу сам на себя.
	var/obj/effect/abstract/z_holder/holder = GLOB.z_pillar_holders[below_turf]
	if(holder)
		qdel(holder)

/// Заказывает окрестность 3x3 под дырой: каждому соседу нужен свой держатель над ним, иначе все девять слипнутся в тайл дыры.
/datum/element/turf_z_transparency/proc/show_neighbours_below(turf/our_turf, turf/below_turf)
	for(var/turf/partner as anything in RANGE_TURFS(1, below_turf))
		if(partner == below_turf)
			continue
		var/turf/host = GET_TURF_ABOVE(partner)
		//Не трейт, а shows_level_below(): на уровне с прозрачным космосом сосед получит трейт позже, а держатель на нём останется навсегда.
		if(!host || host.shows_level_below())
			continue
		request_z_pillar(partner, our_turf, host)

/datum/element/turf_z_transparency/proc/hide_neighbours_below(turf/our_turf, turf/below_turf)
	if(!below_turf)
		return
	for(var/turf/partner as anything in RANGE_TURFS(1, below_turf))
		if(partner == below_turf)
			continue
		release_z_pillar(partner, our_turf)

/// Подложки, не зависящие от того, что творится с уровнем снизу: кладутся один раз на Attach.
/datum/element/turf_z_transparency/proc/add_static_underlays(turf/our_turf)
	if(!isclosedturf(our_turf)) //Show girders below closed turfs
		return
	var/mutable_appearance/girder_underlay = mutable_appearance('icons/obj/structures.dmi', "girder", layer = TURF_LAYER-0.01)
	girder_underlay.appearance_flags = RESET_ALPHA | RESET_COLOR
	our_turf.underlays += girder_underlay
	var/mutable_appearance/plating_underlay = mutable_appearance('icons/turf/floors.dmi', "plating", layer = TURF_LAYER-0.02)
	plating_underlay.appearance_flags = RESET_ALPHA | RESET_COLOR
	our_turf.underlays += plating_underlay

///Updates the viscontents or underlays below this tile.
/datum/element/turf_z_transparency/proc/update_multiz(turf/our_turf, init = FALSE)
	var/turf/below_turf = GET_TURF_BELOW(our_turf)
	if(!below_turf)
		clear_shown_turfs(our_turf)
		hide_neighbours_below(our_turf, shown_neighbourhood[our_turf])
		shown_neighbourhood -= our_turf
		if(show_bottom_level(our_turf))
			return TRUE
		if(!init)
			return FALSE
		our_turf.ChangeTurf(isspaceturf(our_turf) ? /turf/open/space : /turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
		return FALSE
	//Подложка обязана уйти первой: она непрозрачна и закрыла бы собой взятый в vis_contents этаж.
	hide_bottom_level(our_turf)
	show_turf_below(our_turf, below_turf)
	var/turf/previous_centre = shown_neighbourhood[our_turf]
	if(previous_centre == below_turf)
		return TRUE
	hide_neighbours_below(our_turf, previous_centre)
	shown_neighbourhood[our_turf] = below_turf
	show_neighbours_below(our_turf, below_turf)
	return TRUE

/datum/element/turf_z_transparency/proc/on_multiz_turf_del(turf/our_turf, turf/T, dir)
	SIGNAL_HANDLER
	if(dir != DOWN)
		return
	update_multiz(our_turf)

/datum/element/turf_z_transparency/proc/on_multiz_turf_new(turf/our_turf, turf/T, dir)
	SIGNAL_HANDLER
	if(dir != DOWN)
		return
	update_multiz(our_turf)

///Called when there is no real turf below this turf
/datum/element/turf_z_transparency/proc/show_bottom_level(turf/our_turf)
	if(!show_bottom_level)
		return FALSE
	//Второй раз класть нельзя: underlays росли бы на каждое появление и выгрузку уровня снизу.
	if(bottom_underlays[our_turf])
		return TRUE
	var/turf/path = SSmapping.level_trait(our_turf.z, ZTRAIT_BASETURF) || /turf/open/space
	if(!ispath(path))
		path = text2path(path)
		if(!ispath(path))
			warning("Z-level [our_turf.z] has invalid baseturf '[SSmapping.level_trait(our_turf.z, ZTRAIT_BASETURF)]'")
			path = /turf/open/space
	var/mutable_appearance/underlay_appearance = mutable_appearance(initial(path.icon), initial(path.icon_state), layer = TURF_LAYER-0.02, plane = PLANE_SPACE)
	SET_PLANE_EXPLICIT(underlay_appearance, PLANE_SPACE, our_turf)
	underlay_appearance.appearance_flags = RESET_ALPHA | RESET_COLOR
	our_turf.underlays += underlay_appearance
	bottom_underlays[our_turf] = underlay_appearance
	return TRUE

/datum/element/turf_z_transparency/proc/hide_bottom_level(turf/our_turf)
	var/mutable_appearance/standing = bottom_underlays[our_turf]
	if(!standing)
		return FALSE
	our_turf.underlays -= standing
	bottom_underlays -= our_turf
	return TRUE
