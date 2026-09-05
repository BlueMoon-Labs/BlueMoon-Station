// Показ соседей турфа под дырой: каждому нужен свой держатель над ним, потому что vis_contents рисуется в координатах держателя.

/// Показанный снизу турф -> объект-держатель, который его показывает.
GLOBAL_LIST_EMPTY(z_pillar_holders)
/// Показанный снизу турф -> список дыр, которые его затребовали.
GLOBAL_LIST_EMPTY(z_pillar_sources)

/// Пустой якорь на турфе над показываемым: через vis_contents самого турфа нельзя, ChangeTurf их чистит, а движимое переезд переживает.
/obj/effect/abstract/z_holder
	name = "z holder"
	anchored = TRUE
	move_resist = INFINITY
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE
	/// Турф с этажа ниже, который мы показываем.
	var/turf/shown_turf

/// Следим за показываемым турфом, а не за носителем: носитель тоже могут перестроить, и подписка умерла бы вместе с его датумом.
/obj/effect/abstract/z_holder/proc/attach_shown()
	if(!shown_turf)
		return
	if(!(shown_turf in vis_contents))
		vis_contents += shown_turf
	RegisterSignal(shown_turf, COMSIG_PARENT_QDELETING, PROC_REF(on_shown_replaced), override = TRUE)

/// qdel старого турфа вынимает его из vis_contents, новый появится в той же координате следующим шагом - отсюда таймер.
/obj/effect/abstract/z_holder/proc/on_shown_replaced(datum/source)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(attach_shown)), 0)

/obj/effect/abstract/z_holder/Destroy(force)
	if(shown_turf)
		vis_contents -= shown_turf
		if(GLOB.z_pillar_holders[shown_turf] == src)
			GLOB.z_pillar_holders -= shown_turf
		GLOB.z_pillar_sources -= shown_turf
		shown_turf = null
	return ..()

/// Показать турф снизу от имени дыры requester. Держатель ставится над to_display, у уже стоящего просто прибавляется заказчик.
/proc/request_z_pillar(turf/to_display, turf/requester, turf/host)
	if(!to_display || !requester)
		return
	var/list/sources = GLOB.z_pillar_sources[to_display]
	if(sources)
		sources |= requester
		//Держатель мог остаться без содержимого: см. on_shown_replaced.
		var/obj/effect/abstract/z_holder/existing = GLOB.z_pillar_holders[to_display]
		existing?.attach_shown()
		return
	if(!host)
		host = GET_TURF_ABOVE(to_display)
	if(!host)
		return
	var/obj/effect/abstract/z_holder/holder = new(host)
	holder.shown_turf = to_display
	holder.attach_shown()
	GLOB.z_pillar_holders[to_display] = holder
	GLOB.z_pillar_sources[to_display] = list(requester)

/// Снять заказ дыры requester. Держатель уходит вместе с последним заказчиком.
/proc/release_z_pillar(turf/to_display, turf/requester)
	var/list/sources = GLOB.z_pillar_sources[to_display]
	if(!sources)
		return
	sources -= requester
	if(length(sources))
		return
	var/obj/effect/abstract/z_holder/holder = GLOB.z_pillar_holders[to_display]
	if(holder)
		qdel(holder)
		return
	GLOB.z_pillar_holders -= to_display
	GLOB.z_pillar_sources -= to_display

/// Носитель перестал быть дырой: соседние дыры снова показывают турф под ним через держатель.
/// Пока носитель был прозрачным, их заказы уходили вместе с держателем, см. show_turf_below().
/proc/restore_z_pillars_over(turf/host, turf/below)
	if(QDELETED(host) || host.shows_level_below())
		return
	if(!below)
		below = GET_TURF_BELOW(host)
	if(!below)
		return
	for(var/turf/neighbour as anything in RANGE_TURFS(1, host))
		if(neighbour == host || !neighbour.shows_level_below())
			continue
		request_z_pillar(below, neighbour, host)
