
/*

CONTAINS:
T-RAY
HEALTH ANALYZER
GAS ANALYZER
SLIME SCANNER
NANITE SCANNER
GENETICS SCANNER

*/

// Describes the three modes of scanning available for health analyzers
#define SCANMODE_HEALTH		0
#define SCANMODE_CHEMICAL 	1
#define SCANMODE_WOUND	 	2
#define SCANNER_CONDENSED 	0
#define SCANNER_VERBOSE 	1

/obj/item/t_scanner
	name = "\improper T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	custom_price = PRICE_REALLY_CHEAP
	icon = 'icons/obj/device.dmi'
	icon_state = "t-ray0"
	var/on = FALSE
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	custom_materials = list(/datum/material/iron=150)

/obj/item/t_scanner/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to emit terahertz-rays into [user.ru_ego()] brain with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return TOXLOSS

/obj/item/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = copytext_char(icon_state, 1, -1) + "[on]"

	if(on)
		START_PROCESSING(SSobj, src)

/obj/item/t_scanner/process()
	if(!on)
		STOP_PROCESSING(SSobj, src)
		return null
	scan()

/obj/item/t_scanner/proc/scan()
	t_ray_scan(loc)

/proc/t_ray_scan(mob/viewer, flick_time = 8, distance = 3)
	if(!ismob(viewer) || !viewer.client)
		return
	var/list/t_ray_images = list()
	for(var/obj/O in orange(distance, viewer) )
		if(O.level != 1)
			continue

		if(O.invisibility == INVISIBILITY_MAXIMUM)
			var/image/I = new(loc = get_turf(O))
			var/mutable_appearance/MA = new(O)
			MA.alpha = 128
			MA.dir = O.dir
			I.appearance = MA
			t_ray_images += I
	if(t_ray_images.len)
		flick_overlay(t_ray_images, list(viewer.client), flick_time)

/obj/item/healthanalyzer
	name = "health analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "health"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "Ручной сканер тела с функцией анализа показателей здоровья пациента."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)
	var/mode = 1
	var/scanmode = SCANMODE_HEALTH
	var/advanced = FALSE
	// BLUEMOON EDIT START - изменение анализатора здоровья
	var/last_msg = ""
	var/last_recipient_name = ""
	var/last_scan_time = ""
	var/browser_mode = FALSE
	// BLUEMOON EDIT END

/obj/item/healthanalyzer/Initialize(mapload)
	. = ..()

	register_item_context()

/obj/item/healthanalyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] анализирует свое состояние с помощью [src]! Интерфейс показывает что [user.ru_who()] - мертв[user.ru_aya()]!</span>")
	return BRUTELOSS

/obj/item/healthanalyzer/attack_self(mob/user)
	scanmode = (scanmode + 1) % 3
	switch(scanmode)
		if(SCANMODE_HEALTH)
			to_chat(user, "<span class='notice'>Вы переключаете анализатор в режим отображения физического состояния пациента.</span>")
		if(SCANMODE_CHEMICAL)
			to_chat(user, "<span class='notice'>Вы переключаете анализатор в режим отображения химикатов в теле пациента.</span>")
		if(SCANMODE_WOUND)
			to_chat(user, "<span class='notice'>Вы переключаете анализатор в режим отображения дополнительной информации о повреждениях.</span>")

// BLUEMOON ADD START - изменение сканеров здоровья
/obj/item/healthanalyzer/examine(mob/user)
	. = ..()
	. += "\n"
	scanmode = scanmode % 3
	switch(scanmode)
		if(SCANMODE_HEALTH)
			. += span_notice("Сканер в режиме отображения физического состояния пациента. Вы можете переключать режимы, <b>используя сканер в руке</b>.")
		if(SCANMODE_CHEMICAL)
			. += span_notice("Сканер в режиме отображения химикатов в теле пациента. Вы можете переключать режимы, <b>используя сканер в руке.</b>")
		if(SCANMODE_WOUND)
			. += span_notice("Сканер в режиме отображения дополнительной информации о повреждениях. Вы можете переключать режимы, <b>используя сканер в руке.</b>")
	. += span_notice("Режим \"крупным планом\" [browser_mode ? "ВКЛЮЧЕН" : "ВЫКЛЮЧЕН"]. Вы можете переключить его, использовав <b>Alt-Click</b>!")
	if(last_msg)
		. += span_notice("Сканер содержит запись: \"[last_recipient_name]-[last_scan_time]\" Вы можете просмотртеть его, использовав <b>Ctrl-Click</b>!")
	if(advanced)
		. += span_notice("Сканер был улучшен и может проводить более глубокий анализ.")


/obj/item/healthanalyzer/AltClick(mob/user)
	. = ..()
	var/mob/living/carbon/clicker = user
	if(!istype(clicker) || !clicker.canUseTopic(src, BE_CLOSE))
		return
	browser_mode = !browser_mode
	to_chat(clicker, span_notice("Вы переключаете режим \"крупным планом\" в состояние [browser_mode ? "ВКЛЮЧЕНО" : "ВЫКЛЮЧЕНО"]."))

/obj/item/healthanalyzer/CtrlClick(mob/user)
	. = ..()
	var/mob/living/carbon/clicker = user
	if(!istype(clicker) || !clicker.canUseTopic(src, BE_CLOSE))
		return
	if(!last_msg)
		to_chat(clicker, span_warning("В анализаторе отсутствуют сохранённые данные!"))
		return
	var/to_chat_msg = last_msg
	if(advanced)
		to_chat_msg += "<center><a href='?src=[REF(src)];print_scan=1;subject_name=[last_recipient_name];time=[last_scan_time]'>Распечатать</a></center>"
	if(browser_mode)
		to_chat_msg = replacetext(to_chat_msg, "\n", "<br>") // Чтобы нормально переносилось
		to_chat_msg = replacetext(to_chat_msg, "color='#0000CC'", "color='#13ace3'") // На тёмном фоне плохо видно
		var/datum/browser/popup = new(user, "healthscan", "Сканирование [last_recipient_name]", 600, 900)
		popup.set_content(to_chat_msg)
		popup.open()
	else
		to_chat(user, examine_block(to_chat_msg))
// BLUEMOON ADD END

