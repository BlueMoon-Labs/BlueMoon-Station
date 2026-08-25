/obj/item/gun/medbeam
	name = "Medical Beamgun"
	desc = "Don't cross the streams!"
	icon = 'icons/obj/chronos.dmi'
	icon_state = "chronogun"
	item_state = "chronogun"
	w_class = WEIGHT_CLASS_NORMAL

	var/mob/living/current_target
	var/last_check = 0
	var/check_delay = 10 //Check los as often as possible, max resolution is SSobj tick though
	var/max_range = 8
	var/active = 0
	var/datum/beam/current_beam = null
	var/mounted = 0 //Denotes if this is a handheld or mounted version

	var/main_heal = -10
	var/second_heal = -5
	// BLUEMOON ADD START - медлуч восстанавливает кровь и заживляет раны (раны через on_xadone)
	/// Сколько крови восстанавливается за тик обработки луча
	var/blood_restore_per_tick = 5
	/// Сила заживления ран за тик обработки луча (см. /datum/wound/proc/on_xadone)
	var/wound_heal_power = 3
	/// Плоское восстановление brute/burn за тик (heal_overall_damage)
	var/overall_restore_per_tick = 2
	// BLUEMOON ADD END

	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/medbeam/Destroy(mob/user)
	LoseTarget()
	return ..()

/obj/item/gun/medbeam/dropped(mob/user)
	..()
	LoseTarget()

/obj/item/gun/medbeam/equipped(mob/user)
	..()
	LoseTarget()

/obj/item/gun/medbeam/proc/LoseTarget()
	if(active)
		QDEL_NULL(current_beam)
		active = 0
		on_beam_release(current_target)
		playsound(src, 'sound/magic/tf2/medigun_heal_detach.ogg', 50, FALSE, 3)
	STOP_PROCESSING(SSobj, src)
	current_target = null

/obj/item/gun/medbeam/proc/beam_died()
	SIGNAL_HANDLER
	current_beam = null
	active = FALSE //skip qdelling the beam again if we're doing this proc, because
	if(isliving(loc))
		to_chat(loc, span_warning("You lose control of the beam!"))
	LoseTarget()

/obj/item/gun/medbeam/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(isliving(user))
		add_fingerprint(user)

	if(current_target)
		LoseTarget()
	if(!isliving(target) || (user == target))
		return

	current_target = target
	active = TRUE
	// current_beam = new(user,current_target,time=6000,beam_icon_state="medbeam",btype=/obj/effect/ebeam/medical)
	// INVOKE_ASYNC(current_beam, TYPE_PROC_REF(/datum/beam, Start))
	current_beam = user.Beam(current_target, icon_state="medbeam", time = 10 MINUTES, maxdistance = max_range, beam_type = /obj/effect/ebeam/medical)
	RegisterSignal(current_beam, COMSIG_PARENT_QDELETING, PROC_REF(beam_died))
	playsound(src, 'sound/magic/tf2/medigun_heal.ogg', 50, FALSE, 3)
	START_PROCESSING(SSobj, src)

	SSblackbox.record_feedback("tally", "gun_fired", 1, type)

/obj/item/gun/medbeam/process()

	var/source = loc
	if(!mounted && !isliving(source))
		LoseTarget()
		return

	if(!current_target)
		LoseTarget()
		return

	if(world.time <= last_check+check_delay)
		return

	last_check = world.time

	// if(get_dist(source, current_target)>max_range || !los_check(source, current_target))
	// 	LoseTarget()
	// 	if(isliving(source))
	// 		to_chat(source, "<span class='warning'>You lose control of the beam!</span>")
	// 	return
	if(!los_check(source, current_target))
		QDEL_NULL(current_beam)
		return

	if(current_target)
		on_beam_tick(current_target)

