#define HERETIC_DUSK_SHADE_FILTER "heretic_dusk_shade"
#define HERETIC_DUSK_LIGHT_BURN_FILTER "heretic_dusk_light_burn"
#define HERETIC_DUSK_LIGHT_BURN_COLOR "#f4e2a6"
#define HERETIC_DUSK_SERVANT_INTEGRITY 10
#define HERETIC_DUSK_SERVANT_REACH 7
#define HERETIC_DUSK_BURN_PULSE (1 SECONDS)
#define HERETIC_DUSK_BURN_LINGER (1.5 SECONDS)
#define HERETIC_DUSK_DAZZLE_TIME (2.5 SECONDS)
#define HERETIC_DUSK_ROT_CHECK (2 SECONDS)

/// Заветы падшего по id в порядке радиального меню.
GLOBAL_LIST_INIT(heretic_dusk_covenants, list(
	HERETIC_DUSK_COVENANT_SERAPH = new /datum/heretic_dusk_covenant/seraph,
	HERETIC_DUSK_COVENANT_FALLEN = new /datum/heretic_dusk_covenant/fallen,
	HERETIC_DUSK_COVENANT_ROT = new /datum/heretic_dusk_covenant/rot,
))

/// Завет падшего: смещает упор пути, меняет часть приёмов, пассив и лист мутации.
/datum/heretic_dusk_covenant
	var/id
	var/name
	/// Подпись варианта в радиальном меню выбора.
	var/choice_text
	var/choice_state
	var/flash_state
	/// Лист мутации Завета с теми же стейтами и холстом, что у общего.
	var/mutation_icon
	var/examine_line
	var/chosen_text
	var/flash_desc

/datum/heretic_dusk_covenant/seraph
	id = HERETIC_DUSK_COVENANT_SERAPH
	name = "Завет Нимба"
	choice_text = "Завет Нимба: Лик слепит дальше и дольше, луч идёт цепью ламп, Нисхождение жжёт пол светом"
	choice_state = "dusk_cov_seraph"
	flash_state = "dusk_covenant_flash_seraph"
	mutation_icon = 'modular_bluemoon/icons/mob/heretic_dusk_mutation_seraph.dmi'
	examine_line = "Нимб над ним цел, но кровоточит светом, по коже раскрываются глаза-ожоги. Тёмные очки и сварочная маска вдвое ослабят его свет."
	chosen_text = "Вы приносите Завет Нимба. Свет больше не жжёт вас - он вам служит: Лик бьёт дальше и дольше, лампы передают друг другу ваш луч, пол под Нисхождением горит, а на свету раны затягиваются."
	flash_desc = "нимб вспыхивает добела, по коже раскрываются глаза-ожоги!"

/datum/heretic_dusk_covenant/fallen
	id = HERETIC_DUSK_COVENANT_FALLEN
	name = "Завет Крыла"
	choice_text = "Завет Крыла: 3 заряда Шага, Удар из тени режет до крови, Хватка дольше, отнятая тень служит вам"
	choice_state = "dusk_cov_fallen"
	flash_state = "dusk_covenant_flash_fallen"
	mutation_icon = 'modular_bluemoon/icons/mob/heretic_dusk_mutation_fallen.dmi'
	examine_line = "Его крылья - живая тьма, нимб погас и треснул, вместо лица пустота; в тени он расплывается. Луч фонаря в лицо сбивает ему Шаг в тень."
	chosen_text = "Вы приносите Завет Крыла. Свет вам больше не нужен: Шаг в тень держит три заряда, Удар из тени режет до крови, Хватка держит дольше, а отнятые тени служат вам. Берегитесь фонаря в лицо."
	flash_desc = "крылья смыкаются чернильной тьмой, и нимб гаснет!"

