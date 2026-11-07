/datum/antagonist/hk47
	name = "HK-47 Assassin Droid"
	antagpanel_category = "HK-47"
	job_rank = ROLE_HK47
	antag_hud_type = ANTAG_HUD_NINJA
	antag_hud_name = "hk47"
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	/// Очки за контракты, тратятся на улучшения.
	var/points = 0
	var/contracts_done = 0
	/// Ключ голосовой строки -> звук.
	var/static/list/voice_lines = list(
		"hk47_activate" = 'modular_bluemoon/sound/hk_droids/hk47_activate.ogg',
		"hk47_ready" = 'modular_bluemoon/sound/hk_droids/hk47_ready.ogg',
		"hk47_offer" = 'modular_bluemoon/sound/hk_droids/hk47_offer.ogg',
		"hk47_accept" = 'modular_bluemoon/sound/hk_droids/hk47_accept.ogg',
		"hk47_target_acquired" = 'modular_bluemoon/sound/hk_droids/hk47_target_acquired.ogg',
		"hk47_combat_mode" = 'modular_bluemoon/sound/hk_droids/hk47_combat_mode.ogg',
		"hk47_damage" = 'modular_bluemoon/sound/hk_droids/hk47_damage.ogg',
		"hk47_failing" = 'modular_bluemoon/sound/hk_droids/hk47_failing.ogg',
		"hk47_stealth" = 'modular_bluemoon/sound/hk_droids/hk47_stealth.ogg',
		"hk47_full_gain" = 'modular_bluemoon/sound/hk_droids/hk47_full_gain.ogg',
		"hk47_rejoining" = 'modular_bluemoon/sound/hk_droids/hk47_rejoining.ogg',
		"hk47_meatbags" = 'modular_bluemoon/sound/hk_droids/hk47_meatbags.ogg',
		"hk47_charging" = 'modular_bluemoon/sound/hk_droids/hk47_charging.ogg',
		"hk47_purchased" = 'modular_bluemoon/sound/hk_droids/hk47_purchased.ogg',
		"hk47_prospective" = 'modular_bluemoon/sound/hk_droids/hk47_prospective.ogg',
		"hk47_unlock_begin" = 'modular_bluemoon/sound/hk_droids/hk47_unlock_begin.ogg',
		"hk47_unlock_success" = 'modular_bluemoon/sound/hk_droids/hk47_unlock_success.ogg',
		"hk47_unlock_failed" = 'modular_bluemoon/sound/hk_droids/hk47_unlock_failed.ogg',
		"hk47_scan" = 'modular_bluemoon/sound/hk_droids/hk47_scan.ogg',
		"hk47_self_diagnostic" = 'modular_bluemoon/sound/hk_droids/hk47_self_diagnostic.ogg',
		"hk47_recite_shields" = 'modular_bluemoon/sound/hk_droids/hk47_recite_shields.ogg',
		"hk47_accuracy" = 'modular_bluemoon/sound/hk_droids/hk47_accuracy.ogg',
		"hk47_prejudice" = 'modular_bluemoon/sound/hk_droids/hk47_prejudice.ogg',
		"hk47_crude" = 'modular_bluemoon/sound/hk_droids/hk47_crude.ogg',
	)
	/// Служебные строки терминала и модулей: их слышит только сам HK, иначе они выдают его.
	var/static/list/private_voice_lines = list("hk47_offer", "hk47_accept", "hk47_stealth", "hk47_charging", "hk47_full_gain", "hk47_scan", "hk47_self_diagnostic", "hk47_recite_shields", "hk47_accuracy")
	var/last_voice
	COOLDOWN_DECLARE(voice_cooldown)

/datum/antagonist/hk47/on_gain()
	owner.special_role = ROLE_HK47
	var/datum/objective/hk47_contracts/contracts = new
	contracts.owner = owner
	objectives += contracts
	var/datum/objective/hk47_extract/extract = new
	extract.owner = owner
	objectives += extract
	antag_memory += "Я - HK-47, дроид-ассасин. Выполнить [HK47_CONTRACTS_TO_WIN] контракта заказчиков и эвакуироваться. Перепрошивка экипажем отнимет у меня контракты, ЭМИ валит с ног. Шлюзы техтоннелей открываются передо мной без карты, двери отделов - с чужой картой, щупом или считанным доступом.<br>"
	return ..()

