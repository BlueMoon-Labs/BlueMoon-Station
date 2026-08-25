#define SPECIES_DIONA "diona"
#define SPECIES_DIONA_POD "diomorph"
#define RAD_EAT_AMOUNT 4
#define RAD_EAT_MESSAGE_PROB 10
#define NYMPH_DEATH_MIN 2
#define NYMPH_DEATH_MAX 3
#define PESTICIDE_TOX_DAMAGE 6
#define DIONA_REGROW_LIGHT 0.4
#define DIONA_REGROW_DELAY 6 MINUTES
#define DIONA_SHOE_SLOWDOWN 0.6
/// Сколько кровотока в тик закрывает фотосинтез при свете и сытости
#define DIONA_WOUND_SAP_FLOW 0.5
/// Сколько повреждений плоти/заражения снимает за тик лечение соками
#define DIONA_WOUND_SAP_FLESH 0.5
/// Базовое число тиков "срастания" на единицу тяжести перелома
#define DIONA_WOUND_MEND_BASE 60
/// Сколько урона органа (включая глаза) лечит за тик лечение соками
#define DIONA_ORGAN_SAP_HEAL 0.5

/datum/species/diona
	name = "Diona"
	id = SPECIES_DIONA
	say_mod = "chirps"
	default_color = "59CE00"
	heatmod = 3
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/plant
	exotic_blood_color = BLOOD_COLOR_PLANT
	damage_overlay_type = "human"
	attack_verb = "claw"
	attack_sound = 'sound/weapons/slice.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	liked_food = VEGETABLES | FRUIT | GRAIN
	disliked_food = MEAT | DAIRY
	species_traits = list(MUTCOLORS, EYECOLOR, CAN_SCAR, HAS_FLESH, HAS_BONE, HAIR)
	inherent_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mutant_bodyparts = list(
		"mcolor" = "59CE00",
		"mcolor2" = "59CE00",
		"mcolor3" = "59CE00",
		"mam_tail" = "None",
		"mam_ears" = "None",
		"mam_snouts" = "None",
		"insect_wings" = "None",
		"deco_wings" = "None",
		"horns" = "None",
		"taur" = "None",
		"mam_body_markings" = list()
	)
	tail_type = "mam_tail"
	wagging_type = "mam_waggingtail"
	override_bp_icon = 'modular_bluemoon/diona/icons/mob/human_parts_diona.dmi'
	limbs_id = SPECIES_DIONA
	mutant_brain = /obj/item/organ/brain/diona
	mutant_heart = /obj/item/organ/heart/diona
	mutantlungs = /obj/item/organ/lungs/diona
	mutantliver = /obj/item/organ/liver/diona
	mutantappendix = /obj/item/organ/appendix/diona
	mutanteyes = /obj/item/organ/eyes/diona
	species_language_holder = /datum/language_holder/diona
	languagewhitelist = list("Rootsong")
	species_category = SPECIES_CATEGORY_PLANT
	speedmod = 1.25
	inherent_traits = list(CAN_BE_OPERATED_WITHOUT_PAIN, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)

	var/pod_grown = FALSE

/datum/species/diona/random_name(gender, unique, lastname)
	var/new_name = "[pick(list("To Sleep Beneath", "Wind Over", "Embrace of", "Dreams of", "Witnessing", "To Walk Beneath", "Approaching the", "Song of"))]"
	new_name += " [pick(list("the Void", "the Sky", "Encroaching Night", "Planetsong", "Starsong", "the Wandering Star", "the Empty Day", "Daybreak", "Nightfall", "the Rain"))]"
	return new_name

/datum/species/diona/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.faction |= "plants"
	C.faction |= "vines"
	C.AddElement(/datum/element/photosynthesis, -1, -1, -1, -1, 10, 0.5, 0.2, -1000)
	var/datum/language_holder/LH = C.get_language_holder()
	LH.grant_language(/datum/language/rootsong, SPOKEN_LANGUAGE|UNDERSTOOD_LANGUAGE, LANGUAGE_ATOM)
	C.AddElement(/datum/element/diona_regrowth, DIONA_REGROW_DELAY)
	C.grant_ability_from_source(list(INNATE_ABILITY_HUMANOID_CUSTOMIZATION), ABILITY_SOURCE_SPECIES)

