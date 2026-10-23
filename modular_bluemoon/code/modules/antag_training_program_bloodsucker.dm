#define ANTAG_TRAINING_BLOODSUCKER_POWER "Сила при повышении: "

/datum/antag_training_program/antag/bloodsucker
	name = "Кровосос"
	category = "Предатели экипажа"
	desc = "Тёмный сектор: кормление учебной целью, гроб-логово, дыба и учебный вассал, повышение поколения с выбором силы."
	icon = "tooth"
	color = "red"
	learn = "Кормление и запас крови|Гроб-логово|Дыба и учебный вассал|Повышение поколения и выбор силы"
	difficulty = 3
	sector = "dark"
	antag_type = /datum/antagonist/bloodsucker/training
	options = list("Пополнить кровь", "Повысить уровень", "Гроб и дыба", "Цель для кормления")
	var/list/role_options
	/// Подпись кнопки -> тип силы, которую откроет следующее повышение.
	var/list/power_options = list()
	var/next_power
	var/rank_up_hint

/datum/antag_training_program/antag/bloodsucker/New()
	. = ..()
	role_options = options.Copy()
	var/cycle_minutes = antag_training_bloodsucker_cycle_minutes()
	option_hints = list(
		"Пополнить кровь" = "Кровь пополнится до максимума, который растёт с поколением. В раунде кровь даёт только кормление: в сознании и без сна она понемногу уходит, а силы и лечение тратят её быстрее.",
		"Гроб и дыба" = "Рядом с вами в тёмном секторе появятся чёрный гроб и закреплённая дыба, прежние уберутся. Откройте гроб, лягте в него и закройте крышку - тёмный сектор станет логовом. На полигоне гроб занимается сразу; в раунде игра переспросит, логово бывает только на станции и не меняется. Дыбу в раунде собирают в меню крафта (вкладка Misc) после занятия логова и закрепляют щелчком внутри логова.",
		"Цель для кормления" = "Рядом с вами появится ваша учебная цель, из центра и коридора - в лаборатории. Схватите её агрессивно и включите Feed - кормление быстрое, но цель это заметит; стоя рядом без захвата кормление тихое и медленное. Затащите цель на дыбу, щёлкайте по дыбе, пока цель не будет готова, и щёлкните ещё раз: ритуал крови сделает её вассалом. Вассалов не больше, чем поколение; на полигоне вассалом становятся только ваши учебные цели, не другие участники. В раунде кровь пьют только у персонажей, которыми играли люди.",
	)
	rank_up_hint = "Поколение вырастет на одно, а выбранная кнопкой «[ANTAG_TRAINING_BLOODSUCKER_POWER]...» сила откроется. Новая сила стоит [BLOODSUCKER_RANK_BLOOD_SHARE * 100]% максимума крови, повышение без неё бесплатно. В раунде уровни даёт цикл: раз в [cycle_minutes] минут каждый кровосос получает уровень и тратит его сном в закрытом гробу, выбирая силу в окне, а владельцы логова получают Vanishing Act - возврат в логово. Дневного света на сервере нет: фаза дня, когда солнце жгло кровососов вне гроба и ослабляло их, отключена. Учебного кровососа цикл раунда не касается. Стартовый уровень можно потратить и как в раунде - сном в своём гробу."
	refresh_power_options(null)

/// Солнце раунда даёт уровни раз в nighttime_duration срабатываний SSprocessing.
/proc/antag_training_bloodsucker_cycle_minutes()
	var/obj/effect/sunlight/sun = /obj/effect/sunlight
	return round(initial(sun.nighttime_duration) * SSprocessing.wait / (1 MINUTES))

/datum/antag_training_program/antag/bloodsucker/setup(datum/antag_training_session/session)
	. = ..()
	if(.)
		refresh_power_options(session.avatar_mind.has_antag_datum(antag_type))

/datum/antag_training_program/antag/bloodsucker/proc/refresh_power_options(datum/antagonist/bloodsucker/training/vampire)
	for(var/label in power_options)
		option_hints -= label
	power_options = list()
	var/list/buyable = list()
	if(vampire)
		buyable = vampire.BuyablePowers()
	else
		for(var/datum/action/cooldown/bloodsucker/power as anything in typesof(/datum/action/cooldown/bloodsucker))
			if(initial(power.bloodsucker_can_buy))
				buyable[initial(power.name)] = power
	var/list/power_types = list()
	for(var/power_name in buyable)
		var/datum/action/cooldown/bloodsucker/power = buyable[power_name]
		var/label = "[ANTAG_TRAINING_BLOODSUCKER_POWER][power_name]"
		power_options[label] = power
		power_types += power
		option_hints[label] = "Следующее «Повысить уровень» откроет [power_name]: [strip_html_tags(initial(power.desc))]"
	if(!(next_power in power_types))
		next_power = length(power_types) ? power_types[1] : null
	var/datum/action/cooldown/bloodsucker/chosen = next_power
	option_hints["Повысить уровень"] = "[chosen ? "Сейчас выбрана сила [initial(chosen.name)]" : "Все силы изучены, повышение без новой силы"]. [rank_up_hint]"
	options = role_options.Copy()
	for(var/label in power_options)
		options += label

