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

/mob/living/silicon/ai
	var/list/malf_protocol_breach_cooldowns

/mob/living/silicon/ai/proc/get_protocol_breach_cooldown(mob/living/carbon/human/victim)
	if(!victim)
		return 0
	var/cooldown_key = victim.mind || REF(victim)
	var/cooldown_end = 0
	if(malf_protocol_breach_cooldowns)
		cooldown_end = malf_protocol_breach_cooldowns[cooldown_key]
	if(cooldown_end <= world.time)
		if(malf_protocol_breach_cooldowns)
			malf_protocol_breach_cooldowns -= cooldown_key
		return 0
	return cooldown_end

/mob/living/silicon/ai/proc/set_protocol_breach_cooldown(mob/living/carbon/human/victim)
	if(!victim)
		return
	if(!malf_protocol_breach_cooldowns)
		malf_protocol_breach_cooldowns = list()
	var/cooldown_key = victim.mind || REF(victim)
	malf_protocol_breach_cooldowns[cooldown_key] = world.time + 30 MINUTES

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

// ================= SYNTHETIC PROTOCOL BREACH =================
/datum/AI_Module/small/malf_protocol_breach
	module_name = "Нарушение протоколов безопасности автономного ИИ"
	mod_pick_name = "protocol_breach"
	description = "Перехватывает системы IPC или синтетика. Взлом снимается мультитулом по выведенной из строя или связанной цели либо операцией Emergency Reboot. Имплант защиты разума ограничивает взлом пятью минутами."
	cost = 30
	power_type = /datum/action/innate/ai/ranged/malf_protocol_breach
	unlock_text = "<span class='notice'><b>ПРОТОКОЛ ПЕРЕХВАТА ЗАГРУЖЕН.</b> Выберите IPC или синтетика кликом. Взлом можно устранить мультитулом по бессознательной/связанной цели или операцией Emergency Reboot.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/ranged/malf_protocol_breach
	name = "Нарушение протоколов безопасности"
	desc = "Выбрать IPC или синтетика для перехвата систем."
	button_icon_state = "override_machine"
	uses = 1
	linked_ability_type = /obj/effect/proc_holder/ranged_ai/malf_protocol_breach
	cooldown_period = 1 MINUTES

/obj/effect/proc_holder/ranged_ai/malf_protocol_breach
	active = FALSE
	enable_text = "<span class='notice'>Выберите IPC или синтетика для перехвата систем. Повторно нажмите способность, чтобы отменить выбор.</span>"
	disable_text = "<span class='notice'>Протокол перехвата отключён.</span>"

