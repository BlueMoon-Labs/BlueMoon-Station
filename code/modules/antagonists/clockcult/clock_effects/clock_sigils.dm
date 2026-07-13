//Sigils: Rune-like markings on the ground with various effects.
/obj/effect/clockwork/sigil
	name = "sigil"
	desc = "Странный набор знаков, нарисованных на земле."
	clockwork_desc = "Сигил, имеющий какое-то назначение."
	icon_state = "sigil"
	layer = LOW_OBJ_LAYER
	plane = ABOVE_WALL_PLANE
	alpha = 50
	resistance_flags = NONE
	var/affects_servants = FALSE
	var/stat_affected = CONSCIOUS
	var/sigil_name = "Sigil"
	var/resist_string = "светится ослепительно белым светом" //string for when a null rod blocks its effects, "glows [resist_string]"
	var/check_antimagic = TRUE
	var/check_holy = FALSE

/obj/effect/clockwork/sigil/attackby(obj/item/I, mob/living/user, params)
	if(I.force)
		if(is_servant_of_ratvar(user) && user.a_intent != INTENT_HARM)
			return ..()
		if(istype(I, /obj/item/nullrod) || istype(I, /obj/item/clockwork/slab))
			user.visible_message("<span class='warning'>[user] убирает [src] при помощи [I]!</span>", "<span class='danger'>Ты убираешь [src] при помощи [I]!</span>")
			qdel(src)
		return TRUE
	return ..()

/obj/effect/clockwork/sigil/attack_tk(mob/user)
	return //you can't tk stomp sigils, but you can hit them with something

/obj/effect/clockwork/sigil/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(iscarbon(user) && !user.stat)
		if(is_servant_of_ratvar(user) && user.a_intent != INTENT_HARM)
			return ..()
		return TRUE
	. = ..()

/obj/effect/clockwork/sigil/ex_act(severity, target, origin)
	visible_message("<span class='warning'>[src] разлетается на тысячи частиц.</span>")
	qdel(src)

/obj/effect/clockwork/sigil/Crossed(atom/movable/AM)
	..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(L.stat <= stat_affected)
			if((!is_servant_of_ratvar(L) || (affects_servants && is_servant_of_ratvar(L))) && (L.mind || L.has_status_effect(STATUS_EFFECT_SIGILMARK)) && !isdrone(L))
				var/atom/I = L.anti_magic_check(check_antimagic, check_holy)
				if(I)
					if(isitem(I))
						L.visible_message("<span class='warning'>[I.name] в руках [L] [resist_string], защищая [L.ru_ego()] от эффектов [src]!</span>", \
						"<span class='userdanger'>Ваш [I.name] [resist_string], защищая вас!</span>")
					return
				sigil_effects(L)

/obj/effect/clockwork/sigil/proc/sigil_effects(mob/living/L)


//Sigil of Transgression: Stuns the first non-servant to walk on it and flashes all nearby non_servants. Nar'Sian cultists are damaged and knocked down for a longer time
/obj/effect/clockwork/sigil/transgression
	name = "dull sigil"
	desc = "Тусклый, едва различимый золотой сигил. Словно свет был высечен прямо в земле."
	icon = 'icons/effects/clockwork_effects.dmi'
	clockwork_desc = "Сигил, который оглушит следующее существо, не являющееся Слугой, которое наступит на него."
	icon_state = "sigildull"
	layer = HIGH_SIGIL_LAYER
	alpha = 75
	color = "#FAE48C"
	light_range = 1.4
	light_power = 1
	light_color = "#FAE48C"
	sigil_name = "Sigil of Transgression"