/obj/item/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)
	flick("[icon_state]-scan", src)	//makes it so that it plays the scan animation upon scanning, including clumsy scanning

	// Clumsiness/brain damage check
	if ((HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_TRAIT(user, TRAIT_DUMB)) && prob(50))
		user.visible_message("<span class='warning'>[user] анализирует состояние пола!</span>", \
							"<span class='notice'>Вы по-идиотски пытаетесь анализировать пол!</span>")
		to_chat(user, "<span class='info'>Анализ состояния:\n\tОбщее состояние: <b>Здоров</b></span>\
					\n<span class='info'>Тип: <font color='blue'>Удушение</font>/<font color='green'>Токсины</font>/<font color='#FF8000'>Ожоги</font>/<font color='red'>Травмы</font></span>\
					\n<span class='info'>\tПоказатели урона: <font color='blue'>0</font>-<font color='green'>0</font>-<font color='#FF8000'>0</font>-<font color='red'>0</font></span>\
					\n<span class='info'>Температура тела: ???</span>")
		return

	user.visible_message("<span class='notice'>[user] анализирует показатели персонажа [M].</span>", \
						"<span class='notice'>Вы анализируете показатели персонажа [M].</span>")

	if(scanmode == SCANMODE_HEALTH)
		healthscan(user, M, mode, advanced, src)
		playsound(src, 'sound/rig/shortbeep.ogg', 50, 1, 1)
	else if(scanmode == SCANMODE_CHEMICAL)
		chemscan(user, M)
	else
		woundscan(user, M, src)

	add_fingerprint(user)

/obj/item/healthanalyzer/add_item_context(
	obj/item/source,
	list/context,
	atom/target,
)
	if (!isliving(target))
		return NONE

	switch (scanmode)
		if (SCANMODE_HEALTH)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Scan health")
		if (SCANMODE_CHEMICAL)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Scan chemicals")
		if (SCANMODE_WOUND)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Scan wounds")

	return CONTEXTUAL_SCREENTIP_SET