/datum/heretic_dusk_covenant/rot
	id = HERETIC_DUSK_COVENANT_ROT
	name = "Завет Скверны"
	choice_text = "Завет Скверны: Хватка заражает, носители кормят вас, Хватка и Шаг берут их и на свету, Перо гноит их раны"
	choice_state = "dusk_cov_rot"
	flash_state = "dusk_covenant_flash_rot"
	mutation_icon = 'modular_bluemoon/icons/mob/heretic_dusk_mutation_rot.dmi'
	examine_line = "Его перья в плесени и чернильно-зелёной гнили, нимб проржавел, из трещин сочится мутная слизь. Скверну с заражённых снимают огонь, очиститель и святая вода."
	chosen_text = "Вы приносите Завет Скверны. Свет и тень гниют вокруг вас: Хватка оставляет скверну, она липнет к тем, кто касается заражённых, и кормит вас Сумраком, а ваши лампы гниют. Гнилую тень носителя Хватка держит полностью и на свету, Шаг достаёт её издалека, а Перо гноит его раны. Огонь, очиститель и святая вода - ваши враги."
	flash_desc = "по перьям расползается зелёная гниль, нимб ржавеет!"

/datum/heretic_dusk_covenant/proc/confirm_text(mob/living/user)
	if(istype(get_area(user), /area/antag_training))
		return "[choice_text]. В раунде Завет приносится один раз и держится до конца раунда, а на полигоне путь можно подготовить заново и попробовать другой. Принести [name]?"
	return "[choice_text]. Завет приносится один раз и держится до конца раунда: сменить его будет нельзя. Принести [name]?"

/// Гниль в ране от Пера: синтетикам - сбой систем, любителям токсинов - ожог, остальным - токсины. Возвращает нанесённый урон.
/proc/heretic_dusk_rot_wound(mob/living/target, amount)
	if(QDELETED(target) || target.stat == DEAD || amount <= 0)
		return 0
	var/before = target.getToxLoss() + target.getFireLoss()
	if(HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM))
		target.adjustToxLoss(amount, toxins_type = TOX_SYSCORRUPT)
	else if(HAS_TRAIT(target, TRAIT_TOXINLOVER))
		target.adjustFireLoss(amount)
	else
		target.adjustToxLoss(amount)
	if(QDELETED(target))
		return amount
	return max(0, target.getToxLoss() + target.getFireLoss() - before)

/datum/eldritch_knowledge/base_dusk/proc/covenant_datum()
	return covenant ? GLOB.heretic_dusk_covenants[covenant] : null

/// Лист мутации: с выбора Завета - его лист, до выбора - общий.
/datum/eldritch_knowledge/base_dusk/proc/mutation_icon()
	var/datum/heretic_dusk_covenant/chosen = covenant_datum()
	return chosen?.mutation_icon || HERETIC_DUSK_MUTATION_ICON

/// Время Хватки: на свету без отнятой тени короче; без аргумента - по grip_short ложащейся Хватки.
/datum/eldritch_knowledge/base_dusk/proc/grip_time(short)
	if(isnull(short))
		short = grip_short
	return (short ? HERETIC_DUSK_GRIP_LIT_TIME : HERETIC_DUSK_GRIP_TIME) + (covenant == HERETIC_DUSK_COVENANT_FALLEN ? HERETIC_DUSK_FALLEN_GRIP_BONUS : 0)

/datum/eldritch_knowledge/base_dusk/proc/covenant_block_reason(mob/living/user)
	if(!can_use(user, TRUE))
		return "Способность недоступна вашему пути или текущему телу."
	if(!knows(/datum/eldritch_knowledge/spell/dusk_covenant))
		return "Завет открывается на четвёртой ступени пути."
	var/datum/heretic_dusk_covenant/chosen = covenant_datum()
	if(chosen)
		return "[chosen.name] уже принесён и держится до конца раунда."
	return null

