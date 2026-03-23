/datum/surgery
	var/name = "surgery"
	var/desc = "surgery description"
	var/status = 1
	var/list/steps = list()									//Steps in a surgery
	var/step_in_progress = 0								//Actively performing a Surgery
	var/can_cancel = 1										//Can cancel this surgery after step 1 with cautery
	var/list/target_mobtypes = list(/mob/living/carbon/human)		//Acceptable Species
	var/location = BODY_ZONE_CHEST							//Surgery location
	var/requires_bodypart_type = BODYPART_ORGANIC			//Prevents you from performing an operation on incorrect limbs. 0 for any limb type
	var/list/possible_locs = list() 						//Multiple locations
	var/ignore_clothes = 0									//This surgery ignores clothes
	var/mob/living/carbon/target							//Operation target mob
	var/obj/item/bodypart/operated_bodypart					//Operable body part
	var/requires_bodypart = TRUE							//Surgery available only when a bodypart is present, or only when it is missing.
	var/success_multiplier = 0								//Step success propability multiplier
	var/requires_real_bodypart = 0							//Some surgeries don't work on limbs that don't really exist
	var/lying_required = TRUE								//Does the vicitm needs to be lying down.
	var/requires_tech = FALSE
	var/replaced_by
	var/datum/wound/operated_wound							//The actual wound datum instance we're targeting
	var/datum/wound/targetable_wound						//The wound type this surgery targets
	var/is_healing = TRUE									//BLUEMOON ADD || Is this healing operation or improving/other
	var/icon = 'icons/obj/surgery.dmi'						//BLUEMOON ADD || icon file for radial menu
	var/icon_state = "scalpel"								//BLUEMOON ADD || icon state for radial menu
	var/radial_priority = SURGERY_RADIAL_PRIORITY			//BLUEMOON ADD || icon state for radial menu

	var/list/special_surgery_traits = list() // BLUEMOON ADD - наши особые трейты для операции

/datum/surgery/New(surgery_target, surgery_location, surgery_bodypart)
	..()
	if(surgery_target)
		target = surgery_target
		target.surgeries += src
		if(surgery_location)
			location = surgery_location
		if(surgery_bodypart)
			operated_bodypart = surgery_bodypart
			if(targetable_wound)
				operated_wound = operated_bodypart.get_wound_type(targetable_wound)
				operated_wound.attached_surgery = src

/datum/surgery/Destroy()
	if(operated_wound)
		operated_wound.attached_surgery = null
	if(target)
		target.surgeries -= src
	target = null
	operated_bodypart = null
	return ..()


/datum/surgery/proc/can_start(mob/user, mob/living/patient, obj/item/tool) //FALSE to not show in list
	. = TRUE
	if(replaced_by == /datum/surgery)
		return FALSE

	if(HAS_TRAIT(user, TRAIT_SURGEON) || HAS_TRAIT(user.mind, TRAIT_SURGEON))
		if(replaced_by)
			return FALSE
		else
			return TRUE

	if(!requires_tech && !replaced_by)
		return TRUE
	// True surgeons (like abductor scientists) need no instructions

	if(requires_tech)
		. = FALSE

	var/list/advanced_surgeries = list()
	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user
		var/obj/item/surgical_processor/SP = locate() in R.module.modules
		if(SP)
			advanced_surgeries |= SP.advanced_surgeries
	else
		var/obj/item/surgical_processor/SP
		for(var/obj/item/surgical_processor/processor in user.held_items)
			SP = processor
			break
		if(!SP)
			SP = locate(/obj/item/surgical_processor) in get_turf(user)
		if(SP)
			advanced_surgeries |= SP.advanced_surgeries

	var/turf/T = get_turf(patient)
	var/obj/structure/table/optable/table = locate(/obj/structure/table/optable, T)
	if(table?.computer && !(table.computer.machine_stat & (NOPOWER|BROKEN)))
		advanced_surgeries |= table.computer.advanced_surgeries

	if(istype(tool, /obj/item/surgical_drapes/advanced))
		var/obj/item/surgical_drapes/advanced/A = tool
		advanced_surgeries |= A.get_advanced_surgeries()

	if(HAS_TRAIT(user.mind, TRAIT_KNOW_MED_SURGERY_T2))
		advanced_surgeries |= KNOW_MED_SURGERY_OPERATIONS

	if(replaced_by in advanced_surgeries)
		return FALSE
	if(type in advanced_surgeries)
		return TRUE