/// Роль держится на шасси HK-47: другому телу или мозгу без тела админка собирает новое шасси с прибытием по легенде.
/datum/antagonist/hk47/admin_add(datum/mind/new_owner, mob/admin)
	var/mob/living/carbon/human/body = new_owner.current
	if(ishuman(body) && istype(body.dna?.species, /datum/species/ipc/hk/hk47))
		return ..()
	if(!new_owner.key)
		to_chat(admin, span_warning("У [new_owner.name] нет игрока: HK-47 некого посадить в шасси."))
		return
	if(tgui_alert(admin, "[new_owner.name] не в шасси HK-47. Собрать новое шасси и отправить игрока на станцию по случайной легенде?", "HK-47", list("Да", "Нет")) != "Да")
		return
	var/turf/landing = hk47_find_maintenance_turf() || get_turf(admin)
	var/datum/round_event/ghost_role/hk47/event = new(FALSE)
	var/mob/living/carbon/human/droid = event.launch_hk47(new_owner.key, landing)
	event.kill()
	message_admins("[key_name_admin(admin)] made [key_name_admin(droid)] into [name] in a new chassis.")
	log_admin("[key_name(admin)] made [key_name(droid)] into [name] in a new chassis.")

/datum/antagonist/hk47/on_removal()
	if(owner.special_role == ROLE_HK47)
		owner.special_role = null
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	var/datum/mind/master = reprogram_master()
	if(master && show_in_roundend)
		new /datum/team/hk47_record(owner, master.name, hk_master_is_antagonist(master), roundend_details())
	return ..()

/datum/antagonist/hk47/Destroy()
	QDEL_LIST(objectives)
	return ..()

/datum/antagonist/hk47/apply_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, body)
	if(body)
		RegisterSignal(body, COMSIG_MOB_ALLOWED, PROC_REF(tunnel_access))
	if(needs_spike())
		grant_spike(body)
	body?.AddComponent(/datum/component/hk47_voice_cues)
	apply_contract_effects(body)
	apply_status_effects(body)
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_find_rifle(body)
	var/obj/item/firing_pin/hk/hk_pin = rifle?.pin
	if(istype(hk_pin))
		hk_pin.claim(body)

/datum/antagonist/hk47/remove_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || owner.current
	remove_antag_hud(antag_hud_type, body)
	if(body)
		UnregisterSignal(body, COMSIG_MOB_ALLOWED)
	revoke_spike(body)
	qdel(body?.GetComponent(/datum/component/hk47_voice_cues))
	remove_contract_effects(body)
	remove_status_effects(body)

/// Код техтоннелей и доступы, считанные щупом, открывают то же, что карта с ними.
/datum/antagonist/hk47/proc/tunnel_access(mob/living/source, obj/target)
	SIGNAL_HANDLER
	return target.check_access_list(chassis_access())