/datum/eldritch_knowledge/base_dusk/proc/open_covenant_menu(mob/living/user)
	dusk_failure = covenant_block_reason(user)
	if(dusk_failure)
		return FALSE
	var/list/choices = list()
	var/list/ids = list()
	for(var/covenant_id in GLOB.heretic_dusk_covenants)
		var/datum/heretic_dusk_covenant/option = GLOB.heretic_dusk_covenants[covenant_id]
		choices[option.choice_text] = image(icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi', icon_state = option.choice_state)
		ids[option.choice_text] = covenant_id
	var/choice = show_radial_menu(user, user, choices, tooltips = TRUE)
	if(!choice || !ids[choice])
		dusk_failure = "Завет не выбран: кнопка «Завет» подождёт."
		return FALSE
	var/datum/heretic_dusk_covenant/picked = GLOB.heretic_dusk_covenants[ids[choice]]
	if(tgui_alert(user, picked.confirm_text(user), picked.name, list("Принести", "Отмена")) != "Принести")
		dusk_failure = "Завет не принесён: кнопка «Завет» подождёт."
		return FALSE
	return choose_covenant(user, ids[choice])

/// Завет приносится один раз и держится до конца раунда: облик, приёмы и пассив перестраиваются под него.
/datum/eldritch_knowledge/base_dusk/proc/choose_covenant(mob/living/user, covenant_id)
	dusk_failure = covenant_block_reason(user)
	if(dusk_failure)
		return FALSE
	var/datum/heretic_dusk_covenant/chosen = GLOB.heretic_dusk_covenants[covenant_id]
	if(!chosen)
		dusk_failure = "Такого Завета нет."
		return FALSE
	covenant = covenant_id
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/spell/dusk_covenant/rite = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/dusk_covenant)
	if(rite)
		QDEL_NULL(rite.choice_power)
	if(covenant == HERETIC_DUSK_COVENANT_FALLEN)
		fill_charges("step")
	if(covenant == HERETIC_DUSK_COVENANT_ROT)
		for(var/datum/component/heretic_dusk_lamp/hex as anything in lamps)
			hex.set_rot(TRUE)
	refresh_shade_blur()
	refresh_mutation()
	heretic_dusk_screen_glitch(user)
	new /obj/effect/temp_visual/heretic_dusk/covenant_flash(get_turf(user), chosen.flash_state)
	heretic_dusk_sound(user, "covenant_[covenant]", 55, FALSE)
	user.visible_message(span_danger("Облик [user] рывком перерастает: [chosen.flash_desc]"), span_eldritch(chosen.chosen_text))
	log_game("[key_name(user)] приносит [chosen.name] Сумрака в [AREACOORD(user)].")
	notify_resource_changed()
	lesson_event("covenant", user, covenant)
	return TRUE

/// Пассивы Заветов раз в проверку света: Нимб лечится в Лике на свету и слепит носителей огней, Скверна кормится носителями.
/datum/eldritch_knowledge/base_dusk/proc/covenant_tick()
	if(!dusk_body || dusk_body.stat == DEAD)
		return
	var/holy = in_holy_ground || holy_blood || world.time < holy_silence_until
	switch(covenant)
		if(HERETIC_DUSK_COVENANT_SERAPH)
			if(form == HERETIC_DUSK_FORM_FACE && lit && !holy)
				heretic_heal_pool(dusk_body, HERETIC_DUSK_SERAPH_HEAL)
				dazzle_bearers()
		if(HERETIC_DUSK_COVENANT_ROT)
			if(length(rot) && !holy && COOLDOWN_FINISHED(src, rot_feed))
				COOLDOWN_START(src, rot_feed, HERETIC_DUSK_ROT_FEED_TIME)
				gain_combat_resource(length(rot))

/// Лик Нимба на свету слепит тех, кто светит на него фонарём, если на них нет защиты глаз.
/datum/eldritch_knowledge/base_dusk/proc/dazzle_bearers()
	for(var/mob/living/carbon/human/bearer in range(HERETIC_DUSK_SERAPH_DAZZLE_RANGE, dusk_body))
		if(bearer == dusk_body || bearer.stat == DEAD || IS_HERETIC(bearer) || IS_HERETIC_MONSTER(bearer) || bearer.get_eye_protection() > 0)
			continue
		if(length(heretic_dusk_carried_lights(bearer)) && is_A_facing_B(bearer, dusk_body))
			bearer.apply_status_effect(/datum/status_effect/heretic_dusk_dazzled)

/datum/eldritch_knowledge/base_dusk/proc/refresh_shade_blur()
	set_shade_blur(covenant == HERETIC_DUSK_COVENANT_FALLEN && form == HERETIC_DUSK_FORM_WING && !lit && dusk_body?.stat != DEAD)