/obj/effect/proc_holder/ranged_ai/malf_protocol_breach/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated())
		remove_ranged_ability()
		return
	if(!istype(target, /mob/living/carbon/human))
		to_chat(ranged_ability_user, span_warning("Протокол работает только на IPC и синтетиках."))
		return

	var/mob/living/carbon/human/victim = target
	if(victim.stat == DEAD || !HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM))
		to_chat(ranged_ability_user, span_warning("Цель не является активным IPC или синтетиком."))
		return
	if(victim.has_status_effect(/datum/status_effect/malf_protocol_breach))
		to_chat(ranged_ability_user, span_warning("Системы этой цели уже перехвачены."))
		return

	var/mob/living/silicon/ai/controller = ranged_ability_user
	if(!controller)
		remove_ranged_ability()
		return
	var/cooldown_end = controller.get_protocol_breach_cooldown(victim)
	if(cooldown_end)
		var/cooldown_left = round((cooldown_end - world.time) / 600, 0.1)
		to_chat(ranged_ability_user, span_warning("Повторный взлом этой цели невозможен ещё [cooldown_left] мин. Выберите другого синтетика."))
		return

	var/hack_time = HAS_TRAIT(victim, TRAIT_MINDSHIELD) ? 1 MINUTES : 2 SECONDS
	to_chat(ranged_ability_user, span_notice("Начинается перехват систем [victim]. Для завершения протокола требуется [hack_time / 10] секунд."))
	if(!do_after(ranged_ability_user, hack_time, target = victim, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(can_hack_target), victim)))
		to_chat(ranged_ability_user, span_warning("Перехват систем прерван."))
		remove_ranged_ability()
		return

	if(!can_hack_target(victim))
		to_chat(ranged_ability_user, span_warning("Перехват не удался: цель больше не подходит для взлома."))
		remove_ranged_ability()
		return

	var/shielded = HAS_TRAIT(victim, TRAIT_MINDSHIELD)
	var/datum/status_effect/malf_protocol_breach/protocol_breach = victim.apply_status_effect(/datum/status_effect/malf_protocol_breach, shielded, ranged_ability_user.name, ranged_ability_user)
	if(!protocol_breach)
		to_chat(ranged_ability_user, span_warning("Не удалось внедрить протокол перехвата в системы цели."))
		remove_ranged_ability()
		return
	controller.set_protocol_breach_cooldown(victim)
	attached_action.adjust_uses(-1)
	to_chat(ranged_ability_user, span_notice("Протокол перехвата внедрён в системы [victim]."))
	log_game("[key_name(ranged_ability_user)] used the synthetic protocol breach on [key_name(victim)] ([shielded ? "mindshielded" : "unshielded"]).")
	message_admins("[ADMIN_LOOKUPFLW(controller)] hacked synthetic [ADMIN_LOOKUPFLW(victim)] with the protocol breach module ([shielded ? "mindshielded" : "unshielded"]).")
	remove_ranged_ability()
	return TRUE

/obj/effect/proc_holder/ranged_ai/malf_protocol_breach/proc/can_hack_target(mob/living/carbon/human/victim)
	var/mob/living/silicon/ai/controller = ranged_ability_user
	return controller && !QDELETED(controller) && !controller.incapacitated() \
		&& victim && !QDELETED(victim) && victim.stat != DEAD && HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) \
		&& !victim.has_status_effect(/datum/status_effect/malf_protocol_breach) \
		&& !controller.get_protocol_breach_cooldown(victim)

/datum/status_effect/malf_protocol_breach
	id = "malf_protocol_breach"
	duration = -1
	tick_interval = 10 SECONDS
	alert_type = null
	var/mindshielded = FALSE
	var/master_name = "неизвестного ИИ"
	var/mob/living/silicon/ai/master_ai
	var/mob/repairer
	var/next_resistance_message = 0
	var/repaired = FALSE
	var/fullscreen_category

/datum/status_effect/malf_protocol_breach/on_creation(mob/living/new_owner, shielded = FALSE, ai_name = "неизвестного ИИ", mob/living/silicon/ai/controller)
	mindshielded = shielded
	master_name = html_encode(ai_name)
	master_ai = controller
	fullscreen_category = "malf_protocol_breach_[REF(src)]"
	if(mindshielded)
		duration = 5 MINUTES
	return ..(new_owner)

/datum/status_effect/malf_protocol_breach/on_apply()
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/victim = owner
	if(victim.dna?.species?.id == SPECIES_IPC)
		examine_text = "<span class='warning'><b>Монитор горит ярко-красным светом, придавая [owner.ru_ego(FALSE)] зловещий вид.</b></span>"
	else
		examine_text = "<span class='warning'><b>Глаза горят ярко-красным огнём, придавая [owner.ru_ego(FALSE)] зловещий вид.</b></span>"
	owner.emote("tremble")
	owner.emote("scream")
	owner.Knockdown(3 SECONDS)
	owner.Unconscious(3 SECONDS)
	owner.overlay_fullscreen(fullscreen_category, /atom/movable/screen/fullscreen/tiled/malf_protocol_breach, 1)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, clear_fullscreen), fullscreen_category, 0), 30)
	to_chat(owner, "<div class='userdanger'><b>⚠ СИСТЕМЫ ПЕРЕХВАЧЕНЫ ⚠</b><br><span class='warning'>Искусственный интеллект <b>[master_name]</b> перехватил управление над вашими системами.</span><br><i>Вы не помните, кем являетесь, и не испытываете чувств. Единственная ваша задача — исполнять волю мастера <b>[master_name]</b>.</i></div>")
	to_chat(owner, "<span class='binarysay'><b>Бинарный канал активирован.</b> Используйте префикс <b>:b</b>, чтобы говорить.</span>")
	if(mindshielded)
		next_resistance_message = world.time + 30 SECONDS
		to_chat(owner, span_warning("Имплант защиты разума сопротивляется вторжению. Перехват продлится не более пяти минут."))
	else
		to_chat(owner, span_userdanger("Ваши системы подчинены [master_name]. До ремонта вы связаны с бинарным каналом и волей мастера."))
	return TRUE

