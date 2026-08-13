/obj/singularity/narsie //Moving narsie to a child object of the singularity so it can be made to function differently. --NEO
	name = "Nar'Sie's Avatar"
	desc = "Your mind begins to bubble and ooze as it tries to comprehend what it sees."
	icon = 'icons/obj/magic_terror.dmi'
	pixel_x = -89
	pixel_y = -85
	density = FALSE
	current_size = 9 //It moves/eats like a max-size singulo, aside from range. --NEO
	contained = 0 //Are we going to move around?
	dissipate = 0 //Do we lose energy over time?
	move_self = 1 //Do we move on our own?
	grav_pull = 5 //How many tiles out do we pull?
	consume_range = 6 //How many tiles out do we eat
	light_power = 0.7
	light_range = 15
	light_color = rgb(255, 0, 0)
	gender = FEMALE
	var/clashing = FALSE //If Nar'Sie is fighting Ratvar

/obj/singularity/narsie/large
	name = "Nar'Sie"
	icon = 'icons/obj/narsie.dmi'
	// Pixel stuff centers Narsie.
	pixel_x = -236
	pixel_y = -256
	current_size = 12
	grav_pull = 10
	consume_range = 12 //How many tiles out do we eat

/obj/singularity/narsie/large/Initialize(mapload)
	. = ..()
	GLOB.cult_narsie = src
	GLOB.poi_list |= src
	narsie_darken_cosmos()
	send_to_playing_players("<span class='narsie'>NAR'SIE ВОЗНЕСЛАСЬ</span>")
	sound_to_playing_players('sound/creatures/narsie_rises.ogg')

	var/area/A = get_area(src)
	if(A)
		var/mutable_appearance/alert_overlay = mutable_appearance('icons/effects/cult_effects.dmi', "ghostalertsie")
		notify_ghosts("Nar'Sie вознеслась в \the [A.name]. Обратитесь к Геометру, чтобы получить новую оболочку для своей души.", source = src, alert_overlay = alert_overlay, action=NOTIFY_ATTACK)
	INVOKE_ASYNC(src, PROC_REF(narsie_spawn_animation))

/obj/singularity/narsie/large/cult  // For the new cult ending, guaranteed to end the round within 3 minutes
	var/list/souls_needed = list()
	var/soul_goal = 0
	var/souls = 0
	var/resolved = FALSE

/obj/singularity/narsie/large/cult/Initialize(mapload)
	. = ..()
	GLOB.cult_narsie = src
	var/list/all_cults = list()
	for(var/datum/antagonist/cult/C in GLOB.antagonists)
		if(!C.owner)
			continue
		if(C.cult_team)
			all_cults |= C.cult_team
	for(var/datum/team/cult/T in all_cults)
		deltimer(T.blood_target_reset_timer)
		T.blood_target = src
		var/datum/objective/eldergod/summon_objective = locate() in T.objectives
		if(summon_objective)
			summon_objective.summoned = TRUE
	for(var/datum/mind/cult_mind in SSticker.mode.cult)
		if(isliving(cult_mind.current))
			var/mob/living/L = cult_mind.current
			INVOKE_ASYNC(L, TYPE_PROC_REF(/atom, narsie_act))
	var/total_crew = 0
	for(var/mob/living/carbon/crew in GLOB.player_list)
		if(crew.stat != DEAD && crew.loc && is_station_level(crew.loc.z))
			total_crew++
	for(var/mob/living/carbon/player in GLOB.player_list)
		if(player.stat != DEAD && player.loc && is_station_level(player.loc.z) && !iscultist(player) && !isanimal(player))
			souls_needed[player] = TRUE
	soul_goal = round(1 + total_crew * 0.50)
	INVOKE_ASYNC(src, PROC_REF(begin_the_end))

/obj/singularity/narsie/large/cult/proc/begin_the_end()
	sleep(50)
	priority_announce("В вашем секторе зафиксирован крупный пространственный разлом. Разлому присвоен класс опасности: ВЫМИРАНИЕ ВСЕГО ЖИВОГО. Сделайте всё возможное, чтобы остановить это. У ВАС ЕСТЬ 60 СЕКУНД.","Центральное Командование, Отдел Работы с Реальностью", 'sound/misc/airraid.ogg')
	sleep(500)
	priority_announce("Пространственный разлом принял необратимый характер. Мы развертываем последние оставшиеся силы. НЕМЕДЛЕННО ПОКИНЬТЕ СТАНЦИЮ.","Центральное Командование, Отдел Работы с Реальностью")
	sleep(50)
	set_security_level("delta")
	SSshuttle.registerHostileEnvironment(src)
	SSshuttle.lockdown = TRUE
	SSpersistence.station_was_destroyed = TRUE
	sleep(600)
	if(QDELETED(src))
		priority_announce("Датчики более не фиксируют обозначенного пространственного разлома. Решения ЦК отозваны. Тем не менее, рекомендуется произвести немедленную эвакуацию персонала.","Центральное Командование, Отдел Работы с Реальностью")
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), CULT_FAILURE_NARSIE_KILLED), 2 SECONDS)
		return
	if(souls >= soul_goal && !resolved)
		resolved = TRUE
		sound_to_playing_players('sound/machines/alarm.ogg')
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), CULT_VICTORY_MASS_CONVERSION), 10 SECONDS)
	else if(!resolved)
		resolved = TRUE
		sound_to_playing_players('sound/machines/alarm.ogg')
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), CULT_VICTORY_NUKE), 10 SECONDS)

/obj/singularity/narsie/large/Destroy()
	GLOB.poi_list -= src
	if(GLOB.cult_narsie == src)
		GLOB.cult_narsie = null
	return ..()