/datum/species/diona/on_species_loss(mob/living/carbon/C)
	. = ..()
	if(QDELETED(C) || QDELING(C))
		return .
	C.faction -= "plants"
	C.faction -= "vines"
	C.RemoveElement(/datum/element/photosynthesis, -1, -1, -1, -1, 10, 0.5, 0.2, -1000)
	var/datum/language_holder/LH = C.get_language_holder()
	if(LH)
		LH.remove_language(/datum/language/rootsong, ALL, LANGUAGE_ATOM)
	C.RemoveElement(/datum/element/diona_regrowth, DIONA_REGROW_DELAY)
	C.remove_ability_from_source(list(INNATE_ABILITY_HUMANOID_CUSTOMIZATION), ABILITY_SOURCE_SPECIES)

/datum/species/diona/on_hit(obj/item/projectile/P, mob/living/carbon/human/H)
	switch(P.type)
		if(/obj/item/projectile/energy/floramut)
			P.nodamage = TRUE
			H.DefaultCombatKnockdown(1 SECONDS)
			if(prob(80))
				H.easy_randmut(NEGATIVE + MINOR_NEGATIVE)
			else
				H.easy_randmut(POSITIVE)
			H.domutcheck()
			H.visible_message(span_warning("[H] корчится, пока нимфы внутри извиваются и мутируют."), span_userdanger("Вы все неприятно извиваетесь, ощущая, как меняются ваши гены!"))
		if(/obj/item/projectile/energy/florayield)
			P.nodamage = TRUE
			H.heal_overall_damage(5, 5)
			H.visible_message(span_notice("[H] словно наполняется силой, когда [P] попадает в его тело."), span_notice("Твоё тело жадно впитывает [P]."))
	return ..()

/datum/species/diona/spec_life(mob/living/carbon/human/H)
	if(H.stat == DEAD)
		return
	if(H.GetComponent(/datum/component/nanites))
		H.adjustToxLoss(0.17)
		if(prob(5))
			to_chat(H, span_noticealien("Инородные организмы в моем теле воспринимаются как паразиты, мне нужно их уничтожить.. Они мне вредят"))
	if(H.nutrition < NUTRITION_LEVEL_STARVING + 50)
		H.take_overall_damage(2, 0)
	if(H.shoes)
		H.add_movespeed_modifier(/datum/movespeed_modifier/diona_shoes)
	else
		H.remove_movespeed_modifier(/datum/movespeed_modifier/diona_shoes)

/datum/species/diona/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(istype(chem, /datum/reagent/toxin/plantbgone))
		H.adjustToxLoss(PESTICIDE_TOX_DAMAGE)
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
		return TRUE
	if(istype(chem, /datum/reagent/medicine))
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
		return TRUE
	switch(chem.type)
		if(/datum/reagent/nitrogen)
			H.adjustFireLoss(-2 * REM)
			H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
			return TRUE
		if(/datum/reagent/phosphorus)
			H.adjustBruteLoss(-2 * REM)
			H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
			return TRUE
		if(/datum/reagent/diethylamine, /datum/reagent/water)
			H.adjust_nutrition(2 * REM, NUTRITION_LEVEL_WELL_FED)
			H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
			return TRUE
		if(/datum/reagent/blood)
			H.adjustCloneLoss(-2 * REM)
			H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
			return TRUE
	return ..()

/datum/species/diona/handle_mutations_and_radiation(mob/living/carbon/human/H)
	var/radiation = H.radiation
	if(radiation <= 0)
		return TRUE
	H.radiation = max(radiation - RAD_EAT_AMOUNT, 0)
	H.adjust_nutrition(RAD_EAT_AMOUNT * 2, NUTRITION_LEVEL_WELL_FED)
	H.adjustBruteLoss(-RAD_EAT_AMOUNT * 0.5)
	H.adjustFireLoss(-RAD_EAT_AMOUNT * 0.5)
	if(prob(RAD_EAT_MESSAGE_PROB))
		to_chat(H, span_notice("Ты чувствуешь разливающееся по коре тепло, впитывая радиацию."))
	return TRUE

/datum/species/diona/spec_death(gibbed, mob/living/carbon/human/H)
	if(gibbed)
		return ..()
	var/turf/T = get_turf(H)
	H.visible_message(span_danger("[H] распадается с тихим скрипом, обнажая клубок извивающихся дионных нимф!"))
	playsound(T, 'modular_bluemoon/diona/sound/diona_crunch.ogg', 60, TRUE)
	for(var/mob/living/simple_animal/diona_nymph/inner in H.contents)
		inner.split(forced = TRUE)
	var/list/spawned = list()
	for(var/i in 1 to rand(NYMPH_DEATH_MIN, NYMPH_DEATH_MAX))
		spawned += new /mob/living/simple_animal/diona_nymph(T)
	if(H.mind)
		var/mob/living/simple_animal/diona_nymph/heir = pick(spawned)
		heir.name = "diona nymph ([H.real_name])"
		heir.real_name = heir.name
		if(H.vocal_bark_id)
			heir.set_bark(H.vocal_bark_id)
		heir.vocal_speed = H.vocal_speed
		heir.vocal_pitch = H.vocal_pitch
		heir.vocal_pitch_range = H.vocal_pitch_range
		H.mind.transfer_to(heir)
		log_game("Разум [key_name(H)] переселился в нимфу-наследника при смерти в [AREACOORD(T)].")
		to_chat(heir, span_noticealien("Отголоски твоего расщепившегося сознания собираются в одном маленьком теле. Ты выжил — в каком-то смысле."))
	else
		poll_ghost_for_nymph(pick(spawned))
	H.dust(TRUE, TRUE)
	return TRUE

