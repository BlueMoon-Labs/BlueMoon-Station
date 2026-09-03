#define GESTALT_ALERT "gestalt screen alert"
#define NYMPH_ALERT "nymph screen alert"
#define NYMPH_EVOLVE_NUTRITION 500
#define NYMPH_EVOLVE_DONORS 3
#define BLOOD_SAMPLE_DELAY 1 SECONDS

/proc/isdiona(mob/target)
	var/mob/living/carbon/human/H = target
	return istype(H) && istype(H.dna?.species, /datum/species/diona)

/mob/living/simple_animal/diona_nymph
	name = "diona nymph"
	desc = "Маленькая составляющая коллективного разума дионы-гештальта."
	icon = 'modular_bluemoon/diona/icons/mob/nymph.dmi'
	icon_state = "nymph"
	icon_living = "nymph"
	icon_dead = "nymph_dead"
	pass_flags = PASSTABLE | PASSMOB
	mob_biotypes = MOB_ORGANIC
	mob_size = MOB_SIZE_SMALL
	initial_language_holder = /datum/language_holder/diona
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxHealth = 50
	health = 50
	speed = 1
	dextrous = TRUE
	held_items = list(null, null)
	wander = TRUE
	stop_automated_movement_when_pulled = TRUE
	speak_chance = 5
	speak_emote = list("chirrups")
	emote_hear = list("chirrups.")
	emote_see = list("chirrups.")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	melee_damage_lower = 5
	melee_damage_upper = 8
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	harm_intent_damage = 3

	var/list/donors = list()
	var/datum/action/innate/diona_nymph/merge/merge_action
	var/datum/action/innate/diona_nymph/evolve/evolve_action
	var/datum/action/innate/diona_nymph/steal_blood/steal_blood_action
	var/static/list/edible_types = list(/obj/item/reagent_containers/food/snacks/grown)

/obj/item/carry_nymph
	name = "diona nymph"
	desc = "Маленькая нимфа дионы, устроившаяся на руках."
	icon = 'modular_bluemoon/diona/icons/mob/nymph.dmi'
	icon_state = "nymph"
	w_class = WEIGHT_CLASS_SMALL
	var/mob/living/simple_animal/diona_nymph/nymph

/obj/item/carry_nymph/Initialize(mapload)
	. = ..()
	if(nymph)
		name = nymph.name

/obj/item/carry_nymph/Destroy()
	if(nymph && !QDELETED(nymph))
		release(get_turf(src))
	return ..()

/obj/item/carry_nymph/dropped(mob/user, silent = FALSE)
	. = ..()
	if(!QDELETED(src) && nymph && !QDELETED(nymph))
		release(get_turf(src))
		qdel(src)

/obj/item/carry_nymph/attack_self(mob/user)
	release(get_turf(src))
	user.dropItemToGround(src)
	qdel(src)

/obj/item/carry_nymph/proc/release(turf/T)
	if(!nymph || QDELETED(nymph))
		nymph = null
		return
	var/mob/living/simple_animal/diona_nymph/N = nymph
	nymph = null
	N.forceMove(T || get_turf(src))

/mob/living/simple_animal/diona_nymph/Initialize(mapload)
	. = ..()
	if(name == initial(name))
		name = "[name] ([rand(1, 1000)])"
		real_name = name
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	merge_action = new(src)
	evolve_action = new(src)
	steal_blood_action = new(src)
	merge_action.Grant(src)
	evolve_action.Grant(src)
	steal_blood_action.Grant(src)

/mob/living/simple_animal/diona_nymph/death(gibbed)
	if(istype(loc, /obj/item/carry_nymph))
		var/obj/item/carry_nymph/HI = loc
		HI.release(get_turf(src))
	playsound(get_turf(src), 'modular_bluemoon/diona/sound/nymphchirp.ogg', 40, TRUE)
	..(gibbed)

/datum/action/innate/diona_nymph
	name = "Nymph Action"
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'modular_bluemoon/diona/icons/mob/nymph_alerts.dmi'

/datum/action/innate/diona_nymph/merge
	name = "Слиться с гештальтом"
	button_icon_state = "nymph"

/datum/action/innate/diona_nymph/merge/Trigger()
	var/mob/living/simple_animal/diona_nymph/N = owner
	N.merge()