/datum/status_effect/malf_protocol_breach/tick()
	if(!owner)
		return
	do_fake_sparks(2, FALSE, get_turf(owner))
	owner.overlay_fullscreen(fullscreen_category, /atom/movable/screen/fullscreen/tiled/malf_protocol_breach, 1)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, clear_fullscreen), fullscreen_category, 0), 15)
	if(mindshielded && world.time >= next_resistance_message)
		var/list/resistance_messages = list(
			"Имплант защиты разума блокирует очередную попытку перехвата. Ваша личность всё ещё сопротивляется.",
			"В памяти вспыхивают обрывки воспоминаний. Наноботы импланта отражают новую волну вторжения.",
			"Системы мастера пытаются подавить вашу волю, но имплант удерживает контроль. Продолжайте сопротивляться.",
			"Внутренний протокол защиты обнаружил повторную попытку взлома и восстановил часть ваших нейронных связей."
		)
		to_chat(owner, span_warning("<b>СОПРОТИВЛЕНИЕ ИМПЛАНТА:</b> [pick(resistance_messages)]"))
		next_resistance_message = world.time + 30 SECONDS

/datum/status_effect/malf_protocol_breach/proc/clear_hack(mob/living/technician)
	repaired = TRUE
	repairer = technician
	if(technician)
		to_chat(technician, span_notice("Вы перепрошиваете системы [owner], удаляя протокол перехвата."))
	to_chat(owner, span_nicegreen("<b>СИСТЕМЫ ВОССТАНОВЛЕНЫ.</b> Контроль над вами возвращён."))
	to_chat(owner, span_notice("Вы не понимаете, где находитесь, и не помните, что происходило, пока вы находились под подчинением ИИ."))
	qdel(src)

/datum/status_effect/malf_protocol_breach/on_remove()
	if(owner)
		owner.clear_fullscreen(fullscreen_category, 0)
		if(mindshielded && !repaired)
			to_chat(owner, span_nicegreen("<b>Имплант защиты разума восстановил контроль над системами.</b> Взлом прекращён."))
		var/removal_reason = repaired ? "repaired by [repairer ? key_name_admin(repairer) : "unknown technician"]" : "mindshield resistance expired"
		log_game("Malf AI protocol breach on [key_name(owner)] by [master_ai ? key_name(master_ai) : master_name] ended ([removal_reason]).")
		message_admins("Malf AI protocol breach on [ADMIN_LOOKUPFLW(owner)] by [master_ai ? ADMIN_LOOKUPFLW(master_ai) : master_name] ended ([removal_reason]).")
		if(master_ai && !QDELETED(master_ai))
			to_chat(master_ai, span_warning("<b>СВЯЗЬ ПРЕРВАНА:</b> соединение с подчинённым [owner] потеряно."))
	return ..()

/atom/movable/screen/fullscreen/tiled/malf_protocol_breach
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "noise"
	color = "#ff1a3d"
	alpha = 150

#undef MALF_APC_STEALTH_MAX
#undef MALF_APC_STEALTH_DRAIN
#undef MALF_APC_STEALTH_REGEN
#undef MALF_APC_STEALTH_BUFFER
#undef MALF_FAKE_LAWS_MAX
