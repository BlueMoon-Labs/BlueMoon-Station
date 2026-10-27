
/*

CONTAINS:
T-RAY
HEALTH ANALYZER
GAS ANALYZER
SLIME SCANNER
NANITE SCANNER
GENETICS SCANNER

*/

// Временное ограничение переключения формата отчёта; кнопка «Текстом» в окне остаётся доступна.
#define HEALTH_ANALYZER_ALLOW_CHAT_MODE FALSE

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
	desc = "Ручной сканер тела с функцией анализа показателей здоровья пациента."
	icon = 'icons/obj/device.dmi'
	icon_state = "health1"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)
	var/advanced = FALSE
	var/last_msg = ""
	var/last_recipient_name = ""
	var/last_scan_time = ""
	// Снимок показателей; открытие окна не сканирует пациента повторно.
	var/list/scan_data
	var/printing = FALSE
	var/scan_number = 0
	var/last_death_report = ""

/obj/item/healthanalyzer/Initialize(mapload)
	. = ..()

	register_item_context()
	register_context()

/obj/item/healthanalyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] анализирует свое состояние с помощью [src]! Интерфейс показывает что [user.ru_who()] - мертв[user.ru_aya()]!</span>")
	return BRUTELOSS

/obj/item/healthanalyzer/attack_self(mob/user)
	if(!last_msg)
		to_chat(user, span_notice("В памяти анализатора нет результатов обследования."))
		return
	show_results(user)

// BLUEMOON ADD START - изменение сканеров здоровья
/obj/item/healthanalyzer/examine(mob/user)
	. = ..()
	. += span_notice("Результаты обследования [HEALTH_ANALYZER_ALLOW_CHAT_MODE && user.client?.prefs?.health_analyzer_chat ? "выдаются текстовым отчётом" : "отображаются на медицинском дисплее"].")
	if(HEALTH_ANALYZER_ALLOW_CHAT_MODE)
		. += span_notice("<b>Alt-Click</b> меняет способ отображения на всех ваших анализаторах.")
	if(last_msg)
		. += span_notice("Сохранён отчёт от [last_scan_time]. Используйте анализатор в руке, чтобы открыть его.")
	if(advanced)
		. += span_notice("Сканер был улучшен и может проводить более глубокий анализ.")


/obj/item/healthanalyzer/AltClick(mob/user)
	if(!HEALTH_ANALYZER_ALLOW_CHAT_MODE)
		return
	. = ..()
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE) || !user.client?.prefs)
		return
	user.client.prefs.health_analyzer_chat = !user.client.prefs.health_analyzer_chat
	user.client.prefs.save_preferences()
	to_chat(user, span_notice("Все ваши анализаторы теперь [user.client.prefs.health_analyzer_chat ? "выдают текстовый медицинский отчёт" : "показывают результаты на медицинском дисплее"]."))
// BLUEMOON ADD END

/obj/item/healthanalyzer/proc/show_results(mob/user)
	if(HEALTH_ANALYZER_ALLOW_CHAT_MODE && user.client?.prefs?.health_analyzer_chat)
		var/report = get_report(user)
		if(advanced)
			report += "<hr><a href='?src=[REF(src)];print_scan=1;scan=[scan_number]'>Распечатать</a>"
		to_chat(user, examine_block(report), type = MESSAGE_TYPE_INFO)
	else
		ui_interact(user)

/obj/item/healthanalyzer/ui_interact(mob/user, datum/tgui/ui)
	if(!user.client)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Healthanalyzer", "Анализатор здоровья")
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/healthanalyzer/ui_data(mob/user)
	var/list/data = list("advanced" = advanced, "printing" = printing, "scan" = scan_data, "scanNumber" = scan_number)
	return data

/obj/item/healthanalyzer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	switch(action)
		if("clear")
			scan_data = null
			last_msg = ""
			last_death_report = ""
			last_recipient_name = ""
			last_scan_time = ""
			return TRUE
		if("print")
			print_report(usr)
			return TRUE
		if("chat")
			if(last_msg)
				to_chat(usr, examine_block(get_report(usr)), type = MESSAGE_TYPE_INFO)
			return TRUE

/obj/item/healthanalyzer/proc/get_report(mob/user, for_printing = FALSE)
	var/report = last_msg
	if(for_printing)
		report = "[span_info("<b>Пациент: [html_encode(last_recipient_name)]</b>")]<br>[report]"
	if(for_printing && last_death_report)
		report += "<hr><b>Посмертное заключение</b><br>[last_death_report]"
	return report

/obj/item/healthanalyzer/proc/store_scan(mob/user, list/data)
	scan_number++
	last_msg = data["report"]
	last_death_report = data["deathReport"] || ""
	last_recipient_name = data["patientRealName"] || "Неизвестный"
	data.Remove("report")
	data.Remove("deathReport")
	data.Remove("patientRealName")
	scan_data = data
	last_scan_time = data["scanTime"]
	SStgui.update_uis(src)
	show_results(user)

/obj/item/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)
	if(user.incapacitated() || user.eye_blind)
		return
	flick("[icon_state]-scan", src)

	// Неуклюжий пользователь может по ошибке просканировать пол.
	if ((HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_TRAIT(user, TRAIT_DUMB)) && prob(50))
		user.visible_message(span_warning("[user] анализирует состояние пола!"), span_notice("Вы по глупости пытаетесь анализировать пол!"))
		var/list/data = list(
			"patientRealName" = "Пол",
			"scanTime" = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time),
			"unknown" = TRUE,
			"damageLevels" = list("oxy" = 0, "tox" = 0, "burn" = 0, "brute" = 0),
			"damageLocalization" = list(),
			"organs" = list(),
			"sections" = list(),
			"report" = span_info("Результаты анализа пола: общее состояние неизвестно. Температура тела: ???"),
		)
		medical_scan_section(data, "Результат", span_notice("Жизненные показатели не обнаружены. Возможно, вы просканировали пол."))
		store_scan(user, data)
		return

	user.visible_message(span_notice("[user] анализирует показатели персонажа [M]."), span_notice("Вы анализируете показатели персонажа [M]."))

	healthscan(user, M, advanced = advanced, connected_analyzer = src)
	playsound(src, 'sound/rig/shortbeep.ogg', 50, 1, 1)

	add_fingerprint(user)

/obj/item/healthanalyzer/add_item_context(
	obj/item/source,
	list/context,
	atom/target,
)
	if (!isliving(target))
		return NONE

	LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Обследовать пациента")

	return CONTEXTUAL_SCREENTIP_SET

