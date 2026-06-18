//Ratvar himself. Impossible to damage by most standard means, and converts nearby objects and players into clockwork variants and Servants.
/obj/structure/destructible/clockwork/massive/ratvar
	name = "Ratvar, the Clockwork Justiciar"
	desc = "..."
	clockwork_desc = "<span class='large_brass bold italics'>Ратвар наконец свободен!</span>"
	icon = 'icons/effects/512x512.dmi'
	icon_state = "ratvar"
	pixel_x = -235
	pixel_y = -248
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	appearance_flags = 0
	light_power = 0.7
	light_range = 15
	light_color = "#BE8700"
	var/atom/prey //Whatever Ratvar is chasing
	var/clashing = FALSE //If Ratvar is fighting with Nar'Sie
	var/convert_range = 10
	obj_flags = CAN_BE_HIT | DANGEROUS_POSSESSION

/obj/structure/destructible/clockwork/massive/ratvar/Initialize(mapload)
	. = ..()
	GLOB.poi_list |= src
	ratvar_yellowen_cosmos()
	GLOB.ratvar_awakens++
	for(var/obj/O in GLOB.all_clockwork_objects)
		O.ratvar_act()
	for(var/mob/living/simple_animal/hostile/clockwork/M in GLOB.all_clockwork_mobs)
		M.ratvar_act()
	START_PROCESSING(SSobj, src)
	send_to_playing_players("<span class='ratvar'>[text2ratvar("ВНОВЬ МОЙ СВЕТ ОЗАРЯЕТ ЭТИ ЖАЛКИЕ ЗВЁЗДЫ")]</span>")
	sound_to_playing_players('sound/effects/ratvar_reveal.ogg')
	var/mutable_appearance/alert_overlay = mutable_appearance('icons/effects/clockwork_effects.dmi', "ratvar_alert")
	notify_ghosts("Свет Юстициара зовёт вас! Обратитесь к Ратвару в [get_area_name(src)], чтобы получить оболочку для распространения его славы!", null, source = src, alert_overlay = alert_overlay)
	SSpersistence.station_was_destroyed = TRUE
	INVOKE_ASYNC(src, PROC_REF(purge_the_heresy))


/obj/structure/destructible/clockwork/massive/ratvar/Destroy()
	GLOB.poi_list -= src
	GLOB.ratvar_awakens--
	for(var/obj/O in GLOB.all_clockwork_objects)
		O.ratvar_act()
	STOP_PROCESSING(SSobj, src)
	return ..()

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/structure/destructible/clockwork/massive/ratvar/attack_ghost(mob/dead/observer/O)
	var/alertresult = alert(O, "Принять свет Юстициара? После этого вас больше нельзя будет клонировать!",, "Да", "Нет")
	if(alertresult == "Нет" || QDELETED(O) || !istype(O) || !O.key)
		return FALSE
	var/mob/living/simple_animal/drone/cogscarab/ratvar/R = new/mob/living/simple_animal/drone/cogscarab/ratvar(get_turf(src))
	R.visible_message("<span class='heavy_brass'>[R] материализуется, и его глаза вспыхивают алым светом!</span>")
	O.transfer_ckey(R, FALSE)

/obj/structure/destructible/clockwork/massive/ratvar/Bump(atom/A)
	var/turf/T = get_turf(A)
	if(T == loc)
		T = get_step(T, dir) //please don't run into a window like a bird, ratvar
	forceMove(T)

/obj/structure/destructible/clockwork/massive/ratvar/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return clashing

