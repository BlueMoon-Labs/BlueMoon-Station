/datum/species/ipc/hk/hk51
	/// Ключ голосовой строки -> звук.
	var/static/list/voice_lines = list(
		"hk51_diagnostic" = 'modular_bluemoon/sound/hk_droids/hk51_diagnostic.ogg',
		"hk51_loyalty" = 'modular_bluemoon/sound/hk_droids/hk51_loyalty.ogg',
		"hk51_deletions" = 'modular_bluemoon/sound/hk_droids/hk51_deletions.ogg',
		"hk51_efficiency_down" = 'modular_bluemoon/sound/hk_droids/hk51_efficiency_down.ogg',
	)
	var/last_voice
	var/last_combat_time
	/// Запись дроида в базе СБ.
	var/record_id
	COOLDOWN_DECLARE(voice_cooldown)

/datum/species/ipc/hk/hk51/on_species_gain(mob/living/carbon/human/droid, datum/species/old_species, pref_load)
	. = ..()
	RegisterSignals(droid, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_GUN_PROCESS_FIRE), PROC_REF(on_combat))
	RegisterSignal(droid, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

/datum/species/ipc/hk/hk51/on_species_loss(mob/living/carbon/human/droid, datum/species/new_species, pref_load)
	UnregisterSignal(droid, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_STATCHANGE))
	return ..()

/// Голосовая строка с кулдауном на дроида; forced - для активации и смены хозяина.
/datum/species/ipc/hk/hk51/proc/hk51_voice(mob/living/speaker, sound_key, forced = FALSE)
	if(!forced && !COOLDOWN_FINISHED(src, voice_cooldown))
		return FALSE
	if(!hk_voice_line(speaker, voice_lines[sound_key]))
		return FALSE
	COOLDOWN_START(src, voice_cooldown, HK51_VOICE_COOLDOWN)
	last_voice = sound_key
	return TRUE

/datum/species/ipc/hk/hk51/proc/boot_voice(mob/living/droid)
	hk51_voice(droid, "hk51_diagnostic", forced = TRUE)
	addtimer(CALLBACK(src, PROC_REF(delayed_voice), WEAKREF(droid), "hk51_loyalty"), HK51_LOYALTY_LINE_DELAY)

/datum/species/ipc/hk/hk51/proc/delayed_voice(datum/weakref/droid_ref, sound_key)
	hk51_voice(droid_ref.resolve(), sound_key, forced = TRUE)

/datum/species/ipc/hk/hk51/on_master_changed(mob/living/carbon/human/source, datum/mind/new_master, datum/mind/old_master)
	. = ..()
	if(new_master)
		hk51_voice(source, "hk51_loyalty", forced = TRUE)
	if(!new_master)
		note_security_record("Хозяина нет: блок лояльности сброшен.")
	else if(!hk_master_is_antagonist(new_master))
		note_security_record("Блок лояльности перезаписан, хозяин - [new_master.name].")

/datum/species/ipc/hk/hk51/proc/on_combat(mob/living/source)
	SIGNAL_HANDLER
	note_combat(source)

/// Реплика об «удалениях» - только когда бой начинается после затишья, а не на каждый удар.
/datum/species/ipc/hk/hk51/proc/note_combat(mob/living/droid)
	var/calm = isnull(last_combat_time) || world.time - last_combat_time >= HK51_COMBAT_CALM_TIME
	last_combat_time = world.time
	if(!calm || droid.stat != CONSCIOUS)
		return FALSE
	return hk51_voice(droid, "hk51_deletions")