/datum/antagonist/hk47/greet()
	var/mob/living/droid = owner.current
	to_chat(droid, span_userdanger("Утверждение: HK-47 активирован. Основная функция - ликвидация."))
	to_chat(droid, span_warning("Вы - HK-47, дроид-ассасин серии HK. Как вы прибываете и что знает о вас станция, скажет следующее сообщение - легенда прибытия."))
	to_chat(droid, span_notice("<b>Контракты.</b> Заказы приходят на встроенный терминал (кнопка действия), активен один. Очки за контракты идут на модули, и каждый следующий модуль шасси дороже. Цели подбираются по согласию игроков: HUD согласия показывает, кого можно убить, а кого - только вывести из игры."))
	to_chat(droid, span_warning("<b>Свидетели.</b> Грязная работа - заказы Синдиката, конкурентов и частных лиц против станции. Свидетелей в [HK47_WITNESS_RANGE] клетках считают в решающие моменты: попадание по цели, её смерть после попадания, добыча кражи в руке (ID, печать или ценность), вызов капсулы и закрытие контракта. Раскрытие поднимает ступень: ЦК объявляет станции о дроиде-ассасине и СБ приказано арестовать вас, затем СБ получает пеленгатор, а карго - заказ на ваше ядро, затем приказ уничтожить и ионное оружие в бриг. Пеленгатор и ионное оружие доставляются один раз. Контракт ЦК закрывает одно дело, и приказ СБ следует за оставшимися делами: без них розыск снимается, а пеленгатор замолкает. После [HK47_CONTRACTS_TO_WIN] выполненных контрактов каждая грязная работа раскрывает вас и без свидетелей."))
	to_chat(droid, span_warning("<b>Лицензия.</b> Если легенда дала лицензию, она действует, пока идёт её контракт, и истекает вместе с ним. Её отзывают, если член экипажа погибнет в течение [DisplayTimeText(HK47_HIT_MEMORY)] после вашего попадания или попадания ваших слуг; цель контракта, разыскиваемые СБ и напавшие на вас или охраняемого за последние [DisplayTimeText(HK47_AGGRESSION_MEMORY)] не в счёт."))
	to_chat(droid, span_notice("<b>Финал.</b> После [HK47_CONTRACTS_TO_WIN] контрактов терминал открывает эвакуацию: [DisplayTimeText(HK47_EXTRACTION_TIME)] сигнала у открытого космоса, прерванный сигнал можно повторить через [DisplayTimeText(HK47_EXTRACTION_RETRY_COOLDOWN)]. Можно и улететь живым на эвакуационном шаттле вне брига."))
	to_chat(droid, span_warning("<b>Угрозы.</b> ЭМИ и ионное оружие отключают шасси на [HK_EMP_HEAVY_STUN / (1 SECONDS)] с (снова - не раньше чем через [HK_EMP_STUN_COOLDOWN / (1 SECONDS)] с). Обездвиженного HK экипаж может перепрошить операцией на голове - тогда вы служите тому, кто перепрошил. Винтовка стреляет только в ваших руках, одежда и броня на шасси не надеваются. Приводы не устают: дубинки и дизейблеры отнимают у шасси меньше выносливости, чем у человека, а ЭМИ валит его как прежде."))
	to_chat(droid, span_notice("<b>Доступ.</b> Код техтоннелей встроен в шасси: шлюзы техобслуживания открываются без карты. Двери отделов откроет чужая ID-карта в слоте ID, щуп с модулем «Взломщик шлюзов» (шумно) или копия чужого доступа модулем «Считыватель доступа» (тихо)."))
	to_chat(droid, span_notice("<b>Заряд.</b> Винтовка, щит, взлом и самовосстановление тратят заряд шасси. Пополняет его шнур питания из руки (кнопка действия), воткнутый в APC."))
	owner.announce_objectives()
	hk_voice("hk47_activate", forced = TRUE)

/datum/antagonist/hk47/roundend_report()
	var/list/report = list(printplayer(owner))
	report += roundend_details()
	report += "Эвакуация: [evacuation_text()]."
	var/won = TRUE
	var/count = 1
	for(var/datum/objective/objective as anything in objectives)
		var/completion = objective.check_completion()
		var/verdict = span_greentext("Успех!")
		if(completion <= 0)
			verdict = span_redtext("Провал.")
			won = FALSE
		else if(completion < 1)
			verdict = "<span class='yellowtext'>[round(completion * 100)]%</span>"
			won = FALSE
		report += "<b>Цель #[count]</b>: [objective.explanation_text] [verdict]"
		count++
	if(won)
		report += "<span class='greentext big'>HK-47 выполнил контракты и ушёл со станции!</span>"
	else
		report += "<span class='redtext big'>HK-47 не довёл работу до конца.</span>"
	return report.Join("<br>")

/// Строки отчёта раунда: контракты, путь статуса, журнал заказов и модули.
/datum/antagonist/hk47/proc/roundend_details()
	var/list/lines = list()
	lines += "Контрактов выполнено: [contracts_done] из [HK47_CONTRACTS_TO_WIN]."
	lines += "Статус для станции: [status_path_text()]; раскрытий грязной работы: [reveals]."
	if(!length(contract_history) && !active_contract)
		lines += "Журнал контрактов пуст."
	else
		lines += "<b>Журнал контрактов:</b>"
		for(var/list/entry as anything in contract_history)
			var/earned = entry["points"]
			lines += "[FOURSPACES]- [entry["contract"]][hk47_hidden_target_note(entry["contract"], entry["target_name"])]: [entry["outcome_text"] || hk47_outcome_name(entry["outcome"])][earned ? " (очков: [earned])" : ""]"
		if(active_contract)
			var/active_text = active_contract.describe()
			lines += "[FOURSPACES]- [active_text][hk47_hidden_target_note(active_text, active_contract.target_name)]: не закрыт к концу смены"
	lines += "Модули: [upgrades_text()]."
	return lines