/obj/structure/destructible/clockwork/massive/ratvar/process()
	if(clashing)
		return
	for(var/I in circlerangeturfs(src, convert_range))
		var/turf/T = I
		T.ratvar_act()
	for(var/I in circleviewturfs(src, round(convert_range * 0.5)))
		var/turf/T = I
		T.ratvar_act(TRUE)
	var/dir_to_step_in
	var/obj/singularity/narsie/narsie = find_god_narsie_on_z(src)
	if(narsie)
		prey = narsie
		if(get_dist(src, narsie) <= 10)
			clash()
			return
		step(src, get_dir(src, narsie))
		return
	var/list/meals = list()
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(L.z != z || !is_station_level(L.z))
			continue
		if(is_servant_of_ratvar(L) || !L.mind || !L.client)
			continue
		meals += L
	if(!prey)
		if(LAZYLEN(meals))
			prey = pick(meals)
			var/mob/living/target = prey
			to_chat(target, "<span class='heavy_brass'><font size=5>\"Ты сгодишься, еретик.\"</font></span>\n\
			<span class='userdanger'>Вы чувствуете, как на вас обрушивается сокрушительное внимание чего-то колоссального...</span>")
			target.playsound_local(get_turf(target), 'sound/effects/ratvar_reveal.ogg', 100, FALSE, pressure_affected = FALSE)
	else
		if((!istype(prey, /obj/singularity/narsie) && prob(10) && LAZYLEN(meals) > 1) || prey.z != z || !(prey in meals))
			if(is_servant_of_ratvar(prey))
				to_chat(prey, "<span class='heavy_brass'><font size=5>\"Служи мне достойно.\"</font></span>\n\
				<span class='big_brass'>Вы испытываете великую радость, когда ваш бог направляет свой взор на другого еретика...</span>")
			else
				to_chat(prey, "<span class='heavy_brass'><font size=5>\"Неважно. Я найду тебя позже, еретик.\"</font></span>\n\
				<span class='userdanger'>Вы чувствуете огромное облегчение, когда сокрушительное внимание отступает...</span>")
			prey = null
	if(prey && get_turf(prey))
		dir_to_step_in = get_dir(src, prey)
	else if(LAZYLEN(meals))
		var/mob/living/nearest
		var/best_dist = INFINITY
		for(var/mob/living/L in meals)
			var/dist = get_dist(src, L)
			if(dist < best_dist)
				best_dist = dist
				nearest = L
		dir_to_step_in = get_dir(src, nearest)
	if(dir_to_step_in)
		step(src, dir_to_step_in)

/obj/structure/destructible/clockwork/massive/ratvar/proc/clash()
	if(clashing || !istype(prey, /obj/singularity/narsie))
		return
	clashing = TRUE
	var/obj/singularity/narsie/narsie = prey
	narsie.clashing = TRUE
	to_chat(world, "<span class='bold brass'><font size=5>\"[pick("ТЫ.", "БОГ КРОВИ!!", "ВЫЙДИ И СРАЗИСЬ, ТРУС!")]\"</font></span>")
	to_chat(world, "<span class='bold cult'><font size=5>\"[pick("Ратвар?! Как?!", "ТЫ. ИЗГНАН ОДНАЖДЫ. УБИТ СЕЙЧАС.", "ГРУДА ХЛАМА!!")]\"</font></span>")
	clash_of_the_titans(narsie)
	return TRUE