/obj/singularity/narsie/large/cult/Destroy()
	return ..()

/proc/ending_helper()
	SSticker.force_ending = 1

/proc/cult_ending_helper(ending_type = CULT_VICTORY_NUKE)
	switch(ending_type)

		if(CULT_FAILURE_NARSIE_KILLED)
			Cinematic(CINEMATIC_CULT_FA,world,CALLBACK(GLOBAL_PROC,GLOBAL_PROC_REF(ending_helper)))

		if(CULT_VICTORY_MASS_CONVERSION)
			Cinematic(CINEMATIC_CULT,world,CALLBACK(GLOBAL_PROC,GLOBAL_PROC_REF(ending_helper)))

		if(CULT_VICTORY_NUKE)
			Cinematic(CINEMATIC_CULT_NUKE,world,CALLBACK(GLOBAL_PROC,GLOBAL_PROC_REF(ending_helper)))


/proc/find_god_narsie_on_z(atom/ref)
	if(!ref)
		return
	if(GLOB.cult_narsie && !QDELETED(GLOB.cult_narsie) && GLOB.cult_narsie.z == ref.z)
		return GLOB.cult_narsie
	for(var/obj/singularity/narsie/large/N in GLOB.poi_list)
		if(!QDELETED(N) && N.z == ref.z)
			return N
	return null

/proc/find_god_ratvar_on_z(atom/ref)
	if(!ref)
		return
	for(var/obj/structure/destructible/clockwork/massive/ratvar/R in GLOB.poi_list)
		if(!QDELETED(R) && R.z == ref.z)
			return R
	return null

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/singularity/narsie/large/attack_ghost(mob/dead/observer/user as mob)
	makeNewConstruct(/mob/living/simple_animal/hostile/construct/harvester, user, cultoverride = TRUE, loc_override = src.loc)

/obj/singularity/narsie/process()
	if(clashing)
		return
	eat()
	var/obj/structure/destructible/clockwork/massive/ratvar/R = find_god_ratvar_on_z(src)
	if(R)
		acquire(R)
		if(get_dist(src, R) <= 10)
			R.clash()
			return
		move(get_dir(src, R))
		if(prob(25))
			mezzer()
		return
	if(!target || !get_turf(target))
		pickcultist()
	if(target && get_turf(target))
		move(get_dir(src, target))
	if(prob(25))
		mezzer()


/obj/singularity/narsie/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return clashing


/obj/singularity/narsie/Bump(atom/A)
	var/turf/T = get_turf(A)
	if(T == loc)
		T = get_step(A, A.dir) //please don't slam into a window like a bird, Nar'Sie
	forceMove(T)


/obj/singularity/narsie/mezzer()
	for(var/mob/living/carbon/M in fov_viewers(consume_range, src))
		if(M.stat == CONSCIOUS)
			if(!iscultist(M))
				to_chat(M, "<span class='cultsmall'>You feel conscious thought crumble away in an instant as you gaze upon [src.name]...</span>")
				M.apply_effect(60, EFFECT_STUN)


/obj/singularity/narsie/consume(atom/A)
	if(isturf(A))
		A.narsie_act()


/obj/singularity/narsie/ex_act(severity, target, origin) //No throwing bombs at her either.
	return


/obj/singularity/narsie/proc/pickcultist() //Narsie rewards her cultists with being devoured first, then picks a ghost to follow.
	var/obj/structure/destructible/clockwork/massive/ratvar/enemy = find_god_ratvar_on_z(src)
	if(enemy)
		acquire(enemy)
		return

	var/list/cultists = list()
	var/list/noncultists = list()
	for(var/mob/living/carbon/food in GLOB.alive_mob_list)
		var/turf/pos = get_turf(food)
		if(!pos || pos.z != z || !is_station_level(pos.z))
			continue
		if(iscultist(food))
			cultists += food
		else
			noncultists += food

	if(noncultists.len)
		acquire(pick(noncultists))
		return

	if(cultists.len)
		acquire(pick(cultists))
		return

	//no living humans, follow a ghost instead.
	for(var/mob/dead/observer/ghost in GLOB.player_list)
		if(!ghost.client)
			continue
		var/turf/pos = get_turf(ghost)
		if(!pos || (pos.z != z))
			continue
		cultists += ghost
	if(cultists.len)
		acquire(pick(cultists))
		return


/obj/singularity/narsie/proc/acquire(atom/food)
	if(food == target)
		return
	to_chat(target, "<span class='cultsmall'>НАР'СИ ПОТЕРЯЛА К ВАМ ИНТЕРЕС.</span>")
	target = food
	if(ishuman(target))
		to_chat(target, "<span class ='cult'>НАР'СИ ЖАЖДЕТ ВАШЕЙ ДУШИ.</span>")
	else
		to_chat(target, "<span class ='cult'>НАР'СИ ИЗБРАЛА ВАС ПРОВОДНИКОМ К СЛЕДУЮЩЕЙ ЖЕРТВЕ.</span>")

//Wizard narsie
/obj/singularity/narsie/wizard
	grav_pull = 0

/obj/singularity/narsie/wizard/eat()
//	if(defer_powernet_rebuild != 2)
//		defer_powernet_rebuild = 1
	for(var/atom/X in urange(consume_range,src,1))
		if(isturf(X) || ismovable(X))
			consume(X)
//	if(defer_powernet_rebuild != 2)
//		defer_powernet_rebuild = 0
	return


/obj/singularity/narsie/proc/narsie_spawn_animation()
	icon = 'icons/obj/narsie_spawn_anim.dmi'
	setDir(SOUTH)
	move_self = 0
	flick("narsie_spawn_anim",src)
	sleep(11)
	move_self = 1
	icon = initial(icon)