/datum/surgery/proc/next_step(mob/user, intent)
	if(step_in_progress)
		return TRUE

	var/try_to_fail = FALSE
	if(intent == INTENT_DISARM)
		try_to_fail = TRUE

	var/datum/surgery_step/S = get_surgery_step()
	if(S)
		var/obj/item/tool = user.get_active_held_item()
		if(istype(tool, /obj/item/stack/medical/mesh))
			var/obj/item/stack/medical/mesh/T = tool
			if(!T.is_open)
				//to_chat(user, span_warning("Вам нужно вскрыть упаковку, прежде чем приступать к операции!"))
				return
		if(S.try_op(user, target, user.zone_selected, tool, src, try_to_fail))
			return TRUE
		if((tool && tool.item_flags & SURGICAL_TOOL) || (S.stop_implements && (S.implement_type in S.implements))) //Just because you used the wrong tool it doesn't mean you meant to whack the patient with it
			/* BLUERMOON REMOVAL START - перенесено в try_op
			to_chat(user, "<span class='warning'>This step requires a different tool!</span>")
			/ BLUEMOON REMOVAL END */
			return TRUE

/datum/surgery/proc/get_surgery_step()
	var/step_type = steps[status]
	return new step_type

/datum/surgery/proc/get_surgery_next_step()
	if(status < steps.len)
		var/step_type = steps[status + 1]
		return new step_type
	else
		return null

/datum/surgery/proc/complete()
	SSblackbox.record_feedback("tally", "surgeries_completed", 1, type)
	qdel(src)

// Use silent = TRUE to avoid affecting the target
/datum/surgery/proc/get_propability_multiplier(silent = TRUE)
	var/propability = 0.5
	var/turf/T = get_turf(target)

	//It is important that the value with the highest chance is always on top.
	var/static/list/prop_sources = list(
		/obj/structure/table/optable/abductor 	= 1,
		/obj/structure/table/optable           	= 0.5,
		/obj/machinery/stasis                  	= 0.4,
		/obj/structure/bed/roller             	= 0.35,
		/obj/structure/table                   	= 0.3,
		/obj/structure/bed                     	= 0.1
		)

	for (var/path in prop_sources)
		if (locate(path, T))
			propability += prop_sources[path]
			break

	// BLUEMOON ADDITION AHEAD - сверх-большие персонажи ломают собой столы. Поблажка, дабы с ними всё ещё можно было проводить нормально операции
	if(target.mob_weight > MOB_WEIGHT_HEAVY)
		propability = max(propability, 0.8)

	// Шансы на операции в зависимости от состояния пациента
	var/check_for_painkillers = FALSE
	var/check_for_pain = FALSE
	var/pain_propability_debuff = 0
	var/surgeon_requirments_debuff = 0
	if(ishuman(target))
		var/mob/living/carbon/human/patient = target
		if(!HAS_TRAIT(patient, CAN_BE_OPERATED_WITHOUT_PAIN) && !isbloodfledge(patient)) // на некоторых расах операцию можно проводить без дебафов

			var/in_conscious = !(patient.IsSleeping() || patient.stat >= 2 || patient.IsUnconscious()) // убого, при этом, если не провряется что-то из заявленного, были моменты "пробуждения" пациента