/obj/effect/clockwork/sigil/transgression/sigil_effects(mob/living/L)
	var/target_flashed = L.flash_act()
	for(var/mob/living/M in viewers(5, src))
		if(!is_servant_of_ratvar(M) && M != L)
			M.flash_act()
	if(iscultist(L)) //No longer stuns cultists, instead sets them on fire and burns them
		to_chat(L, "<span class='heavy_brass'>\"Смотри под ноги, ублюдок.\"</span>")
		L.adjustFireLoss(10)
		L.DefaultCombatKnockdown(20, FALSE)
		L.adjust_fire_stacks(5) //Burn!
		L.IgniteMob()
	else
		L.Stun(40)
	L.visible_message("<span class='warning'>[src] появляется вокруг ног [L] в яркой вспышке света!</span>", \
	"<span class='userdanger'>[target_flashed ? "Невидимая сила":"Светящийся сигил вокруг тебя"] [iscultist(L) ? " вспыхивает пламенем!" : "держит вас на месте!"]</span>")
	L.apply_status_effect(STATUS_EFFECT_BELLIGERENT)
	new /obj/effect/temp_visual/ratvar/sigil/transgression(get_turf(src))
	qdel(src)


//Sigil of Submission: After a short time, converts any non-servant standing on it. Knocks down and silences them for five seconds afterwards.
/obj/effect/clockwork/sigil/submission
	name = "ominous sigil"
	desc = "Светящийся золотой сигил. Что-то в нём вас сильно беспокоит."
	clockwork_desc = "Сигил, который порабощает любое существо, не являющееся Слугой, если оно останется на нём в течение 8 секунд, включая целей без сознания и мертвых целей. Не проникает через имплант защиты разума."
	icon_state = "sigilsubmission"
	layer = LOW_SIGIL_LAYER
	alpha = 125
	color = "#FAE48C"
	light_range = 2 //soft light
	light_power = 0.9
	light_color = "#FAE48C"
	stat_affected = DEAD
	resist_string = "слабо светится желтым светом"
	var/convert_time = 80
	var/delete_on_finish = TRUE
	sigil_name = "Sigil of Submission"
	var/glow_type = /obj/effect/temp_visual/ratvar/sigil/submission

/obj/effect/clockwork/sigil/submission/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(check_initial_occupants))

/// Targets already on the sigil tile when it is created do not trigger Crossed().
/obj/effect/clockwork/sigil/submission/proc/check_initial_occupants()
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/atom/movable/AM in T)
		if(try_trigger_on(AM))
			return

/obj/effect/clockwork/sigil/submission/proc/try_trigger_on(atom/movable/AM)
	if(istype(AM, /obj/item/aicard))
		var/obj/item/aicard/cardy = AM
		if(!cardy.AI)
			return FALSE
		var/mob/living/silicon/ai/aiconvert = cardy.AI
		if(aiconvert.stat > stat_affected)
			return FALSE
		if(is_servant_of_ratvar(aiconvert) || !(aiconvert.mind || aiconvert.has_status_effect(STATUS_EFFECT_SIGILMARK)))
			return FALSE
		sigil_effects(aiconvert)
		return TRUE
	if(!isliving(AM))
		return FALSE
	var/mob/living/L = AM
	if(L.stat > stat_affected)
		return FALSE
	if(is_servant_of_ratvar(L) || !(L.mind || L.has_status_effect(STATUS_EFFECT_SIGILMARK)) || isdrone(L))
		return FALSE
	var/atom/I = L.anti_magic_check(check_antimagic, check_holy)
	if(I)
		if(isitem(I))
			L.visible_message("<span class='warning'>[I.name] в руках [L] [resist_string], защищая [L.ru_ego()] от эффектов [src]</span>", \
			"<span class='userdanger'>Ваш [I.name] [resist_string], защищая вас!</span>")
		return FALSE
	sigil_effects(L)
	return TRUE

/obj/effect/clockwork/sigil/submission/Crossed(atom/movable/AM)
	try_trigger_on(AM)