// Used by the PDA medical scanner too
/proc/healthscan(mob/user, mob/living/M, mode = 1, advanced = FALSE, obj/item/healthanalyzer/connected_analyzer = null)
	if(isliving(user) && (user.incapacitated() || user.eye_blind))
		return
	//Damage specifics
	var/oxy_loss = M.getOxyLoss()
	var/tox_loss = M.getToxLoss()
	var/fire_loss = M.getFireLoss()
	var/brute_loss = M.getBruteLoss()
	var/mob_status = (M.stat == DEAD ? "<span class='alert'><b>Мертв[M.ru_a()]</b></span>" : "<b>[round(M.health/M.maxHealth,0.01)*100] %</b>")

	if(HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced)
		if(iszombie(M))
			mob_status = "<span class='alert'><b>Неизвестный</b></span>"
			oxy_loss = (rand(0, 100) - (tox_loss + fire_loss + brute_loss))
			tox_loss = (rand(0, 100) - (oxy_loss + fire_loss + brute_loss))
			fire_loss = (rand(0, 100) - (oxy_loss + tox_loss + brute_loss))
			brute_loss = (rand(0, 100) - (oxy_loss + tox_loss + fire_loss))
		else if(!iszombie(M))
			mob_status = "<span class='alert'><b>Мертв[M.ru_a()]</b></span>"
			oxy_loss = max(rand(1, 40), oxy_loss, (300 - (tox_loss + fire_loss + brute_loss))) // Random oxygen loss

	// BLUEMOON EDIT START - изменение анализаторов здоровья
	var/msg = ""
	var/scan_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	msg += "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8'><title>Сканирование [M] от [scan_time]</title></head>"
	msg += "<span class='info'><center><b>\[[scan_time]\]</b></center>\nРезультаты анализа субъекта - <b>[M]</b>:\n\tОбщее состояние: [mob_status]</span>"
	// BLUEMOON EDIT END

	// Damage descriptions
	if(brute_loss > 10)
		msg += "\n<span class='alert'>Обнаружены [brute_loss > 50 ? "серьёзные" : "незначительные"] травмы.</span>"
	if(fire_loss > 10)
		msg += "\n<span class='alert'>Обнаружены [fire_loss > 50 ? "серьёзные" : "незначительные"] ожоги.</span>"
	if(oxy_loss > 10)
		msg += "\n<span class='info'><span class='alert'>Обнаружено [oxy_loss > 50 ? "серьёзное" : "незначительное"] кислородное голодание.</span>"
	if(tox_loss > 10)
		msg += "\n<span class='alert'>Обнаружено [tox_loss > 50 ? "серьёзное" : "незначительное"] [HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM) ? "повреждение системы" : "отравление токсинами"].</span>"
	if(M.getStaminaLoss())
		msg += "\n<span class='alert'>Субъект имеет признаки усталости.</span>"
		if(advanced)
			msg += "\n<span class='info'>Степень усталости: [M.getStaminaLoss()]%.</span>"
	if (M.getCloneLoss())
		msg += "\n<span class='alert'>Обнаружены [M.getCloneLoss() > 30 ? "серьёзные" : "незначительные"] повреждения цепей ДНК.</span>"
		if(advanced)
			msg += "\n<span class='info'>Степень повреждения ДНК: [M.getCloneLoss()].</span>"
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(advanced && H.has_dna() && !HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON CHANGES - у синтетиков нет генетической стабильности
			msg += "\n\t<span class='info'>Генетическая стабильность: [H.dna.stability]%.</span>" // BLUEMOON TODO - а чё это вообще

	// Body part damage report
	var/list/dmgreport = list()
	if(iscarbon(M) && mode == 1)
		var/mob/living/carbon/C = M
		var/list/damaged = C.get_damaged_bodyparts(1,1)
		if(length(damaged)>0 || oxy_loss>0 || tox_loss>0 || fire_loss>0)
			dmgreport += "<table><tr><font face='Verdana'>\
							<td style='width: 90px;'><font color='#0000CC'>Повреждения:</font></td>\
							<td style='width: 55px;'><font color='red'><b>Травмы</b></font></td>\
							<td style='width: 45px;'><font color='orange'><b>Ожоги</b></font></td>\
							<td style='width: 45px;'><font color='green'><b>[HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "Коррозия" :"Токсины"]</b></font></td>\
							<td style='width: 90px;'><font color='purple'><b>Удушение</b></font></td></tr>\
							<tr><td><font color='#0000CC'>Всего:</font></td>\
							<td><font color='red'>[brute_loss]</font></td>\
							<td><font color='orange'>[fire_loss]</font></td>\
							<td><font color='green'>[tox_loss]</font></td>\
							<td><font color='purple'>[oxy_loss]</font></td></tr>"

			for(var/o in damaged)
				var/obj/item/bodypart/org = o //head, left arm, right arm, etc.
				dmgreport += "<tr><td><font color='#0000CC'>[capitalize(org.ru_name)]:</font></td>\
								<td><font color='red'>[(org.brute_dam > 0) ? "[org.brute_dam]" : "0"]</font></td>\
								<td><font color='orange'>[(org.burn_dam > 0) ? "[org.burn_dam]" : "0"]</font></td></tr>"
			dmgreport += "</table>"
			msg += "\n[dmgreport.Join()]"

	msg += "\n"

	//Organ damages report
	var/heart_ded = FALSE
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/mob/living/carbon/human/H = M
		for(var/organ in C.internal_organs)
			var/temp_message
			var/damage_message
			var/obj/item/organ/O = organ

			//EYES
			if(istype(O, /obj/item/organ/eyes))
				var/obj/item/organ/eyes/eyes = O
				if(advanced)
					if(HAS_TRAIT(C, TRAIT_BLIND))
						temp_message += " <span class='alert'>Субъект слепой.</span>"
					if(HAS_TRAIT(C, TRAIT_NEARSIGHT))
						temp_message += " <span class='alert'>Субъект страдает от близорукости.</span>"
					if(eyes.damage > 30)
						damage_message += " <span class='alert'>Субъект имеет серьезные повреждения глаз.</span>"
					else if(eyes.damage > 20)
						damage_message += " <span class='alert'>Субъект имеет имеет повреждения глаз.</span>"
					else if(eyes.damage)
						damage_message += " <span class='alert'>Субъект имеет незначительные повреждения глаз.</span>"


			//EARS
			else if(istype(O, /obj/item/organ/ears))
				var/obj/item/organ/ears/ears = O
				if(advanced)
					if(HAS_TRAIT_FROM(C, TRAIT_DEAF, GENETIC_MUTATION))
						temp_message += " <span class='alert'>Субъект генетически глухой.</span>"
					else if(HAS_TRAIT(C, TRAIT_DEAF))
						temp_message += " <span class='alert'>Субъект глухой.</span>"
					else
						if(ears.damage)
							damage_message += " <span class='alert'>Субъект имеет [ears.damage > ears.maxHealth ? "постоянные ": "временные "] повреждения барабанных перепонок.</span>"
						if(ears.deaf)
							damage_message += " <span class='alert'>Субъект [ears.damage > ears.maxHealth ? "навечно ": "временно "] оглох.</span>"


			//BRAIN
			else if(istype(O, /obj/item/organ/brain))
				if (C.getOrganLoss(ORGAN_SLOT_BRAIN) >= 200)
					damage_message += " <span class='alert'>Мозг субъекта не функционирует. Рекомендуется инъекция нейрина.</span>"
				else if (C.getOrganLoss(ORGAN_SLOT_BRAIN) >= 120)
					damage_message += " <span class='alert'>Обнаружены серьезные повреждения мозга. Скорее всего у субъекта есть ментальные травмы.</span>"
				else if (C.getOrganLoss(ORGAN_SLOT_BRAIN) >= 45)
					damage_message += " <span class='alert'>Обнаружены повреждения мозга.</span>"
				if(advanced)
					temp_message += " <span class='info'>Степень активности мозга: [(200 - M.getOrganLoss(ORGAN_SLOT_BRAIN))/2]%.</span>"

				//TRAUMAS
				if(LAZYLEN(C.get_traumas()))
					var/list/trauma_text = list()
					for(var/datum/brain_trauma/B in C.get_traumas())
						var/trauma_desc = ""
						switch(B.resilience)
							if(TRAUMA_RESILIENCE_SURGERY)
								trauma_desc += "серьёзной "
							if(TRAUMA_RESILIENCE_LOBOTOMY)
								trauma_desc += "глубоко укоренившейся "
							if(TRAUMA_RESILIENCE_MAGIC, TRAUMA_RESILIENCE_ABSOLUTE)
								trauma_desc += "неизлечимой "
						trauma_desc += B.scan_desc
						trauma_text += trauma_desc
					temp_message += " <span class='alert'>Обнаружены церебральные травмы: субъект, судя по всему страдает, от [english_list(trauma_text)].</span>"
				if(C.roundstart_quirks.len)
					temp_message += " <span class='info'>Субъект обладает следующими психофизиологическими особенностями: [C.get_trait_string(FALSE, TRUE)].</span>"

				if(ishuman(C) && advanced)
					//MON PETIT CHAUFFEUR
					if(H.hallucinating())
						temp_message += " <span class='info'>У субъекта галлюцинации.</span>"

					//MKUltra
					if(H.has_status_effect(/datum/status_effect/chem/enthrall))
						temp_message += " <span class='info'>У субъекта наблюдаются аномальные функции мозга.</span>"

					//Astrogen shenanigans
					if(H.reagents.has_reagent(/datum/reagent/fermi/astral))
						if(H.mind)
							temp_message += " <span class='danger'>Внимание: субъект может быть одержим</span>"
						else
							temp_message += " <span class='notice'>Субъект, похоже, находится в астральной проекции.</span>"


			//LIVER
			else if(istype(O, /obj/item/organ/liver))
				var/obj/item/organ/liver/L = O
				if(L.organ_flags & ORGAN_FAILING && H.stat != DEAD) //might be depreciated
					temp_message += "<span class='danger'>Обнаружено разложение печени: примените Коразон или немедленно замените печень!</span>"

			//HEART
			else if(ishuman(M) && (istype(O, /obj/item/organ/heart)))
				var/obj/item/organ/heart/He = O
				if(H.undergoing_cardiac_arrest() && H.stat != DEAD)
					temp_message += " <span class='danger'>Обнаружен сердечный приступ: <b>немедленно</b> произведите дефибрилляцию!</span>"
				if(He.organ_flags & ORGAN_FAILING)
					heart_ded = TRUE

			//TONGUE
			else if(istype(O, /obj/item/organ/tongue))
				var/obj/item/organ/tongue/T = O
				if(T.name == "fluffy tongue")
					temp_message += " <span class='danger'>Язык субъекта покрылся шерстью. Возможные варианты лечения: Ямерол или замена языка.</span>"


			//GENERAL HANDLER
			if(!damage_message)
				if(O.organ_flags & ORGAN_FAILING)
					damage_message += " <span class='alert'><b>Орган в критической стадии разложения - [O.ru_name]</b></span>"
				else if(O.damage > O.high_threshold)
					damage_message += " <span class='alert'>Орган в острой стадии разложения - [O.name].</span>"
				else if(O.damage > O.low_threshold && advanced)
					damage_message += " <font color='red'>Орган в начальной стадии разложения - [O.ru_name]</span>"

			if(temp_message || damage_message)
				msg += "\n<b><span class='info'>[uppertext(O.name)]:</b></span> [damage_message] [temp_message]\n"



		//END; LOOK FOR MISSING ORGANS?
		var/breathes = TRUE
		var/blooded = TRUE
		if(C.dna && C.dna.species)
			if(!HAS_TRAIT_FROM(C, TRAIT_AUXILIARY_LUNGS, SPECIES_TRAIT) && HAS_TRAIT_FROM(C, TRAIT_NOBREATH, SPECIES_TRAIT))
				breathes = FALSE
			if(NOBLOOD in C.dna.species.species_traits)
				blooded = FALSE
		var/has_liver = C.dna && !(NOLIVER in C.dna.species.species_traits)
		var/has_stomach = C.dna && !(NOSTOMACH in C.dna.species.species_traits)
		if(!M.getorganslot(ORGAN_SLOT_EYES))
			msg += "<span class='alert'><b>У субъекта отсутствуют глаза.</b></span>\n"
		if(!M.getorganslot(ORGAN_SLOT_EARS))
			msg += "<span class='alert'><b>У субъекта отсутсвуют уши.</b></span>\n"
		if(!M.getorganslot(ORGAN_SLOT_TONGUE))
			msg += "<span class='alert'><b>У субъекта отсутсвует язык.</b></span>\n"
		if(!M.getorganslot(ORGAN_SLOT_BRAIN))
			msg += "<span class='alert'><b>У субъекта отсутствуют функции мозга!</b></span>\n"
		if(has_liver && !M.getorganslot(ORGAN_SLOT_LIVER))
			msg += "<span class='alert'><b>У субъекта отсутствует печень!</b></span>\n"
		if(blooded && !M.getorganslot(ORGAN_SLOT_HEART))
			msg += "<span class='alert'><b>У субъекта отсутствует сердце!</b></span>\n"
		if(breathes && !M.getorganslot(ORGAN_SLOT_LUNGS))
			msg += "<span class='alert'><b>Лёгкие пациента разорвались из-за травмы!</b></span>\n"
		if(has_stomach && !M.getorganslot(ORGAN_SLOT_STOMACH))
			msg += "<span class='alert'><b>У субъекта отсутствует желудок!</span>\n"


		if(M.radiation)
			if(M.radiation > RAD_MOB_SAFE)
				msg += "<span class='alert'>Субъект заражен опасной дозой радиацией!</span>\n"
			else
				msg += "<span class='red'>Субъект подвергся безопасному уровню радиационного воздействия.</span>\n"
			msg += "<span class='info'>Показатели радиационного заражения: [M.radiation] rad</span>\n"



	// Species and body temperature
	var/mob/living/carbon/human/H = M //Start to use human only stuff here
	if(ishuman(M))
		var/datum/species/S = H.dna.species
		var/mutant = FALSE
		var/mutated_parts = FALSE // BLUEMOON ADD
		if (H.dna.check_mutation(HULK))
			mutant = TRUE
		else if (S.mutantlungs != initial(S.mutantlungs))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutant_brain != initial(S.mutant_brain))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutant_heart != initial(S.mutant_heart))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutanteyes != initial(S.mutanteyes))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutantears != initial(S.mutantears))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutanthands != initial(S.mutanthands))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutanttongue != initial(S.mutanttongue))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutanttail != initial(S.mutanttail))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutantliver != initial(S.mutantliver))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.mutantstomach != initial(S.mutantstomach))
			mutated_parts = TRUE // BLUEMOON EDIT - было mutant
		else if (S.flying_species != initial(S.flying_species))
			mutant = TRUE

		msg += "\n<span class='info'>Раса: [H.spec_trait_examine_font()][H.dna.custom_species ? H.dna.custom_species : S.name]</font></span>\n"
		msg += "<span class='info'>Первоначальная раса: [H.spec_trait_examine_font()][S.name]</font></span>\n"
		if(mutant)
			msg += "<span class='info'>У субъекта имеются мутации.</span>\n"
		// BLUEMOON ADD START - уточнение про неоригинальные органы, а не просто мутации
		if(mutated_parts)
			msg += "<span class='info'>У субъекта имеются [HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM) ? "неоригинальные внутренние детали." : "неродные внутренние органы"].</span>\n"
		// BLUEMOON ADD END
	msg += "<span class='info'>Температура тела: [round(M.bodytemperature-T0C,0.1)] &deg;C ([round(M.bodytemperature*1.8-459.67,0.1)] &deg;F)</span>\n"

	// Time of death
	if(M.tod && (M.stat == DEAD || ((HAS_TRAIT(M, TRAIT_FAKEDEATH)) && !advanced)))
		var/zdelta = round(rand(-world.time, world.time) - M.timeofdeath)
		if(iszombie(M))
			msg += "<span class='danger'>Субъект умер [DisplayTimeText(zdelta)] назад, дефибрилляция ещё возможна!</span>"
			msg += "<span class='danger'> Онаружена аномалия.</span>\n"
		else
			msg += "<span class='info'>Время смерти:</span> [M.tod]\n"
			var/tdelta = round(world.time - M.timeofdeath)
			if(tdelta < (DEFIB_TIME_LIMIT * 10))
				if(heart_ded)
					msg += "<span class='danger'>Субъект умер [DisplayTimeText(tdelta)] назад, требуется вмешательство в сердце для дефибрилляции.</span>"
				else
					msg += "<span class='danger'>Субъект умер [DisplayTimeText(tdelta)] назад, дефибрилляция ещё возможна!</span>"
				if(advanced)
					if(H.get_ghost() || H.key || H.client)//Since it can last a while.
						msg += "<span class='danger'> Вмешательство рекомендовано.</span>\n"
					else
						msg += "\n"
	// Operations
	if(M.sterilize_power)
		msg += span_nicegreen("Ткани пациента продезинфицированы, что повышет шанс успеха операции на [M.sterilize_power] %. ") + span_info("Эффект продлится еще [DisplayTimeText(M._sterilize_expire - world.time)]\n")

	for(var/datum/surgery/procedure in M.surgeries)
		var/datum/surgery_step/surgery_step = procedure.get_surgery_step()
		msg += span_danger("Начата операция на [procedure.operated_bodypart?.ru_name_v], шанс на успех в текущих условиях: [clamp(surgery_step.get_chance(M, user, user.get_inactive_held_item(), procedure, TRUE),0,100)] %\n")

	// Wounds
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/list/wounded_parts = C.get_wounded_bodyparts()
		for(var/i in wounded_parts)
			var/obj/item/bodypart/wounded_part = i
			msg += "<span class='alert ml-1'><b>Внимание: Физическая травма[LAZYLEN(wounded_part.wounds) > 1? "" : ""] обнаружена в [wounded_part.ru_name_v]</b>"
			for(var/k in wounded_part.wounds)
				var/datum/wound/W = k
				msg += "<div class='ml-2'>Тип: [W.ru_name]\nТяжесть: [W.severity_text()]\nРекомендуемое лечение: [W.treat_text]</div>\n" // less lines than in woundscan() so we don't overload people trying to get basic med info
			msg += "</span>\n"

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(!(D.visibility_flags & HIDDEN_SCANNER))
			msg += "<span class='alert'><b>Внимание: обнаружена инфекция - [D.form]</b>\nНаименование: [D.name].\nТип: [D.spread_text].\nСтадия: [D.stage]/[D.max_stages].\nВозможное лечение: [D.cure_text]</span>\n"

	// Blood Level
	if(M.has_dna())
		var/mob/living/carbon/C = M
		var/blood_typepath = C.get_blood_id()
		if(blood_typepath)
			if(ishuman(C))
				if(H.is_bleeding())
					msg += "<span class='danger'>У субъекта кровотечение!</span>\n"
			var/blood_percent = round((C.scan_blood_volume() / (BLOOD_VOLUME_NORMAL * C.blood_ratio))*100)
			var/integrated_blood_percent = round((C.integrating_blood / (BLOOD_VOLUME_NORMAL * C.blood_ratio))*100)
			var/blood_type = C.dna.blood_type
			if(!(blood_typepath in GLOB.blood_reagent_types))
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_typepath]
				if(R)
					blood_type = R.name


			if((C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_SAFE * C.blood_ratio) && (C.scan_blood_volume() + C.integrating_blood) > (BLOOD_VOLUME_OKAY*C.blood_ratio))
				msg += "<span class='danger'>НИЗКИЙ УРОВЕНЬ [HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "гидравлической жидкости" : "крови"] [blood_percent] %, [C.scan_blood_volume()] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [C.integrating_blood] cl " : ""].</span> <span class='info'>type: [blood_type]</span>\n"
			else if((C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_OKAY * C.blood_ratio))
				msg += "<span class='danger'>КРИТИЧЕСКИЙ УРОВЕНЬ [HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "гидравлической жидкости" : "крови"] [blood_percent] %, [C.scan_blood_volume()] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [C.integrating_blood] cl " : ""].</span> <span class='info'>type: [blood_type]</span>\n"
			else
				msg += "<span class='info'>[HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "Показатель уровня гидравлической жидкости" : "Показатель уровня крови"] [blood_percent] %, [C.scan_blood_volume()] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [C.integrating_blood] cl " : ""]. type: [blood_type]</span>\n"


		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/CI in C.internal_organs)
			if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
				cyberimp_detect += "[C.name] модифицирован с помощью [CI.name].<br>"
		if(cyberimp_detect)
			msg += "<span class='notice'>Обнаружены кибернетические модификации:</span>\n"
			msg += "<span class='notice'>[cyberimp_detect]</span>\n"

	// BLUEMOON EDIT START - изменение анализаторов здоровья; to_chat_msg - чтобы на распечатанном листочке не было "распечатать"
	var/to_chat_msg = msg
	if(connected_analyzer && advanced)
		to_chat_msg += "<center><a href='?src=[REF(connected_analyzer)];print_scan=1;subject_name=[M.get_visible_name()];time=[scan_time]'>Распечатать</a></center>"
	to_chat_msg += "</body></html>"

	SEND_SIGNAL(M, COMSIG_HEALTH_SCAN, user)//SPLURT EDIT ADD - gregnancy
	SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, FALSE)
	if(connected_analyzer)
		connected_analyzer.last_msg = msg
		connected_analyzer.last_recipient_name = M.get_visible_name()
		connected_analyzer.last_scan_time = scan_time
		if(connected_analyzer.browser_mode)
			to_chat_msg = replacetext(to_chat_msg, "\n", "<br>")
			to_chat_msg = replacetext(to_chat_msg, "color='#0000CC'", "color='#13ace3'")
			var/datum/browser/popup = new(user, "healthscan", "Сканирование [M]", 600, 900)
			popup.set_content(to_chat_msg)
			popup.open()
		else
			to_chat(user, examine_block(to_chat_msg))
	else
		to_chat(user, examine_block(to_chat_msg))
	// BLUEMOON EDIT END