/*
			if(patient.stat == DEAD && patient.timeofdeath + 50 SECONDS > world.time) // персонаж погиб И это было недавно (нужно для предотвращения убийства-и-немедленной-операции)
				patient.visible_message(span_warning("[patient] погиб менее минуты назад, тело ещё напряжено от трупного спазма и его намного сложнее оперировать!"), vision_distance = 1)
				pain_propability_debuff -= 0.5
*/
			if(!in_conscious) // без сознания или уже в гост-чате
				// Нет штрафов
			else if(patient.IsParalyzed() || patient.IsStun()) // не может совершать сложные движения, но всё ещё минимальная мимика присутствует
				pain_propability_debuff -= 0.2
				check_for_painkillers = TRUE
				check_for_pain = TRUE
			else if(patient.handcuffed || istype(patient.wear_suit, /obj/item/clothing/suit/straight_jacket)) // в сознании, может двигаться, но скован наручниками или смерительной рубашкой
				pain_propability_debuff -= 0.4
				check_for_painkillers = TRUE
				check_for_pain = TRUE
			else // пациент в сознании, не скован
				pain_propability_debuff -= 0.6 // Операция на полу без обезбола - гарантированный провал без химии и другой помощи
				check_for_painkillers = TRUE
				check_for_pain = TRUE

			if(check_for_painkillers)
				if(HAS_TRAIT(patient, TRAIT_BLUEMOON_FEAR_OF_SURGEONS))
					pain_propability_debuff -= 0.2 // пациент ЕЩЁ СИЛЬНЕЕ дёргается на месте
					if(!silent && prob(20))
						if(HAS_TRAIT(patient, TRAIT_PAINKILLER))
							to_chat(patient, span_danger("ОБЕЗБОЛИВАЮЩЕЕ НЕ ПОМОГАЕТ, ЭТО УЖАСНО! ДАЙТЕ МНЕ АНЕСТЕЗИЮ!"))
						else
							to_chat(patient, span_danger("ЭТО УЖАСНО! Я НЕ МОГУ ЭТО ВЫНЕСТИ! ДАЙТЕ МНЕ АНЕСТЕЗИЮ!"))
				else if(IS_IN_STASIS(patient) || HAS_TRAIT(patient, TRAIT_PAINKILLER))
					pain_propability_debuff = 0
					check_for_pain = FALSE
					if(!silent)
						SEND_SIGNAL(patient, COMSIG_ADD_MOOD_EVENT, "surgery_pain", /datum/mood_event/surgery_pain/painkiller)
						if(prob(5))
							to_chat(patient, span_warning(pick(
								"Меня оперируют без анестезии... Не по себе от этого.", "А что чувствует доктор, когда режет меня?", \
								"Что если доктор сделает что-то не так? Я что-то почувствую?", "Боюсь подумать, что это было бы без наркоза.", \
								"Я вообще ничего не чувствую там, где меня оперируют...", "У меня онемение, я ничего не чувствую в месте операции!")))
				else if(HAS_TRAIT(patient, TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD))
					pain_propability_debuff = max(0, min(pain_propability_debuff + 0.2, 0))
					check_for_pain = FALSE
					if(!silent)
						switch(rand(1,4))
							if(1)
								patient.blur_eyes(5)
							if(2)
								patient.Dizzy(15)
							if(3)
								patient.stuttering = max(patient.stuttering, 10)
							if(4)
								patient.Jitter(20) // 4 секунды всего
						if(patient.mind?.active) // игрок в игре
							if(prob(15))
								patient.emote("me", EMOTE_VISIBLE, pick(list(\
								"сжимает зубы от боли.", "жмурится и рычит, сжимая зубы.", \
								"жмурится, пока по щеке стекает слеза от боли.", "что-то бубнит про себя, пробуя отвлечься от ощущений при операции.", \
								"коротко мычит, терпя боль", "цепляется за поверхность рядом, терпя боль.")))
							if(prob(10))
								patient.say(pick("Мнгх...", "Ххх...", "Пхх...", "Хррр...", "Нгхх..."))
						SEND_SIGNAL(patient, COMSIG_ADD_MOOD_EVENT, "surgery_pain", /datum/mood_event/surgery_pain/lesser)
				else if(patient.drunkenness > 20)
					pain_propability_debuff += 0.2
					if(!silent)
						patient.visible_message(span_notice("[patient] явно в опьянении. Это помогает облегчить боль."), vision_distance = 1)

			// специальные проверки для некоторых операций
			if(special_surgery_traits.len)
				if((OPERATION_NEED_FULL_ANESTHETIC in special_surgery_traits) && in_conscious) // пациент в сознания и операция это требует
					surgeon_requirments_debuff -= 0.5
					if(!silent && prob(30))
						if(IS_IN_STASIS(patient) || HAS_TRAIT(patient, TRAIT_PAINKILLER))
							patient.visible_message(span_warning("[patient] под обезболивающим. Это помогает облегчить операцию, но он всё ещё слегка двигается, что затрудняет операцию."), span_notice("Я под обезболивающим... Но кажется, всё равно слегка двигаюсь и мешаю этим врачу при операции."), vision_distance = 1)

				if(OPERATION_MUST_BE_PERFORMED_AWAKE in special_surgery_traits && !in_conscious) // пациент без сознании и операция это требует
					surgeon_requirments_debuff -= 0.5

			// операция наживую, очень больно
			if(!silent && check_for_pain && in_conscious)
				// сердечный приступ от боли
				if(prob(1)) // С учётом кучи проваленных попыток, это серьезный шанс
					if(!patient.undergoing_cardiac_arrest())
						patient.visible_message(span_danger("[patient] несколько раз дёргается перед тем, как замереть в скрюченной позе... [patient.ru_who(TRUE)] не дышит!"), span_big_warning("СЕРДЦЕ! БОЛЬ В ГРУДИ..."))
						patient.set_heartattack(TRUE)
						patient.set_dizziness(0) // перестаём дрожать

				patient.Jitter(50)
				patient.Dizzy(100)
				patient.stuttering = max(patient.stuttering, 20)
				patient.adjustStaminaLoss(40)
				patient.blur_eyes(20)
				if(HAS_TRAIT(patient, TRAIT_BLUEMOON_FEAR_OF_SURGEONS))
					SEND_SIGNAL(patient, COMSIG_ADD_MOOD_EVENT, "surgery_pain", /datum/mood_event/surgery_pain/trait)
				else
					SEND_SIGNAL(patient, COMSIG_ADD_MOOD_EVENT, "surgery_pain", /datum/mood_event/surgery_pain)

				if(patient.mind?.active) // если игрока нет в игре и проигрываются кастомные эмоуты, то игра выдаёт SQL ошибки
					if(prob(50))
						to_chat(patient, span_big_warning(pick(\
							"ГОСПОДИ, КАК ЖЕ БОЛЬНО!", "ЗВЁЗДЫ, МЕНЯ РЕЖУТ НАЖИВУЮ!", "УБЕЙТЕ МЕНЯ, Я НЕ ВЫНЕСУ!", "Я ХОЧУ ЖИТЬ! ПОМОГИТЕ!", "УБЕРИТЕ ИХ ОТ МЕНЯ!", \
							"УБЛЮДОК! ТВАРЬ! КАК ЖЕ БОЛЬНО!", "АААГХ!", "АААААА!", "ПОМОГИТЕ, Я НЕ МОГУ!", "СПАСИТЕ, МЕНЯ РЕЖУТ!", "АААААААААААА!")))
					switch(rand(1,10))
						if(1 to 8)
							if(prob(50))
								patient.say(pick("AAA!!", "АААХ!!", "ААГХ!!"))
								patient.emote("me", EMOTE_VISIBLE, pick(list(\
									"елозит и кричит от боли!", "выгибается и кричит от агонии!", "трясётся и кричит от боли!", "дрожит и вскрикивает от боли!", \
									"кричит от боли!", "елозит на месте и кричит от боли!", "жмурится и вопит в агонии!")))
							else
								patient.emote(pick("realagony", "scream"))
						if(9 to 10)
							patient.emote("cry")
				else if(prob(40))
					patient.emote(pick("realagony", "scream", "cry"))

	propability += pain_propability_debuff + surgeon_requirments_debuff
	// BLUEMOON ADDITION END
	return propability + success_multiplier + (target.sterilize_power / 100)