/// Крыло в тени расплывается: фильтр на теле, пока облик и тень держатся.
/datum/eldritch_knowledge/base_dusk/proc/set_shade_blur(enabled)
	if(shade_blur == enabled)
		return
	shade_blur = enabled
	if(!dusk_body)
		return
	if(enabled)
		dusk_body.add_filter(HERETIC_DUSK_SHADE_FILTER, 2, gauss_blur_filter(1))
	else
		dusk_body.remove_filter(HERETIC_DUSK_SHADE_FILTER)

/// Фонарь в лицо Крылу Завета сбивает Шаг в тень.
/datum/eldritch_knowledge/base_dusk/proc/jam_step(mob/living/user)
	if(!dusk_body || dusk_body.stat == DEAD || form != HERETIC_DUSK_FORM_WING || !is_A_facing_B(dusk_body, user))
		return FALSE
	step_jam_until = world.time + HERETIC_DUSK_FALLEN_LIGHT_JAM
	to_chat(dusk_body, span_warning("Свет фонаря бьёт в лицо, и тень за спиной съёживается: Шаг в тень недоступен [HERETIC_DUSK_FALLEN_LIGHT_JAM / (1 SECONDS)] секунды."))
	dusk_body.visible_message(span_notice("Луч фонаря бьёт [dusk_body] в лицо, и чернильные крылья судорожно сжимаются."), vision_distance = COMBAT_MESSAGE_RANGE)
	log_combat(user, dusk_body, "сбивает фонарём Шаг в тень Сумрака у")
	lesson_event("step_jammed", user)
	return TRUE

/// Удар из тени Крыла режет до крови.
/datum/eldritch_knowledge/base_dusk/proc/strike_bleed(mob/living/user, mob/living/target)
	var/mob/living/carbon/victim = target
	if(!istype(victim))
		return FALSE
	var/obj/item/bodypart/part = victim.get_bodypart(check_zone(user.zone_selected)) || victim.get_bodypart(BODY_ZONE_CHEST)
	if(!part)
		return FALSE
	part.generic_bleedstacks += HERETIC_DUSK_FALLEN_BLEED
	return TRUE

/// Отнятая тень встаёт слугой Крыла; слуга один, новый сменяет прежнего.
/datum/eldritch_knowledge/base_dusk/proc/raise_servant(mob/living/victim)
	if(!dusk_body)
		return null
	QDEL_NULL(servant)
	var/obj/structure/heretic_dusk_shade/shade = new(get_turf(victim), src)
	if(QDELETED(shade))
		return null
	servant = shade
	heretic_dusk_sound(shade, "shade_servant", 40, TRUE)
	log_game("[key_name(dusk_body)] поднимает тень-слугу Сумрака из тени [key_name(victim)] в [AREACOORD(shade)].")
	lesson_event("servant", shade)
	return shade

/datum/eldritch_knowledge/base_dusk/proc/on_servant_gone(obj/structure/heretic_dusk_shade/shade)
	if(servant == shade)
		servant = null

/// Скверна садится на человека, пока у хозяина меньше трёх носителей.
/datum/eldritch_knowledge/base_dusk/proc/infect_rot(mob/living/victim, mob/living/carrier)
	if(covenant != HERETIC_DUSK_COVENANT_ROT || !dusk_body || !ishuman(victim) || length(rot) >= HERETIC_DUSK_ROT_CARRIERS)
		return null
	if(victim.has_status_effect(/datum/status_effect/heretic_dusk_rot) || !heretic_can_affect(dusk_body, victim, chargecost = 0, notify = FALSE))
		return null
	var/datum/status_effect/heretic_dusk_rot/spot = victim.apply_status_effect(/datum/status_effect/heretic_dusk_rot, src)
	if(QDELETED(spot))
		return null
	log_combat(dusk_body, victim, carrier ? "заражает скверной Сумрака через [key_name(carrier)]" : "заражает скверной Сумрака")
	lesson_event("rot", victim)
	return spot

