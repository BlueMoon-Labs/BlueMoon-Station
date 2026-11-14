#define SWARMER_ORGANIC_ITEM_PROCESS_LIMIT 5
#define SWARMER_ORGANIC_ITEM_PROCESS_DELAY 10 SECONDS
#define SWARMER_ORGANIC_ITEM_PROCESS_GAIN (rand(1, 5))

/obj/structure/swarmer/organic_processer
	name = "swarmer organic processer"
	desc = "Переработчик, позволяющий обрабатывать органику в ресурсы \"Свармеров\"."
	icon_state = "bio_processer"
	swarmer_examine = "Обрабатывает овощи, реагенты. Не делает этого в открученном состоянии. Загрузка в эту машину происходит через атаку по данным предметам."
	max_integrity = 70
	var/currently_processing = 0
	var/process_timer
	var/process_limit = SWARMER_ORGANIC_ITEM_PROCESS_LIMIT
	var/datum/looping_sound/swarmer_processer/sound_loop
	var/datum/effect_system/spark_spread/spark_system

/obj/structure/swarmer/organic_processer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	sound_loop = new(src, FALSE)
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/structure/swarmer/organic_processer/Destroy(force)
	if(process_timer)
		deltimer(process_timer)
	QDEL_NULL(spark_system)
	QDEL_NULL(sound_loop)
	for(var/atom/movable/atom_movable as anything in contents)
		atom_movable.forceMove(loc)
	return ..()

/obj/structure/swarmer/organic_processer/emp_act(severity)
	..()
	if(!currently_processing)
		return

	sound_loop.stop()
	addtimer(CALLBACK(sound_loop, TYPE_PROC_REF(/datum/looping_sound, start)), SWARMER_STRUCTURE_EMP_DURATION * severity, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_NO_HASH_WAIT | TIMER_DELETE_ME)
	animate(src, transform = matrix())

	var/new_delay = SWARMER_ORGANIC_ITEM_PROCESS_DELAY + SWARMER_STRUCTURE_EMP_DURATION * severity
	deltimer(process_timer)
	process_timer = addtimer(CALLBACK(src, PROC_REF(finish_processing)), new_delay, TIMER_STOPPABLE)

/obj/structure/swarmer/organic_processer/proc/try_load_item(obj/item)
	if(!anchored)
		return FALSE
	if(currently_processing >= process_limit)
		return FALSE
	if(!currently_processing)
		process_timer = addtimer(CALLBACK(src, PROC_REF(finish_processing)), SWARMER_ORGANIC_ITEM_PROCESS_DELAY, TIMER_STOPPABLE)
		sound_loop.start()
	if(item)
		item.forceMove(src)
	currently_processing++
	spark_system.start()
	return TRUE

/obj/structure/swarmer/organic_processer/proc/finish_processing()
	process_timer = null
	if(length(contents))
		var/obj/item = contents[1]
		if(!QDELETED(item))
			qdel(item)
	balloon_alert_to_viewers("обработано!")
	spark_system.start()
	team?.adjust_organic(SWARMER_ORGANIC_ITEM_PROCESS_GAIN)
	currently_processing--
	if(currently_processing)
		process_timer = addtimer(CALLBACK(src, PROC_REF(finish_processing)), SWARMER_ORGANIC_ITEM_PROCESS_DELAY, TIMER_STOPPABLE)
		return

	sound_loop.stop()
	playsound(loc, 'sound/machines/ding.ogg', 50, TRUE)
	animate(src, transform = matrix())

/obj/structure/swarmer/organic_processer/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!currently_processing)
		return ..()

	swarmer.balloon_alert(swarmer, "не открутить, работает!")

#undef SWARMER_ORGANIC_ITEM_PROCESS_LIMIT
#undef SWARMER_ORGANIC_ITEM_PROCESS_DELAY
#undef SWARMER_ORGANIC_ITEM_PROCESS_GAIN