/datum/antag_training_program/antag/bloodsucker/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/bloodsucker/training/vampire = role(session)
	if(!vampire)
		to_chat(user, span_warning("Роль кровососа снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	refresh_power_options(vampire)
	if(findtext(option, ANTAG_TRAINING_BLOODSUCKER_POWER) == 1 && !power_options[option])
		to_chat(user, span_warning("Эта сила уже изучена. Выберите другую."))
		return FALSE
	if(power_options[option])
		next_power = power_options[option]
		var/datum/action/cooldown/bloodsucker/power = next_power
		to_chat(user, span_notice("Следующее повышение откроет [initial(power.name)]."))
		refresh_power_options(vampire)
		return TRUE
	switch(option)
		if("Пополнить кровь")
			vampire.AddBloodVolume(vampire.max_blood_volume - user.blood_volume)
			to_chat(user, span_notice("Крови [round(user.blood_volume)] из [vampire.max_blood_volume]."))
		if("Повысить уровень")
			if(!vampire.training_rank_up(next_power))
				return FALSE
			refresh_power_options(vampire)
		if("Гроб и дыба")
			return place_lair(session, user, vampire)
		if("Цель для кормления")
			return spawn_prey(session, user)
	return TRUE

/datum/antag_training_program/antag/bloodsucker/proc/place_lair(datum/antag_training_session/session, mob/living/user, datum/antagonist/bloodsucker/training/vampire)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	if(dark?.state != ANTAG_TRAINING_SECTOR_READY || !arena.inside_bounds(get_turf(user), dark.bounds))
		to_chat(user, span_warning("Гроб и дыба ставятся в тёмном секторе. Перейдите туда через вкладку «Зоны» и нажмите кнопку снова."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	vampire.clear_training_lair()
	arena.prune_supplies()
	var/turf/coffin_spot = lair_spot(arena, user, dark.bounds)
	if(!coffin_spot)
		to_chat(user, span_warning(lair_problem(arena, user)))
		return FALSE
	var/obj/structure/closet/crate/coffin/blackcoffin/coffin = new(coffin_spot)
	arena.track_supply(coffin, session)
	arena.placed_structures += WEAKREF(coffin)
	vampire.training_coffin_ref = WEAKREF(coffin)
	var/turf/rack_spot = lair_spot(arena, user, dark.bounds)
	if(!rack_spot)
		to_chat(user, span_warning(lair_problem(arena, user)))
		vampire.clear_training_lair()
		return FALSE
	var/obj/structure/bloodsucker/vassalrack/rack = new(rack_spot)
	rack.owner = user
	rack.anchored = TRUE
	rack.density = FALSE
	arena.track_supply(rack, session)
	arena.placed_structures += WEAKREF(rack)
	vampire.training_rack_ref = WEAKREF(rack)
	to_chat(user, span_notice("Гроб и дыба рядом. Откройте гроб, лягте в него и закройте крышку - тёмный сектор станет логовом."))
	return TRUE

/datum/antag_training_program/antag/bloodsucker/proc/lair_problem(datum/antag_training_arena/arena, mob/living/user)
	return arena.construction_error(get_step(user, user.dir)) || "Рядом нет свободного места для гроба и дыбы. Отойдите от стен и мебели."

/// Свободная клетка пола сектора перед участником или вокруг него.
/datum/antag_training_program/antag/bloodsucker/proc/lair_spot(datum/antag_training_arena/arena, mob/living/user, list/bounds)
	for(var/turf/open/floor/spot in list(get_step(user, user.dir)) + orange(1, user) + orange(2, user))
		if(arena.inside_bounds(spot, bounds) && !arena.construction_error(spot))
			return spot
	return null

/datum/antag_training_program/antag/bloodsucker/proc/spawn_prey(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/prey = place_practice_dummy(session, user, "Цель не появилась: идёт сброс или дуэль, либо целей уже [ANTAG_TRAINING_TARGET_LIMIT]. Уберите лишние цели в разделе «Цели».")
	if(!prey)
		return FALSE
	to_chat(user, span_notice("[prey.real_name] - [dummy_zone_name(session, prey)]. Схватите и включите Feed или уложите на дыбу."))
	return TRUE

/datum/antagonist/bloodsucker/training
	name = "Учебный кровосос"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training
	var/datum/weakref/training_coffin_ref
	var/datum/weakref/training_rack_ref

/datum/antagonist/bloodsucker/training/join_sunlight_cycle()
	return

/datum/antagonist/bloodsucker/training/leave_sunlight_cycle()
	return

/datum/antagonist/bloodsucker/training/forge_bloodsucker_objectives()
	return

/datum/antagonist/bloodsucker/training/threat()
	return 0

/datum/antagonist/bloodsucker/training/greet()
	antag_memory += "Учебное имя в не-жизни: <b>[ReturnFullName(TRUE)]</b>.<br>"
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/bloodsucker/training/proc/brief()
	to_chat(owner.current, briefing())
	owner.current.playsound_local(null, 'sound/bloodsucker/BloodsuckerAlert.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/antagonist/bloodsucker/training/proc/briefing()
	return jointext(list(
		span_userdanger("Тренировка кровососа. Вы - [ReturnFullName(TRUE)]."),
		span_notice("Feed, Masquerade и Veil уже ваши; Feed пьёт кровь у схваченной или стоящей рядом цели, Masquerade прячет бледность и тишину сердца ценой крови. Кровь лечит раны и питает силы."),
		span_notice("«Пульт полигона», раздел «Моя роль»: пополнить кровь, повысить поколение с выбором силы, гроб и дыба рядом с вами, цель для кормления. Лягте в гроб и закройте крышку - тёмный сектор станет логовом; на дыбе учебная цель становится вассалом. Здесь дыба закреплена заранее и работает без логова, в раунде её закрепляют только в своём логове."),
		span_notice("Цикл раунда, который раз в [antag_training_bloodsucker_cycle_minutes()] минут даёт кровососам уровни, учебного кровососа не касается: уровень даёт кнопка. Дневного света на сервере нет, солнце не жжёт."),
	), "<br>")

/datum/antagonist/bloodsucker/training/proc/training_rank_up(power_type)
	var/mob/living/body = owner.current
	var/datum/action/cooldown/bloodsucker/power = power_type
	if(power && (locate(power) in powers))
		to_chat(body, span_warning("[initial(power.name)] уже изучена. Выберите другую силу."))
		return FALSE
	var/cost = max_blood_volume * BLOODSUCKER_RANK_BLOOD_SHARE
	if(power && body.blood_volume < cost)
		to_chat(body, span_warning("Новая сила стоит [cost] крови, у вас [round(body.blood_volume)]. Нажмите «Пополнить кровь» или покормитесь."))
		return FALSE
	if(power)
		AddBloodVolume(-cost)
		BuyPower(new power)
		to_chat(body, span_cult("Вы использовали [cost] крови и изучили [initial(power.name)]!"))
	bloodsucker_level_unspent++
	AdvanceRank()
	log_game("[key_name(body)] на тренировочном полигоне повышает учебного кровососа до [bloodsucker_level] поколения[power ? ", сила [initial(power.name)]" : ""].")
	return TRUE

/datum/antagonist/bloodsucker/training/attempt_turn_vassal(mob/living/carbon/target)
	target.silent = 0
	if(!SSticker.mode.can_make_vassal(target, owner))
		return FALSE
	var/datum/antagonist/vassal/training/vassal = new
	vassal.master = src
	vassal.training = training
	if(!target.mind.add_antag_datum(vassal))
		return FALSE
	SelectTitle(am_fledgling = FALSE)
	log_game("[key_name(owner.current)] на тренировочном полигоне делает [target.real_name] учебным вассалом.")
	return TRUE

/datum/antagonist/bloodsucker/training/proc/clear_training_lair()
	var/obj/structure/closet/crate/coffin/old_coffin = training_coffin_ref?.resolve()
	var/obj/structure/bloodsucker/vassalrack/old_rack = training_rack_ref?.resolve()
	training_coffin_ref = null
	training_rack_ref = null
	if(old_rack)
		old_rack.owner = null
		qdel(old_rack)
	if(coffin && coffin.resident == owner.current)
		coffin.resident = null
		coffin.anchored = FALSE
	coffin = null
	lair = null
	qdel(old_coffin)

/datum/antagonist/bloodsucker/training/on_removal()
	FreeAllVassals()
	clear_training_lair()
	return ..()

/// Удаление разума с сессией зовёт Destroy() мимо on_removal().
/datum/antagonist/bloodsucker/training/Destroy()
	if(owner)
		FreeAllVassals()
		clear_training_lair()
	. = ..()
	training = null
	coffin = null
	lair = null
	vassals.Cut()

/datum/antagonist/vassal/training
	name = "Учебный вассал"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/vassal/training/on_gain()
	. = ..()
	SSticker.mode.vassals -= owner

/datum/antagonist/vassal/training/threat()
	return 0

/datum/antagonist/vassal/training/Destroy()
	if(master)
		master.vassals -= src
	. = ..()
	training = null
	master = null

#undef ANTAG_TRAINING_BLOODSUCKER_POWER