/datum/species/ipc/hk/hk51/proc/on_stat_change(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(old_stat == CONSCIOUS && new_stat != DEAD && source.InCritical())
		hk51_voice(source, "hk51_efficiency_down")

/// HK-51 в базе СБ: собран экипажем, при хозяине-экипаже - не преступник. Хозяина-антагониста СБ не узнаёт, как и у HK-47.
/datum/species/ipc/hk/hk51/proc/file_security_record(mob/living/carbon/human/droid, datum/mind/master)
	var/id = num2hex(rand(1, 16777215), 6)
	var/rank = "Дроид HK-51"
	var/datum/data/record/general = new
	general.fields["id"] = id
	general.fields["name"] = droid.real_name
	general.fields["rank"] = rank
	general.fields["real_rank"] = rank
	general.fields["gender"] = "Male"
	general.fields["age"] = "Unknown"
	general.fields["species"] = "HK"
	general.fields["fingerprint"] = "Нет: дроид"
	general.fields["p_stat"] = "Active"
	general.fields["m_stat"] = "Stable"
	general.photo_source = new /datum/record_photo_source(droid, null, null)
	GLOB.data_core.general += general
	GLOB.data_core.register_record(general, "general")
	var/datum/data/record/security = new
	security.name = "Security Record #[id]"
	security.fields["id"] = id
	security.fields["name"] = droid.real_name
	security.fields["criminal"] = SEC_RECORD_STATUS_NONE
	security.fields["mi_crim"] = list()
	security.fields["ma_crim"] = list()
	security.fields["fines"] = list()
	var/master_note = "Хозяин не задан."
	if(hk_master_is_antagonist(master))
		master_note = "Хозяин в записи не указан."
	else if(master)
		master_note = "Хозяин - [master.name]."
	security.fields["notes"] = "Собран экипажем из найденных частей. [master_note]"
	security.fields["actions_logs"] = list("<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [droid.real_name] | [rank] | [id] -- ИНИЦИАТОР: робототехника;</u><br>")
	LAZYINITLIST(security.fields["comments"])
	GLOB.data_core.security += security
	GLOB.data_core.register_record(security, "security")
	record_id = id
	droid.sec_hud_set_security_status()
	return security

/datum/species/ipc/hk/hk51/proc/note_security_record(note)
	var/datum/data/record/record = record_id ? GLOB.data_core.security_by_id[record_id] : null
	if(!record)
		return FALSE
	var/notes = record.fields["notes"]
	record.fields["notes"] = length(notes) ? "[notes] [note]" : note
	return TRUE

/// "выше на 2 палубы" для уровней одной связки, иначе null.
/proc/hk51_deck_relation(turf/here, turf/there)
	if(!here || !there || here.z == there.z)
		return null
	var/list/stack = SSmapping.get_connected_levels(here.z)
	var/here_index = stack.Find(here.z)
	var/there_index = stack.Find(there.z)
	if(!here_index || !there_index)
		return null
	return "[there_index > here_index ? "выше" : "ниже"] на [hk51_decks_text(abs(there_index - here_index))]"

/proc/hk51_decks_text(decks)
	var/tens = decks % 100
	if(tens < 11 || tens > 14)
		switch(decks % 10)
			if(1)
				return "[decks] палубу"
			if(2 to 4)
				return "[decks] палубы"
	return "[decks] палуб"

/// Хозяин ушёл насовсем: тела нет (крио, уничтожено) или он мёртв и отказался возвращаться.
/proc/hk51_master_gone(datum/mind/master)
	var/mob/living/body = master?.current
	if(!istype(body) || QDELETED(body))
		return TRUE
	return body.stat == DEAD && !body.key && !master.get_ghost()

/// Датчик хозяина HK-51: стрелка до хозяина на этом уровне, палубы на соседних; протокол телохранителя метит нападавших на хозяина.
/datum/status_effect/hk51_master_tracker
	id = "hk51_master_tracker"
	duration = -1
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/hk_pointer/hk51_master
	/// Состояние стрелки из icons/obj/device.dmi.
	var/pointer
	var/datum/weakref/watched_master_ref
	/// WEAKREF(нападавший) -> world.time последнего сигнала о нём.
	var/list/last_alerts
	/// WEAKREF(нападавший) -> метка над ним, видная только дроиду.
	var/list/threat_marks

/atom/movable/screen/alert/status_effect/hk_pointer/hk51_master
	name = "HK master tracker"
	desc = "Встроенный датчик HK-51 показывает направление на хозяина и примерную дальность до него на этом уровне, а на соседних - сколько палуб выше или ниже."

/datum/status_effect/hk51_master_tracker/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(.)
		update_pointer()

/datum/status_effect/hk51_master_tracker/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_HK_MASTER_CHANGED, PROC_REF(on_master_changed))

