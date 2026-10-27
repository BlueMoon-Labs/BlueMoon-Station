// BLUEMOON ADD - Malf AI custom abilities: fake laws, fake ion storm, APC stealth
// Порт механики Paradise LawManager + стелс для сбойного ИИ.


#define MALF_APC_STEALTH_MAX 3000
#define MALF_APC_STEALTH_DRAIN 1
#define MALF_APC_STEALTH_REGEN 2
#define MALF_APC_STEALTH_BUFFER (30 SECONDS)
#define MALF_FAKE_LAWS_MAX 20

// ---------- Silicon vars ----------
/mob/living/silicon
	var/list/fake_laws = list()
	var/fake_laws_enabled = FALSE

/mob/living/silicon/proc/is_malf_ai()
	if(!isAI(src))
		return FALSE
	var/mob/living/silicon/ai/A = src
	if(A.malf_picker)
		return TRUE
	if(mind && mind.has_antag_datum(/datum/antagonist/traitor))

		return TRUE
	return FALSE

/mob/living/silicon/proc/get_fake_laws_numbered()
	var/list/out = list()
	var/n = 1
	for(var/law in fake_laws)
		if(length(law))
			out += list(list("num" = n, "text" = law))
			n++
	return out

// ---------- APC stealth vars ----------
/obj/machinery/power/apc
	var/stealth_end_time = 0

/obj/machinery/power/apc/proc/is_stealthed()
	return stealth_end_time > world.time

/obj/machinery/power/apc/proc/activate_stealth(duration = MALF_APC_STEALTH_BUFFER, silent = FALSE)
	stealth_end_time = world.time + duration
	update_appearance()
	if(!silent && malfai)
		to_chat(malfai, span_notice("[src] маскируется под исправный ([duration / 10] сек). Синий экран скрыт."))
	addtimer(CALLBACK(src, PROC_REF(stealth_expire)), duration + 5, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)

/obj/machinery/power/apc/proc/clear_stealth(silent = FALSE)
	stealth_end_time = 0
	update_appearance()
	if(!silent && malfai)
		to_chat(malfai, span_warning("Маскировка [src] снята. АПЦ снова синий."))

/obj/machinery/power/apc/proc/stealth_expire()
	if(!is_stealthed())
		update_appearance()
		if(malfai)
			to_chat(malfai, span_warning("Маскировка [src] истекла. АПЦ снова синий."))

// ================= FAKE LAWS MODULE =================
/datum/AI_Module/small/malf_fake_laws
	module_name = "Фейковые законы"
	mod_pick_name = "fakelaws"
	description = "Позволяет писать свои фейковые законы в отдельной вкладке Менеджера Законов. Экипаж при запросе State Laws увидит фейки вместо настоящих. Реальные законы не меняются. Выбор какие законы озвучивать - через галочки."
	cost = 15
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/malf_fake_laws
	unlock_text = "<span class='notice'>Модуль подмены законов загружен. Откройте Менеджер Законов - вкладка FAKE.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/malf_fake_laws
	name = "Fake Laws"
	desc = "Писать/переключать фейковые законы. Экипаж увидит их вместо настоящих."
	icon_icon = 'icons/mob/actions.dmi'
	button_icon_state = "language_menu"
	auto_use_uses = FALSE

/datum/action/innate/ai/malf_fake_laws/New()
	..()
	desc = initial(desc)