/proc/chemscan(mob/living/user, mob/living/M)
	if(istype(M))
		if(M.reagents)
			var/msg = "<span class='info'>"
			if(M.reagents.reagent_list.len)
				var/list/datum/reagent/reagents = list()
				for(var/datum/reagent/R in M.reagents.reagent_list)
					if(R.chemical_flags & REAGENT_INVISIBLE)
						continue
					reagents += R

				if(length(reagents))
					msg += "<span class='notice'>В организме субъекта присутствуют следующие реагенты:</span>\n"
					for(var/datum/reagent/R in reagents)
						var/invalid_reagent = is_reagent_processing_invalid(R, M)
						msg += "<span class='notice'>[invalid_reagent ? "<font color='grey'>" : ""][R.volume] единиц реагента [R.name][invalid_reagent ? "</font>" : ""][R.overdosed == 1 ? "</span> - <span class='boldannounce'>ПЕРЕДОЗ</span>" : ".</span>"]\n"
				else
					msg += "<span class='notice'>У субъекта в организме нет реагентов.</span>\n"

			else
				msg += "<span class='notice'>У субъекта в организме нет реагентов.</span>\n"
			if(M.reagents.addiction_list.len)
				msg += "<span class='boldannounce'>У субъекта есть зависимость к следующим реагентам:</span>\n"
				for(var/datum/reagent/R in M.reagents.addiction_list)
					msg += "<span class='danger'>[R.name]</span>\n"
			else
				msg += "<span class='notice'>У субъекта нет зависимости к каким-либо реагентам.</span>\n"

			var/datum/reagent/impure/fermiTox/F = M.reagents.has_reagent(/datum/reagent/impure/fermiTox)
			if(istype(F,/datum/reagent/impure/fermiTox))
				switch(F.volume)
					if(5 to 10)
						msg += "<span class='notice'Субъект содержит в себе незначительное количество токсичных изомеров.</span>\n"
					if(10 to 25)
						msg += "<span class='danger'>Субъект содержит в себе токсичные изомеры.</span>\n"
					if(25 to 50)
						msg += "<span class='danger'>Субъект содержит в себе повышенное количество токсичных изомеров.</span>\n"
					if(50 to 95)
						msg += "<span class='danger'>Субъект содержит в себе очень много токсичных изомеров.</span>\n"
					if(95 to INFINITY)
						msg += "<span class='danger'>Субъект содержит в себе крайне опасное количество токсичных изомеров.</span>\n"

			msg += "</span>"
			to_chat(user, examine_block(msg))