/obj/effect/clockwork/sigil/submission/sigil_effects(mob/living/L)
	var/turf/T = get_turf(src)
	var/has_sigil = FALSE
	var/has_servant = FALSE
	if(locate(/obj/effect/clockwork/sigil/transgression) in T)
		has_sigil = TRUE
	for(var/mob/living/M in range(3, src))
		if(is_servant_of_ratvar(M) && !M.stat)
			has_servant = TRUE
	if(!has_sigil && !has_servant)
		visible_message("<span class='danger'>[src] переходит в нежный фиолетовый оттенок, но постепенно блекнет...</span>")
		return
	L.visible_message("<span class='warning'>[src] начинает светиться ярким пурпурным светом!</span>", "<span class='sevtug'>Вы чувствуете, как что-то начинает проникать в ваш разум...</span>")
	var/oldcolor = color
	animate(src, color = "#AF0AAF", time = convert_time, flags = ANIMATION_END_NOW)
	var/obj/effect/temp_visual/ratvar/sigil/glow
	if(glow_type)
		glow = new glow_type(get_turf(src))
		animate(glow, alpha = 255, time = convert_time)
	var/end_time = world.time+convert_time
	while(world.time < end_time && get_turf(L) == get_turf(src))
		stoplag(1)
	if(get_turf(L) != get_turf(src))
		if(glow)
			qdel(glow)
		animate(src, color = oldcolor, time = 20, flags = ANIMATION_END_NOW)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 20)
		visible_message("<span class='warning'>[src] постепенно перестает светиться!</span>")
		return
	if(is_eligible_servant(L))
		to_chat(L, "<span class='heavy_brass'>\"Теперь ты принадлежишь мне.\"</span>")
		if(!GLOB.application_scripture_unlocked)
			GLOB.application_scripture_unlocked = TRUE
			hierophant_message("<span class='large_brass bold'>С присоединением нового слуги сила Сети Иерофанта растёт. Открыты новые Писания для служения Ратвару.</span>")
	if(add_servant_of_ratvar(L))
		L.log_message("conversion was done with a [sigil_name]", LOG_ATTACK, color="BE8700")
		var/datum/antagonist/clockcult/clock_antag = L.mind?.has_antag_datum(/datum/antagonist/clockcult)
		clock_antag?.clock_team?.check_size()
		var/was_dead = L.stat == DEAD
		if(iscarbon(L))
			var/mob/living/carbon/M = L
			M.uncuff()
		if(iscyborg(L) && was_dead)
			var/mob/living/silicon/robot/R = L
			R.revive(TRUE)
			R.visible_message("<span class='warning'>Шасси [R] содрогается, когда латунный свет перепрошивает [R.ru_ego()] схемы!</span>", \
			"<span class='heavy_brass'>Ваши системы перезагружаются в пользу Юстициара.</span>")
		else
			var/brutedamage = L.getBruteLoss()
			var/burndamage = L.getFireLoss()
			if(brutedamage || burndamage)
				L.adjustBruteLoss(-(brutedamage * 0.75))
				L.adjustFireLoss(-(burndamage * 0.75))
				L.visible_message("<span class='warning'>[L] корчится от боли, когда [L.ru_ego()]  раны заживают и затягиваются!</span>", \
				"<span class='heavy_brass'><i>AAAAAAAAAAAAAA-</i></span>")
		if(!was_dead)
			L.DefaultCombatKnockdown(50) //Completely defenseless for five seconds - mainly to give them time to read over the information they've just been presented with
			if(iscarbon(L))
				var/mob/living/carbon/H = L
				H.silent += 5
	var/message = "[sigil_name] в [get_area(src)] <span class='sevtug'>[is_servant_of_ratvar(L) ? "успешно конвертировал" : "не удалось конвертировать"]</span>"
	new /obj/item/clockwork/slab (get_turf(src))
	for(var/M in GLOB.mob_list)
		if(isobserver(M))
			var/link = FOLLOW_LINK(M, L)
			to_chat(M,  "[link] <span class='heavy_brass'>[message] [L.real_name]!</span>")
		else if(is_servant_of_ratvar(M))
			if(M == L)
				to_chat(M, "<span class='heavy_brass'>[message] вас!</span>")
			else
				to_chat(M, "<span class='heavy_brass'>[message] [L.real_name]!</span>")
	animate(src, color = oldcolor, time = 20, flags = ANIMATION_END_NOW)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 20)
	visible_message("<span class='warning'>[src] медленно перестаёт светиться!</span>")