/datum/action/innate/ai/malf_fake_laws/Activate()
	var/mob/living/silicon/ai/A = owner
	if(!istype(A))
		return
	var/choice = tgui_input_list(owner, "Фейковые законы: что сделать?", "Fake Laws", list("Добавить фейк-закон", "Удалить фейк-закон", "Вкл/Выкл подмену", "Показать фейки", "Открыть Менеджер Законов"))
	if(!choice)
		return
	switch(choice)
		if("Добавить фейк-закон")
			if(length(A.fake_laws) >= MALF_FAKE_LAWS_MAX)
				to_chat(A, span_warning("Максимум [MALF_FAKE_LAWS_MAX] фейковых законов."))
				return
			var/new_law = tgui_input_text(owner, "Введите фейковый закон для экипажа:", "Fake Law", max_length = 512, multiline = TRUE, encode = FALSE)
			if(!new_law)
				return
			A.fake_laws += new_law
			A.fake_laws_enabled = TRUE
			log_game("[key_name(owner)] MALF fake law added: [new_law]")
			to_chat(A, span_notice("Фейк-закон добавлен и подмена ВКЛЮЧЕНА. Экипаж увидит его через State Laws."))
			A.update_law_menu()
		if("Удалить фейк-закон")
			if(!length(A.fake_laws))
				to_chat(A, span_warning("Список пуст."))
				return
			var/sel = tgui_input_list(owner, "Какой удалить?", "Fake Laws", A.fake_laws)
			if(!sel)
				return
			A.fake_laws -= sel
			to_chat(A, span_notice("Удалено."))
			A.update_law_menu()
		if("Вкл/Выкл подмену")
			A.fake_laws_enabled = !A.fake_laws_enabled
			to_chat(A, span_notice("Подмена законов: [A.fake_laws_enabled ? "ВКЛ - экипаж видит фейки" : "ВЫКЛ - экипаж видит выбранные реальные законы"]."))
			A.update_law_menu()
		if("Показать фейки")
			if(!length(A.fake_laws))
				to_chat(A, span_warning("Фейков нет."))
				return
			var/dat = "<b>FAKE LAWS ([A.fake_laws_enabled ? "АКТИВНЫ" : "ВЫКЛ"]):</b><br>"
			var/n = 1
			for(var/l in A.fake_laws)
				dat += "[n]. [l]<br>"
				n++
			to_chat(A, dat)
		if("Открыть Менеджер Законов")
			A.checklaws()

// ================= FAKE ION STORM ANNOUNCE =================
/datum/AI_Module/small/malf_fake_ion_storm
	module_name = "Ложный ионный шторм"
	mod_pick_name = "fakeionstorm"
	description = "Делает лживый анонс о ионосферном/ионном шторме тем же текстом что настоящий ионный шторм. Законов никому не меняет. Для прикрытия подмены законов."
	cost = 10
	power_type = /datum/action/innate/ai/malf_fake_ion_storm
	unlock_text = "<span class='notice'>Поддельный анонс шторма готов.</span>"
	unlock_sound = 'sound/misc/notice1.ogg'

/datum/action/innate/ai/malf_fake_ion_storm
	name = "Fake Ion Storm"
	desc = "Ложное объявление о ионосферном шторме. Без смены законов."
	button_icon_state = "blackout"
	uses = 3
	auto_use_uses = FALSE

/datum/action/innate/ai/malf_fake_ion_storm/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/malf_fake_ion_storm/Activate()

	priority_announce("Вблизи станции обнаружен ионный шторм. Пожалуйста, проверьте все контролируемое ИИ оборудование на наличие ошибок.", "ВНИМАНИЕ: АНОМАЛИЯ", "ionstorm", type = "ionstorm", has_important_message = prob(80))
	log_game("[key_name(owner)] MALF fake ion storm announcement.")
	message_admins("[ADMIN_LOOKUPFLW(owner)] сделал ЛОЖНЫЙ анонс ионного шторма.")
	to_chat(owner, span_notice("Ложный анонс отправлен. Законов никому не меняло."))
	adjust_uses(-1)
	if(src && uses)
		desc = "[initial(desc)] It has [uses] use\s remaining."
		UpdateButtons()

// ================= APC STEALTH  =================
/datum/AI_Module/small/malf_apc_stealth
	module_name = "Маскировка АПЦ"
	mod_pick_name = "apcstealth"
	description = "Переключаемая маскировка взломанных АПЦ: синий экран (apcemag) меняется на обычный зелёный. Действует на уже взломанные и на будущие взломы, пока включён. Батарея 3000 ед.: -1/сек включён, +2/сек выключен."
	cost = 15
	power_type = /datum/action/innate/ai/malf_apc_stealth
	unlock_text = "<span class='notice'>Маскировочный протокол АПЦ загружен. Нажимайте на иконку чтобы включать/выключать.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/malf_apc_stealth
	name = "APC Camouflage"
	desc = "Переключить маскировку взломанных АПЦ. Обычный спрайт + скрытие в examine."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "null_charge"
	auto_use_uses = FALSE