/obj/item/healthanalyzer/verb/toggle_mode()
	set name = "Switch Verbosity"
	set category = "Object"

	var/mob/living/L = usr
	if(!istype(L) || !CHECK_MOBILITY(L, MOBILITY_USE))
		return

	mode = !mode
	switch (mode)
		if(1)
			to_chat(usr, "Сканер теперь показывает повреждения отдельно взятой конечности.")
		if(0)
			to_chat(usr, "Сканер теперь не показывает повреждения конечности.")

/obj/item/healthanalyzer/advanced
	name = "advanced health analyzer"
	icon_state = "health_adv"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	advanced = TRUE
	var/printing = FALSE

// BLUEMOON ADD START - изменение анализаторов здоровья
/obj/item/healthanalyzer/advanced/Topic(href, href_list)
	. = ..()
	var/mob/living/carbon/user = usr
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	if(href_list["print_scan"])
		if(printing)
			return
		if(last_recipient_name != href_list["subject_name"] || last_scan_time != href_list["time"])
			to_chat(user, span_warning("Данные этого сканирования были затёрты последующими."))
			return
		printing = TRUE
		playsound(src, 'sound/effects/printer.ogg', 50, FALSE)
		sleep(2 SECONDS)
		var/obj/item/paper/new_health_report = new(get_turf(loc))
		new_health_report.add_raw_text(last_msg, advanced_html = TRUE)
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
		new_health_report.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 1, "stamp-machine")
		new_health_report.name = "Health Scan Report - [last_recipient_name] - [last_scan_time]"
		new_health_report.update_appearance()
		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		printing = FALSE