//Sigil of Transmission: Serves as an access point for powered structures.
/obj/effect/clockwork/sigil/transmission
	name = "suspicious sigil"
	desc = "Светящийся оранжевый сигил. Воздух вокруг него наполнен статическим электричеством."
	clockwork_desc = "Сигил, служащий источником энергии и аккумулятором для механических конструкций, связанный со всеми другими сигилами этого типа."
	icon_state = "sigiltransmission"
	alpha = 50
	color = "#EC8A2D"
	light_color = "#EC8A2D"
	resist_string = "glows faintly"
	sigil_name = "Sigil of Transmission"
	affects_servants = TRUE

/obj/effect/clockwork/sigil/transmission/Initialize(mapload)
	. = ..()
	update_icon()

/obj/effect/clockwork/sigil/transmission/ex_act(severity, target, origin)
	if(severity == 3)
		adjust_clockwork_power(500) //Light explosions charge the network!
		visible_message("<span class='warning'>[src] сверкает ярким оранжевым цветом!</span>")
	else
		..()

/obj/effect/clockwork/sigil/transmission/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		var/structure_number = 0
		for(var/obj/structure/destructible/clockwork/powered/P in range(SIGIL_ACCESS_RANGE, src))
			structure_number++
		. += "<span class='[get_clockwork_power() ? "brass":"alloy"]'>Оно хранит <b>[DisplayPower(get_clockwork_power())]</b> общей энергии \
		и в зоне находится <b>[structure_number]</b> часов[structure_number == 1 ? "ой" : "ых"] механизм[structure_number == 1 ? "" : (structure_number >= 2 && structure_number <= 4 ? "а" : "ов")] .</span>"
		if(iscyborg(user))
			. += "<span class='brass'>Вы можете восполнить энергию [sigil_name], пройдя через него.</span>"

/obj/effect/clockwork/sigil/transmission/sigil_effects(mob/living/L)
	if(is_servant_of_ratvar(L))
		if(iscyborg(L))
			charge_cyborg(L)
	else if(get_clockwork_power())
		to_chat(L, "<span class='brass'>Вы чувствуете лёгкий статический разряд.</span>")

/obj/effect/clockwork/sigil/transmission/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/clockwork/sigil/transmission/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/clockwork/sigil/transmission/process()
	do_process()

/obj/effect/clockwork/sigil/transmission/proc/do_process()
	set waitfor = FALSE
	var/power_drained = 0
	var/power_mod = 0.005
	for(var/t in spiral_range_turfs(SIGIL_ACCESS_RANGE, src))
		var/turf/T = t
		for(var/M in T)
			var/atom/movable/A = M
			power_drained += A.power_drain(TRUE)

		CHECK_TICK

	adjust_clockwork_power(power_drained * power_mod * 15)
	new /obj/effect/temp_visual/ratvar/sigil/transmission(loc, 1 + (power_drained * 0.0035))

/obj/effect/clockwork/sigil/transmission/proc/charge_cyborg(mob/living/silicon/robot/cyborg)
	if(!cyborg_checks(cyborg))
		return
	to_chat(cyborg, "<span class='brass'>Вы начинаете заряжаться от [sigil_name]...</span>")
	if(!do_after(cyborg, 50, target = src, extra_checks = CALLBACK(src, PROC_REF(cyborg_checks), cyborg, TRUE)))
		return
	var/giving_power = min(FLOOR(cyborg.cell.maxcharge - cyborg.cell.charge, MIN_CLOCKCULT_POWER), get_clockwork_power()) //give the borg either all our power or their missing power floored to MIN_CLOCKCULT_POWER
	if(adjust_clockwork_power(-giving_power))
		cyborg.visible_message("<span class='warning'>[cyborg] светится ярким оранжевым цветом!</span>")
		var/previous_color = cyborg.color
		cyborg.color = list("#EC8A2D", "#EC8A2D", "#EC8A2D", rgb(0,0,0))
		cyborg.apply_status_effect(STATUS_EFFECT_POWERREGEN, giving_power * 0.1) //ten ticks, restoring 10% each
		animate(cyborg, color = previous_color, time = 100)
		addtimer(CALLBACK(cyborg, TYPE_PROC_REF(/atom, update_atom_colour)), 100)