/datum/action/innate/diona_nymph/evolve
	name = "Эволюционировать"
	button_icon_state = "gestalt"

/datum/action/innate/diona_nymph/evolve/Trigger()
	var/mob/living/simple_animal/diona_nymph/N = owner
	N.evolve()

/datum/action/innate/diona_nymph/steal_blood
	name = "Украсть кровь"
	button_icon_state = "nymph_dead"

/datum/action/innate/diona_nymph/steal_blood/Trigger()
	var/mob/living/simple_animal/diona_nymph/N = owner
	N.steal_blood()

/mob/living/simple_animal/diona_nymph/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(stat != CONSCIOUS)
		return ..()
	if(isdiona(A) && loc == A)
		visible_message(span_notice("[src] слегка извивается."))
		return
	if(proximity && is_type_in_list(A, edible_types))
		consume_plant(A)
		return
	return ..()

/mob/living/simple_animal/diona_nymph/proc/consume_plant(obj/item/reagent_containers/food/snacks/grown/plant)
	if(nutrition >= NYMPH_EVOLVE_NUTRITION)
		to_chat(src, span_warning("Ты слишком сыт, чтобы есть это! Может, пора подрасти..."))
		return
	var/found = FALSE
	for(var/datum/reagent/R in plant.reagents?.reagent_list)
		if(R.name in list("nutriment", "plantmatter", "vitamin"))
			found = TRUE
			adjust_nutrition(R.volume * 2, NYMPH_EVOLVE_NUTRITION)
	if(!found)
		adjust_nutrition(2, NYMPH_EVOLVE_NUTRITION)
	visible_message(span_notice("[src] грызёт [plant]."))
	playsound(get_turf(src), 'modular_bluemoon/diona/sound/diona_crunch.ogg', 30, TRUE)
	qdel(plant)

/mob/living/simple_animal/diona_nymph/attack_hand(mob/living/carbon/human/M)
	if(M.a_intent == INTENT_HELP && stat != DEAD)
		if(isdiona(M))
			do_merge(M)
			return
		if(!M.get_active_held_item())
			pickup_by(M)
			return
	..()

/mob/living/simple_animal/diona_nymph/proc/pickup_by(mob/living/carbon/human/M)
	if(M.incapacitated() || istype(loc, /obj/item/carry_nymph))
		return
	var/obj/item/carry_nymph/holder_item = new(get_turf(src))
	holder_item.nymph = src
	forceMove(holder_item)
	holder_item.name = name
	if(!M.put_in_hands(holder_item))
		holder_item.release(get_turf(src))
		qdel(holder_item)
		return
	to_chat(M, span_notice("Ты аккуратно берёшь [src] на руки."))
	to_chat(src, span_notice("[M] бережно берёт тебя на руки."))

/mob/living/simple_animal/diona_nymph/proc/merge()
	if(stat != CONSCIOUS || istype(loc, /obj/item/carry_nymph))
		return FALSE
	var/list/choices = list()
	for(var/mob/living/carbon/human/H in view(1, src))
		if(!Adjacent(H) || !isdiona(H) || H.stat == DEAD)
			continue
		choices += H
	if(!length(choices))
		to_chat(src, span_warning("Рядом нет подходящей дионы."))
		return FALSE
	var/mob/living/carbon/human/target = tgui_input_list(src, "С кем ты хочешь слиться?", "Слияние нимфы", choices)
	if(QDELETED(src) || !target || !Adjacent(target) || stat != CONSCIOUS)
		return FALSE
	if(isdiona(target))
		return do_merge(target)
	return FALSE

/mob/living/simple_animal/diona_nymph/proc/do_merge(mob/living/carbon/human/target)
	if(stat != CONSCIOUS || !istype(target) || QDELETED(target) || target.stat == DEAD)
		return FALSE
	if(loc == target)
		return TRUE
	to_chat(target, "Ты чувствуешь, как твоё существо сплетается с существом [src], вливающимся в твою биомассу.")
	to_chat(src, "Ты чувствуешь, как твоё существо сплетается с существом [target], когда ты вливаешься в его биомассу.")
	log_game("[key_name(src)] слился с гештальтом [key_name(target)] в [AREACOORD(src)].")
	forceMove(target)
	throw_alert("[GESTALT_ALERT]-[REF(src)]", /atom/movable/screen/alert/nymph, new_master = src)
	target.throw_alert("[NYMPH_ALERT]-[REF(src)]", /atom/movable/screen/alert/gestalt, new_master = src)
	return TRUE