// BLUEMOON ADD END

/// Displays wounds with extended information on their status vs medscanners
/proc/woundscan(mob/user, mob/living/carbon/patient, obj/item/healthanalyzer/wound/scanner)
	if(!istype(patient))
		return

	var/render_list = ""
	for(var/i in patient.get_wounded_bodyparts())
		if(render_list == "")
			render_list += "<blockquote class='warning'>"
		var/obj/item/bodypart/wounded_part = i
		render_list += "<span class='alert ml-1'><b>Внимание: Физические травмы[LAZYLEN(wounded_part.wounds) > 1? "" : ""] обнаружены в [wounded_part.ru_name_v]</b>"
		for(var/k in wounded_part.wounds)
			var/datum/wound/W = k
			render_list += "<div class='ml-2'>[W.get_scanner_description()]</div>\n"
		render_list += "</blockquote>"

	if(render_list == "")
		if(istype(scanner))
			// Only emit the cheerful scanner message if this scan came from a scanner
			playsound(scanner, 'sound/machines/ping.ogg', 50, FALSE)
			to_chat(user, "<span class='notice'>\The [scanner] makes a happy ping and briefly displays a smiley face with several exclamation points! It's really excited to report that [patient] has no wounds!</span>")
		else
			to_chat(user, "<span class='notice ml-1'>No wounds detected in subject.</span>")
	else
		to_chat(user, jointext(render_list, ""))

/obj/item/healthanalyzer/wound
	name = "first aid analyzer"
	icon_state = "adv_spectrometer"
	desc = "A prototype MeLo-Tech medical scanner used to diagnose injuries and recommend treatment for serious wounds, but offers no further insight into the patient's health. You hope the final version is less annoying to read!"
	scanmode = SCANMODE_WOUND // Forces context to give correct tip.
	var/next_encouragement
	var/greedy

/obj/item/healthanalyzer/wound/attack_self(mob/user)
	if(next_encouragement < world.time)
		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		var/list/encouragements = list("briefly displays a happy face, gazing emptily at you", "briefly displays a spinning cartoon heart", "displays an encouraging message about eating healthy and exercising", \
				"reminds you that everyone is doing their best", "displays a message wishing you well", "displays a sincere thank-you for your interest in first-aid", "formally absolves you of all your sins")
		to_chat(user, "<span class='notice'>\The [src] makes a happy ping and [pick(encouragements)]!</span>")
		next_encouragement = world.time + 10 SECONDS
		greedy = FALSE
	else if(!greedy)
		to_chat(user, "<span class='warning'>\The [src] displays an eerily high-definition frowny face, chastizing you for asking it for too much encouragement.</span>")
		greedy = TRUE
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
		if(isliving(user))
			var/mob/living/L = user
			to_chat(L, "<span class='warning'>\The [src] makes a disappointed buzz and pricks your finger for being greedy. Ow!</span>")
			L.adjustBruteLoss(4)
			L.dropItemToGround(src)

/obj/item/healthanalyzer/wound/attack(mob/living/carbon/patient, mob/living/carbon/human/user)
	add_fingerprint(user)
	user.visible_message("<span class='notice'>[user] scans [patient] for serious injuries.</span>", "<span class='notice'>You scan [patient] for serious injuries.</span>")

	if(!istype(patient))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		to_chat(user, "<span class='notice'>\The [src] makes a sad buzz and briefly displays a frowny face, indicating it can't scan [patient].</span>")
		return

	woundscan(user, patient, src)

/obj/item/analyzer
	desc = "Ручной анализатор среды, докладывающий о состоянии газов вокруг себя."
	name = "analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "analyzer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	tool_behaviour = TOOL_ANALYZER
	custom_materials = list(/datum/material/iron=30, /datum/material/glass=20)
	grind_results = list(/datum/reagent/mercury = 5, /datum/reagent/iron = 5, /datum/reagent/silicon = 5)
	var/cooldown = FALSE
	var/cooldown_time = 250
	var/accuracy // 0 is the best accuracy.

/obj/item/analyzer/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click для активации функций барометра.</span>"

/obj/item/analyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] начинает анализировать себя с помощью [src]! Экран показывает, что [user.ru_who()] мертв[user.ru_a()]!</span>")
	return BRUTELOSS

/obj/item/analyzer/attack_self(mob/user)
	add_fingerprint(user)

	if (user.stat || user.eye_blind)
		return

	//Functionality moved down to proc/scan_turf()
	var/turf/location = get_turf(user)
	if(!istype(location))
		return

	scan_turf(user, location)

/obj/item/analyzer/AltClick(mob/user) //Barometer output for measuring when the next storm happens
	. = ..()

	if(user.canUseTopic(src))
		. = TRUE
		if(cooldown)
			to_chat(user, "<span class='warning'>[src]'s barometer function is preparing itself.</span>")
			return

		var/turf/T = get_turf(user)
		if(!T)
			return

		playsound(src, 'sound/effects/pop.ogg', 100)
		var/area/user_area = T.loc
		var/datum/weather/ongoing_weather = null

		if(!user_area.outdoors)
			to_chat(user, "<span class='warning'>[src]'s barometer function won't work indoors!</span>")
			return

		for(var/V in SSweather.processing)
			var/datum/weather/W = V
			if(W.barometer_predictable && (T.z in W.impacted_z_levels) && W.area_type == user_area.type && !(W.stage == END_STAGE))
				ongoing_weather = W
				break

		if(ongoing_weather)
			if((ongoing_weather.stage == MAIN_STAGE) || (ongoing_weather.stage == WIND_DOWN_STAGE))
				to_chat(user, "<span class='warning'>[src]'s barometer function can't trace anything while the storm is [ongoing_weather.stage == MAIN_STAGE ? "already here!" : "winding down."]</span>")
				return

			to_chat(user, "<span class='notice'>The next [ongoing_weather] will hit in [butchertime(ongoing_weather.next_hit_time - world.time)].</span>")
			if(ongoing_weather.aesthetic)
				to_chat(user, "<span class='warning'>[src]'s barometer function says that the next storm will breeze on by.</span>")
		else
			var/next_hit = SSweather.next_hit_by_zlevel["[T.z]"]
			var/fixed = next_hit ? next_hit - world.time : -1
			if(fixed < 0)
				to_chat(user, "<span class='warning'>[src]'s barometer function was unable to trace any weather patterns.</span>")
			else
				to_chat(user, "<span class='warning'>[src]'s barometer function says a storm will land in approximately [butchertime(fixed)].</span>")
		cooldown = TRUE
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/analyzer, ping)), cooldown_time)