/obj/item/healthanalyzer/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(!isliving(user))
		return
	if(HEALTH_ANALYZER_ALLOW_CHAT_MODE)
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Сменить формат отчёта")
	if(user.is_holding(src))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Открыть последний отчёт")
	return CONTEXTUAL_SCREENTIP_SET

// Общий сбор показателей для анализатора, КПК, имплантов и медицинских машин.
/proc/healthscan(mob/user, mob/living/M, advanced = FALSE, obj/item/healthanalyzer/connected_analyzer = null, datum/live_source = null, include_chemistry = FALSE)
	if(isliving(user) && (user.incapacitated() || user.eye_blind))
		return
	var/list/data = medical_scan_results(user, M, advanced, include_chemistry = include_chemistry || !isnull(connected_analyzer))
	var/report = data["report"]
	SEND_SIGNAL(M, COMSIG_HEALTH_SCAN, user)
	if(connected_analyzer)
		connected_analyzer.store_scan(user, data)
	else
		show_medical_scan(user, data, M, live_source, "Medical", advanced, include_chemistry)
	return report

// Общий дисплей для медицинских инструментов и встроенных систем; чат остаётся доступен по префу.
/proc/show_medical_scan(mob/user, list/data, mob/living/patient, datum/live_source = null, scan_kind = "Medical", advanced = FALSE, include_chemistry = FALSE)
	if(!length(data))
		return
	if(!user.client || (HEALTH_ANALYZER_ALLOW_CHAT_MODE && user.client.prefs.health_analyzer_chat))
		var/report = data["report"]
		if(live_source)
			report = replacetext(report, "Снимок от", "Показатели на")
		to_chat(user, examine_block(report), type = MESSAGE_TYPE_INFO)
		return
	var/datum/component/medical_scan_display/display = user.LoadComponent(/datum/component/medical_scan_display)
	display.show_scan(data, patient, live_source, scan_kind, advanced, include_chemistry)

// Встроенная система явно подтверждает доступ к актуальным показателям своего носителя.
/datum/proc/can_monitor_medical_scan(mob/user, mob/living/patient, scan_kind)
	return FALSE

/datum/component/medical_scan_display
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/list/scan_data
	var/last_report = ""
	var/datum/weakref/patient_ref
	var/datum/weakref/source_ref
	var/scan_kind = "Medical"
	var/advanced = FALSE
	var/include_chemistry = FALSE
	var/scan_number = 0

/datum/component/medical_scan_display/Initialize()
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/medical_scan_display/Destroy(force, silent)
	SStgui.close_uis(src)
	scan_data = null
	patient_ref = null
	source_ref = null
	return ..()

/datum/component/medical_scan_display/proc/show_scan(list/data, mob/living/patient, datum/live_source, new_scan_kind, new_advanced, new_include_chemistry)
	patient_ref = live_source ? WEAKREF(patient) : null
	source_ref = live_source ? WEAKREF(live_source) : null
	scan_kind = new_scan_kind
	advanced = new_advanced
	include_chemistry = new_include_chemistry
	scan_number++
	set_scan(data)
	ui_interact(parent)

/datum/component/medical_scan_display/proc/set_scan(list/data)
	last_report = data["report"]
	if(source_ref)
		last_report = replacetext(last_report, "Снимок от", "Показатели на")
	scan_data = data.Copy()
	scan_data.Remove("report", "deathReport", "patientRealName")

/datum/component/medical_scan_display/proc/refresh_scan()
	if(!source_ref)
		return TRUE
	var/datum/source = source_ref.resolve()
	var/mob/living/patient = patient_ref?.resolve()
	if(!source || !patient || !source.can_monitor_medical_scan(parent, patient, scan_kind))
		return FALSE
	var/list/data
	switch(scan_kind)
		if("Medical")
			data = medical_scan_results(parent, patient, advanced, include_chemistry)
		if("Chemical")
			data = chemical_scan_results(patient)
		if("Wound")
			data = wound_scan_results(parent, patient)
	if(!length(data))
		return FALSE
	set_scan(data)
	return TRUE

/datum/component/medical_scan_display/ui_host(mob/user)
	return parent

/datum/component/medical_scan_display/ui_state(mob/user)
	return GLOB.self_state

/datum/component/medical_scan_display/ui_status(mob/user, datum/ui_state/state)
	if(user != parent || !user.client)
		return UI_CLOSE
	if(source_ref)
		var/datum/source = source_ref.resolve()
		var/mob/living/patient = patient_ref?.resolve()
		if(!source || !patient || user.stat != CONSCIOUS || user.incapacitated() || user.eye_blind || !source.can_monitor_medical_scan(user, patient, scan_kind))
			return UI_CLOSE
	return ..()

/datum/component/medical_scan_display/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Healthanalyzer", "Медицинские показатели")
		ui.set_autoupdate(!isnull(source_ref))
		ui.open()
	else
		ui.set_autoupdate(!isnull(source_ref))

/datum/component/medical_scan_display/ui_data(mob/user)
	if(!refresh_scan())
		scan_data = null
	return list("scan" = scan_data, "scanNumber" = scan_number, "advanced" = advanced, "live" = !isnull(source_ref), "canPrint" = FALSE, "canClear" = isnull(source_ref), "deviceLabel" = "")

/datum/component/medical_scan_display/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	switch(action)
		if("chat")
			if(refresh_scan() && scan_data)
				to_chat(usr, examine_block(last_report), type = MESSAGE_TYPE_INFO)
			return TRUE
		if("clear")
			if(!source_ref)
				scan_data = null
				last_report = ""
			return TRUE

/datum/component/medical_scan_display/ui_close(mob/user)
	source_ref = null
	patient_ref = null
	scan_data = null
	last_report = ""