/datum/eldritch_knowledge/base_dusk/proc/update_rot_alert()
	if(!dusk_body)
		return
	if(!length(rot))
		dusk_body.clear_alert(HERETIC_DUSK_ROT_ALERT)
	else
		var/atom/movable/screen/alert/heretic_dusk_rot_carriers/alert = dusk_body.throw_alert(HERETIC_DUSK_ROT_ALERT, /atom/movable/screen/alert/heretic_dusk_rot_carriers)
		alert?.desc = "Носителей скверны: [length(rot)] из [HERETIC_DUSK_ROT_CARRIERS]. Вы видите их сквозь стены и раз в [HERETIC_DUSK_ROT_FEED_TIME / (1 SECONDS)] секунд копите от каждого единицу Сумрака; Хватка держит их полностью и на свету, Шаг дотягивается до них издалека, Перо гноит их раны на [HERETIC_DUSK_ROT_QUILL_TOX] токсина. Огонь, очиститель и святая вода снимают скверну."
	notify_resource_changed()

/obj/effect/proc_holder/spell/self/heretic_dusk/covenant
	name = "Завет"
	desc = "Принесите один из трёх Заветов падшего - раз и до конца раунда, после подтверждения; облик мутации перерастёт под него. Нимб: Лик слепит в 4 клетках на 6 секунд, луч лампы идёт цепью ваших ламп и жжёт сильнее, Нисхождение оставляет ожог света, в Лике на свету вы медленно лечитесь, а светящие на вас фонарём видят хуже; тёмные очки и сварочные маски вдвое ослабляют свет Нимба. Крыло: 3 заряда Шага, Удар из тени сильнее и режет до крови, Хватка дольше на 3 секунды, отнятая тень встаёт тенью-слугой, в тени вы расплываетесь; фонарь в лицо сбивает Шаг на 3 секунды. Скверна: Хватка заражает цель на 60 секунд, скверна переходит на касавшихся - до 3 носителей, вы видите их и копите от них Сумрак, Хватка держит их полностью и на свету, Шаг дотягивается до них за 14 клеток, а каждый удар Пером по носителю - ещё 4 токсина; ваши лампы гниют, у Чёрных солнц растёт налёт; огонь, очиститель и святая вода снимают скверну."
	summary = "Раз и до конца раунда: Нимб - свет и контроль, Крыло - убийца из тени, Скверна - заражение и гниль."
	charge_max = 1 SECONDS
	usable_while_grabbed = TRUE
	holy_ground_allowed = TRUE
	action_icon_state = "dusk_covenant"

/obj/effect/proc_holder/spell/self/heretic_dusk/covenant/block_reason(mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	return dusk ? dusk.covenant_block_reason(user) : "Способность недоступна вашему пути или текущему телу."

/obj/effect/proc_holder/spell/self/heretic_dusk/covenant/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk?.open_covenant_menu(user))
		heretic_revert_cast(user, dusk?.dusk_failure)

/// Скверна Завета: гниль на человеке выдаёт его хозяину, кормит его Сумраком и липнет к касавшимся.
/datum/status_effect/heretic_dusk_rot
	id = "heretic_dusk_rot"
	duration = HERETIC_DUSK_ROT_TIME
	tick_interval = HERETIC_DUSK_ROT_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_rot
	examine_text = span_warning("SUBJECTPRONOUN роняет хлопья зелёной гнили, тень под ногами плесневеет. Кто тронет - подхватит скверну; огонь, космический очиститель или святая вода её снимут.")
	var/datum/weakref/dusk_ref
	var/applied = FALSE
	var/mutable_appearance/spores

/datum/status_effect/heretic_dusk_rot/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dusk/dusk)
	dusk_ref = WEAKREF(dusk)
	return ..()