/obj/item/analyzer/proc/ping()
	if(isliving(loc))
		var/mob/living/L = loc
		to_chat(L, "<span class='notice'>Функция барометра [src] готова!</span>")
	playsound(src, 'sound/machines/click.ogg', 100)
	cooldown = FALSE

/obj/item/analyzer/proc/butchertime(amount)
	if(!amount)
		return
	if(accuracy)
		var/inaccurate = round(accuracy*(1/3))
		if(prob(50))
			amount -= inaccurate
		if(prob(50))
			amount += inaccurate
	return DisplayTimeText(max(1,amount))

/proc/atmosanalyzer_scan(mixture, mob/living/user, atom/target = src, silent = FALSE)
	mixture = target.return_analyzable_air()
	if(!mixture)
		return FALSE

	var/icon = target
	var/render_list = list()
	if(!silent && isliving(user))
		user.visible_message("<span class='notice'>[user] использует анализатор на [icon2html(icon, viewers(user))] [target].</span>", "<span class='notice'>Вы используете анализатор на [icon2html(icon, user)] [target].</span>")
	render_list += "<span class='boldnotice'>Результаты анализа [icon2html(icon, user)] [target].</span>"

	var/list/airs = islist(mixture) ? mixture : list(mixture)
	for(var/g in airs)
		if(airs.len > 1) //not a unary gas mixture
			render_list += "<span class='boldnotice'>Node [airs.Find(g)]</span>"
		var/datum/gas_mixture/air_contents = g

		var/total_moles = air_contents.total_moles()
		var/pressure = air_contents.return_pressure()
		var/volume = air_contents.return_volume() //could just do mixture.volume... but safety, I guess?
		var/temperature = air_contents.return_temperature()
		var/cached_scan_results = air_contents.analyzer_results

		if(total_moles > 0)
			//WS Start -- Atmos Analyzer Reformat (Issue #419)
			render_list += "<span class='notice'>Молей: [round(total_moles, 0.01)] mol</span>\
							\n<span class='notice'>Объём: [volume] L</span>\
							\n<span class='notice'>Давление: [round(pressure,0.01)] кПа</span>\
							\n<span class='notice'>Температура: [round(temperature - T0C,0.01)] &deg;C ([round(temperature, 0.01)] K)</span>"
			//WS End

			for(var/id in air_contents.get_gases())
				var/gas_concentration = air_contents.get_moles(id)/total_moles
				render_list += "<span class='notice'>[GLOB.gas_data.names[id]]: [round(gas_concentration*100, 0.01)] % ([round(air_contents.get_moles(id), 0.01)] mol)</span>"  //WS Edit -- Atmos Analyzer Reformat (Issue #419)

		else
			render_list += airs.len > 1 ? "<span class='notice'>This node is empty!</span>" : "<span class='notice'>[target] is empty!</span>"

		if(cached_scan_results && cached_scan_results["fusion"]) //notify the user if a fusion reaction was detected
			render_list += "<span class='boldnotice'>Большое количество свободных нейтронов зафиксировано в воздухе, свидетельствуя, что реакция синтеза была поблизости.</span>\
						\n<span class='notice'>Нестабильность недавней реакции синтеза: [round(cached_scan_results["fusion"], 0.01)].</span>"

	// we let the join apply newlines so we do need handholding
	to_chat(user, examine_block(jointext(render_list, "\n")), type = MESSAGE_TYPE_INFO)
	return TRUE

/obj/item/analyzer/proc/scan_turf(mob/user, turf/location)

	var/datum/gas_mixture/environment = location.return_air()

	var/pressure = environment.return_pressure()
	var/total_moles = environment.total_moles()
	var/cached_scan_results = environment.analyzer_results

	var/results = "<span class='info'><B>Результаты:</B></span>"
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		results += "\n<span class='info'>Давление: [round(pressure, 0.01)] кПа</span>"
	else
		results += "\n<span class='alert'>Давление: [round(pressure, 0.01)] кПа</span>"
	if(total_moles)

		var/o2_concentration = environment.get_moles(GAS_O2)/total_moles
		var/n2_concentration = environment.get_moles(GAS_N2)/total_moles
		var/co2_concentration = environment.get_moles(GAS_CO2)/total_moles
		var/plasma_concentration = environment.get_moles(GAS_PLASMA)/total_moles

		if(abs(n2_concentration - N2STANDARD) < 20)
			results += "\n<span class='info'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_N2), 0.01)] mol)</span>"
		else
			results += "\n<span class='alert'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_N2), 0.01)] mol)</span>"

		if(abs(o2_concentration - O2STANDARD) < 2)
			results += "\n<span class='info'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_O2), 0.01)] mol)</span>"
		else
			results += "\n<span class='alert'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_O2), 0.01)] mol)</span>"

		if(co2_concentration > 0.01)
			results += "\n<span class='alert'>CO2: [round(co2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_CO2), 0.01)] mol)</span>"
		else
			results += "\n<span class='info'>CO2: [round(co2_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_CO2), 0.01)] mol)</span>"

		if(plasma_concentration > 0.005)
			results += "\n<span class='alert'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_PLASMA), 0.01)] mol)</span>"
		else
			results += "\n<span class='info'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(environment.get_moles(GAS_PLASMA), 0.01)] mol)</span>"

		for(var/id in environment.get_gases())
			if(id in GLOB.hardcoded_gases)
				continue
			var/gas_concentration = environment.get_moles(id)/total_moles
			results += "\n<span class='alert'>[GLOB.gas_data.names[id]]: [round(gas_concentration*100, 0.01)] % ([round(environment.get_moles(id), 0.01)] mol)</span>"
		results += "\n<span class='info'>Температура: [round(environment.return_temperature()-T0C, 0.01)] &deg;C ([round(environment.return_temperature(), 0.01)] K)</span>"

		if(cached_scan_results && cached_scan_results["fusion"]) //notify the user if a fusion reaction was detected
			var/instability = round(cached_scan_results["fusion"], 0.01)
			var/tier = instability2text(instability)
			results += "\n<span class='boldnotice'>Large amounts of free neutrons detected in the air indicate that a fusion reaction took place.</span>"
			results += "\n<span class='notice'>Instability of the last fusion reaction: [instability]\n This indicates it was [tier].</span>"

	to_chat(user, examine_block(results))

/obj/item/analyzer/ranged
	desc = "A hand-held scanner which uses advanced spectroscopy and infrared readings to analyze gases as a distance. Alt-Click to use the built in barometer function."
	name = "long-range analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "ranged_analyzer"

/obj/item/analyzer/ranged/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(target.tool_act(user, src, tool_behaviour))
		return
	// Tool act didn't scan it, so let's get it's turf.
	var/turf/location = get_turf(target)
	scan_turf(user, location)

//slime scanner

/obj/item/slime_scanner
	name = "slime scanner"
	desc = "A device that analyzes a slime's internal composition and measures its stats."
	icon = 'icons/obj/device.dmi'
	icon_state = "adv_spectrometer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=30, /datum/material/glass=20)

