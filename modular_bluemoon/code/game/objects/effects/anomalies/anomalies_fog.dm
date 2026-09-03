/obj/effect/particle_effect/smoke/fog
	name = "fog"
	icon = 'modular_bluemoon/code/game/objects/effects/anomalies/96x96.dmi'
	icon_state = "smoke"
	alpha = 170
	lifetime = INFINITY
	amount = INFINITY
	var/obj/effect/anomaly/fog/anomaly_parent
	COOLDOWN_DECLARE(spread_smoke_cd)

/obj/effect/particle_effect/smoke/fog/Initialize(mapload, obj/effect/anomaly/fog/fog_anomaly)
	anomaly_parent = fog_anomaly
	. = ..()
	if(!anomaly_parent)
		var/turf/t_loc = get_turf(src)
		if(!t_loc)
			return INITIALIZE_HINT_QDEL
		for(var/turf/T in t_loc.GetAtmosAdjacentTurfs())
			var/obj/effect/particle_effect/smoke/fog/foundsmoke = locate(/obj/effect/particle_effect/smoke/fog) in T
			if(foundsmoke && foundsmoke.anomaly_parent)
				anomaly_parent = foundsmoke.anomaly_parent
				break
	if(QDELETED(anomaly_parent))
		return INITIALIZE_HINT_QDEL
	QDEL_NULL(reagents) // незачем занимать память для неиспользуемых механик
	anomaly_parent.fog_to_expand += src
	RegisterSignal(anomaly_parent, COMSIG_PARENT_QDELETING, PROC_REF(clear_fog))

/obj/effect/particle_effect/smoke/fog/Destroy()
	UnregisterSignal(anomaly_parent, COMSIG_PARENT_QDELETING)
	anomaly_parent = null
	. = ..()

/obj/effect/particle_effect/smoke/fog/proc/clear_fog()
	SIGNAL_HANDLER
	QDEL_IN(src, rand(1 SECONDS, 30 SECONDS))

/obj/effect/particle_effect/smoke/fog/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		alpha = 50
		set_opacity(FALSE)
		smoke_mob(AM)

/obj/effect/particle_effect/smoke/fog/Uncrossed(atom/movable/AM)
	. = ..()
	if(isliving(AM) && !(locate(/mob/living) in loc))
		alpha = initial(alpha)
		set_opacity(TRUE)

// мы НЕ хотим нагружать подсистему obj сотнями малоинтерактивных текстурок
/obj/effect/particle_effect/smoke/fog/process()
	return PROCESS_KILL

// как у родителя, но без лишних проверок и таймеров.
/obj/effect/particle_effect/smoke/fog/smoke_mob(mob/living/L)
	if(prob(1))
		L.playsound_local(get_turf(src), pick(CREEPY_SOUNDS), 50, FALSE)

/obj/effect/particle_effect/smoke/fog/spread_smoke()
	if(!COOLDOWN_FINISHED(src, spread_smoke_cd))
		return // защита от спама когда спавнятся новые
	COOLDOWN_START(src, spread_smoke_cd, 2 SECONDS)
	if(QDELETED(anomaly_parent))
		return
	if(get_dist_euclidian(src, anomaly_parent) > 20)
		anomaly_parent.fog_to_expand -= src
		return
	if(TICK_CHECK)
		return // когда серверу плохо, мы ничего не делаем
	stoplag(1 SECONDS) // туман расползается медленно (+доп защита от перегрузок сервака)
	. = ..()

/obj/effect/anomaly/fog
	name = "fog anomaly"
	icon_state = "dimensional_overlay"
	light_range = 2
	light_color = COLOR_GRAY
	lifespan = INFINITY
	aSignal = /obj/item/assembly/signaler/anomaly/fog
	immortal = TRUE
	immobile = TRUE
	layer = FLY_LAYER + 0.1
	/**
	 * spread_smoke при спавне новых дымов проходит единожды. Если потом появились новые пути для дыма, то они будут игнорироваться.
	 * Поэтому прохождение повторных проверок необходимо.
	 * Каждый эффект дымки может обрабатываться в SSobj, но было бы слишком ресурсоемко проверять каждый из них на возможность расползания.
	 * Лучше хранить ограниченный список актуальных пограничных дымков, ведь они неуничтожимы в обычных условиях, и дыры не могут образоваться в неожиданных местах.
	 */
	var/list/fog_to_expand = list()

/obj/effect/anomaly/fog/Initialize(mapload, new_lifespan)
	. = ..()
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "smoke"))
	new /obj/effect/particle_effect/smoke/fog(loc, src)

/obj/effect/anomaly/fog/Destroy()
	fog_to_expand = null
	. = ..()

/obj/effect/anomaly/fog/anomalyEffect(seconds_per_tick)
	. = ..()
	// если моб пробежит в тайле аномалии, то тусклый свет потухнет, и её будет очень сложно найти вновь
	var/obj/effect/particle_effect/smoke/fog/F
	F = locate(/obj/effect/particle_effect/smoke/fog, loc) // по какой то причине свет будет обновляться только в случае постоянно нового обнаружения объекта тумана
	F?.set_opacity(FALSE)
	var/list/to_be_removed = list()
	for(F as anything in fog_to_expand)
		if(QDELETED(src))
			return
		if(QDELETED(F))
			to_be_removed += F
			continue
		if(TICK_CHECK)
			break // сервер вот-вот крякнет, повременим с распространением тумана
		var/adj_counter = 0
		for(var/direction in GLOB.cardinals)
			if(locate(/obj/effect/particle_effect/smoke/fog, get_step(F, direction)))
				adj_counter++
		if(adj_counter < 4 || length(fog_to_expand) < 4)
			INVOKE_ASYNC(F, TYPE_PROC_REF(/obj/effect/particle_effect/smoke/fog, spread_smoke))
		else
			to_be_removed += F
	fog_to_expand -= to_be_removed
