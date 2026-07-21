/datum/reagent/drug/heroinhydrochloride
	name = "Гидрохлорид диацетилморфина"
	description = "Шмурдячок"
	color = "#EFE5CB"
	reagent_state = LIQUID
	taste_description = "bitter"
	overdose_threshold = 20
	pH = 3.5
	addiction_threshold = 25
	metabolization_rate = 0.15
	metabolizing = FALSE

/datum/chemical_reaction/fermi/heroinhydrochloride
	name = "Гидрохлорид диацетилморфина"
	id = /datum/reagent/drug/heroinhydrochloride
	results = list(/datum/reagent/drug/heroinhydrochloride = 1)
	required_reagents = list(/datum/reagent/medicine/morphine = 2, /datum/reagent/medicine/sal_acid = 2, /datum/reagent/acetone = 2, /datum/reagent/toxin/acid/fluacid = 0.6)
	mix_message = "Смесь бурно реагирует, оставляя после себя мутноватый раствор молочного цвета."
	//FermiChem vars:
	OptimalTempMin 	= 500
	OptimalTempMax 	= 550
	ExplodeTemp 	= 800
	OptimalpHMin 	= 3
	OptimalpHMax 	= 6
	ReactpHLim 		= 3
	CurveSharpT 	= 1
	CurveSharppH 	= 1
	ThermicConstant = 5
	HIonRelease 	= 0.02
	RateUpLim 		= 1
	FermiChem		= TRUE
	PurityMin 		= 0.25


/datum/reagent/drug/heroinhydrochloride/on_mob_metabolize(mob/living/M)
	..()
	ADD_TRAIT(M, TRAIT_PAINKILLER, PAINKILLER_MORPHINE)
	M.throw_alert("painkiller", /atom/movable/screen/alert/painkiller)
	M.add_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))
	M.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 1)
	M.clear_fullscreen("depression", 1000)
	M.add_client_colour(/datum/client_colour/heroinhydrochloride)

/datum/reagent/drug/heroinhydrochloride/on_mob_end_metabolize(mob/living/M)
	M.remove_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))
	REMOVE_TRAIT(M, TRAIT_PAINKILLER, PAINKILLER_MORPHINE)
	M.clear_alert("painkiller", /atom/movable/screen/alert/painkiller)
	M.remove_client_colour(/datum/client_colour/heroinhydrochloride)
	..()

/datum/reagent/drug/heroinhydrochloride/on_mob_life(mob/living/carbon/M)
	..()

/datum/reagent/drug/heroinhydrochloride/overdose_process(mob/living/M)
	switch(current_cycle)
		if(12)
			to_chat(M, "<span class='warning'>Вы чувствуете себя устало...</span>" )
		if(24 to 48)
			M.drowsyness += 1
		if(96 to INFINITY)
			M.Sleeping(100, 0)
			. = 1
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(2)
		M.Jitter(2)
	..()