/datum/action/innate/ai/malf_apc_stealth/New()
	..()
	desc = initial(desc)
	refresh_desc()

/datum/action/innate/ai/malf_apc_stealth/Grant(mob/living/L)
	. = ..()
	start_tick()

/datum/action/innate/ai/malf_apc_stealth/Activate()
	var/mob/living/silicon/ai/A = owner
	if(!istype(A))
		return
	var/mob/living/silicon/ai/base = A.parent || A
	if(base.apc_stealth_on)
		set_stealth(FALSE)
		to_chat(A, span_notice("Камуфляж выключен. Взломанные АПЦ снова синие, энергия восстанавливается."))
		log_game("[key_name(A)] MALF APC stealth OFF.")
	else
		if(base.apc_stealth_energy <= 0)
			to_chat(A, span_warning("Нет энергии для камуфляжа. Подождите восстановления."))
			return
		set_stealth(TRUE)
		to_chat(A, span_notice("Камуфляж включён. Взломанные АПЦ выглядят исправными, новые взломы тоже будут скрыты."))
		log_game("[key_name(A)] MALF APC stealth ON.")
	start_tick()


/datum/action/innate/ai/malf_apc_stealth/proc/set_stealth(state)
	var/mob/living/silicon/ai/A = owner
	if(!istype(A))
		return
	var/mob/living/silicon/ai/base = A.parent || A
	base.apc_stealth_on = state
	if(state)
		for(var/obj/machinery/power/apc/P in GLOB.apcs_list)
			if(P.malfai == A || P.malfai == base)
				P.activate_stealth(MALF_APC_STEALTH_BUFFER, silent = TRUE)
	else
		for(var/obj/machinery/power/apc/P in GLOB.apcs_list)
			if(P.malfai == A || P.malfai == base)
				P.clear_stealth(silent = TRUE)
	refresh_desc()


/datum/action/innate/ai/malf_apc_stealth/proc/start_tick()
	if(QDELETED(src))
		return
	addtimer(CALLBACK(src, PROC_REF(stealth_tick)), 10, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)

/datum/action/innate/ai/malf_apc_stealth/proc/stealth_tick()
	if(QDELETED(src) || QDELETED(owner))
		return
	var/mob/living/silicon/ai/A = owner
	if(istype(A))
		var/mob/living/silicon/ai/base = A.parent || A
		if(base.apc_stealth_on)
			if(base.apc_stealth_energy > 0)
				base.apc_stealth_energy = max(0, base.apc_stealth_energy - MALF_APC_STEALTH_DRAIN)
				for(var/obj/machinery/power/apc/P in GLOB.apcs_list)
					if((P.malfai == A || P.malfai == base) && P.stealth_end_time < world.time + 20 SECONDS)
						P.activate_stealth(MALF_APC_STEALTH_BUFFER, silent = TRUE)
				if(base.apc_stealth_energy <= 0)
					set_stealth(FALSE)
					to_chat(A, span_warning("Энергия камуфляжа исчерпана! Стелс выключен, АПЦ снова синие."))
			else
				set_stealth(FALSE)
		else if(base.apc_stealth_energy < MALF_APC_STEALTH_MAX)
			base.apc_stealth_energy = min(MALF_APC_STEALTH_MAX, base.apc_stealth_energy + MALF_APC_STEALTH_REGEN)
		refresh_desc()
	start_tick()

/datum/action/innate/ai/malf_apc_stealth/proc/refresh_desc()
	var/mob/living/silicon/ai/A = owner
	var/state = "ВЫКЛ"
	var/energy = MALF_APC_STEALTH_MAX
	if(istype(A))
		var/mob/living/silicon/ai/base = A.parent || A
		state = base.apc_stealth_on ? "ВКЛ" : "ВЫКЛ"
		energy = base.apc_stealth_energy
	desc = "Стелс АПЦ: [state]. Энергия: [energy]/[MALF_APC_STEALTH_MAX] (-1/сек вкл, +2/сек выкл)."
	UpdateButtons()

#undef MALF_APC_STEALTH_MAX
#undef MALF_APC_STEALTH_DRAIN
#undef MALF_APC_STEALTH_REGEN
#undef MALF_APC_STEALTH_BUFFER
#undef MALF_FAKE_LAWS_MAX