/// Имя цели для отчёта, если описание контракта его не называет: неопознанная цель охоты.
/proc/hk47_hidden_target_note(contract_text, target_name)
	if(!target_name || findtext(contract_text, target_name))
		return ""
	return " (цель: [target_name])"

/datum/antagonist/hk47/proc/upgrades_text()
	var/list/bought = list()
	for(var/upgrade_id in GLOB.hk47_upgrades)
		var/count = upgrades[upgrade_id]
		if(!count)
			continue
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_id]
		bought += count > 1 ? "[upgrade.name] x[count]" : upgrade.name
	return length(bought) ? jointext(bought, ", ") : "не покупал"

/datum/antagonist/hk47/proc/evacuation_text()
	if(extracted)
		return "капсулой после [HK47_CONTRACTS_TO_WIN] контрактов"
	var/datum/objective/hk47_extract/extract = locate() in objectives
	if(extract?.check_completion())
		return "живым на эвакуационном шаттле"
	return "не эвакуировался"

/// Разум, который перепрошил HK: хозяин блока лояльности, если это не сам HK.
/datum/antagonist/hk47/proc/reprogram_master()
	var/datum/component/hk_loyalty/loyalty = owner.current?.GetComponent(/datum/component/hk_loyalty)
	var/datum/mind/master = loyalty?.get_master()
	return master != owner ? master : null

/proc/hk47_outcome_name(outcome)
	switch(outcome)
		if(HK_CONTRACT_DONE)
			return "выполнен"
		if(HK_CONTRACT_FAILED)
			return "провален"
		if(HK_CONTRACT_REFUSED)
			return "отклонён"
		if(HK_CONTRACT_DROPPED)
			return "снят: цель недоступна"
	return outcome

/datum/antagonist/hk47/proc/award(amount)
	points += amount
	to_chat(owner.current, span_notice("Утверждение: начислено очков - [amount], на счету [points]."))

/// Голосовая строка с кулдауном на дроида; forced - для прибытия, смерти и перепрошивки. Кулдаун встаёт, только если строка прозвучала.
/datum/antagonist/hk47/proc/hk_voice(sound_key, forced = FALSE)
	var/voice = voice_lines[sound_key]
	var/mob/living/droid = owner?.current
	if(!voice || !droid)
		return FALSE
	if(!forced && !COOLDOWN_FINISHED(src, voice_cooldown))
		return FALSE
	if(!play_voice(droid, voice, voice_is_private(droid, sound_key)))
		return FALSE
	COOLDOWN_START(src, voice_cooldown, HK47_VOICE_COOLDOWN)
	last_voice = sound_key
	return TRUE

/// Служебные строки слышит только сам HK; в маскировке - все, кроме приветствия протокольного дроида.
/datum/antagonist/hk47/proc/voice_is_private(mob/living/droid, sound_key)
	if(sound_key in private_voice_lines)
		return TRUE
	return HAS_TRAIT(droid, TRAIT_HK47_DISGUISED) && sound_key != "hk47_prospective"

/datum/antagonist/hk47/proc/play_voice(mob/living/droid, voice, private)
	return hk_voice_line(droid, voice, private)

/// HK-47, которого перепрошил экипаж: роли больше нет, но отчёт раунда его помнит.
/datum/team/hk47_record
	name = "HK-47"
	member_name = "HK-47"
	var/datum/weakref/droid_mind_ref
	var/master_name
	var/master_was_antagonist = FALSE
	var/list/details

/datum/team/hk47_record/New(datum/mind/droid_mind, master_name, master_was_antagonist, list/details)
	. = ..(null)
	droid_mind_ref = WEAKREF(droid_mind)
	src.master_name = master_name
	src.master_was_antagonist = master_was_antagonist
	src.details = details

/datum/team/hk47_record/roundend_report()
	var/datum/mind/droid_mind = droid_mind_ref?.resolve()
	var/list/report = list("<span class='header'>HK-47 Assassin Droid</span>")
	report += droid_mind ? printplayer(droid_mind) : HK47_NAME
	report += "Перепрошит: хозяин - [master_name], дальше служил [master_was_antagonist ? "ему и его команде" : "на стороне станции"]."
	report += details
	report += "Эвакуация: нет, роль снята перепрошивкой."
	return "<div class='panel redborder'>[report.Join("<br>")]</div>"