/datum/status_effect/heretic_dusk_rot/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!. || !dusk || owner.stat == DEAD || length(dusk.rot) >= HERETIC_DUSK_ROT_CARRIERS)
		return FALSE
	applied = TRUE
	dusk.rot += src
	spores = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_rot_mark", ABOVE_MOB_LAYER)
	spores.appearance_flags = RESET_COLOR | KEEP_APART
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	RegisterSignal(owner, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_touched))
	RegisterSignal(owner, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_touching))
	RegisterSignal(owner, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	RegisterSignal(owner, COMSIG_LIVING_IGNITED, PROC_REF(on_ignited))
	owner.update_icon()
	heretic_dusk_sound(owner, "rot_spread", 40, FALSE)
	to_chat(owner, span_userdanger("По коже ползут хлопья гнили, и тень под ногами плесневеет! Огонь, космический очиститель или святая вода снимут скверну; не трогайте других."))
	dusk.update_rot_alert()
	return TRUE

/datum/status_effect/heretic_dusk_rot/tick()
	if(owner.on_fire)
		cleanse("Огонь выжигает гниль с [owner].")
	else if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		cleanse("Святая вода в крови [owner] вытравливает гниль.")

/datum/status_effect/heretic_dusk_rot/proc/cleanse(message)
	if(QDELETED(src))
		return
	owner.visible_message(span_notice(message), span_notice("Скверна сходит с вас."))
	heretic_dusk_sound(owner, "rot_cleanse", 50, TRUE)
	qdel(src)

/datum/status_effect/heretic_dusk_rot/proc/spread_to(mob/living/other)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(dusk && isliving(other) && other != owner)
		dusk.infect_rot(other, owner)

/datum/status_effect/heretic_dusk_rot/proc/on_touched(datum/source, mob/user)
	SIGNAL_HANDLER
	spread_to(user)

/datum/status_effect/heretic_dusk_rot/proc/on_touching(datum/source, atom/target)
	SIGNAL_HANDLER
	spread_to(target)

/datum/status_effect/heretic_dusk_rot/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	if(method != TOUCH && method != VAPOR)
		return
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			cleanse("Святая вода смывает гниль с [owner].")
			return
		if(istype(reagent, /datum/reagent/space_cleaner))
			cleanse("Очиститель смывает гниль с [owner].")
			return

/datum/status_effect/heretic_dusk_rot/proc/on_ignited(datum/source)
	SIGNAL_HANDLER
	cleanse("Огонь выжигает гниль с [owner].")

/datum/status_effect/heretic_dusk_rot/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(spores)
		overlays += spores

/datum/status_effect/heretic_dusk_rot/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_ATOM_ATTACK_HAND, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_LIVING_IGNITED))
		spores = null
		owner.update_icon()
		var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
		if(dusk)
			dusk.rot -= src
			dusk.update_rot_alert()
	dusk_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dusk_rot
	name = "Скверна"
	desc = "По коже ползёт гниль падшего ангела. Сама она не ранит, но выдаёт вас еретику, кормит его, гноит раны от его Пера, даёт его тени схватить вас и на свету и липнет к тем, кого вы касаетесь. Огонь, космический очиститель или святая вода её снимут; через 60 секунд она отпадёт сама."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_rot_carriers"

/atom/movable/screen/alert/heretic_dusk_rot_carriers
	name = "Носители скверны"
	desc = "Носители вашей скверны видны вам сквозь стены и кормят вас Сумраком."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_rot_carriers"

/// Ожог света Нисхождения Нимба: пол 3 на 3 светится, стоящий на нём подсвечен и вязнет.
/obj/effect/heretic_dusk_light_burn
	name = "light burn"
	desc = "Пол выжжен светом в сетку светлых трещин, от него больно глазам. Стоящих на нём видно издалека, и ноги вязнут; тёмные очки или сварочная маска спасают от замедления."
	icon = HERETIC_DUSK_FX_ICON
	icon_state = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_OPEN_TURF_LAYER
	light_range = 2
	light_power = 0.8
	light_color = HERETIC_DUSK_LIGHT_BURN_COLOR
	var/datum/weakref/dusk_ref
	var/pulses = 0

/obj/effect/heretic_dusk_light_burn/Initialize(mapload, datum/eldritch_knowledge/base_dusk/dusk)
	. = ..()
	dusk_ref = WEAKREF(dusk)
	var/list/tiles = list()
	for(var/dx in -1 to 1)
		for(var/dy in -1 to 1)
			var/mutable_appearance/tile = mutable_appearance(icon, "dusk_light_burn_zone")
			tile.pixel_x = dx * world.icon_size
			tile.pixel_y = dy * world.icon_size
			tiles += tile
	add_overlay(tiles)
	heretic_dusk_sound(src, "light_burn", 50, TRUE)
	pulse()