/obj/effect/clockwork/sigil/transmission/proc/cyborg_checks(mob/living/silicon/robot/cyborg, silent)
	if(!cyborg.cell)
		if(!silent)
			to_chat(cyborg, "<span class='warning'>У вас нет батареи</span>")
		return FALSE
	if(!get_clockwork_power())
		if(!silent)
			to_chat(cyborg, "<span class='warning'>Нет доступной энергии в сети сигилов!</span>")
		return FALSE
	if(cyborg.cell.charge > cyborg.cell.maxcharge - MIN_CLOCKCULT_POWER)
		if(!silent)
			to_chat(cyborg, "<span class='warning'>Вы уже имеете максимальный заряд!</span>")
		return FALSE
	if(cyborg.has_status_effect(STATUS_EFFECT_POWERREGEN))
		if(!silent)
			to_chat(cyborg, "<span class='warning'>Вы уже регенерируете энергию!</span>")
		return FALSE
	return TRUE

/obj/effect/clockwork/sigil/transmission/update_icon()
	. = ..()
	var/power_charge = get_clockwork_power()
	if(GLOB.ratvar_awakens)
		alpha = 255
	else
		alpha = min(CEILING(initial(alpha) + power_charge * 0.02, 35), 255)
	var/r = alpha * 0.02
	var/p = max(alpha * 0.01, 0.1)
	if(!power_charge && light_range != 0)
		set_light(0)
	else if(r != light_range || p != light_power)
		set_light(r, p)

//Vitality Matrix: Drains health from non-servants to heal or even revive servants.
/obj/effect/clockwork/sigil/vitality
	name = "comforting sigil"
	desc = "Слабый голубой сигил. Глядя на него, чувствуешь себя в безопасности."
	clockwork_desc = "Сигил, который будет поглощать жизненную силу всех существ, кроме Слуг, находящихся на его поверхности. Слуги, остающиеся на нем, будут восстанавливать здоровье, если с него будет поглощена жизненная сила."
	icon_state = "sigilvitality"
	layer = SIGIL_LAYER
	alpha = 125
	color = "#123456"
	affects_servants = TRUE
	stat_affected = DEAD
	resist_string = "светится мерцающим желтым светом"
	sigil_name = "Vitality Matrix"
	var/revive_cost = 150
	var/sigil_active = FALSE
	var/min_drain_health = -INFINITY
	var/can_dust = TRUE
	var/animation_number = 3 //each cycle increments this by 1, at 4 it produces an animation and resets
	var/static/list/damage_heal_order = list(CLONE, TOX, BURN, BRUTE, OXY) //we heal damage in this order

/obj/effect/clockwork/sigil/vitality/neutered
	min_drain_health = 20
	can_dust = FALSE

/obj/effect/clockwork/sigil/vitality/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='[GLOB.clockwork_vitality ? "inathneq_small":"alloy"]'>Он имеет доступ к <b>[GLOB.ratvar_awakens ? "INFINITE":GLOB.clockwork_vitality]</b> единицами жизненной силы.</span>"
		if(GLOB.ratvar_awakens)
			. += "<span class='inathneq_small'>Он может воскрешать Слуг совершенно бесплатно!</span>"
		else
			. += "<span class='inathneq_small'>Он может воскресить Слуг за <b>[revive_cost]</b> единиц жизненной силы.</span>"