/mob/living/simple_animal/diona_nymph/proc/split(forced = FALSE)
	if((stat != CONSCIOUS && !forced) || !isdiona(loc))
		return FALSE
	var/mob/living/carbon/human/host = loc
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	to_chat(host, "Ты чувствуешь укол утраты, когда [src] отделяется от твоей биомассы.")
	to_chat(src, "Ты выползаешь из глубин биомассы [host] и шлёпаешься на землю.")
	forceMove(T)
	host.clear_alert("[NYMPH_ALERT]-[REF(src)]")
	clear_alert("[GESTALT_ALERT]-[REF(src)]")
	return TRUE

/mob/living/simple_animal/diona_nymph/proc/steal_blood()
	if(stat != CONSCIOUS)
		return FALSE
	var/list/choices = list()
	for(var/mob/living/carbon/human/H in oview(1, src))
		if(Adjacent(H) && H.dna && !(NOBLOOD in H.dna.species.species_traits))
			choices += H
	if(!length(choices))
		to_chat(src, span_warning("Рядом нет подходящих доноров крови."))
		return FALSE
	var/mob/living/carbon/human/target = tgui_input_list(src, "У кого взять пробу крови?", "Забор крови", choices)
	if(QDELETED(src) || !target || !Adjacent(target) || stat != CONSCIOUS)
		return FALSE
	if(!target.dna || (NOBLOOD in target.dna.species.species_traits))
		to_chat(src, span_warning("У этого донора нечего брать."))
		return FALSE
	to_chat(target, span_warning("Ты чувствуешь лёгкий укол — [src] берёт пробу твоей крови!"))
	if(!do_after(src, BLOOD_SAMPLE_DELAY, target))
		to_chat(src, span_warning("Ты не смог удержать усик на доноре."))
		return FALSE
	if(donors.Find(target.real_name))
		to_chat(src, span_warning("Этот донор больше не даст тебе ничего нового."))
		return FALSE
	visible_message(span_danger("[src] выбрасывает усик и ловко забирает пробу крови [target]."), span_danger("Ты выбрасываешь усик и ловко забираешь пробу крови [target]."))
	donors += target.real_name
	log_game("[key_name(src)] взял пробу крови у [key_name(target)] в [AREACOORD(src)].")
	var/datum/language_holder/target_holder = target.get_language_holder()
	var/datum/language_holder/my_holder = get_language_holder()
	for(var/lang_type in target_holder.spoken_languages)
		my_holder.grant_language(lang_type, SPOKEN_LANGUAGE|UNDERSTOOD_LANGUAGE, LANGUAGE_ALL)
	addtimer(CALLBACK(src, PROC_REF(update_progression)), 2.5 SECONDS)
	return TRUE

/mob/living/simple_animal/diona_nymph/proc/update_progression()
	if(QDELETED(src) || stat != CONSCIOUS || !length(donors))
		return
	if(length(donors) >= NYMPH_EVOLVE_DONORS)
		to_chat(src, span_noticealien("Ты чувствуешь готовность перейти на следующую ступень роста."))
	else
		to_chat(src, span_noticealien("Кровь впитывается в твою маленькую форму, наполняя формирующийся разум отголосками чужих воспоминаний и личностей."))