/obj/item/slime_scanner/attack(mob/living/M, mob/living/user)
	if(user.stat || user.eye_blind)
		return
	if (!isslime(M))
		to_chat(user, "<span class='warning'>This device can only scan slimes!</span>")
		return
	slime_scan(M, user)

/proc/slime_scan(mob/living/simple_animal/slime/T, mob/living/user)
	var/output = "<b>Slime scan results:</b>"
	output += "\n<span class='notice'>[T.colour] [T.is_adult ? "adult" : "baby"] slime</span>"
	output += "\nNutrition: [T.nutrition]/[T.get_max_nutrition()]"
	if (T.nutrition < T.get_starve_nutrition())
		output += "\n<span class='warning'>Warning: slime is starving!</span>"
	else if (T.nutrition < T.get_hunger_nutrition())
		output += "\n<span class='warning'>Warning: slime is hungry</span>"
	output += "\nElectric change strength: [T.powerlevel]"
	output += "\nHealth: [round(T.health/T.maxHealth,0.01)*100]%"
	if (T.slime_mutation[4] == T.colour)
		output += "\nThis slime does not evolve any further."
	else
		if (T.slime_mutation[3] == T.slime_mutation[4])
			if (T.slime_mutation[2] == T.slime_mutation[1])
				output += "\nPossible mutation: [T.slime_mutation[3]]"
				output += "\nGenetic destability: [T.mutation_chance/2] % chance of mutation on splitting"
			else
				output += "\nPossible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]] (x2)"
				output += "\nGenetic destability: [T.mutation_chance] % chance of mutation on splitting"
		else
			output += "\nPossible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]], [T.slime_mutation[4]]"
			output += "\nGenetic destability: [T.mutation_chance] % chance of mutation on splitting"
	if (T.cores > 1)
		output += "\nMultiple cores detected"
	output += "\nGrowth progress: [T.amount_grown]/[SLIME_EVOLUTION_THRESHOLD]"
	if(T.effectmod)
		output += "\n<span class='notice'>Core mutation in progress: [T.effectmod]</span>"
		output += "\n<span class = 'notice'>Progress in core mutation: [T.applied] / [SLIME_EXTRACT_CROSSING_REQUIRED]</span>"

	to_chat(user, examine_block(span_info(output)))


/obj/item/nanite_scanner
	name = "nanite scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_scanner"
	item_state = "nanite_remote"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner able to detect nanites and their programming."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)

/obj/item/nanite_scanner/attack(mob/living/M, mob/living/carbon/human/user)
	user.visible_message("<span class='notice'>[user] has analyzed [M]'s nanites.</span>")

	add_fingerprint(user)

	var/response = SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, TRUE)
	if(!response)
		to_chat(user, "<span class='info'>No nanites detected in the subject.</span>")

/obj/item/sequence_scanner
	name = "genetic sequence scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "gene"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held scanner for analyzing someones gene sequence on the fly. Hold near a DNA console to update the internal database."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)
	var/list/discovered = list() //hit a dna console to update the scanners database
	buffer = list()
	var/ready = TRUE
	var/cooldown = 200

/obj/item/sequence_scanner/attack(mob/living/M, mob/living/carbon/human/user)
	add_fingerprint(user)
	if (!HAS_TRAIT_NOT_FROM(M, TRAIT_RADIMMUNE,BLOODSUCKER_TRAIT)) //no scanning if its a husk or DNA-less Species
		user.visible_message("<span class='notice'>[user] analyzes [M]'s genetic sequence.</span>", \
							"<span class='notice'>You analyze [M]'s genetic sequence.</span>")
		gene_scan(M, user)

	else
		user.visible_message("<span class='notice'>[user] failed to analyse [M]'s genetic sequence.</span>", "<span class='warning'>[M] has no readable genetic sequence!</span>")

/obj/item/sequence_scanner/attack_self(mob/user)
	display_sequence(user)

/obj/item/sequence_scanner/attack_self_tk(mob/user)
	return

/obj/item/sequence_scanner/afterattack(obj/O, mob/user, proximity)
	. = ..()
	if(!istype(O) || !proximity)
		return

	if(istype(O, /obj/machinery/computer/scan_consolenew))
		var/obj/machinery/computer/scan_consolenew/C = O
		if(C.stored_research)
			to_chat(user, "<span class='notice'>[name] linked to central research database.</span>")
			discovered = C.stored_research.discovered_mutations
		else
			to_chat(user,"<span class='warning'>No database to update from.</span>")

/obj/item/sequence_scanner/proc/gene_scan(mob/living/carbon/C, mob/living/user)
	if(!iscarbon(C) || !C.has_dna() || HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - у синтетиков "нет" генов, полезных для хранилища
		return
	buffer = C.dna.mutation_index
	var/text = "<span class='notice'>Subject [C.name]'s DNA sequence has been saved to buffer.</span>"
	if(LAZYLEN(buffer))
		text += "<hr>"
		for(var/A in buffer)
			text += "<span class='notice'>[get_display_name(A)]</span>"
			if(A != buffer[length(A)])
				text += "\n"
	to_chat(user, examine_block(text))


/obj/item/sequence_scanner/proc/display_sequence(mob/living/user)
	if(!LAZYLEN(buffer) || !ready)
		return
	var/list/options = list()
	for(var/A in buffer)
		options += get_display_name(A)

	var/answer = input(user, "Analyze Potential", "Sequence Analyzer")  as null|anything in sort_list(options)
	if(answer && ready && user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		var/sequence
		for(var/A in buffer) //this physically hurts but i dont know what anything else short of an assoc list
			if(get_display_name(A) == answer)
				sequence = buffer[A]
				break

		if(sequence)
			var/display
			for(var/i in 0 to length_char(sequence) / DNA_MUTATION_BLOCKS-1)
				if(i)
					display += "-"
				display += copytext_char(sequence, 1 + i*DNA_MUTATION_BLOCKS, DNA_MUTATION_BLOCKS*(1+i) + 1)

			to_chat(user, "<span class='boldnotice'>[display]</span><br>")

		ready = FALSE
		icon_state = "[icon_state]_recharging"
		addtimer(CALLBACK(src, PROC_REF(recharge)), cooldown, TIMER_UNIQUE)

/obj/item/sequence_scanner/proc/recharge()
	icon_state = initial(icon_state)
	ready = TRUE

/obj/item/sequence_scanner/proc/get_display_name(mutation)
	var/datum/mutation/human/HM = GET_INITIALIZED_MUTATION(mutation)
	if(!HM)
		return "ERROR"
	if(mutation in discovered)
		return  "[HM.name] ([HM.alias])"
	else
		return HM.alias

#undef SCANMODE_HEALTH
#undef SCANMODE_CHEMICAL
#undef SCANMODE_WOUND
#undef SCANNER_CONDENSED
#undef SCANNER_VERBOSE