/datum/status_effect/hk51_master_tracker/on_remove()
	UnregisterSignal(owner, COMSIG_HK_MASTER_CHANGED)
	watch_master(null)
	for(var/datum/weakref/attacker_ref as anything in threat_marks)
		clear_mark(attacker_ref)
	last_alerts = null
	return ..()

/datum/status_effect/hk51_master_tracker/tick()
	check_master_gone()
	update_pointer()

/datum/status_effect/hk51_master_tracker/proc/on_master_changed(datum/source, datum/mind/new_master, datum/mind/old_master)
	SIGNAL_HANDLER
	update_pointer()

/datum/status_effect/hk51_master_tracker/proc/loyalty()
	return owner?.GetComponent(/datum/component/hk_loyalty)

/datum/status_effect/hk51_master_tracker/proc/master_body()
	var/datum/component/hk_loyalty/loyalty = loyalty()
	var/datum/mind/master = loyalty?.get_master()
	return master?.current

/// Хозяин ушёл насовсем: дроид свободен до новой перепрошивки.
/datum/status_effect/hk51_master_tracker/proc/check_master_gone()
	var/datum/component/hk_loyalty/loyalty = loyalty()
	var/datum/mind/master = loyalty?.get_master()
	if(!master || !hk51_master_gone(master))
		return FALSE
	to_chat(owner, span_boldnotice("Сигнал хозяина пропал насовсем: [master.name] не вернётся. Вы свободны до новой перепрошивки."))
	loyalty.set_master(null)
	return TRUE

/datum/status_effect/hk51_master_tracker/proc/update_pointer()
	var/mob/living/body = master_body()
	watch_master(body)
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(body)
	var/new_pointer = "pinonnull"
	var/direction = SOUTH
	var/text = "Хозяина нет или у него нет тела: датчик пуст."
	if(here && there)
		if(here.z != there.z)
			var/relation = hk51_deck_relation(here, there)
			text = relation ? "Хозяин [body.real_name] [relation]." : "Хозяин [body.real_name] в другом секторе."
		else
			var/static/list/pointer_names = list("pinondirect" = "вплотную", "pinonclose" = "рядом", "pinonmedium" = "близко", "pinonfar" = "далеко")
			var/distance = here == there ? 0 : get_dist(here, there)
			new_pointer = hk_tracker_pointer(distance)
			if(distance)
				direction = get_dir(here, there)
			text = "Хозяин [body.real_name]: [pointer_names[new_pointer]][distance ? ", [dir2text_ru(direction)]" : ""]."
	pointer = new_pointer
	var/atom/movable/screen/alert/status_effect/hk_pointer/alert = linked_alert
	alert?.show_pointer(new_pointer, direction, text)

/// Следить за нападениями на тело хозяина; null снимает слежку.
/datum/status_effect/hk51_master_tracker/proc/watch_master(mob/living/body)
	var/mob/living/watched = watched_master_ref?.resolve()
	if(watched == body)
		return
	if(watched)
		UnregisterSignal(watched, list(COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_HIT_BY_PROJECTILE))
	watched_master_ref = null
	if(!istype(body) || body == owner)
		return
	watched_master_ref = WEAKREF(body)
	RegisterSignal(body, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_master_attacked))
	RegisterSignal(body, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_master_shot))

/datum/status_effect/hk51_master_tracker/proc/on_master_shot(mob/living/source, obj/item/projectile/projectile, def_zone)
	SIGNAL_HANDLER
	if(projectile.firer)
		on_master_attacked(source, projectile.firer)