/// Голос HK-47 в бою: режим боя после затишья, тяжёлые повреждения, крит, отключение, запуск после ремонта и посадка.
/datum/component/hk47_voice_cues
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/last_combat_time
	var/last_failing_time
	/// Строка о повреждениях снова зазвучит, когда прочность поднимется выше порога.
	var/damage_line_armed = TRUE

/datum/component/hk47_voice_cues/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/hk47_voice_cues/RegisterWithParent()
	RegisterSignals(parent, list(COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_LIVING_ATTACKER_SET), PROC_REF(on_combat))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(parent, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignal(parent, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))

/datum/component/hk47_voice_cues/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_LIVING_ATTACKER_SET, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOB_STATCHANGE, COMSIG_LIVING_REVIVE, COMSIG_MOVABLE_MOVED))

/datum/component/hk47_voice_cues/proc/on_combat(mob/living/source)
	SIGNAL_HANDLER
	note_combat()

/datum/component/hk47_voice_cues/proc/note_combat()
	var/mob/living/droid = parent
	var/calm = isnull(last_combat_time) || world.time - last_combat_time >= HK47_COMBAT_CALM_TIME
	last_combat_time = world.time
	if(!calm || droid.stat != CONSCIOUS)
		return FALSE
	return hk47_upgrade_voice(droid, "hk47_combat_mode")

/// Урон ещё не списан, когда приходит сигнал: прочность смотрим на следующем тике.
/datum/component/hk47_voice_cues/proc/on_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage > 0 && damagetype != STAMINA)
		addtimer(CALLBACK(src, PROC_REF(check_damage_line)), 0.1 SECONDS, TIMER_UNIQUE)

/datum/component/hk47_voice_cues/proc/check_damage_line()
	var/mob/living/droid = parent
	if(droid.stat == DEAD)
		return FALSE
	if(droid.InCritical())
		damage_line_armed = FALSE
		return FALSE
	if(droid.health >= droid.maxHealth * HK47_DAMAGE_LINE_HEALTH)
		damage_line_armed = TRUE
		return FALSE
	if(!damage_line_armed || !hk47_upgrade_voice(droid, "hk47_damage"))
		return FALSE
	damage_line_armed = FALSE
	return TRUE

/datum/component/hk47_voice_cues/proc/on_stat_change(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat == DEAD)
		if(isnull(last_failing_time) || world.time - last_failing_time >= HK47_VOICE_COOLDOWN)
			say_failing(forced = TRUE)
		return
	if(old_stat == CONSCIOUS && source.InCritical())
		say_failing()

/datum/component/hk47_voice_cues/proc/say_failing(forced = FALSE)
	damage_line_armed = FALSE
	if(!hk47_upgrade_voice(parent, "hk47_failing", forced))
		return FALSE
	last_failing_time = world.time
	return TRUE

/datum/component/hk47_voice_cues/proc/on_revive(mob/living/source)
	SIGNAL_HANDLER
	damage_line_armed = TRUE
	last_failing_time = null
	hk47_upgrade_voice(source, "hk47_activate", forced = TRUE)

/datum/objective/hk47_contracts
	name = "HK-47 contracts"

/datum/objective/hk47_contracts/New(text)
	. = ..()
	update_explanation_text()

/datum/objective/hk47_contracts/update_explanation_text()
	explanation_text = "Выполнить контракты заказчиков: для полной победы нужно [HK47_CONTRACTS_TO_WIN], каждый выполненный засчитывается частично."

/datum/objective/hk47_contracts/check_completion()
	if(completed)
		return TRUE
	var/datum/antagonist/hk47/hunter = owner?.has_antag_datum(/datum/antagonist/hk47)
	if(!hunter)
		return FALSE
	return min(hunter.contracts_done / HK47_CONTRACTS_TO_WIN, 1)

/datum/objective/hk47_extract
	name = "HK-47 extraction"

/datum/objective/hk47_extract/New(text)
	. = ..()
	update_explanation_text()

/datum/objective/hk47_extract/update_explanation_text()
	explanation_text = "Эвакуироваться со станции: после [HK47_CONTRACTS_TO_WIN] контрактов - капсулой ([DisplayTimeText(HK47_EXTRACTION_TIME)] сигнала у клетки с открытым космосом), или живым на эвакуационном шаттле вне брига."

/datum/objective/hk47_extract/check_completion()
	if(completed)
		return TRUE
	if(!SSticker.mode || !SSshuttle.emergency)
		return FALSE
	return considered_escaped(owner)