/proc/medical_scan_results(mob/user, mob/living/M, advanced = FALSE, include_chemistry = FALSE)
	if(isliving(user) && (user.incapacitated() || user.eye_blind))
		return
	// Показатели повреждений с учётом маскировки смерти.
	var/oxy_loss = round(M.getOxyLoss(), 0.001)
	var/tox_loss = round(M.getToxLoss(), 0.001)
	var/fire_loss = round(M.getFireLoss(), 0.001)
	var/brute_loss = round(M.getBruteLoss(), 0.001)

	if(HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced)
		if(iszombie(M))
			oxy_loss = (rand(0, 100) - (tox_loss + fire_loss + brute_loss))
			tox_loss = (rand(0, 100) - (oxy_loss + fire_loss + brute_loss))
			fire_loss = (rand(0, 100) - (oxy_loss + tox_loss + brute_loss))
			brute_loss = (rand(0, 100) - (oxy_loss + tox_loss + fire_loss))
		else if(!iszombie(M))
			oxy_loss = max(rand(1, 40), oxy_loss, (300 - (tox_loss + fire_loss + brute_loss))) // Маскировка смерти увеличивает измеренное кислородное голодание.

	var/scan_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	var/list/data = list(
		"patientRealName" = M.real_name || "Неизвестный",
		"scanTime" = scan_time,
		"health" = (M.stat == DEAD || (HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced)) ? null : round(M.health / M.maxHealth * 100, 0.001),
		"dead" = M.stat == DEAD || (HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced && !iszombie(M)),
		"unknown" = HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced && iszombie(M),
		"robotic" = HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM),
		"temperatureC" = round(M.bodytemperature - T0C, 0.001),
		"temperatureF" = round(M.bodytemperature * 1.8 - 459.67, 0.001),
		"damageLevels" = list("oxy" = oxy_loss, "tox" = tox_loss, "burn" = fire_loss, "brute" = brute_loss),
		"sections" = list(),
		"report" = "",
	)
	var/msg = ""

	if(brute_loss > 10)
		msg += "\n" + span_alert("Травмы: [brute_loss > 50 ? "серьёзные" : "незначительные"]")
	if(fire_loss > 10)
		msg += "\n" + span_alert("Ожоги: [fire_loss > 50 ? "серьёзные" : "незначительные"]")
	if(oxy_loss > 10)
		msg += "\n" + span_alert("Кислородное голодание: [oxy_loss > 50 ? "серьёзное" : "незначительное"]")
	if(tox_loss > 10)
		msg += "\n" + span_alert("[HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM) ? "Повреждение системы" : "Отравление"]: [tox_loss > 50 ? "серьёзное" : "незначительное"]")
	if(M.getStaminaLoss())
		msg += "\n" + span_alert("Усталость[advanced ? ": [round(M.getStaminaLoss(), 0.001)]%" : " обнаружена"]")
	if (M.getCloneLoss())
		msg += "\n" + span_alert("Повреждения ДНК: [M.getCloneLoss() > 30 ? "серьёзные" : "незначительные"][advanced ? " ([round(M.getCloneLoss(), 0.001)])" : ""]")
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(advanced && H.has_dna() && H.dna.stability <= 90 && !HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM))
			msg += "\n\t" + span_info("Генетическая стабильность: [round(H.dna.stability, 0.001)]%.")
	if(advanced && (locate(/obj/item/implant/fake_mindshield) in M.implants))
		msg += "\n" + span_alert("Внимание: сигнатура импланта защиты разума не проходит верификацию Nanotrasen. Вероятна подделка.")

	if(ishuman(M))
		var/mob/living/carbon/human/patient = M
		if(patient.is_bleeding())
			msg += "\n" + span_danger("Обнаружено кровотечение.")
	if(M.radiation)
		var/radiation_message = "Облучение: [round(M.radiation, 0.001)] rad[M.radiation > RAD_MOB_SAFE ? ", опасно!" : ""]"
		msg += "\n" + (M.radiation > RAD_MOB_SAFE ? span_alert(radiation_message) : span_info(radiation_message))
	var/general_diagnosis = msg
	msg = ""

	// Единая таблица повреждений, отсутствующих конечностей, ран и инородных тел.
	var/list/limbs = list()
	var/limb_report = "<table><tr><th></th><th>[span_danger("Травмы")]</th><th>[span_orange("Ожоги")]</th><th>[span_nicegreen(HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM) ? "Коррозия" : "Токсины")]</th><th>[span_info("Удушение")]</th></tr>"
	limb_report += "<tr><td><b>Всего</b></td><td>[span_danger("[brute_loss]")]</td><td>[span_orange("[fire_loss]")]</td><td>[span_nicegreen("[tox_loss]")]</td><td>[span_info("[oxy_loss]")]</td></tr>"
	var/limb_details = ""
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		for(var/zone in list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
			var/obj/item/bodypart/limb = C.get_bodypart(zone)
			var/list/entry = list("name" = capitalize(ru_parse_zone(zone)), "missing" = isnull(limb), "wounds" = list(), "embeds" = list())
			var/list/wounds = entry["wounds"]
			var/list/embeds = entry["embeds"]
			if(limb)
				entry["brute"] = round(limb.brute_dam, 0.001)
				entry["burn"] = round(limb.burn_dam, 0.001)
				for(var/datum/wound/wound as anything in limb.wounds)
					wounds += list(list("name" = wound.ru_name, "icon" = wound.scanner_icon, "severity" = wound.severity_text(), "treatment" = strip_html_tags(wound.treat_text), "details" = strip_html_tags(replacetext(wound.get_scanner_description(user), "<br>", "\n"))))
				for(var/obj/item/embedded as anything in limb.embedded_objects)
					embeds += embedded.name
			if(limb && !limb.brute_dam && !limb.burn_dam && !length(wounds) && !length(embeds))
				continue
			limbs += list(entry)
			if(!limb)
				limb_details += "<tr><td colspan='5'>[span_bolddanger("[html_encode(entry["name"])] отсутствует")]</td></tr>"
			else
				limb_details += "<tr><td>[html_encode(entry["name"])]</td><td>[span_danger("[entry["brute"]]")]</td><td>[span_orange("[entry["burn"]]")]</td></tr>"
			for(var/embedded_name in embeds)
				limb_details += "<tr><td colspan='5'>[span_alert(span_tooltip("Извлеките хирургическим зажимом.", "↳ Инородное тело: [html_encode(embedded_name)]", "", "", "font-size:85%; margin-left:1em"))]</td></tr>"
			for(var/list/wound in wounds)
				limb_details += "<tr><td colspan='5'>[span_alert(span_tooltip(html_encode(wound["details"]), "<i class='fas fa-[wound["icon"]]'></i> ↳ [html_encode(wound["name"])] ([wound["severity"]])", "", "", "font-size:85%; margin-left:1em"))]</td></tr>"
	data["damageLocalization"] = limbs
	data["report"] += "<hr><b>Состояние тела</b><br>[limb_report][limb_details]</table>"

	var/list/organ_data = list()
	data["organs"] = organ_data
	var/list/missing_organs = list()
	data["missingOrgans"] = missing_organs
	var/organ_report = ""

	var/heart_ded = FALSE
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/mob/living/carbon/human/H = M
		for(var/organ in C.internal_organs)
			var/temp_message
			var/damage_message
			var/obj/item/organ/O = organ

			if(istype(O, /obj/item/organ/eyes))
				var/obj/item/organ/eyes/eyes = O
				if(advanced)
					if(eyes.organ_flags & ORGAN_FAILING)
						damage_message += " " + span_alert("Зрение утрачено из-за отказа глаз.")
					else if(HAS_TRAIT(C, TRAIT_BLIND))
						temp_message += " " + span_alert("Зрение отсутствует.")
					else if(eyes.damage > eyes.high_threshold)
						damage_message += " " + span_alert("Сильное помутнение зрения.")
					else if(eyes.damage > eyes.low_threshold)
						damage_message += " " + span_alert("Помутнение зрения.")
					else if(eyes.damage)
						damage_message += " " + span_info("Зрение не нарушено повреждениями глаз.")
					if(HAS_TRAIT(C, TRAIT_NEARSIGHT) && !HAS_TRAIT(C, TRAIT_BLIND))
						temp_message += " " + span_alert("Близорукость: снижена чёткость дальнего зрения.")

			else if(istype(O, /obj/item/organ/ears))
				var/obj/item/organ/ears/ears = O
				if(advanced)
					if(HAS_TRAIT_FROM(C, TRAIT_DEAF, GENETIC_MUTATION))
						temp_message += " " + span_alert("Слух отсутствует: генетическая глухота.")
					else if(HAS_TRAIT(C, TRAIT_DEAF))
						temp_message += " " + span_alert("Слух отсутствует.")
					if(ears.organ_flags & ORGAN_FAILING)
						damage_message += " " + span_alert("Слух отсутствует: отказ слухового органа. Требуется восстановление или замена.")
					else if(!HAS_TRAIT(C, TRAIT_DEAF))
						if(ears.deaf)
							damage_message += " " + span_alert("Слух временно отсутствует.")
						else if(ears.damage > ears.low_threshold)
							damage_message += " " + span_alert("Слух сохранён; возможны приступы звона в ушах и кратковременной глухоты.")
						else if(ears.damage)
							damage_message += " " + span_info("Слух сохранён.")

			else if(istype(O, /obj/item/organ/brain))
				if(O.organ_flags & ORGAN_FAILING)
					damage_message += " " + span_alert("Нейронная активность отсутствует. Рекомендован нейрин.")
				else if(O.damage > BRAIN_DAMAGE_SEVERE)
					damage_message += " " + span_alert("Высокий риск тяжёлых неврологических нарушений.")
				else if(O.damage > BRAIN_DAMAGE_MILD)
					damage_message += " " + span_alert("Риск неврологических нарушений.")
				if(advanced && C.getOrganLoss(ORGAN_SLOT_BRAIN) > 0)
					temp_message += " " + span_info("Активность: [round((1 - O.damage / O.maxHealth) * 100, 1)]%.")

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
					temp_message += " " + span_alert("Церебральные травмы: [english_list(trauma_text)].")
				if(C.roundstart_quirks.len)
					temp_message += " " + span_info("Особенности: [C.get_trait_string(FALSE, TRUE)].")

				if(ishuman(C) && advanced)

					if(H.hallucinating())
						temp_message += " " + span_info("Галлюцинации.")

					if(H.has_status_effect(/datum/status_effect/chem/enthrall))
						temp_message += " " + span_info("Аномальная активность.")

					if(H.reagents.has_reagent(/datum/reagent/fermi/astral))
						if(H.mind)
							temp_message += " " + span_danger("Возможна одержимость.")
						else
							temp_message += " " + span_notice("Астральная проекция.")

			else if(istype(O, /obj/item/organ/liver))
				var/obj/item/organ/liver/L = O
				if(L.organ_flags & ORGAN_FAILING)
					damage_message += " " + span_alert("Метаболизм большинства препаратов прекращён; риск интоксикации.")
				else if(L.damage >= L.high_threshold)
					damage_message += " " + span_alert("Метаболизм сохранён; поражение печени ограничивает подвижность.")
				else if(L.damage && advanced)
					damage_message += " " + span_info("Метаболизм препаратов сохранён.")

			else if(istype(O, /obj/item/organ/heart))
				var/obj/item/organ/heart/He = O
				if(He.organ_flags & ORGAN_FAILING)
					heart_ded = TRUE
					damage_message += " " + span_alert("Отказ [He.organ_flags & ORGAN_SYNTHETIC ? "циркуляционного насоса" : "сердечной мышцы"]. Требуется восстановление или замена.")
				else if(C.undergoing_cardiac_arrest())
					damage_message += " " + span_alert("Кровообращение остановлено.")
					if(C.stat != DEAD)
						temp_message += " " + span_danger("<b>Срочная дефибрилляция!</b>")
				else if(!He.beating)
					damage_message += " " + span_alert("Сократительная активность отсутствует.")
				else if(He.damage > He.high_threshold)
					damage_message += " " + span_alert("Сократительная активность сохранена; высокий риск отказа сердца.")
				else if(He.damage && advanced)
					damage_message += " " + span_info("Сократительная активность сохранена.")

			else if(istype(O, /obj/item/organ/lungs))
				if(istype(O, /obj/item/organ/lungs/ipc))
					var/obj/item/organ/lungs/ipc/cooling_system = O
					if(O.organ_flags & ORGAN_FAILING)
						damage_message += " " + span_alert("Отказ контура охлаждения; активное охлаждение недоступно.")
					else if(O.damage > O.high_threshold || (O.damage && advanced))
						damage_message += " " + span_info("Активное охлаждение [cooling_system.is_cooling ? "включено" : "выключено"].")
				else if(O.organ_flags & ORGAN_FAILING)
					damage_message += " " + span_alert("Лёгкие не обеспечивают дыхание; угроза удушья.")
				else if(O.damage > O.high_threshold)
					damage_message += " " + span_alert("Газообмен значительно затруднён; риск дыхательной недостаточности.")
				else if(O.damage > O.low_threshold && advanced)
					damage_message += " " + span_alert("Газообмен затруднён; дыхательный резерв снижен.")
				else if(O.damage && advanced)
					damage_message += " " + span_info("Газообмен сохранён; дыхательный резерв снижен.")

			else if(istype(O, /obj/item/organ/stomach))
				if(O.organ_flags & ORGAN_FAILING)
					damage_message += " " + span_alert("Отказ желудка; нарушение пищеварения.")
				else if(O.damage > O.high_threshold)
					damage_message += " " + span_alert("Пища плохо удерживается; высокий риск рвоты после еды.")
				else if(O.damage && advanced)
					damage_message += " " + span_alert("Риск рвоты после еды; возрастает при больших порциях.")

			else if(istype(O, /obj/item/organ/tongue))
				var/obj/item/organ/tongue/T = O
				if(T.name == "fluffy tongue")
					temp_message += " " + span_danger("Язык покрыт шерстью. Рекомендован ямерол или замена языка.")

			if(advanced && (O.organ_flags & ORGAN_SYNTHETIC_EMP))
				temp_message += " " + span_alert("ЭМИ-повреждение; состояние системы ухудшается.")
			if(!damage_message)
				if(O.organ_flags & ORGAN_FAILING)
					damage_message += " " + span_alert("Отказ [O.organ_flags & ORGAN_SYNTHETIC ? "системы" : "органа"]; требуется восстановление или замена.")
				else if(O.damage > O.high_threshold)
					damage_message += " " + span_alert("Высокий риск отказа [O.organ_flags & ORGAN_SYNTHETIC ? "системы" : "органа"].")
				else if(O.damage > O.low_threshold && advanced)
					damage_message += " " + span_alert("Повреждения требуют [O.organ_flags & ORGAN_SYNTHETIC ? "ремонта" : "лечения"]; отказ не обнаружен.")
				else if(O.damage && advanced)
					damage_message += " " + span_info("Признаков отказа нет.")

			if(temp_message || damage_message)
				if(O.damage > 0 || (O.organ_flags & ORGAN_FAILING))
					var/organ_icon = icon2base64html(O, sourceonly = TRUE)
					var/critical = !!(O.organ_flags & ORGAN_FAILING)
					var/damage_percent = round(O.damage / O.maxHealth * 100, 1)
					var/organ_diagnosis = "[damage_message] [temp_message]"
					organ_data += list(list("name" = capitalize(O.ru_name || O.name), "icon" = organ_icon, "damage" = advanced ? damage_percent : null, "status" = trim(strip_html_tags(organ_diagnosis)), "warning" = !!(findtext(organ_diagnosis, "class='danger") || findtext(organ_diagnosis, "class='alert")), "critical" = critical))
					organ_report += "<tr[critical ? " style='font-weight:bold'" : ""]><td style='white-space:nowrap'><img src='data:image/png;base64,[organ_icon]' width='24' height='24' style='vertical-align:middle'> [html_encode(capitalize(O.ru_name || O.name))]</td>[advanced ? "<td style='white-space:nowrap'>[span_danger("[damage_percent]%")]</td>" : ""]<td>[damage_message] [temp_message]</td></tr>"
				else
					// Функциональные нарушения без повреждения органа остаются в общей диагностике.
					general_diagnosis += "\n[span_info("[capitalize(O.ru_name || O.name)]:")] [temp_message] [damage_message]"

		// Отсутствующие органы с учётом физиологии вида.
		var/breathes = TRUE
		var/blooded = TRUE
		if(C.dna && C.dna.species)
			if(!HAS_TRAIT_FROM(C, TRAIT_AUXILIARY_LUNGS, SPECIES_TRAIT) && HAS_TRAIT_FROM(C, TRAIT_NOBREATH, SPECIES_TRAIT))
				breathes = FALSE
			if(NOBLOOD in C.dna.species.species_traits)
				blooded = FALSE
		var/has_liver = C.dna && !(NOLIVER in C.dna.species.species_traits)
		var/has_stomach = C.dna && !(NOSTOMACH in C.dna.species.species_traits)
		var/list/required_organs = list(
			ORGAN_SLOT_EYES = /obj/item/organ/eyes,
			ORGAN_SLOT_EARS = /obj/item/organ/ears,
			ORGAN_SLOT_TONGUE = /obj/item/organ/tongue,
			ORGAN_SLOT_BRAIN = /obj/item/organ/brain,
		)
		if(has_liver)
			required_organs[ORGAN_SLOT_LIVER] = /obj/item/organ/liver
		if(blooded)
			required_organs[ORGAN_SLOT_HEART] = /obj/item/organ/heart
		if(breathes)
			required_organs[ORGAN_SLOT_LUNGS] = /obj/item/organ/lungs
		if(has_stomach)
			required_organs[ORGAN_SLOT_STOMACH] = /obj/item/organ/stomach
		var/list/missing_organ_report = list()
		for(var/slot in required_organs)
			if(M.getorganslot(slot))
				continue
			var/obj/item/organ/organ_type = required_organs[slot]
			var/organ_name = capitalize(initial(organ_type.ru_name))
			var/organ_icon = icon2base64html(organ_type, sourceonly = TRUE)
			missing_organs += list(list("name" = organ_name, "icon" = organ_icon))
			missing_organ_report += "<b style='white-space:nowrap'><img src='data:image/png;base64,[organ_icon]' width='24' height='24' style='vertical-align:middle'> [html_encode(organ_name)]</b>"
		if(length(organ_data) || length(missing_organs))
			data["report"] += "<hr><b>Состояние органов</b>"
			if(length(organ_data))
				data["report"] += "<table><tr><th>Орган</th>[advanced ? "<th>Повреждения</th>" : ""]<th>Состояние</th></tr>[organ_report]</table>"
			if(length(missing_organs))
				data["report"] += "<br>[span_bolddanger("Отсутствует: [jointext(missing_organ_report, ", ")]")]"

		if(advanced && M.has_status_effect(/datum/status_effect/heretic_dance_earworm))
			general_diagnosis += "\n" + span_alert("Сердцебиение подстроилось под чужой ритм: пульс бьёт ровными тактами, как метроном. Сбить ритм может разряд дефибриллятора.")

	// Вид организма и отклонения.
	var/mob/living/carbon/human/H = M
	if(ishuman(M))
		var/datum/species/S = H.dna.species
		var/mutant = FALSE
		var/mutated_parts = FALSE
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

		data["species"] = H.dna.custom_species || S.name
		data["similarSpecies"] = S.name
		if(mutant)
			msg += span_info("У субъекта имеются мутации.") + "\n"
		// BLUEMOON ADD START - уточнение про неоригинальные органы, а не просто мутации
		if(mutated_parts)
			msg += span_info("У субъекта имеются [HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM) ? "неоригинальные внутренние детали." : "неродные внутренние органы"].") + "\n"

	if(advanced)
		general_diagnosis += "\n[msg]"
	data["diagnosis"] = medical_scan_lines(general_diagnosis)
	var/diagnosis_report = jointext(splittext(trim(general_diagnosis), "\n") - "", " · ")
	msg = ""

	if(M.tod && (M.stat == DEAD || ((HAS_TRAIT(M, TRAIT_FAKEDEATH)) && !advanced)))
		var/zdelta = round(rand(-world.time, world.time) - M.timeofdeath)
		if(iszombie(M))
			msg += span_danger("Обнаружена аномалия, неточные данные. Субъект умер [DisplayTimeText(zdelta)] назад, дефибрилляция ещё возможна!") + "\n"
		else
			msg += span_info("Время смерти:") + " [M.tod]\n"
			var/tdelta = round(world.time - M.timeofdeath)
			if(tdelta < (DEFIB_TIME_LIMIT * 10))
				if(heart_ded)
					msg += span_danger("Субъект умер [DisplayTimeText(tdelta)] назад, требуется вмешательство в сердце для дефибрилляции.")
				else
					msg += span_danger("Субъект умер [DisplayTimeText(tdelta)] назад, дефибрилляция ещё возможна!")
				if(advanced)
					if(H.get_ghost() || H.key || H.client)
						msg += span_danger(" Вмешательство рекомендовано.") + "\n"
					else
						msg += "\n"

	data["deathReport"] = replacetext(msg, "\n", "<br>")
	msg = ""
	if(M.sterilize_power)
		msg += span_nicegreen("Ткани пациента продезинфицированы, что повышет шанс успеха операции на [round(M.sterilize_power, 0.001)] %. ") + span_info("Эффект продлится еще [DisplayTimeText(M._sterilize_expire - world.time)]\n")

	for(var/datum/surgery/procedure in M.surgeries)
		var/datum/surgery_step/surgery_step = procedure.get_surgery_step()
		msg += span_danger("Начата операция на [procedure.operated_bodypart?.ru_name_v], шанс на успех в текущих условиях: [round(clamp(surgery_step.get_chance(M, user, user.get_inactive_held_item(), procedure, TRUE),0,100), 0.001)] %\n")

	medical_scan_section(data, "Операции", msg)
	msg = ""
	var/palm_scan = blood_oath_palm_scan(M)
	if(palm_scan)
		msg += span_info("[palm_scan]") + "\n"

	medical_scan_section(data, "Особые признаки", msg)
	msg = ""
	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(!(D.visibility_flags & HIDDEN_SCANNER))
			msg += span_alert("<b>Внимание: обнаружена инфекция - [D.form]</b>\nНаименование: [D.name].\nТип: [D.spread_text].\nСтадия: [D.stage]/[D.max_stages].\nВозможное лечение: [D.cure_text]") + "\n"

	medical_scan_section(data, "Инфекции", msg)
	msg = ""
	// Объём крови с учётом размера тела и поступающего переливания.
	var/blood_report = ""
	if(M.has_dna())
		var/mob/living/carbon/C = M
		var/blood_typepath = C.get_blood_id()
		if(blood_typepath)
			var/blood_percent = round((C.scan_blood_volume() / (BLOOD_VOLUME_NORMAL * C.blood_ratio))*100, 0.1)
			var/integrated_blood_percent = round((C.integrating_blood / (BLOOD_VOLUME_NORMAL * C.blood_ratio))*100, 0.1)
			var/blood_volume = round(C.scan_blood_volume(), 0.001)
			var/integrating_blood = round(C.integrating_blood, 0.001)
			data["blood"] = list("percent" = blood_percent, "volume" = blood_volume, "incoming" = integrating_blood, "low" = (C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_SAFE * C.blood_ratio), "critical" = (C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_OKAY * C.blood_ratio))
			var/blood_type = C.dna.blood_type
			if(!(blood_typepath in GLOB.blood_reagent_types))
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_typepath]
				if(R)
					blood_type = R.name

			var/list/blood_data = data["blood"]
			blood_data["type"] = blood_type
			if((C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_SAFE * C.blood_ratio) && (C.scan_blood_volume() + C.integrating_blood) > (BLOOD_VOLUME_OKAY*C.blood_ratio))
				blood_report += span_danger("НИЗКИЙ УРОВЕНЬ [HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "гидравлической жидкости" : "крови"] [blood_percent] %, [blood_volume] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [integrating_blood] cl " : ""].") + " " + span_info("группа: [blood_type]") + "\n"
			else if((C.scan_blood_volume() + C.integrating_blood) <= (BLOOD_VOLUME_OKAY * C.blood_ratio))
				blood_report += span_danger("КРИТИЧЕСКИЙ УРОВЕНЬ [HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "гидравлической жидкости" : "крови"] [blood_percent] %, [blood_volume] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [integrating_blood] cl " : ""].") + " " + span_info("группа: [blood_type]") + "\n"
			else
				blood_report += span_info("[HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM) ? "Показатель уровня гидравлической жидкости" : "Показатель уровня крови"] [blood_percent] %, [blood_volume] cl[C.integrating_blood? ", и ещё поступает [integrated_blood_percent] %, [integrating_blood] cl " : ""]. группа: [blood_type]") + "\n"

		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/CI in C.internal_organs)
			if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
				cyberimp_detect += "[capitalize(CI.ru_name || CI.name)]<br>"
		if(cyberimp_detect)
			msg += span_notice("Обнаружены кибернетические модификации:") + "\n"
			msg += span_notice("[cyberimp_detect]") + "\n"

	if(SEND_SIGNAL(M, COMSIG_NANITE_SCAN, null, FALSE))
		msg += span_info("<b>Обнаружены наниты</b>")
	else if(HAS_TRAIT_FROM(M, TRAIT_NANITES_IMMUNITY, NANITES_IMMUNITY_FROM_REAGENT))
		msg += span_info("<b>Обнаружено действие Nanite Protector.</b>\n")
	medical_scan_section(data, "Импланты и наниты", msg)
	if(include_chemistry)
		var/list/chemical_data = chemical_scan_results(M)
		data["reagents"] = chemical_data["reagents"]
		data["addictions"] = chemical_data["addictions"]
		var/list/sections = data["sections"]
		sections += chemical_data["sections"]
		data["report"] += chemical_data["report"]
	var/header = span_info("<b>Результаты анализа</b><br>")
	if(data["unknown"])
		header += span_info("Общее состояние: Неизвестно<br>")
	if(data["species"])
		header += span_info("Раса: [html_encode(data["species"])] | ")
		if(data["similarSpecies"] && data["similarSpecies"] != data["species"])
			header += span_info("Схожая раса: [html_encode(data["similarSpecies"])] | ")
	header += span_info("Температура тела: [data["temperatureC"]] °C ([data["temperatureF"]] °F)<br>")
	header += replacetext(blood_report, "\n", "<br>")
	if(diagnosis_report)
		header += "[diagnosis_report]<br>"
	var/report = "[header][data["report"]]<hr>[span_info("Снимок от [scan_time]")]"
	data["report"] = report
	return data