/mob/living/simple_animal/diona_nymph/proc/evolve()
	if(stat != CONSCIOUS)
		return FALSE
	if(istype(loc, /obj/item/carry_nymph))
		var/obj/item/carry_nymph/HI = loc
		HI.release(get_turf(HI))
	if(length(donors) < NYMPH_EVOLVE_DONORS)
		to_chat(src, span_warning("Тебе нужно больше крови, чтобы подняться на новую ступень сознания..."))
		return FALSE
	if(nutrition < NYMPH_EVOLVE_NUTRITION)
		to_chat(src, span_warning("Тебе нужно наесться растений, чтобы набрать силы для роста. Питание: [nutrition]/[NYMPH_EVOLVE_NUTRITION]."))
		return FALSE
	if(isdiona(loc) && !split())
		return FALSE
	var/turf/spawn_turf = get_turf(loc)
	if(!spawn_turf)
		return FALSE
	visible_message(span_danger("[src] начинает дрожать и корчиться, взрываясь ливнем сброшенной коры, и распадается на клубок почти из дюжины новых дионей."), span_danger("Ты начинаешь дрожать, ощущая, как твоё осознание раскалывается. Разом мы поглощаем запасённые питательные вещества, устремляясь в рост. Мы обрели форму гештальта."))
	playsound(spawn_turf, 'modular_bluemoon/diona/sound/diona_crunch.ogg', 60, TRUE)
	var/mob/living/carbon/human/adult = new(spawn_turf)
	adult.set_species(/datum/species/diona)
	var/datum/language_holder/my_holder = get_language_holder()
	var/datum/language_holder/adult_holder = adult.get_language_holder()
	for(var/lang_type in my_holder.spoken_languages)
		adult_holder.grant_language(lang_type, ALL, LANGUAGE_MIND)
	if(vocal_bark_id)
		adult.set_bark(vocal_bark_id)
	adult.vocal_speed = vocal_speed
	adult.vocal_pitch = vocal_pitch
	adult.vocal_pitch_range = vocal_pitch_range
	adult.real_name = adult.dna.species.random_name(MALE, FALSE)
	adult.name = adult.real_name
	if(mind)
		mind.transfer_to(adult)
	else
		transfer_ckey(adult, FALSE)
	log_game("[key_name(src)] эволюционировал в диону-гештальт [key_name(adult)] в [AREACOORD(src)].")
	clear_alert("[GESTALT_ALERT]-[REF(src)]")
	qdel(src)
	return TRUE

/atom/movable/screen/alert/nymph
	name = "Часть гештальта"
	desc = "Ты слился с дионой-гештальтом. Кликни или сопротивляйся, чтобы выбраться."
	icon = 'modular_bluemoon/diona/icons/mob/nymph_alerts.dmi'
	icon_state = "nymph"
	clickable_glow = TRUE

/atom/movable/screen/alert/gestalt
	name = "Нимфа в биомассе"
	desc = "Диона-нимфа слилась с твоей биомассой. Кликни, чтобы выдавить её."
	icon = 'modular_bluemoon/diona/icons/mob/nymph_alerts.dmi'
	icon_state = "gestalt"
	clickable_glow = TRUE

/atom/movable/screen/alert/nymph/Click(location, control, params)
	if(master_ref)
		var/mob/living/simple_animal/diona_nymph/N = master_ref.resolve()
		if(istype(N) && !QDELETED(N) && isdiona(N.loc))
			N.split()
			return
	return ..()

/atom/movable/screen/alert/gestalt/Click(location, control, params)
	if(master_ref)
		var/mob/living/simple_animal/diona_nymph/N = master_ref.resolve()
		if(istype(N) && !QDELETED(N))
			N.split()
			return
	return ..()

/mob/living/simple_animal/diona_nymph/resist()
	if(isdiona(loc))
		split()
		return
	if(istype(loc, /obj/item/carry_nymph))
		var/obj/item/carry_nymph/holder_item = loc
		var/turf/T = get_turf(holder_item)
		holder_item.release(T)
		to_chat(src, span_notice("Ты спрыгиваешь с рук и оказываешься на земле."))
		qdel(holder_item)
		return
	..()

/proc/poll_ghost_for_nymph(mob/living/simple_animal/diona_nymph/nymph)
	set waitfor = FALSE
	var/list/candidates = pollCandidatesForMob("Диона-нимфа отделилась от своего гештальта. Стать ею?", null, null, 0, 15 SECONDS, nymph)
	if(QDELETED(nymph) || !length(candidates))
		return
	var/mob/chosen = pick(candidates)
	if(!chosen?.key || QDELETED(nymph))
		return
	nymph.key = chosen.key

#undef GESTALT_ALERT
#undef NYMPH_ALERT
#undef NYMPH_EVOLVE_NUTRITION
#undef NYMPH_EVOLVE_DONORS
#undef BLOOD_SAMPLE_DELAY