/datum/species/diona/pod
	name = "Diomorph"
	id = SPECIES_DIONA_POD
	pod_grown = TRUE

/datum/movespeed_modifier/diona_shoes
	multiplicative_slowdown = DIONA_SHOE_SLOWDOWN

/datum/element/diona_regrowth
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	var/regrow_delay = DIONA_REGROW_DELAY
	var/list/next_regrowth
	var/list/regen_started
	/// Моб -> ассоц-лист (рана -> накопленные тики срастания перелома)
	var/list/mend_progress

/datum/element/diona_regrowth/Attach(datum/target, delay)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE || !isliving(target))
		return ELEMENT_INCOMPATIBLE
	regrow_delay = delay
	if(!next_regrowth)
		next_regrowth = list()
	if(!regen_started)
		regen_started = list()
	if(!mend_progress)
		mend_progress = list()
	START_PROCESSING(SSobj, src)
	next_regrowth[target] = 0
	regen_started[target] = FALSE

/datum/element/diona_regrowth/Detach(datum/target)
	if(next_regrowth)
		next_regrowth -= target
	if(regen_started)
		regen_started -= target
	if(mend_progress)
		mend_progress -= target
	if(next_regrowth && !length(next_regrowth))
		STOP_PROCESSING(SSobj, src)
		next_regrowth = null
		regen_started = null
		mend_progress = null
	return ..()

/datum/element/diona_regrowth/process()
	if(!next_regrowth || !regen_started)
		return
	for(var/atom/movable/AM as anything in next_regrowth)
		if(!next_regrowth)
			break
		if(QDELETED(AM) || !isliving(AM))
			next_regrowth -= AM
			regen_started -= AM
			mend_progress -= AM
			continue
		var/mob/living/carbon/human/H = AM
		if(H.stat == DEAD)
			continue
		var/light_amount = 0
		if(isturf(H.loc))
			var/turf/T = H.loc
			light_amount = T.get_lumcount()
		var/light_ok = light_amount >= DIONA_REGROW_LIGHT
		var/nourished = H.nutrition >= NUTRITION_LEVEL_WELL_FED || H.reagents?.has_reagent(/datum/reagent/water)
		if(light_ok && nourished)
			mend_wounds(H)
			mend_organs(H)
		if(!next_regrowth || !(AM in next_regrowth))
			continue
		if(world.time < next_regrowth[AM])
			continue
		// Для роста конечности нужны ВСЕ условия сразу: и свет, и питание/вода.
		if(!light_ok || !nourished)
			if(regen_started[AM])
				to_chat(H, span_warning("Соки отливают от раны — рост конечности приостановлен."))
				regen_started[AM] = FALSE
			continue
		var/missing_zone = null
		for(var/zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD))
			if(!H.get_bodypart(zone))
				missing_zone = zone
				break
		if(!missing_zone)
			regen_started[AM] = FALSE
			continue
		if(!regen_started[AM])
			regen_started[AM] = TRUE
			next_regrowth[AM] = world.time + regrow_delay
			to_chat(H, span_notice("Ты чувствуешь, как соки стекают к ране — утраченная конечность начала медленно расти заново."))
			continue
		H.regenerate_limb(missing_zone)
		H.visible_message(span_notice("На месте утраченной конечности [H] проклёвывается свежий побег."), span_notice("Новая конечность полностью сформировалась."))
		regen_started[AM] = FALSE
		next_regrowth[AM] = world.time + regrow_delay

/**
 * Медленное заживление ран соками: требуется и свет (DIONA_REGROW_LIGHT), и питание
 * (сытость либо вода в организме). Порезы и колотые раны просто теряют кровоток -
 * их собственный процесс довершает свёртывание и понижение тяжести. Ожоги теряют
 * повреждения плоти и заражение. Переломы копят прогресс и срастаются сами,
 * по тем же правилам неспешности, что и отращивание конечностей.
 */