// В чат и на бумагу идёт форматированный текст, в TGUI — обычный текст и уровень предупреждения.
/proc/medical_scan_section(list/data, title, text)
	var/list/lines = medical_scan_lines(text)
	if(!length(lines))
		return
	var/list/sections = data["sections"]
	sections += list(list("title" = title, "lines" = lines))
	data["report"] += "<hr><b>[title]</b><br>[replacetext(text, "\n", "<br>")]"

// Сохраняем кириллицу без перекодирования; HTML-сущности декодирует интерфейс.
/proc/medical_scan_lines(text)
	var/list/lines = list()
	if(!length(text))
		return lines
	for(var/line in splittext(replacetext(text, "\n", "<br>"), "<br>"))
		var/plain = trim(strip_html_tags(line))
		if(!length(plain))
			continue
		lines += list(list("text" = plain, "warning" = !!(findtext(line, "class='alert") || findtext(line, "class='danger") || findtext(line, "class='red") || findtext(line, "class='bolddanger"))))
	return lines


/proc/chemscan(mob/user, mob/living/M, datum/live_source = null)
	if(!istype(M) || !M.reagents)
		return
	var/list/data = chemical_scan_results(M)
	show_medical_scan(user, data, M, live_source, "Chemical")
	return data["report"]

/proc/chemical_scan_results(mob/living/target)
	var/scan_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	var/list/data = list(
		"patientRealName" = target.real_name || "Неизвестный",
		"scanTime" = scan_time,
		"chemicalOnly" = TRUE,
		"sections" = list(),
		"reagents" = list(),
		"addictions" = list(),
		"report" = "",
	)
	var/list/reagents = data["reagents"]
	var/list/addictions = data["addictions"]
	var/msg = ""
	for(var/datum/reagent/reagent as anything in target.reagents?.reagent_list)
		if(reagent.chemical_flags & REAGENT_INVISIBLE)
			continue
		var/invalid = is_reagent_processing_invalid(reagent, target)
		reagents += list(list("name" = reagent.name, "volume" = round(reagent.volume, 0.001), "overdosed" = reagent.overdosed, "inactive" = invalid))
		var/reagent_text = "[round(reagent.volume, 0.001)] u [html_encode(reagent.name)]"
		msg += "[span_notice(reagent_text)][reagent.overdosed ? " — [span_bolddanger("ПЕРЕДОЗИРОВКА")]" : ""]<br>"
	if(!length(reagents))
		msg = span_notice("В организме не обнаружены реагенты.")
	msg += "<br>"
	var/addiction_text = ""
	for(var/datum/reagent/reagent as anything in target.reagents?.addiction_list)
		addictions += reagent.name
		addiction_text += "[length(addiction_text) ? ", " : ""][html_encode(reagent.name)]"
	if(length(addictions))
		msg += span_danger("Зависимости: [addiction_text].")
	else
		msg += span_notice("Химические зависимости не обнаружены.")
	medical_scan_section(data, "Реагенты в организме", msg)
	msg = ""
	var/datum/reagent/impure/fermiTox/isomers = target.reagents?.has_reagent(/datum/reagent/impure/fermiTox)
	if(istype(isomers))
		switch(isomers.volume)
			if(5 to 10)
				msg = span_notice("Обнаружено незначительное количество токсичных изомеров.")
			if(10 to 25)
				msg = span_danger("Обнаружены токсичные изомеры.")
			if(25 to 50)
				msg = span_danger("Обнаружено повышенное количество токсичных изомеров.")
			if(50 to 95)
				msg = span_danger("Обнаружено очень много токсичных изомеров.")
			if(95 to INFINITY)
				msg = span_danger("Обнаружено крайне опасное количество токсичных изомеров.")
	medical_scan_section(data, "Дополнительная диагностика", msg)
	return data