/datum/surgery/advanced
	name = "advanced surgery"
	requires_tech = TRUE

/obj/item/disk/surgery
	name = "Surgery Procedure Disk"
	desc = "A disk that contains advanced surgery procedures, must be loaded into an Operating Console."
	icon_state = "datadisk1"
	custom_materials = list(/datum/material/iron=300, /datum/material/glass=100)
	var/list/surgeries

/obj/item/disk/surgery/debug
	name = "Debug Surgery Disk"
	desc = "A disk that contains all existing surgery procedures."
	icon_state = "datadisk1"
	custom_materials = list(/datum/material/iron=300, /datum/material/glass=100)

/obj/item/disk/surgery/debug/Initialize(mapload)
	. = ..()
	surgeries = list()
	var/list/req_tech_surgeries = subtypesof(/datum/surgery)
	for(var/i in req_tech_surgeries)
		var/datum/surgery/beep = i
		if(initial(beep.requires_tech))
			surgeries += beep

//INFO
//Check /mob/living/carbon/attackby for how surgery progresses, and also /mob/living/carbon/attack_hand.
//As of Feb 21 2013 they are in code/modules/mob/living/carbon/carbon.dm, lines 459 and 51 respectively.
//Other important variables are var/list/surgeries (/mob/living) and var/list/internal_organs (/mob/living/carbon)
// var/list/bodyparts (/mob/living/carbon/human) is the LIMBS of a Mob.
//Surgical procedures are initiated by attempt_initiate_surgery(), which is called by surgical drapes and bedsheets.


//TODO
//specific steps for some surgeries (fluff text)
//more interesting failure options
//randomised complications
//more surgeries!
//add a probability modifier for the state of the surgeon- health, twitching, etc. blindness, god forbid.
//helper for converting a zone_sel.selecting to body part (for damage)


//RESOLVED ISSUES //"Todo" jobs that have been completed
//combine hands/feet into the arms - Hands/feet were removed - RR
//surgeries (not steps) that can be initiated on any body part (corresponding with damage locations) - Call this one done, see possible_locs var - c0