/obj/effect/heretic_dusk_light_burn/proc/pulse()
	if(QDELETED(src))
		return
	for(var/mob/living/victim in range(1, src))
		if(victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		victim.apply_status_effect(/datum/status_effect/heretic_dusk_light_burned, victim.get_eye_protection() > 0)
	pulses++
	if(pulses * HERETIC_DUSK_BURN_PULSE >= HERETIC_DUSK_SERAPH_BURN_TIME)
		qdel(src)
		return
	addtimer(CALLBACK(src, PROC_REF(pulse)), HERETIC_DUSK_BURN_PULSE)

/// Ожог света на человеке: обводка видна издалека, ноги вязнут, если глаза не защищены.
/datum/status_effect/heretic_dusk_light_burned
	id = "heretic_dusk_light_burned"
	duration = HERETIC_DUSK_BURN_LINGER
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/shielded = FALSE

/datum/status_effect/heretic_dusk_light_burned/on_creation(mob/living/new_owner, shielded)
	src.shielded = shielded
	return ..()

/datum/status_effect/heretic_dusk_light_burned/on_apply()
	. = ..()
	owner.add_filter(HERETIC_DUSK_LIGHT_BURN_FILTER, 2, outline_filter(size = 1, color = HERETIC_DUSK_LIGHT_BURN_COLOR))
	if(!shielded)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_light_burned)
		to_chat(owner, span_warning("Пол под вами горит светом, ноги вязнут!"))

/datum/status_effect/heretic_dusk_light_burned/on_remove()
	owner.remove_filter(HERETIC_DUSK_LIGHT_BURN_FILTER)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_light_burned)
	return ..()

/datum/movespeed_modifier/heretic_dusk_light_burned
	multiplicative_slowdown = 0.6

/// Лик Нимба слепит того, кто светит на него фонарём.
/datum/status_effect/heretic_dusk_dazzled
	id = "heretic_dusk_dazzled"
	duration = HERETIC_DUSK_DAZZLE_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_dusk_dazzled/on_apply()
	. = ..()
	owner.overlay_fullscreen("heretic_dusk_dazzle", /atom/movable/screen/fullscreen/scaled/impaired, 1)
	to_chat(owner, span_warning("Ваш фонарь отражается от лика ангела и бьёт обратно в глаза!"))

/datum/status_effect/heretic_dusk_dazzled/on_remove()
	owner.clear_fullscreen("heretic_dusk_dazzle", 1 SECONDS)
	return ..()

/// Тень-слуга Завета Крыла: бежит за хозяином и путает ноги погоне; любой удар или фонарик её рвут.
/obj/structure/heretic_dusk_shade
	name = "shade servant"
	desc = "Чужая тень оторвалась от хозяина и бежит за другим: сгорбленная чернильная фигура с белыми глазами. Наступивший на неё спотыкается. Любой удар или луч фонарика рвут её."
	icon = HERETIC_DUSK_FX_ICON
	icon_state = "dusk_shade_servant"
	density = FALSE
	anchored = TRUE
	max_integrity = HERETIC_DUSK_SERVANT_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF
	layer = BELOW_MOB_LAYER
	var/datum/weakref/dusk_ref
	var/datum/weakref/master_ref
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/obj/structure/heretic_dusk_shade/Initialize(mapload, datum/eldritch_knowledge/base_dusk/dusk)
	. = ..()
	var/mob/living/master = dusk?.dusk_body
	if(!master)
		return INITIALIZE_HINT_QDEL
	dusk_ref = WEAKREF(dusk)
	master_ref = WEAKREF(master)
	RegisterSignal(master, COMSIG_MOVABLE_MOVED, PROC_REF(on_master_moved))
	AddElement(/datum/element/connect_loc, loc_connections)
	setDir(get_dir(src, master) || SOUTH)
	addtimer(CALLBACK(src, PROC_REF(fade)), HERETIC_DUSK_SERVANT_TIME)

/obj/structure/heretic_dusk_shade/Destroy()
	var/mob/living/master = master_ref?.resolve()
	if(master)
		UnregisterSignal(master, COMSIG_MOVABLE_MOVED)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	dusk?.on_servant_gone(src)
	dusk_ref = null
	master_ref = null
	return ..()