/obj/effect/clockwork/sigil/vitality/sigil_effects(mob/living/L)
	if((is_servant_of_ratvar(L) && L.suiciding) || sigil_active)
		return
	animate(src, alpha = 255, time = 10, flags = ANIMATION_END_NOW) //we may have a previous animation going. finish it first, then do this one without delay.
	sleep(10)
//as long as they're still on the sigil and are either not a servant or they're a servant AND it has remaining vitality
	var/consumed_vitality
	while(L && (!is_servant_of_ratvar(L) || (is_servant_of_ratvar(L) && (GLOB.ratvar_awakens || GLOB.clockwork_vitality))) && get_turf(L) == get_turf(src) && !L.buckled)
		sigil_active = TRUE
		if(animation_number >= 4)
			new /obj/effect/temp_visual/ratvar/sigil/vitality(get_turf(src))
			animation_number = 0
		animation_number++
		if(!is_servant_of_ratvar(L))
			var/vitality_drained = 0
			if(L.stat == DEAD && !consumed_vitality && can_dust)
				consumed_vitality = TRUE //Prevent the target from being consumed multiple times
				vitality_drained = L.maxHealth
				var/obj/effect/temp_visual/ratvar/sigil/vitality/V = new /obj/effect/temp_visual/ratvar/sigil/vitality(get_turf(src))
				animate(V, alpha = 0, transform = matrix()*2, time = 8)
				playsound(L, 'sound/magic/wandodeath.ogg', 50, 1)
				L.visible_message("<span class='warning'>[L] сжимается в себя, когда [src] вспыхивает ярко-синим светом!</span>")
				to_chat(L, "<span class='inathneq_large'>\"[text2ratvar("Твоя жизнь не будет потрачена впустую.")]\"</span>")
				for(var/obj/item/W in L)
					if(!L.dropItemToGround(W))
						qdel(W)
				L.dust()
			else if(L.health > min_drain_health)
				if(!GLOB.ratvar_awakens && L.stat == CONSCIOUS)
					vitality_drained = L.adjustToxLoss(1, forced = TRUE, toxins_type = TOX_OMNI)
				else
					vitality_drained = L.adjustToxLoss(1.5, forced = TRUE, toxins_type = TOX_OMNI)
			if(vitality_drained)
				GLOB.clockwork_vitality += vitality_drained
			else
				break
		else
			if(L.stat == DEAD)
				var/revival_cost = revive_cost
				if(GLOB.ratvar_awakens || L.suiciding) // No cost if Ratvar is summoned or if you're reviving a convert who suicided
					revival_cost = 0
				var/mob/dead/observer/ghost = L.get_ghost(TRUE)
				if(GLOB.clockwork_vitality >= revival_cost && (ghost || (L.mind && L.mind.active)))
					if(L.has_status_effect(STATUS_EFFECT_ICHORIAL_STAIN))
						visible_message("<span class='boldwarning'>[src] напрягается, но ничего не происходит...</span>")
						if(L.pulledby)
							to_chat(L.pulledby, "<span class='userdanger'>[L] недавно уже был воскрешён с помощью матрицы жизненной силы! Подождите ещё немного!</span>")
						break
					else
						if(ghost)
							ghost.reenter_corpse()
						L.revive(1, 1)
						var/obj/effect/temp_visual/ratvar/sigil/vitality/V = new /obj/effect/temp_visual/ratvar/sigil/vitality(get_turf(src))
						animate(V, alpha = 0, transform = matrix()*2, time = 8)
						playsound(L, 'sound/magic/staff_healing.ogg', 50, 1)
						to_chat(L, "<span class='inathneq'>\"[text2ratvar("Все будет хорошо, дитя.")]\"</span>")
						L.apply_status_effect(STATUS_EFFECT_ICHORIAL_STAIN)
						GLOB.clockwork_vitality -= revival_cost
				break
			if(!L.client || L.client.is_afk())
				set waitfor = FALSE
				var/list/mob/candidates = pollCandidatesForMob("Do you want to play as a [L.name], an inactive clock cultist?", ROLE_SERVANT_OF_RATVAR, null, ROLE_SERVANT_OF_RATVAR, 50, L)
				if(LAZYLEN(candidates))
					var/mob/C = pick(candidates)
					to_chat(L, "<span class='userdanger'>Из-за вашей бездеятельности ваше тело захватила другая душа! Обратитесь за помощью к админам, если хотите вернуть себе тело!</span>")
					message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(L)]) to replace an inactive clock cultist.")
					L.ghostize(0)
					C.transfer_ckey(L, FALSE)
					var/obj/effect/temp_visual/ratvar/sigil/vitality/V = new /obj/effect/temp_visual/ratvar/sigil/vitality(get_turf(src))
					animate(V, alpha = 0, transform = matrix()*2, time = 8)
					playsound(L, 'sound/magic/staff_healing.ogg', 50, 1)
					L.visible_message("<span class='warning'>Глаза [L] внезапно широко раскрылись, засияв новой энергией в борьбе за дело!</span>", "<span class='inathneq'>\"[text2ratvar("Пробудись!")]\"</span>")
					break
			var/vitality_for_cycle = 3
			if(!GLOB.ratvar_awakens)
				if(L.stat == CONSCIOUS)
					vitality_for_cycle = 2
				vitality_for_cycle = min(GLOB.clockwork_vitality, vitality_for_cycle)
			var/vitality_used = L.heal_ordered_damage(vitality_for_cycle, damage_heal_order)

			if(!vitality_used)
				break

			if(!GLOB.ratvar_awakens)
				if(GLOB.clockwork_vitality <= 0)
					break
				GLOB.clockwork_vitality -= vitality_used

		sleep(2)

	if(sigil_active)
		animation_number = initial(animation_number)
		sigil_active = FALSE
	animate(src, alpha = initial(alpha), time = 10, flags = ANIMATION_END_NOW)