/obj/item/gun/medbeam/proc/los_check(atom/movable/user, mob/target)
	var/turf/user_turf = user.loc
	if(mounted)
		user_turf = get_turf(user)
	else if(!istype(user_turf))
		return FALSE
	var/obj/dummy = new(user_turf)
	dummy.pass_flags |= PASSTABLE|PASSGLASS|PASSGRILLE //Grille/Glass so it can be used through common windows
	var/turf/previous_step = user_turf
	var/first_step = TRUE
	for(var/turf/next_step as anything in (getline(user_turf, target) - user_turf))
		if(first_step)
			for(var/obj/blocker in user_turf)
				if(!blocker.density || !(blocker.flags_1 & ON_BORDER_1))
					continue
				if(blocker.CanPass(dummy, get_dir(user_turf, next_step)))
					continue
				// Болванка стоит на турфе, сборщик её не возьмёт: этот выход единственный
				// обходил qdel, и каждый тик луча у перегороженной границы оставлял в мире голый /obj.
				qdel(dummy)
				return FALSE
			first_step = FALSE

		if(mounted && next_step == user_turf)
			continue //Mechs are dense and thus fail the check
		if(next_step.density)
			qdel(dummy)
			return FALSE
		for(var/atom/movable/AM as anything in next_step)
			if(!AM.CanPass(dummy, get_dir(next_step, previous_step)))
				qdel(dummy)
				return FALSE
		for(var/obj/effect/ebeam/medical/B in next_step)// Don't cross the str-beams!
			if(QDELETED(current_beam))
				break
			if(QDELETED(B))
				continue
			if(!B.owner)
				stack_trace("beam without an owner! [B]")
			if(B.owner.origin != current_beam.origin)
				explosion(B.loc, 0, 3, 5, 8)
				qdel(dummy)
				return FALSE
		previous_step = next_step
	qdel(dummy)
	return TRUE

/obj/item/gun/medbeam/proc/on_beam_hit(var/mob/living/target)
	return

/obj/item/gun/medbeam/proc/on_beam_tick(var/mob/living/target)
	// BLUEMOON EDIT - луч теперь виден и когда лечим раны или кровь, а не только урон
	var/healing_something = target.health != target.maxHealth
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		if(length(carbon_target.all_wounds) || carbon_target.blood_volume < BLOOD_VOLUME_NORMAL)
			healing_something = TRUE
	if(healing_something)
		new /obj/effect/temp_visual/heal(get_turf(target), "#80F5FF")
	target.drowsyness = max(target.drowsyness-5, 0)
	target.AdjustUnconscious(main_heal, FALSE)
	target.AdjustAllImmobility(main_heal, FALSE)
	target.adjustStaminaLoss(main_heal, FALSE)
	target.adjustBruteLoss(main_heal, FALSE, TRUE, only_robotic = FALSE, only_organic = FALSE)
	target.adjustFireLoss(main_heal, FALSE, TRUE, only_robotic = FALSE, only_organic = FALSE)
	target.heal_overall_damage(overall_restore_per_tick, overall_restore_per_tick, 0, only_robotic = FALSE, only_organic = FALSE, updating_health = TRUE)
	target.adjustToxLoss(second_heal, forced = TRUE)
	target.adjustOxyLoss(second_heal)
	target.adjust_disgust(second_heal)
	// Восстановление крови и заживление ран (порезы, проколы, ожоги,
	// переломы через общий механизм крио-прогресса). Копия списка обязательна: on_xadone
	// может удалить полностью залеченную рану прямо во время обхода.
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		if(carbon_target.blood_volume < BLOOD_VOLUME_NORMAL)
			carbon_target.blood_volume = min(carbon_target.blood_volume + blood_restore_per_tick, BLOOD_VOLUME_NORMAL)
		if(length(carbon_target.all_wounds))
			for(var/datum/wound/wound as anything in carbon_target.all_wounds.Copy())
				wound.on_xadone(wound_heal_power)
	return

/obj/item/gun/medbeam/proc/on_beam_release(var/mob/living/target)
	return

/obj/effect/ebeam/medical
	name = "medical beam"

/obj/item/gun/medbeam/weak
	name = "Civilian Medical Beamgun"
	desc = "Just like a regular beamgun, but cheaper."
	main_heal = -5
	second_heal = -2.5
	blood_restore_per_tick = 2.5
	wound_heal_power = 1.5
	overall_restore_per_tick = 1

///////////////////////////////Syndicate Version///////////////////////////////

#define MEDBEAM_UBER_CHARGE_PER_TICK 2

/obj/item/gun/medbeam/syndicate
	name = "\improper Syndicate Medical Beamgun"
	desc = "Чудо инженерии Syndicate с модулем Уберзаряда. Держа луч на пациенте, вы заряжаете \
			Уберзаряд; когда он полон, активируйте его кнопкой использования предмета (Пробел): \
			вы и ваш пациент на десять секунд покрываетесь неуязвимым алым сиянием."

	/// Текущий заряд убера, 0-100
	var/uber_charge = 0
	/// Активен ли уберзаряд прямо сейчас (на это время новый заряд не копится)
	var/uber_deployed = FALSE
	/// Длительность неуязвимости
	var/uber_duration = 10 SECONDS
	/// Сообщили ли уже пользователю о готовности заряда
	var/charge_ready_reported = FALSE