/// Слуга встаёт на клетку, которую хозяин только что покинул.
/obj/structure/heretic_dusk_shade/proc/on_master_moved(atom/movable/source, atom/old_loc, movement_dir, forced, list/old_locs)
	SIGNAL_HANDLER
	var/turf/behind = old_loc
	if(!isturf(behind) || behind == loc || behind.z != z || get_dist(behind, source) > 1 || get_dist(src, behind) > HERETIC_DUSK_SERVANT_REACH)
		return
	if(!isopenturf(behind) || behind.is_blocked_turf(exclude_mobs = TRUE))
		return
	forceMove(behind)
	setDir(get_dir(behind, source) || dir)

/obj/structure/heretic_dusk_shade/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/stepper = arrived
	if(!isliving(stepper) || stepper.stat == DEAD || IS_HERETIC(stepper) || IS_HERETIC_MONSTER(stepper))
		return
	stepper.apply_status_effect(/datum/status_effect/heretic_dusk_slowed)
	to_chat(stepper, span_warning("Чужая тень цепляется за ваши ноги!"))

/obj/structure/heretic_dusk_shade/attackby(obj/item/item, mob/living/user, params)
	if(heretic_dusk_light_item(item))
		user.changeNext_move(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		visible_message(span_notice("[user] светит на тень-слугу, и она рвётся в клочья."))
		deconstruct(FALSE)
		return TRUE
	return ..()

/obj/structure/heretic_dusk_shade/attack_hand(mob/user, act_intent = user?.a_intent, attackchain_flags)
	. = ..()
	if(!isliving(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src)
	visible_message(span_notice("[user] бьёт тень-слугу, и она рвётся в клочья."))
	deconstruct(FALSE)

/obj/structure/heretic_dusk_shade/proc/fade()
	if(!QDELETED(src))
		deconstruct(FALSE)

/obj/structure/heretic_dusk_shade/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		new /obj/effect/temp_visual/heretic_dusk/servant_burst(place)
		heretic_dusk_sound(place, "shade_burst", 50, TRUE)
	return ..()

/// Налёт скверны у Чёрного солнца Скверны: наступивший подхватывает скверну, моют очиститель, швабра и святая вода.
/obj/effect/decal/cleanable/heretic_dusk_rot
	name = "rot bloom"
	desc = "Чернильно-зелёный налёт гнили расползается по полу от Чёрного солнца. Наступивший на него подхватывает скверну. Его смывают космический очиститель, швабра, мыло и святая вода."
	icon = HERETIC_DUSK_FX_ICON
	icon_state = "dusk_rot_decal1"
	random_icon_states = list("dusk_rot_decal1", "dusk_rot_decal2", "dusk_rot_decal3")
	var/datum/weakref/dusk_ref
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_EXPOSE_REAGENTS = PROC_REF(on_floor_exposed),
	)

/obj/effect/decal/cleanable/heretic_dusk_rot/Initialize(mapload, list/datum/disease/diseases, datum/eldritch_knowledge/base_dusk/dusk)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	dusk_ref = WEAKREF(dusk)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/decal/cleanable/heretic_dusk_rot/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(dusk && isliving(arrived))
		dusk.infect_rot(arrived)

/obj/effect/decal/cleanable/heretic_dusk_rot/proc/on_floor_exposed(turf/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			visible_message(span_notice("Святая вода шипит на налёте скверны, и он смывается."))
			qdel(src)
			return

/obj/effect/temp_visual/heretic_dusk/covenant_flash
	icon_state = "dusk_covenant_flash_seraph"
	duration = 1.4 SECONDS

/obj/effect/temp_visual/heretic_dusk/covenant_flash/Initialize(mapload, state)
	. = ..()
	if(state)
		icon_state = state

/obj/effect/temp_visual/heretic_dusk/servant_burst
	name = "torn shadow"
	icon_state = "dusk_shade_servant_burst"
	duration = 1.2 SECONDS

#undef HERETIC_DUSK_SHADE_FILTER
#undef HERETIC_DUSK_LIGHT_BURN_FILTER
#undef HERETIC_DUSK_LIGHT_BURN_COLOR
#undef HERETIC_DUSK_SERVANT_INTEGRITY
#undef HERETIC_DUSK_SERVANT_REACH
#undef HERETIC_DUSK_BURN_PULSE
#undef HERETIC_DUSK_BURN_LINGER
#undef HERETIC_DUSK_DAZZLE_TIME
#undef HERETIC_DUSK_ROT_CHECK