/obj/item/healthanalyzer/advanced
	name = "advanced health analyzer"
	desc = "Ручной сканер тела, определяющий жизненные показатели с высокой точностью. Может печатать медицинские отчёты."
	icon_state = "health_adv"
	advanced = TRUE

/obj/item/healthanalyzer/advanced/Topic(href, href_list)
	. = ..()
	var/mob/living/user = usr
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	if(href_list["print_scan"])
		if(scan_number != text2num(href_list["scan"]))
			to_chat(user, span_warning("Данные этого сканирования были затёрты последующими."))
			return
		print_report(user)

/obj/item/healthanalyzer/proc/print_report(mob/user)
	if(!advanced || printing || !last_msg)
		return
	// Сохраняем снимок до задержки: новое сканирование не должно подменить печатаемый отчёт.
	var/report = get_report(user, for_printing = TRUE)
	var/report_name = last_recipient_name
	var/report_time = last_scan_time
	printing = TRUE
	SStgui.update_uis(src)
	playsound(src, 'sound/effects/printer.ogg', 50, FALSE)
	sleep(2 SECONDS)
	if(QDELETED(src))
		return
	var/obj/item/paper/new_health_report = new(drop_location())
	new_health_report.add_raw_text(report, advanced_html = TRUE)
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
	new_health_report.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 1, "stamp-machine")
	new_health_report.name = "Health Scan Report - [report_name] - [report_time]"
	new_health_report.update_appearance()
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
	printing = FALSE
	SStgui.update_uis(src)