/obj/effect/clockwork/sigil/rite
	name = "radiant sigil"
	desc = "Сигил, сияющий едва сдерживаемой силой."
	clockwork_desc = "Сигил, с помощью которого вы сможете проводить определенные обряды, при условии, что у вас есть достаточный запас энергии и необходимые материалы."
	icon_state = "sigiltransmission" //am big lazy - recolored transmission sigil
	sigil_name = "Sigil of Rites"
	alpha = 255
	var/performing_rite = FALSE
	color = "#ffe63a"
	light_color = "#ffe63a"
	light_range = 1
	light_power = 2

/obj/effect/clockwork/sigil/rite/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!is_servant_of_ratvar(user))
		return
	if(!GLOB.all_clockwork_rites.len) //Did we already generate the list?
		generate_all_rites()
	if(performing_rite)
		to_chat(user, "<span class='warning'>Кто-то уже проводит ритуал здесь!</span>")
		return
	var/list/possible_rites = list()
	for(var/datum/clockwork_rite/R in GLOB.all_clockwork_rites)
		if(is_servant_of_ratvar(user, require_full_power = TRUE) || !R.requires_full_power)
			possible_rites[R] = R
	var/input_key = input(user, "Выберите ритуал", "Выбор ритуала") as null|anything in possible_rites
	if(!input_key)
		return
	var/datum/clockwork_rite/CR = possible_rites[input_key]
	if(!CR)
		return
	var/choice = alert(user, "Что делать с этим ритуалом?", "Что сделать?", "Применить", "Показать информацию", "Отмена")
	switch(choice)
		if("Применить")
			CR.try_cast(src, user)
		if("Показать информацию")
			var/infotext = CR.build_info()
			to_chat(user, infotext)

/obj/effect/clockwork/sigil/rite/proc/generate_all_rites() //The first time someone uses a sigil of rites, all the rites are actually generated. No need to have a bunch of random datums laying around all the time.
	for(var/V in subtypesof(/datum/clockwork_rite))
		var/datum/clockwork_rite/R = new V
		GLOB.all_clockwork_rites += R