/obj/item/gun/medbeam/syndicate/examine(mob/user)
	. = ..()
	if(uber_deployed)
		. += span_warning("Уберзаряд активен!")
	else
		. += span_notice("Заряд Уберзаряда: [round(uber_charge)]%[uber_charge >= 100 ? ". ГОТОВ - активируйте кнопкой использования предмета!" : "."]")

/obj/item/gun/medbeam/syndicate/attack_self(mob/living/user)
	activate_uber(user)

/// Пока луч работает, уберзаряд копится сам собой
/obj/item/gun/medbeam/syndicate/on_beam_tick(var/mob/living/target)
	..()
	if(uber_deployed || !isliving(loc))
		return
	uber_charge = min(100, uber_charge + MEDBEAM_UBER_CHARGE_PER_TICK)
	if(uber_charge >= 100 && !charge_ready_reported)
		charge_ready_reported = TRUE
		var/mob/living/user = loc
		user.balloon_alert(user, "уберзаряд готов!")

/obj/item/gun/medbeam/syndicate/proc/activate_uber(mob/living/user)
	if(uber_deployed)
		to_chat(user, "<span class='warning'>Уберзаряд уже активен!</span>")
		return
	if(uber_charge < 100)
		user.balloon_alert(user, "уберзаряд не готов ([round(uber_charge)]%)")
		return

	uber_charge = 0
	charge_ready_reported = FALSE
	uber_deployed = TRUE
	addtimer(CALLBACK(src, PROC_REF(end_uber)), uber_duration)
	playsound(src, 'sound/magic/tf2/medigun_charged.ogg', 50, TRUE)

	// Неуязвимость получает и медик, и пациент под лучом
	if(isliving(user) && !(user.status_flags & GODMODE))
		user.apply_status_effect(/datum/status_effect/ubercharged, uber_duration)
	if(isliving(current_target) && current_target != user && !(current_target.status_flags & GODMODE))
		current_target.apply_status_effect(/datum/status_effect/ubercharged, uber_duration)

/obj/item/gun/medbeam/syndicate/proc/end_uber()
	uber_deployed = FALSE

#undef MEDBEAM_UBER_CHARGE_PER_TICK

/// Кратковременная полная неуязвимость с алым оверлеем, как уберзаряд из Team Fortress 2.
/// Ставится парой: на медика с пушкой и на пациента под лучом.
/datum/status_effect/ubercharged
	id = "ubercharged"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/ubercharged
	/// Цвет владельца до покрытия алым сиянием, возвращаем при снятии
	var/old_color

/atom/movable/screen/alert/status_effect/ubercharged
	name = "Уберзаряд"
	desc = "Алое сияние защищает вас от любого вреда!"
	icon_state = "blooddrunk"

/datum/status_effect/ubercharged/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	return ..()

/datum/status_effect/ubercharged/on_apply()
	. = ..()
	if(!.)
		return
	old_color = owner.color
	owner.log_message("gained ÜberCharge invulnerability", LOG_ATTACK)
	owner.visible_message("<span class='warning'>[owner] вспыхивает алым сиянием!</span>", \
		"<span class='userdanger'>Вас накрывает алое сияние уберзаряда - вы неуязвимы!</span>")
	// Алый оверлей: красный канал сохранён, зелёный и синий приглушены
	animate(owner, color = list(1,0,0,0, 0,0.25,0,0, 0,0,0.25,0, 0,0,0,1), time = 5)
	owner.status_flags |= GODMODE
	playsound(owner, 'sound/magic/tf2/medi_shield_deploy.ogg', 50, TRUE)

/datum/status_effect/ubercharged/on_remove()
	. = ..()
	owner.status_flags &= ~GODMODE
	owner.log_message("lost ÜberCharge invulnerability", LOG_ATTACK)
	owner.visible_message("<span class='warning'>Алое сияние вокруг [owner] гаснет.</span>", \
		"<span class='boldwarning'>Сияние гаснет - вы снова уязвимы!</span>")
	animate(owner, color = old_color, time = 5)
	playsound(owner, 'sound/magic/tf2/medi_shield_retract.ogg', 50, TRUE)

// BLUEMOON ADD END

//////////////////////////////Mech Version///////////////////////////////
/obj/item/gun/medbeam/mech
	mounted = TRUE
	// main_heal = -20 //! Слишком мощно.
	// second_heal = -10 //! Слишком мощно.

/obj/item/gun/medbeam/mech/Initialize(mapload)
	. = ..()
	STOP_PROCESSING(SSobj, src) //Mech mediguns do not process until installed, and are controlled by the holder obj