// Подробное описание ран остаётся доступным у всех вызывающих этот прок инструментов.
/proc/woundscan(mob/user, mob/living/carbon/patient, obj/item/healthanalyzer/scanner, datum/live_source = null)
	if(!istype(patient) || (isliving(user) && (user.incapacitated() || user.eye_blind)))
		return
	var/list/data = wound_scan_results(user, patient)
	if(!length(patient.get_wounded_bodyparts()) && istype(scanner, /obj/item/healthanalyzer/wound))
		playsound(scanner, 'sound/machines/ping.ogg', 50, FALSE)
	if(istype(scanner))
		scanner.store_scan(user, data)
	else
		show_medical_scan(user, data, patient, live_source, "Wound")

// Отдельный сбор данных позволяет обновлять встроенный сканер ран без повторного вывода в чат.
/proc/wound_scan_results(mob/user, mob/living/carbon/patient)
	if(!istype(patient))
		return
	var/scan_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	var/list/data = list(
		"patientRealName" = patient.real_name || "Неизвестный",
		"scanTime" = scan_time,
		"woundOnly" = TRUE,
		"sections" = list(),
		"report" = span_info("<b>Анализ ран</b>"),
	)
	for(var/obj/item/bodypart/limb as anything in patient.get_wounded_bodyparts())
		var/msg = ""
		for(var/datum/wound/wound as anything in limb.wounds)
			msg += "[span_alert(wound.get_scanner_description(user))]<br><br>"
		medical_scan_section(data, "Раны: [limb.ru_name]", msg)
	if(!length(data["sections"]))
		medical_scan_section(data, "Результат", span_notice("Физические травмы не обнаружены."))
	data["report"] += "<hr>[span_info("Снимок от [scan_time]")]"
	return data