/datum/reagent/drug/heroinhydrochloride/addiction_act_stage1(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/drug/heroinhydrochloride/addiction_act_stage2(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(1*REM, 0)
		. = 1
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/drug/heroinhydrochloride/addiction_act_stage3(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REM, 0)
		. = 1
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/drug/heroinhydrochloride/addiction_act_stage4(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(3*REM, 0)
		. = 1
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/client_colour/heroinhydrochloride
	colour = list(rgb(190, 60, 60), rgb(60, 190, 60), rgb(60, 60, 190), rgb(0, 0, 0))
	priority = 6

/obj/item/reagent_containers/glass/bottle/heroinhydrochloride
	name = "Гидрохлорид диацетилморфина bottle"
	desc = "A small bottle of Гидрохлорид диацетилморфина."
	icon = 'icons/obj/chemical.dmi'
	list_reagents = list(/datum/reagent/drug/heroinhydrochloride = 30)

/datum/reagent/drug/heroin
	name = "Героин"
	description = "Сильный опиоид"
	color = "#d8cbab"
	reagent_state = LIQUID
	taste_description = "bitter"
	var/obj/effect/hallucination/simple/zavisimost/slova
	var/list/trip_types = list("prihod")
	overdose_threshold = 10
	addiction_threshold = 5
	metabolization_rate = 0.15
	metabolizing = FALSE

/datum/chemical_reaction/fermi/heroin
	name = "Героин"
	id = /datum/reagent/drug/heroin
	results = list(/datum/reagent/drug/heroin = 1, /datum/reagent/acetone = 1)
	required_reagents = list(/datum/reagent/drug/heroinhydrochloride = 1, /datum/reagent/consumable/ethanol = 3, /datum/reagent/medicine/charcoal = 1)
	mix_message = "После бурной реакции на дно выпадает осадок из порошка грязно-молочного цвета."
	//FermiChem vars:
	OptimalTempMin 	= 390
	OptimalTempMax 	= 450
	ExplodeTemp 	= 800
	OptimalpHMin 	= 8
	OptimalpHMax 	= 10
	ReactpHLim 		= 3
	CurveSharpT 	= 1
	CurveSharppH 	= 1
	ThermicConstant = 5
	HIonRelease 	= 0.02
	RateUpLim 		= 1
	FermiChem		= TRUE
	PurityMin 		= 0.50



/datum/reagent/drug/heroin/overdose_process(mob/living/M)
	if(prob(10))
		var/picked_option = rand(1,3)
		switch(picked_option)
			if(1)
				M.adjustToxLoss(rand(5,15), 0)
				. = TRUE
			if(2)
				M.losebreath += 10
				M.adjustOxyLoss(rand(5,15), 0)
				. = TRUE
			if(3)
				to_chat(M, "<b><big>Должно быть скоро все закончится...</big></b>")
				M.adjustOrganLoss(ORGAN_SLOT_HEART, 30)
				. = TRUE
	return ..() || .

/datum/reagent/drug/heroin/addiction_act_stage1(mob/living/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(min(mood.sanity, SANITY_DISTURBED))
	if(prob(10))
		M.emote(pick("twitch","shiver","frown"))
	..()

/datum/reagent/drug/heroin/addiction_act_stage2(mob/living/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(min(mood.sanity, SANITY_DISTURBED))
	M.Jitter(5)
	if(prob(20))
		create_zavisimost(M)
	if(prob(20))
		M.emote(pick("twitch","shiver","frown"))
	..()

/datum/reagent/drug/heroin/addiction_act_stage3(mob/living/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(min(mood.sanity, SANITY_UNSTABLE))
	ADD_TRAIT(M, TRAIT_UNSTABLE, type)
	M.Jitter(15)
	if(prob(50))
		create_zavisimost(M)
	if(prob(40))
		M.emote(pick("twitch","gasp","frown"))
	..()

/datum/reagent/drug/heroin/addiction_act_stage4(mob/living/carbon/human/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(SANITY_UNSTABLE)
	M.Jitter(20)
	if(prob(80))
		create_zavisimost(M)
	if(prob(10))
		M.losebreath+= 5
		M.adjustOxyLoss(5, 0)
	if(prob(50))
		M.emote(pick("twitch","drool", "gasp","realagony","frown"))
	..()
	. = 1




/datum/reagent/drug/heroin/on_mob_metabolize(mob/living/M)
	. = ..()

	M.add_client_colour(/datum/client_colour/heroin)
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "heroin", /datum/mood_event/heroin, name)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(SANITY_NEUTRAL)
	ADD_TRAIT(M, TRAIT_PAINKILLER, PAINKILLER_MORPHINE)
	M.throw_alert("painkiller", /atom/movable/screen/alert/painkiller)
	M.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 3)
	M.clear_fullscreen("depression", 3000)
	M.overlay_fullscreen("flash", /atom/movable/screen/fullscreen/tiled/flash)
	M.clear_fullscreen("flash", 60)
	shake_camera(M, 30, 1)
	SEND_SOUND(M, sound('modular_bluemoon/sound/hallucinations/heroin/PhotoFlash.ogg', volume = 100))
	var/sound/sound = sound(pick('modular_bluemoon/sound/hallucinations/heroin/HeroinRing1.ogg','modular_bluemoon/sound/hallucinations/heroin/HeroinRing2.ogg', \
	'modular_bluemoon/sound/hallucinations/heroin/HeroinRing3.ogg'), TRUE)
	sound.environment = 35
	sound.volume = 60
	SEND_SOUND(M.client, sound)
	M.sound_environment_override = SOUND_ENVIRONMENT_DRUGGED
	to_chat(M, "<span class='warning'>В ушах начинает сильно гудеть!</span>")
	M.Paralyze(15)

	..()
	. = 1

/datum/reagent/drug/heroin/on_mob_life(mob/living/M)
	if(prob(10))
		M.Jitter(35)
		SEND_SOUND(M, sound(pick('modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing.ogg', 'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing2.ogg', \
		'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing3.ogg','modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing4.ogg'), volume = 100))
		M.emote(pick("twitch","drool","moan","realagony","gasp"))
		M.overlay_fullscreen("prihod", /atom/movable/screen/fullscreen/heroin, rand(1, 6))
		M.clear_fullscreen("prihod", rand(15, 60))
	M.adjustStaminaLoss(5, 0)
	REMOVE_TRAIT(M, TRAIT_UNSTABLE, type)
	var/high_message = pick("Ты в полном порядке","Ты чувствуешь себя спокойно","Вся боль в твоей жизни ушла","Будто бы можно жить дальше","Хорошо","Нормально")
	if(prob(5))
		to_chat(M, span_notice("<i> ... [high_message] ... </i>"))
	..()

/datum/reagent/drug/heroin/on_mob_end_metabolize(mob/living/M)
	M.remove_client_colour(/datum/client_colour/heroin)
	REMOVE_TRAIT(M, TRAIT_PAINKILLER, PAINKILLER_MORPHINE)
	M.clear_alert("painkiller", /atom/movable/screen/alert/painkiller)
	DIRECT_OUTPUT(M.client, sound(null))
	to_chat(M, "<b><big>Обратно в этот гнилой мир...</big></b>")
	..()

/atom/movable/screen/fullscreen/heroin
	icon = 'modular_bluemoon/icons/screen/heroin_fullscreen.dmi'
	plane = SPLASHSCREEN_PLANE
	screen_loc = "CENTER-7,SOUTH"
	icon_state = ""

/datum/client_colour/heroin
	colour = list(rgb(255, 40, 40), rgb(40, 255, 40), rgb(40, 40, 255), rgb(0, 0, 0))
	priority = 6




/obj/effect/hallucination/simple/zavisimost
	name = "А-оо"
	desc = "НЕЕЕТ!"
	image_icon = 'modular_bluemoon/icons/effects/heroin_phrases.dmi'
	image_state = "eshe1"
	var/list/states = list("dose1", "dose2", "dose3", "eshe1", "eshe2", "eshe3", "need1", \
		"need2", "need3", "want1", "want2", "want3", "more1", "more2", "more3", \
		"dozu1", "dozu2", "dozu3", "dai1", "dai2", "vmaz", "proshu")

/datum/reagent/drug/heroin/proc/create_zavisimost(mob/living/carbon/M)
	for(var/turf/T in orange(14,M))
		if(prob(3))
			if(!(locate(slova) in T.contents))
				slova = new(T, M)

/obj/effect/hallucination/simple/zavisimost/New(turf/location_who_cares_fuck, mob/living/carbon/M, forced = TRUE)
	image_state = pick(states)
	. = ..()
	SpinAnimation(rand(5, 40), TRUE, prob(50))
	pixel_x = (rand(-16, 16))
	pixel_y = (rand(-16, 16))
	animate(src, color = color_matrix_rotate_hue(rand(0, 360)), transform = matrix()*rand(1,3), time = 200, pixel_x = rand(-64,64), pixel_y = rand(-64,64), easing = CIRCULAR_EASING)
	QDEL_IN(src, rand(40, 200))




/datum/mood_event/heroin
	mood_change = 3
	timeout = 3600

/datum/mood_event/heroin/add_effects(param)
	description = "<span class='boldwarning'>Мне хорошо.</span>\n"




/obj/item/reagent_containers/syringe/heroin
	name = "syringe (heroin)"
	desc = "Contains heroin - a strong opioid."
	list_reagents = list(/datum/reagent/drug/heroin = 15)


/obj/item/reagent_containers/pill/powder_heroin
	name = "Героин"
	desc = "Горстка порошка грязно-молочного цвета. "
	icon = 'modular_bluemoon/icons/obj/moredrugs.dmi'
	icon_state = "heroinpowder"
	volume = 10
	list_reagents = list(/datum/reagent/drug/heroin = 10)

/datum/chemical_reaction/powder_heroin
	is_cold_recipe = TRUE
	required_reagents = list(/datum/reagent/drug/heroin = 10)
	results = list()
	required_temp = 250
	mix_message = "Смесь кристаллизируется, застывает и формируется в порошочек грязно-молочного цвета."

/datum/chemical_reaction/powder_heroin/on_reaction(datum/reagents/holder, created_volume)
	var/location = get_turf(holder.my_atom)
	for(var/i in 1 to created_volume)
		new /obj/item/reagent_containers/pill/powder_heroin(location)


/obj/item/reagent_containers/pill/powder_heroin/proc/snort(mob/living/user)
	if(!iscarbon(user))
		return
	var/covered = ""
	if(user.is_mouth_covered(ITEM_SLOT_HEAD))
		covered = "headgear"
	else if(user.is_mouth_covered(ITEM_SLOT_MASK))
		covered = "mask"
	if(covered)
		to_chat(user, span_warning("You have to remove your [covered] first!"))
		return
	var/snort_message = pick("снюхивает","пылесосит носом","долбит по ноздре","вмазывает")
	user.visible_message(span_notice("[user] [snort_message] [src]."))
	if(do_after(user, 30, src))
		to_chat(user, span_notice("You finish snorting the [src]."))
		if(user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
			playsound(user, pick('sound/voice/sniff_f1.ogg'), 50, 1)
		else
			playsound(user, pick('sound/voice/sniff_m1.ogg'), 50, 1)
		if(reagents.total_volume)
			reagents.trans_to(user, reagents.total_volume)
		qdel(src)


/obj/item/reagent_containers/pill/powder_heroin/MouseDrop_T(mob/target, mob/user)
	if(user.stat || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target))
		return

	snort(target)

	return