/// Протокол телохранителя: имя и направление нападавшего, метка над ним на HK51_BODYGUARD_MARK_TIME. Невидимку датчик не опознаёт.
/datum/status_effect/hk51_master_tracker/proc/on_master_attacked(mob/living/source, atom/movable/attacker)
	SIGNAL_HANDLER
	if(!ismob(attacker) || attacker == owner || attacker == source || QDELETED(attacker))
		return
	var/datum/weakref/attacker_ref = WEAKREF(attacker)
	var/last_alert = LAZYACCESS(last_alerts, attacker_ref)
	if(!isnull(last_alert) && world.time < last_alert + HK51_BODYGUARD_REPEAT)
		return
	LAZYSET(last_alerts, attacker_ref, world.time)
	var/turf/here = get_turf(owner)
	owner.playsound_local(here, 'sound/machines/twobeep_high.ogg', 50, FALSE)
	var/atom/movable/screen/alert/hk51_threat/alert = owner.throw_alert("hk51_threat", /atom/movable/screen/alert/hk51_threat, duration_ds = HK51_BODYGUARD_MARK_TIME)
	if(attacker.alpha <= HK47_STEALTH_ALPHA || attacker.invisibility > owner.see_invisible)
		to_chat(owner, span_userdanger("Протокол телохранителя: на хозяина напали, но датчик не видит нападавшего."))
		alert?.show_unseen_threat()
		return
	var/turf/there = get_turf(attacker)
	var/where = here && there && here.z == there.z ? "направление - [dir2text_ru(get_dir(here, there))]" : "вне досягаемости датчика"
	to_chat(owner, span_userdanger("Протокол телохранителя: на хозяина напал [attacker.name], [where]."))
	alert?.show_threat(attacker, here && there && here.z == there.z ? get_dir(here, there) : SOUTH, where)
	mark_threat(attacker)

/datum/status_effect/hk51_master_tracker/proc/mark_threat(atom/movable/attacker)
	var/datum/weakref/attacker_ref = WEAKREF(attacker)
	if(!LAZYACCESS(threat_marks, attacker_ref))
		var/image/mark = image('icons/effects/neural_interface_overlays.dmi', attacker, "target", FLOAT_LAYER)
		mark.color = "#ff5a3c"
		mark.appearance_flags = RESET_COLOR | RESET_TRANSFORM
		LAZYSET(threat_marks, attacker_ref, mark)
		owner.client?.images += mark
		RegisterSignal(attacker, COMSIG_PARENT_QDELETING, PROC_REF(on_threat_deleted))
	addtimer(CALLBACK(src, PROC_REF(clear_mark), attacker_ref), HK51_BODYGUARD_MARK_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/status_effect/hk51_master_tracker/proc/on_threat_deleted(atom/movable/attacker)
	SIGNAL_HANDLER
	LAZYREMOVE(last_alerts, attacker.weak_reference)
	clear_mark(attacker.weak_reference)

/datum/status_effect/hk51_master_tracker/proc/clear_mark(datum/weakref/attacker_ref)
	var/image/mark = LAZYACCESS(threat_marks, attacker_ref)
	if(!mark)
		return
	LAZYREMOVE(threat_marks, attacker_ref)
	var/atom/movable/attacker = attacker_ref.resolve()
	if(attacker)
		UnregisterSignal(attacker, COMSIG_PARENT_QDELETING)
	owner?.client?.images -= mark
	mark.loc = null

/atom/movable/screen/alert/hk51_threat
	name = "HK bodyguard protocol"
	desc = "На хозяина напали."
	icon = 'icons/obj/device.dmi'
	icon_state = "pinpointer_syndicate"

/atom/movable/screen/alert/hk51_threat/proc/show_threat(atom/movable/attacker, direction, where)
	desc = "На хозяина напал [attacker.name], [where]."
	setDir(direction)
	cut_overlays()
	add_overlay("pinonclose")

/atom/movable/screen/alert/hk51_threat/proc/show_unseen_threat()
	desc = "На хозяина напали, но датчик не видит нападавшего: ни имени, ни направления."
	setDir(SOUTH)
	cut_overlays()