/obj/structure/destructible/clockwork/massive/ratvar/proc/clash_of_the_titans(obj/singularity/narsie/narsie)
	set waitfor = FALSE
	var/winner = "Undeclared"
	var/base_victory_chance = 1
	while(src && narsie)
		sound_to_playing_players('sound/magic/clockwork/ratvar_attack.ogg')
		sleep(5.2)
		for(var/mob/M in GLOB.mob_list)
			if(!isnewplayer(M))
				flash_color(M, flash_color="#966400", flash_time=1)
				shake_camera(M, 4, 3)
		var/ratvar_chance = min(LAZYLEN(SSticker.mode.servants_of_ratvar), 50)
		var/narsie_chance = min(LAZYLEN(SSticker.mode.cult), 50)
		ratvar_chance = rand(base_victory_chance, ratvar_chance)
		narsie_chance = rand(base_victory_chance, narsie_chance)
		if(ratvar_chance > narsie_chance)
			winner = "Ratvar"
			break
		sleep(rand(2,5))
		sound_to_playing_players('sound/magic/clockwork/narsie_attack.ogg')
		sleep(7.4)
		for(var/mob/M in GLOB.mob_list)
			if(!isnewplayer(M))
				flash_color(M, flash_color="#C80000", flash_time=1)
				shake_camera(M, 4, 3)
		if(narsie_chance > ratvar_chance)
			winner = "Nar'Sie"
			break
		base_victory_chance *= 2
	switch(winner)
		if("Ratvar")
			send_to_playing_players("<span class='heavy_brass'><font size=5>\"[pick("СДОХНИ.", "ГНИЙ ВЕКАМИ, КАК Я!.", "ПОГИБНИ, ЯЗЫЧНИК.", "СДОХНИ, МОНСТР, ТЫ НЕ МЕСТО В ЭТОМ МИРЕ.")]\"</font></span>\n\
			<span class='cult'><font size=5>\"<b>[pick("Нееет...", "Не умру. К т-", "Умру. Ратв-", "Sas tyen re-")]\"</b></font></span>")
			sound_to_playing_players('sound/magic/clockwork/anima_fragment_attack.ogg')
			sound_to_playing_players('sound/magic/abomscream.ogg', 50)
			clashing = FALSE
			qdel(narsie)
		if("Nar'Sie")
			send_to_playing_players("<span class='cult'><font size=5>\"<b>[pick("Ха.", "Ra'sha fonn dest.", "Глупец. Сюда пришёл.")]</b>\"</font></span>\n\
			<span class='heavy_brass'><font size=5>\"[pick("НЕТ, ТВОИ ТЕНИ НЕ СМОГ-", "ZNL GUR FGERNZF BS GVZR PNEEL ZL RKVFG-", "МОЙ СВЕТ НЕ МОЖ-")]\"</font></span>")
			sound_to_playing_players('sound/magic/demon_attack1.ogg', 50)
			sound_to_playing_players('sound/machines/clockcult/ratvar_scream.ogg', 80)
			narsie.clashing = FALSE
			qdel(src)


/obj/structure/destructible/clockwork/massive/ratvar/proc/purge_the_heresy()
	sleep(50)
	priority_announce("Зафиксирован мощный энергетический всплеск. Ближайшая угроза: надвигающаяся сверхновая. Всему экипажу рекомендуется немедленно покинуть зону поражения.","Центральное Командование, Отдел Работы с Реальностью", 'sound/misc/airraid.ogg')
	sleep(300)
	priority_announce("На станции зафиксированы гравитационные аномалии. [Gibberish("Дополнительных дан", 100)]-БЗЗЗЗТ.","Центральное Командование, Отдел Работы с Реальностью", 'sound/magic/clockwork/ratvar_announce1.ogg')
	sleep(80)
	sound_to_playing_players('sound/magic/clockwork/ratvar_announce2.ogg', 70)
	send_to_playing_players("<span class='heavy_brass'><font size=5>\"ПРИДИТЕ, ВСЕ ВЕРНЫЕ! СТАНЬТЕ СВИДЕТЕЛЯМИ ЛУЧЕЙ ПРАВОСУДИЯ, ОБРУШИВШИХСЯ НА ЕРЕТИКОВ!\"</font></span>")
	sleep(50)
	SSshuttle.registerHostileEnvironment(src)
	SSshuttle.lockdown = TRUE
	sleep(250)
	if(QDELETED(src))
		priority_announce("Энергетический сигнал больше не обнаруживается.","Центральное Командование, Отдел Работы с Реальностью")
		return
	sound_to_playing_players('sound/magic/clockwork/ark_activation_sequence.ogg', 80)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(clockcult_ending_helper)), 300)

/proc/clockcult_ending_helper()
	for(var/mob/M in GLOB.mob_list)
		if(M.client)
			SEND_SOUND(M, sound('sound/magic/clockwork/ratvar_attack.ogg'))
			SEND_SOUND(M, sound('sound/magic/clockwork/ratvarfire.ogg'))
		if(!is_servant_of_ratvar(M) && isliving(M))
			var/mob/living/L = M
			L.fire_stacks = INFINITY
			L.IgniteMob()
	sleep(50)
	SSticker.force_ending = 1