/datum/element/diona_regrowth/proc/mend_wounds(mob/living/carbon/human/H)
	var/list/finished_mends
	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		if(BP.is_robotic_limb())
			continue
		for(var/datum/wound/W as anything in BP.wounds)
			if(istype(W, /datum/wound/slash))
				var/datum/wound/slash/cut = W
				if(cut.blood_flow <= 0)
					continue
				cut.blood_flow = max(cut.blood_flow - DIONA_WOUND_SAP_FLOW, 0)
				BP.update_part_wound_overlay()
				if(prob(10))
					to_chat(H, span_notice("Соки стекаются к ране на [BP.ru_name_v], медленно затягивая её."))
			else if(istype(W, /datum/wound/pierce))
				var/datum/wound/pierce/puncture = W
				if(puncture.blood_flow <= 0)
					continue
				puncture.blood_flow = max(puncture.blood_flow - DIONA_WOUND_SAP_FLOW, 0)
				BP.update_part_wound_overlay()
				if(prob(10))
					to_chat(H, span_notice("Соки стекаются к ране на [BP.ru_name_v], медленно затягивая её."))
			else if(istype(W, /datum/wound/burn))
				var/datum/wound/burn/scorch = W
				var/mended = FALSE
				if(scorch.flesh_damage > 0)
					scorch.flesh_damage = max(scorch.flesh_damage - DIONA_WOUND_SAP_FLESH, 0)
					mended = TRUE
				if(scorch.infestation > 0)
					scorch.infestation = max(scorch.infestation - DIONA_WOUND_SAP_FLESH, 0)
					mended = TRUE
				if(mended && prob(10))
					to_chat(H, span_notice("Обожжённая кора на [BP.ru_name_v] размягчается и нарастает заново."))
			else if(istype(W, /datum/wound/blunt))
				if(mend_bone(H, W, BP))
					LAZYADD(finished_mends, W)
	for(var/datum/wound/W as anything in finished_mends)
		log_wound(H, W)
		W.remove_wound()

/**
 * Медленное восстановление органов соками, включая глаза-узлы: те же условия,
 * что и для ран - свет и питание. Лечит и отказавшие органы: отрицательный
 * applyOrganDamage() сам снимает флаг ORGAN_FAILING.
 */
/datum/element/diona_regrowth/proc/mend_organs(mob/living/carbon/human/H)
	for(var/obj/item/organ/O in H.internal_organs)
		if(O.organ_flags & ORGAN_SYNTHETIC)
			continue
		if(O.damage <= 0)
			continue
		O.applyOrganDamage(-DIONA_ORGAN_SAP_HEAL)
		if(prob(3))
			to_chat(H, span_notice("Ты чувствуешь разливающееся тепло - соки восстанавливают твои внутренние органы."))

/**
 * Срастание переломов/вывихов силами самого растения. Скорость привязана к
 * регенерации конечностей: базовые DIONA_WOUND_MEND_BASE тиков SSobj (2 сек.)
 * за каждую ступень тяжести, т.е. вывих ~4 минуты, тяжёлый перелом ~6,
 * открытый ~8 минут при свете и сытости. Возвращает TRUE, когда рана полностью
 * срослась и её можно снять (снятие - вне цикла по списку ран).
 */
/datum/element/diona_regrowth/proc/mend_bone(mob/living/carbon/human/H, datum/wound/blunt/W, obj/item/bodypart/BP)
	var/list/my_mends = mend_progress[H]
	if(!my_mends)
		my_mends = list()
		mend_progress[H] = my_mends
	var/progress = my_mends[W] + 1
	my_mends[W] = progress
	if(progress == 1)
		to_chat(H, span_notice("Нимфы в глубине твоей [BP.ru_name] принимаются стягивать разошедшиеся волокна, заполняя трещины свежей древесиной."))
		return FALSE
	if(progress < DIONA_WOUND_MEND_BASE * W.severity)
		if(prob(5))
			to_chat(H, span_notice("Повреждение в твоей [BP.ru_name] потрескивает, срастаясь под напором соков..."))
		return FALSE
	my_mends -= W
	if(!length(my_mends))
		mend_progress -= H
	to_chat(H, span_green("Волокна твоей [BP.ru_name] сплелись заново — повреждение больше не грозит тебе!"))
	return TRUE

#undef RAD_EAT_AMOUNT
#undef RAD_EAT_MESSAGE_PROB
#undef NYMPH_DEATH_MIN
#undef NYMPH_DEATH_MAX
#undef DIONA_WOUND_SAP_FLOW
#undef DIONA_WOUND_SAP_FLESH
#undef DIONA_WOUND_MEND_BASE
#undef DIONA_ORGAN_SAP_HEAL