/obj/item/healthanalyzer/wound
	name = "first aid analyzer"
	icon_state = "adv_spectrometer"
	desc = "A prototype MeLo-Tech medical scanner used to diagnose injuries and recommend treatment for serious wounds, but offers no further insight into the patient's health. You hope the final version is less annoying to read!"
	var/next_encouragement
	var/greedy

/obj/item/healthanalyzer/wound/attack_self(mob/user)
	if(last_msg)
		return ..()
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
	/// Разобранные смеси последнего скана. Окно показывает снимок, а не живые данные:
	/// анализатор уносят от того, что просканировали, и смесь под ним меняется.
	var/list/last_gasmix_data
	/// REF смеси -> нестабильность недавнего синтеза. Лежит РЯДОМ со смесью, а не
	/// внутри неё: контракт gas_mixture_parser общий для всех окон и поля под это не имеет.
	var/list/last_fusion_data

/obj/item/analyzer/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click для активации функций барометра.</span>"

/obj/item/analyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] начинает анализировать себя с помощью [src]! Экран показывает, что [user.ru_who()] мертв[user.ru_a()]!</span>")
	return BRUTELOSS

/obj/item/analyzer/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/analyzer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GasAnalyzer", "Газоанализатор")
		ui.open()

/obj/item/analyzer/ui_data(mob/user)
	LAZYINITLIST(last_gasmix_data)
	LAZYINITLIST(last_fusion_data)
	return list(
		"gasmixes" = last_gasmix_data,
		"fusion_instability" = last_fusion_data,
	)

/obj/item/analyzer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	// Вторая точка входа в справочник. Анализатор - тот прибор, который в руках
	// у человека ровно в тот момент, когда он смотрит на незнакомый газ и не
	// понимает, что это и чем оно опасно.
	if(action == "handbook")
		open_atmos_handbook(usr)
		return TRUE

/** Снимает смеси цели в `last_gasmix_data` для окна.
 *
 * Аргументы:
 * * target: атом, у которого спрашивается воздух через `return_analyzable_air()`.
 *
 * Возвращает TRUE, если у цели нашлось что анализировать. На FALSE прошлый снимок
 * остаётся нетронутым: показать вместо стены старую смесь честнее, чем пустое окно
 * без объяснений, а вызывающий код в этом случае уходит в чат-вывод.
 */
/obj/item/analyzer/proc/on_analyze(atom/target)
	if(!target)
		return FALSE
	var/mixture = target.return_analyzable_air()
	if(!mixture)
		return FALSE
	var/list/airs = islist(mixture) ? mixture : list(mixture)
	// Пустой list() в DM истинен, поэтому нулевую длину проверяем отдельно: иначе
	// окно откроется с пустым снимком вместо честного ухода в чат.
	if(!length(airs))
		return FALSE
	var/list/new_gasmix_data = list()
	var/list/new_fusion_data = list()
	var/target_name = capitalize(lowertext(target.name)) //от узла к узлу не меняется
	var/multiple_nodes = length(airs) > 1
	// Идём по индексам, а не по значениям: номер узла обязан быть позицией в списке.
	// Поиск позиции по значению искал бы её заново на каждой итерации, а для двух узлов
	// с одной и той же смесью вернул бы обоим первый индекс - секции окна стали бы
	// неразличимы.
	for(var/node_index in 1 to length(airs))
		// istype, а не `as anything`: nullifyNode() делает QDEL_NULL(airs[i]) и
		// оставляет в списке дырку, обращение к полям null было бы рантаймом.
		var/datum/gas_mixture/air = airs[node_index]
		if(!istype(air))
			continue
		var/mix_name = target_name
		if(multiple_nodes) //не унарная смесь: у машины несколько узлов
			mix_name += " - Узел [node_index]"
		new_gasmix_data += list(gas_mixture_parser(air, mix_name))
		var/list/cached_scan_results = air.analyzer_results
		if(cached_scan_results && cached_scan_results["fusion"])
			new_fusion_data[REF(air)] = round(cached_scan_results["fusion"], 0.01)
	// Список был не пуст, но состоял из одних дырок: снимка не получилось.
	if(!length(new_gasmix_data))
		return FALSE
	last_gasmix_data = new_gasmix_data
	last_fusion_data = new_fusion_data
	return TRUE

/obj/item/analyzer/attack_self(mob/user)
	add_fingerprint(user)

	if (user.stat || user.eye_blind)
		return

	//Functionality moved down to proc/scan_turf()
	var/turf/location = get_turf(user)
	if(!istype(location))
		return

	// Окно - основной вывод, но открыть его есть чем не всегда: без клиента
	// (мобы под ИИ, юнит-тесты) и на турфе без анализируемого воздуха остаётся чат.
	if(user.client && on_analyze(location))
		ui_interact(user)
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
			render_list += span_notice("Молей: [round(total_moles, 0.01)] mol\n\
									Объём: [volume] L\n\
									Давление: [round(pressure,0.01)] кПа\n\
									Температура: [round(temperature - T0C,0.01)] &deg;C ([round(temperature, 0.01)] K)")
			//WS End

			for(var/id in air_contents.get_gases())
				var/gas_concentration = air_contents.get_moles(id)/total_moles
				render_list += span_notice("[GLOB.gas_data.names[id]]: [round(gas_concentration*100, 0.01)] % ([round(air_contents.get_moles(id), 0.01)] mol)")  //WS Edit -- Atmos Analyzer Reformat (Issue #419)

		else
			render_list += airs.len > 1 ? span_notice("Этот узел пуст!") : span_notice("Внутри [target] пусто!")

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
	if(target.tool_act(user, src, click_parameters))
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
		var/list/lines = list()
		for(var/A in buffer)
			lines += "<span class='notice'>[get_display_name(A)]</span>"
		text += lines.Join("\n")
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

#undef HEALTH_ANALYZER_ALLOW_CHAT_MODE
